/// Line chart renderer for UV screens.
library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Draws a line chart of [values] into [area] on [screen].
///
/// The line is rendered using Braille dot patterns (U+2800–U+28FF) which
/// provide 2×4 sub-cell resolution per character cell.  Data points are
/// mapped directly to their Braille-space positions and connected with
/// Bresenham lines for smooth, continuous curves.  Data-point markers are
/// drawn on top of the Braille line when [showMarkers] is true.
void drawLineChart(
  Screen screen,
  Rectangle area,
  List<double> values, {
  UvStyle lineStyle = const UvStyle(),
  UvStyle gridStyle = const UvStyle(),
  UvStyle labelStyle = const UvStyle(),
  bool showGrid = false,
  int gridRows = 3,
  int gridCols = 3,
  bool showMarkers = true,
  String markerChar = '●',
  String lineChar = '•',
  List<String>? xLabels,
  List<String>? yLabels,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 1 || height <= 1 || values.isEmpty) return;

  if (showGrid) {
    drawGrid(
      screen,
      area,
      rows: gridRows,
      cols: gridCols,
      style: gridStyle,
      hChar: '·',
      vChar: '·',
      intersectionChar: '·',
    );
  }

  // --- Braille sub-pixel canvas ---
  // Each cell is 2 dots wide × 4 dots tall.
  final bWidth = width * 2;
  final bHeight = height * 4;

  // Allocate the Braille dot grid (false = empty).
  final dots = List<List<bool>>.generate(
    bHeight,
    (_) => List<bool>.filled(bWidth, false),
  );

  // Compute min/max from the original values.
  final minValue = values.reduce((a, b) => a < b ? a : b);
  final maxValue = values.reduce((a, b) => a > b ? a : b);

  // Map each original data point to a Braille-space coordinate.
  // N data points are evenly spaced across the Braille width.
  final n = values.length;
  final bPoints = List<({int x, int y})>.generate(n, (i) {
    // Evenly distribute data points across Braille-space X axis.
    final bx = n <= 1 ? 0 : (i * (bWidth - 1) / (n - 1)).round();
    final normalized = normalize(values[i], minValue, maxValue);
    // y=0 is top in Braille grid; invert so high values are at the top.
    final by = (bHeight - 1) - (normalized * (bHeight - 1)).round();
    return (x: bx.clamp(0, bWidth - 1), y: by.clamp(0, bHeight - 1));
  });

  // Rasterize lines between successive Braille-space points.
  for (var i = 0; i < bPoints.length - 1; i++) {
    _brailleLine(
      dots,
      bPoints[i].x,
      bPoints[i].y,
      bPoints[i + 1].x,
      bPoints[i + 1].y,
    );
  }
  // If there's only one point, plot it as a single dot.
  if (bPoints.length == 1) {
    final p = bPoints[0];
    if (p.x >= 0 && p.x < bWidth && p.y >= 0 && p.y < bHeight) {
      dots[p.y][p.x] = true;
    }
  }

  // Convert the dot grid to Braille characters.
  _renderBraille(screen, area, dots, lineStyle);

  // --- Markers at the original (cell-resolution) data-point positions ---
  if (showMarkers) {
    for (var i = 0; i < n; i++) {
      // Same X mapping as Braille-space, but in cell coordinates.
      final cellX = n <= 1 ? 0 : (i * (width - 1) / (n - 1)).round();
      final normalized = normalize(values[i], minValue, maxValue);
      final cellY = area.maxY - 1 - (normalized * (height - 1)).round();
      putCell(
        screen,
        (area.minX + cellX).clamp(area.minX, area.maxX - 1),
        cellY.clamp(area.minY, area.maxY - 1),
        markerChar,
        lineStyle,
      );
    }
  }

  if ((xLabels != null && xLabels.isNotEmpty) ||
      (yLabels != null && yLabels.isNotEmpty)) {
    drawAxisLabels(
      screen,
      area,
      xLabels: xLabels,
      yLabels: yLabels,
      style: labelStyle,
    );
  }
}

/// Plots a line between two points on the Braille dot grid using Bresenham.
void _brailleLine(List<List<bool>> dots, int x0, int y0, int x1, int y1) {
  var dx = (x1 - x0).abs();
  var dy = -(y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;
  final bw = dots[0].length;
  final bh = dots.length;

  var cx = x0;
  var cy = y0;

  while (true) {
    if (cx >= 0 && cx < bw && cy >= 0 && cy < bh) {
      dots[cy][cx] = true;
    }
    if (cx == x1 && cy == y1) break;
    final e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      cx += sx;
    }
    if (e2 <= dx) {
      err += dx;
      cy += sy;
    }
  }
}

/// Converts the Braille dot grid into characters and writes them to [screen].
///
/// Each terminal cell maps to a 2-wide × 4-tall region of the dot grid.
/// The 8 dots are encoded into the Unicode Braille Patterns block
/// (U+2800 + bitmask), where the bit positions are:
///
/// ```
///   Col0  Col1
///   0x01  0x08
///   0x02  0x10
///   0x04  0x20
///   0x40  0x80
/// ```
void _renderBraille(
  Screen screen,
  Rectangle area,
  List<List<bool>> dots,
  UvStyle style,
) {
  final bw = dots.isEmpty ? 0 : dots[0].length;
  final bh = dots.length;
  final cellW = area.width;
  final cellH = area.height;

  for (var cy = 0; cy < cellH; cy++) {
    for (var cx = 0; cx < cellW; cx++) {
      var codePoint = 0;
      // Map cell (cx, cy) -> dot region starting at (cx*2, cy*4).
      final bx = cx * 2;
      final by = cy * 4;

      // Left column bits: rows 0-2 => bits 0-2, row 3 => bit 6.
      if (by < bh && bx < bw && dots[by][bx]) codePoint |= 0x01;
      if (by + 1 < bh && bx < bw && dots[by + 1][bx]) codePoint |= 0x02;
      if (by + 2 < bh && bx < bw && dots[by + 2][bx]) codePoint |= 0x04;
      if (by + 3 < bh && bx < bw && dots[by + 3][bx]) codePoint |= 0x40;

      // Right column bits: rows 0-2 => bits 3-5, row 3 => bit 7.
      if (by < bh && bx + 1 < bw && dots[by][bx + 1]) codePoint |= 0x08;
      if (by + 1 < bh && bx + 1 < bw && dots[by + 1][bx + 1]) {
        codePoint |= 0x10;
      }
      if (by + 2 < bh && bx + 1 < bw && dots[by + 2][bx + 1]) {
        codePoint |= 0x20;
      }
      if (by + 3 < bh && bx + 1 < bw && dots[by + 3][bx + 1]) {
        codePoint |= 0x80;
      }

      if (codePoint != 0) {
        final glyph = String.fromCharCode(0x2800 + codePoint);
        putCell(screen, area.minX + cx, area.minY + cy, glyph, style);
      }
    }
  }
}
