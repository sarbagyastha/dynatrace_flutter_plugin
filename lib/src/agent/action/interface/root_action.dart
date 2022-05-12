import './action.dart';
import '../../model/platform.dart';

/// Root action which can additionally to the normal DynatraceAction
/// create another layer of actions underneath.
abstract class DynatraceRootAction implements DynatraceAction {
  /// Enters a (child) Action with a specified [actionName] on this Action.
  /// If the given [actionName] is [null] or an empty string, no reporting
  /// will happen on that [RootAction].
  DynatraceAction enterAction(String? actionName, {Platform? platform});
}
