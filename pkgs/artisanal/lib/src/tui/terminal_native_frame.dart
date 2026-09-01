import 'view.dart';
import 'package:ultraviolet/core.dart' as uv_buffer;
import 'package:ultraviolet/core.dart';
import 'package:ultraviolet/core.dart' as uv_styled;

/// Native cell-buffer snapshot of rendered terminal output.
class TerminalNativeFrame {
  /// Creates a native frame snapshot.
  const TerminalNativeFrame({
    required this.width,
    required this.height,
    required this.lines,
  });

  /// Width of the backing cell buffer.
  final int width;

  /// Height of the backing cell buffer.
  final int height;

  /// Captured native lines.
  final List<TerminalNativeLine> lines;

  /// Captures a native frame from a UV [buffer].
  factory TerminalNativeFrame.fromBuffer(uv_buffer.Buffer buffer) {
    final lines = <TerminalNativeLine>[];
    for (var y = 0; y < buffer.height(); y++) {
      final line = buffer.line(y);
      lines.add(
        TerminalNativeLine(
          index: y,
          cells: List<TerminalNativeCell>.unmodifiable(
            line == null
                ? const <TerminalNativeCell>[]
                : line.cells.map(TerminalNativeCell.fromCell),
          ),
          dirtySpans: _dirtySpansFor(buffer, y),
        ),
      );
    }
    return TerminalNativeFrame(
      width: buffer.width(),
      height: buffer.height(),
      lines: List<TerminalNativeLine>.unmodifiable(lines),
    );
  }

  /// Captures a native frame from a UV [screen].
  factory TerminalNativeFrame.fromScreenBuffer(uv_buffer.ScreenBuffer screen) {
    return TerminalNativeFrame.fromBuffer(screen.buffer);
  }

  /// Renders [view] into a temporary UV screen buffer and captures its cells.
  static TerminalNativeFrame inspect(
    Object view, {
    required int width,
    required int height,
    bool wrap = true,
  }) {
    final content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };

    final screen = uv_buffer.ScreenBuffer(width, height);
    final styled = uv_styled.newStyledString(content)..wrap = wrap;
    styled.draw(screen, screen.bounds());
    return TerminalNativeFrame.fromScreenBuffer(screen);
  }

  /// ANSI-like textual reconstruction of the native frame.
  String get plainText => lines.map((line) => line.plainText).join('\n');

  /// Returns only lines that carried dirty spans in the backing buffer.
  List<TerminalNativeLine> get dirtyLines =>
      List<TerminalNativeLine>.unmodifiable(
        lines.where((line) => line.dirtySpans.isNotEmpty),
      );
}

/// Delta snapshot containing only dirty lines from a native frame.
class TerminalNativeDeltaFrame {
  /// Creates a native delta snapshot.
  const TerminalNativeDeltaFrame({
    required this.width,
    required this.height,
    required this.lines,
  });

  /// Width of the backing buffer.
  final int width;

  /// Height of the backing buffer.
  final int height;

  /// Dirty lines captured from the backing buffer.
  final List<TerminalNativeLine> lines;

  /// Captures only dirty lines from a UV [buffer].
  factory TerminalNativeDeltaFrame.fromBuffer(uv_buffer.Buffer buffer) {
    return TerminalNativeDeltaFrame.fromFrame(
      TerminalNativeFrame.fromBuffer(buffer),
    );
  }

  /// Captures only dirty lines from an existing native [frame].
  factory TerminalNativeDeltaFrame.fromFrame(TerminalNativeFrame frame) {
    return TerminalNativeDeltaFrame(
      width: frame.width,
      height: frame.height,
      lines: frame.dirtyLines,
    );
  }

  /// Whether this delta contains any changed lines.
  bool get isEmpty => lines.isEmpty;
}

/// Delta snapshot containing changed cells between two native frames.
class TerminalNativeCellDeltaFrame {
  /// Creates a cell-delta snapshot.
  const TerminalNativeCellDeltaFrame({
    required this.width,
    required this.height,
    required this.lines,
  });

  /// Width of the compared frames.
  final int width;

  /// Height of the compared frames.
  final int height;

  /// Lines containing changed cells.
  final List<TerminalNativeLineDelta> lines;

  /// Computes changed cells between [previous] and [current].
  factory TerminalNativeCellDeltaFrame.between(
    TerminalNativeFrame? previous,
    TerminalNativeFrame current,
  ) {
    final lines = <TerminalNativeLineDelta>[];
    final previousLines = previous?.lines ?? const <TerminalNativeLine>[];
    final maxLineCount = current.lines.length > previousLines.length
        ? current.lines.length
        : previousLines.length;

    for (var y = 0; y < maxLineCount; y++) {
      final currentLine = y < current.lines.length ? current.lines[y] : null;
      final previousLine = y < previousLines.length ? previousLines[y] : null;
      final currentCells = currentLine?.cells ?? const <TerminalNativeCell>[];
      final previousCells = previousLine?.cells ?? const <TerminalNativeCell>[];
      final maxCellCount = currentCells.length > previousCells.length
          ? currentCells.length
          : previousCells.length;
      final deltas = <TerminalNativeCellDelta>[];

      for (var x = 0; x < maxCellCount; x++) {
        final prev = x < previousCells.length ? previousCells[x] : null;
        final next = x < currentCells.length ? currentCells[x] : null;
        if (_nativeCellEquals(prev, next)) continue;
        deltas.add(
          TerminalNativeCellDelta(column: x, previous: prev, current: next),
        );
      }

      if (deltas.isNotEmpty) {
        lines.add(
          TerminalNativeLineDelta(
            index: y,
            cells: List<TerminalNativeCellDelta>.unmodifiable(deltas),
          ),
        );
      }
    }

    return TerminalNativeCellDeltaFrame(
      width: current.width,
      height: current.height,
      lines: List<TerminalNativeLineDelta>.unmodifiable(lines),
    );
  }

  /// Whether this delta contains any changed cells.
  bool get isEmpty => lines.isEmpty;

  /// Returns grouped current-value spans derived from changed cells.
  List<TerminalNativeSpanDelta> get spanDeltas =>
      List<TerminalNativeSpanDelta>.unmodifiable(
        lines
            .map(
              (line) => TerminalNativeSpanDelta(
                index: line.index,
                spans: _groupDeltaSpans(line),
              ),
            )
            .where((line) => line.spans.isNotEmpty),
      );
}

/// One changed line in a cell-delta snapshot.
class TerminalNativeLineDelta {
  /// Creates a line-delta snapshot.
  const TerminalNativeLineDelta({required this.index, required this.cells});

  /// Zero-based line index.
  final int index;

  /// Changed cells on this line.
  final List<TerminalNativeCellDelta> cells;
}

/// One changed cell between two native frames.
class TerminalNativeCellDelta {
  /// Creates a cell-delta record.
  const TerminalNativeCellDelta({
    required this.column,
    this.previous,
    this.current,
  });

  /// Zero-based column index.
  final int column;

  /// Previously committed cell snapshot, if any.
  final TerminalNativeCell? previous;

  /// Current cell snapshot, if any.
  final TerminalNativeCell? current;
}

/// One captured line from a native frame.
class TerminalNativeLine {
  /// Creates a native line snapshot.
  const TerminalNativeLine({
    required this.index,
    required this.cells,
    this.dirtySpans = const <TerminalDirtySpan>[],
  });

  /// Zero-based row index.
  final int index;

  /// Captured cells for this line.
  final List<TerminalNativeCell> cells;

  /// Dirty spans reported by the backing UV buffer.
  final List<TerminalDirtySpan> dirtySpans;

  /// Plain-text content of the line.
  String get plainText {
    final buffer = StringBuffer();
    for (final cell in cells) {
      if (cell.isZero) continue;
      if (cell.isEmpty) {
        buffer.write(' ');
        continue;
      }
      buffer.write(cell.content);
    }
    return buffer.toString();
  }

  /// Styled spans grouped from adjacent cells with matching metadata.
  List<TerminalNativeSpan> get spans => _groupLineSpans(index, cells);
}

/// One captured native cell.
class TerminalNativeCell {
  /// Creates a native cell snapshot.
  const TerminalNativeCell({
    required this.content,
    required this.width,
    required this.style,
    required this.link,
    required this.isZero,
    required this.isEmpty,
    required this.hasDrawable,
    required this.packed,
  });

  /// Grapheme content stored in the cell.
  final String content;

  /// Display width in terminal cells.
  final int width;

  /// Style snapshot for this cell.
  final TerminalNativeStyle style;

  /// Hyperlink snapshot for this cell.
  final TerminalNativeLink link;

  /// Whether this cell is a zero-width placeholder.
  final bool isZero;

  /// Whether this cell is a plain empty space.
  final bool isEmpty;

  /// Whether this cell carries a drawable payload.
  final bool hasDrawable;

  /// Stable packed UV cell tuple for low-level inspection.
  final List<int> packed;

  /// Builds a snapshot from a UV [cell].
  factory TerminalNativeCell.fromCell(Cell cell) {
    return TerminalNativeCell(
      content: cell.content,
      width: cell.width,
      style: TerminalNativeStyle.fromStyle(cell.style),
      link: TerminalNativeLink.fromLink(cell.link),
      isZero: cell.isZero,
      isEmpty: cell.isEmpty,
      hasDrawable: cell.drawable != null,
      packed: List<int>.unmodifiable(cell.packed.words),
    );
  }
}

/// One grouped semantic span from a native line.
class TerminalNativeSpan {
  /// Creates a native span.
  const TerminalNativeSpan({
    required this.lineIndex,
    required this.startColumn,
    required this.endColumn,
    required this.text,
    required this.style,
    required this.link,
    required this.hasDrawable,
  });

  /// Zero-based line index.
  final int lineIndex;

  /// Inclusive start column.
  final int startColumn;

  /// Exclusive end column.
  final int endColumn;

  /// Text content represented by this span.
  final String text;

  /// Shared style metadata for the span.
  final TerminalNativeStyle style;

  /// Shared hyperlink metadata for the span.
  final TerminalNativeLink link;

  /// Whether any cell in the span had a drawable.
  final bool hasDrawable;
}

/// Grouped span deltas for one line.
class TerminalNativeSpanDelta {
  /// Creates a span-delta line record.
  const TerminalNativeSpanDelta({required this.index, required this.spans});

  /// Zero-based line index.
  final int index;

  /// Current-value spans reconstructed from changed cells.
  final List<TerminalNativeSpan> spans;
}

bool _nativeCellEquals(TerminalNativeCell? a, TerminalNativeCell? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.content != b.content ||
      a.width != b.width ||
      a.isZero != b.isZero ||
      a.isEmpty != b.isEmpty ||
      a.hasDrawable != b.hasDrawable) {
    return false;
  }
  if (!_listIntEquals(a.packed, b.packed)) return false;
  if (a.link.url != b.link.url || a.link.params != b.link.params) return false;
  final as = a.style;
  final bs = b.style;
  if (as.attrs != bs.attrs ||
      as.underline != bs.underline ||
      as.packedKey != bs.packedKey) {
    return false;
  }
  return _nativeColorEquals(as.fg, bs.fg) &&
      _nativeColorEquals(as.bg, bs.bg) &&
      _nativeColorEquals(as.underlineColor, bs.underlineColor);
}

List<TerminalNativeSpan> _groupLineSpans(
  int lineIndex,
  List<TerminalNativeCell> cells,
) {
  final spans = <TerminalNativeSpan>[];
  TerminalNativeStyle? activeStyle;
  TerminalNativeLink? activeLink;
  StringBuffer? text;
  int? startColumn;
  int? endColumn;
  var hasDrawable = false;

  void flush() {
    if (activeStyle == null ||
        activeLink == null ||
        text == null ||
        startColumn == null ||
        endColumn == null) {
      return;
    }
    spans.add(
      TerminalNativeSpan(
        lineIndex: lineIndex,
        startColumn: startColumn!,
        endColumn: endColumn!,
        text: text.toString(),
        style: activeStyle!,
        link: activeLink!,
        hasDrawable: hasDrawable,
      ),
    );
    activeStyle = null;
    activeLink = null;
    text = null;
    startColumn = null;
    endColumn = null;
    hasDrawable = false;
  }

  for (var x = 0; x < cells.length; x++) {
    final cell = cells[x];
    if (cell.isZero) continue;
    final content = cell.isEmpty ? ' ' : cell.content;
    final matchesActive =
        activeStyle != null &&
        activeLink != null &&
        _nativeStyleEquals(activeStyle!, cell.style) &&
        _nativeLinkEquals(activeLink!, cell.link) &&
        hasDrawable == cell.hasDrawable &&
        endColumn == x;

    if (!matchesActive) {
      flush();
      activeStyle = cell.style;
      activeLink = cell.link;
      text = StringBuffer();
      startColumn = x;
      endColumn = x;
      hasDrawable = cell.hasDrawable;
    }

    text!.write(content);
    endColumn = x + 1;
  }

  flush();
  return List<TerminalNativeSpan>.unmodifiable(spans);
}

List<TerminalNativeSpan> _groupDeltaSpans(TerminalNativeLineDelta line) {
  final spans = <TerminalNativeSpan>[];
  TerminalNativeStyle? activeStyle;
  TerminalNativeLink? activeLink;
  StringBuffer? text;
  int? startColumn;
  int? endColumn;
  var hasDrawable = false;

  void flush() {
    if (activeStyle == null ||
        activeLink == null ||
        text == null ||
        startColumn == null ||
        endColumn == null) {
      return;
    }
    spans.add(
      TerminalNativeSpan(
        lineIndex: line.index,
        startColumn: startColumn!,
        endColumn: endColumn!,
        text: text.toString(),
        style: activeStyle!,
        link: activeLink!,
        hasDrawable: hasDrawable,
      ),
    );
    activeStyle = null;
    activeLink = null;
    text = null;
    startColumn = null;
    endColumn = null;
    hasDrawable = false;
  }

  for (final delta in line.cells) {
    final cell = delta.current;
    if (cell == null || cell.isZero) continue;
    final content = cell.isEmpty ? ' ' : cell.content;
    final matchesActive =
        activeStyle != null &&
        activeLink != null &&
        _nativeStyleEquals(activeStyle!, cell.style) &&
        _nativeLinkEquals(activeLink!, cell.link) &&
        hasDrawable == cell.hasDrawable &&
        endColumn == delta.column;

    if (!matchesActive) {
      flush();
      activeStyle = cell.style;
      activeLink = cell.link;
      text = StringBuffer();
      startColumn = delta.column;
      endColumn = delta.column;
      hasDrawable = cell.hasDrawable;
    }

    text!.write(content);
    endColumn = delta.column + 1;
  }

  flush();
  return List<TerminalNativeSpan>.unmodifiable(spans);
}

bool _nativeStyleEquals(TerminalNativeStyle a, TerminalNativeStyle b) {
  return a.attrs == b.attrs &&
      a.underline == b.underline &&
      a.packedKey == b.packedKey &&
      _nativeColorEquals(a.fg, b.fg) &&
      _nativeColorEquals(a.bg, b.bg) &&
      _nativeColorEquals(a.underlineColor, b.underlineColor);
}

bool _nativeLinkEquals(TerminalNativeLink a, TerminalNativeLink b) {
  return a.url == b.url && a.params == b.params;
}

bool _nativeColorEquals(TerminalNativeColor? a, TerminalNativeColor? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return a.kind == b.kind &&
      a.index == b.index &&
      a.bright == b.bright &&
      a.r == b.r &&
      a.g == b.g &&
      a.b == b.b &&
      a.a == b.a;
}

bool _listIntEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Snapshot of UV link metadata.
class TerminalNativeLink {
  /// Creates a native link snapshot.
  const TerminalNativeLink({required this.url, required this.params});

  /// Link target URL.
  final String url;

  /// Link parameter string.
  final String params;

  /// Whether this link is empty.
  bool get isZero => url.isEmpty && params.isEmpty;

  /// Builds a snapshot from a UV [link].
  factory TerminalNativeLink.fromLink(Link link) {
    return TerminalNativeLink(url: link.url, params: link.params);
  }
}

/// Snapshot of UV cell style metadata.
class TerminalNativeStyle {
  /// Creates a native style snapshot.
  const TerminalNativeStyle({
    required this.fg,
    required this.bg,
    required this.underlineColor,
    required this.underline,
    required this.attrs,
    required this.packedKey,
  });

  /// Foreground color, when present.
  final TerminalNativeColor? fg;

  /// Background color, when present.
  final TerminalNativeColor? bg;

  /// Underline color, when present.
  final TerminalNativeColor? underlineColor;

  /// Underline mode.
  final UnderlineStyle underline;

  /// UV attribute bitmask.
  final int attrs;

  /// Stable packed style key.
  final int packedKey;

  /// Whether this style has no metadata.
  bool get isZero =>
      fg == null &&
      bg == null &&
      underlineColor == null &&
      underline == UnderlineStyle.none &&
      attrs == 0;

  /// Builds a snapshot from a UV [style].
  factory TerminalNativeStyle.fromStyle(UvStyle style) {
    return TerminalNativeStyle(
      fg: TerminalNativeColor.fromUv(style.fg),
      bg: TerminalNativeColor.fromUv(style.bg),
      underlineColor: TerminalNativeColor.fromUv(style.underlineColor),
      underline: style.underline,
      attrs: style.attrs,
      packedKey: style.packedKey,
    );
  }
}

/// Snapshot of a UV color.
class TerminalNativeColor {
  /// Creates a native color snapshot.
  const TerminalNativeColor._({
    required this.kind,
    this.index,
    this.bright,
    this.r,
    this.g,
    this.b,
    this.a,
  });

  /// Color representation kind: `basic16`, `indexed256`, or `rgb`.
  final String kind;

  /// Palette index when present.
  final int? index;

  /// Bright flag for basic ANSI colors.
  final bool? bright;

  /// Red channel for RGB colors.
  final int? r;

  /// Green channel for RGB colors.
  final int? g;

  /// Blue channel for RGB colors.
  final int? b;

  /// Alpha channel for RGB colors.
  final int? a;

  /// Converts a UV color to a native snapshot.
  static TerminalNativeColor? fromUv(UvColor? color) {
    return switch (color) {
      null => null,
      UvBasic16(:final index, :final bright) => _basic16Color(index, bright),
      UvIndexed256(:final index) => _indexed256Color(index),
      UvRgb(:final r, :final g, :final b, :final a) => _rgbColor(r, g, b, a),
    };
  }
}

final List<TerminalNativeColor?> _terminalBasic16ColorCache =
    List<TerminalNativeColor?>.filled(16, null);
final List<TerminalNativeColor?> _terminalIndexed256ColorCache =
    List<TerminalNativeColor?>.filled(256, null);
final Map<int, TerminalNativeColor> _terminalRgbColorCache =
    <int, TerminalNativeColor>{};

TerminalNativeColor _basic16Color(int index, bool bright) {
  final slot = index + (bright ? 8 : 0);
  if (slot >= 0 && slot < _terminalBasic16ColorCache.length) {
    return _terminalBasic16ColorCache[slot] ??= TerminalNativeColor._(
      kind: 'basic16',
      index: index,
      bright: bright,
    );
  }
  return TerminalNativeColor._(kind: 'basic16', index: index, bright: bright);
}

TerminalNativeColor _indexed256Color(int index) {
  if (index >= 0 && index < _terminalIndexed256ColorCache.length) {
    return _terminalIndexed256ColorCache[index] ??= TerminalNativeColor._(
      kind: 'indexed256',
      index: index,
    );
  }
  return TerminalNativeColor._(kind: 'indexed256', index: index);
}

TerminalNativeColor _rgbColor(int r, int g, int b, int a) {
  final key = r | (g << 8) | (b << 16) | (a << 24);
  final cached = _terminalRgbColorCache[key];
  if (cached != null) return cached;
  if (_terminalRgbColorCache.length >= 1024) {
    _terminalRgbColorCache.clear();
  }
  return _terminalRgbColorCache[key] = TerminalNativeColor._(
    kind: 'rgb',
    r: r,
    g: g,
    b: b,
    a: a,
  );
}

/// Dirty cell range captured from the UV buffer.
class TerminalDirtySpan {
  /// Creates a dirty span snapshot.
  const TerminalDirtySpan({required this.start, required this.end});

  /// Inclusive start cell index.
  final int start;

  /// Exclusive end cell index.
  final int end;
}

List<TerminalDirtySpan> _dirtySpansFor(uv_buffer.Buffer buffer, int y) {
  if (y < 0 || y >= buffer.touched.length) return const <TerminalDirtySpan>[];
  final lineData = buffer.touched[y];
  if (lineData == null || !lineData.isDirty) return const <TerminalDirtySpan>[];
  if (lineData.spans.isNotEmpty) {
    return List<TerminalDirtySpan>.unmodifiable(
      lineData.spans.map(
        (span) => TerminalDirtySpan(start: span.start, end: span.end),
      ),
    );
  }
  return List<TerminalDirtySpan>.unmodifiable(<TerminalDirtySpan>[
    TerminalDirtySpan(start: lineData.firstCell, end: lineData.lastCell),
  ]);
}
