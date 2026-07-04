/// Stacked ribbon (area) chart renderer for UV screens.
library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';
import 'package:artisanal/style.dart';

/// Draws a stacked ribbon chart of multiple [series] into [area] on [screen].
///
/// Each column of cells is divided into vertical bands, one per series,
/// stacked from the bottom up.  Band boundaries use half-block characters
/// (`▀`/`▄`) with foreground/background colour blending to produce smoother
/// transitions between adjacent series colours.
void drawRibbonChart(
  Screen screen,
  Rectangle area,
  List<List<double>> series, {
  List<UvStyle>? styles,
  bool normalizeTotals = true,
  String fillChar = BlockShades.full,
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

  // Use sub-cell resolution: 8 sub-rows per cell for smoother gradients.
  final subHeight = height * 8;

  for (var x = 0; x < width; x++) {
    final total = totals[x];
    final scale = normalizeTotals
        ? (total <= 0 ? 0.0 : subHeight / total)
        : (maxTotal <= 0 ? 0.0 : subHeight / maxTotal);

    final subRows = List<int>.filled(subHeight, -1);
    var cursor = 0;
    var cumulative = 0.0;
    for (var i = 0; i < seriesCount; i++) {
      final value = sampled[i][x];
      final prevRound = cumulative.round();
      cumulative += value * scale;
      final nextRound = cumulative.round();
      final bandHeight = nextRound - prevRound;
      for (var s = 0; s < bandHeight && cursor + s < subHeight; s++) {
        subRows[cursor + s] = i;
      }
      cursor += bandHeight;
      if (cursor >= subHeight) break;
    }

    for (var cellRow = 0; cellRow < height; cellRow++) {
      final screenY = area.minY + cellRow;
      final upperSub = subHeight - 1 - cellRow * 8; // top sub-row of cell
      final lowerSub = upperSub - 7; // bottom sub-row of cell (8 sub-rows)

      // Determine series indices for this cell's 8 sub-rows, clamping.
      final upperIdx = (upperSub >= 0 && upperSub < subHeight)
          ? subRows[upperSub]
          : -1;
      final lowerIdx = (lowerSub >= 0 && lowerSub < subHeight)
          ? subRows[lowerSub]
          : -1;

      if (upperIdx == -1 && lowerIdx == -1) {
        continue;
      }

      if (upperIdx == lowerIdx && upperIdx != -1) {
        final sty = palette[upperIdx % palette.length];
        putSolidChartCell(
          screen,
          area.minX + x,
          screenY,
          sty,
          fillChar,
        );
      } else if (upperIdx == -1) {
        final sty = palette[lowerIdx % palette.length];
        final fgColor = sty.bg ?? sty.fg;
        putCell(
          screen,
          area.minX + x,
          screenY,
          BlockShades.lower,
          UvStyle(fg: fgColor),
        );
      } else if (lowerIdx == -1) {
        final sty = palette[upperIdx % palette.length];
        final fgColor = sty.bg ?? sty.fg;
        putCell(
          screen,
          area.minX + x,
          screenY,
          BlockShades.upper,
          UvStyle(fg: fgColor),
        );
      } else {
        final upperSty = palette[upperIdx % palette.length];
        final lowerSty = palette[lowerIdx % palette.length];
        final fg = upperSty.bg ?? upperSty.fg;
        final bg = lowerSty.bg ?? lowerSty.fg;
        putCell(
          screen,
          area.minX + x,
          screenY,
          BlockShades.upper,
          UvStyle(fg: fg, bg: bg),
        );
      }
    }
  }
}
