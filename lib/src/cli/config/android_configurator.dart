import 'dart:io';

import 'package:dynatrace_flutter_plugin/src/agent/util/logger.dart';
import 'package:dynatrace_flutter_plugin/src/cli/config/model/cli_arguments.dart';
import 'package:dynatrace_flutter_plugin/src/cli/util/pathConstants.dart';
import 'package:dynatrace_flutter_plugin/src/cli/config/model/android_config.dart';
import 'package:dynatrace_flutter_plugin/src/cli/config/gradle_files.dart';

class AndroidConfigurator {
  static const String GRADLE_CONFIG_IDENTIFIER = "// AUTO - INSERTED";
  static const String GRADLE_DYNATRACE_FILE =
      "apply from: \"./dynatrace.gradle\"";
  static const String GRADLE_BUILDSCRIPT_IDENTIFIER = "buildscript";
  static const String GRADLE_APPLY_BUILDSCRIPT =
      "apply from: \"./plugin.gradle\", to: buildscript";

  late PathConstants _paths;
  late File _buildGradleFile;

  AndroidConfigurator(PathConstants paths, CommandLineArguments arguments,
      File? buildGradleFile) {
    _paths = paths;

    if (buildGradleFile == null) {
      _buildGradleFile = File(arguments.gradlePath!);
    } else {
      _buildGradleFile = buildGradleFile;
    }
  }

  /// Configuring the android folder more specificaly the gradle file which should be
  /// found under [_buildGradleFile].
  Future<void> instrumentAndroidPlatform() async {
    if (await _gradleFileExists(_buildGradleFile)) {
      await _changeFlutterBuildGradleFile();
    } else {
      throw FileSystemException(
          "Can't find .gradle file. Gradle path must also include the gradle file!");
    }
  }

  /// Configures and modifies the Gradle file which can be found under [_customGradleFile].
  Future<void> _changeFlutterBuildGradleFile() async {
    List<String> gradleFileContentLines = await gradleAsList();

    int gradlePluginFileIndex = -1;
    int gradleDynatraceFileIndex = -1;

    for (int i = 0;
        i < gradleFileContentLines.length &&
            (gradleDynatraceFileIndex == -1 || gradlePluginFileIndex == -1);
        i++) {
      if (gradleFileContentLines[i].indexOf("plugin.gradle") > -1) {
        gradlePluginFileIndex = i;
      } else if (gradleFileContentLines[i].indexOf("dynatrace.gradle") > -1) {
        gradleDynatraceFileIndex = i;
      }
    }

    bool modified = false;

    if (gradlePluginFileIndex == -1) {
      int gradleFileFlutterIndex = -1;
      for (int i = 0; i < gradleFileContentLines.length; i++) {
        if (gradleFileContentLines[i]
            .startsWith(GRADLE_BUILDSCRIPT_IDENTIFIER)) {
          gradleFileFlutterIndex = i;
          break;
        }
      }

      if (gradleFileFlutterIndex == -1) {
        throw Exception("Could not find Buildscript block in build.gradle.");
      }

      gradleFileContentLines.insert(
          gradleFileFlutterIndex + 1, GRADLE_APPLY_BUILDSCRIPT);
      modified = true;
    }

    if (gradleDynatraceFileIndex == -1) {
      gradleFileContentLines.insert(0, GRADLE_DYNATRACE_FILE);
      modified = true;
    }

    String fullGradleFile = gradleFileContentLines.join("\n");
    if (modified) {
      await _buildGradleFile.writeAsString(fullGradleFile);
      Logger().d(
          "Added Dynatrace plugin and agent to build.gradle: ${_buildGradleFile.path}");
    } else {
      Logger().d(
          "Dynatrace plugin and agent already added to build.gradle file: ${_buildGradleFile.path}");
    }
  }

  /// Modify the Gradle file and write it. The configuration which should be written is in [androidConfig].
  Future<void> writeGradleConfig(AndroidConfiguration androidConfig) async {
    if (androidConfig.getConfig() == null) {
      Logger().i(
          "Can't write configuration of Android agent because it is missing!",
          logType: LogType.Warning);
      return;
    }

    Directory gradleDir = _buildGradleFile.parent;

    if (!await gradleDir.exists()) {
      throw FileSystemException(
          "Gradle Directory doesn't exist. Can't continue to write configuration.");
    }

    File dynatraceGradle = File(_paths.getDynatraceGradle(gradleDir));
    File pluginGradle = File(_paths.getPluginGradle(gradleDir));

    // Check if dynatrace.gradle exists - if not create it
    if (!await dynatraceGradle.exists()) {
      await dynatraceGradle.writeAsString(getGradleDynatraceContent());
    }

    // Always write the plugin.gradle as it is controlling the version of the plugin
    await pluginGradle.writeAsString(getGradlePluginContent());

    String gradleFileContent = await dynatraceGradle.readAsString();
    List<String?> gradleFileContentLines =
        _removeOldGradleConfig(gradleFileContent);

    int gradleFileIndex = -1;
    for (int i = 0; i < gradleFileContentLines.length; i++) {
      if (gradleFileContentLines[i]!.indexOf(GRADLE_CONFIG_IDENTIFIER) > -1) {
        gradleFileIndex = i;
        break;
      }
    }

    // Insert Gradle Command
    gradleFileContentLines.insert(
        gradleFileIndex + 1, androidConfig.getConfig());

    String fullGradleFile = gradleFileContentLines.join("\n");
    dynatraceGradle.writeAsString(fullGradleFile);

    Logger().d(
        "Replaced old configuration with current configuration in dynatrace.gradle");
  }

  /// Removing old gradle stuff that should not be used anymore.
  List<String?> _removeOldGradleConfig(String gradleFileContent) {
    List<String?> gradleFileContentLines = gradleFileContent.split("\n");

    List<int> gradleConfigIndex = [];
    for (int i = 0;
        i < gradleFileContentLines.length && gradleConfigIndex.length < 2;
        i++) {
      if (gradleFileContentLines[i]!.indexOf(GRADLE_CONFIG_IDENTIFIER) > -1) {
        gradleConfigIndex.add(i);
      }
    }

    if (gradleConfigIndex.length != 2) {
      throw Exception(
          "Could not find identfier in internal gradle file. Please re-install.");
    }

    gradleFileContentLines.removeRange(
        gradleConfigIndex[0] + 1, gradleConfigIndex[1]);
    return gradleFileContentLines;
  }

  Future<void> removeGradleLinesForUninstall() async {
    if (await _gradleFileExists(_buildGradleFile)) {
      // Remove dynatrace.gradle and plugin.gradle references from build.gradle
      List<String> gradleContent = await gradleAsList();

      if (gradleContent.contains(GRADLE_APPLY_BUILDSCRIPT)) {
        gradleContent.remove(GRADLE_APPLY_BUILDSCRIPT);
      }

      if (gradleContent.contains(GRADLE_DYNATRACE_FILE)) {
        gradleContent.remove(GRADLE_DYNATRACE_FILE);
      }

      String fullGradleFile = gradleContent.join("\n");
      await _buildGradleFile.writeAsString(fullGradleFile);
      Logger().d(
          "Removed dynatrace references from the gradle file: ${_buildGradleFile.path}");
    } else {
      throw FileSystemException(
          "Can't find build.gradle file. Skipping removal of dynatrace references in gradle file as it does not exist!");
    }
  }

  Future<void> removeDynatraceGradleFiles() async {
    File dynatraceGradle =
        File(_paths.getDynatraceGradle(_buildGradleFile.parent));
    File pluginGradle = File(_paths.getPluginGradle(_buildGradleFile.parent));
    // Remove dynatrace.gradle and plugin.gradle files
    try {
      if (await _gradleFileExists(dynatraceGradle)) {
        await dynatraceGradle.delete();
      }

      if (await _gradleFileExists(pluginGradle)) {
        await pluginGradle.delete();
      }

      Logger().d("Removed dynatrace gradle confguration files!",
          logType: LogType.Info);
    } catch (e) {
      Logger().i(
          "Unable to remove dynatrace gradle confguration files during uninstall: ${e.toString()}",
          logType: LogType.Warning);
    }
  }

  Future<bool> _gradleFileExists(File gradleFile) async {
    return gradleFile.path.endsWith(".gradle") && await gradleFile.exists();
  }

  Future<List<String>> gradleAsList() async {
    String gradleFileContent = await _buildGradleFile.readAsString();
    return gradleFileContent.split("\n");
  }
}
