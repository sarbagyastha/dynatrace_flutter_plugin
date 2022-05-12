import 'package:dynatrace_flutter_plugin/src/agent/model/user_privacy_options.dart';
import 'package:flutter/widgets.dart';
import '../model/configuration.dart';
import '../agent_impl.dart';
import '../model/platform.dart';
import '../action/interface/root_action.dart';

/// The main API of the flutter plugin which gives access
/// to the functions of the native agents.
abstract class Dynatrace {
  /// Factory which creates a [Dynatrace] object which is able to do the native
  /// communication with the Mobile Agents.
  factory Dynatrace() => DynatraceImpl();

  /// Start function which should be called to start the agent. The [topLevelWidget]
  /// is the widget which is starting the application. The Configuration contains
  /// default values for all properties. reportCrash value is true per default.
  /// monitorWebRequest is true per default.
  Future<void> start(Widget topLevelWidget, {Configuration configuration});

  /// Start function which should be called to start the agent. This option will capture uncaught
  /// exceptions but will not capture zoned errors. The Configuration contains
  /// default values for all properties. reportCrash value is true per default.
  /// monitorWebRequest is true per default.
  Future<void> startWithoutWidget({Configuration configuration});

  /// Creating a [DynatraceRootAction] which is able to have child actions. If
  /// you enter [null] or an empty [String] for the [name] you will get a root action
  /// which will be disabled.
  DynatraceRootAction enterAction(String name, {Platform? platform});

  /// Reports an int [value] with a specified [valueName].
  void reportIntValue(String? valueName, int? value, {Platform? platform});

  /// Reports a double [value] with a specified [valueName].
  void reportDoubleValue(String? valueName, double? value,
      {Platform? platform});

  /// Reports a String [value] with a specified [valueName].
  void reportStringValue(String? valueName, String? value,
      {Platform? platform});

  /// Reports an event with a specified [eventName] (but without any value).
  void reportEvent(String? eventName, {Platform? platform});

  /// Reports an error with a specified [errorName], [errorCode].
  void reportErrorInAction(String? errorName, int? errorCode,
      {Platform? platform});

  /// Report an error with [errorName] and [errorCode] directly without any action.
  void reportError(String? errorName, int? errorCode, {Platform? platform});

  /// Report an error with [errorName], [errorValue], [reason] and [stacktrace] directly without any action.
  void reportErrorStacktrace(
      String errorName, String errorValue, String reason, String stacktrace,
      {Platform? platform});

  /// Report an error with [error] and [stacktrace] inside of a zone.
  Future<void> reportZoneStacktrace(dynamic error, StackTrace stacktrace,
      {Platform? platform});

  /// Report an error which contains an [exceptionObject] and will therefor be reported as a real
  /// crash. The error includes [crashName] as well as [reason] if you include it.
  Future<void> reportCrashWithException(
      String crashName, Exception exceptionObject,
      {String? reason, Platform? platform});

  /// Report an error which contains a [stacktrace] and will therefor be reported as a real
  /// crash. The error includes [errorName] and [reason] as well.
  Future<void> reportCrash(String? errorName, String reason, String stacktrace,
      {Platform? platform});

  /// Closes the session in the next possible moment.
  void endSession({Platform? platform});

  /// Will attach a [user] to the session so you can identify the session later on.
  void identifyUser(String? user, {Platform? platform});

  /// Sets the GPS location of the session with [latitude] and [longitude].
  void setGPSLocation(double latitude, double longitude, {Platform? platform});

  /// Retrieve the currently used user privacy options.
  Future<UserPrivacyOptions> getUserPrivacyOptions({Platform? platform});

  /// Applies the specified [userPrivacyOptions] which contains information about
  /// crash reporting and data collection level.
  void applyUserPrivacyOptions(UserPrivacyOptions userPrivacyOptions,
      {Platform? platform});

  /// Send events if necessary.
  void flushEvents({Platform? platform});
}
