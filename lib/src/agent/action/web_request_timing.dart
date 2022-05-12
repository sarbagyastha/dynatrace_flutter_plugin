import 'package:dynatrace_flutter_plugin/src/agent/interface/web_request_timing.dart';

import '../util/logger.dart';
import '../util/string_utils.dart';

import 'package:flutter/services.dart';

class DynatraceWebRequestTiming extends WebRequestTiming {
  final MethodChannel _methodChannel;
  final String _requestTag;
  final String _url;

  DynatraceWebRequestTiming(this._requestTag, this._url, this._methodChannel);

  // Starts the timing of a web request on a user action.
  void startWebRequestTiming() {
    if (_requestTag != "" && !StringUtils.isStringNullEmptyOrWhitespace(_url)) {
      _methodChannel.invokeMethod("startWebRequestTiming",
          <String, dynamic>{"requestTag": _requestTag, "url": _url});
    } else {
      Logger().d("Web Request Timing could not be created!",
          logType: LogType.Error);
    }
  }

  // Stops the timing of a web request on a user action.
  void stopWebRequestTiming(int responseCode, String? responseMessage) {
    if (_requestTag != "" && !StringUtils.isStringNullEmptyOrWhitespace(_url)) {
      _methodChannel.invokeMethod("stopWebRequestTiming", <String, dynamic>{
        "requestTag": _requestTag,
        "url": _url,
        "responseCode": responseCode,
        "responseMessage": responseMessage
      });
    } else {
      Logger().d(
          "Web Request Timing could not be stopped!" +
              "- Request Tag: $_requestTag Url: $_url responseCode: $responseCode responseMessage: $responseMessage",
          logType: LogType.Error);
    }
  }

  @override
  String getRequestTag() {
    return _requestTag;
  }

  @override
  String getRequestTagHeader() {
    return "x-dynatrace";
  }
}
