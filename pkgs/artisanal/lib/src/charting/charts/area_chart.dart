/// Filled area charts with optional stacking.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders an area chart onto [screen] within [area].
void renderAreaChart(
  Screen screen,
  Rectangle area,
  AreaChartProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || props.series.isEmpty) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final axisColor = fg(props.yAxis?.color ?? '#555555');
  final colors = props.colors ?? defaultColors;
  final margins = resolveMargins(props.margins);
  final stacked = props.stacked ?? false;
  final fillChar = props.fillChar ?? Block.shadeMedium;
  final showDots = props.showDots ?? false;

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

  final processedSeries =
      props.series.map((s) => List<double>.from(s.data)).toList();
  if (stacked && processedSeries.length > 1) {
    for (var si = 1; si < processedSeries.length; si++) {
      for (var i = 0; i < processedSeries[si].length; i++) {
        final prev = i < processedSeries[si - 1].length
            ? processedSeries[si - 1][i]
            : 0.0;
        processedSeries[si][i] += prev;
      }
    }
  }

  var allMin = 0.0;
  var allMax = double.negativeInfinity;
  for (final s in processedSeries) {
    for (final v in s) {
      if (v > allMax) allMax = v;
    }
  }
  allMin = props.yAxis?.min ?? allMin;
  allMax = props.yAxis?.max ?? allMax;
  if (allMax == double.negativeInfinity) allMax = 1;

  final scale = computeNiceScale(
    allMin,
    allMax,
    props.yAxis?.tickCount ?? math.min(plotH - 1, 10),
    plotH,
  );
  final maxLen = props.series.map((s) => s.data.length).fold(0, math.max);
  final xLabels = List.generate(maxLen, (i) => '${i + 1}');

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
  final ePY = plotY + (scale.plotYOffset ?? 0);
  final baseY = ePY + ePH - 2;
  final innerW = math.max(1, plotW - 2);
  final innerH = math.max(1, ePH - 1);

  final drawOrder = stacked
      ? List.generate(processedSeries.length, (i) => i).reversed.toList()
      : List.generate(processedSeries.length, (i) => i);

  for (final si in drawOrder) {
    final data = processedSeries[si];
    if (data.isEmpty) continue;
    final seriesHex = props.series[si].color ?? colors[si % colors.length];
    final seriesColor = fg(seriesHex);
    final fillColor = dimFg(seriesHex, 0.55);

    final points = <(int, int)>[];
    for (var i = 0; i < data.length; i++) {
      final t = data.length == 1 ? 0.5 : i / (data.length - 1);
      final x = (plotX + 1 + t * (plotW - 2)).round();
      final yNorm = (data[i] - scale.min) / (scale.max - scale.min);
      final y = (ePY + ePH - 2 - yNorm * (ePH - 3)).round();
      points.add((x, y));
    }

    List<int>? baseline;
    if (stacked && si > 0) {
      final prevData = processedSeries[si - 1];
      baseline = [];
      for (var i = 0; i < prevData.length; i++) {
        final yNorm = (prevData[i] - scale.min) / (scale.max - scale.min);
        baseline.add((ePY + ePH - 2 - yNorm * (ePH - 3)).round());
      }
    }

    fillAreaUnderPolyline(
      screen,
      area,
      points,
      baseY,
      plotX,
      plotY,
      plotW,
      plotH,
      fillColor,
      bg,
      fillChar: fillChar,
      baselineYs: baseline,
    );

    final qc = QuadrantCanvas(innerW, innerH);
    final termPts = <(double, double)>[];
    for (var i = 0; i < data.length; i++) {
      final tVal = data.length == 1 ? 0.5 : i / (data.length - 1);
      final xf = tVal * (innerW - 1);
      final yNormF = (data[i] - scale.min) / (scale.max - scale.min);
      final yf = (1 - yNormF) * (innerH - 1);
      termPts.add((xf, yf));
    }
    for (var i = 0; i < termPts.length - 1; i++) {
      final (ax, ay) = termPts[i];
      final (bx, by) = termPts[i + 1];
      qc.drawLine(
        (ax * 2).round(),
        (ay * 2).round(),
        (bx * 2).round(),
        (by * 2).round(),
        seriesHex,
      );
    }
    qc.render(screen, area, plotX + 1, ePY, bg);

    if (showDots) {
      for (final (px, py) in points) {
        putCell(screen, px, py, LineChars.dot, mergeStyle(seriesColor, bg));
      }
    }
  }

  if (props.legend?.show != false && props.series.length > 1) {
    final items = [
      for (var i = 0; i < props.series.length; i++)
        (
          name: props.series[i].name,
          color: props.series[i].color ?? colors[i % colors.length],
        ),
    ];
    drawLegend(screen, area, items, margins.left, height - 1, plotW, bg);
  }
}

/// Creates an area chart and returns it rendered as a multi-line string.
String createAreaChart(AreaChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderAreaChart(screen, area, props),
  );
}
