/// Heatmap grid charts.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a heatmap chart onto [screen] within [area].
void renderHeatmapChart(
  Screen screen,
  Rectangle area,
  HeatmapChartProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || props.data.isEmpty) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final margins = resolveMargins(props.margins);

  fillRect(screen, area, 0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    putText(
      screen,
      area,
      margins.left,
      0,
      props.title!,
      mergeStyle(fg(props.titleColor ?? '#FFFFFF'), bg),
    );
    titleOffset = 1;
  }

  final plotX = margins.left;
  final plotY = margins.top + titleOffset;
  final plotW = width - margins.left - margins.right;
  final plotH = height - margins.top - margins.bottom - titleOffset;

  final rows = props.data.length;
  final cols = props.data[0].length;

  var minV = double.infinity;
  var maxV = double.negativeInfinity;
  for (final row in props.data) {
    for (final v in row) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
  }
  if (minV == maxV) maxV = minV + 1;

  final cellW = math.max(1, plotW ~/ cols);
  final cellH = math.max(1, plotH ~/ rows);
  final colorScale = props.colorScale ?? defaultColors;

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final v = props.data[r][c];
      final t = (v - minV) / (maxV - minV);
      final idx = (t * (colorScale.length - 1)).round().clamp(0, colorScale.length - 1);
      final cellColor = fg(colorScale[idx]);
      final x = plotX + c * cellW;
      final y = plotY + r * cellH;
      for (var rr = 0; rr < cellH; rr++) {
        for (var cc = 0; cc < cellW; cc++) {
          final px = x + cc;
          final py = y + rr;
          if (px >= plotX &&
              px < plotX + plotW &&
              py >= plotY &&
              py < plotY + plotH) {
            putSolidChartCell(screen, px, py, cellColor, Block.full);
          }
        }
      }
      if (props.showValues ?? false) {
        final valStr = formatNumber(v);
        if (valStr.length <= cellW) {
          putText(
            screen,
            area,
            x + (cellW - valStr.length) ~/ 2,
            y + (cellH - 1) ~/ 2,
            valStr,
            mergeStyle(fg('#000000'), bg),
          );
        }
      }
    }
  }

  if (props.xLabels != null) {
    for (var c = 0; c < math.min(props.xLabels!.length, cols); c++) {
      final x = plotX + c * cellW + cellW ~/ 2;
      final label = props.xLabels![c];
      putText(
        screen,
        area,
        x - label.length ~/ 2,
        plotY + rows * cellH,
        label,
        mergeStyle(fg('#888888'), bg),
      );
    }
  }

  if (props.yLabels != null) {
    for (var r = 0; r < math.min(props.yLabels!.length, rows); r++) {
      final y = plotY + r * cellH + cellH ~/ 2;
      putText(
        screen,
        area,
        math.max(0, plotX - props.yLabels![r].length - 1),
        y,
        props.yLabels![r],
        mergeStyle(fg('#888888'), bg),
      );
    }
  }
}

/// Creates a heatmap chart and returns it rendered as a multi-line string.
String createHeatmapChart(HeatmapChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderHeatmapChart(screen, area, props),
  );
}
