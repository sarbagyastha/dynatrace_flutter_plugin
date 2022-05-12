import 'package:dynatrace_flutter_plugin/src/cli/util/version.dart';

/// Returns the content of the plugin file which contains the version of the Android Agent
String getGradlePluginContent() {
  return """dependencies {
	classpath 'com.dynatrace.tools.android:gradle-plugin:${getAndroidVersion()}'
}""";
}

/// Returns the default content of the dynatrace gradle file which contains the configuration
String getGradleDynatraceContent() {
  return """ext['dynatrace.instrumentationFlavor'] = 'flutter'
apply plugin: 'com.dynatrace.instrumentation'

// AUTO - INSERTED
// AUTO - INSERTED
  """;
}
