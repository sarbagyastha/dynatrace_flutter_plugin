import 'package:dynatrace_flutter_plugin/src/agent/action/web_request_timing.dart';
import 'package:dynatrace_flutter_plugin/src/agent/interface/web_request_timing.dart';

import '../util/logger.dart';

import 'null_actions/null_action_impl.dart';
import '../util/string_utils.dart';
import 'package:flutter/services.dart';
import '../model/platform.dart';
import 'interface/action.dart';
import 'counter.dart';
import 'interface/root_action.dart';

class DynatraceRootActionImpl extends DynatraceActionImpl
    implements DynatraceRootAction {
  DynatraceRootActionImpl.private(int _key, MethodChannel _methodChannel)
      : super.private(_key, _methodChannel);

  @override
  DynatraceAction enterAction(String? actionName, {Platform? platform}) {
    if (_closed) {
      Logger().d("Action was closed already! Child action will have no effect.",
          logType: LogType.Warning);
      return DynatraceNullAction();
    }

    if (StringUtils.isStringNullOrEmpty(actionName)) {
      Logger().d(
          "Action name was empty or null! Child action will have no effect.",
          logType: LogType.Warning);
      return DynatraceNullAction();
    }

    int newKey = ActionCounter().getNewActionId();
    DynatraceAction action =
        DynatraceActionImpl.private(newKey, _methodChannel);
    ActionCounter().setOpenAction(newKey, action);

    _methodChannel.invokeMethod("enterAction", <String, dynamic>{
      "name": actionName,
      "key": newKey,
      "parent": _key,
      "platform": platform != null ? platform.index : null
    });

    return action;
  }

  @override
  Future<WebRequestTiming> createWebRequestTiming(String url) async {
    String? tag = await getRequestTag(url);
    return DynatraceWebRequestTiming(tag, url, _methodChannel);
  }
}

class DynatraceActionImpl implements DynatraceAction {
  final int _key;
  final MethodChannel _methodChannel;
  bool _closed = false;

  DynatraceActionImpl.private(this._key, this._methodChannel);

  @override
  void reportError(String? errorName, int? errorCode, {Platform? platform}) {
    if (_closed) {
      Logger().d(
          "Action was closed already! Error can not be reported on this action!",
          logType: LogType.Error);
      return;
    }

    if (!StringUtils.isStringNullOrEmpty(errorName) && errorCode != null) {
      _methodChannel.invokeMethod("reportErrorInAction", <String, dynamic>{
        "key": _key,
        "errorName": errorName,
        "errorCode": errorCode,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "Error was not reported! ErrorName:$errorName errorCode:$errorCode",
          logType: LogType.Error);
    }
  }

  @override
  void reportEvent(String? eventName, {Platform? platform}) {
    if (_closed) {
      Logger().d(
          "Action was closed already! Event can not be reported on this action!",
          logType: LogType.Error);
      return;
    }
    if (!StringUtils.isStringNullOrEmpty(eventName)) {
      _methodChannel.invokeMethod("reportEventInAction", <String, dynamic>{
        "key": _key,
        "name": eventName,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "Event was not reported because of missing name! EventName:$eventName",
          logType: LogType.Error);
    }
  }

  @override
  void reportStringValue(String? valueName, String? value,
      {Platform? platform}) {
    if (_closed) {
      Logger().d(
          "Action was closed already! String can not be reported on this action!",
          logType: LogType.Error);
      return;
    }

    if (!StringUtils.isStringNullOrEmpty(valueName)) {
      _methodChannel
          .invokeMethod("reportStringValueInAction", <String, dynamic>{
        "key": _key,
        "name": valueName,
        "value": value,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "String was not reported because of missing values! ValueName:$valueName Value:$value",
          logType: LogType.Error);
    }
  }

  @override
  void reportIntValue(String? valueName, int? value, {Platform? platform}) {
    if (_closed) {
      Logger().d(
          "Action was closed already! Integer can not be reported on this action!",
          logType: LogType.Error);
      return;
    }

    if (!StringUtils.isStringNullOrEmpty(valueName) && value != null) {
      _methodChannel.invokeMethod("reportIntValueInAction", <String, dynamic>{
        "key": _key,
        "name": valueName,
        "value": value,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "Integer was not reported because of missing values! ValueName:$valueName Value:$value",
          logType: LogType.Error);
    }
  }

  @override
  void reportDoubleValue(String? valueName, double? value,
      {Platform? platform}) {
    if (_closed) {
      Logger().d(
          "Action was closed already! Double can not be reported on this action!",
          logType: LogType.Error);
      return;
    }

    if (!StringUtils.isStringNullOrEmpty(valueName) && value != null) {
      _methodChannel
          .invokeMethod("reportDoubleValueInAction", <String, dynamic>{
        "key": _key,
        "name": valueName,
        "value": value,
        "platform": platform != null ? platform.index : null
      });
    } else {
      Logger().d(
          "Double was not reported because of missing values! ValueName:$valueName Value:$value",
          logType: LogType.Error);
    }
  }

  @override
  void leaveAction() {
    if (_closed) {
      Logger().d("Action was closed already! Can not leave the action again!",
          logType: LogType.Error);
      return;
    }

    _closed = true;
    _methodChannel.invokeMethod("leaveAction", <String, dynamic>{"key": _key});
    ActionCounter().removeClosedAction(_key);
  }

  @override
  void cancel() {
    if (_closed) {
      Logger().d(
          "Action was closed already! Can not cancel the action anymore!",
          logType: LogType.Error);
      return;
    }

    _closed = true;
    _methodChannel.invokeMethod("cancelAction", <String, dynamic>{"key": _key});
    ActionCounter().removeClosedAction(_key);
  }

  @override
  Future<String> getRequestTag(String url) async {
    String? tag = await _methodChannel.invokeMethod(
        "getRequestTag", <String, dynamic>{"key": _key, "url": url});

    return tag == null ? "" : tag;
  }

  @override
  String getRequestTagHeader() {
    return "x-dynatrace";
  }

  @override
  Future<WebRequestTiming> createWebRequestTiming(String url) async {
    String tag = await getRequestTag(url);
    return DynatraceWebRequestTiming(tag, url, _methodChannel);
  }
}
