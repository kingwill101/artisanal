/// Immediate-mode Canvas for composing [Drawable]s onto a backing [Buffer].
///
/// [Canvas] implements [Screen] and provides simple drawing operations that
/// write directly into a cell buffer. Use it to build layers of content and
/// then present via a [Compositor] and [Screen].
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final canvas = Canvas(80, 24);
/// // Compose a drawable (e.g., StyledString) onto the canvas.
/// StyledString('Hello, UV').draw(canvas, canvas.bounds());
/// final rendered = canvas.render();
/// ```
library;

import 'cell.dart';
import 'buffer.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import '../unicode/width.dart';

/// Canvas is a cell-buffer that can be used to compose and draw [Drawable]s.
final class Canvas
    implements
        Screen,
        OwnedCellScreen,
        ClearableScreen,
        ClearAreaScreen,
        FillableScreen,
        FillAreaScreen,
        Drawable {
  /// Creates a canvas with [width] and [height] in cells.
  Canvas(int width, int height)
    : _scr = ScreenBuffer(width, height, tracksDirty: false) {
    // Lip Gloss v2 uses GraphemeWidth for canvas composition.
    _scr.method = WidthMethod.grapheme;
  }

  final ScreenBuffer _scr;

  /// The mutable backing buffer.
  Buffer get buffer => _scr.buffer;

  /// Resizes the canvas backing buffer to the given dimensions.
  void resize(int width, int height) => _scr.resize(width, height);

  /// Clears the entire canvas to empty cells.
  @override
  void clear() => _scr.clear();

  @override
  void clearArea(Rectangle area) => _scr.clearArea(area);

  @override
  void fill(Cell? cell) => _scr.fill(cell);

  @override
  void fillArea(Cell? cell, Rectangle area) => _scr.fillArea(cell, area);

  /// The current canvas width in cells.
  int width() => _scr.width();

  /// The current canvas height in cells.
  int height() => _scr.height();

  /// Returns the drawable bounds of the canvas.
  @override
  Rectangle bounds() => _scr.bounds();

  /// Returns the active grapheme width measurement method.
  @override
  WidthMethod widthMethod() => _scr.widthMethod();

  /// Returns the cell at ([x], [y]) or null if out of bounds.
  @override
  Cell? cellAt(int x, int y) => _scr.cellAt(x, y);

  /// Sets the cell at ([x], [y]) in the backing buffer.
  @override
  void setCell(int x, int y, Cell? cell) => _scr.setCell(x, y, cell);

  @override
  void setCellOwned(int x, int y, Cell? cell) => _scr.setCellOwned(x, y, cell);

  /// Composes a [Drawable] onto this canvas.
  Canvas compose(Drawable drawer) {
    drawer.draw(this, bounds());
    return this;
  }

  /// Renders the canvas into a string (trimming trailing spaces per line).
  String render() => _scr.buffer.render();

  /// Draws this canvas onto another [Screen] within [area].
  @override
  void draw(Screen screen, Rectangle area) => _scr.draw(screen, area);
}
