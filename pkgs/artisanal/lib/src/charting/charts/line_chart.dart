/// Multi-series line charts with quadrant sub-pixel rendering.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a line chart onto [screen] within [area].
void renderLineChart(
  Screen screen,
  Rectangle area,
  LineChartProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final axisColor = fg(
    props.yAxis?.color ?? props.xAxis?.color ?? '#555555',
  );
  final colors = props.colors ?? defaultColors;
  final margins = resolveMargins(props.margins);
  final showDots = props.showDots != false;
  final dotChar = props.dotChar ?? LineChars.dot;
  final lineStyle = props.lineStyle ?? LineStyle.straight;

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

  if (plotW < 3 || plotH < 3 || props.series.isEmpty) return;

  var seriesList = props.series;
  if (props.maxPoints != null && props.maxPoints! > 0) {
    seriesList = [
      for (final s in props.series)
        DataSeries(
          name: s.name,
          color: s.color,
          data: s.data.length > props.maxPoints!
              ? s.data.sublist(s.data.length - props.maxPoints!)
              : s.data,
        ),
    ];
  }

  var allMin = double.infinity;
  var allMax = double.negativeInfinity;
  for (final s in seriesList) {
    for (final v in s.data) {
      if (v < allMin) allMin = v;
      if (v > allMax) allMax = v;
    }
  }
  allMin = props.yAxis?.min ?? allMin;
  allMax = props.yAxis?.max ?? allMax;
  if (allMin == double.infinity) {
    allMin = 0;
    allMax = 1;
  }

  final scale = computeNiceScale(
    allMin,
    allMax,
    props.yAxis?.tickCount ?? math.min(plotH - 1, 12),
    plotH,
  );

  final maxLen = seriesList.map((s) => s.data.length).fold(0, math.max);
  final xLabels = props.xAxis?.show != false
      ? List.generate(maxLen, (i) => '${i + 1}')
      : null;

  drawAxes(
    screen,
    area,
    plotX,
    plotY,
    plotW,
    plotH,
    scale,
    xLabels,
    bg,
    axisColor,
    props.xAxis,
    props.yAxis,
    props.grid,
  );

  final ePH = scale.effectivePlotH ?? plotH;
  final ePYoff = scale.plotYOffset ?? 0;
  final ePY = plotY + ePYoff;
  final innerW = plotW - 1;
  final innerH = ePH;

  for (var si = 0; si < seriesList.length; si++) {
    final series = seriesList[si];
    final seriesColor = fg(series.color ?? colors[si % colors.length]);
    final seriesHex = series.color ?? colors[si % colors.length];
    final data = series.data;
    if (data.isEmpty) continue;

    final termPoints = <(double, double)>[];
    for (var i = 0; i < data.length; i++) {
      final t = data.length == 1 ? 0.5 : i / (data.length - 1);
      final x = t * (innerW - 1);
      final yNorm = (data[i] - scale.min) / (scale.max - scale.min);
      final y = (1 - yNorm) * (ePH - 1);
      termPoints.add((x, y));
    }

    if (props.fillArea == true) {
      final baseY = ePY + ePH - 2;
      final dimFill = dimFg(seriesHex, 0.35);
      final cellPoints = [
        for (final (tx, ty) in termPoints)
          (plotX + 1 + tx.round(), ePY + ty.round()),
      ];
      fillAreaUnderPolyline(
        screen,
        area,
        cellPoints,
        baseY,
        plotX,
        plotY,
        plotW,
        plotH,
        dimFill,
        bg,
        fillChar: Block.shadeLight,
      );
    }

    if (lineStyle == LineStyle.step) {
      for (var i = 0; i < termPoints.length - 1; i++) {
        final (tx0, ty0) = termPoints[i];
        final (tx1, ty1) = termPoints[i + 1];
        final px0 = plotX + 1 + tx0.round();
        final py0 = ePY + ty0.round();
        final px1 = plotX + 1 + tx1.round();
        final py1 = ePY + ty1.round();
        drawLine(screen, area, px0, py0, px1, py0, seriesColor, bg, '─');
        drawLine(screen, area, px1, py0, px1, py1, seriesColor, bg, '│');
      }
      if (showDots) {
        for (final (tx, ty) in termPoints) {
          putCell(
            screen,
            plotX + 1 + tx.round(),
            ePY + ty.round(),
            dotChar,
            mergeStyle(seriesColor, bg),
          );
        }
      }
    } else {
      final qc = QuadrantCanvas(innerW, innerH);
      final subPoints = <(int, int)>[];
      for (final (tx, ty) in termPoints) {
        subPoints.add(((tx * 2).round(), (ty * 2).round()));
      }
      for (var i = 0; i < subPoints.length - 1; i++) {
        final (sx0, sy0) = subPoints[i];
        final (sx1, sy1) = subPoints[i + 1];
        qc.drawLine(sx0, sy0, sx1, sy1, seriesHex);
      }
      if (showDots) {
        for (final (sx, sy) in subPoints) {
          qc.set(sx, sy, seriesHex);
        }
      }
      qc.render(screen, area, plotX + 1, ePY, bg);
    }
  }

  if (props.legend?.show != false && seriesList.length > 1) {
    final items = [
      for (var i = 0; i < seriesList.length; i++)
        (
          name: seriesList[i].name,
          color: seriesList[i].color ?? colors[i % colors.length],
        ),
    ];
    drawLegend(screen, area, items, margins.left, height - 1, plotW, bg);
  }
}

/// Creates a line chart and returns it rendered as a multi-line string.
String createLineChart(LineChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderLineChart(screen, area, props),
  );
}
