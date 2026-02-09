/// Histogram (vertical bar) chart renderer for UV screens.
library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Draws a vertical bar histogram of [values] into [area] on [screen].
void drawHistogram(
  Screen screen,
  Rectangle area,
  List<double> values, {
  UvStyle barStyle = const UvStyle(),
  UvStyle axisStyle = const UvStyle(),
  UvStyle gridStyle = const UvStyle(),
  UvStyle labelStyle = const UvStyle(),
  bool showAxis = true,
  bool showGrid = false,
  int gridRows = 3,
  int gridCols = 0,
  List<String>? xLabels,
  List<String>? yLabels,
  String barChar = '█',
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || values.isEmpty) return;

  final usableHeight = showAxis ? height - 1 : height;
  if (usableHeight <= 0) return;

  final bins = sampleSeries(values, width);
  final minValue = bins.reduce((a, b) => a < b ? a : b);
  final maxValue = bins.reduce((a, b) => a > b ? a : b);

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

  for (var x = 0; x < width; x++) {
    final normalized = normalize(bins[x], minValue, maxValue);
    final barHeight = (normalized * usableHeight).round();
    for (var y = 0; y < barHeight; y++) {
      final targetY = area.maxY - 1 - y - (showAxis ? 1 : 0);
      putCell(screen, area.minX + x, targetY, barChar, barStyle);
    }
  }

  if (showAxis) {
    final axisY = area.maxY - 1;
    for (var x = 0; x < width; x++) {
      putCell(screen, area.minX + x, axisY, '─', axisStyle);
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
