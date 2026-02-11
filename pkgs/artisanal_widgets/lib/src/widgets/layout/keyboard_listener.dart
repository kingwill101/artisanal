import 'package:artisanal/tui.dart' show Cmd, Msg, KeyMsg;
import '../core/framework.dart' show BuildContext, State, StatefulWidget;
import '../core/widget.dart';
import '../focus/focus.dart' show FocusKeyCallback;

/// A widget that calls a callback when a key is pressed.
///
/// This widget receives [KeyMsg] during the normal broadcast dispatch.
/// By default, it receives the event after its children because the
/// widget tree uses bottom-up dispatching.
class KeyboardListener extends StatefulWidget {
  KeyboardListener({required this.child, this.onKey, super.key});

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when a key message is received.
  final FocusKeyCallback? onKey;

  @override
  State createState() => _KeyboardListenerState();
}

class _KeyboardListenerState extends State<KeyboardListener> {
  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is KeyMsg) {
      return widget.onKey?.call(msg);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
