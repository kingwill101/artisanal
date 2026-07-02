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

  // Use sub-cell (half-block) resolution: 2 half-rows per cell.
  final subHeight = height * 2;

  for (var x = 0; x < width; x++) {
    final total = totals[x];
    final scale = normalizeTotals
        ? (total <= 0 ? 0.0 : subHeight / total)
        : (maxTotal <= 0 ? 0.0 : subHeight / maxTotal);

    // Compute the series index for each sub-row (bottom = index 0).
    // -1 means empty.
    final subRows = List<int>.filled(subHeight, -1);
    var cursor = 0;
    for (var i = 0; i < seriesCount; i++) {
      final value = sampled[i][x];
      final bandHeight = (value * scale).round();
      for (var s = 0; s < bandHeight && cursor + s < subHeight; s++) {
        subRows[cursor + s] = i;
      }
      cursor += bandHeight;
      if (cursor >= subHeight) break;
    }

    // Now render pairs of sub-rows into cells.
    // Sub-row 0 is the bottom of the chart; cell row (height-1) is the
    // bottom screen row.  Within a cell, the lower half corresponds to the
    // even sub-row and the upper half to the odd sub-row.
    for (var cellRow = 0; cellRow < height; cellRow++) {
      final screenY = area.minY + cellRow;
      // Map: cellRow 0 = top of area.  Sub-row for top-of-chart is
      // subHeight-1.
      final upperSub = subHeight - 1 - cellRow * 2; // top half of cell
      final lowerSub = upperSub - 1; // bottom half of cell

      final upperIdx = (upperSub >= 0 && upperSub < subHeight)
          ? subRows[upperSub]
          : -1;
      final lowerIdx = (lowerSub >= 0 && lowerSub < subHeight)
          ? subRows[lowerSub]
          : -1;

      if (upperIdx == -1 && lowerIdx == -1) {
        // Empty cell — skip.
        continue;
      }

      if (upperIdx == lowerIdx) {
        // Both halves are the same series — full block.
        final sty = palette[upperIdx % palette.length];
        final bgColor = sty.bg ?? sty.fg;
        if (bgColor != null) {
          putCell(screen, area.minX + x, screenY, ' ', UvStyle(bg: bgColor));
        } else {
          putCell(screen, area.minX + x, screenY, fillChar, sty);
        }
      } else if (upperIdx == -1) {
        // Only the lower half has content — draw ▄ (lower half block).
        final sty = palette[lowerIdx % palette.length];
        final fgColor = sty.bg ?? sty.fg;
        putCell(screen, area.minX + x, screenY, BlockShades.lower, UvStyle(fg: fgColor));
      } else if (lowerIdx == -1) {
        // Only the upper half has content — draw ▀ (upper half block).
        final sty = palette[upperIdx % palette.length];
        final fgColor = sty.bg ?? sty.fg;
        putCell(screen, area.minX + x, screenY, BlockShades.upper, UvStyle(fg: fgColor));
      } else {
        // Two different series meet — draw ▀ with fg = upper color,
        // bg = lower color.
        final upperSty = palette[upperIdx % palette.length];
        final lowerSty = palette[lowerIdx % palette.length];
        final fg = upperSty.bg ?? upperSty.fg;
        final bg = lowerSty.bg ?? lowerSty.fg;
        putCell(screen, area.minX + x, screenY, BlockShades.upper, UvStyle(fg: fg, bg: bg));
      }
    }
  }
}
