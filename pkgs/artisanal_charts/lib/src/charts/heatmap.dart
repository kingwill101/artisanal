/// 2D heatmap charts.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../frame_buffer.dart';
import '../surface.dart';
import '../types.dart';
import '../utils.dart';

/// Renders a heatmap onto [fb].
void renderHeatmapChart(
  ChartFrameBuffer fb,
  int width,
  int height,
  HeatmapChartProps props,
) {
  final bg = color(props.backgroundColor ?? '#1A1A2E');
  final axisColor = color(props.yAxis?.color ?? '#555555');
  final margins = resolveMargins(props.margins);
  final showValues = props.showValues ?? false;
  final colorScale = props.colorScale ??
      const ['#1A237E', '#1565C0', '#4FC3F7', '#FFD54F', '#FF6F00', '#D50000'];

  fb.fillRect(0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    fb.drawText(props.title!, margins.left, 0, color(props.titleColor ?? '#FFFFFF'), bg);
    titleOffset = 1;
  }

  final data = props.data;
  if (data.isEmpty) return;

  final rows = data.length;
  final cols = data.map((r) => r.length).fold(0, math.max);

  var vMin = double.infinity;
  var vMax = double.negativeInfinity;
  for (final row in data) {
    for (final v in row) {
      if (v < vMin) vMin = v;
      if (v > vMax) vMax = v;
    }
  }

  final plotX = margins.left;
  final plotY = margins.top + titleOffset;
  final plotW = width - margins.left - margins.right;
  final plotH = height - margins.top - margins.bottom - titleOffset;

  if (plotW < 3 || plotH < 3) return;

  final cellW = math.max(1, plotW ~/ math.max(1, cols));
  final cellH = math.max(1, plotH ~/ math.max(1, rows));

  UvStyle getHeatColor(double value) {
    final norm = vMax == vMin ? 0.5 : (value - vMin) / (vMax - vMin);
    final scaleLen = colorScale.length - 1;
    final idx = norm * scaleLen;
    final lower = idx.floor();
    final upper = math.min(lower + 1, scaleLen);
    final t = idx - lower;
    return lerpColor(colorScale[lower], colorScale[upper], t);
  }

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final val = (r < data.length && c < data[r].length) ? data[r][c] : 0.0;
      final cellColor = getHeatColor(val);
      final cx = plotX + c * cellW;
      final cy = plotY + r * cellH;

      // Solid background cells so the color ramp is visible (█ + fg alone
      // often collapses to a uniform block in terminal paste/output).
      for (var dy = 0; dy < cellH && cy + dy < plotY + plotH; dy++) {
        for (var dx = 0; dx < cellW && cx + dx < plotX + plotW; dx++) {
          fb.setSolid(cx + dx, cy + dy, cellColor);
        }
      }

      if (showValues && cellW >= 3 && cellH >= 1) {
        var valStr = formatNumber(val);
        if (valStr.length > cellW) valStr = valStr.substring(0, cellW);
        final textX = cx + (cellW - valStr.length) ~/ 2;
        final textY = cy + cellH ~/ 2;
        if (textX >= 0 && textY >= 0 && textX + valStr.length <= width) {
          fb.drawText(valStr, textX, textY, color('#FFFFFF'), cellColor);
        }
      }
    }
  }

  if (props.yLabels != null) {
    for (var r = 0; r < rows && r < props.yLabels!.length; r++) {
      final y = plotY + r * cellH + cellH ~/ 2;
      final raw = props.yLabels![r];
      final label = raw.length > margins.left - 1
          ? raw.substring(0, margins.left - 1)
          : raw;
      fb.drawText(
        label.padLeft(math.max(0, margins.left - 1)),
        0,
        y,
        axisColor,
        bg,
      );
    }
  }

  if (props.xLabels != null) {
    final labelY = plotY + plotH;
    for (var c = 0; c < cols && c < props.xLabels!.length; c++) {
      final x = plotX + c * cellW;
      final raw = props.xLabels![c];
      final label = raw.length > cellW ? raw.substring(0, cellW) : raw;
      if (labelY < height) {
        fb.drawText(label, x, labelY, axisColor, bg);
      }
    }
  }
}

/// Creates a heatmap surface.
ChartSurface createHeatmapChart(HeatmapChartProps props) {
  return createChartSurface(
    width: props.width,
    height: props.height,
    paint: (fb, w, h) => renderHeatmapChart(fb, w, h, props),
  );
}

/// Updates an existing heatmap surface.
void updateHeatmapChart(ChartSurface surface, HeatmapChartProps props) {
  updateChartSurface(
    surface,
    paint: (fb, w, h) => renderHeatmapChart(fb, w, h, props),
  );
}
