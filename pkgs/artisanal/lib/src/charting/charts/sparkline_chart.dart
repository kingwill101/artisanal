/// Sparkline charts.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a sparkline chart onto [screen] within [area].
void renderSparklineChart(
  Screen screen,
  Rectangle area,
  SparklineProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || props.data.isEmpty) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final lineColor = fg(props.color ?? defaultColors[0]);
  final style = props.style ?? SparklineStyle.line;

  fillRect(screen, area, 0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    putText(
      screen,
      area,
      0,
      0,
      props.title!,
      mergeStyle(fg(props.titleColor ?? '#FFFFFF'), bg),
    );
    titleOffset = 1;
  }

  final plotH = height - titleOffset;
  if (plotH < 1) return;

  final minV = props.data.reduce(math.min);
  final maxV = props.data.reduce(math.max);
  final range = maxV - minV == 0 ? 1.0 : maxV - minV;

  switch (style) {
    case SparklineStyle.bar:
      final barW = math.max(1, width ~/ math.max(1, props.data.length));
      for (var i = 0; i < props.data.length; i++) {
        final v = props.data[i];
        final barH = ((v - minV) / range * (plotH - 1)).round().clamp(1, plotH);
        final x = math.min(width - 1, i * barW);
        for (var row = 0; row < barH; row++) {
          putSolidChartCell(
            screen,
            x,
            plotH - 1 - row + titleOffset,
            lineColor,
            Block.full,
          );
        }
      }
    case SparklineStyle.dot:
      for (var x = 0; x < width; x++) {
        final t = width <= 1 ? 0.0 : x / (width - 1);
        final idx = (t * (props.data.length - 1)).round();
        final v = props.data[idx];
        final y = ((plotH - 1) - (v - minV) / range * (plotH - 1))
            .round()
            .clamp(0, plotH - 1);
        putCell(screen, x, y + titleOffset, LineChars.dot,
            mergeStyle(lineColor, bg));
      }
    case SparklineStyle.line:
      for (var x = 0; x < width; x++) {
        final t = width <= 1 ? 0.0 : x / (width - 1);
        final idx = (t * (props.data.length - 1)).toDouble();
        final i0 = idx.floor().clamp(0, props.data.length - 1);
        final i1 = idx.ceil().clamp(0, props.data.length - 1);
        final frac = idx - i0;
        final v = props.data[i0] + (props.data[i1] - props.data[i0]) * frac;
        final y = ((plotH - 1) - (v - minV) / range * (plotH - 1))
            .round()
            .clamp(0, plotH - 1);
        putSolidChartCell(screen, x, y + titleOffset, lineColor, Block.full);
      }
  }

  if (props.showMinMax ?? false) {
    final minStr = formatNumber(minV);
    final maxStr = formatNumber(maxV);
    putText(screen, area, 0, titleOffset, maxStr,
        mergeStyle(fg('#888888'), bg));
    putText(screen, area, math.max(0, width - minStr.length), height - 1,
        minStr, mergeStyle(fg('#888888'), bg));
  }
}

/// Creates a sparkline chart and returns it rendered as a multi-line string.
String createSparklineChart(SparklineProps props) {
  return renderChart(
    props.width,
    props.height ?? 3,
    (screen, area) => renderSparklineChart(screen, area, props),
  );
}

/// Alias for [createSparklineChart] matching the legacy opentui-charts name.
String createSparkline(SparklineProps props) => createSparklineChart(props);
