part of 'selection_widgets.dart';

/// Provides a shared [SelectionController] to descendant [SelectableText]
/// widgets, enabling cross-widget text selection.
///
/// Wrap any subtree with [SelectionArea] to make all [SelectableText]
/// descendants share a single selection state. Click-drag across multiple
/// [SelectableText] widgets selects text spanning all of them, and Ctrl+C
/// copies the combined selection.
///
/// ```dart
/// SelectionArea(
///   child: Column(
///     children: [
///       SelectableText('First paragraph'),
///       SelectableText('Second paragraph'),
///     ],
///   ),
/// )
/// ```
class SelectionArea extends StatefulWidget {
  SelectionArea({required this.child, this.controller, super.key});

  /// The subtree whose [SelectableText] widgets will share selection.
  final Widget child;

  /// Optional external [SelectionController]. If null, one is created.
  final SelectionController? controller;

  @override
  State createState() => _SelectionAreaState();
}

class _SelectionAreaState extends State<SelectionArea> {
  SelectionController? _ownController;

  /// Tracks whether any child received a hit-test this frame.
  /// Used to detect clicks outside all SelectableText children.
  bool _childHitTestedThisFrame = false;

  SelectionController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    _ownController ??= SelectionController();
    return _ownController!;
  }

  /// The SelectionArea clears the shared selection when a click lands
  /// outside all descendant [SelectableText] widgets.
  ///
  /// Detection: [HitTestMouseMsg] is dispatched to hit-tested elements first,
  /// then the raw [MouseMsg] is broadcast to all elements. If we see a raw
  /// left-press without a preceding hit-test, the click landed outside our
  /// selectable children.
  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) {
      _childHitTestedThisFrame = true;
    }

    if (msg is MouseMsg) {
      if (_childHitTestedThisFrame) {
        _childHitTestedThisFrame = false;
      } else if (msg.action == MouseAction.press &&
          msg.button == MouseButton.left) {
        // Click landed outside all children — clear shared selection.
        final ctrl = _effectiveController;
        if (ctrl.hasSelection) {
          ctrl.clearSelection();
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionScope(
      controller: _effectiveController,
      child: widget.child,
    );
  }
}

/// InheritedWidget that provides a [SelectionController] to descendants.
class _SelectionScope extends InheritedWidget {
  _SelectionScope({required this.controller, required super.child});

  final SelectionController controller;

  /// Returns the nearest [SelectionController] from the context, if any.
  static SelectionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SelectionScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(covariant _SelectionScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
