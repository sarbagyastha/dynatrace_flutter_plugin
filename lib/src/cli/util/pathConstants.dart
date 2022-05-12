import 'package:path/path.dart' as p;
import 'dart:io';

class PathConstants {
  String getApplicationPath() {
    return p.current;
  }

  String getAndroidFolder() {
    return p.join(getApplicationPath(), "android");
  }

  String getAndroidGradle() {
    return p.join(getAndroidFolder(), "build.gradle");
  }

  String getDynatraceGradle(Directory gradleDir) {
    return p.join(gradleDir.path, "dynatrace.gradle");
  }

  String getPluginGradle(Directory gradleDir) {
    return p.join(gradleDir.path, "plugin.gradle");
  }

  String getIosFolder() {
    return p.join(getApplicationPath(), "ios");
  }

  String getIosPListFile() {
    return p.join(getIosFolder(), "Runner", "Info.plist");
  }

  String getConfigurationPath() {
    return p.join(getApplicationPath(), "dynatrace.config.yaml");
  }
}
