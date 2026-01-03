import 'dart:math' as math;

import '../../style/ranges.dart' as ranges;
import '../../style/color.dart';
import '../../style/style.dart';
import '../../terminal/ansi.dart';
import '../../layout/layout.dart';
import '../../unicode/grapheme.dart' as uni;
import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'key_binding.dart';

const undefined = Object();

/// Key bindings for viewport navigation.
class ViewportKeyMap implements KeyMap {
  ViewportKeyMap({
    KeyBinding? pageDown,
    KeyBinding? pageUp,
    KeyBinding? halfPageUp,
    KeyBinding? halfPageDown,
    KeyBinding? down,
    KeyBinding? up,
    KeyBinding? left,
    KeyBinding? right,
    KeyBinding? copy,
  }) : pageDown =
           pageDown ??
           KeyBinding.withHelp(['pgdown', ' ', 'f'], 'f/pgdn', 'page down'),
       pageUp =
           pageUp ?? KeyBinding.withHelp(['pgup', 'b'], 'b/pgup', 'page up'),
       halfPageUp =
           halfPageUp ?? KeyBinding.withHelp(['u', 'ctrl+u'], 'u', '½ page up'),
       halfPageDown =
           halfPageDown ??
           KeyBinding.withHelp(['d', 'ctrl+d'], 'd', '½ page down'),
       down = down ?? KeyBinding.withHelp(['down', 'j'], '↓/j', 'down'),
       up = up ?? KeyBinding.withHelp(['up', 'k'], '↑/k', 'up'),
       left = left ?? KeyBinding.withHelp(['left', 'h'], '←/h', 'left'),
       right = right ?? KeyBinding.withHelp(['right', 'l'], '→/l', 'right'),
       copy = copy ?? KeyBinding.withHelp(['ctrl+c', 'y'], 'y', 'copy');

  final KeyBinding pageDown;
  final KeyBinding pageUp;
  final KeyBinding halfPageUp;
  final KeyBinding halfPageDown;
  final KeyBinding down;
  final KeyBinding up;
  final KeyBinding left;
  final KeyBinding right;
  final KeyBinding copy;

  @override
  List<KeyBinding> shortHelp() => [up, down, pageUp, pageDown, copy];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [up, down, pageUp, pageDown],
    [halfPageUp, halfPageDown, left, right, copy],
  ];
}

/// GutterContext provides context to a [GutterFunc].
class GutterContext {
  /// Index is the line index of the line which the gutter is being rendered for.
  final int index;

  /// TotalLines is the total number of lines in the viewport.
  final int totalLines;

  /// Soft is whether or not the line is soft wrapped.
  final bool soft;

  GutterContext({
    required this.index,
    required this.totalLines,
    required this.soft,
  });
}

/// GutterFunc can be implemented and set into [ViewportModel.leftGutterFunc].
typedef GutterFunc = String Function(GutterContext context);

/// A viewport widget for scrollable content.
///
/// The viewport manages a scrollable view of content that may be larger
/// than the available display area. It supports vertical and horizontal
/// scrolling with keyboard and mouse input.
///
/// ## Example
///
/// ```dart
/// class DocViewerModel implements Model {
///   final ViewportModel viewport;
///   final String content;
///
///   DocViewerModel({ViewportModel? viewport, this.content = ''})
///       : viewport = (viewport ?? ViewportModel(width: 80, height: 24))
///           ..setContent(content);
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // Handle window resize
///     if (msg is WindowSizeMsg) {
///       return (
///         DocViewerModel(
///           viewport: viewport.copyWith(
///             width: msg.width,
///             height: msg.height - 2, // Leave room for status
///           ),
///           content: content,
///         ),
///         null,
///       );
///     }
///
///     final (newViewport, cmd) = viewport.update(msg);
///     return (
///       DocViewerModel(viewport: newViewport as ViewportModel, content: content),
///       cmd,
///     );
///   }
///
///   @override
///   String view() => '''
/// ${viewport.view()}
/// ${(viewport.scrollPercent * 100).toInt()}%
/// ''';
/// }
/// ```
class ViewportModel extends ViewComponent {
  /// Creates a new viewport model.
  ViewportModel({
    this.width = 80,
    this.height = 24,
    this.gutter = 0,
    this.yOffset = 0,
    this.xOffset = 0,
    this.mouseWheelEnabled = true,
    this.mouseWheelDelta = 3,
    this.horizontalStep = 6,
    this.softWrap = false,
    this.fillHeight = false,
    this.showLineNumbers = false,
    this.leftGutterFunc,
    Style? style,
    Style? highlightStyle,
    Style? selectedHighlightStyle,
    this.styleLineFunc,
    List<HighlightInfo>? highlights,
    this.currentHighlightIndex = -1,
    this.selectionStart,
    this.selectionEnd,
    this.lastClickTime,
    this.lastClickPos,
    ViewportKeyMap? keyMap,
    List<String>? lines,
    List<String>? wrappedLines,
    List<String>? originalLines,
  }) : style = style ?? Style(),
       highlightStyle = highlightStyle ?? Style(),
       selectedHighlightStyle = selectedHighlightStyle ?? Style(),
       keyMap = keyMap ?? ViewportKeyMap(),
       _highlights = highlights ?? const [],
       _lines = lines ?? [],
       _wrappedLines = wrappedLines ?? lines ?? [],
       _originalLines = originalLines ?? lines ?? [];

  /// Width of the viewport in columns.
  final int width;

  /// Height of the viewport in rows. If null, the viewport will show all
  /// lines and will not scroll vertically.
  final int? height;

  /// Left gutter (spaces) applied to each rendered line. Also reduces
  /// available content width.
  final int gutter;

  /// Vertical scroll offset (0 = top).
  final int yOffset;

  /// Horizontal scroll offset (0 = left).
  final int xOffset;

  /// Whether mouse wheel scrolling is enabled.
  final bool mouseWheelEnabled;

  /// Number of lines to scroll per mouse wheel tick.
  final int mouseWheelDelta;

  /// Number of columns to scroll left/right. 0 disables horizontal scrolling.
  final int horizontalStep;

  /// Whether to wrap lines that exceed the viewport width.
  final bool softWrap;

  /// Whether to fill to the height of the viewport with empty lines.
  final bool fillHeight;

  /// Whether to show line numbers in the gutter.
  final bool showLineNumbers;

  /// A function that returns the gutter for a given line index.
  /// If provided, [gutter] is ignored for rendering but still used
  /// for width calculations.
  final GutterFunc? leftGutterFunc;

  /// Style applies a lipgloss style to the viewport. Realistically, it's most
  /// useful for setting borders, margins and padding.
  final Style style;

  /// HighlightStyle highlights the ranges set with [SetHighlights].
  final Style highlightStyle;

  /// SelectedHighlightStyle highlights the highlight range focused during
  /// navigation.
  final Style selectedHighlightStyle;

  /// StyleLineFunc allows to return a [Style] for each line.
  /// The argument is the line index.
  final Style Function(int lineIndex)? styleLineFunc;

  /// Internal highlight information.
  final List<HighlightInfo> _highlights;

  /// The index of the currently focused highlight.
  final int currentHighlightIndex;

  /// Returns the current highlights.
  List<HighlightInfo> get highlights => _highlights;

  /// The start of the selection (x, y) in content coordinates.
  final (int, int)? selectionStart;

  /// The end of the selection (x, y) in content coordinates.
  final (int, int)? selectionEnd;

  /// The time of the last mouse click.
  final DateTime? lastClickTime;

  /// The position of the last mouse click.
  final (int, int)? lastClickPos;

  /// Key bindings for navigation.
  final ViewportKeyMap keyMap;

  final List<String> _lines;
  final List<String> _wrappedLines;
  final List<String> _originalLines;
  int _longestLineWidth = 0;

  /// The content lines.
  List<String> get lines => softWrap ? _wrappedLines : _lines;

  /// Internal lines (unwrapped).
  List<String> get internalLines => _lines;

  /// Internal wrapped lines.
  List<String> get internalWrappedLines => _wrappedLines;

  /// Internal original lines (before styling).
  List<String> get internalOriginalLines => _originalLines;

  /// calculateLine taking soft wrapping into account, returns the total viewable
  /// lines and the real-line index for the given yoffset, as well as the virtual
  /// line offset.
  (int total, int ridx, int voffset) calculateLine(int yoffset) {
    if (!softWrap) {
      return (_lines.length, math.min(yoffset, _lines.length), 0);
    }

    final maxWidth = _maxWidth().toDouble();
    if (maxWidth <= 0) return (0, 0, 0);

    var total = 0;
    var ridx = 0;
    var voffset = 0;

    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final lineWidth = Style.visibleLength(line);
      final lineHeight = math.max(1, (lineWidth / maxWidth).ceil());

      if (yoffset >= total && yoffset < total + lineHeight) {
        ridx = i;
        voffset = yoffset - total;
      }
      total += lineHeight;
    }

    if (yoffset >= total) {
      ridx = _lines.length;
      voffset = 0;
    }

    return (total, ridx, voffset);
  }

  int _maxWidth() {
    var gutterSize = 0;
    if (leftGutterFunc != null) {
      gutterSize = Style.visibleLength(
        leftGutterFunc!(GutterContext(index: 0, totalLines: 0, soft: false)),
      );
    } else {
      gutterSize = gutter;
    }
    return math.max(0, width - style.getHorizontalFrameSize - gutterSize);
  }

  int _maxHeight() {
    if (height == null) {
      final (total, _, _) = calculateLine(0);
      return total;
    }
    return math.max(0, height! - style.getVerticalFrameSize);
  }

  int get _contentWidth => _maxWidth();

  /// Creates a copy with the given fields replaced.
  ViewportModel copyWith({
    int? width,
    int? height,
    int? yOffset,
    int? xOffset,
    bool? mouseWheelEnabled,
    int? mouseWheelDelta,
    int? horizontalStep,
    ViewportKeyMap? keyMap,
    List<String>? lines,
    int? gutter,
    bool? softWrap,
    bool? fillHeight,
    bool? showLineNumbers,
    GutterFunc? leftGutterFunc,
    Style? style,
    Style? highlightStyle,
    Style? selectedHighlightStyle,
    Style Function(int lineIndex)? styleLineFunc,
    List<HighlightInfo>? highlights,
    int? currentHighlightIndex,
    Object? selectionStart = undefined,
    Object? selectionEnd = undefined,
    DateTime? lastClickTime,
    (int, int)? lastClickPos,
  }) {
    final newWidth = width ?? this.width;
    final newGutter = gutter ?? this.gutter;
    final newSoftWrap = softWrap ?? this.softWrap;
    final newFillHeight = fillHeight ?? this.fillHeight;
    final newShowLineNumbers = showLineNumbers ?? this.showLineNumbers;
    final newOriginalLines = lines ?? _originalLines;
    final newHighlights = highlights ?? _highlights;
    final newSelectionStart = selectionStart == undefined
        ? this.selectionStart
        : selectionStart as (int, int)?;
    final newSelectionEnd = selectionEnd == undefined
        ? this.selectionEnd
        : selectionEnd as (int, int)?;

    // Apply highlights to original lines
    var styledLines = newOriginalLines;
    // Note: In v2-exp, highlights are applied during rendering (visibleLines),
    // but we'll keep the current approach for now if it works, or migrate to
    // on-the-fly styling if needed for performance.
    // Actually, let's follow upstream and apply them in visibleLines.

    final newModel = ViewportModel(
      width: newWidth,
      height: height ?? this.height,
      gutter: newGutter,
      yOffset: yOffset ?? this.yOffset,
      xOffset: xOffset ?? this.xOffset,
      mouseWheelEnabled: mouseWheelEnabled ?? this.mouseWheelEnabled,
      mouseWheelDelta: mouseWheelDelta ?? this.mouseWheelDelta,
      horizontalStep: horizontalStep ?? this.horizontalStep,
      keyMap: keyMap ?? this.keyMap,
      lines: styledLines,
      originalLines: newOriginalLines,
      softWrap: newSoftWrap,
      fillHeight: newFillHeight,
      showLineNumbers: newShowLineNumbers,
      leftGutterFunc: leftGutterFunc ?? this.leftGutterFunc,
      style: style ?? this.style,
      highlightStyle: highlightStyle ?? this.highlightStyle,
      selectedHighlightStyle:
          selectedHighlightStyle ?? this.selectedHighlightStyle,
      styleLineFunc: styleLineFunc ?? this.styleLineFunc,
      highlights: newHighlights,
      currentHighlightIndex:
          currentHighlightIndex ?? this.currentHighlightIndex,
      selectionStart: newSelectionStart,
      selectionEnd: newSelectionEnd,
      lastClickTime: lastClickTime ?? this.lastClickTime,
      lastClickPos: lastClickPos ?? this.lastClickPos,
    );
    newModel._longestLineWidth = _findLongestLineWidth(styledLines);
    return newModel;
  }

  /// Clears the current selection.
  ViewportModel clearSelection() {
    return copyWith(selectionStart: null, selectionEnd: null);
  }

  /// Selects all text in the viewport.
  ViewportModel selectAll() {
    if (_lines.isEmpty) return this;
    return copyWith(
      selectionStart: (0, 0),
      selectionEnd: (_lines.last.length, _lines.length - 1),
    );
  }

  (int, int) _findWordAt(int x, int y) {
    if (y < 0 || y >= lines.length) return (x, x);
    final line = Style.stripAnsi(lines[y]);
    if (x < 0 || x >= line.length) return (x, x);

    if (_isWhitespace(line[x])) {
      // Find whitespace block
      var start = x;
      while (start > 0 && _isWhitespace(line[start - 1])) {
        start--;
      }
      var end = x;
      while (end < line.length && _isWhitespace(line[end])) {
        end++;
      }
      return (start, end);
    } else {
      // Find word block
      var start = x;
      while (start > 0 && !_isWhitespace(line[start - 1])) {
        start--;
      }
      var end = x;
      while (end < line.length && !_isWhitespace(line[end])) {
        end++;
      }
      return (start, end);
    }
  }

  bool _isWhitespace(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  /// Sets the content of the viewport.
  ViewportModel setContent(String content) {
    final normalized = content.replaceAll('\r\n', '\n');
    final newLines = normalized.split('\n');
    final newModel = copyWith(lines: newLines);
    newModel._longestLineWidth = _findLongestLineWidth(newLines);

    // Adjust offset if content is shorter
    if (newModel.yOffset > newModel._maxYOffset) {
      return newModel.gotoBottom();
    }
    return newModel;
  }

  /// Maximum Y offset based on content and height.
  int get _maxYOffset {
    final (total, _, _) = calculateLine(0);
    final h = _maxHeight();
    if (h == 0) return math.max(0, total - (height ?? 0));
    return math.max(0, total - h);
  }

  /// Whether the viewport is at the top.
  bool get atTop => yOffset <= 0;

  /// Whether the viewport is at the bottom.
  bool get atBottom => yOffset >= _maxYOffset;

  /// Whether the viewport is scrolled past the bottom.
  bool get pastBottom => yOffset > _maxYOffset;

  /// Returns the scroll percentage (0.0 to 1.0).
  double get scrollPercent {
    final (total, _, _) = calculateLine(0);
    final h = _maxHeight();
    if (h >= total || h == 0) return 1.0;
    final y = yOffset.toDouble();
    final t = total.toDouble();
    final v = y / (t - h);
    return v.clamp(0.0, 1.0);
  }

  /// Sets ranges of characters to highlight.
  /// For instance, `[[2, 10], [20, 30]]` will highlight characters
  /// 2 to 10 and 20 to 30.
  /// Note that highlights are not expected to transpose each other, and are also
  /// expected to be in order.
  ViewportModel setHighlights(List<List<int>> matches) {
    if (matches.isEmpty || _lines.isEmpty) {
      return copyWith(highlights: []);
    }
    final highlights = _parseMatches(_originalLines.join('\n'), matches);
    final newModel = copyWith(highlights: highlights);
    return newModel
        .copyWith(currentHighlightIndex: newModel._findNearestMatch())
        ._showHighlight();
  }

  /// Clears previously set highlights.
  ViewportModel clearHighlights() {
    return copyWith(highlights: [], currentHighlightIndex: -1);
  }

  ViewportModel _showHighlight() {
    if (currentHighlightIndex == -1 || _highlights.isEmpty) {
      return this;
    }
    final (line, colstart, colend) = _highlights[currentHighlightIndex]
        .coords();
    return ensureVisible(line, colstart, colend);
  }

  /// Moves the viewport to the next highlight.
  ViewportModel highlightNext() {
    if (_highlights.isEmpty) return this;
    final nextIndex = (currentHighlightIndex + 1) % _highlights.length;
    return copyWith(currentHighlightIndex: nextIndex)._showHighlight();
  }

  /// Moves the viewport to the previous highlight.
  ViewportModel highlightPrev() {
    if (_highlights.isEmpty) return this;
    final prevIndex =
        (currentHighlightIndex - 1 + _highlights.length) % _highlights.length;
    return copyWith(currentHighlightIndex: prevIndex)._showHighlight();
  }

  int _findNearestMatch() {
    for (var i = 0; i < _highlights.length; i++) {
      if (_highlights[i].lineStart >= yOffset) {
        return i;
      }
    }
    return -1;
  }

  /// Ensures that the given line and column are in the viewport.
  ViewportModel ensureVisible(int line, int colstart, int colend) {
    final maxWidth = _maxWidth();
    var newModel = this;
    if (softWrap) {
      // In soft-wrap mode, horizontal scrolling isn't meaningful: instead we map
      // the target to a virtual y-offset (wrapped subline).
      newModel = newModel.setXOffset(0);
    } else if (colend <= maxWidth) {
      newModel = newModel.setXOffset(0);
    } else {
      newModel = newModel.setXOffset(colstart - horizontalStep);
    }

    final targetYOffset = softWrap
        ? _virtualYOffsetFor(line, colstart, maxWidth)
        : line;
    if (targetYOffset < yOffset || targetYOffset >= yOffset + _maxHeight()) {
      newModel = newModel.setYOffset(targetYOffset);
    }
    return newModel;
  }

  int _virtualYOffsetFor(int line, int colstart, int maxWidth) {
    if (!softWrap) return line;
    if (_lines.isEmpty) return 0;
    if (maxWidth <= 0) return 0;

    final clampedLine = line.clamp(0, _lines.length);
    var total = 0;
    for (var i = 0; i < clampedLine; i++) {
      final lineWidth = Style.visibleLength(_lines[i]);
      total += math.max(1, (lineWidth / maxWidth).ceil());
    }

    // Scroll to the wrapped segment that contains colstart.
    final seg = (colstart / maxWidth).floor();
    return total + math.max(0, seg);
  }

  /// Returns the horizontal scroll percentage (0.0 to 1.0).
  double get horizontalScrollPercent {
    if (softWrap) return 1.0;
    final contentWidth = _contentWidth;
    if (contentWidth <= 0 || _longestLineWidth <= contentWidth) return 1.0;
    if (xOffset >= _longestLineWidth - contentWidth) return 1.0;
    final x = xOffset.toDouble();
    final w = contentWidth.toDouble();
    final t = _longestLineWidth.toDouble();
    final v = x / (t - w);
    return v.clamp(0.0, 1.0);
  }

  /// Total number of lines in the content.
  int get totalLineCount => _lines.length;

  /// Number of visible lines.
  int get visibleLineCount => _visibleLines().length;

  /// Returns the visible lines based on current scroll position.
  List<String> _visibleLines() {
    final maxHeight = _maxHeight();
    final maxWidth = _maxWidth();

    if (maxHeight == 0 || maxWidth == 0) {
      return [];
    }

    final (total, ridx, voffset) = calculateLine(yOffset);
    var visible = <String>[];

    if (total > 0) {
      final bottom = (ridx + maxHeight).clamp(ridx, _lines.length);
      visible = _lines.sublist(ridx, bottom);
      visible = _styleLines(visible, ridx);
      visible = _highlightLines(visible, ridx);
      visible = _applySelection(visible, ridx);
    }

    while (fillHeight && visible.length < maxHeight) {
      visible.add('');
    }

    // if longest line fit within width, no need to do anything else.
    if ((xOffset == 0 && _longestLineWidth <= maxWidth) || maxWidth == 0) {
      return _setupGutter(visible, total, ridx);
    }

    if (softWrap) {
      return _softWrapLines(visible, maxWidth, maxHeight, total, ridx, voffset);
    }

    // Cut the lines to the viewport width.
    for (var i = 0; i < visible.length; i++) {
      visible[i] = ranges.cutAnsiByCells(
        visible[i],
        xOffset,
        xOffset + maxWidth,
      );
    }
    return _setupGutter(visible, total, ridx);
  }

  List<String> _applySelection(List<String> lines, int offset) {
    if (selectionStart == null || selectionEnd == null) return lines;

    final (x1, y1) = selectionStart!;
    final (x2, y2) = selectionEnd!;

    final startY = math.min(y1, y2);
    final endY = math.max(y1, y2);

    if (endY < offset) return lines;
    if (startY >= offset + lines.length) return lines;

    final selectionStyle = Style()
        .background(const AnsiColor(7))
        .foreground(const AnsiColor(0));

    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final lineIdx = i + offset;
      var line = lines[i];

      if (lineIdx < startY || lineIdx > endY) {
        result.add(line);
        continue;
      }

      final maxX = Style.visibleLength(line);

      int startX;
      int endX;

      if (startY == endY) {
        startX = math.min(x1, x2);
        endX = math.max(x1, x2);
      } else if (lineIdx == startY) {
        startX = y1 < y2 ? x1 : x2;
        endX = maxX;
      } else if (lineIdx == endY) {
        startX = 0;
        endX = y1 < y2 ? x2 : x1;
      } else {
        startX = 0;
        endX = maxX;
      }

      startX = startX.clamp(0, maxX);
      endX = endX.clamp(0, maxX);
      if (startX >= endX) {
        result.add(line);
        continue;
      }

      line = ranges.styleRanges(line, [
        ranges.StyleRange(startX, endX, selectionStyle),
      ]);
      result.add(line);
    }

    return result;
  }

  List<String> _styleLines(List<String> lines, int offset) {
    if (styleLineFunc == null) return lines;
    final result = <String>[];
    for (var i = 0; i < lines.length; i++) {
      result.add(styleLineFunc!(i + offset).render(lines[i]));
    }
    return result;
  }

  List<String> _highlightLines(List<String> lines, int offset) {
    if (_highlights.isEmpty) return lines;
    final result = <String>[];
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      final lineIdx = i + offset;

      final rs = _makeHighlightRanges(_highlights, lineIdx, highlightStyle);
      line = ranges.styleRanges(line, rs);

      if (currentHighlightIndex >= 0 && !selectedHighlightStyle.isEmpty) {
        final sel = _highlights[currentHighlightIndex];
        final hi = sel.lines[lineIdx];
        if (hi != null) {
          line = ranges.styleRanges(line, [
            ranges.StyleRange(hi.$1, hi.$2, selectedHighlightStyle),
          ]);
        }
      }
      result.add(line);
    }
    return result;
  }

  List<String> _softWrapLines(
    List<String> lines,
    int maxWidth,
    int maxHeight,
    int total,
    int ridx,
    int voffset,
  ) {
    final wrappedLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      final lineWidth = Style.visibleLength(line);

      if (lineWidth <= maxWidth) {
        if (leftGutterFunc != null) {
          line =
              leftGutterFunc!(
                GutterContext(index: i + ridx, totalLines: total, soft: false),
              ) +
              line;
        }
        wrappedLines.add(line);
        continue;
      }

      var idx = 0;
      while (lineWidth > idx) {
        var truncatedLine = ranges.cutAnsiByCells(line, idx, maxWidth + idx);
        if (leftGutterFunc != null) {
          truncatedLine =
              leftGutterFunc!(
                GutterContext(
                  index: i + ridx,
                  totalLines: total,
                  soft: idx > 0,
                ),
              ) +
              truncatedLine;
        }
        wrappedLines.add(truncatedLine);
        idx += maxWidth;
      }
    }

    final start = voffset.clamp(0, wrappedLines.length);
    final end = (voffset + maxHeight).clamp(start, wrappedLines.length);
    return wrappedLines.sublist(start, end);
  }

  List<String> _setupGutter(List<String> lines, int total, int ridx) {
    if (leftGutterFunc == null) return lines;

    final result = <String>[];
    for (var i = 0; i < lines.length; i++) {
      result.add(
        leftGutterFunc!(
              GutterContext(index: i + ridx, totalLines: total, soft: false),
            ) +
            lines[i],
      );
    }
    return result;
  }

  /// Sets the Y offset (clamped to valid range).
  ViewportModel setYOffset(int n) {
    return copyWith(yOffset: n.clamp(0, _maxYOffset));
  }

  /// Sets the X offset (clamped to valid range).
  ViewportModel setXOffset(int n) {
    if (softWrap) {
      // In soft-wrap mode horizontal scrolling doesn't apply.
      return xOffset == 0 ? this : copyWith(xOffset: 0);
    }
    final maxXOffset = _longestLineWidth - _contentWidth;
    return copyWith(xOffset: n.clamp(0, maxXOffset > 0 ? maxXOffset : 0));
  }

  /// Scrolls down by the given number of lines.
  ViewportModel scrollDown(int n) {
    if (atBottom || n == 0 || _lines.isEmpty) return this;
    final newModel = setYOffset(yOffset + n);
    return newModel.copyWith(
      currentHighlightIndex: newModel._findNearestMatch(),
    );
  }

  /// Scrolls up by the given number of lines.
  ViewportModel scrollUp(int n) {
    if (atTop || n == 0 || _lines.isEmpty) return this;
    final newModel = setYOffset(yOffset - n);
    return newModel.copyWith(
      currentHighlightIndex: newModel._findNearestMatch(),
    );
  }

  /// Scrolls left by the given number of columns.
  ViewportModel scrollLeft(int n) {
    if (softWrap) return this;
    return setXOffset(xOffset - n);
  }

  /// Scrolls right by the given number of columns.
  ViewportModel scrollRight(int n) {
    if (softWrap) return this;
    return setXOffset(xOffset + n);
  }

  /// Moves down by one page.
  ViewportModel pageDown() {
    if (atBottom || height == null) return this;
    return scrollDown(height!);
  }

  /// Moves up by one page.
  ViewportModel pageUp() {
    if (atTop || height == null) return this;
    return scrollUp(height!);
  }

  /// Moves down by half a page.
  ViewportModel halfPageDown() {
    if (atBottom || height == null) return this;
    return scrollDown(height! ~/ 2);
  }

  /// Moves up by half a page.
  ViewportModel halfPageUp() {
    if (atTop || height == null) return this;
    return scrollUp(height! ~/ 2);
  }

  /// Goes to the top of the content.
  ViewportModel gotoTop() {
    if (atTop) return this;
    final newModel = setYOffset(0);
    return newModel.copyWith(
      currentHighlightIndex: newModel._findNearestMatch(),
    );
  }

  /// Goes to the bottom of the content.
  ViewportModel gotoBottom() {
    final newModel = setYOffset(_maxYOffset);
    return newModel.copyWith(
      currentHighlightIndex: newModel._findNearestMatch(),
    );
  }

  /// Returns the currently selected text.
  String getSelectedText() {
    if (selectionStart == null || selectionEnd == null) return '';

    final (x1, y1) = selectionStart!;
    final (x2, y2) = selectionEnd!;

    final startY = math.min(y1, y2);
    final endY = math.max(y1, y2);

    if (startY < 0 || endY >= lines.length) return '';

    final sb = StringBuffer();
    for (var y = startY; y <= endY; y++) {
      final line = lines[y];
      final plain = Style.stripAnsi(line);

      int startX, endX;
      if (startY == endY) {
        startX = math.min(x1, x2);
        endX = math.max(x1, x2);
      } else if (y == startY) {
        startX = y1 < y2 ? x1 : x2;
        endX = Style.visibleLength(plain);
      } else if (y == endY) {
        startX = 0;
        endX = y1 < y2 ? x2 : x1;
      } else {
        startX = 0;
        endX = Style.visibleLength(plain);
      }

      final maxX = Style.visibleLength(plain);
      startX = startX.clamp(0, maxX);
      endX = endX.clamp(0, maxX);

      if (startX < endX) {
        sb.write(ranges.cutAnsiByCells(plain, startX, endX));
      }
      if (y < endY) {
        sb.write('\n');
      }
    }

    return sb.toString();
  }

  @override
  Cmd? init() => null;

  @override
  (ViewportModel, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(:final key):
        if (key.matchesSingle(keyMap.pageDown)) {
          return (pageDown(), null);
        }
        if (key.matchesSingle(keyMap.pageUp)) {
          return (pageUp(), null);
        }
        if (key.matchesSingle(keyMap.halfPageDown)) {
          return (halfPageDown(), null);
        }
        if (key.matchesSingle(keyMap.halfPageUp)) {
          return (halfPageUp(), null);
        }
        if (key.matchesSingle(keyMap.down)) {
          return (scrollDown(1), null);
        }
        if (key.matchesSingle(keyMap.up)) {
          return (scrollUp(1), null);
        }
        if (horizontalStep > 0) {
          if (!softWrap && key.matchesSingle(keyMap.left)) {
            return (scrollLeft(horizontalStep), null);
          }
          if (!softWrap && key.matchesSingle(keyMap.right)) {
            return (scrollRight(horizontalStep), null);
          }
        }
        if (key.matchesSingle(keyMap.copy)) {
          final text = getSelectedText();
          if (text.isNotEmpty) {
            return (this, Cmd.setClipboard(text));
          }
        }
        return (this, null);

      case MouseMsg(
        :final button,
        :final action,
        :final x,
        :final y,
        :final shift,
      ):
        if (button == MouseButton.left) {
          final isOutside =
              y < 0 || (height != null ? y >= height! : y >= lines.length);
          if (isOutside) {
            if (action == MouseAction.press) {
              return (clearSelection(), null);
            }
            return (this, null);
          }

          if (action == MouseAction.press) {
            final contentX = x - gutter + xOffset;
            final contentY = y + yOffset;
            final now = DateTime.now();

            // Check for double click
            if (lastClickTime != null &&
                now.difference(lastClickTime!) <
                    const Duration(milliseconds: 500) &&
                lastClickPos == (contentX, contentY)) {
              final (start, end) = _findWordAt(contentX, contentY);
              return (
                copyWith(
                  selectionStart: (start, contentY),
                  selectionEnd: (end, contentY),
                  lastClickTime: now,
                  lastClickPos: (contentX, contentY),
                ),
                null,
              );
            }

            // Start selection
            return (
              copyWith(
                selectionStart: (contentX, contentY),
                selectionEnd: (contentX, contentY),
                lastClickTime: now,
                lastClickPos: (contentX, contentY),
              ),
              null,
            );
          }

          if (action == MouseAction.motion && selectionStart != null) {
            // Update selection
            final contentX = x - gutter + xOffset;
            final contentY = y + yOffset;
            return (copyWith(selectionEnd: (contentX, contentY)), null);
          }

          if (action == MouseAction.release && button == MouseButton.left) {
            // Finalize selection (keep it for copying)
            return (this, null);
          }
        }

        if (!mouseWheelEnabled ||
            (action != MouseAction.press && action != MouseAction.wheel)) {
          return (this, null);
        }

        switch (button) {
          case MouseButton.wheelUp:
            if (!softWrap && shift && horizontalStep > 0) {
              return (scrollLeft(horizontalStep), null);
            }
            return (scrollUp(mouseWheelDelta), null);

          case MouseButton.wheelDown:
            if (!softWrap && shift && horizontalStep > 0) {
              return (scrollRight(horizontalStep), null);
            }
            return (scrollDown(mouseWheelDelta), null);

          case MouseButton.wheelLeft:
            if (!softWrap && horizontalStep > 0) {
              return (scrollLeft(horizontalStep), null);
            }
            return (this, null);

          case MouseButton.wheelRight:
            if (!softWrap && horizontalStep > 0) {
              return (scrollRight(horizontalStep), null);
            }
            return (this, null);

          default:
            return (this, null);
        }

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    final w = width;
    final h = height ?? _visibleLines().length;

    if (w == 0 || h == 0) {
      return '';
    }

    final contentWidth = w - style.getHorizontalFrameSize;
    final contentHeight = h - style.getVerticalFrameSize;

    final visible = _visibleLines();
    var contents = visible.join('\n');

    // Pad to width and height using Style
    contents = Style()
        .width(contentWidth)
        .height(contentHeight)
        .render(contents);

    var rendered = style.unsetWidth().unsetHeight().render(contents);
    // Defensive: ensure we don't leak any active SGR state to whatever gets
    // rendered after this component (e.g. when wrapping + height truncation
    // drops a trailing reset).
    if (rendered.contains(Ansi.escape)) {
      rendered = '$rendered${Ansi.reset}';
    }
    return rendered;
  }

  static int _findLongestLineWidth(List<String> lines) {
    var maxWidth = 0;
    for (final line in lines) {
      final w = Style.visibleLength(line);
      if (w > maxWidth) {
        maxWidth = w;
      }
    }
    return maxWidth;
  }
}

class HighlightInfo {
  /// in which line this highlight starts and ends
  final int lineStart;
  final int lineEnd;

  /// the grapheme highlight ranges for each of these lines
  final Map<int, (int, int)> lines;

  HighlightInfo({
    required this.lineStart,
    required this.lineEnd,
    required this.lines,
  });

  /// coords returns the line x column of this highlight.
  (int, int, int) coords() {
    for (var i = lineStart; i <= lineEnd; i++) {
      final hl = lines[i];
      if (hl == null) continue;
      return (i, hl.$1, hl.$2);
    }
    return (lineStart, 0, 0);
  }
}

List<HighlightInfo> _parseMatches(String content, List<List<int>> matches) {
  if (matches.isEmpty) return [];

  var line = 0;
  var graphemePos = 0;
  var previousLinesOffset = 0;
  var bytePos = 0;

  final highlights = <HighlightInfo>[];

  for (final match in matches) {
    final byteStart = match[0];
    final byteEnd = match[1];

    final hiLines = <int, (int, int)>{};

    // find the beginning of this byte range, setup current line and
    // grapheme position.
    while (byteStart > bytePos && bytePos < content.length) {
      if (content.codeUnitAt(bytePos) == 0x1b) {
        bytePos = Ansi.consumeEscapeSequence(content, bytePos);
        continue;
      }
      final (:grapheme, :nextIndex) = uni.readGraphemeAt(content, bytePos);
      if (grapheme == '\n') {
        previousLinesOffset = graphemePos + 1;
        line++;
      }
      graphemePos += math.max(1, Layout.visibleLength(grapheme));
      bytePos = nextIndex;
    }

    final lineStart = line;
    final graphemeStart = graphemePos;

    // loop until we find the end
    while (byteEnd > bytePos && bytePos < content.length) {
      if (content.codeUnitAt(bytePos) == 0x1b) {
        bytePos = Ansi.consumeEscapeSequence(content, bytePos);
        continue;
      }
      final (:grapheme, :nextIndex) = uni.readGraphemeAt(content, bytePos);

      // if it ends with a new line, add the range, increase line, and continue
      if (grapheme == '\n') {
        final colstart = math.max(0, graphemeStart - previousLinesOffset);
        final colend = math.max(
          graphemePos - previousLinesOffset + 1,
          colstart,
        );

        if (colend > colstart) {
          hiLines[line] = (colstart, colend);
        }

        previousLinesOffset = graphemePos + 1;
        line++;
      }

      graphemePos += math.max(1, Layout.visibleLength(grapheme));
      bytePos = nextIndex;
    }

    // we found it!, add highlight and continue
    if (bytePos == byteEnd || bytePos == content.length) {
      final colstart = math.max(0, graphemeStart - previousLinesOffset);
      final colend = math.max(graphemePos - previousLinesOffset, colstart);

      if (colend > colstart) {
        hiLines[line] = (colstart, colend);
      }
    }

    highlights.add(
      HighlightInfo(lineStart: lineStart, lineEnd: line, lines: hiLines),
    );
  }

  return highlights;
}

List<ranges.StyleRange> _makeHighlightRanges(
  List<HighlightInfo> highlights,
  int line,
  Style style,
) {
  final result = <ranges.StyleRange>[];
  for (final hi in highlights) {
    final lihi = hi.lines[line];
    if (lihi == null) continue;
    result.add(ranges.StyleRange(lihi.$1, lihi.$2, style));
  }
  return result;
}
