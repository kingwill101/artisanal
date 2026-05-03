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

import 'dart:typed_data';

import 'ansi.dart';
import 'cell.dart';
import 'color_utils.dart' as color_utils;
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import 'style_ops.dart' as style_ops;
import 'terminal_graphics.dart' as terminal_graphics;
import '../ansi.dart' as term_ansi;
import '../unicode/width.dart';

/// Metadata for a touched line.
///
/// Upstream: `third_party/ultraviolet/terminal_renderer.go` (`LineData`).
final class DirtyDensityMap {
  DirtyDensityMap._(this.width, this.height, this._prefixSums);

  factory DirtyDensityMap.fromBuffer(Buffer buffer, {Int32List? scratch}) {
    final width = buffer.width();
    final height = buffer.height();
    final size = (width + 1) * (height + 1);
    final prefix = scratch != null && scratch.length >= size
        ? scratch
        : Int32List(size);
    prefix.fillRange(0, size, 0);

    for (var y = 0; y < height; y++) {
      var rowSum = 0;
      for (var x = 0; x < width; x++) {
        if (buffer.isCellDirty(x, y)) rowSum++;
        final idx = (y + 1) * (width + 1) + (x + 1);
        prefix[idx] = prefix[idx - (width + 1)] + rowSum;
      }
    }

    return DirtyDensityMap._(width, height, prefix);
  }

  final int width;
  final int height;
  final Int32List _prefixSums;

  int count(Rectangle area) {
    final clipped = _clipRect(area);
    if (clipped.isEmpty) return 0;
    final stride = width + 1;
    final x0 = clipped.minX;
    final y0 = clipped.minY;
    final x1 = clipped.maxX;
    final y1 = clipped.maxY;
    return _prefixSums[y1 * stride + x1] -
        _prefixSums[y0 * stride + x1] -
        _prefixSums[y1 * stride + x0] +
        _prefixSums[y0 * stride + x0];
  }

  bool hasAny(Rectangle area) => count(area) > 0;

  Rectangle _clipRect(Rectangle area) {
    final x0 = area.minX < 0 ? 0 : area.minX;
    final y0 = area.minY < 0 ? 0 : area.minY;
    final x1 = area.maxX > width ? width : area.maxX;
    final y1 = area.maxY > height ? height : area.maxY;
    if (x0 >= x1 || y0 >= y1) {
      return rect(0, 0, 0, 0);
    }
    return rect(x0, y0, x1 - x0, y1 - y0);
  }
}

final class DirtySpan {
  const DirtySpan({required this.start, required this.end});

  final int start;
  final int end;

  bool overlapsOrTouches(DirtySpan other) =>
      start <= other.end && end >= other.start;

  @override
  bool operator ==(Object other) =>
      other is DirtySpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Metadata for one dirty line.
///
/// [firstCell] and [lastCell] preserve the historical coarse range used by the
/// current renderer. [spans] keeps up to a small number of disjoint dirty
/// ranges so future diff passes can skip unchanged islands without losing the
/// existing fast path.
final class LineData {
  const LineData({
    required this.firstCell,
    required this.lastCell,
    this.spans = const <DirtySpan>[],
    this.overflowed = false,
  }) : _mutableSpans = false;

  LineData._tracked({
    required this.firstCell,
    required this.lastCell,
    required this.spans,
    required this.overflowed,
  }) : _mutableSpans = true;

  static const LineData clean = LineData(firstCell: -1, lastCell: -1);

  final int firstCell;
  final int lastCell;
  final List<DirtySpan> spans;
  final bool overflowed;
  final bool _mutableSpans;

  bool get isDirty => firstCell != -1 || lastCell != -1;

  @override
  bool operator ==(Object other) =>
      other is LineData &&
      other.firstCell == firstCell &&
      other.lastCell == lastCell &&
      other.overflowed == overflowed &&
      _listEquals(other.spans, spans);

  @override
  int get hashCode =>
      Object.hash(firstCell, lastCell, Object.hashAll(spans), overflowed);
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
  int? _renderHash;

  /// The number of cells in this line.
  int get length => _cells.length;

  /// Returns the cell at [x], or null if out of bounds.
  Cell? at(int x) => (x < 0 || x >= _cells.length) ? null : _cells[x];

  /// Replaces the cell at [x] with [cell] without applying wide-cell rules.
  void replace(int x, Cell cell) {
    if (x < 0 || x >= _cells.length) return;
    final cachedHash = _renderHash;
    if (cachedHash != null) {
      final previous = _cells[x];
      _renderHash =
          (cachedHash ^
              _slotHash(x, previous.renderFingerprint) ^
              _slotHash(x, cell.renderFingerprint)) &
          0xFFFFFFFFFFFFFFFF;
    }
    _cells[x].dispose();
    _cells[x] = cell;
  }

  /// Replaces the cell at [x] with a copy of [cell].
  void replaceWithClone(int x, Cell cell) {
    if (x < 0 || x >= _cells.length) return;
    final cachedHash = _renderHash;
    if (cachedHash != null) {
      final previous = _cells[x];
      _renderHash =
          (cachedHash ^
              _slotHash(x, previous.renderFingerprint) ^
              _slotHash(x, cell.renderFingerprint)) &
          0xFFFFFFFFFFFFFFFF;
    }
    _cells[x].copyFrom(cell);
  }

  /// Returns a cached hash of the line's rendered content.
  int renderHash() {
    final cached = _renderHash;
    if (cached != null) return cached;
    var hash = 0;
    for (var i = 0; i < _cells.length; i++) {
      hash ^= _slotHash(i, _cells[i].renderFingerprint);
    }
    _renderHash = hash & 0xFFFFFFFFFFFFFFFF;
    return hash;
  }

  /// Sets the cell at [x], taking ownership of [cell] if provided.
  ///
  /// Callers should use this only when they know [cell] is a freshly created
  /// instance that will not be reused elsewhere.
  void setOwned(int x, Cell? cell) =>
      _setInternal(x, cell, takeOwnership: true);

  /// Sets the cell at [x], applying wide-cell overwrite rules.
  void set(int x, Cell? cell) => _setInternal(x, cell, takeOwnership: false);

  void _setInternal(int x, Cell? cell, {required bool takeOwnership}) {
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
          replace(x + j, prev.cloneEmpty());
        }
      } else if (pw == 0) {
        // Placeholder overwrite: scan left for the wide cell origin.
        for (var j = 1; j < maxCellWidth && x - j >= 0; j++) {
          final wide = at(x - j);
          if (wide == null) continue;
          final ww = wide.width;
          if (ww > 1 && j < ww) {
            for (var k = 0; k < ww && x - j + k < lineWidth; k++) {
              replace(x - j + k, wide.cloneEmpty());
            }
            break;
          }
        }
      }
    }

    if (cell == null) {
      replace(x, Cell.emptyCell());
      return;
    }

    if (takeOwnership) {
      replace(x, cell);
    } else {
      replaceWithClone(x, cell);
    }
    final cw = cell.width;

    if (x + cw > lineWidth) {
      for (var i = 0; i < cw && x + i < lineWidth; i++) {
        replace(x + i, cell.cloneEmpty());
      }
      return;
    }

    if (cw > 1) {
      // Mark placeholder cells with zero-width zero cells.
      for (var j = 1; j < cw && x + j < lineWidth; j++) {
        replace(x + j, Cell.zeroCell());
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
  Buffer._(this.lines, {required this.tracksDirty})
    : touched = tracksDirty
          ? List<LineData?>.filled(lines.length, null)
          : <LineData?>[],
      dirtyRows = tracksDirty
          ? List<bool>.filled(lines.length, false)
          : <bool>[],
      dirtyBits = tracksDirty
          ? List<Uint32List>.generate(lines.length, (_) => Uint32List(0))
          : <Uint32List>[];

  factory Buffer.create(int width, int height, {bool tracksDirty = true}) {
    final lines = List<Line>.generate(height, (_) => Line.filled(width));
    final b = Buffer._(lines, tracksDirty: tracksDirty);
    b.resize(width, height);
    return b;
  }

  /// Creates a buffer from pre-built cells without applying `Line.set()`.
  ///
  /// Upstream tests construct expected buffers directly (without triggering
  /// overwrite logic), so this helper lets Dart parity tests do the same.
  factory Buffer.fromCells(List<List<Cell>> cellLines) {
    final lines = cellLines.map(Line.fromCells).toList(growable: false);
    return Buffer._(lines, tracksDirty: true);
  }

  final List<Line> lines;
  final bool tracksDirty;

  List<LineData?> touched;
  List<bool> dirtyRows;
  List<Uint32List> dirtyBits;
  final List<Rectangle> _scissorStack = <Rectangle>[];
  final List<double> _opacityStack = <double>[1];

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

  /// Pushes a scissor clip rectangle onto the clipping stack.
  ///
  /// Each pushed rectangle is intersected with the current active scissor and
  /// clamped to buffer bounds. Empty clips are retained so that matching pops
  /// restore prior clipping behavior.
  void pushScissor(Rectangle clip) {
    final bufferBounds = bounds();
    final clamped = bufferBounds.intersect(clip);
    final active = _scissorStack.isEmpty ? bufferBounds : _scissorStack.last;
    _scissorStack.add(active.intersect(clamped));
  }

  /// Restores the previous scissor clip rectangle.
  ///
  /// Popping past an empty stack is a no-op.
  void popScissor() {
    if (_scissorStack.isNotEmpty) {
      _scissorStack.removeLast();
    }
  }

  /// Pushes an opacity multiplier onto the opacity stack.
  ///
  /// Multiplicative opacity is applied to incoming `Cell` RGB style channels. This
  /// enables nested translucent overlays where opacity composes as a product.
  void pushOpacity(double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    _opacityStack.add(_opacityStack.last * clamped);
  }

  /// Restores the previous opacity stack frame.
  ///
  /// Popping past the base frame restores full opacity.
  void popOpacity() {
    if (_opacityStack.length > 1) {
      _opacityStack.removeLast();
    }
  }

  /// Sets the cell at ([x], [y]) and updates dirty tracking.
  void setCell(int x, int y, Cell? cell) =>
      _setCell(x, y, cell, takeOwnership: false);

  /// Sets the cell at ([x], [y]) and may take ownership of [cell].
  void setCellOwned(int x, int y, Cell? cell) =>
      _setCell(x, y, cell, takeOwnership: true);

  void _setCell(int x, int y, Cell? cell, {required bool takeOwnership}) {
    if (y < 0 || y >= lines.length) return;
    final line = lines[y];
    if (x < 0 || x >= line.length) return;
    final rawNext = cell ?? Cell.emptyCell();
    if (_isOutsideScissor(x, y, rawNext.width)) return;

    final current = line._cells[x];
    final opacity = _opacityStack.isEmpty ? 1.0 : _opacityStack.last;
    final Cell opacityNext;
    var ownsNext = cell == null;
    if (opacity >= 1.0) {
      opacityNext = rawNext;
    } else {
      opacityNext = _applyOpacity(rawNext);
      ownsNext = true;
    }

    final next = _hasTranslucentOverlay(opacityNext.style)
        ? _compositeCell(current, opacityNext)
        : opacityNext;
    if (current == next) return;
    final w = next.width > 0 ? next.width : 1;
    touchLine(x, y, w);
    final shouldTakeOwnership =
        takeOwnership || ownsNext || !identical(next, rawNext);
    if (shouldTakeOwnership) {
      line.setOwned(x, next);
    } else {
      line.set(x, next);
    }
  }

  /// Resizes the buffer to [width] × [height], preserving content where possible.
  void resize(int width, int height) {
    if (width < 0 || height <= 0) {
      lines.clear();
      touched = <LineData?>[];
      dirtyRows = <bool>[];
      dirtyBits = <Uint32List>[];
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
          newLine.replaceWithClone(x, lines[y].cells[x]);
        }
        lines[y] = newLine;
      }
    }

    if (!tracksDirty) {
      touched = <LineData?>[];
      dirtyRows = <bool>[];
      dirtyBits = <Uint32List>[];
      return;
    }

    touched = List<LineData?>.filled(lines.length, null);
    dirtyRows = List<bool>.filled(lines.length, false);
    dirtyBits = List<Uint32List>.generate(
      lines.length,
      (_) => Uint32List(_dirtyWordCount(width)),
    );
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
    final clipped = area.intersect(bounds());
    if (clipped.isEmpty) return;

    final opaqueSingleWidth =
        (cell == null || !_hasTranslucentOverlay(cell.style)) &&
        (cell == null || cell.width <= 1);
    if (opaqueSingleWidth) {
      final fillCell = cell ?? Cell.emptyCell();
      for (var y = clipped.minY; y < clipped.maxY; y++) {
        touchLine(clipped.minX, y, clipped.width);
        for (var x = clipped.minX; x < clipped.maxX; x++) {
          lines[y].replaceWithClone(x, fillCell);
        }
      }
      return;
    }

    var cellWidth = 1;
    if (cell.width > 1) cellWidth = cell.width;
    for (var y = clipped.minY; y < clipped.maxY; y++) {
      for (var x = clipped.minX; x < clipped.maxX; x += cellWidth) {
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

    final n = Buffer.create(area.width, area.height, tracksDirty: tracksDirty);
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
        lines[i].replaceWithClone(x, lines[i - n].cells[x]);
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
        lines[dst].replaceWithClone(x, lines[src].cells[x]);
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
      lines[y].replaceWithClone(i, lines[y].cells[i - n]);
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
    if (!tracksDirty) return;
    if (y < 0 || y >= lines.length) return;
    if (width <= 0) return;

    if (y >= touched.length) {
      touched = [
        ...touched,
        ...List<LineData?>.filled(y - touched.length + 1, null),
      ];
    }
    if (y >= dirtyRows.length) {
      dirtyRows = [
        ...dirtyRows,
        ...List<bool>.filled(y - dirtyRows.length + 1, false),
      ];
    }
    if (y >= dirtyBits.length) {
      final width = this.width();
      dirtyBits = [
        ...dirtyBits,
        ...List<Uint32List>.generate(
          y - dirtyBits.length + 1,
          (_) => Uint32List(_dirtyWordCount(width)),
        ),
      ];
    }

    final ch = touched[y];
    final first = x;
    final last = x + width;
    dirtyRows[y] = true;
    _markDirtyBits(y, first, last);
    if (ch == null) {
      touched[y] = LineData._tracked(
        firstCell: first,
        lastCell: last,
        spans: <DirtySpan>[DirtySpan(start: first, end: last)],
        overflowed: false,
      );
    } else {
      final prevFirst = ch.firstCell == -1 ? first : ch.firstCell;
      final prevLast = ch.lastCell == -1 ? last : ch.lastCell;
      if (ch.overflowed) {
        final mergedFirst = first < prevFirst ? first : prevFirst;
        final mergedLast = last > prevLast ? last : prevLast;
        final spans = ch._mutableSpans && ch.spans.isNotEmpty
            ? ch.spans
            : <DirtySpan>[DirtySpan(start: mergedFirst, end: mergedLast)];
        if (spans.isNotEmpty) {
          spans[0] = DirtySpan(start: mergedFirst, end: mergedLast);
          if (spans.length > 1) spans.removeRange(1, spans.length);
        }
        touched[y] = LineData._tracked(
          firstCell: mergedFirst,
          lastCell: mergedLast,
          spans: spans,
          overflowed: true,
        );
        return;
      }
      if (ch.spans.isNotEmpty) {
        final lastSpan = ch.spans.last;
        if (first <= lastSpan.end && first >= lastSpan.start) {
          final mergedSpans = ch._mutableSpans
              ? ch.spans
              : List<DirtySpan>.from(ch.spans);
          mergedSpans[mergedSpans.length - 1] = DirtySpan(
            start: lastSpan.start,
            end: last > lastSpan.end ? last : lastSpan.end,
          );
          touched[y] = LineData._tracked(
            firstCell: first < prevFirst ? first : prevFirst,
            lastCell: last > prevLast ? last : prevLast,
            spans: mergedSpans,
            overflowed: false,
          );
          return;
        }
      }
      final spans = _mergeDirtySpans(
        ch.spans,
        DirtySpan(start: first, end: last),
        reuseExisting: ch._mutableSpans,
      );
      touched[y] = LineData._tracked(
        firstCell: first < prevFirst ? first : prevFirst,
        lastCell: last > prevLast ? last : prevLast,
        spans: spans.spans,
        overflowed: spans.overflowed || ch.overflowed,
      );
    }
  }

  void clearDirtyLine(int y) {
    if (!tracksDirty) return;
    if (y < 0 || y >= lines.length) return;
    if (y < touched.length) {
      touched[y] = LineData.clean;
    }
    if (y < dirtyRows.length) {
      dirtyRows[y] = false;
    }
    if (y < dirtyBits.length) {
      dirtyBits[y].fillRange(0, dirtyBits[y].length, 0);
    }
  }

  void clearDirtyTracking() {
    if (!tracksDirty) {
      touched = <LineData?>[];
      dirtyRows = <bool>[];
      dirtyBits = <Uint32List>[];
      return;
    }
    touched = List<LineData?>.filled(lines.length, LineData.clean);
    dirtyRows = List<bool>.filled(lines.length, false);
    dirtyBits = List<Uint32List>.generate(
      lines.length,
      (_) => Uint32List(_dirtyWordCount(width())),
    );
  }

  bool _isOutsideScissor(int x, int y, int width) {
    if (_scissorStack.isEmpty) return false;
    final s = _scissorStack.last;
    final minX = x;
    final maxX = x + width;
    return y < s.minY || y >= s.maxY || maxX <= s.minX || minX >= s.maxX;
  }

  Cell _applyOpacity(Cell cell) {
    final opacity = _opacityStack.isEmpty ? 1.0 : _opacityStack.last;
    if (opacity >= 1.0) return cell;
    if (opacity <= 0.0) {
      return Cell(
        content: cell.content,
        style: const UvStyle(),
        link: cell.link,
        width: cell.width,
      );
    }

    final style = cell.style;
    return Cell(
      content: cell.content,
      style: UvStyle(
        fg: _scaledColor(style.fg, opacity),
        bg: _scaledColor(style.bg, opacity),
        underlineColor: _scaledColor(style.underlineColor, opacity),
        underline: style.underline,
        attrs: style.attrs,
      ),
      link: cell.link,
      width: cell.width,
    );
  }

  bool isCellDirty(int x, int y) {
    if (x < 0 || y < 0 || y >= dirtyBits.length) return false;
    final bits = dirtyBits[y];
    if (bits.isEmpty) return false;
    final word = x >> 5;
    if (word >= bits.length) return false;
    final mask = 1 << (x & 31);
    return (bits[word] & mask) != 0;
  }

  List<DirtySpan> dirtyBitSpans(int y) {
    if (y < 0 || y >= dirtyBits.length) return const <DirtySpan>[];
    final bits = dirtyBits[y];
    if (bits.isEmpty) return const <DirtySpan>[];
    final spans = <DirtySpan>[];
    final rowWidth = width();
    var start = -1;
    for (var x = 0; x < rowWidth; x++) {
      final dirty = isCellDirty(x, y);
      if (dirty) {
        start = start == -1 ? x : start;
      } else if (start != -1) {
        spans.add(DirtySpan(start: start, end: x));
        start = -1;
      }
    }
    if (start != -1) {
      spans.add(DirtySpan(start: start, end: rowWidth));
    }
    return spans;
  }

  void _markDirtyBits(int y, int start, int end) {
    if (y < 0 || y >= dirtyBits.length) return;
    final bits = dirtyBits[y];
    if (bits.isEmpty) return;
    final width = this.width();
    var x0 = start < 0 ? 0 : start;
    var x1 = end > width ? width : end;
    if (x0 >= x1) return;
    final startWord = x0 >> 5;
    final endWord = (x1 - 1) >> 5;
    for (var word = startWord; word <= endWord; word++) {
      final wordStart = word << 5;
      final wordEnd = wordStart + 32;
      final from = x0 > wordStart ? x0 - wordStart : 0;
      final to = x1 < wordEnd ? x1 - wordStart : 32;
      final mask = _bitMask(from, to);
      bits[word] |= mask;
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

Cell _compositeCell(Cell base, Cell overlay) {
  final style = overlay.style;
  if (!_hasTranslucentOverlay(style)) {
    return overlay;
  }
  final bg = color_utils.sourceOver(style.bg, base.style.bg);
  final fg = color_utils.sourceOver(style.fg, base.style.fg);
  final underlineColor = color_utils.sourceOver(
    style.underlineColor,
    base.style.underlineColor,
  );
  if (bg == style.bg &&
      fg == style.fg &&
      underlineColor == style.underlineColor) {
    return overlay;
  }
  return overlay.clone()
    ..style = style.copyWith(
      fg: fg,
      clearFg: fg == null,
      bg: bg,
      clearBg: bg == null,
      underlineColor: underlineColor,
      clearUnderlineColor: underlineColor == null,
    );
}

bool _hasTranslucentOverlay(UvStyle style) =>
    _isTranslucentColor(style.fg) ||
    _isTranslucentColor(style.bg) ||
    _isTranslucentColor(style.underlineColor);

bool _isTranslucentColor(UvColor? color) =>
    color is UvRgb && color.a > 0 && color.a < 255;

UvColor? _scaledColor(UvColor? color, double opacity) {
  if (color == null) return null;
  if (color is! UvRgb) return color;
  final a = (color.a * opacity).clamp(0, 255).round();
  return UvRgb(color.r, color.g, color.b, a: a);
}

({List<DirtySpan> spans, bool overflowed}) _mergeDirtySpans(
  List<DirtySpan> existing,
  DirtySpan next, {
  bool reuseExisting = false,
}) {
  const maxTrackedSpans = 4;
  if (existing.isEmpty) {
    return (spans: <DirtySpan>[next], overflowed: false);
  }

  final spans = reuseExisting ? existing : <DirtySpan>[...existing];
  spans.add(next);
  spans.sort((a, b) => a.start.compareTo(b.start));

  var writeIndex = 0;
  for (final span in spans) {
    if (writeIndex == 0) {
      spans[writeIndex++] = span;
      continue;
    }
    final last = spans[writeIndex - 1];
    if (last.overlapsOrTouches(span)) {
      spans[writeIndex - 1] = DirtySpan(
        start: last.start < span.start ? last.start : span.start,
        end: last.end > span.end ? last.end : span.end,
      );
      continue;
    }
    spans[writeIndex++] = span;
  }

  if (writeIndex <= maxTrackedSpans) {
    if (writeIndex < spans.length) {
      spans.removeRange(writeIndex, spans.length);
    }
    return (spans: spans, overflowed: false);
  }

  final first = spans.first.start;
  final last = spans[writeIndex - 1].end;
  spans[0] = DirtySpan(start: first, end: last);
  if (spans.length > 1) spans.removeRange(1, spans.length);
  return (spans: spans, overflowed: true);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _dirtyWordCount(int width) => width <= 0 ? 0 : ((width - 1) >> 5) + 1;

int _slotHash(int index, int value) {
  var hash = 0xcbf29ce484222325;
  hash ^= index & 0xFFFFFFFF;
  hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  hash ^= index >>> 32;
  hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  hash ^= value & 0xFFFFFFFF;
  hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  hash ^= value >>> 32;
  hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  return hash;
}

int _bitMask(int from, int to) {
  var mask = 0;
  for (var bit = from; bit < to; bit++) {
    mask |= 1 << bit;
  }
  return mask;
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
        OwnedCellScreen,
        CloneableScreen,
        CloneAreaScreen {
  ScreenBuffer(int width, int height, {bool tracksDirty = true})
    : method = WidthMethod.wcwidth,
      buffer = Buffer.create(width, height, tracksDirty: tracksDirty);

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

  @override
  void setCellOwned(int x, int y, Cell? cell) =>
      buffer.setCellOwned(x, y, cell);

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
  final normalized = text.contains('\r') ? text.replaceAll('\r\n', '\n') : text;
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
  final stripped = term_ansi.Ansi.stripAnsi(line);
  final expanded = term_ansi.Ansi.expandTabs(stripped);
  return method.stringWidth(expanded) +
      terminal_graphics.terminalGraphicsCellWidth(line);
}
