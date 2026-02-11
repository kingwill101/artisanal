/// Histogram (vertical bar) chart renderer for UV screens.
library;

import 'dart:math' as math;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Bottom-half block character for sub-cell precision.
const _bottomHalf = '▄';

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
  String barChar = '█',
  int barGap = 1,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || values.isEmpty) return;

  // Reserve bottom row for axis when enabled.
  final usableHeight = showAxis ? height - 1 : height;
  if (usableHeight <= 0) return;

  final n = values.length;
  // Compute bar width so that n bars + (n-1) gaps fit in width.
  final effectiveGap = math.max(0, barGap);
  final totalGaps = (n - 1) * effectiveGap;
  var barWidth = n > 0 ? ((width - totalGaps) / n).floor() : 0;
  if (barWidth < 1) barWidth = 1;

  final maxValue = values.reduce((a, b) => a > b ? a : b);
  final minValue = values.reduce((a, b) => a < b ? a : b);

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

  // Draw each bar.
  for (var i = 0; i < n; i++) {
    final normalized = normalize(values[i], minValue, maxValue);
    // Sub-cell height: usableHeight * 2 half-rows.
    final subHeight = (normalized * usableHeight * 2).round();
    final fullRows = subHeight ~/ 2;
    final hasHalf = subHeight.isOdd;

    final barStartX = area.minX + i * (barWidth + effectiveGap);
    if (barStartX >= area.maxX) break;
    final barEndX = math.min(barStartX + barWidth, area.maxX);

    // Full block rows from the bottom up.
    for (var r = 0; r < fullRows; r++) {
      final cellY = area.maxY - 1 - r - (showAxis ? 1 : 0);
      if (cellY < area.minY) break;
      for (var bx = barStartX; bx < barEndX; bx++) {
        putCell(screen, bx, cellY, barChar, barStyle);
      }
    }

    // Half-block at the top of the bar for sub-cell precision.
    if (hasHalf) {
      final cellY = area.maxY - 1 - fullRows - (showAxis ? 1 : 0);
      if (cellY >= area.minY) {
        // Use the lower-half block: the bar "grows" from the bottom of
        // this cell.  Set foreground to the bar color.
        for (var bx = barStartX; bx < barEndX; bx++) {
          putCell(screen, bx, cellY, _bottomHalf, barStyle);
        }
      }
    }
  }

  // Axis line.
  if (showAxis) {
    final axisY = area.maxY - 1;
    for (var x = 0; x < width; x++) {
      putCell(screen, area.minX + x, axisY, '─', axisStyle);
    }
  }

  // Labels — use per-bar centering for X labels.
  // When label count matches bar count, each label goes under its bar.
  // When label count differs, labels are distributed evenly across the
  // full bar range so they don't bunch up on the left side.
  if (xLabels != null && xLabels.isNotEmpty) {
    final axisY = area.maxY - 1;
    final labelCount = xLabels.length;

    if (labelCount == n) {
      // 1:1 mapping — label[i] under bar[i].
      for (var i = 0; i < labelCount; i++) {
        final label = xLabels[i];
        final barStartX = area.minX + i * (barWidth + effectiveGap);
        final barCenter = barStartX + barWidth ~/ 2;
        var labelX = barCenter - label.length ~/ 2;
        labelX = math.max(
          area.minX,
          math.min(labelX, area.maxX - label.length),
        );
        putText(screen, area, labelX, axisY, label, labelStyle);
      }
    } else {
      // Distribute labels evenly across the full bar span.
      // First bar center and last bar center define the span.
      final firstBarCenter = area.minX + barWidth ~/ 2;
      final lastBarCenter =
          area.minX + (n - 1) * (barWidth + effectiveGap) + barWidth ~/ 2;
      for (var i = 0; i < labelCount; i++) {
        final label = xLabels[i];
        final center = labelCount <= 1
            ? (firstBarCenter + lastBarCenter) ~/ 2
            : firstBarCenter +
                  ((lastBarCenter - firstBarCenter) * i / (labelCount - 1))
                      .round();
        var labelX = center - label.length ~/ 2;
        labelX = math.max(
          area.minX,
          math.min(labelX, area.maxX - label.length),
        );
        putText(screen, area, labelX, axisY, label, labelStyle);
      }
    }
  }

  if (yLabels != null && yLabels.isNotEmpty) {
    drawAxisLabels(screen, area, yLabels: yLabels, style: labelStyle);
  }
}
