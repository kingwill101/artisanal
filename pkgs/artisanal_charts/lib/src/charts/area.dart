/// Filled area charts with optional stacking.
library;

import 'dart:math' as math;

import '../frame_buffer.dart';
import '../surface.dart';
import '../types.dart';
import '../utils.dart';

/// Renders an area chart onto [fb].
void renderAreaChart(
  ChartFrameBuffer fb,
  int width,
  int height,
  AreaChartProps props,
) {
  final bg = color(props.backgroundColor ?? '#1A1A2E');
  final axisColor = color(props.yAxis?.color ?? '#555555');
  final colors = props.colors ?? defaultColors;
  final margins = resolveMargins(props.margins);
  final stacked = props.stacked ?? false;
  final fillChar = props.fillChar ?? Block.shadeMedium;
  final showDots = props.showDots ?? false;

  fb.fillRect(0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    fb.drawText(
      props.title!,
      margins.left,
      0,
      color(props.titleColor ?? '#FFFFFF'),
      bg,
    );
    titleOffset = 1;
  }

  final plotX = margins.left;
  final plotY = margins.top + titleOffset;
  final plotW = width - margins.left - margins.right;
  final plotH = height - margins.top - margins.bottom - titleOffset;

  if (plotW < 3 || plotH < 3) return;

  final maxLen = props.series.map((s) => s.data.length).fold(0, math.max);
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
  final xLabels = List.generate(maxLen, (i) => '${i + 1}');

  drawAxes(
    fb,
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

  // Back-to-front when stacked so lower bands paint under upper ones correctly.
  final drawOrder = stacked
      ? List.generate(processedSeries.length, (i) => i).reversed.toList()
      : List.generate(processedSeries.length, (i) => i);

  for (final si in drawOrder) {
    final data = processedSeries[si];
    final seriesHex = props.series[si].color ?? colors[si % colors.length];
    final seriesColor = color(seriesHex);
    final fillColor = dimColor(seriesHex, 0.55);
    if (data.isEmpty) continue;

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

    // Continuous shade fill (not solid blocks).
    fillAreaUnderPolyline(
      fb,
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

    // Thin top stroke via quadrant canvas.
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
    qc.render(fb, plotX + 1, ePY, bg);

    if (showDots) {
      for (final (px, py) in points) {
        fb.setCell(px, py, LineChars.dot, seriesColor, bg);
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
    drawLegend(fb, items, margins.left, height - 1, plotW, bg);
  }
}

/// Creates an area chart surface.
ChartSurface createAreaChart(AreaChartProps props) {
  return createChartSurface(
    width: props.width,
    height: props.height,
    paint: (fb, w, h) => renderAreaChart(fb, w, h, props),
  );
}

/// Updates an existing area chart surface.
void updateAreaChart(ChartSurface surface, AreaChartProps props) {
  updateChartSurface(
    surface,
    paint: (fb, w, h) => renderAreaChart(fb, w, h, props),
  );
}
