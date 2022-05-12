import 'package:dynatrace_flutter_plugin/src/agent/interface/web_request_timing.dart';

import '../interface/action.dart';
import '../interface/root_action.dart';
import '../null_web_request_timing.dart';
import './null_action_impl.dart';
import '../../model/platform.dart';

class DynatraceNullRootAction implements DynatraceRootAction {
  @override
  DynatraceAction enterAction(String? actionName, {Platform? platform}) {
    return DynatraceNullAction();
  }

  @override
  void leaveAction() {
    return;
  }

  @override
  void cancel() {
    return;
  }

  @override
  void reportDoubleValue(String? valueName, double? value,
      {Platform? platform}) {
    return;
  }

  @override
  void reportError(String? errorName, int? errorCode, {Platform? platform}) {
    return;
  }

  @override
  void reportEvent(String? eventName, {Platform? platform}) {
    return;
  }

  @override
  void reportIntValue(String? valueName, int? value, {Platform? platform}) {
    return;
  }

  @override
  void reportStringValue(String? valueName, String? value,
      {Platform? platform}) {
    return;
  }

  @override
  Future<String> getRequestTag(String url) async {
    return "";
  }

  @override
  String getRequestTagHeader() {
    return "";
  }

  @override
  Future<WebRequestTiming> createWebRequestTiming(String url) {
    return Future.value(NullWebRequestTiming());
  }
}
