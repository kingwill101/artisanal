/// Generic cell-buffer strokes: horizontal, vertical, and Bresenham runs.
///
/// These helpers write a caller-supplied glyph and [UvStyle]. They do not
/// infer chart-specific box-drawing characters from step direction.
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
library;

import 'cell.dart';
import 'geometry.dart';
import 'screen.dart';

/// Writes [count] cells of [glyph] starting at ([x], [y]), advancing right.
void drawHorizontal(
  Screen screen,
  int x,
  int y,
  int count, {
  String glyph = '─',
  UvStyle style = const UvStyle(),
}) {
  _drawRun(screen, x, y, 1, 0, count, glyph, style);
}

/// Writes [count] cells of [glyph] starting at ([x], [y]), advancing down.
void drawVertical(
  Screen screen,
  int x,
  int y,
  int count, {
  String glyph = '│',
  UvStyle style = const UvStyle(),
}) {
  _drawRun(screen, x, y, 0, 1, count, glyph, style);
}

/// Writes [glyph] along a Bresenham line from ([x0], [y0]) to ([x1], [y1]).
///
/// Out-of-bounds cells are skipped. Endpoints are inclusive.
void drawStroke(
  Screen screen,
  int x0,
  int y0,
  int x1,
  int y1, {
  String glyph = '─',
  UvStyle style = const UvStyle(),
}) {
  final bounds = screen.bounds();
  final dx = (x1 - x0).abs();
  final dy = (y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx - dy;
  var cx = x0;
  var cy = y0;

  while (true) {
    _putGlyph(screen, bounds, cx, cy, glyph, style);
    if (cx == x1 && cy == y1) return;
    final e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      cx += sx;
    }
    if (e2 < dx) {
      err += dx;
      cy += sy;
    }
  }
}

void _drawRun(
  Screen screen,
  int x,
  int y,
  int stepX,
  int stepY,
  int count,
  String glyph,
  UvStyle style,
) {
  if (count <= 0) return;
  final bounds = screen.bounds();
  var cx = x;
  var cy = y;
  for (var i = 0; i < count; i++) {
    _putGlyph(screen, bounds, cx, cy, glyph, style);
    cx += stepX;
    cy += stepY;
  }
}

void _putGlyph(
  Screen screen,
  Rectangle bounds,
  int x,
  int y,
  String glyph,
  UvStyle style,
) {
  if (x < bounds.minX ||
      y < bounds.minY ||
      x >= bounds.maxX ||
      y >= bounds.maxY) {
    return;
  }
  final cell = Cell.newCell(screen.widthMethod(), glyph)..style = style;
  if (screen is OwnedCellScreen) {
    screen.setCellOwned(x, y, cell);
  } else {
    screen.setCell(x, y, cell);
  }
}
