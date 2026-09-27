part of 'selection.dart';

int _selectionAreaAutoScrollDelta({
  required int localY,
  required int viewportHeight,
}) {
  if (viewportHeight <= 0) return 0;
  final edgeThreshold = viewportHeight <= 2 ? 0 : 1;
  if (localY <= edgeThreshold) return -1;
  if (localY >= viewportHeight - 1 - edgeThreshold) return 1;
  return 0;
}

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
  SelectionArea({
    required this.child,
    this.controller,
    this.scrollController,
    this.onSelectionChanged,
    this.onSelectionEnd,
    super.key,
  });

  /// The subtree whose selectable text widgets will share selection.
  final Widget child;

  /// Optional external [SelectionController]. If null, one is created.
  final SelectionController? controller;

  /// Overrides the scroll controller discovered from the selection viewport.
  ///
  /// Selection coordinates remain anchored in content space while scrolling.
  final ScrollController? scrollController;

  /// Reports selected plain text across the registered descendants.
  final SelectionCallback? onSelectionChanged;

  /// Reports nonempty combined text once a user completes a selection.
  ///
  /// Use this to implement copy-on-selection without handling each child.
  /// Programmatic changes and clearing do not fire this callback.
  final SelectionCallback? onSelectionEnd;

  @override
  State createState() => _SelectionAreaState();
}

class _SelectionAreaState extends State<SelectionArea> {
  SelectionController? _ownController;
  SelectionController? _listeningController;
  bool _isDraggingFromArea = false;

  ScrollController? get _scrollController =>
      widget.scrollController ??
      switch (_findSelectionViewport()) {
        RenderSingleChildViewport viewport => viewport.controller,
        RenderListViewScrollViewport viewport => viewport.controller,
        RenderListViewport viewport => viewport.controller,
        _ => null,
      };

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

  void _selectionChanged() {
    widget.onSelectionChanged?.call(
      _effectiveController.getSelectedRegisteredText(),
    );
  }

  void Function()? _selectionEnded() {
    final callback = widget.onSelectionEnd;
    if (callback == null) return null;
    final text = _effectiveController.getSelectedRegisteredText();
    return text.isEmpty ? null : () => callback(text);
  }

  void _syncSelectionCallbacks() {
    final controller = _effectiveController;
    if (identical(controller, _listeningController)) return;
    _listeningController?.removeListener(_selectionChanged);
    _listeningController?._completionListeners.remove(_selectionEnded);
    _listeningController = controller;
    controller.addListener(_selectionChanged);
    controller._completionListeners.add(_selectionEnded);
  }

  @override
  void dispose() {
    _listeningController?.removeListener(_selectionChanged);
    _listeningController?._completionListeners.remove(_selectionEnded);
    super.dispose();
  }

  /// Clears the shared selection if one is active.
  void _clearSharedSelection() {
    final ctrl = _effectiveController;
    if (ctrl.hasSelection) {
      ctrl.clearSelection();
    }
  }

  int _wheelScrollDelta(MouseMsg event) {
    return switch (event.button) {
      MouseButton.wheelUp => -3,
      MouseButton.wheelDown => 3,
      _ => 0,
    };
  }

  SelectionPoint _selectionPointForEvent(MouseMsg event) {
    final yOffset = _scrollController?.offset ?? 0;
    return (x: event.x.toInt(), y: event.y.toInt() + yOffset);
  }

  bool _isWheelLike(MouseMsg event) =>
      event.action == MouseAction.wheel ||
      event.button == MouseButton.wheelUp ||
      event.button == MouseButton.wheelDown ||
      event.button == MouseButton.wheelLeft ||
      event.button == MouseButton.wheelRight;

  void _selectRegisteredWordAt(
    SelectionController ctrl,
    _RegisteredSelectionTarget target,
  ) {
    final (startX, endX) = findWordAt(
      target.lines,
      target.localX,
      target.localY,
    );
    ctrl._selectionStart = (
      x: target.globalPoint.x - target.localX + startX,
      y: target.globalPoint.y,
    );
    ctrl._selectionEnd = (
      x: target.globalPoint.x - target.localX + endX,
      y: target.globalPoint.y,
    );
    ctrl._selecting = false;
    ctrl._notifyListeners();
    ctrl._notifySelectionEnd();
  }

  void _selectRegisteredLineAt(
    SelectionController ctrl,
    _RegisteredSelectionTarget target,
  ) {
    final (startX, endX) = findLineAt(target.lines, target.localY);
    ctrl._selectionStart = (
      x: target.globalPoint.x - target.localX + startX,
      y: target.globalPoint.y,
    );
    ctrl._selectionEnd = (
      x: target.globalPoint.x - target.localX + endX,
      y: target.globalPoint.y,
    );
    ctrl._selecting = false;
    ctrl._notifyListeners();
    ctrl._notifySelectionEnd();
  }

  bool _maybeStartSharedSelectionFromArea(MouseMsg event) {
    if (event.action != MouseAction.press || event.button != MouseButton.left) {
      return false;
    }

    final ctrl = _effectiveController;
    if (ctrl.selecting) return false;

    final target = ctrl._snapGlobalPointToRegisteredRow(
      _selectionPointForEvent(event),
    );
    if (target == null) return false;

    final screenPos = target.globalPoint;
    final clickCount = ctrl.registerClick(screenPos);

    if (clickCount == 2) {
      _selectRegisteredWordAt(ctrl, target);
      return true;
    }
    if (clickCount >= 3) {
      _selectRegisteredLineAt(ctrl, target);
      return true;
    }

    ctrl.clearSelection();
    ctrl._selectionStart = target.globalPoint;
    ctrl._selectionEnd = target.globalPoint;
    ctrl._selecting = true;
    _isDraggingFromArea = true;
    elementOf(widget)?.captureMouse();
    ctrl._notifyListeners();
    return true;
  }

  bool _maybeUpdateSharedSelectionFromArea(MouseMsg event) {
    if (!_isDraggingFromArea) return false;
    final ctrl = _effectiveController;

    if (event.action == MouseAction.motion) {
      _maybeAutoScrollSelection(event);
      final target = ctrl._snapGlobalPointToRegisteredRow(
        _selectionPointForEvent(event),
      );
      if (target != null) {
        ctrl._selectionEnd = target.globalPoint;
        ctrl._notifyListeners();
      }
      return true;
    }

    if (event.action == MouseAction.release) {
      _isDraggingFromArea = false;
      ctrl._selecting = false;
      elementOf(widget)?.releaseMouse();
      ctrl._notifyListeners();
      ctrl._notifySelectionEnd();
      return true;
    }

    return false;
  }

  void _maybeAutoScrollSelection(MouseMsg event) {
    final scrollController = _scrollController;
    final ctrl = _effectiveController;
    if (scrollController == null || !ctrl.selecting || !_isDraggingFromArea) {
      return;
    }

    final ro = _findSelectionViewport();
    if (ro == null) return;

    final viewportLocalY = (event.y - _renderObjectScreenY(ro)).toInt();
    final viewportHeight = ro.size.height.toInt();
    final delta = _selectionAreaAutoScrollDelta(
      localY: viewportLocalY,
      viewportHeight: viewportHeight,
    );
    if (delta != 0) {
      scrollController.scrollBy(delta);
    }
  }

  RenderObject? _findSelectionViewport() {
    final el = elementOf(widget);
    Element? current = el?.parent;
    while (current != null) {
      if (current is RenderObjectElement) {
        final ro = current.renderObject;
        if (ro is RenderSingleChildViewport ||
            ro is RenderListViewScrollViewport ||
            ro is RenderListViewport ||
            ro is RenderViewport) {
          return ro;
        }
      }
      current = current.parent;
    }
    RenderObject? descendantViewport(Element node) {
      if (node is RenderObjectElement) {
        final render = node.renderObject;
        if (render is RenderSingleChildViewport ||
            render is RenderListViewScrollViewport ||
            render is RenderListViewport ||
            render is RenderViewport) {
          return render;
        }
      }
      for (final child in node.children) {
        final found = descendantViewport(child);
        if (found != null) return found;
      }
      return null;
    }

    return el == null ? null : descendantViewport(el);
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
      if (msg.event.action == MouseAction.motion) {
        _maybeAutoScrollSelection(msg.event);
      }
      final isWheelLike = _isWheelLike(msg.event);
      if (isWheelLike &&
          _isDraggingFromArea &&
          _scrollController != null &&
          _effectiveController.selecting) {
        final delta = _wheelScrollDelta(msg.event);
        if (delta != 0) {
          _scrollController!.scrollBy(delta);
          return Cmd.none();
        }
      }
      if (!isWheelLike) {
        _lastHitTestAction = msg.event.action;
      }
    }

    if (msg is MouseMsg) {
      final wasHandledByHitTest = _lastHitTestAction == msg.action;

      if (_isWheelLike(msg) &&
          _isDraggingFromArea &&
          _scrollController != null &&
          _effectiveController.selecting) {
        final delta = _wheelScrollDelta(msg);
        if (delta != 0) {
          _scrollController!.scrollBy(delta);
          return Cmd.none();
        }
      }

      if (_maybeUpdateSharedSelectionFromArea(msg)) {
        return null;
      }

      if (!wasHandledByHitTest && _maybeStartSharedSelectionFromArea(msg)) {
        _lastHitTestAction = null;
        return null;
      }

      if (msg.action == MouseAction.motion) {
        _maybeAutoScrollSelection(msg);
      }

      // Check if this raw MouseMsg matches the action of the last
      // HitTestMouseMsg we received. If so, the event was already
      // dispatched through hit-testing to one of our children — consume
      // the flag and don't treat it as an outside click.
      if (wasHandledByHitTest) {
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
    _syncSelectionCallbacks();
    return _SelectionScope(
      controller: _effectiveController,
      scrollController: widget.scrollController,
      child: widget.child,
    );
  }
}

/// InheritedWidget that provides a [SelectionController] to descendants.
class _SelectionScope extends InheritedWidget {
  _SelectionScope({
    required this.controller,
    required this.scrollController,
    required super.child,
  });

  final SelectionController controller;
  final ScrollController? scrollController;

  /// Returns the nearest [SelectionController] from the context, if any.
  static SelectionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SelectionScope>()
        ?.controller;
  }

  static ScrollController? maybeScrollController(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SelectionScope>()
        ?.scrollController;
  }

  @override
  bool updateShouldNotify(covariant _SelectionScope oldWidget) {
    return controller != oldWidget.controller ||
        scrollController != oldWidget.scrollController;
  }
}
