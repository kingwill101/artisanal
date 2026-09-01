import 'package:artisanal/runtime.dart' show Cmd, Msg, KeyMsg;
import '../core/framework.dart' show BuildContext, State, StatefulWidget;
import '../core/widget.dart';

/// A widget that blocks keyboard events from reaching its children.
///
/// When [blocking] is true (the default), all [KeyMsg] events are intercepted
/// and consumed before they reach the subtree below. This is useful for
/// preventing keyboard interaction with content behind a modal or overlay.
///
/// ```dart
/// BlockFocus(
///   blocking: true,
///   child: Text('This cannot receive keyboard events'),
/// )
/// ```
class BlockFocus extends StatefulWidget {
  BlockFocus({required this.child, this.blocking = true, super.key});

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether keyboard events should be blocked.
  ///
  /// When false, events pass through to children normally.
  final bool blocking;

  @override
  State createState() => _BlockFocusState();
}

class _BlockFocusState extends State<BlockFocus> {
  @override
  Cmd? handleIntercept(Msg msg) {
    if (widget.blocking && msg is KeyMsg) {
      // Swallow the event — return a no-op command to signal it was handled.
      return Cmd.none();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
