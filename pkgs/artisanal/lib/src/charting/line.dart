/// Line chart renderer for UV screens.
library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Draws a line chart of [values] into [area] on [screen].
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
      hChar: '┄',
      vChar: '┆',
      intersectionChar: '┼',
    );
  }

  final samples = sampleSeries(values, width);
  final minValue = samples.reduce((a, b) => a < b ? a : b);
  final maxValue = samples.reduce((a, b) => a > b ? a : b);

  final points = List.generate(samples.length, (i) {
    final normalized = normalize(samples[i], minValue, maxValue);
    final y = area.maxY - 1 - (normalized * (height - 1)).round();
    return (x: area.minX + i, y: y);
  }, growable: false);

  for (var i = 0; i < points.length - 1; i++) {
    final start = points[i];
    final end = points[i + 1];
    _drawLineSegment(
      screen,
      start.x,
      start.y,
      end.x,
      end.y,
      lineChar,
      lineStyle,
    );
  }

  if (showMarkers) {
    for (final point in points) {
      putCell(screen, point.x, point.y, markerChar, lineStyle);
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

void _drawLineSegment(
  Screen screen,
  int x0,
  int y0,
  int x1,
  int y1,
  String glyph,
  UvStyle style,
) {
  final dx = (x1 - x0).abs();
  final dy = (y1 - y0).abs();
  final steps = dx > dy ? dx : dy;
  if (steps == 0) {
    putCell(screen, x0, y0, glyph, style);
    return;
  }
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = (x0 + (x1 - x0) * t).round();
    final y = (y0 + (y1 - y0) * t).round();
    putCell(screen, x, y, glyph, style);
  }
}
