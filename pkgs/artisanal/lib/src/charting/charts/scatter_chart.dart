/// Scatter plot charts.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a scatter chart onto [screen] within [area].
void renderScatterChart(
  Screen screen,
  Rectangle area,
  ScatterChartProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || props.points.isEmpty) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final axisColor = fg(props.yAxis?.color ?? '#555555');
  final defaultPointColor = fg(props.defaultColor ?? defaultColors[0]);
  final margins = resolveMargins(props.margins);
  final dotChar = props.dotChar ?? LineChars.dot;

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

  if (plotW < 3 || plotH < 3) return;

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
    screen,
    area,
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
  final ePYoff = yScale.plotYOffset ?? 0;
  final ePY = plotY + ePYoff;

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
          point.color != null ? fg(point.color!) : defaultPointColor;
      putCell(screen, px, py, dotChar, mergeStyle(pointColor, bg));
    }
  }
}

/// Creates a scatter chart and returns it rendered as a multi-line string.
String createScatterChart(ScatterChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderScatterChart(screen, area, props),
  );
}
