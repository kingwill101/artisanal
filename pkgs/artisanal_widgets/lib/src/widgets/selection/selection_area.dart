part of 'selection_widgets.dart';

/// Provides a shared [SelectionController] to descendant selectable text
/// widgets, enabling cross-widget text selection.
///
/// Wrap any subtree with [SelectionArea] to make all [SelectableText],
/// [SelectableRichText], and [SelectableView] descendants share a single
/// selection state. Click-drag across multiple selectable widgets selects
/// text spanning all of them, and Ctrl+C copies the combined selection.
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

  /// The subtree whose selectable text widgets will share selection.
  final Widget child;

  /// Optional external [SelectionController]. If null, one is created.
  final SelectionController? controller;

  @override
  State createState() => _SelectionAreaState();
}

class _SelectionAreaState extends State<SelectionArea> {
  SelectionController? _ownController;

  /// Tracks the action type of the last HitTestMouseMsg received.
  /// Reset to `null` when the corresponding raw MouseMsg is consumed.
  /// This prevents stale hit-test flags from blocking outside-click
  /// detection when mouse capture interrupts the normal dispatch flow.
  MouseAction? _lastHitTestAction;

  SelectionController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    _ownController ??= SelectionController();
    return _ownController!;
  }

  /// Clears the shared selection if one is active.
  void _clearSharedSelection() {
    final ctrl = _effectiveController;
    if (ctrl.hasSelection) {
      ctrl.clearSelection();
    }
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
      final isWheelLike =
          msg.event.action == MouseAction.wheel ||
          msg.event.button == MouseButton.wheelUp ||
          msg.event.button == MouseButton.wheelDown ||
          msg.event.button == MouseButton.wheelLeft ||
          msg.event.button == MouseButton.wheelRight;
      if (!isWheelLike) {
        _lastHitTestAction = msg.event.action;
      }
    }

    if (msg is MouseMsg) {
      // Check if this raw MouseMsg matches the action of the last
      // HitTestMouseMsg we received. If so, the event was already
      // dispatched through hit-testing to one of our children — consume
      // the flag and don't treat it as an outside click.
      if (_lastHitTestAction == msg.action) {
        _lastHitTestAction = null;
      } else if ((msg.action == MouseAction.press ||
              msg.action == MouseAction.release) &&
          msg.button == MouseButton.left) {
        // Click (press or release) landed outside all children — clear
        // shared selection. We check both press and release because
        // press events may not be broadcast by WidgetApp, so the
        // release serves as the fallback outside-click signal.
        _lastHitTestAction = null;
        _clearSharedSelection();
      }
    }

    if (msg is KeyMsg && msg.key.char == 'c' && msg.key.ctrl) {
      final text = _effectiveController.getSelectedRegisteredText();
      if (text.isNotEmpty) {
        return Cmd.setClipboard(text);
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
