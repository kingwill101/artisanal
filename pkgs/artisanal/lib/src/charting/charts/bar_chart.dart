/// Vertical and horizontal bar charts with axis scaling.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a bar chart onto [screen] within [area].
void renderBarChart(
  Screen screen,
  Rectangle area,
  BarChartProps props,
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
  final barChar = props.barChar ?? Block.full;
  final orientation = props.orientation ?? ChartOrientation.vertical;
  final grouped = props.grouped != false;

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

  var allMax = double.negativeInfinity;
  var allMin = 0.0;
  for (final s in props.series) {
    for (final v in s.data) {
      if (v > allMax) allMax = v;
      if (v < allMin) allMin = v;
    }
  }
  allMin = props.yAxis?.min ?? allMin;
  allMax = props.yAxis?.max ?? allMax;

  final scale = computeNiceScale(
    math.min(0, allMin),
    allMax,
    props.yAxis?.tickCount ?? math.min(plotH - 1, 12),
    plotH,
  );

  final dataLen = props.series.map((s) => s.data.length).fold(0, math.max);
  final labels = props.labels ??
      List.generate(dataLen, (i) => '${i + 1}');

  if (orientation == ChartOrientation.vertical) {
    drawAxes(
      screen,
      area,
      plotX,
      plotY,
      plotW,
      plotH,
      scale,
      labels,
      bg,
      axisColor,
      props.xAxis,
      props.yAxis,
      props.grid,
    );

    final ePH = scale.effectivePlotH ?? plotH;
    final ePYoff = scale.plotYOffset ?? 0;
    final ePY = plotY + ePYoff;
    final numSeries = props.series.length;
    final totalGroups = dataLen;
    final groupWidth = (plotW - 2) ~/ math.max(1, totalGroups);
    final gap = props.gap ?? 1;
    final barWidth = props.barWidth ??
        (grouped
            ? math.max(1, (groupWidth - gap) ~/ math.max(1, numSeries))
            : math.max(1, groupWidth - gap));

    for (var gi = 0; gi < totalGroups; gi++) {
      final groupStartX = plotX + 1 + gi * groupWidth;
      for (var si = 0; si < numSeries; si++) {
        final series = props.series[si];
        final val = gi < series.data.length ? series.data[gi] : 0.0;
        final seriesColor = fg(series.color ?? colors[si % colors.length]);
        final yNorm = (val - scale.min) / (scale.max - scale.min);
        final barH = (yNorm * (ePH - 2)).round();
        final baseY = ePY + ePH - 2;
        final bx = grouped
            ? groupStartX + si * barWidth + gap ~/ 2
            : groupStartX + gap ~/ 2;

        for (var row = 0; row < barH; row++) {
          for (var col = 0; col < barWidth; col++) {
            final px = bx + col;
            final py = baseY - row;
            if (px >= plotX + 1 &&
                px < plotX + plotW - 1 &&
                py >= plotY &&
                py < plotY + plotH) {
              if (barChar == Block.full) {
                putSolidChartCell(screen, px, py, seriesColor, Block.full);
              } else {
                putCell(screen, px, py, barChar, mergeStyle(seriesColor, bg));
              }
            }
          }
        }
      }
    }
  } else {
    final numSeries = props.series.length;
    final totalGroups = dataLen;
    final groupHeight = (plotH - 2) ~/ math.max(1, totalGroups);
    final gap = props.gap ?? 1;
    final barHeight = grouped
        ? math.max(1, (groupHeight - gap) ~/ math.max(1, numSeries))
        : math.max(1, groupHeight - gap);

    for (var gi = 0; gi < totalGroups; gi++) {
      final y = plotY + 1 + gi * groupHeight + groupHeight ~/ 2;
      final label = gi < labels.length
          ? (labels[gi].length > margins.left - 1
              ? labels[gi].substring(0, margins.left - 1)
              : labels[gi])
          : '';
      putText(
        screen,
        area,
        0,
        y,
        label.padLeft(math.max(0, margins.left - 1)),
        mergeStyle(axisColor, bg),
      );
    }

    for (var gi = 0; gi < totalGroups; gi++) {
      final groupStartY = plotY + 1 + gi * groupHeight;
      for (var si = 0; si < numSeries; si++) {
        final series = props.series[si];
        final val = gi < series.data.length ? series.data[gi] : 0.0;
        final seriesColor = fg(series.color ?? colors[si % colors.length]);
        final xNorm = (val - scale.min) / (scale.max - scale.min);
        final barW = (xNorm * (plotW - 2)).round();
        final by = grouped
            ? groupStartY + si * barHeight + gap ~/ 2
            : groupStartY + gap ~/ 2;

        for (var row = 0; row < barHeight; row++) {
          for (var col = 0; col < barW; col++) {
            final px = plotX + 1 + col;
            final py = by + row;
            if (px < plotX + plotW && py < plotY + plotH) {
              if (barChar == Block.full) {
                putSolidChartCell(screen, px, py, seriesColor, Block.full);
              } else {
                putCell(screen, px, py, barChar, mergeStyle(seriesColor, bg));
              }
            }
          }
        }

        final valStr = formatNumber(val);
        putText(
          screen,
          area,
          plotX + 1 + (xNorm * (plotW - 2)).round() + 1,
          by,
          valStr,
          mergeStyle(axisColor, bg),
        );
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

/// Creates a bar chart and returns it rendered as a multi-line string.
String createBarChart(BarChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderBarChart(screen, area, props),
  );
}
