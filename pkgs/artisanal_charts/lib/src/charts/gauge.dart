/// Semicircular gauge charts with braille arcs.
library;

import 'dart:math' as math;

import '../frame_buffer.dart';
import '../surface.dart';
import '../types.dart';
import '../utils.dart';

/// Renders a gauge chart onto [fb].
void renderGaugeChart(
  ChartFrameBuffer fb,
  int width,
  int height,
  GaugeChartProps props,
) {
  final bg = color(props.backgroundColor ?? '#1A1A2E');
  final margins = resolveMargins(props.margins);

  fb.fillRect(0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    fb.drawText(props.title!, margins.left, 0, color(props.titleColor ?? '#FFFFFF'), bg);
    titleOffset = 1;
  }

  final min = props.min ?? 0;
  final max = props.max ?? 100;
  final value = props.value.clamp(min, max);
  final norm = max == min ? 0.0 : (value - min) / (max - min);

  final chartW = width - margins.left - margins.right;
  final chartH = height - margins.top - margins.bottom - titleOffset;
  if (chartW < 4 || chartH < 3) return;

  final textRows = (props.showValue != false ? 1 : 0) + (props.label != null ? 1 : 0);
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
    return colorCanvasMap.putIfAbsent(hex, () => BrailleCanvas(chartW, arcAreaH));
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
  unfilledCanvas.render(fb, offsetX, offsetY, color('#333333'), bg);
  for (final entry in colorCanvasMap.entries) {
    entry.value.render(fb, offsetX, offsetY, color(entry.key), bg);
  }

  final centerTermX = margins.left + chartW ~/ 2;
  var textY = margins.top + titleOffset + arcAreaH;

  if (props.showValue != false) {
    final valStr = formatNumber(value);
    fb.drawText(
      valStr,
      centerTermX - valStr.length ~/ 2,
      textY,
      color('#FFFFFF'),
      bg,
    );
    textY++;
  }

  if (props.label != null) {
    fb.drawText(
      props.label!,
      centerTermX - props.label!.length ~/ 2,
      textY,
      color('#888888'),
      bg,
    );
  }

  final minStr = formatNumber(min);
  final maxStr = formatNumber(max);
  final bottomY = margins.top + titleOffset + arcAreaH;
  fb.drawText(minStr, margins.left, bottomY, color('#666666'), bg);
  fb.drawText(
    maxStr,
    width - margins.right - maxStr.length,
    bottomY,
    color('#666666'),
    bg,
  );
}

/// Creates a gauge chart surface.
ChartSurface createGaugeChart(GaugeChartProps props) {
  return createChartSurface(
    width: props.width,
    height: props.height,
    paint: (fb, w, h) => renderGaugeChart(fb, w, h, props),
  );
}

/// Updates an existing gauge chart surface.
void updateGaugeChart(ChartSurface surface, GaugeChartProps props) {
  updateChartSurface(
    surface,
    paint: (fb, w, h) => renderGaugeChart(fb, w, h, props),
  );
}
