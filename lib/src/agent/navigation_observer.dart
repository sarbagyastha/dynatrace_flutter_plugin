import 'package:flutter/widgets.dart';

import 'interface/agent_interface.dart';
import 'util/logger.dart';

/// Navigation observer which is reporting routes
class DynatraceNavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  Dynatrace? _dynatrace;

  DynatraceNavigationObserver() : _dynatrace = Dynatrace();

  /// Private constructor which should only be used for testing purpose
  @visibleForTesting
  DynatraceNavigationObserver.private({Dynatrace? dynatrace})
      : _dynatrace = dynatrace;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _reportRoute(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _reportRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _reportRoute(previousRoute);
    }
  }

  void _reportRoute(PageRoute route) {
    if (route.settings.name != null) {
      // Route has a name and will be reported
      _dynatrace!
          .enterAction("Navigated to screen ${route.settings.name}")
          .leaveAction();
    } else {
      Logger().d(
          "Navigation occurred but Route will not be reported as it has no name!",
          logType: LogType.Info);
    }
  }
}
