/// Histogram (vertical bar) chart renderer for UV screens.
library;

import 'dart:math' as math;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';
import 'package:artisanal/style.dart';

/// Fractional top glyphs used by FTUI-style grouped vertical bars.
const _barChars = SparkBars.levels;

// ---------------------------------------------------------------------------
// Single-series vertical histogram (backward-compatible)
// ---------------------------------------------------------------------------

/// Draws a vertical bar histogram of [values] into [area] on [screen].
///
/// Each bar occupies one or more columns with a 1-cell gap between bars.
/// The bar heights use half-block characters at the top for sub-cell
/// vertical precision (2× resolution).  When [showAxis] is true the
/// bottom row is reserved for a horizontal axis line.
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
  String barChar = BlockShades.full,
  int barGap = 1,
  int? barWidth,
  bool drawAxisLine = true,
}) {
  drawGroupedHistogram(
    screen,
    area,
    [values],
    styles: [barStyle],
    axisStyle: axisStyle,
    gridStyle: gridStyle,
    labelStyle: labelStyle,
    showAxis: showAxis,
    showGrid: showGrid,
    gridRows: gridRows,
    gridCols: gridCols,
    xLabels: xLabels,
    yLabels: yLabels,
    barChar: barChar,
    barGap: barGap,
    groupGap: barGap,
    barWidth: barWidth,
    drawAxisLine: drawAxisLine,
  );
}

// ---------------------------------------------------------------------------
// Multi-series grouped histogram (side-by-side bars)
// ---------------------------------------------------------------------------

/// Draws a grouped (side-by-side) multi-series vertical bar chart.
///
/// Each group contains one bar per series, placed side by side.
/// [seriesList] is a list of value lists (one per series).
/// [styles] provides a [UvStyle] per series (cycled if shorter).
///
/// ```dart
/// drawGroupedHistogram(
///   screen, area,
///   [[42, 58, 35], [38, 45, 52], [55, 62, 48]], // 3 series, 3 groups
///   styles: [style1, style2, style3],
///   xLabels: ['Q1', 'Q2', 'Q3'],
/// );
/// ```
void drawGroupedHistogram(
  Screen screen,
  Rectangle area,
  List<List<double>> seriesList, {
  List<UvStyle> styles = const [UvStyle()],
  UvStyle axisStyle = const UvStyle(),
  UvStyle gridStyle = const UvStyle(),
  UvStyle labelStyle = const UvStyle(),
  bool showAxis = true,
  bool showGrid = false,
  int gridRows = 3,
  int gridCols = 0,
  List<String>? xLabels,
  List<String>? yLabels,
  String barChar = BlockShades.full,
  int barGap = 1,
  int groupGap = 1,
  int? barWidth,
  bool drawAxisLine = true,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || seriesList.isEmpty) return;

  final numSeries = seriesList.length;
  final numGroups = seriesList[0].length;
  if (numGroups == 0) return;
  for (final s in seriesList) {
    if (s.length != numGroups) return; // inconsistent series lengths
  }

  final usableHeight = showAxis ? height - 1 : height;
  if (usableHeight <= 0) return;

  // Find global max across all series.
  var globalMax = 0.0;
  for (final s in seriesList) {
    for (final v in s) {
      if (v > globalMax) globalMax = v;
    }
  }
  if (globalMax <= 0) globalMax = 1.0;

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

  final effectiveGroupGap = math.max(0, groupGap);
  final effectiveBarGap = math.max(0, barGap);

  // Compute group width and bar width.
  final totalGroupGaps = (numGroups - 1) * effectiveGroupGap;
  final totalBarWidthPerGroup =
      (width - totalGroupGaps) / numGroups; // available space per group
  final totalBarGapsPerGroup = (numSeries - 1) * effectiveBarGap;
  var resolvedBarWidth =
      barWidth ??
      ((totalBarWidthPerGroup - totalBarGapsPerGroup) / numSeries).floor();
  if (resolvedBarWidth < 1) resolvedBarWidth = 1;

  final chartHeight = usableHeight.toDouble();
  final labelY = area.maxY - 1;

  for (var g = 0; g < numGroups; g++) {
    final groupStartX =
        area.minX +
        g *
            ((resolvedBarWidth * numSeries + totalBarGapsPerGroup).floor() +
                effectiveGroupGap);

    for (var s = 0; s < numSeries; s++) {
      final value = seriesList[s][g];
      final hRaw = (value / globalMax) * chartHeight;
      final h = hRaw.isNaN ? 0.0 : hRaw;
      final fullRows = h.floor();
      final fracIdx = ((h - fullRows) * 8.0).round().clamp(0, 8);

      final barStartX = groupStartX + s * (resolvedBarWidth + effectiveBarGap);
      if (barStartX >= area.maxX) continue;
      final barEndX = math.min(barStartX + resolvedBarWidth, area.maxX);

      final style = styles[s % styles.length];

      final baseY = showAxis ? area.maxY - 2 : area.maxY - 1;

      for (var r = 0; r < fullRows; r++) {
        final cellY = baseY - r;
        if (cellY < area.minY) break;
        for (var bx = barStartX; bx < barEndX; bx++) {
          putSolidChartCell(screen, bx, cellY, style, barChar);
        }
      }

      if (fracIdx > 0) {
        final cellY = baseY - fullRows;
        if (cellY >= area.minY) {
          for (var bx = barStartX; bx < barEndX; bx++) {
            putSolidChartCell(screen, bx, cellY, style, _barChars[fracIdx]);
          }
        }
      }
    }
  }

  if (showAxis && drawAxisLine) {
    final axisY = labelY;
    for (var x = 0; x < width; x++) {
      putCell(screen, area.minX + x, axisY, '─', axisStyle);
    }
  }

  // X labels (centered under each group).
  if (xLabels != null && xLabels.isNotEmpty) {
    final groupWidth = resolvedBarWidth * numSeries + totalBarGapsPerGroup;
    for (var g = 0; g < xLabels.length && g < numGroups; g++) {
      final groupStartX = area.minX + g * (groupWidth + effectiveGroupGap);
      final label = xLabels[g];
      final renderWidth = math.min(label.length, groupWidth);
      if (renderWidth <= 0) continue;
      final clipped = label.substring(0, renderWidth);
      final groupCenter = groupStartX + groupWidth ~/ 2;
      var labelX = groupCenter - clipped.length ~/ 2;
      labelX = math.max(
        area.minX,
        math.min(labelX, area.maxX - clipped.length),
      );
      putText(screen, area, labelX, labelY, clipped, labelStyle);
    }
  }

  if (yLabels != null && yLabels.isNotEmpty) {
    drawAxisLabels(screen, area, yLabels: yLabels, style: labelStyle);
  }
}

// ---------------------------------------------------------------------------
// Multi-series stacked histogram
// ---------------------------------------------------------------------------

/// Draws a stacked multi-series vertical bar chart.
///
/// Each group has one bar with series values stacked on top of each other.
/// [styles] provides a [UvStyle] per series (cycled if shorter).
void drawStackedHistogram(
  Screen screen,
  Rectangle area,
  List<List<double>> seriesList, {
  List<UvStyle> styles = const [UvStyle()],
  UvStyle axisStyle = const UvStyle(),
  UvStyle gridStyle = const UvStyle(),
  UvStyle labelStyle = const UvStyle(),
  bool showAxis = true,
  bool showGrid = false,
  int gridRows = 3,
  int gridCols = 0,
  List<String>? xLabels,
  List<String>? yLabels,
  String barChar = BlockShades.full,
  int barGap = 1,
  int groupGap = 1,
  int? barWidth,
  bool drawAxisLine = true,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || seriesList.isEmpty) return;

  final numSeries = seriesList.length;
  final numGroups = seriesList[0].length;
  if (numGroups == 0) return;
  for (final s in seriesList) {
    if (s.length != numGroups) return;
  }

  final usableHeight = showAxis ? height - 1 : height;
  if (usableHeight <= 0) return;

  // Find global max of stacked totals.
  var globalMax = 0.0;
  for (var g = 0; g < numGroups; g++) {
    var total = 0.0;
    for (var s = 0; s < numSeries; s++) {
      total += seriesList[s][g];
    }
    if (total > globalMax) globalMax = total;
  }
  if (globalMax <= 0) globalMax = 1.0;

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

  final effectiveGap = math.max(0, groupGap);
  final totalGaps = (numGroups - 1) * effectiveGap;
  var resolvedBarWidth = barWidth ?? ((width - totalGaps) / numGroups).floor();
  if (resolvedBarWidth < 1) resolvedBarWidth = 1;

  final chartHeight = usableHeight.toDouble();
  final labelY = area.maxY - 1;

  for (var g = 0; g < numGroups; g++) {
    final barStartX = area.minX + g * (resolvedBarWidth + effectiveGap);
    if (barStartX >= area.maxX) break;
    final barEndX = math.min(barStartX + resolvedBarWidth, area.maxX);

    // Render series bottom-up using cumulative rounded rows to avoid gaps.
    var cumulativeValue = 0.0;
    for (var s = 0; s < numSeries; s++) {
      final value = seriesList[s][g];
      final style = styles[s % styles.length];

      final prevRows = ((cumulativeValue / globalMax) * chartHeight).round();
      cumulativeValue += value;
      final currRows = ((cumulativeValue / globalMax) * chartHeight).round();
      final segmentRows = currRows - prevRows;

      if (segmentRows <= 0) continue;

      final baseY = showAxis ? area.maxY - 2 : area.maxY - 1;

      for (var r = 0; r < segmentRows; r++) {
        final cellY = baseY - prevRows - r;
        if (cellY < area.minY) break;
        for (var bx = barStartX; bx < barEndX; bx++) {
          putSolidChartCell(screen, bx, cellY, style, barChar);
        }
      }
    }
  }

  if (showAxis && drawAxisLine) {
    final axisY = labelY;
    for (var x = 0; x < width; x++) {
      putCell(screen, area.minX + x, axisY, '─', axisStyle);
    }
  }

  if (xLabels != null && xLabels.isNotEmpty) {
    for (var g = 0; g < xLabels.length && g < numGroups; g++) {
      final barStartX = area.minX + g * (resolvedBarWidth + effectiveGap);
      final barCenter = barStartX + resolvedBarWidth ~/ 2;
      final label = xLabels[g];
      final renderWidth = math.min(label.length, resolvedBarWidth);
      if (renderWidth <= 0) continue;
      final clipped = label.substring(0, renderWidth);
      var labelX = barCenter - clipped.length ~/ 2;
      labelX = math.max(
        area.minX,
        math.min(labelX, area.maxX - clipped.length),
      );
      putText(screen, area, labelX, labelY, clipped, labelStyle);
    }
  }

  if (yLabels != null && yLabels.isNotEmpty) {
    drawAxisLabels(screen, area, yLabels: yLabels, style: labelStyle);
  }
}

// ---------------------------------------------------------------------------
// Horizontal variants
// ---------------------------------------------------------------------------

/// Draws a grouped multi-series horizontal bar chart.
void drawHorizontalGroupedHistogram(
  Screen screen,
  Rectangle area,
  List<List<double>> seriesList, {
  List<UvStyle> styles = const [UvStyle()],
  UvStyle axisStyle = const UvStyle(),
  UvStyle gridStyle = const UvStyle(),
  UvStyle labelStyle = const UvStyle(),
  bool showAxis = true,
  bool showGrid = false,
  int gridRows = 0,
  int gridCols = 3,
  List<String>? yLabels,
  String barChar = BlockShades.full,
  int barGap = 1,
  int groupGap = 1,
  int? barWidth,
  bool drawAxisLine = true,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || seriesList.isEmpty) return;

  final numSeries = seriesList.length;
  final numGroups = seriesList[0].length;
  if (numGroups == 0) return;
  for (final s in seriesList) {
    if (s.length != numGroups) return;
  }

  final longestLabel = yLabels == null || yLabels.isEmpty
      ? 0
      : yLabels.map((l) => l.length).fold<int>(0, math.max);
  final labelWidth = showAxis ? (math.min(longestLabel, width ~/ 3) + 1) : 0;
  final usableWidth = width - labelWidth;
  if (usableWidth <= 0) return;

  var globalMax = 0.0;
  for (final s in seriesList) {
    for (final v in s) {
      if (v > globalMax) globalMax = v;
    }
  }
  if (globalMax <= 0) globalMax = 1.0;

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

  final effectiveGroupGap = math.max(0, groupGap);
  final effectiveBarGap = math.max(0, barGap);

  final totalGroupGaps = (numGroups - 1) * effectiveGroupGap;
  final totalBarHeightPerGroup = (height - totalGroupGaps) / numGroups;
  final totalBarGapsPerGroup = (numSeries - 1) * effectiveBarGap;
  var barHeight =
      barWidth ??
      ((totalBarHeightPerGroup - totalBarGapsPerGroup) / numSeries).floor();
  if (barHeight < 1) barHeight = 1;

  for (var g = 0; g < numGroups; g++) {
    final groupStartY =
        area.minY +
        g *
            ((barHeight * numSeries + totalBarGapsPerGroup).floor() +
                effectiveGroupGap);

    for (var s = 0; s < numSeries; s++) {
      final value = seriesList[s][g];
      final barLenF = (value / globalMax) * usableWidth;
      final barLen = (barLenF.isNaN || value == 0.0)
          ? 0
          : math.max(1, barLenF.round());

      final barStartY = groupStartY + s * (barHeight + effectiveBarGap);
      if (barStartY >= area.maxY) continue;
      final barEndY = math.min(barStartY + barHeight, area.maxY);

      final style = styles[s % styles.length];

      for (var by = barStartY; by < barEndY; by++) {
        for (var c = 0; c < barLen; c++) {
          final cellX = area.minX + labelWidth + c;
          if (cellX >= area.maxX) break;
          putSolidChartCell(screen, cellX, by, style, barChar);
        }
      }
    }
  }

  if (yLabels != null && yLabels.isNotEmpty) {
    for (var g = 0; g < yLabels.length && g < numGroups; g++) {
      final groupHeight = barHeight * numSeries + totalBarGapsPerGroup;
      final groupStartY = area.minY + g * (groupHeight + effectiveGroupGap);
      final labelY = groupStartY;
      if (labelY >= area.minY && labelY < area.maxY) {
        putText(screen, area, area.minX, labelY, yLabels[g], labelStyle);
      }
    }
  }
}

/// Draws a stacked multi-series horizontal bar chart.
void drawHorizontalStackedHistogram(
  Screen screen,
  Rectangle area,
  List<List<double>> seriesList, {
  List<UvStyle> styles = const [UvStyle()],
  UvStyle axisStyle = const UvStyle(),
  UvStyle gridStyle = const UvStyle(),
  UvStyle labelStyle = const UvStyle(),
  bool showAxis = true,
  bool showGrid = false,
  int gridRows = 0,
  int gridCols = 3,
  List<String>? yLabels,
  String barChar = BlockShades.full,
  int barGap = 1,
  int groupGap = 1,
  int? barWidth,
  bool drawAxisLine = true,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || seriesList.isEmpty) return;

  final numSeries = seriesList.length;
  final numGroups = seriesList[0].length;
  if (numGroups == 0) return;
  for (final s in seriesList) {
    if (s.length != numGroups) return;
  }

  final longestLabel = yLabels == null || yLabels.isEmpty
      ? 0
      : yLabels.map((l) => l.length).fold<int>(0, math.max);
  final labelWidth = showAxis ? (math.min(longestLabel, width ~/ 3) + 1) : 0;
  final usableWidth = width - labelWidth;
  if (usableWidth <= 0) return;

  var globalMax = 0.0;
  for (var g = 0; g < numGroups; g++) {
    var total = 0.0;
    for (var s = 0; s < numSeries; s++) {
      total += seriesList[s][g];
    }
    if (total > globalMax) globalMax = total;
  }
  if (globalMax <= 0) globalMax = 1.0;

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

  final effectiveGap = math.max(0, groupGap);
  final totalGaps = (numGroups - 1) * effectiveGap;
  var barHeight = barWidth ?? ((height - totalGaps) / numGroups).floor();
  if (barHeight < 1) barHeight = 1;

  for (var g = 0; g < numGroups; g++) {
    final barStartY = area.minY + g * (barHeight + effectiveGap);
    if (barStartY >= area.maxY) break;
    final barEndY = math.min(barStartY + barHeight, area.maxY);

    var cumulativeValue = 0.0;
    for (var s = 0; s < numSeries; s++) {
      final value = seriesList[s][g];
      final style = styles[s % styles.length];

      final prevCols = ((cumulativeValue / globalMax) * usableWidth).round();
      cumulativeValue += value;
      final currCols = ((cumulativeValue / globalMax) * usableWidth).round();
      final segmentCols = currCols - prevCols;

      for (var by = barStartY; by < barEndY; by++) {
        for (var c = 0; c < segmentCols; c++) {
          final cellX = area.minX + labelWidth + prevCols + c;
          if (cellX >= area.maxX) break;
          putSolidChartCell(screen, cellX, by, style, barChar);
        }
      }
    }
  }

  if (yLabels != null && yLabels.isNotEmpty) {
    for (var g = 0; g < yLabels.length && g < numGroups; g++) {
      final barStartY = area.minY + g * (barHeight + effectiveGap);
      if (barStartY >= area.minY && barStartY < area.maxY) {
        putText(screen, area, area.minX, barStartY, yLabels[g], labelStyle);
      }
    }
  }
}
