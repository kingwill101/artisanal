/// Scatter plot charts.
library;

import 'dart:math' as math;

import '../frame_buffer.dart';
import '../surface.dart';
import '../types.dart';
import '../utils.dart';

/// Renders a scatter chart onto [fb].
void renderScatterChart(
  ChartFrameBuffer fb,
  int width,
  int height,
  ScatterChartProps props,
) {
  final bg = color(props.backgroundColor ?? '#1A1A2E');
  final axisColor = color(props.yAxis?.color ?? '#555555');
  final defaultPointColor = color(props.defaultColor ?? defaultColors[0]);
  final margins = resolveMargins(props.margins);
  final dotChar = props.dotChar ?? LineChars.dot;

  fb.fillRect(0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    fb.drawText(props.title!, margins.left, 0, color(props.titleColor ?? '#FFFFFF'), bg);
    titleOffset = 1;
  }

  final plotX = margins.left;
  final plotY = margins.top + titleOffset;
  final plotW = width - margins.left - margins.right;
  final plotH = height - margins.top - margins.bottom - titleOffset;

  if (plotW < 3 || plotH < 3 || props.points.isEmpty) return;

  var xMin = double.infinity;
  var xMax = double.negativeInfinity;
  var yMin = double.infinity;
  var yMax = double.negativeInfinity;
  for (final p in props.points) {
    if (p.x < xMin) xMin = p.x;
    if (p.x > xMax) xMax = p.x;
    if (p.y < yMin) yMin = p.y;
    if (p.y > yMax) yMax = p.y;
  }

  xMin = props.xAxis?.min ?? xMin;
  xMax = props.xAxis?.max ?? xMax;
  yMin = props.yAxis?.min ?? yMin;
  yMax = props.yAxis?.max ?? yMax;

  final yScale = computeNiceScale(
    yMin,
    yMax,
    props.yAxis?.tickCount ?? math.min(plotH - 1, 10),
    plotH,
  );
  final xScale = computeNiceScale(
    xMin,
    xMax,
    props.xAxis?.tickCount ?? math.min(plotW ~/ 8, 10),
  );

  final xLabels = xScale.ticks
      .map((v) => props.xAxis?.formatTick?.call(v) ?? v.round().toString())
      .toList();
  drawAxes(
    fb,
    plotX,
    plotY,
    plotW,
    plotH,
    yScale,
    xLabels,
    bg,
    axisColor,
    props.xAxis,
    props.yAxis,
    props.grid,
  );

  final ePH = yScale.effectivePlotH ?? plotH;
  final ePY = plotY + (yScale.plotYOffset ?? 0);

  for (final point in props.points) {
    final xNorm = (point.x - xScale.min) / (xScale.max - xScale.min);
    final yNorm = (point.y - yScale.min) / (yScale.max - yScale.min);
    final px = (plotX + 1 + xNorm * (plotW - 3)).round();
    final py = (ePY + ePH - 2 - yNorm * (ePH - 3)).round();

    if (px > plotX &&
        px < plotX + plotW - 1 &&
        py >= plotY &&
        py < plotY + plotH - 1) {
      final pointColor =
          point.color != null ? color(point.color!) : defaultPointColor;
      fb.setCell(px, py, dotChar, pointColor, bg);
    }
  }
}

/// Creates a scatter chart surface.
ChartSurface createScatterChart(ScatterChartProps props) {
  return createChartSurface(
    width: props.width,
    height: props.height,
    paint: (fb, w, h) => renderScatterChart(fb, w, h, props),
  );
}

/// Updates an existing scatter chart surface.
void updateScatterChart(ChartSurface surface, ScatterChartProps props) {
  updateChartSurface(
    surface,
    paint: (fb, w, h) => renderScatterChart(fb, w, h, props),
  );
}
