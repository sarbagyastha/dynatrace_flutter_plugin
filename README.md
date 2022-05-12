[![N|Solid](https://assets.dynatrace.com/content/dam/dynatrace/misc/dynatrace_web.png)](https://dynatrace.com)

# Dynatrace Flutter Plugin
The Dynatrace Flutter plugin adds the Dynatrace OneAgent for Android and iOS to your Flutter app and provides an API to use [manual instrumentation](#usageMobileAgent) for Flutter/Dart data capturing.

## Requirements
* Flutter Version >= 1.12.0
* Gradle: >= 5.x
* Supported Webrequest Framework: Dart HttpClient

## Agent Versions
This agent versions are configured in this plugin:

* iOS Agent: 8.235.1.1015
* Android Agent: 8.231.2.1007

## <a name="importantNote"></a>**Important Note**

After installing the Dynatrace Flutter plugin via the [quick setup](#installPlugin) section, please follow the [manual instrumentation](#usageMobileAgent) API section as this implementation will be required to capture actions based on Flutter layer, i.e. widgets like buttons or gestures/user input.

For information on what is automatically captured in the native Android/iOS layer of your application, please see our [native layer](#native) section.

## Quick Setup

1. [Install plugin](#installPlugin)
2. [Setup configuration](#installationDynatrace)
3. [Start Flutter plugin](#startPlugin)
4. [Build and run your app](#buildAndRun)

## Startup
* [Plugin Startup](#startupConfig)
* [Manual OneAgent Startup](#manualStartup)

## Advanced topics

* [Native layer](#native)
* [Navigation Observer](#navigationObserver)
* [Manual instrumentation](#usageMobileAgent)
  * [Create Manual Action](#manualAction)
  * [Create Manual Subactions](#manualSubActions)
  * [Report Values and Errors](#reportValues)
  * [Manual Web Request Monitoring](#webRequest)
  * [Identify User](#identifyUser)
  * [Capture Zone Errors using startWithoutWidget](#zoneErrors)
  * [Crash Reporting](#crashReporting)
  * [User Privacy Options](#userPrivacy)
  * [Report GPS Position](#reportgps)
  * [Platform independent reporting](#platform)
* [Webrequest Behavior](#webrequest)
* [Custom Arguments](#customArguments)
* [Configuration structure](#configurationStructure)
  * [Define build stages](#buildStages)
  * [User Opt In Mode](#useroptin)
  * [OneAgent debug logs](#agentDebugLogs)
* [Maven Central in top-level gradle file](#mavenCentral)

## Troubleshooting
* [Known Issues](#issues)
* [Documentation](#documentation)
* [Report bug / Get support](#supportcase)


# Quick Setup

## <a name="installPlugin"></a>1. Install the plugin

Open the `pubspec.yaml` file located inside the app folder, and add `dynatrace_flutter_plugin:` under dependencies: 

```
dynatrace_flutter_plugin: ^1.202.0
```

After adding the dependency, resolve any dependencies if it hasn't happened automatically. 

* From the terminal, run `flutter pub get`.
* From Android Studio/IntelliJ, click **Packages get** in the action ribbon at the top of `pubspec.yaml`.
* From VS Code, click **Get Packages** located to the right of the action ribbon at the top of `pubspec.yaml`.

## <a name="installationDynatrace"></a>2. Set up `dynatrace.config.yaml`

* Create a mobile app in Dynatrace and open **Mobile app settings**. Go to Flutter configuration and download the configuration `dynatrace.config.yaml`. Store it in the root folder of your application.

### Data collection
By default, the [user opt-in mode](#useroptin) is activated in the configuration. This means that OneAgent only sends a limited number of actions until you change the [privacy mode](#datacollection).

## <a name="startPlugin"></a>3. Start the Flutter plugin

There are two start options to run our Flutter plugin. The Flutter plugin starts only when you directly call it via `start()` or `startWithoutWidget()`. 

`start({Configuration configuration})` takes an optional [configuration](#startupConfig) object to customize the behavior of the plugin. This configuration parameter can also be used for a [manual startup](#manualStartup). You can provide values such as `beaconUrl` or `applicationId` at runtime. `runApp()` is called internally.

`startWithoutWidget({Configuration configuration})` is similar to `start({Configuration configuration})`. The two differences are that it does not call `runApp()` internally (that is controlled by you) and zoned errors will not be captured automatically. However, uncaught errors will be captured by default. You should see the following in your application:

```dart
void main() => runApp(MyApp());
```

Replace it with one of the following statements:

Option 1:
```dart
import 'package:dynatrace_flutter_plugin/dynatrace_flutter_plugin.dart';

void main() => Dynatrace().start(MyApp());
```


Option 2:
```dart
import 'package:dynatrace_flutter_plugin/dynatrace_flutter_plugin.dart';

void main() {
  Dynatrace().startWithoutWidget();
  runApp(MyApp());
}
```


## <a name="installPlugin"></a>4. Build and run your app

Run `flutter pub run dynatrace_flutter_plugin` in the root of your Flutter project. This configures both Android and iOS projects with settings from `dynatrace.config.yaml`. If you want to see more logging, append or customize some paths via [custom arguments](#customArguments) while executing the command. 

> Before running your app, please see this [important Note](#importantNote) relating to capturing  Flutter/Dart user actions.

Call `flutter run` and the application starts including Dynatrace OneAgent.

# Startup

### <a name="startupConfig"></a>Plugin startup

The startup of the plugin is triggered via the `start(Widget _topLevelWidget, {Configuration configuration})` method. Without the start-up call, the plugin doesn't send data that is coming from the Flutter app part. The optional configuration parameters should only be used when doing a manual startup. The available options  which are offered by the Configuration constructor are listed in the following table:

```dart
Configuration(
  reportCrash: true,
  monitorWebRequest : true,
  logLevel: LogLevel.Info,
  beaconUrl,
  applicationId,
  certificateValidation: true;
  userOptIn: false;
)
```

| Property name    | Type   | Default     | Description                                       |
|------------------|--------|-------------|---------------------------------------------------|
|reportCrash       |bool    |true         |Reports automatically Dart and Flutter crashes.    |
|monitorWebRequest |bool    |true         |Monitors web requests in your Flutter application. |
|logLevel          |LogLevel|LogLevel.Info|Allows you to choose between `LogLevel.Info` and `LogLevel.Debug`. Debug returns more logs. This is especially important when something is not functioning correctly.|
|beaconUrl         |String  |null         |Identifies your environment within Dynatrace. This property is mandatory for [manual startup](#manualStartup). OneAgent issues an error when the key isn't present.|
|applicationId     |String  |null         |Identifies your mobile app. This property is mandatory for [manual startup](#manualStartup). OneAgent issues an error when the key isn't present.|
|certificateValidation|bool |true         |Allows the use of self-signed certificates. By default, it is set to false. When set to true, OneAgent accepts self-signed certificates that are not signed by a root-CA. This configuration key doesn't impact mobile app connections. It's only used for OneAgent communication, but doesn't overrule the host-name validation.|
|userOptIn        |bool     |false        |Activates the privacy mode when set to `true`. User consent must be queried and set. The privacy settings for [user privacy options](#userPrivacy) can be changed via OneAgent SDK for Mobile as described under Data privacy. The default value is `false`.|

**Note**: The values used for the parameters are their default value.

**Attention:** Please use those parameters only when doing a manual startup. If you want to do an automated startup, please configure the properties via the [auto startup configuration](#configurationStructure). You will find a list which explains all the counterparts for the available options here.

An example could look like the following:

```dart
import 'package:dynatrace_flutter_plugin/dynatrace_flutter_plugin.dart';

void main() => Dynatrace().start(MyApp(), Configuration: Configuration(logLevel: LogLevel.Debug));
```

### <a name="manualStartup"></a>Manual OneAgent startup

If you can't do a automated startup through the `dynatrace.config.yaml`, you can always perform a manual startup and decide values such as `beaconUrl` and `applicationId` at runtime. 

**Note**: An automated startup usually provides you with a lifecycle application start-up event. A manual startup on the other hand occurs later, thereby causing you to miss everything, including this application startup event, until the startup occurs.

A manual startup requires the following two steps:

1. Deactivate the automated startup in `dynatrace.config.yaml`: 

```yaml
android:
  config: 
    "dynatrace {
      configurations {
        defaultConfig {
          autoStart.enabled false
        }
      }
    }"
  
ios:
  config: 
    "<key>DTXAutoStart</key>
    <false/>"
```

2. Make the start-up call with at least `beaconUrl` and `applicationId`:

Example of a startup call:

```dart
import 'package:dynatrace_flutter_plugin/dynatrace_flutter_plugin.dart';

void main() => Dynatrace().start(MyApp(), Configuration: Configuration(beaconUrl: "..", applicationId: ".."));
```

**Note**: If you don't deactivate the automated startup with the `dynatrace.config.yaml` file, the `beaconUrl` and `applicationId` values have no impact and are thrown away.

# Advanced topics

## <a name="native"></a>Native layer

When using a native view like an Activity (Android) or View Controller (iOS) with native elements/controls, the Android/iOS agent that is running via the flutter plugin will capture these actions as they would in a native Android/iOS app out of the box. So if `autoStart` is set to true (default value), then you will likely see a `Loading <AppName>` action with the lifecycle events inside of the user action waterfall in the captured user session.

For more information on the the Android/iOS agents, please see our [documentation](#documentation) section.

## <a name="navigationObserver"></a>Navigation observer

To track navigations in your application, add `DynatraceNavigationObserver` to your `MaterialApp`:

```dart
MaterialApp(
  home: MyAppHome(),
  navigatorObservers: [
    DynatraceNavigationObserver(),
  ],
);
```

## <a name="usageMobileAgent"></a>Manual instrumentation

To use the API of the Flutter plugin, add the following import at the top of your `dart` file:

```dart
import 'package:dynatrace_flutter_plugin/dynatrace_flutter_plugin.dart';
```

### <a name="manualAction"></a>Create manual actions

To create a manual action named `"MyButton tapped"`, use the following code:

```dart
DynatraceRootAction myAction = Dynatrace().enterAction("MyButton tapped");
//Perform the action and whatever else is needed.
myAction.leaveAction();
```

**Note**: `leaveAction` closes the action again. To report values for this action before closing, see [Report values](#reportValues).

### <a name="manualSubAction"></a>Create manual sub-actions

You can create a single manual action and several sub-actions. `MyButton Sub Action` is automatically put under `MyButton tapped`. Only one sub-action level is allowed; you can't create a sub sub-action. 

```dart
DynatraceRootAction myAction = Dynatrace().enterAction("MyButton tapped");
DynatraceAction mySubAction = myAction.enterAction("MyButton Sub Action");

//Perform the action and whatever else is needed.
mySubAction.leaveAction();
myAction.leaveAction();
```

### <a name="reportValues"></a>Report values

You can report certain values for any open action. If you want to report a value without action reference skip to the [next section](#reportValuesWithoutAction). The following API is available for `DynatraceRootAction` and `DynatraceAction`:

```dart
void reportError(String errorName, int errorCode, {Platform platform})
void reportErrorStacktrace(
      String errorName, String errorValue, String reason, String stacktrace,
      {Platform platform});
void reportEvent(String eventName, {Platform platform})
void reportStringValue(String valueName, String value, {Platform platform})
void reportIntValue(String valueName, int value, {Platform platform})
void reportDoubleValue(String valueName, double value, {Platform platform})
```

To report a string value, use the following code:

```dart
DynatraceRootAction myAction = Dynatrace().enterAction("MyButton tapped");
myAction.reportStringValue("ValueName", "ImportantValue");
myAction.leaveAction();
```

The `{Platform platform}` optional parameter is available for API calls. This parameter offers the possibility to report values only for a specific platform. For more information, see [platform independent reporting](#platform).

### <a name="reportValuesWithoutAction"></a>Report values without action reference

This section shows an API that offers reporting of values directly with the main agent interface. Be aware that those methods are helper methods and are internally attaching the value to the latest opened action. If there is no open action, the value will not be reported.

```dart
void reportError(String errorName, int errorCode, {Platform platform})
void reportErrorStacktrace(
      String errorName, String errorValue, String reason, String stacktrace,
      {Platform platform});
void reportEvent(String eventName, {Platform platform})
void reportStringValue(String valueName, String value, {Platform platform})
void reportIntValue(String valueName, int value, {Platform platform})
void reportDoubleValue(String valueName, double value, {Platform platform})
```

To report a string value, use the following code:

```dart
Dynatrace().reportStringValue("ValueName", "ImportantValue");
```

The `{Platform platform}` optional parameter is available for API calls. This parameter offers the possibility to report values only for a specific platform. For more information, see [platform independent reporting](#platform).

### <a name="webRequest"></a>Manual Web Request Monitoring

**Note:** 
You should not manually and auto-instrument the same web requests. This behavior can lead to incorrect monitoring data. Auto-instrumentation automatically instruments **Dart HttpClient** based web requests. To turn off auto-instrumentation of web requests, see the **monitorWebRequest** in the [startup config section.](#startupConfig)

You can manually tag and time your web requests. By default, our plugin can capture web requests that are using the **Dart HttpClient**. With this API, you are able to manually capture the web requests if another framework is used or override the web request tag (x-dynatrace header value) and add the web request to a specific user action.  

```dart
// DynatraceRootAction and DynatraceAction
Future<WebRequestTiming> createWebRequestTiming(String url);
Future<String> getRequestTag(String url);
String getRequestTagHeader();

// WebRequestTiming
void startWebRequestTiming();
void stopWebRequestTiming(int responseCode, String? responseMessage);
String getRequestTag();
String getRequestTagHeader();
```

Example using full manual instrumentation of a web request:

**Note:** When using the full manual instrumentation for web requests, you will need to turn off the auto-instrumentation of web requests that is done with the flutter plugin. Please see the **monitorWebRequest** in the [startup config section](#startupConfig) for more information.

```dart
HttpClient client = HttpClient();
// Create an action
DynatraceRootAction action =
        Dynatrace().enterAction("MyButton tapped - Web Action");

// Create a timing object
WebRequestTiming timing = await action.createWebRequestTiming(url);

final request = await client.getUrl(Uri.parse(url));

// Add headers to the request
request.headers.set(timing.getRequestTagHeader(), timing.getRequestTag());

// Start timing the web request
timing.startWebRequestTiming();
final response = await request.close();

// Stop timing
timing.stopWebRequestTiming(response.statusCode, response.reasonPhrase));

// Leave the action
action.leaveAction();
```

Overriding the web request tag (x-dynatrace header value) to add the web request to a specific user action:

```dart
HttpClient client = HttpClient();
// Create an action
DynatraceRootAction action =
        Dynatrace().enterAction("MyButton tapped - Web Action");

final request = await client.getUrl(Uri.parse(url));

// Add headers to the request
request.headers.set(action.getRequestTagHeader(), await action.getRequestTag(url));

final response = await request.close();

// Leave the action
action.leaveAction();
```


### <a name="identifyUser"></a>Identify a user

You can identify a user and tag the current session with a name by making the following call:

```dart
Dynatrace().identifyUser("User XY");
```

### <a name="zoneErrors"></a>Capturing Zone Errors when using startWithoutWidget

When using the `startWithoutWidget` method to start the Dynatrace plugin, zone errors are not caught out of the box and needs to be manually added. Here is an example of how you would set this up:

```dart
main() {
  runZonedGuarded<Future<void>>(() async {
    Dynatrace().startWithoutWidget();
    runApp(MyApp());
  }, Dynatrace().reportZoneStacktrace);
```

### <a name="crashReporting"></a>Crash reporting

Crash reporting is enabled by default. Mobile OneAgent captures all unhandled exceptions and errors, and then, it immediately sends the error report to the server. To change this behavior via the API, enable [user opt-in](#useroptin) and set the [user privacy options](#userPrivacy). 

To report a crash manually, use the following API on a `Dynatrace()` instance:

---
```dart
Future<void> reportZoneStacktrace(dynamic error, StackTrace stacktrace);
Future<void> reportCrash(String errorName, String errorMessage, String stacktrace, {Platform platform});
```
---
<br>
Examples for the parameters are:

---
```dart
try {
  Fail();
} catch (exception, stacktrace) {
  await reportZoneStacktrace(exception, stacktrace);
}
```
<br>





### <a name="userPrivacy"></a>User Privacy Options 

If you want to use the user privacy options you need to enable the [user opt-in](#useroptin). By default, crash reporting is deactivated and the data-collection level is set to off, when enabling user opt-in mode. Based on your user's individual preferences, you can change the privacy settings when the app starts for the first time. Dynatrace doesn't provide a privacy dialog or any similar UI component. You must integrate the consent banner into your app. You must also allow your users to change their privacy settings in the future.

The API to get and set the current user privacy options looks like this:

```dart
Future<UserPrivacyOptions> getUserPrivacyOptions({Platform platform})
void applyUserPrivacyOptions(DataCollectionLevel dataCollectionLevel, bool crashReportingOptedIn, {Platform platform});
```

The privacy API methods allow you to dynamically change the data-collection level based on the individual preferences of your end users. crashReportingOptedIn enables or disables the crash reporting. dataCollectionLevel can be selected from three data-privacy levels:

```dart
enum DataCollectionLevel {
    Off,
    Performance,
    UserBehavior
}
```

* Off: Mobile OneAgent doesn't capture any monitoring data.
* Performance: Mobile OneAgent captures only anonymous performance data. Monitoring data that can be used to identify individual users, such as user tags and custom values, isn't captured.
* UserBehavior: Mobile OneAgent captures both performance and user data. In this mode, Mobile OneAgent recognizes and reports users who re-visit in future sessions.

A call to enable monitoring might look like the following:

```dart
Dynatrace().applyUserPrivacyOptions(DataCollectionLevel.UserBehavior, true);
```

### <a name="reportgps"></a>Report GPS location

You can report latitude and longitude and specify an optional platform. These coordinates will be used to have Dynatrace calculate the city that is closest to the reported GPS location. 

To manually set the coordinates of the user:
```dart
void setGPSLocation(double latitude, double longitude, {Platform platform})
```

For automatic capturing of GPS coordinates please see the platform specific sections below:

**Android:**<br>
If set to true, auto-instrumentation instruments your *LocationListener* classes and sends the captured location as metric to the server. The default value is false. To enable this feature to automatically capture location if your application gathers location based on *LocationListener* use the configuration shown [here.](https://www.dynatrace.com/support/help/shortlink/dynatrace-android-gradle-plugin-monitoring#location-monitoring)
https://www.dynatrace.com/support/help/technology-support/operating-systems/android/legacy-documentation/customization/advanced-settings-for-android-auto-instrumentation/#expand-3762auto-instrumentation-properties

**iOS:**<br>
Captures the location only if the app uses *CLLocationManager* and sends the captured location as a metric to the server. The OneAgent SDK for iOS doesn't perform GPS location capturing on its own; it only captures three fractional digits to protect the privacy of the end user. Set the value to false to disable location capturing. The default value is true.
https://www.dynatrace.com/support/help/technology-support/operating-systems/ios/customization/configuration-settings/#expand-3708configuration-keys

**Note:**
When location monitoring is disabled or no location information is available, Dynatrace uses IP addresses to determine the location of the user. For more information, click [here.](https://www.dynatrace.com/support/help/shortlink/detection#geolocations)

### <a name="platform"></a>Platform independent reporting

Each method has an additional optional parameter named `platform` of type `Platform`. Use this parameter to only trigger manual instrumentation for a specific OS. The available values are: `Platform.iOS` and `Platform.Android`. By default, it will work on any platform. Otherwise it is passed only to the relevant OS. For example:

* Passing to **iOS** only:
```dart
DynatraceAction myAction = Dynatrace().enterAction("MyButton tapped", Platform.iOS);
//Perform the action and whatever else is needed.
myAction.leaveAction("ios"); 
```
 
* Passing to **Android** only:
```dart
DynatraceAction myAction = Dynatrace().enterAction("MyButton tapped", Platform.Android);
//Perform the action and whatever else is needed.
myAction.leaveAction("android"); 
```
 
* Passing to **both**:
```dart
DynatraceAction myAction = Dynatrace().enterAction("MyButton tapped");
//Perform the action and whatever else is needed.
myAction.leaveAction(); 
```

## <a name="webrequest"></a>Webrequest behavior

Currently the Dynatrace Flutter plugin supports the default Dart HTTPClient:

```dart
await HttpClient()
  .getUrl(Uri.parse('http://TestUrl.com')) 
  .then((request) => request.close()) 
  .then((response) => print("Request Done"));
```

This block is the standard implementation for a web request and doesn't need any further modification. It is tracked automatically. The following rules for action linking are applicable:

* Root Action available: When you open a manual `DynatraceRootAction` before the request because the request is part of some user action, such as clicking a log-in button, the web request is linked to this `DynatraceRootAction`. If there are several `DynatraceRootActions` active, the request is linked to the newest one.
* Root Action not available: When you trigger a request and don't have any open `DynatraceRootAction`, the request is tagged without any action information. The only exception for this tagging is if there are Android or iOS native auto user actions available. In such a case, we take this one for linking. The amount of native auto user actions is rare for Flutter as they are only fired from native components. Therefore, the request usually stands on its own. It is linked to the session but as a root web request. It isn't directly visible in the user session view in the web UI but is associated and visible within the Network performance tile.

## <a name="customArguments"></a>Custom arguments

Our scripts assume that the usual Flutter project structure is standard. The following arguments can be specified for our instrumentation script if the project structure is different.

* `--debug`: Displays more log lines for the instrumentation script. Might be important if you have problems and want to get more information.
* `--gradle=C:\MyFlutterAndroidProject\build.gradle`: The location of the root build.gradle file. We assume that the other gradle file resides in `\app\build.gradle`. This adds  OneAgent dependencies automatically for you and updates the configuration.
* `--plist=C:\MyFlutterIOSProject\projectName\info.plist`: Indicates the location of the `info.plist` file. The `plist` file is used for updating the configuration for the OneAgent. 
* `--config=C:\SpecialFolderForDynatrace\dynatrace.config.yaml`: Indicates that the config file isn't in the root folder of the Flutter project.
* `--uninstall`: Removes files and references of Dynatrace that were added by our plugin. This includes the removal of the `dynatrace.config.yaml` file.

Example:

```
flutter pub run dynatrace_flutter_plugin --config=C:\SpecialFolderForDynatrace\dynatrace.config.yaml
```

## <a name="configurationStructure"></a>Structure of the `dynatrace.config.yaml` file
The configuration is structured in the following way:

```
android:
  // Configuration for Android auto instrumentation

ios:
  // Configuration for iOS auto instrumentation
```

### Manual Startup Counterparts

Here is a list of all the counterparts for the options that can be used with a manual startup. Below the counterparts table you will find an example configuration block for both Android and iOS.

| Property Name | Default | Android | iOS |
|---------------|------|---------|-------------|
|reportCrash|true|crashReporting|DTXCrashReporting|
|monitorWebRequest|true|webRequests.enabled|DTXInstrumentWebRequestTiming|
|logLevel|LogLevel.Info|debug.agentLogging|DTXLogLevel
|beaconUrl|null|autoStart.beaconUrl|DTXBeaconURL
|applicationId|null|autoStart.applicationId|DTXApplicationId|
|certificateValidation|false|debug.certificateValidation|DTXAllowAnyCert|
|userOptIn|false|userOptIn|DTXUserOptIn|

### Android Block

The Android block is a wrapper for the Android configuration. You can find it under **Mobile app settings** in the web UI. Copy the content into the following block:

```
android:
  config: "CONTENT_OF_ANDROID_CONFIG"
```

The content of the `config` block is directly copied to the gradle file. To know more about the possible configuration options, see the [DSL documentation](https://www.dynatrace.com/support/doc/javadoc/oneagent/android/gradle-plugin/dsl/) of our gradle plugin. 

The following block shows similar properties that can be used with manual startup but are used in auto startup configuration:

```
android:
  config: "dynatrace {
      configurations {
        defaultConfig {
          autoStart{
            applicationId 'xxx'
            beaconUrl 'xxx'
          }
          userOptIn false
          crashReporting true
          debug.agentLogging true
          debug.certificateValidation true
          webRequests.enabled true
        }
      }
    }"
```

### iOS Block

The iOS block is a wrapper for the iOS configuration. You can find it under **Mobile app settings** in the web UI. Copy the content into the following block:

```
ios:
  config: "CONTENT_OF_IOS_CONFIG"
};
```

The content of the `config` block is directly copied to the plist file, so you can use all the settings and properties listed in our official [iOS Agent documentation](#documentation).

The following block shows similar properties that can be used with manual startup but are used in auto startup configuration:

```
ios:
  config: "
    <key>DTXBeaconURL</key>
    <string>xxx</string>
    <key>DTXApplicationId</key>
    <string>xxx</string>
    <key>DTXLogLevel</key>
    <string>ALL</string>
    <key>DTXUserOptIn</key>
    <true/>
    <key>DTXCrashReporting</key>
    <true/>
    <key>DTXAllowAnyCert</key>
    <true/>
    <key>DTXInstrumentWebRequestTiming</key>
    <false/>"
};
```

## <a name="buildStages"></a>Define build stages in `dynatrace.config.yaml`

If you have several stages like debug, QA, and production, use a different configuration to separate them and have each stage report into different applications in the web UI.

### Android

In Android, you can enter all the information in the config file. So the following `dynatrace {}` block must be inserted into the android `config` variable in your `dynatrace.config.yaml` file.

```
android:
  config: "
    dynatrace {
      configurations {
        dev {
            variantFilter "Debug" // build type name is upper case because a product flavor is used
            // other variant-specific properties
        }
        demo {
            variantFilter "demo" // the first product flavor name is always lower case
            // other variant-specific properties
        }
        prod {
            variantFilter "Release" // build type name is upper case because a product flavor is used
            // other variant-specific properties
        }
      }
    }
  "
```

This results into the following:

```
> Task :app:printVariantAffiliation
Variant 'demoDebug' will use configuration 'dev'
Variant 'demoRelease' will use configuration 'demo'
Variant 'paidDebug' will use configuration 'dev'
Variant 'paidRelease' will use configuration 'prod'
```

In all these blocks, you can define your different application IDs. You can even use a different environment.

### iOS

In iOS, you can define some variables in the `dynatrace.config.yaml` file. These variables must then be inserted into a prebuild script. The following properties must be inserted into the iOS `config` variable in your `dynatrace.config.yaml` file.

```
ios:
  config: "
  <key>DTXApplicationID</key>
  <string>${APPLICATION_ID}</string>
  <key>DTXBeaconURL</key>
  <string>Your Beacon URL</string>
  "
}
```

The `${APPLICATION_ID}` variable must then be inserted with a prebuild script. For more information on this, read https://medium.com/@andersongusmao/xcode-targets-with-multiples-build-configuration-90a575ddc687.

## <a name="useroptin"></a>User opt-in mode

Allows the user to opt in for monitoring. When enabled, specify the privacy settings. For more information, see the [user privacy options section](#userPrivacy).

### Android

```
android:
  config: "
    dynatrace {
      configurations {
        defaultConfig {
          autoStart{
            ...
          }
          userOptIn true
        }
      }
    }
  "
}
```

### iOS

```
ios:
  config: "
  <key>DTXUserOptIn</key>
  <true/>
  "
}
```

## <a name="agentDebugLogs"></a>Mobile OneAgent debug logs

If the instrumentation runs through and your application starts but you see no data, you must investigate and find out the reason the mobile agents are not sending any data. You can always open a support ticket, but we strongly recommend that you first collect logs. 

The whole structure is visible, so you can see where the config belongs.

### Android

Add the following configuration snippet to your other configuration in `dynatrace.config.yaml` and run `flutter pub run dynatrace_flutter_plugin` in the root of your Flutter project:

```
android:
  config: "
    dynatrace {
      configurations {
        defaultConfig {
          autoStart{
            ...
          }
          debug.agentLogging true
        }
      }
    }
  "
}
```

### iOS

Add the following configuration snippet to your other configuration in `dynatrace.config.yaml` and run `flutter pub run dynatrace_flutter_plugin` in the root of your Flutter project:

```
ios:
  config: "
  <key>DTXLogLevel</key>
  <string>ALL</string>
  "
}
```

## <a name="mavenCentral"></a>Maven Central in top-level gradle file

Because the Dynatrace Android agent now requires the MavenCentral repository, if either `jcenter()` or `mavenCentral()` is not added inside of **ALL** the repositories blocks via the [top-level build.gradle](https://dt-url.net/jm610pso), the build will fail. 
Below is an example of what a basic [top-level build.gradle](https://dt-url.net/jm610pso) file should look like after adding `mavenCentral()` to all repository blocks:

![mavenCentralFlutter](https://dt-cdn.net/images/mavencentralflutter-548-bc6032e7aa.png)

The location of the [top-level build.gradle](https://dt-url.net/jm610pso) should be:
* `<rootOfProject>\android\build.gradle`

**Note:**
JCenter has noted its [sunset](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/) on May 1st. Though, JCenter is still syncing with Maven Central so having`jcenter()` in your **build.gradle** file without the use of `mavenCentral()` will retrieve the Dynatrace Android Gradle Plugin no problem.


## <a name="issues"></a>Known issues

* `OneAgent SDK version X does not match Dynatrace Android Gradle plugin version X`: You've probably upgraded the Flutter package. Call `flutter pub run dynatrace_flutter_plugin` again so that the dependencies in the gradle are updated.
* `I'm not seeing any captured user actions for flutter widgets or flutter/dart gestures/user input`: See this [important note](#importantNote) relating to flutter/dart user actions and [manual instrumentation](#usageMobileAgent).
* For Android, if you see an error like "Gradle sync failed: Could not find com.dynatrace.tools.android:gradle-plugin:8.225.1.1004.", please see the [MavenCentral](#mavenCentral) section for an example and more information.


## <a name="documentation"></a>Dynatrace documentation
The documentation for OneAgent for Android and iOS is available at the following locations:
* Android: https://www.dynatrace.com/support/help/setup-and-configuration/oneagent/android/
* iOS: https://www.dynatrace.com/support/help/setup-and-configuration/oneagent/ios/

**Note:**
The Dynatrace Android Gradle plugin is hosted on [Maven Central](https://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22com.dynatrace.tools.android%22%20AND%20a%3A%22gradle-plugin%22). JCenter has noted it's [sunset](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/) on May 1st so Maven Central is the primary source of the Dynatrace Android Gradle plugin.

## <a name="supportcase"></a>Report a bug or open a support case

For issues, open a support ticket at support.dynatrace.com and provide us with the following details:
* Logs from [Mobile OneAgent](#agentDebugLogs)
* Your `dynatrace.config.yaml` file



