part of 'selection_widgets.dart';

/// A render object that paints text with optional selection highlighting.
class RenderSelectableText extends RenderBox {
  RenderSelectableText({required this.text, this.controller});

  String text;
  SelectionController? controller;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final width = Layout.getWidth(text).toDouble();
    final height = Layout.getHeight(text).toDouble();
    size = constraints.constrain(Size(width, height));
  }

  @override
  String paint() {
    final maxW = size.width.toInt();

    // Truncate lines to constrained width.
    var lines = text.split('\n');
    lines = lines.map((l) {
      final w = Style.visibleLength(l);
      if (w <= maxW) return l;
      return Layout.truncate(l, maxW, ellipsis: '');
    }).toList();

    // Apply selection highlighting if controller has active selection.
    final ctrl = controller;
    if (ctrl != null && ctrl.hasSelection) {
      lines = _applySelectionHighlighting(lines, 0, ctrl);
    }

    return lines.join('\n');
  }
}

/// A text widget that supports click-drag selection and Ctrl+C copy.
///
/// This is a drop-in replacement for [Text] with the same parameters plus
/// selection support. When selection is active, highlighted text is rendered
/// with a white-on-black style and Ctrl+C copies to clipboard.
///
/// Can be used standalone or inside a [SelectionArea] for cross-widget
/// selection.
///
/// ```dart
/// SelectableText('Click and drag to select me')
/// ```
class SelectableText extends StatefulWidget {
  SelectableText(
    this.data, {
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    this.controller,
  });

  /// The text to display.
  final String data;

  /// Style applied to the text.
  final Style? style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the text should wrap at soft line breaks.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// Maximum width in columns for text truncation.
  final int? maxWidth;

  /// Optional external [SelectionController].
  ///
  /// If null, a private controller is created. If this widget is inside a
  /// [SelectionArea], the area's controller is used instead.
  final SelectionController? controller;

  @override
  State createState() => _SelectableTextState();
}

class _SelectableTextState extends State<SelectableText> {
  SelectionController? _ownController;
  bool _hitTestedThisFrame = false;

  /// Whether THIS widget instance initiated the current drag.
  /// Guards against sibling SelectableText widgets handling raw MouseMsg
  /// events when they share a SelectionController via SelectionArea.
  bool _isDragging = false;

  /// Set to `true` by [_handleRawMouse] when a release ends a drag.
  /// Prevents the outside-click detection from misinterpreting a
  /// legitimate drag-end release as a click outside.
  bool _justFinishedDrag = false;

  /// Screen-to-local coordinate offsets, captured at press time.
  /// Used to convert raw [MouseMsg] screen coordinates to the render
  /// object's local coordinate space during drag. This correctly accounts
  /// for scroll offset because the values are derived from the hit-test
  /// coordinates which already include scroll adjustment.
  double _screenToLocalDx = 0;
  double _screenToLocalDy = 0;

  SelectionController get _effectiveController {
    // If widget provides a controller, use it.
    if (widget.controller != null) return widget.controller!;
    // Check for ancestor SelectionArea.
    final area = _SelectionScope.maybeOf(context);
    if (area != null) return area;
    // Create our own.
    _ownController ??= SelectionController();
    return _ownController!;
  }

  /// Resolves the rendered text content the same way [Text] does.
  String _renderText() {
    String content = widget.data;
    final style = widget.style;
    if (style != null) {
      final s = style.copy();
      content = s.render(content);
    }

    if (widget.softWrap) {
      final wrapWidth = Layout.getWidth(content);
      content = Layout.wrapLines(content, wrapWidth);
    }

    if (widget.overflow == TextOverflow.ellipsis && widget.maxWidth != null) {
      content = Layout.truncateLines(
        content,
        widget.maxWidth!,
        ellipsis: '...',
      );
    }

    final lines = content.split('\n');
    final renderedWidth = lines.isEmpty
        ? 0
        : lines.map(Layout.visibleLength).reduce(math.max);

    final aligned = switch (widget.textAlign) {
      TextAlign.left => lines,
      TextAlign.center => Layout.alignLines(
        lines,
        renderedWidth,
        HorizontalAlign.center,
      ),
      TextAlign.right => Layout.alignLines(
        lines,
        renderedWidth,
        HorizontalAlign.right,
      ),
      TextAlign.justify => lines,
    };

    return aligned.join('\n');
  }

  /// Returns the content lines for selection operations.
  List<String> _getContentLines() {
    return _renderText().split('\n');
  }

  void _markNeedsPaint() {
    elementOf(widget)?.markNeedsPaint();
  }

  /// Clears selection when a click completes outside this widget.
  ///
  /// Only acts on standalone controllers ([_ownController]). Shared
  /// controllers from [SelectionArea] are cleared by the area itself.
  void _clearSelectionOnOutsideClick() {
    if (_ownController != null && _ownController!.hasSelection) {
      _ownController!.clearSelection();
      _markNeedsPaint();
    }
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) {
      final isWheelLike =
          msg.event.action == MouseAction.wheel ||
          msg.event.button == MouseButton.wheelUp ||
          msg.event.button == MouseButton.wheelDown ||
          msg.event.button == MouseButton.wheelLeft ||
          msg.event.button == MouseButton.wheelRight;
      _hitTestedThisFrame = !isWheelLike;
      final cmd = _handleSelectionMouse(msg);
      if (cmd != null) return cmd;
    }

    // Handle raw mouse events (not dispatched via hit-test).
    if (msg is MouseMsg) {
      if (_hitTestedThisFrame && !_isDragging) {
        // Same event already processed via HitTestMouseMsg in this frame.
        // Skip re-processing, but allow through when dragging — during
        // mouse capture the raw MouseMsg is the ONLY delivery path for
        // motion/release, so the guard must not block it.
        _hitTestedThisFrame = false;
      } else if (msg.action == MouseAction.motion ||
          msg.action == MouseAction.release) {
        _hitTestedThisFrame = false;
        final cmd = _handleRawMouse(msg);
        if (cmd != null) return cmd;
        // If we're not dragging and a release arrived via broadcast (not
        // from capture), it means a click completed outside this widget.
        // Clear selection for standalone controllers. Press events are not
        // broadcast by WidgetApp (to avoid breaking scroll thumbs), so we
        // detect outside clicks on release instead.
        //
        // Guard: _handleRawMouse handles releases during active drag
        // (_isDragging was true on entry). If _handleRawMouse returned null
        // but _isDragging was just cleared (drag finished), do NOT treat
        // that as an outside click — track via _justFinishedDrag.
        if (!_isDragging &&
            !_justFinishedDrag &&
            msg.action == MouseAction.release &&
            msg.button == MouseButton.left) {
          _clearSelectionOnOutsideClick();
        }
        _justFinishedDrag = false;
      } else if (msg.action == MouseAction.press &&
          msg.button == MouseButton.left) {
        // Click landed outside this widget. Only clear if we own the
        // controller (standalone mode). Shared controllers from
        // SelectionArea are cleared by the area itself.
        _clearSelectionOnOutsideClick();
      }
    }

    if (msg is KeyMsg) {
      final cmd = _handleSelectionKey(msg);
      if (cmd != null) return cmd;
    }

    return null;
  }

  /// Handles mouse events for selection (via hit-test dispatch).
  Cmd? _handleSelectionMouse(HitTestMouseMsg msg) {
    final ctrl = _effectiveController;
    final event = msg.event;

    // Use localX/localY from the hit-test result. These are already in the
    // render object's local coordinate space and correctly account for scroll
    // offset (RenderSingleChildViewport.hitTest adds scroll offset when
    // testing children).
    final localX = msg.localX.toInt();
    final localY = msg.localY.toInt();

    // Motion/release during active selection from THIS widget.
    if (event.action == MouseAction.motion && _isDragging) {
      ctrl._selectionEnd = (x: localX, y: localY);
      _markNeedsPaint();
      return null;
    }
    if (event.action == MouseAction.release && _isDragging) {
      ctrl._selecting = false;
      _isDragging = false;
      _justFinishedDrag = true;
      elementOf(widget)?.releaseMouse();
      return null;
    }

    if (event.button == MouseButton.left && event.action == MouseAction.press) {
      final now = DateTime.now();
      final pos = (x: localX, y: localY);
      // Use screen-space coordinates for double-click detection so that
      // clicks on different widgets at the same local position don't
      // register as double-clicks.
      final screenPos = (x: event.x.toInt(), y: event.y.toInt());

      // Double-click: select word.
      if (ctrl._lastClickTime != null &&
          now.difference(ctrl._lastClickTime!) <
              const Duration(milliseconds: 500) &&
          ctrl._lastClickPos == screenPos) {
        final lines = _getContentLines();
        final (wordStart, wordEnd) = _findWordAt(lines, localX, localY);
        ctrl._selectionStart = (x: wordStart, y: localY);
        ctrl._selectionEnd = (x: wordEnd, y: localY);
        ctrl._selecting = false;
        ctrl._lastClickTime = now;
        ctrl._lastClickPos = screenPos;
        _markNeedsPaint();
        return null;
      }

      // Start new selection.
      ctrl.clearSelection();
      ctrl._selectionStart = pos;
      ctrl._selectionEnd = pos;
      ctrl._selecting = true;
      _isDragging = true;
      // Store the screen-to-local offset for raw MouseMsg coordinate
      // conversion during drag. This captures the scroll-adjusted mapping.
      _screenToLocalDx = event.x.toDouble() - localX;
      _screenToLocalDy = event.y.toDouble() - localY;
      ctrl._lastClickTime = now;
      ctrl._lastClickPos = screenPos;

      // Capture mouse so we get motion/release even outside bounds.
      elementOf(widget)?.captureMouse();
      _markNeedsPaint();
      return null;
    }

    return null;
  }

  /// Handles raw mouse events during captured drag.
  Cmd? _handleRawMouse(MouseMsg msg) {
    if (!_isDragging) return null;
    final ctrl = _effectiveController;

    // Convert screen coordinates to local space using the offset captured
    // at press time. This correctly accounts for scroll offset.
    final localX = (msg.x - _screenToLocalDx).toInt();
    final localY = (msg.y - _screenToLocalDy).toInt();

    if (msg.action == MouseAction.motion) {
      ctrl._selectionEnd = (x: localX, y: localY);
      _markNeedsPaint();
      return null;
    }
    if (msg.action == MouseAction.release) {
      ctrl._selecting = false;
      _isDragging = false;
      _justFinishedDrag = true;
      elementOf(widget)?.releaseMouse();
      return null;
    }
    return null;
  }

  /// Handles Ctrl+C for copying selection to clipboard.
  Cmd? _handleSelectionKey(KeyMsg msg) {
    final ctrl = _effectiveController;

    if (msg.key.char == 'c' && msg.key.ctrl) {
      if (ctrl.hasSelection) {
        final lines = _getContentLines();
        final text = ctrl.getSelectedText(lines);
        if (text.isNotEmpty) {
          return Cmd.setClipboard(text);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rendered = _renderText();
    final ctrl = _effectiveController;

    return _SelectableTextRender(text: rendered, controller: ctrl);
  }
}

/// Internal widget that creates the [RenderSelectableText].
class _SelectableTextRender extends LeafRenderObjectWidget {
  _SelectableTextRender({required this.text, required this.controller});

  final String text;
  final SelectionController controller;

  @override
  RenderObject createRenderObject() {
    return RenderSelectableText(text: text, controller: controller);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as RenderSelectableText;
    ro
      ..text = text
      ..controller = controller;
  }

  @override
  Object view() => text;
}
