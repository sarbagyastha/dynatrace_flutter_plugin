package com.dynatrace.android.agent;

import android.location.Location;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.net.MalformedURLException;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.LinkedList;

import com.dynatrace.android.agent.conf.ConfigurationFactory;
import com.dynatrace.android.agent.conf.DataCollectionLevel;
import com.dynatrace.android.agent.conf.DynatraceConfigurationBuilder;
import com.dynatrace.android.agent.conf.UserPrivacyOptions;
import com.dynatrace.android.agent.context.FlutterContext;
import com.dynatrace.android.agent.crash.PlatformType;

class DynatraceMethodCallHandler implements MethodChannel.MethodCallHandler {

	private Hashtable<Integer, DTXAction> actions;
	// x-dynatrace header value (will always be unique) and the timing object associated with
	private Hashtable<String, WebRequestTiming> webTimings;
	private LinkedList<Integer> rootActions;

	private static final int PLATFORM_ANDROID = 0;

	private FlutterContext flutterContext;

	public DynatraceMethodCallHandler(FlutterContext flutterContext) {
		this.flutterContext = flutterContext;
		actions = new Hashtable<>();
		webTimings = new Hashtable<>();
		rootActions = new LinkedList<>();
	}

	@Override
	public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
		if (methodCall.method.equals("enterAction")) {
			if (methodCall.argument("parent") != null) {
				enterActionWithParent((String) methodCall.argument("name"), (int) methodCall.argument("key"), (int) methodCall.argument("parent"),
						methodCall.argument("platform"));
			} else {
				enterAction((String) methodCall.argument("name"), (int) methodCall.argument("key"), methodCall.argument("platform"));
			}
		} else if (methodCall.method.equals("leaveAction")) {
			leaveAction((int) methodCall.argument("key"));
		} else if (methodCall.method.equals("cancelAction")) {
			cancelAction((int) methodCall.argument("key"));
		} else if (methodCall.method.equals("endVisit")) {
			endVisit(methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportError")) {
			reportError((String) methodCall.argument("errorName"), (int) methodCall.argument("errorCode"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportErrorStacktrace")) {
			reportErrorStacktrace((String) methodCall.argument("errorName"), (String) methodCall.argument("errorValue"), (String) methodCall.argument("reason"),
					(String) methodCall.argument("stacktrace"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportCrash")) {
			reportCrash((String) methodCall.argument("errorValue"), (String) methodCall.argument("reason"),
					(String) methodCall.argument("stacktrace"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportCrashWithException")) {
			reportCrashWithException((String) methodCall.argument("crashName"), (String) methodCall.argument("reason"),
					(String) methodCall.argument("stacktrace"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportErrorInAction")) {
			reportErrorInAction((int) methodCall.argument("key"), (String) methodCall.argument("errorName"),
					(int) methodCall.argument("errorCode"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("identifyUser")) {
			identifyUser((String) methodCall.argument("user"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportEventInAction")) {
			reportEventInAction((int) methodCall.argument("key"), (String) methodCall.argument("name"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportStringValueInAction")) {
			reportStringValueInAction((int) methodCall.argument("key"), (String) methodCall.argument("name"),
					(String) methodCall.argument("value"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportIntValueInAction")) {
			reportIntValueInAction((int) methodCall.argument("key"), (String) methodCall.argument("name"), (int) methodCall.argument("value"),
					methodCall.argument("platform"));
		} else if (methodCall.method.equals("reportDoubleValueInAction")) {
			reportDoubleValueInAction((int) methodCall.argument("key"), (String) methodCall.argument("name"),
					(double) methodCall.argument("value"), methodCall.argument("platform"));
		} else if (methodCall.method.equals("setGPSLocation")) {
			setGPSLocation((double) methodCall.argument("latitude"), (double) methodCall.argument("longitude"),
					methodCall.argument("platform"));
		} else if (methodCall.method.equals("flushEvents")) {
			flushEvents(methodCall.argument("platform"));
		} else if (methodCall.method.equals("applyUserPrivacyOptions")) {
			applyUserPrivacyOptions((int) methodCall.argument("dataCollectionLevel"), (boolean) methodCall.argument("crashReportingOptedIn"),
					methodCall.argument("platform"));
		} else if (methodCall.method.equals("getUserPrivacyOptions")) {
			result.success(getUserPrivacyOptions(methodCall.argument("platform")));
		} else if (methodCall.method.equals("getRequestTag")) {
			result.success(getRequestTag((int) methodCall.argument("key"), (String) methodCall.argument("url")));
		} else if (methodCall.method.equals("getRequestTagForInterceptor")) {
			result.success(getRequestTagForInterceptor());
		} else if (methodCall.method.equals("startWebRequestTiming")) {
			startWebRequestTiming((String) methodCall.argument("requestTag"));
		} else if (methodCall.method.equals("stopWebRequestTiming")) {
			stopWebRequestTiming((String) methodCall.argument("requestTag"), (String) methodCall.argument("url"),
					(int) methodCall.argument("responseCode"), (String) methodCall.argument("responseMessage"));
		} else if (methodCall.method.equals("start")) {
			start((String) methodCall.argument("beaconUrl"), (String) methodCall.argument("applicationId"),
					(Boolean) methodCall.argument("userOptIn"), (Boolean) methodCall.argument("crashReporting"),
					(String) methodCall.argument("logLevel"), (Boolean) methodCall.argument("certificateValidation"));
		} else if (methodCall.method.equals("getAutoStartConfiguration")) {
			HashMap<String, Boolean> configuration = new HashMap<>();
			configuration.put("autoStart", ConfigurationFactory.getConfiguration().autoStart);
			configuration.put("logLevel", ConfigurationFactory.getConfiguration().debugLogLevel);
			configuration.put("webRequest", ConfigurationFactory.getConfiguration().webRequestTiming);
			configuration.put("crashReporting", ConfigurationFactory.getConfiguration().crashReporting);
			result.success(configuration);
		} else {
			result.notImplemented();
		}
	}

	private void start(String beaconUrl, String applicationId, Boolean userOptIn, Boolean crashReporting, String logLevel,
			Boolean certificateValidation) {
		DynatraceConfigurationBuilder builder = new DynatraceConfigurationBuilder(applicationId, beaconUrl);

		if (userOptIn != null) {
			builder.withUserOptIn(userOptIn);
		}

		if (crashReporting != null) {
			builder.withCrashReporting(crashReporting);
		}

		if (logLevel != null && logLevel.equals("debug")) {
			builder.withDebugLogging(true);
		}

		if (certificateValidation != null) {
			builder.withCertificateValidation(certificateValidation);
		}

		Dynatrace.startup(flutterContext.getContext(), builder.buildConfiguration());
	}

	private void enterAction(String name, int key, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			DTXAction action = Dynatrace.enterAction(name);
			actions.put(key, action);
			rootActions.add(key);
		}
	}

	private void enterActionWithParent(String name, int key, int parentKey, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			DTXAction parent = actions.get(parentKey);

			if (parent != null) {
				DTXAction action = Dynatrace.enterAction(name, parent);
				actions.put(key, action);
			} else {
				enterAction(name, key, platform);
			}
		}
	}

	private void leaveAction(int key) {
		DTXAction action = actions.get(key);

		if (action != null) {
			if (action instanceof DTXAutoAction) {
				((DTXAutoAction) action).startTimer();
			} else {
				action.leaveAction();
			}

			actions.remove(key);
		}

		rootActions.remove((Integer) key);
	}

	private void cancelAction(int key) {
		DTXAction action = actions.get(key);

		if (action != null) {
			action.cancel();
			actions.remove(key);
		}

		rootActions.remove((Integer) key);
	}


	private void endVisit(Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Dynatrace.endVisit();
		}
	}

	private void reportError(String errorName, int errorCode, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Dynatrace.reportError(errorName, errorCode);
		}
	}

	/**
	 * Reports a stacktrace - Used primary for the internal error handler
	 *
	 * @param errorName  Name of the Error - SyntaxError
	 * @param errorValue  Name of the Error
	 * @param reason     Reason for the Error
	 * @param stacktrace Whole Stacktrace
	 * @param platform   Platform wise or both
	 */
	private void reportErrorStacktrace(String errorName, String errorValue, String reason, String stacktrace,
			Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Dynatrace.reportError(PlatformType.CUSTOM, errorName, errorValue, reason, stacktrace);
		}
	}

	public void reportCrash(String errorValue, String reason, String stacktrace, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Dynatrace.reportCrash(PlatformType.CUSTOM, errorValue, reason, stacktrace);
			Dynatrace.createNewSession();
		}
	}

	public void reportCrashWithException(String crashName, String reason, String stacktrace, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Dynatrace.reportCrash(PlatformType.DART, crashName, reason, stacktrace);
			Dynatrace.createNewSession();
		}
	}

	private void reportErrorInAction(int key, String errorName, int errorCode, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			DTXAction action = actions.get(key);
			if (action == null)
				return;
			action.reportError(errorName, errorCode);
		}
	}

	private void identifyUser(String user, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Dynatrace.identifyUser(user);
		}
	}

	private void reportEventInAction(int key, String name, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			DTXAction action = actions.get(key);
			if (action == null)
				return;
			action.reportEvent(name);
		}
	}

	private void reportStringValueInAction(int key, String name, String value, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			DTXAction action = actions.get(key);
			if (action == null)
				return;
			action.reportValue(name, value);
		}
	}

	private void reportIntValueInAction(int key, String name, int value, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			DTXAction action = actions.get(key);
			if (action == null)
				return;
			action.reportValue(name, value);
		}
	}

	private void reportDoubleValueInAction(int key, String name, double value, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			DTXAction action = actions.get(key);
			if (action == null)
				return;
			action.reportValue(name, value);
		}
	}

	private void setGPSLocation(double latitude, double longitude, Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Location location = new Location("");
			location.setLatitude(latitude);
			location.setLongitude(longitude);
			Dynatrace.setGpsLocation(location);
		}
	}

	private void flushEvents(Object platform) {
		if (this.shouldWorkOnAndroid(platform)) {
			Dynatrace.flushEvents();
		}
	}

	private String getRequestTag(int key, String url) {
		if (key != 0 && url != null) {
			DTXAction action = actions.get(key);
			if (action != null) {
				return action.getRequestTag();
			}
		}
		return Dynatrace.getRequestTag();
	}

	private String getRequestTagForInterceptor() {
		if (!rootActions.isEmpty()) {
			DTXAction action = actions.get(rootActions.getLast());

			if (action != null) {
				return action.getRequestTag();
			}
		}
		return Dynatrace.getRequestTag();
	}

	private void startWebRequestTiming(String requestTag) {
		if (requestTag != null) {
			WebRequestTiming timing = Dynatrace.getWebRequestTiming(requestTag);
			if(timing != null){
				webTimings.put(requestTag, timing);
				timing.startWebRequestTiming();
			}
		}
	}

	private void stopWebRequestTiming(String requestTag, String url, int responseCode, String responseMessage) {
		if (requestTag != null) {
			WebRequestTiming timing = webTimings.get(requestTag);
			if (timing != null) {
				try {
					timing.stopWebRequestTiming(url, responseCode, responseMessage);
					webTimings.remove(requestTag);
				} catch (MalformedURLException ex) {
					// do nothing
				}
			}
		}
	}

	private void applyUserPrivacyOptions(int dataCollectionLevel, boolean crashReporting, Object platform){
		if(this.shouldWorkOnAndroid(platform)){
			UserPrivacyOptions.Builder optionsBuilder = UserPrivacyOptions.builder();
			optionsBuilder.withCrashReportingOptedIn(crashReporting);
			optionsBuilder.withDataCollectionLevel(DataCollectionLevel.values()[dataCollectionLevel]);

			Dynatrace.applyUserPrivacyOptions(optionsBuilder.build());
		}
	}

	private HashMap<String, Object> getUserPrivacyOptions(Object platform){
		HashMap<String, Object> optionsMap = new HashMap<>();

		if(this.shouldWorkOnAndroid(platform)){
			UserPrivacyOptions options = Dynatrace.getUserPrivacyOptions();
			optionsMap.put("dataCollectionLevel", options.getDataCollectionLevel().ordinal());
			optionsMap.put("crashReportingOptedIn", Boolean.valueOf(options.isCrashReportingOptedIn()));
		}

		return optionsMap;
	}

	private Boolean shouldWorkOnAndroid(Object platform) {
		return platform == null || ((int) platform) == PLATFORM_ANDROID;
	}

}
