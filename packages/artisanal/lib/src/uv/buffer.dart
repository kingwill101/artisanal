/// Buffer, Line, and LineData for UV terminal screen state.
///
/// This module provides a 2D grid of [Cell]s organized as [Line]s and
/// tracked via [LineData] to enable diffed, incremental rendering.
/// It is optimized for partial updates and minimal terminal output.
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Integration points:
/// - Feed [Buffer] frames to [UvTerminalRenderer.render] for efficient diffs.
/// - Use [Screen] and [Canvas] to compose and present buffer contents.
/// - Combine with [StyledString] to generate cells from ANSI/OSC text.
///
/// Example:
/// ```dart
/// final buf = Buffer.create(80, 24);
/// buf.line(0)?.set(0, Cell(content: 'H'));
/// buf.touch(0, 0);
/// final renderer = UvTerminalRenderer(StringBuffer());
/// renderer.render(buf);
/// renderer.flush();
/// ```
library;
import 'ansi.dart';
import 'cell.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import 'style_ops.dart' as style_ops;
import '../terminal/ansi.dart' as term_ansi;
import '../unicode/width.dart';

/// Metadata for a touched line.
///
/// Upstream: `third_party/ultraviolet/terminal_renderer.go` (`LineData`).
final class LineData {
  const LineData({required this.firstCell, required this.lastCell});

  final int firstCell;
  final int lastCell;
}

/// A line is a fixed-width list of cells.
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Line`, `Line.Set`).
/// A single row of fixed-width [Cell]s.
final class Line {
  Line._(this._cells);

  /// Creates a line of [width] cells, initialized to spaces.
  factory Line.filled(int width) {
    final cells = List<Cell>.generate(width, (_) => Cell.emptyCell());
    return Line._(cells);
  }

  /// Creates a line from pre-built cells without applying `set()` semantics.
  ///
  /// This is primarily useful for porting upstream tests that include explicit
  /// wide-cell placeholder cells.
  /// Creates a line from [cells] without applying wide-cell semantics.
  factory Line.fromCells(List<Cell> cells) {
    return Line._(cells.map((c) => c.clone()).toList(growable: false));
  }

  final List<Cell> _cells;

  /// The number of cells in this line.
  int get length => _cells.length;

  /// Returns the cell at [x], or null if out of bounds.
  Cell? at(int x) => (x < 0 || x >= _cells.length) ? null : _cells[x];

  /// Sets the cell at [x], applying wide-cell overwrite rules.
  void set(int x, Cell? cell) {
    // Upstream: maxCellWidth = 5.
    const maxCellWidth = 5;

    final lineWidth = _cells.length;
    if (x < 0 || x >= lineWidth) return;

    // Wide-cell overwrite clearing (port of `buffer.go:Line.Set`).
    final prev = at(x);
    if (prev != null) {
      final pw = prev.width;
      if (pw > 1) {
        for (var j = 0; j < pw && x + j < lineWidth; j++) {
          final c = prev.clone()..empty();
          _cells[x + j] = c;
        }
      } else if (pw == 0) {
        // Placeholder overwrite: scan left for the wide cell origin.
        for (var j = 1; j < maxCellWidth && x - j >= 0; j++) {
          final wide = at(x - j);
          if (wide == null) continue;
          final ww = wide.width;
          if (ww > 1 && j < ww) {
            for (var k = 0; k < ww && x - j + k < lineWidth; k++) {
              final c = wide.clone()..empty();
              _cells[x - j + k] = c;
            }
            break;
          }
        }
      }
    }

    if (cell == null) {
      _cells[x] = Cell.emptyCell();
      return;
    }

    _cells[x] = cell.clone();
    final cw = cell.width;

    if (x + cw > lineWidth) {
      for (var i = 0; i < cw && x + i < lineWidth; i++) {
        final c = cell.clone()..empty();
        _cells[x + i] = c;
      }
      return;
    }

    if (cw > 1) {
      // Mark placeholder cells with zero-width zero cells.
      for (var j = 1; j < cw && x + j < lineWidth; j++) {
        _cells[x + j] = Cell();
      }
    }
  }

  List<Cell> get cells => _cells;

  /// String representation without trailing spaces.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Line.String`).
  @override
  String toString() {
    final out = StringBuffer();
    final pending = StringBuffer();

    for (final c in _cells) {
      if (c.isZero) continue;
      if (c.isEmpty) {
        pending.write(' ');
        continue;
      }
      if (pending.isNotEmpty) {
        out.write(pending.toString());
        pending.clear();
      }
      out.write(c.content);
    }

    return out.toString();
  }

  /// Renders the line to a styled string (including SGR and OSC 8 sequences),
  /// trimming trailing spaces.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Line.Render`, `renderLine`).
  String render() {
    final out = StringBuffer();
    _renderLine(out, this);
    return out.toString();
  }
}

/// A 2D buffer of [Line]s representing a terminal screen or a portion of it.
///
/// The buffer maintains a grid of [Cell]s and tracks which lines have been
/// "touched" (modified) to allow for efficient incremental rendering.
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Buffer`).
final class Buffer {
  Buffer._(this.lines) : touched = List<LineData?>.filled(lines.length, null);

  factory Buffer.create(int width, int height) {
    final lines = List<Line>.generate(height, (_) => Line.filled(width));
    final b = Buffer._(lines);
    b.resize(width, height);
    return b;
  }

  /// Creates a buffer from pre-built cells without applying `Line.set()`.
  ///
  /// Upstream tests construct expected buffers directly (without triggering
  /// overwrite logic), so this helper lets Dart parity tests do the same.
  factory Buffer.fromCells(List<List<Cell>> cellLines) {
    final lines = cellLines.map(Line.fromCells).toList(growable: false);
    return Buffer._(lines);
  }

  final List<Line> lines;

  List<LineData?> touched;

  /// The buffer width in cells.
  int width() => lines.isEmpty ? 0 : lines[0].length;

  /// The buffer height in cells.
  int height() => lines.length;

  /// Returns the full buffer bounds as a [Rectangle].
  Rectangle bounds() => rect(0, 0, width(), height());

  /// Returns the line at [y], or null if out of bounds.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Buffer.Line`).
  /// Returns the line at [y], or null if out of bounds.
  Line? line(int y) => (y < 0 || y >= lines.length) ? null : lines[y];

  /// Returns the cell at ([x], [y]), or null if out of bounds.
  Cell? cellAt(int x, int y) =>
      (y < 0 || y >= lines.length) ? null : lines[y].at(x);

  /// Marks a single cell as dirty.
  ///
  /// Upstream: `third_party/ultraviolet/buffer_test.go` (`Touch`).
  /// Marks the cell at ([x], [y]) as dirty.
  void touch(int x, int y) => touchLine(x, y, 1);

  /// Sets the cell at ([x], [y]) and updates dirty tracking.
  void setCell(int x, int y, Cell? cell) {
    if (y < 0 || y >= lines.length) return;
    final current = cellAt(x, y);
    final next = cell ?? Cell.emptyCell();
    if (current == null || current != next) {
      final w = next.width > 0 ? next.width : 1;
      touchLine(x, y, w);
    }
    lines[y].set(x, cell);
  }

  /// Resizes the buffer to [width] × [height], preserving content where possible.
  void resize(int width, int height) {
    if (width < 0 || height <= 0) {
      lines.clear();
      touched = <LineData?>[];
      return;
    }

    final oldHeight = lines.length;
    final oldWidth = oldHeight == 0 ? 0 : lines[0].length;

    // Resize height.
    if (height > oldHeight) {
      for (var i = oldHeight; i < height; i++) {
        lines.add(Line.filled(width));
      }
    } else if (height < oldHeight) {
      lines.removeRange(height, oldHeight);
    }

    // Resize width (rebuild lines to keep wide-placeholder invariants simple).
    if (width != oldWidth && lines.isNotEmpty) {
      for (var y = 0; y < lines.length; y++) {
        final newLine = Line.filled(width);
        final copyWidth = width < oldWidth ? width : oldWidth;
        for (var x = 0; x < copyWidth; x++) {
          newLine.cells[x] = lines[y].cells[x].clone();
        }
        lines[y] = newLine;
      }
    }

    touched = List<LineData?>.filled(lines.length, null);
  }

  /// Fills the buffer with [cell] over its full bounds.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Fill`).
  void fill(Cell? cell) => fillArea(cell, bounds());

  /// Fills the buffer with [cell] within [area].
  ///
  /// Note: we step by cell width to avoid repeatedly overwriting wide-cell
  /// placeholders.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`FillArea`).
  void fillArea(Cell? cell, Rectangle area) {
    var cellWidth = 1;
    if (cell != null && cell.width > 1) cellWidth = cell.width;
    for (var y = area.minY; y < area.maxY; y++) {
      for (var x = area.minX; x < area.maxX; x += cellWidth) {
        setCell(x, y, cell);
      }
    }
  }

  /// Clears the buffer over its full bounds.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Clear`).
  void clear() => clearArea(bounds());

  /// Clears the buffer within [area] (fills with spaces).
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`ClearArea`).
  void clearArea(Rectangle area) => fillArea(null, area);

  /// Clones [area] into a new buffer, or returns null if out-of-bounds.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`CloneArea`).
  Buffer? cloneArea(Rectangle area) {
    final b = bounds();
    if (!b.containsRect(area)) return null;

    final n = Buffer.create(area.width, area.height);
    for (var y = area.minY; y < area.maxY; y++) {
      for (var x = area.minX; x < area.maxX; x++) {
        final c = cellAt(x, y);
        if (c == null || c.isZero) continue;
        n.setCell(x - area.minX, y - area.minY, c);
      }
    }
    return n;
  }

  /// Clones the entire buffer into a new buffer.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Clone`).
  Buffer clone() {
    final b = cloneArea(bounds());
    return b ?? Buffer.create(0, 0);
  }

  /// Inserts [n] lines at [y] within full bounds.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`InsertLine`).
  void insertLine(int y, int n, Cell? cell) =>
      insertLineArea(y, n, cell, bounds());

  /// Inserts [n] lines at [y] within [area] (ansi IL semantics).
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`InsertLineArea`).
  void insertLineArea(int y, int n, Cell? cell, Rectangle area) {
    if (n <= 0 || y < area.minY || y >= area.maxY || y >= height()) return;
    if (y + n > area.maxY) n = area.maxY - y;

    for (var i = area.maxY - 1; i >= y + n; i--) {
      for (var x = area.minX; x < area.maxX; x++) {
        lines[i].cells[x] = lines[i - n].cells[x].clone();
      }
      touchLine(area.minX, i, area.maxX - area.minX);
      touchLine(area.minX, i - n, area.maxX - area.minX);
    }

    for (var i = y; i < y + n; i++) {
      for (var x = area.minX; x < area.maxX; x++) {
        setCell(x, i, cell);
      }
    }
  }

  /// Deletes [n] lines at [y] within full bounds.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`DeleteLine`).
  void deleteLine(int y, int n, Cell? cell) =>
      deleteLineArea(y, n, cell, bounds());

  /// Deletes [n] lines at [y] within [area] (ansi DL semantics).
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`DeleteLineArea`).
  void deleteLineArea(int y, int n, Cell? cell, Rectangle area) {
    if (n <= 0 || y < area.minY || y >= area.maxY || y >= height()) return;
    if (n > area.maxY - y) n = area.maxY - y;

    for (var dst = y; dst < area.maxY - n; dst++) {
      final src = dst + n;
      for (var x = area.minX; x < area.maxX; x++) {
        lines[dst].cells[x] = lines[src].cells[x].clone();
      }
      touchLine(area.minX, dst, area.maxX - area.minX);
      touchLine(area.minX, src, area.maxX - area.minX);
    }

    for (var i = area.maxY - n; i < area.maxY; i++) {
      for (var x = area.minX; x < area.maxX; x++) {
        setCell(x, i, cell);
      }
    }
  }

  /// Inserts [n] cells at (x,y) within full bounds (ansi ICH semantics).
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`InsertCell`).
  void insertCell(int x, int y, int n, Cell? cell) =>
      insertCellArea(x, y, n, cell, bounds());

  /// Inserts [n] cells at (x,y) within [area] (ansi ICH semantics).
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`InsertCellArea`).
  void insertCellArea(int x, int y, int n, Cell? cell, Rectangle area) {
    if (n <= 0 ||
        y < area.minY ||
        y >= area.maxY ||
        y >= height() ||
        x < area.minX ||
        x >= area.maxX ||
        x >= width()) {
      return;
    }

    if (x + n > area.maxX) n = area.maxX - x;

    for (var i = area.maxX - 1; i >= x + n && i - n >= area.minX; i--) {
      lines[y].cells[i] = lines[y].cells[i - n].clone();
    }
    touchLine(x, y, n);

    for (var i = x; i < x + n && i < area.maxX; i++) {
      setCell(i, y, cell);
    }
  }

  /// Deletes [n] cells at (x,y) within full bounds (ansi DCH semantics).
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`DeleteCell`).
  void deleteCell(int x, int y, int n, Cell? cell) =>
      deleteCellArea(x, y, n, cell, bounds());

  /// Deletes [n] cells at (x,y) within [area] (ansi DCH semantics).
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`DeleteCellArea`).
  void deleteCellArea(int x, int y, int n, Cell? cell, Rectangle area) {
    if (n <= 0 ||
        y < area.minY ||
        y >= area.maxY ||
        y >= height() ||
        x < area.minX ||
        x >= area.maxX ||
        x >= width()) {
      return;
    }

    final remainingCells = area.maxX - x;
    if (n > remainingCells) n = remainingCells;

    for (var i = x; i < area.maxX - n; i++) {
      if (i + n < area.maxX) {
        setCell(i, y, cellAt(i + n, y));
      }
    }
    touchLine(x, y, n);

    for (var i = area.maxX - n; i < area.maxX; i++) {
      setCell(i, y, cell);
    }
  }

  /// Renders buffer content to a string.
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Render`).
  String render() {
    final out = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      _renderLine(out, lines[i]);
      if (i < lines.length - 1) out.write('\n');
    }
    return out.toString();
  }

  void touchLine(int x, int y, int width) {
    if (y < 0 || y >= lines.length) return;

    if (y >= touched.length) {
      touched = [
        ...touched,
        ...List<LineData?>.filled(y - touched.length + 1, null),
      ];
    }

    final ch = touched[y];
    final first = x;
    final last = x + width;
    if (ch == null) {
      touched[y] = LineData(firstCell: first, lastCell: last);
    } else {
      final prevFirst = ch.firstCell == -1 ? first : ch.firstCell;
      final prevLast = ch.lastCell == -1 ? last : ch.lastCell;
      touched[y] = LineData(
        firstCell: first < prevFirst ? first : prevFirst,
        lastCell: last > prevLast ? last : prevLast,
      );
    }
  }

  /// Draws this buffer onto [screen] at the specified [area].
  ///
  /// Upstream: `third_party/ultraviolet/buffer.go` (`Buffer.Draw`).
  void draw(Screen screen, Rectangle area) {
    if (area.isEmpty) return;
    final bounds = screen.bounds();
    if (area.minX < bounds.minX ||
        area.minY < bounds.minY ||
        area.maxX > bounds.maxX ||
        area.maxY > bounds.maxY) {
      return;
    }

    for (var y = area.minY; y < area.maxY; y++) {
      var x = area.minX;
      while (x < area.maxX) {
        final c = cellAt(x - area.minX, y - area.minY);
        if (c == null || c.isZero) {
          x++;
          continue;
        }
        screen.setCell(x, y, c);
        x += c.width > 0 ? c.width : 1;
      }
    }
  }

  @override
  String toString() {
    final out = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      out.write(lines[i].toString());
      if (i < lines.length - 1) out.write('\n');
    }
    return out.toString();
  }
}

void _renderLine(StringSink out, Line line) {
  // Upstream: `third_party/ultraviolet/buffer.go` (`renderLine`).
  var pen = const UvStyle();
  var link = const Link();
  final pending = StringBuffer();

  for (final c in line.cells) {
    if (c.isZero) continue;

    if (c.isEmpty) {
      if (!pen.isZero) {
        out.write(UvAnsi.resetStyle);
        pen = const UvStyle();
      }
      if (!link.isZero) {
        out.write(UvAnsi.resetHyperlink());
        link = const Link();
      }
      pending.write(' ');
      continue;
    }

    if (pending.isNotEmpty) {
      out.write(pending.toString());
      pending.clear();
    }

    if (c.style.isZero && !pen.isZero) {
      out.write(UvAnsi.resetStyle);
      pen = const UvStyle();
    }
    if (c.style != pen) {
      out.write(style_ops.styleDiff(pen, c.style));
      pen = c.style;
    }

    if (c.link != link && link.url.isNotEmpty) {
      out.write(UvAnsi.resetHyperlink());
      link = const Link();
    }
    if (c.link != link) {
      out.write(UvAnsi.setHyperlink(c.link.url, c.link.params));
      link = c.link;
    }

    out.write(c.content);
  }

  if (link.url.isNotEmpty) {
    out.write(UvAnsi.resetHyperlink());
  }
  if (!pen.isZero) {
    out.write(UvAnsi.resetStyle);
  }
}

/// A screen buffer that implements `Screen` operations and carries a width
/// method for calculating cell widths.
///
/// Upstream: `third_party/ultraviolet/screen` + `NewScreenBuffer`.
final class ScreenBuffer
    implements
        Screen,
        Drawable,
        ClearableScreen,
        ClearAreaScreen,
        FillableScreen,
        FillAreaScreen,
        CloneableScreen,
        CloneAreaScreen {
  ScreenBuffer(int width, int height)
    : method = WidthMethod.wcwidth,
      buffer = Buffer.create(width, height);

  WidthMethod method;
  final Buffer buffer;

  int width() => buffer.width();
  int height() => buffer.height();

  @override
  Rectangle bounds() => buffer.bounds();

  @override
  Cell? cellAt(int x, int y) => buffer.cellAt(x, y);

  @override
  void setCell(int x, int y, Cell? cell) => buffer.setCell(x, y, cell);

  void resize(int width, int height) => buffer.resize(width, height);

  @override
  void clear() => buffer.fill(Cell.emptyCell());

  @override
  void clearArea(Rectangle area) => buffer.clearArea(area);

  @override
  void fill(Cell? cell) => buffer.fill(cell);

  @override
  void fillArea(Cell? cell, Rectangle area) => buffer.fillArea(cell, area);

  @override
  Buffer clone() => buffer.clone();

  @override
  Buffer? cloneArea(Rectangle area) => buffer.cloneArea(area);

  @override
  WidthMethod widthMethod() => method;

  @override
  void draw(Screen screen, Rectangle area) => buffer.draw(screen, area);
}

/// Parses a string and returns its bounds (width/height) using a width method.
///
/// Upstream: `third_party/ultraviolet/styled.go` (`StyledString.widthHeight`).
Rectangle styledStringBounds(String text, WidthMethod method) {
  final normalized = text.replaceAll('\r\n', '\n');
  final expanded = term_ansi.Ansi.expandTabs(normalized);
  final lines = expanded.split('\n');
  var maxWidth = 0;
  for (final line in lines) {
    final width = _visibleStringWidth(line, method);
    if (width > maxWidth) maxWidth = width;
  }
  return rect(0, 0, maxWidth, lines.length);
}

int _visibleStringWidth(String line, WidthMethod method) {
  // Remove CSI and OSC sequences (minimal; enough for our UV parity cases).
  final stripped = line.replaceAll(
    RegExp(
      r'\x1b'
      r'(?:'
      r'\[[0-9;:]*[ -/]*[@-~]'
      r'|'
      r'\][^\x07]*\x07'
      r'|'
      r'\][^\x1b]*\x1b\\'
      r')',
    ),
    '',
  );
  final expanded = term_ansi.Ansi.expandTabs(stripped);
  return method.stringWidth(expanded);
}
