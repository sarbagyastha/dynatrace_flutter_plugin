import '../model/log_level.dart';
import '../util/string_utils.dart';

const bool _DEFAULT_REPORT_CRASH = true;
const bool _DEFAULT_MONITOR_WEB_REQUEST = true;
const bool _DEFAULT_CERTIFICATE_VALIDATION = true;
const bool _DEFAULT_USER_OPT_IN = false;
const LogLevel _DEFAULT_LOG_LEVEL = LogLevel.Info;

/// Configuration class which can be used for manual instrumentation.
class Configuration {
  final LogLevel _logLevel;
  final bool _reportCrash;
  final bool _monitorWebRequest;
  final String? _beaconUrl;
  final String? _applicationId;
  final bool _certificateValidation;
  final bool _userOptIn;

  /// Constructor of configuration class.
  const Configuration(
      {bool reportCrash = _DEFAULT_REPORT_CRASH,
      bool monitorWebRequest = _DEFAULT_MONITOR_WEB_REQUEST,
      LogLevel logLevel = _DEFAULT_LOG_LEVEL,
      String? beaconUrl,
      String? applicationId,
      bool certificateValidation = _DEFAULT_CERTIFICATE_VALIDATION,
      bool userOptIn = _DEFAULT_USER_OPT_IN})
      : _reportCrash = reportCrash,
        _monitorWebRequest = monitorWebRequest,
        _logLevel = logLevel,
        _applicationId = applicationId,
        _beaconUrl = beaconUrl,
        _certificateValidation = certificateValidation,
        _userOptIn = userOptIn;

  /// Returns if crash reporting is enabled.
  bool get isCrashReportingEnabled {
    return _reportCrash;
  }

  /// Check if the properties for the Autostart are available and valid
  /// If [beaconUrl] and [applicationId] are available this will return true
  bool get isAutoStartPropertyAvailable {
    return !StringUtils.isStringNullEmptyOrWhitespace(_beaconUrl) &&
        !StringUtils.isStringNullEmptyOrWhitespace(_applicationId);
  }

  /// Returns if web request monitoring is enabled
  bool get isWebRequestMonitoringEnabled => _monitorWebRequest;
  LogLevel get logLevel => _logLevel;

  /// Generating the Startup configuration for a manual startup. Only
  /// relevant configurations will be passed to the native agents.
  /// Currently this is applicationId, beaconUrl and loglevel.
  Map<String, dynamic> getStartupConfiguration() {
    Map<String, dynamic> startupConfiguration = Map();

    if (!StringUtils.isStringNullEmptyOrWhitespace(_applicationId)) {
      startupConfiguration["applicationId"] = _applicationId;
    }

    if (!StringUtils.isStringNullEmptyOrWhitespace(_beaconUrl)) {
      startupConfiguration["beaconUrl"] = _beaconUrl;
    }

    if (_logLevel == LogLevel.Debug) {
      // Only sending the non-default value which is debug
      startupConfiguration["logLevel"] = "debug";
    }

    if (!_certificateValidation) {
      // Only sending the non-default value which is false
      startupConfiguration["certificateValidation"] = false;
    }

    if (_userOptIn) {
      // Only sending the non-default value which is true
      startupConfiguration["userOptIn"] = true;
    }

    if (!_reportCrash) {
      // Only sending the non-default value which is false
      startupConfiguration["crashReporting"] = false;
    }

    return startupConfiguration;
  }
}
