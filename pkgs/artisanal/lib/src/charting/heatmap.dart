/// Heatmap renderer for UV screens.
library;

import 'package:ultraviolet/core.dart';
import 'core.dart';
import 'palette.dart';

/// Draws a heatmap of the 2-D [grid] values into [area] on [screen].
void drawHeatmap(
  Screen screen,
  Rectangle area,
  List<List<double>> grid, {
  ChartRamp? ramp,
  bool useBackground = true,
  String glyph = ' ',
  bool showGrid = false,
  int gridRows = 3,
  int gridCols = 3,
  UvStyle gridStyle = const UvStyle(),
  List<String>? xLabels,
  List<String>? yLabels,
  UvStyle labelStyle = const UvStyle(),
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || grid.isEmpty) return;

  final gridHeight = grid.length;
  final gridWidth = grid.first.length;
  if (gridWidth == 0) return;

  final rampToUse = ramp ?? ChartRamp.thermal();

  final xScale = gridWidth / width;
  final yScale = gridHeight / height;

  for (var y = 0; y < height; y++) {
    final sourceY = (y * yScale).floor().clamp(0, gridHeight - 1);
    final row = grid[sourceY];
    for (var x = 0; x < width; x++) {
      final sourceX = (x * xScale).floor().clamp(0, gridWidth - 1);
      final value = clamp01(row[sourceX]);
      final style = rampToUse.styleFor(value, background: useBackground);
      final cellStyle = useBackground ? style : style.copyWith(clearBg: true);
      putCell(screen, area.minX + x, area.minY + y, glyph, cellStyle);
    }
  }

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
      preserveBackground: useBackground,
    );
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
