/// Stacked bar charts with cumulative series.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a stacked bar chart onto [screen] within [area].
void renderStackedBarChart(
  Screen screen,
  Rectangle area,
  StackedBarChartProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || props.series.isEmpty) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final axisColor = fg(props.yAxis?.color ?? props.xAxis?.color ?? '#555555');
  final colors = props.colors ?? defaultColors;
  final margins = resolveMargins(props.margins);
  final barChar = props.barChar ?? Block.full;
  final orientation = props.orientation ?? ChartOrientation.vertical;

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

  final dataLen = props.series.map((s) => s.data.length).fold(0, math.max);
  final totals = List<double>.filled(dataLen, 0);
  for (final s in props.series) {
    for (var i = 0; i < s.data.length && i < dataLen; i++) {
      totals[i] += s.data[i];
    }
  }

  var allMax = totals.fold(double.negativeInfinity, math.max);
  var allMin = 0.0;
  allMin = props.yAxis?.min ?? allMin;
  allMax = props.yAxis?.max ?? (allMax == double.negativeInfinity ? 1 : allMax);

  final scale = computeNiceScale(
    allMin,
    allMax,
    props.yAxis?.tickCount ?? math.min(plotH - 1, 12),
    plotH,
  );

  final labels = props.labels ?? List.generate(dataLen, (i) => '${i + 1}');

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
  final groupWidth = (plotW - 2) ~/ math.max(1, dataLen);
  final gap = math.max(0, groupWidth - 4);
  final barWidth = math.max(1, groupWidth - gap);

  for (var gi = 0; gi < dataLen; gi++) {
    final groupStartX = plotX + 1 + gi * groupWidth;
    var cumulative = 0.0;

    if (orientation == ChartOrientation.vertical) {
      for (var si = 0; si < numSeries; si++) {
        final series = props.series[si];
        final val = gi < series.data.length ? series.data[gi] : 0.0;
        cumulative += val;
        final seriesColor = fg(series.color ?? colors[si % colors.length]);
        final yNorm = (cumulative - scale.min) / (scale.max - scale.min);
        final prevNorm = (cumulative - val - scale.min) / (scale.max - scale.min);
        final topY = ePY + ePH - 2 - (yNorm * (ePH - 2)).round();
        final bottomY = ePY + ePH - 2 - (prevNorm * (ePH - 2)).round();

        for (var row = topY; row < bottomY; row++) {
          for (var col = 0; col < barWidth; col++) {
            final px = groupStartX + gap ~/ 2 + col;
            final py = row;
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
    } else {
      for (var si = 0; si < numSeries; si++) {
        final series = props.series[si];
        final val = gi < series.data.length ? series.data[gi] : 0.0;
        cumulative += val;
        final seriesColor = fg(series.color ?? colors[si % colors.length]);
        final xNorm = (cumulative - scale.min) / (scale.max - scale.min);
        final prevNorm = (cumulative - val - scale.min) / (scale.max - scale.min);
        final leftX = plotX + 1 + (prevNorm * (plotW - 2)).round();
        final rightX = plotX + 1 + (xNorm * (plotW - 2)).round();
        final barH = math.max(1, (groupWidth - gap));

        for (var col = leftX; col < rightX; col++) {
          for (var row = 0; row < barH; row++) {
            final px = col;
            final py = groupStartX + gap ~/ 2 + row;
            if (px < plotX + plotW && py < plotY + plotH) {
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

/// Creates a stacked bar chart and returns it rendered as a multi-line string.
String createStackedBarChart(StackedBarChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderStackedBarChart(screen, area, props),
  );
}
