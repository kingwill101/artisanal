part of 'selection_widgets.dart';

/// A render object that paints text with optional selection highlighting.
class RenderSelectableText extends RenderBox {
  RenderSelectableText({
    required this.text,
    required this.selectionHighlightStyle,
    this.selectionHighlightRangesByLine,
    this.selectionStart,
    this.selectionEnd,
  });

  String text;
  Style selectionHighlightStyle;
  List<List<StyleRange>>? selectionHighlightRangesByLine;
  SelectionPoint? selectionStart;
  SelectionPoint? selectionEnd;
  int _cachedMaxWidth = -1;
  String? _cachedTextKey;
  List<String>? _cachedBaseLines;
  List<int>? _cachedBaseLineWidths;
  List<bool>? _cachedBaseLineHasAnsi;
  String? _cachedBaseText;

  void _ensureBaseCache(int maxWidth) {
    if (_cachedBaseLines != null &&
        _cachedMaxWidth == maxWidth &&
        _cachedTextKey == text) {
      return;
    }

    _cachedMaxWidth = maxWidth;
    _cachedTextKey = text;
    final baseLines = <String>[];
    final baseLineWidths = <int>[];
    final baseLineHasAnsi = <bool>[];

    for (final rawLine in text.split('\n')) {
      var line = rawLine;
      var width = Style.visibleLength(line);
      if (width > maxWidth) {
        line = Layout.truncate(line, maxWidth, ellipsis: '');
        width = Style.visibleLength(line);
      }
      baseLines.add(line);
      baseLineWidths.add(width);
      baseLineHasAnsi.add(line.contains('\x1b'));
    }

    _cachedBaseLines = List.unmodifiable(baseLines);
    _cachedBaseLineWidths = List.unmodifiable(baseLineWidths);
    _cachedBaseLineHasAnsi = List.unmodifiable(baseLineHasAnsi);
    _cachedBaseText = baseLines.join('\n');
  }

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
    _ensureBaseCache(maxW);

    final baseLines = _cachedBaseLines!;
    final baseLineWidths = _cachedBaseLineWidths!;
    final baseLineHasAnsi = _cachedBaseLineHasAnsi!;
    final start = selectionStart;
    final end = selectionEnd;
    if (start != null && end != null) {
      final customRanges = selectionHighlightRangesByLine;
      final lines = customRanges == null
          ? applySelectionHighlighting(
              baseLines,
              offset: 0,
              selectionStart: start,
              selectionEnd: end,
              highlightStyle: selectionHighlightStyle,
              lineWidths: baseLineWidths,
              lineHasAnsi: baseLineHasAnsi,
            )
          : applySelectionHighlightingWithRanges(
              baseLines,
              offset: 0,
              selectionStart: start,
              selectionEnd: end,
              highlightStyle: selectionHighlightStyle,
              lineWidths: baseLineWidths,
              lineHasAnsi: baseLineHasAnsi,
              lineHighlightRanges: [
                for (var i = 0; i < baseLines.length; i++)
                  i < customRanges.length
                      ? [
                          for (final range in customRanges[i])
                            StyleRange(
                              range.start.clamp(0, maxW),
                              range.end.clamp(0, maxW),
                              range.style,
                            ),
                        ]
                      : const <StyleRange>[],
              ],
            );
      return lines.join('\n');
    }
    return _cachedBaseText!;
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
    this.selectionHighlightRangesByLine,
    this.controller,
    this.selectionHighlightStyle,
  });

  final String text;
  final List<List<StyleRange>>? selectionHighlightRangesByLine;
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

  int _updateClickCount(SelectionController ctrl, SelectionPoint screenPos) =>
      ctrl.registerClick(screenPos);

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
      final screenPos = _selectionPointForEvent(event);
      final clickCount = _updateClickCount(ctrl, screenPos);

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
      selectionHighlightRangesByLine: widget.selectionHighlightRangesByLine,
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
    this.selectionHighlightRangesByLine,
    this.selectionStart,
    this.selectionEnd,
  });

  final String text;
  final Style selectionHighlightStyle;
  final List<List<StyleRange>>? selectionHighlightRangesByLine;
  final SelectionPoint? selectionStart;
  final SelectionPoint? selectionEnd;

  @override
  RenderObject createRenderObject() {
    return RenderSelectableText(
      text: text,
      selectionHighlightStyle: selectionHighlightStyle,
      selectionHighlightRangesByLine: selectionHighlightRangesByLine,
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
      ..selectionHighlightRangesByLine = selectionHighlightRangesByLine
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

_SelectableRenderedContent _renderRichSpanContent(
  TextSpan text, {
  Style? baseStyle,
  required TextAlign textAlign,
  required bool softWrap,
  required TextOverflow overflow,
  int? maxWidth,
}) {
  return _finalizeRenderedContent(
    _renderSelectableSpanContent(text, baseStyle),
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

final class _SelectableRenderedContent {
  const _SelectableRenderedContent({
    required this.text,
    required this.selectionHighlightRangesByLine,
  });

  final String text;
  final List<List<StyleRange>> selectionHighlightRangesByLine;
}

final class _SelectableRenderedContentBuilder {
  _SelectableRenderedContentBuilder()
    : _lineBuffers = <StringBuffer>[StringBuffer()],
      _selectionRangesByLine = <List<StyleRange>>[<StyleRange>[]],
      _lineWidths = <int>[0];

  final List<StringBuffer> _lineBuffers;
  final List<List<StyleRange>> _selectionRangesByLine;
  final List<int> _lineWidths;

  void addText(String text, {Style? renderStyle, Style? selectionStyle}) {
    final parts = text.split('\n');
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        final lineIndex = _lineBuffers.length - 1;
        final start = _lineWidths[lineIndex];
        final rendered = renderStyle != null ? renderStyle.render(part) : part;
        _lineBuffers[lineIndex].write(rendered);
        final width = Layout.visibleLength(part);
        if (selectionStyle != null && width > 0) {
          _selectionRangesByLine[lineIndex].add(
            StyleRange(start, start + width, selectionStyle),
          );
        }
        _lineWidths[lineIndex] = start + width;
      }
      if (i < parts.length - 1) {
        _lineBuffers.add(StringBuffer());
        _selectionRangesByLine.add(<StyleRange>[]);
        _lineWidths.add(0);
      }
    }
  }

  _SelectableRenderedContent build() {
    return _SelectableRenderedContent(
      text: _lineBuffers.map((buffer) => buffer.toString()).join('\n'),
      selectionHighlightRangesByLine: [
        for (final ranges in _selectionRangesByLine)
          List<StyleRange>.unmodifiable(ranges),
      ],
    );
  }
}

_SelectableRenderedContent _renderSelectableSpanContent(
  TextSpan span,
  Style? baseStyle, {
  Style? inheritedSelectionStyle,
  _SelectableRenderedContentBuilder? builder,
}) {
  final contentBuilder = builder ?? _SelectableRenderedContentBuilder();
  Style? resolvedStyle;
  if (baseStyle != null || span.style != null) {
    resolvedStyle = (baseStyle ?? Style()).copy();
    if (span.style != null) {
      resolvedStyle.inherit(span.style!);
    }
  }

  final resolvedSelectionStyle =
      span.selectionHighlightStyle ?? inheritedSelectionStyle;

  final text = span.text;
  if (text != null && text.isNotEmpty) {
    contentBuilder.addText(
      text,
      renderStyle: resolvedStyle,
      selectionStyle: resolvedSelectionStyle,
    );
  }

  for (final child in span.children) {
    _renderSelectableSpanContent(
      child,
      resolvedStyle ?? baseStyle,
      inheritedSelectionStyle: resolvedSelectionStyle,
      builder: contentBuilder,
    );
  }

  return contentBuilder.build();
}

_SelectableRenderedContent _finalizeRenderedContent(
  _SelectableRenderedContent content, {
  required TextAlign textAlign,
  required bool softWrap,
  required TextOverflow overflow,
  int? maxWidth,
}) {
  var lines = content.text.split('\n');
  var rangesByLine = [
    for (final ranges in content.selectionHighlightRangesByLine)
      List<StyleRange>.from(ranges),
  ];

  if (softWrap) {
    final wrapWidth = Layout.getWidth(content.text);
    if (wrapWidth > 0) {
      // Current selectable rich text preserves line structure; wrapping to the
      // widest line matches the existing no-op behavior.
      lines = lines;
    }
  }

  if (overflow == TextOverflow.ellipsis && maxWidth != null) {
    for (var i = 0; i < lines.length; i++) {
      lines[i] = Layout.truncate(lines[i], maxWidth, ellipsis: '...');
      rangesByLine[i] = [
        for (final range in rangesByLine[i])
          if (range.start < maxWidth && range.end > 0)
            StyleRange(
              range.start.clamp(0, maxWidth),
              range.end.clamp(0, maxWidth),
              range.style,
            ),
      ];
    }
  }

  final renderedWidth = lines.isEmpty
      ? 0
      : lines.map(Layout.visibleLength).reduce(math.max);

  if (textAlign != TextAlign.left) {
    for (var i = 0; i < lines.length; i++) {
      final lineWidth = Layout.visibleLength(lines[i]);
      final shortAmount = renderedWidth - lineWidth;
      if (shortAmount <= 0) continue;
      final padLeft = switch (textAlign) {
        TextAlign.center => shortAmount ~/ 2,
        TextAlign.right => shortAmount,
        _ => 0,
      };
      final padRight = switch (textAlign) {
        TextAlign.center => shortAmount - padLeft,
        TextAlign.right => 0,
        _ => shortAmount,
      };
      if (padLeft > 0 || padRight > 0) {
        lines[i] = '${' ' * padLeft}${lines[i]}${' ' * padRight}';
        if (padLeft > 0) {
          rangesByLine[i] = [
            for (final range in rangesByLine[i])
              StyleRange(
                range.start + padLeft,
                range.end + padLeft,
                range.style,
              ),
          ];
        }
      }
    }
  }

  return _SelectableRenderedContent(
    text: lines.join('\n'),
    selectionHighlightRangesByLine: [
      for (final ranges in rangesByLine) List<StyleRange>.unmodifiable(ranges),
    ],
  );
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
