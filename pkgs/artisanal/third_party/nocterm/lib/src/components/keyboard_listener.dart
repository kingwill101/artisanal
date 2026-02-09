import '../framework/framework.dart';
import '../keyboard/logical_key.dart';
import '../keyboard/keyboard_event.dart';
import 'focusable.dart';

/// A simple keyboard listener that converts keyboard events to logical keys
class KeyboardListener extends StatelessComponent {
  final bool Function(LogicalKey key)? onKeyEvent;
  final Component child;
  final bool autofocus;

  const KeyboardListener({
    super.key,
    required this.onKeyEvent,
    required this.child,
    this.autofocus = false,
  });

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: autofocus, // Use actual autofocus value
      onKeyEvent: (KeyboardEvent event) {
        // If onKeyEvent is provided, call it and return its result
        // Otherwise, don't handle the event
        return onKeyEvent?.call(event.logicalKey) ?? false;
      },
      child: child,
    );
  }
}
