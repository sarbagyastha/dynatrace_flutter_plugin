import 'package:dynatrace_flutter_plugin/src/agent/action/null_actions/null_root_action_impl.dart';
import 'package:flutter/widgets.dart';

class ActionCounter {
  static ActionCounter? _instance;

  int _count;

  Map<int, dynamic> currentActions = Map();

  ActionCounter.private(this._count);

  factory ActionCounter() {
    if (_instance == null) {
      _instance = ActionCounter.private(0);
    }

    return _instance!;
  }

  @visibleForTesting
  void resetCount() {
    _count = 0;
  }

  int getCount() {
    return _count;
  }

  // Should be the latest created actionId
  getCurrentAction() {
    if (currentActions.containsKey(_count - 1)) {
      return currentActions[_count - 1];
    }
    return DynatraceNullRootAction();
  }

  int getNewActionId() {
    return _count;
  }

  void setOpenAction(int key, dynamic action) {
    if (action != null) {
      currentActions[_count] = action;
      _count++;
    }
  }

  void removeClosedAction(int key) {
    if (currentActions.containsKey(key)) {
      currentActions.remove(key);
    }
  }
}
