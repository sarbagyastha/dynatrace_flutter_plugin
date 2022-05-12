import '../model/log_level.dart';

import 'string_utils.dart';

enum LogType { Info, Error, Warning }

class Logger {
  static Logger? _instance;
  LogLevel? _definedLogLevel;

  factory Logger() {
    if (_instance == null) {
      _instance = Logger.private();
    }

    return _instance!;
  }

  Logger.private() {
    this._definedLogLevel = LogLevel.Info;
  }

  set logLevel(LogLevel logLevel) => _definedLogLevel = logLevel;

  /// Is logging a debug log. This will only be logged if
  /// the customer activated the debug logs
  void d(String message, {LogType logType = LogType.Info}) {
    if (_definedLogLevel == LogLevel.Debug) {
      _logMessage(logType, message);
    }
  }

  /// Is logging a info log. This log will always be displayed.
  /// So be careful when using it
  void i(String? message, {LogType logType = LogType.Info}) {
    _logMessage(logType, message);
  }

  /// Logging a [message] with a certain [logLevel]
  void _logMessage(LogType logType, String? message) {
    if (!StringUtils.isStringNullEmptyOrWhitespace(message)) {
      print(
          "[${_currentDate()}][${_getLogTypeString(logType)}][DYNATRACE]: $message");
    }
  }

  String _getLogTypeString(LogType logType) {
    if (logType == LogType.Error) {
      return "ERROR";
    } else if (logType == LogType.Warning) {
      return "WARNING";
    } else {
      return "INFO";
    }
  }

  String _currentDate() {
    String date = DateTime.now().toIso8601String().replaceFirst("T", " ");
    return date.substring(0, date.indexOf("."));
  }
}
