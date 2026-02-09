import '../framework/framework.dart';
import 'block_focus.dart';

/// A widget that creates a focus scope boundary.
///
/// When [blocking] is true, all focusable widgets in the subtree
/// will be blocked from receiving keyboard events.
/// This is useful for disabling focus on background content
/// when showing modal dialogs or overlays.
class FocusScope extends StatelessComponent {
  /// The child widget tree.
  final Component child;

  /// Whether to block focus events from reaching children.
  ///
  /// When true, keyboard events are blocked and not passed to children.
  /// Defaults to true.
  final bool blocking;

  const FocusScope({
    super.key,
    this.blocking = true,
    required this.child,
  });

  @override
  Component build(BuildContext context) {
    // Use BlockFocus which is properly handled by TerminalBinding._dispatchKeyToElement
    // to actually block keyboard events from reaching children
    return BlockFocus(
      blocking: blocking,
      child: child,
    );
  }
}
