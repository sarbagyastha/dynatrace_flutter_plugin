import 'package:dynatrace_flutter_plugin/src/cli/util/pathConstants.dart';

class CommandLineArguments {
  final bool? _debug;
  final bool? _uninstall;
  final String? _configPath;
  final String? _gradlePath;
  final String? _plistPath;

  CommandLineArguments._private(this._debug, this._uninstall, this._configPath,
      this._gradlePath, this._plistPath);

  static CommandLineArguments parseArgumentList(
      PathConstants paths, List<String> arguments) {
    return CommandLineArguments._private(
        _readValueFromArguments(
            arguments, "--debug", false, (argument) => true),
        _readValueFromArguments(
            arguments, "--uninstall", false, (argument) => true),
        _readValueFromArguments(arguments, "--config",
            paths.getConfigurationPath(), (argument) => argument.split("=")[1]),
        _readValueFromArguments(arguments, "--gradle", paths.getAndroidGradle(),
            (argument) => argument.split("=")[1]),
        _readValueFromArguments(arguments, "--plist", paths.getIosPListFile(),
            (argument) => argument.split("=")[1]));
  }

  static dynamic _readValueFromArguments(List<String> arguments, String key,
      dynamic defaultValue, Function result) {
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i].startsWith(key)) {
        return result(arguments[i]);
      }
    }

    return defaultValue;
  }

  String? get plistPath => this._plistPath;
  String? get gradlePath => this._gradlePath;
  String? get configPath => this._configPath;
  bool? get isDebug => this._debug;
  bool? get isUninstall => this._uninstall;
}
