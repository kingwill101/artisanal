/// Stacked bar charts.
library;

import 'dart:math' as math;

import '../frame_buffer.dart';
import '../surface.dart';
import '../types.dart';
import '../utils.dart';

/// Renders a stacked bar chart onto [fb].
void renderStackedBarChart(
  ChartFrameBuffer fb,
  int width,
  int height,
  StackedBarChartProps props,
) {
  final bg = color(props.backgroundColor ?? '#1A1A2E');
  final axisColor = color(props.yAxis?.color ?? '#555555');
  final colors = props.colors ?? defaultColors;
  final margins = resolveMargins(props.margins);
  final barChar = props.barChar ?? Block.full;
  final orientation = props.orientation ?? ChartOrientation.vertical;

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

  if (plotW < 3 || plotH < 3) return;

  final dataLen = props.series.map((s) => s.data.length).fold(0, math.max);
  final labels = props.labels ?? List.generate(dataLen, (i) => '${i + 1}');

  final stackedTotals = <double>[];
  for (var i = 0; i < dataLen; i++) {
    var total = 0.0;
    for (final s in props.series) {
      total += i < s.data.length ? s.data[i] : 0.0;
    }
    stackedTotals.add(total);
  }

  final allMax = stackedTotals.isEmpty ? 0.0 : stackedTotals.reduce(math.max);
  final scale = computeNiceScale(
    0,
    allMax,
    props.yAxis?.tickCount ?? math.min(plotH - 1, 12),
    plotH,
  );

  if (orientation == ChartOrientation.vertical) {
    drawAxes(
      fb,
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
    final ePY = plotY + (scale.plotYOffset ?? 0);
    final groupWidth = (plotW - 2) ~/ math.max(1, dataLen);
    final barWidth = math.max(1, groupWidth - 2);
    final gap = (groupWidth - barWidth) ~/ 2;
    final baseY = ePY + ePH - 2;

    for (var gi = 0; gi < dataLen; gi++) {
      final barX = plotX + 1 + gi * groupWidth + gap;
      var currentBase = baseY;

      for (var si = 0; si < props.series.length; si++) {
        final val = gi < props.series[si].data.length
            ? props.series[si].data[gi]
            : 0.0;
        final seriesColor = color(
          props.series[si].color ?? colors[si % colors.length],
        );
        final yNorm = val / (scale.max - scale.min);
        final barH = (yNorm * (ePH - 2)).round();

        for (var row = 0; row < barH; row++) {
          for (var col = 0; col < barWidth; col++) {
            final px = barX + col;
            final py = currentBase - row;
            if (px > plotX &&
                px < plotX + plotW - 1 &&
                py >= plotY &&
                py < plotY + plotH) {
              if (barChar == Block.full) {
                fb.setSolid(px, py, seriesColor);
              } else {
                fb.setCell(px, py, barChar, seriesColor, bg);
              }
            }
          }
        }
        currentBase -= barH;
      }
    }
  } else {
    final groupHeight = (plotH - 2) ~/ math.max(1, dataLen);
    final barHeight = math.max(1, groupHeight - 2);
    final gap = (groupHeight - barHeight) ~/ 2;

    for (var gi = 0; gi < dataLen; gi++) {
      final y = plotY + 1 + gi * groupHeight + gap;
      final label = gi < labels.length
          ? (labels[gi].length > margins.left - 1
              ? labels[gi].substring(0, margins.left - 1)
              : labels[gi])
          : '';
      fb.drawText(label.padLeft(math.max(0, margins.left - 1)), 0, y, axisColor, bg);

      var currentX = plotX + 1;
      for (var si = 0; si < props.series.length; si++) {
        final val = gi < props.series[si].data.length
            ? props.series[si].data[gi]
            : 0.0;
        final seriesColor = color(
          props.series[si].color ?? colors[si % colors.length],
        );
        final xNorm = val / (scale.max - scale.min);
        final barW = (xNorm * (plotW - 2)).round();

        for (var row = 0; row < barHeight; row++) {
          for (var col = 0; col < barW; col++) {
            final px = currentX + col;
            final py = y + row;
            if (px < plotX + plotW && py < plotY + plotH) {
              if (barChar == Block.full) {
                fb.setSolid(px, py, seriesColor);
              } else {
                fb.setCell(px, py, barChar, seriesColor, bg);
              }
            }
          }
        }
        currentX += barW;
      }
    }
  }

  if (props.legend?.show != false) {
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

/// Creates a stacked bar chart surface.
ChartSurface createStackedBarChart(StackedBarChartProps props) {
  return createChartSurface(
    width: props.width,
    height: props.height,
    paint: (fb, w, h) => renderStackedBarChart(fb, w, h, props),
  );
}

/// Updates an existing stacked bar chart surface.
void updateStackedBarChart(ChartSurface surface, StackedBarChartProps props) {
  updateChartSurface(
    surface,
    paint: (fb, w, h) => renderStackedBarChart(fb, w, h, props),
  );
}
