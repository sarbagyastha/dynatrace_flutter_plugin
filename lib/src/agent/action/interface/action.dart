import 'package:dynatrace_flutter_plugin/src/agent/interface/web_request_timing.dart';

import '../../model/platform.dart';

/// Dynatrace action which has a start- and end-time and can
/// report several values onto it. When finished call leaveAction.
abstract class DynatraceAction {
  /// Reports an event with a specified [eventName] (but without any value).
  void reportEvent(String? eventName, {Platform? platform});

  /// Reports an int [value] with a specified [valueName].
  void reportIntValue(String? valueName, int? value, {Platform? platform});

  /// Reports a double [value] with a specified [valueName].
  void reportDoubleValue(String? valueName, double? value,
      {Platform? platform});

  /// Reports a String [value] with a specified [valueName].
  void reportStringValue(String? valueName, String? value,
      {Platform? platform});

  /// Reports an error with a specified [errorName], [errorCode].
  void reportError(String? errorName, int? errorCode, {Platform? platform});

  /// Returns a unique x-dynatrace header for the web request with a specified [url].
  Future<String> getRequestTag(String url);

  /// Returns the header key that needs to be added to the web request for user action/purepath correlation.
  String getRequestTagHeader();

  /// Returns a webrequest timing object which can be used to measure a web request. Input the [url] of the web request.
  Future<WebRequestTiming> createWebRequestTiming(String url);

  /// Leaves this action.
  void leaveAction();

  // Cancel this action.
  void cancel();
}
