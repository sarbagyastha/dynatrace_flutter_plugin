import 'package:dynatrace_flutter_plugin/src/cli/dynatrace_instrumentation.dart';
import 'package:dynatrace_flutter_plugin/src/cli/util/pathConstants.dart';

/// Main starting point for the instrumentation
void main(List<String> arguments) {
  setupConfiguration(PathConstants(), arguments);
}
