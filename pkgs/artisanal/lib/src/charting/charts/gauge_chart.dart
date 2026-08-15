/// Semicircular gauge charts with braille arcs.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a gauge chart onto [screen] within [area].
void renderGaugeChart(
  Screen screen,
  Rectangle area,
  GaugeChartProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final margins = resolveMargins(props.margins);

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

  final min = props.min ?? 0;
  final max = props.max ?? 100;
  final value = props.value.clamp(min, max);
  final norm = max == min ? 0.0 : (value - min) / (max - min);

  final chartW = width - margins.left - margins.right;
  final chartH = height - margins.top - margins.bottom - titleOffset;
  if (chartW < 4 || chartH < 3) return;

  final textRows = (props.showValue == false ? 0 : 1) +
      (props.label != null ? 1 : 0);
  final arcAreaH = chartH - textRows;
  if (arcAreaH < 2) return;

  final spW = chartW * 2;
  final spH = arcAreaH * 4;
  final centerSX = spW / 2;
  final centerSY = spH.toDouble();
  final maxRadiusH = spW / 2 - 1;
  final maxRadiusV = spH - 1.0;
  final outerRadius = math.min(maxRadiusH, maxRadiusV);
  final thickness = math.max(3, (outerRadius * 0.2).floor()).toDouble();
  final innerRadius = math.max(0, outerRadius - thickness);

  final thresholds = props.thresholds ??
      const [
        GaugeThreshold(value: 0.33, color: '#4CAF50'),
        GaugeThreshold(value: 0.66, color: '#FFC107'),
        GaugeThreshold(value: 1.0, color: '#F44336'),
      ];

  String getColorForNorm(double n) {
    for (final t in thresholds) {
      if (n <= t.value) return t.color;
    }
    return thresholds.isNotEmpty ? thresholds.last.color : '#FFFFFF';
  }

  final unfilledCanvas = BrailleCanvas(chartW, arcAreaH);
  final colorCanvasMap = <String, BrailleCanvas>{};

  BrailleCanvas getCanvas(String hex) {
    return colorCanvasMap.putIfAbsent(
      hex,
      () => BrailleCanvas(chartW, arcAreaH),
    );
  }

  for (var sy = 0; sy < spH; sy++) {
    for (var sx = 0; sx < spW; sx++) {
      final nx = sx - centerSX;
      final ny = sy - centerSY;
      final dist = math.sqrt(nx * nx + ny * ny);
      if (dist > outerRadius || dist < innerRadius) continue;
      if (ny > 0) continue;

      final angle = math.atan2(-ny, nx);
      final angleFrac = 1 - angle / math.pi;

      if (angleFrac <= norm) {
        getCanvas(getColorForNorm(angleFrac)).set(sx, sy);
      } else {
        unfilledCanvas.set(sx, sy);
      }
    }
  }

  final offsetX = margins.left;
  final offsetY = margins.top + titleOffset;
  unfilledCanvas.render(
    screen,
    area,
    offsetX,
    offsetY,
    fg('#333333'),
    bg,
  );
  for (final entry in colorCanvasMap.entries) {
    entry.value.render(
      screen,
      area,
      offsetX,
      offsetY,
      fg(entry.key),
      bg,
    );
  }

  final centerTermX = margins.left + chartW ~/ 2;
  var textY = margins.top + titleOffset + arcAreaH;

  if (props.showValue != false) {
    final valStr = formatNumber(value);
    putText(
      screen,
      area,
      centerTermX - valStr.length ~/ 2,
      textY,
      valStr,
      mergeStyle(fg('#FFFFFF'), bg),
    );
    textY++;
  }

  if (props.label != null) {
    putText(
      screen,
      area,
      centerTermX - props.label!.length ~/ 2,
      textY,
      props.label!,
      mergeStyle(fg('#888888'), bg),
    );
  }

  final minStr = formatNumber(min);
  final maxStr = formatNumber(max);
  final bottomY = margins.top + titleOffset + arcAreaH;
  putText(
    screen,
    area,
    margins.left,
    bottomY,
    minStr,
    mergeStyle(fg('#666666'), bg),
  );
  putText(
    screen,
    area,
    width - margins.right - maxStr.length,
    bottomY,
    maxStr,
    mergeStyle(fg('#666666'), bg),
  );
}

/// Creates a gauge chart and returns it rendered as a multi-line string.
String createGaugeChart(GaugeChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderGaugeChart(screen, area, props),
  );
}
