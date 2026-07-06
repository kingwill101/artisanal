part of 'components_widgets.dart';

/// Manages a stack of modal dialogs.
///
/// Wraps its [child] and renders the top-most dialog as a [Modal] overlay.
/// Provides static methods to push, pop, replace, and clear dialogs from
/// anywhere in the subtree.
///
/// The stack handles `esc` to pop the top dialog automatically.
///
/// ```dart
/// // Wrap your app or section with DialogStack
/// DialogStack(child: MyApp())
///
/// // Open a dialog from anywhere below
/// DialogStack.of(context).push(MyDialog());
///
/// // Close the top dialog
/// DialogStack.of(context).pop();
/// ```
@Deprecated(
  'Use DialogRoute via Navigator.of(context).showDialog() instead. '
  'Will be removed in a future release.',
)
class DialogStack extends StatefulWidget {
  DialogStack({
    required this.child,
    this.backdropOpacity = 0.6,
    this.backdropColor,
    this.dismissible = true,
    super.key,
  });

  /// The content below the dialog stack.
  final Widget child;

  /// Opacity of the backdrop behind the top dialog.
  final double backdropOpacity;

  /// Color of the backdrop (defaults to theme background).
  final Color? backdropColor;

  /// Whether clicking the backdrop dismisses the top dialog.
  final bool dismissible;

  /// Returns the nearest [DialogStackState] above [context].
  ///
  /// Throws if no [DialogStack] is found in the tree.
  static DialogStackState of(BuildContext context) {
    final state = context
        .dependOnInheritedWidgetOfExactType<_DialogStackScope>()
        ?.state;
    assert(state != null, 'No DialogStack found in the widget tree');
    return state!;
  }

  /// Returns the nearest [DialogStackState] if available.
  static DialogStackState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DialogStackScope>()
        ?.state;
  }

  @override
  State createState() => DialogStackState();
}

/// State for [DialogStack], providing the push/pop/replace/clear API.
@Deprecated(
  'Use DialogRoute via Navigator.of(context).showDialog() instead. '
  'Will be removed in a future release.',
)
class DialogStackState extends State<DialogStack> {
  final List<Widget> _stack = [];

  /// Whether any dialog is currently open.
  bool get isOpen => _stack.isNotEmpty;

  /// The number of dialogs in the stack.
  int get depth => _stack.length;

  /// Push a dialog onto the stack.
  void push(Widget dialog) {
    setState(() {
      _stack.add(dialog);
    });
  }

  /// Pop the top dialog from the stack.
  ///
  /// Returns `true` if a dialog was popped, `false` if the stack was empty.
  bool pop() {
    if (_stack.isEmpty) return false;
    setState(() {
      _stack.removeLast();
    });
    return true;
  }

  /// Replace the entire stack with a single dialog.
  void replace(Widget dialog) {
    setState(() {
      _stack
        ..clear()
        ..add(dialog);
    });
  }

  /// Clear all dialogs from the stack.
  void clear() {
    if (_stack.isEmpty) return;
    setState(() {
      _stack.clear();
    });
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (_stack.isEmpty) return null;

    // Esc pops the top dialog
    if (msg is KeyMsg) {
      final key = msg.key;
      if (key.type == terminal_keys.KeyType.escape) {
        pop();
        return Cmd.none();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scope = _DialogStackScope(state: this, child: _buildStack(context));
    return scope;
  }

  Widget _buildStack(BuildContext context) {
    if (_stack.isEmpty) return widget.child;

    final topDialog = _stack.last;

    return Modal(
      open: true,
      backdropOpacity: widget.backdropOpacity,
      backdropColor: widget.backdropColor,
      dismissible: widget.dismissible,
      onDismiss: () {
        pop();
        return null;
      },
      dialog: topDialog,
      child: widget.child,
    );
  }
}

/// InheritedWidget that exposes the [DialogStackState] to descendants.
class _DialogStackScope extends InheritedWidget {
  _DialogStackScope({required this.state, required super.child});

  final DialogStackState state;

  @override
  bool updateShouldNotify(covariant _DialogStackScope oldWidget) {
    return state != oldWidget.state;
  }
}
