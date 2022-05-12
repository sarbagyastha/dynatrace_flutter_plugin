import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'action/null_web_request_timing.dart';
import 'interface/web_request_timing.dart';
import 'action/web_request_timing.dart';
import 'model/configuration.dart';
import 'http/http_instrumentation.dart';
import 'interface/agent_interface.dart';
import 'action/null_actions/null_root_action_impl.dart';
import 'model/data_collection_level.dart';
import 'model/log_level.dart';
import 'model/user_privacy_options.dart';
import 'util/logger.dart';
import 'util/string_utils.dart';
import 'action/action.dart';
import 'action/counter.dart';
import 'action/interface/root_action.dart';
import 'model/platform.dart';

class DynatraceImpl implements Dynatrace {
  static Dynatrace? _instance;
  final MethodChannel _methodChannel;

  final Function _startupUpFunction;

  bool _started = false;
  bool _crashReporting = true;

  factory DynatraceImpl() {
    if (_instance == null) {
      final MethodChannel _methodChannel =
          const MethodChannel('dynatrace_flutter_plugin/dynatrace');
      DynatraceImpl.private(_methodChannel);
    }

    return _instance as DynatraceImpl;
  }

  DynatraceImpl.private(this._methodChannel,
      {Function startUpFunction = runApp})
      : _startupUpFunction = startUpFunction {
    _instance = this;
  }

  /// Returns if the plugin is already enabled or not. This depends if
  /// there is a configuration available which will only be set in the start
  /// method.
  bool _isEnabled() {
    return _started;
  }

  Future<void> start(Widget topLevelWidget,
      {Configuration configuration = const Configuration()}) async {
    // If our plugin fails to intialize, allow the app to run like normal
    await runZonedGuarded<Future<void>>(() async {
      await setConfig(configuration: configuration);
      _startupUpFunction(topLevelWidget);
    }, Dynatrace().reportZoneStacktrace);
  }

  Future<void> startWithoutWidget(
      {Configuration configuration = const Configuration()}) {
    return setConfig(configuration: configuration);
  }

  Future<void> setConfig(
      {bool crashReport = true,
      Configuration configuration = const Configuration()}) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      Map<String, bool>? autoStartConfiguration =
          await _methodChannel.invokeMapMethod("getAutoStartConfiguration");

      if (!_isEnabled()) {
        _started = true;

        if (autoStartConfiguration!["autoStart"]!) {
          // Take over the log level of native agent
          configuration = Configuration(
              logLevel: autoStartConfiguration["logLevel"]!
                  ? LogLevel.Debug
                  : LogLevel.Info,
              reportCrash: autoStartConfiguration["crashReporting"]!,
              monitorWebRequest: autoStartConfiguration["webRequest"]!);
        } else {
          if (configuration.isAutoStartPropertyAvailable) {
            // We need to do a manual startup if it is available
            _methodChannel.invokeMethod(
                "start", configuration.getStartupConfiguration());
          }
        }

        Logger().logLevel = configuration.logLevel;

        if (configuration.isWebRequestMonitoringEnabled) {
          // Override the HTTP communication with our handler
          HttpOverrides.global = new DynatraceHttpOverrides(_instance!);
        } else {
          Logger().d("Webrequest Instrumentation deactivated.",
              logType: LogType.Info);
        }

        _crashReporting = configuration.isCrashReportingEnabled;

        if (!configuration.isCrashReportingEnabled) {
          Logger().d("Crash reporting deactivated.", logType: LogType.Info);
        } else {
          // Overrides FlutterError.onError to capture unhandled exceptions and report them
          enableFlutterErrorCapturing();
        }
      }

      Logger().i("Dynatrace Flutter Plugin started!", logType: LogType.Info);
    } catch (e) {
      Logger().i(
          "Dynatrace Flutter Plugin failed to initialize. Error: ${e.toString()}",
          logType: LogType.Error);
      _crashReporting = false;
      _started = false;
    }
  }

  void enableFlutterErrorCapturing() {
    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.dumpErrorToConsole(details, forceReport: true);
      if (_crashReporting) {
        return reportErrorStacktrace(
            details.exception.runtimeType.toString() +
                ": " +
                details.summary.toString(),
            details.exception.runtimeType.toString(),
            details.summary.toString(),
            details.stack.toString());
      }
    };
  }

  DynatraceRootAction enterAction(String name, {Platform? platform}) {
    if (!_isEnabled()) {
      Logger().i(
          "Dynatrace().start() method was not called! Action will have no effect.",
          logType: LogType.Warning);
      return DynatraceNullRootAction();
    }

    if (StringUtils.isStringNullOrEmpty(name)) {
      Logger().d("Action Name was empty or null! Action will have no effect.",
          logType: LogType.Error);
      return DynatraceNullRootAction();
    }

    int key = ActionCounter().getNewActionId();
    DynatraceRootAction action =
        DynatraceRootActionImpl.private(key, _methodChannel);
    ActionCounter().setOpenAction(key, action);

    _methodChannel.invokeMethod("enterAction", <String, dynamic>{
      "name": name,
      "key": key,
      "platform": platform != null ? platform.index : null
    });

    return action;
  }

  Future<String?> getHTTPTagForWebRequest(String url) async {
    return await _methodChannel.invokeMethod(
        "getRequestTagForInterceptor", <String, dynamic>{"url": url});
  }

  WebRequestTiming createWebRequestTiming(String header, String url) {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);

      return NullWebRequestTiming();
    }

    return DynatraceWebRequestTiming(header, url, _methodChannel);
  }

  void reportStringValue(String? valueName, String? value,
      {Platform? platform}) {
    if (ActionCounter().getCurrentAction().runtimeType !=
        DynatraceNullRootAction) {
      ActionCounter().getCurrentAction().reportStringValue(valueName, value);
    } else {
      Logger().d("There are no open actions! String cannot be reported!",
          logType: LogType.Error);
    }
  }

  void reportIntValue(String? valueName, int? value, {Platform? platform}) {
    if (ActionCounter().getCurrentAction().runtimeType !=
        DynatraceNullRootAction) {
      ActionCounter().getCurrentAction().reportIntValue(valueName, value);
    } else {
      Logger().d("There are no open actions! Int cannot be reported!",
          logType: LogType.Error);
    }
  }

  void reportDoubleValue(String? valueName, double? value,
      {Platform? platform}) {
    if (ActionCounter().getCurrentAction().runtimeType !=
        DynatraceNullRootAction) {
      ActionCounter().getCurrentAction().reportDoubleValue(valueName, value);
    } else {
      Logger().d("There are no open actions! Double cannot be reported!",
          logType: LogType.Error);
    }
  }

  void reportEvent(String? eventName, {Platform? platform}) {
    if (ActionCounter().getCurrentAction().runtimeType !=
        DynatraceNullRootAction) {
      ActionCounter().getCurrentAction().reportEvent(eventName);
    } else {
      Logger().d("There are no open actions! Event cannot be reported!",
          logType: LogType.Error);
    }
  }

  void reportErrorInAction(String? errorName, int? errorCode,
      {Platform? platform}) {
    if (ActionCounter().getCurrentAction().runtimeType !=
        DynatraceNullRootAction) {
      ActionCounter().getCurrentAction().reportError(errorName, errorCode);
    } else {
      Logger().d("There are no open actions! Error cannot be reported!",
          logType: LogType.Error);
    }
  }

  void reportError(String? errorName, int? errorCode, {Platform? platform}) {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
      return;
    }

    if (!StringUtils.isStringNullOrEmpty(errorName) && errorCode != null) {
      _methodChannel.invokeMethod("reportError", <String, dynamic>{
        "errorName": errorName,
        "errorCode": errorCode,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "Error was not reported! ErrorName: $errorName errorCode: $errorCode",
          logType: LogType.Error);
    }
  }

  void reportErrorStacktrace(
      String errorName, String errorValue, String reason, String stacktrace,
      {Platform? platform}) {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
      return;
    }

    if (!StringUtils.isStringNullOrEmpty(errorName)) {
      _methodChannel.invokeMethod("reportErrorStacktrace", <String, dynamic>{
        "errorName": errorName,
        "errorValue": errorValue,
        "reason": reason,
        "stacktrace": stacktrace,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "Error will not be reported because something is missing! errorName: $errorName reason: $reason stacktrace: $stacktrace",
          logType: LogType.Error);
    }
  }

  Future<void> reportZoneStacktrace(dynamic error, StackTrace stacktrace,
      {Platform? platform}) async {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
    }

    if (_crashReporting && error != null) {
      await _methodChannel
          .invokeMethod("reportErrorStacktrace", <String, dynamic>{
        "errorName":
            error.runtimeType.toString() + ": " + error.message.toString(),
        "errorValue": error.runtimeType.toString(),
        "reason": error.message.toString(),
        "stacktrace": stacktrace.toString(),
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "Error will not be reported because something is missing! errorName: $error stacktrace: $stacktrace",
          logType: LogType.Error);
    }
  }

  Future<void> reportCrashWithException(
      String crashName, Exception exceptionObject,
      {String? reason = "-", Platform? platform}) async {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
    }

    if (!StringUtils.isStringNullOrEmpty(crashName) &&
        !StringUtils.isStringNullOrEmpty(exceptionObject.toString())) {
      if (_crashReporting) {
        await _methodChannel
            .invokeMethod("reportCrashWithException", <String, dynamic>{
          "crashName": crashName,
          "reason": reason,
          "stacktrace": exceptionObject.toString(),
          "platform": platform != null ? platform.index : null
        });
      }
    } else {
      Logger().d(
          "Crash will not be reported because something is missing! crashName: $crashName exceptionObject: ${exceptionObject.toString()} reason:${reason != "-" ? reason : "named/optional parameter not used"}",
          logType: LogType.Error);
    }
  }

  Future<void> reportCrash(String? errorName, String reason, String stacktrace,
      {Platform? platform}) async {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
    }

    if (!StringUtils.isStringNullOrEmpty(errorName)) {
      if (_crashReporting) {
        await _methodChannel.invokeMethod("reportCrash", <String, dynamic>{
          "errorValue": errorName,
          "reason": reason,
          "stacktrace": stacktrace,
          "platform": platform != null ? platform.index : null
        });
      }
    } else {
      Logger().d(
          "Crash will not be reported because something is missing! errorName: $errorName reason: $reason stacktrace: $stacktrace",
          logType: LogType.Error);
    }
  }

  void endSession({Platform? platform}) {
    if (_isEnabled()) {
      _methodChannel.invokeMethod("endVisit", <String, dynamic>{
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
    }
  }

  void identifyUser(String? user, {Platform? platform}) {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
      return;
    }

    _methodChannel.invokeMethod("identifyUser", <String, dynamic>{
      "user": user,
      "platform": platform != null ? platform.index : null
    });
  }

  void setGPSLocation(double latitude, double longitude, {Platform? platform}) {
    if (!_isEnabled()) {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
      return;
    }

    _methodChannel.invokeMethod("setGPSLocation", <String, dynamic>{
      "latitude": latitude,
      "longitude": longitude,
      "platform": platform != null ? platform.index : null
    });
  }

  void flushEvents({Platform? platform}) {
    if (_isEnabled()) {
      _methodChannel.invokeMethod("flushEvents", <String, dynamic>{
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().i("Dynatrace().start() method was not called!",
          logType: LogType.Warning);
    }
  }

  void applyUserPrivacyOptions(UserPrivacyOptions userPrivacyOptions,
      {Platform? platform}) {
    if (_isEnabled()) {
      _methodChannel.invokeMethod("applyUserPrivacyOptions", <String, dynamic>{
        "crashReportingOptedIn": userPrivacyOptions.crashReportingOptedIn,
        "dataCollectionLevel": userPrivacyOptions.dataCollectionLevel.index == 3
            ? 2
            : userPrivacyOptions.dataCollectionLevel.index,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().i(
          "Dynatrace().start() method was not called! User Privacy Options can't be applied!",
          logType: LogType.Warning);
    }
  }

  Future<UserPrivacyOptions> getUserPrivacyOptions({Platform? platform}) async {
    if (_isEnabled()) {
      Map<String, dynamic>? userPrivacyOptions = await (_methodChannel
          .invokeMapMethod("getUserPrivacyOptions", <String, dynamic>{
        "platform": platform != null ? platform.index : null
      }));

      if (userPrivacyOptions != null) {
        return new UserPrivacyOptions(
            DataCollectionLevel
                .values[userPrivacyOptions["dataCollectionLevel"]],
            userPrivacyOptions["crashReportingOptedIn"]);
      } else {
        Logger().i(
            "User Privacy Options called failed! Returning default values!",
            logType: LogType.Warning);
        return new UserPrivacyOptions(DataCollectionLevel.Off, false);
      }
    } else {
      Logger().i(
          "Dynatrace().start() method was not called! User Privacy Options are not available!",
          logType: LogType.Warning);
      return new UserPrivacyOptions(DataCollectionLevel.Off, false);
    }
  }
}
