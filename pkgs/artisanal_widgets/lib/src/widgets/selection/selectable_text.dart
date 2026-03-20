part of 'selection_widgets.dart';

/// A render object that paints text with optional selection highlighting.
class RenderSelectableText extends RenderBox {
  RenderSelectableText({
    required this.text,
    required this.selectionHighlightStyle,
    this.selectionStart,
    this.selectionEnd,
  });

  String text;
  Style selectionHighlightStyle;
  SelectionPoint? selectionStart;
  SelectionPoint? selectionEnd;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : Layout.getWidth(text).toDouble();
    final height = Layout.getHeight(text).toDouble();
    size = constraints.constrain(Size(width, height));
  }

  @override
  String paint() {
    final maxW = size.width.toInt();

    var lines = text.split('\n');
    lines = lines.map((line) {
      final width = Style.visibleLength(line);
      if (width <= maxW) return line;
      return Layout.truncate(line, maxW, ellipsis: '');
    }).toList();

    final start = selectionStart;
    final end = selectionEnd;
    if (start != null && end != null) {
      lines = applySelectionHighlighting(
        lines,
        offset: 0,
        selectionStart: start,
        selectionEnd: end,
        highlightStyle: selectionHighlightStyle,
      );
    }

    return lines.join('\n');
  }
}

/// A text widget that supports click-drag selection and Ctrl+C copy.
///
/// This is a drop-in replacement for [Text] with the same parameters plus
/// selection support. When selection is active, highlighted text is rendered
/// with the current theme's highlight colors and Ctrl+C copies to clipboard.
///
/// Can be used standalone or inside a [SelectionArea] for cross-widget
/// selection.
class SelectableText extends StatelessWidget {
  SelectableText(
    this.data, {
    super.key,
    this.style,
    this.selectionHighlightStyle,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    this.controller,
  });

  final String data;
  final Style? style;
  final Style? selectionHighlightStyle;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxWidth;
  final SelectionController? controller;

  @override
  Widget build(BuildContext context) {
    return _SelectableRenderedText(
      text: _renderPlainText(
        data,
        style: style,
        textAlign: textAlign,
        softWrap: softWrap,
        overflow: overflow,
        maxWidth: maxWidth,
      ),
      controller: controller,
      selectionHighlightStyle: selectionHighlightStyle,
    );
  }
}

class _SelectableRenderedText extends StatefulWidget {
  _SelectableRenderedText({
    required this.text,
    this.controller,
    this.selectionHighlightStyle,
  });

  final String text;
  final SelectionController? controller;
  final Style? selectionHighlightStyle;

  @override
  State createState() => _SelectableRenderedTextState();
}

class _SelectableRenderedTextState extends State<_SelectableRenderedText> {
  SelectionController? _ownController;
  SelectionController? _registeredController;
  SelectionController? _listeningController;
  bool _hitTestedThisFrame = false;
  bool _isDragging = false;
  bool _justFinishedDrag = false;
  double _screenToLocalDx = 0;
  double _screenToLocalDy = 0;

  SelectionController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    final area = _SelectionScope.maybeOf(context);
    if (area != null) return area;
    _ownController ??= SelectionController();
    return _ownController!;
  }

  bool get _usingSharedController {
    final area = _SelectionScope.maybeOf(context);
    return area != null && identical(area, _effectiveController);
  }

  ScrollController? get _sharedScrollController =>
      _SelectionScope.maybeScrollController(context);

  int get _sharedSelectionYOffset => _sharedScrollController?.offset ?? 0;

  List<String> _getContentLines() => widget.text.split('\n');

  void _markNeedsPaint() {
    if (mounted) {
      setState(() {});
    }
    elementOf(widget)?.markNeedsPaint();
  }

  void _handleControllerChanged() {
    _markNeedsPaint();
  }

  void _syncControllerListener() {
    final ctrl = _effectiveController;
    if (identical(ctrl, _listeningController)) return;
    _listeningController?.removeListener(_handleControllerChanged);
    _listeningController = ctrl;
    ctrl.addListener(_handleControllerChanged);
  }

  void _emitSelectionChanged(SelectionController ctrl) {
    if (_usingSharedController) {
      ctrl._notifyListeners();
    } else {
      _markNeedsPaint();
    }
  }

  void _clearSelectionOnOutsideClick() {
    if (_ownController != null && _ownController!.hasSelection) {
      _ownController!.clearSelection();
      _markNeedsPaint();
    }
  }

  SelectionPoint _globalOrigin() {
    final ro = _firstRenderObjectForWidget(widget);
    if (ro == null) return (x: 0, y: 0);
    final globalY = _renderObjectGlobalY(ro).toInt();
    return (
      x: _renderObjectGlobalX(ro).toInt(),
      y: globalY + (_usingSharedController ? _sharedSelectionYOffset : 0),
    );
  }

  SelectionPoint? _localSelectionPoint(SelectionPoint? point) {
    if (point == null) return null;
    if (!_usingSharedController) return point;
    final origin = _globalOrigin();
    return (x: point.x - origin.x, y: point.y - origin.y);
  }

  void _refreshParticipantRegistration() {
    final ctrl = _effectiveController;
    if (!_usingSharedController) {
      _registeredController?._unregisterParticipant(this);
      _registeredController = null;
      return;
    }

    ctrl._registerParticipant(
      _SelectionParticipant(
        owner: this,
        getGlobalOrigin: _globalOrigin,
        getContentLines: _getContentLines,
      ),
    );
    _registeredController = ctrl;
  }

  SelectionPoint _selectionPointForLocal(int localX, int localY) {
    if (!_usingSharedController) {
      return (x: localX, y: localY);
    }
    final origin = _globalOrigin();
    return (x: origin.x + localX, y: origin.y + localY);
  }

  SelectionPoint _selectionPointForEvent(MouseMsg event) {
    if (!_usingSharedController) {
      return (x: event.x.toInt(), y: event.y.toInt());
    }
    return (x: event.x.toInt(), y: event.y.toInt() + _sharedSelectionYOffset);
  }

  int _updateClickCount(
    SelectionController ctrl,
    DateTime now,
    SelectionPoint screenPos,
  ) {
    final isSequential =
        ctrl._lastClickTime != null &&
        now.difference(ctrl._lastClickTime!) <
            const Duration(milliseconds: 500) &&
        ctrl._lastClickPos == screenPos;
    final count = isSequential ? math.min(ctrl._lastClickCount + 1, 3) : 1;
    ctrl
      .._lastClickTime = now
      .._lastClickPos = screenPos
      .._lastClickCount = count;
    return count;
  }

  void _selectWordAt(SelectionController ctrl, int localX, int localY) {
    final lines = _getContentLines();
    final (startX, endX) = findWordAt(lines, localX, localY);
    ctrl._selectionStart = _selectionPointForLocal(startX, localY);
    ctrl._selectionEnd = _selectionPointForLocal(endX, localY);
    ctrl._selecting = false;
    _emitSelectionChanged(ctrl);
  }

  void _selectLineAt(SelectionController ctrl, int localY) {
    final lines = _getContentLines();
    final (startX, endX) = findLineAt(lines, localY);
    ctrl._selectionStart = _selectionPointForLocal(startX, localY);
    ctrl._selectionEnd = _selectionPointForLocal(endX, localY);
    ctrl._selecting = false;
    _emitSelectionChanged(ctrl);
  }

  void _maybeAutoScrollSharedSelection(MouseMsg event) {
    if (!_usingSharedController) return;
    final scrollController = _sharedScrollController;
    if (scrollController == null) return;

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
    return null;
  }

  @override
  void dispose() {
    _listeningController?.removeListener(_handleControllerChanged);
    _registeredController?._unregisterParticipant(this);
    super.dispose();
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

    if (msg is MouseMsg) {
      if (_hitTestedThisFrame && !_isDragging) {
        _hitTestedThisFrame = false;
      } else if (msg.action == MouseAction.motion ||
          msg.action == MouseAction.release) {
        _hitTestedThisFrame = false;
        final cmd = _handleRawMouse(msg);
        if (cmd != null) return cmd;
        if (!_isDragging &&
            !_justFinishedDrag &&
            msg.action == MouseAction.release &&
            msg.button == MouseButton.left) {
          _clearSelectionOnOutsideClick();
        }
        _justFinishedDrag = false;
      } else if (msg.action == MouseAction.press &&
          msg.button == MouseButton.left) {
        _clearSelectionOnOutsideClick();
      }
    }

    if (msg is KeyMsg) {
      final cmd = _handleSelectionKey(msg);
      if (cmd != null) return cmd;
    }

    return null;
  }

  Cmd? _handleSelectionMouse(HitTestMouseMsg msg) {
    final ctrl = _effectiveController;
    final event = msg.event;
    final localX = msg.localX.toInt();
    final localY = msg.localY.toInt();

    if (event.action == MouseAction.motion && _isDragging) {
      _maybeAutoScrollSharedSelection(event);
      ctrl._selectionEnd = _usingSharedController
          ? _selectionPointForEvent(event)
          : (x: localX, y: localY);
      _emitSelectionChanged(ctrl);
      return null;
    }
    if (event.action == MouseAction.release && _isDragging) {
      ctrl._selecting = false;
      _isDragging = false;
      _justFinishedDrag = true;
      elementOf(widget)?.releaseMouse();
      _emitSelectionChanged(ctrl);
      return null;
    }

    if (event.button == MouseButton.left && event.action == MouseAction.press) {
      final now = DateTime.now();
      final screenPos = _selectionPointForEvent(event);
      final clickCount = _updateClickCount(ctrl, now, screenPos);

      if (clickCount == 2) {
        _selectWordAt(ctrl, localX, localY);
        _markNeedsPaint();
        return null;
      }
      if (clickCount >= 3) {
        _selectLineAt(ctrl, localY);
        _markNeedsPaint();
        return null;
      }

      ctrl.clearSelection();
      ctrl._selectionStart = _usingSharedController
          ? screenPos
          : (x: localX, y: localY);
      ctrl._selectionEnd = ctrl._selectionStart;
      ctrl._selecting = true;
      _isDragging = true;
      _screenToLocalDx = event.x.toDouble() - localX;
      _screenToLocalDy = event.y.toDouble() - localY;
      elementOf(widget)?.captureMouse();
      _emitSelectionChanged(ctrl);
      return null;
    }

    return null;
  }

  Cmd? _handleRawMouse(MouseMsg msg) {
    if (!_isDragging) return null;
    final ctrl = _effectiveController;
    final localX = (msg.x - _screenToLocalDx).toInt();
    final localY = (msg.y - _screenToLocalDy).toInt();

    if (msg.action == MouseAction.motion) {
      _maybeAutoScrollSharedSelection(msg);
      ctrl._selectionEnd = _usingSharedController
          ? _selectionPointForEvent(msg)
          : (x: localX, y: localY);
      _emitSelectionChanged(ctrl);
      return null;
    }
    if (msg.action == MouseAction.release) {
      ctrl._selecting = false;
      _isDragging = false;
      _justFinishedDrag = true;
      elementOf(widget)?.releaseMouse();
      _emitSelectionChanged(ctrl);
      return null;
    }
    return null;
  }

  Cmd? _handleSelectionKey(KeyMsg msg) {
    final ctrl = _effectiveController;
    if (msg.key.char != 'c' || !msg.key.ctrl || !ctrl.hasSelection) {
      return null;
    }

    if (_usingSharedController) {
      return null;
    }

    final text = ctrl.getSelectedText(_getContentLines());
    if (text.isEmpty) return null;
    return Cmd.setClipboard(text);
  }

  @override
  Widget build(BuildContext context) {
    _syncControllerListener();
    _refreshParticipantRegistration();

    final ctrl = _effectiveController;
    final selectionHighlightStyle =
        widget.selectionHighlightStyle ??
        selectionHighlightStyleForTheme(ThemeScope.of(context));

    return _SelectableTextRender(
      text: widget.text,
      selectionStart: _localSelectionPoint(ctrl.selectionStart),
      selectionEnd: _localSelectionPoint(ctrl.selectionEnd),
      selectionHighlightStyle: selectionHighlightStyle,
    );
  }
}

/// Internal widget that creates the [RenderSelectableText].
class _SelectableTextRender extends LeafRenderObjectWidget {
  _SelectableTextRender({
    required this.text,
    required this.selectionHighlightStyle,
    this.selectionStart,
    this.selectionEnd,
  });

  final String text;
  final Style selectionHighlightStyle;
  final SelectionPoint? selectionStart;
  final SelectionPoint? selectionEnd;

  @override
  RenderObject createRenderObject() {
    return RenderSelectableText(
      text: text,
      selectionHighlightStyle: selectionHighlightStyle,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as RenderSelectableText;
    ro
      ..text = text
      ..selectionHighlightStyle = selectionHighlightStyle
      ..selectionStart = selectionStart
      ..selectionEnd = selectionEnd;
  }

  @override
  Object view() => text;
}

String _renderPlainText(
  String data, {
  Style? style,
  required TextAlign textAlign,
  required bool softWrap,
  required TextOverflow overflow,
  int? maxWidth,
}) {
  var content = data;
  if (style != null) {
    final resolved = style.copy();
    content = resolved.render(content);
  }
  return _finalizeRenderedText(
    content,
    textAlign: textAlign,
    softWrap: softWrap,
    overflow: overflow,
    maxWidth: maxWidth,
  );
}

String _renderRichSpanText(
  TextSpan text, {
  Style? baseStyle,
  required TextAlign textAlign,
  required bool softWrap,
  required TextOverflow overflow,
  int? maxWidth,
}) {
  return _finalizeRenderedText(
    _renderSelectableSpan(text, baseStyle),
    textAlign: textAlign,
    softWrap: softWrap,
    overflow: overflow,
    maxWidth: maxWidth,
  );
}

String _renderSelectableView(
  Object content, {
  required TextAlign textAlign,
  required bool softWrap,
  required TextOverflow overflow,
  int? maxWidth,
}) {
  return _finalizeRenderedText(
    _viewToSelectableString(content),
    textAlign: textAlign,
    softWrap: softWrap,
    overflow: overflow,
    maxWidth: maxWidth,
  );
}

String _finalizeRenderedText(
  String content, {
  required TextAlign textAlign,
  required bool softWrap,
  required TextOverflow overflow,
  int? maxWidth,
}) {
  if (softWrap) {
    final wrapWidth = Layout.getWidth(content);
    content = Layout.wrapLines(content, wrapWidth);
  }

  if (overflow == TextOverflow.ellipsis && maxWidth != null) {
    content = Layout.truncateLines(content, maxWidth, ellipsis: '...');
  }

  final lines = content.split('\n');
  final renderedWidth = lines.isEmpty
      ? 0
      : lines.map(Layout.visibleLength).reduce(math.max);

  final aligned = switch (textAlign) {
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

String _viewToSelectableString(Object content) {
  if (content is String) return content;
  if (content is View) return content.content;
  return content.toString();
}

String _renderSelectableSpan(TextSpan span, Style? baseStyle) {
  final buffer = StringBuffer();
  Style? resolvedStyle;
  if (baseStyle != null || span.style != null) {
    resolvedStyle = (baseStyle ?? Style()).copy();
    if (span.style != null) {
      resolvedStyle.inherit(span.style!);
    }
  }

  final text = span.text;
  if (text != null && text.isNotEmpty) {
    if (resolvedStyle != null) {
      buffer.write(resolvedStyle.render(text));
    } else {
      buffer.write(text);
    }
  }

  for (final child in span.children) {
    buffer.write(_renderSelectableSpan(child, resolvedStyle ?? baseStyle));
  }

  return buffer.toString();
}

RenderObject? _firstRenderObjectForWidget(Widget widget) {
  final element = elementOf(widget);
  if (element == null) return null;

  RenderObject? visit(Element current) {
    if (current is RenderObjectElement) {
      return current.renderObject;
    }
    for (final child in current.children) {
      final found = visit(child);
      if (found != null) return found;
    }
    return null;
  }

  return visit(element);
}

double _renderObjectGlobalX(RenderObject ro) {
  double x = 0;
  RenderObject? current = ro;
  while (current != null) {
    x += current.offset.dx;
    current = current.parent;
  }
  return x;
}

double _renderObjectGlobalY(RenderObject ro) {
  double y = 0;
  RenderObject? current = ro;
  while (current != null) {
    y += current.offset.dy;
    y -= _renderObjectScrollYOffset(current);
    current = current.parent;
  }
  return y;
}

double _renderObjectScreenY(RenderObject ro) {
  double y = 0;
  RenderObject? current = ro;
  while (current != null) {
    y += current.offset.dy;
    current = current.parent;
  }
  return y;
}

double _renderObjectScrollYOffset(RenderObject ro) {
  if (ro is RenderSingleChildViewport) {
    return ro.controller.offset.toDouble();
  }
  if (ro is RenderListViewScrollViewport) {
    return ro.controller.offset.toDouble();
  }
  if (ro is RenderListViewport) {
    return ro.controller.offset.toDouble();
  }
  if (ro is RenderViewport) {
    return ro.controller.offset.toDouble();
  }
  return 0;
}
