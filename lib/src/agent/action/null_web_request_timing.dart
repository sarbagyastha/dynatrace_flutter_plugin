import 'package:dynatrace_flutter_plugin/src/agent/interface/web_request_timing.dart';

class NullWebRequestTiming extends WebRequestTiming {
  @override
  void startWebRequestTiming() {
    return;
  }

  @override
  void stopWebRequestTiming(int responseCode, String? responseMessage) {
    return;
  }

  @override
  String getRequestTag() {
    return "";
  }

  @override
  String getRequestTagHeader() {
    return "";
  }
}
