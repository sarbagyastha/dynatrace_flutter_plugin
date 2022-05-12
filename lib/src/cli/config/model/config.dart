import 'package:dynatrace_flutter_plugin/src/cli/config/model/ios_config.dart';
import 'package:dynatrace_flutter_plugin/src/cli/config/model/android_config.dart';

import 'package:yaml/yaml.dart';

class Configuration {
  AndroidConfiguration? _androidConfiguration;
  IosConfiguration? _iosConfiguration;

  Configuration(String contentYaml) {
    YamlMap? mapYaml = loadYaml(contentYaml);

    if (mapYaml != null && mapYaml["ios"] != null) {
      _iosConfiguration = IosConfiguration(mapYaml["ios"]["config"]);
    } else {
      _iosConfiguration = IosConfiguration(null);
    }

    if (mapYaml != null && mapYaml["android"] != null) {
      YamlMap androidMap = mapYaml.nodes["android"] as YamlMap;
      if (androidMap.nodes["config"] != null) {
        _androidConfiguration = AndroidConfiguration(
            androidMap.nodes["config"]!.span.text.replaceAll("\"", ""));
      } else {
        _androidConfiguration = AndroidConfiguration(null);
      }
    } else {
      _androidConfiguration = AndroidConfiguration(null);
    }
  }

  AndroidConfiguration? getAndroidConfiguration() {
    return _androidConfiguration;
  }

  IosConfiguration? getIosConfiguration() {
    return _iosConfiguration;
  }
}
