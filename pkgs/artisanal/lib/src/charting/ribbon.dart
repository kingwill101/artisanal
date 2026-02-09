/// Stacked ribbon (area) chart renderer for UV screens.
library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Draws a stacked ribbon chart of multiple [series] into [area] on [screen].
void drawRibbonChart(
  Screen screen,
  Rectangle area,
  List<List<double>> series, {
  List<UvStyle>? styles,
  bool normalizeTotals = true,
  String fillChar = '█',
  bool showGrid = false,
  int gridRows = 3,
  int gridCols = 0,
  UvStyle gridStyle = const UvStyle(),
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || series.isEmpty) return;

  final sampled = series.map((values) => sampleSeries(values, width)).toList();
  final seriesCount = sampled.length;
  final palette = styles ?? List<UvStyle>.filled(seriesCount, const UvStyle());

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

  final totals = List<double>.filled(width, 0);
  for (var x = 0; x < width; x++) {
    var total = 0.0;
    for (var i = 0; i < seriesCount; i++) {
      total += sampled[i][x];
    }
    totals[x] = total;
  }

  final maxTotal = totals.reduce((a, b) => a > b ? a : b);

  for (var x = 0; x < width; x++) {
    final total = totals[x];
    final scale = normalizeTotals
        ? (total <= 0 ? 0 : height / total)
        : (maxTotal <= 0 ? 0 : height / maxTotal);

    var cursorY = area.maxY - 1;
    for (var i = 0; i < seriesCount; i++) {
      final value = sampled[i][x];
      final bandHeight = (value * scale).round();
      if (bandHeight <= 0) continue;
      for (var y = 0; y < bandHeight && cursorY - y >= area.minY; y++) {
        putCell(screen, area.minX + x, cursorY - y, fillChar, palette[i]);
      }
      cursorY -= bandHeight;
      if (cursorY < area.minY) break;
    }
  }
}
