import 'dart:io';

import '../agent_impl.dart';
import '../interface/agent_interface.dart';
import 'http_client.dart';

class DynatraceHttpOverrides extends HttpOverrides {
  Dynatrace _dynatrace;
  DynatraceHttpOverrides(this._dynatrace);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return DynatraceHttpClient(
        super.createHttpClient(context), _dynatrace as DynatraceImpl);
  }
}
