/// Pie and donut charts with braille sub-pixel fill.
library;

import 'dart:math' as math;

import '../frame_buffer.dart';
import '../surface.dart';
import '../types.dart';
import '../utils.dart';

/// Renders a pie chart onto [fb].
void renderPieChart(
  ChartFrameBuffer fb,
  int width,
  int height,
  PieChartProps props,
) {
  final bg = color(props.backgroundColor ?? '#1A1A2E');
  final colors = props.colors ?? defaultColors;
  final margins = resolveMargins(props.margins);
  final showPercentages = props.showPercentages != false;
  final showLabels = props.showLabels != false;
  final isDonut = props.donut == true;

  fb.fillRect(0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    fb.drawText(props.title!, margins.left, 0, color(props.titleColor ?? '#FFFFFF'), bg);
    titleOffset = 1;
  }

  final total = props.slices.fold<double>(0, (sum, s) => sum + s.value);
  if (total == 0) return;

  final legendWidth = showLabels
      ? math.min(
          25,
          math.max(
            15,
            props.slices.map((s) => s.label.length).fold(0, math.max) + 10,
          ),
        )
      : 0;
  final chartAreaW = width - margins.left - margins.right - legendWidth;
  final chartAreaH = height - margins.top - margins.bottom - titleOffset;

  if (chartAreaW < 4 || chartAreaH < 4) return;

  final spW = chartAreaW * 2;
  final spH = chartAreaH * 4;
  final centerSX = spW / 2;
  final centerSY = spH / 2;
  final maxRadius = math.min(centerSX, centerSY) - 1;
  final radiusSP = props.radius != null ? props.radius! * 4.0 : maxRadius;
  final innerRadiusSP = isDonut
      ? (props.donutInnerRadius != null
          ? props.donutInnerRadius! * 4.0
          : (radiusSP * 0.4).floorToDouble())
      : 0.0;

  final sliceAngles = <({double start, double end})>[];
  var currentAngle = -math.pi / 2;
  for (final slice in props.slices) {
    final angle = (slice.value / total) * 2 * math.pi;
    sliceAngles.add((start: currentAngle, end: currentAngle + angle));
    currentAngle += angle;
  }

  final canvases = List.generate(
    props.slices.length,
    (_) => BrailleCanvas(chartAreaW, chartAreaH),
  );

  for (var sy = 0; sy < spH; sy++) {
    for (var sx = 0; sx < spW; sx++) {
      final nx = sx - centerSX;
      final ny = sy - centerSY;
      final dist = math.sqrt(nx * nx + ny * ny);
      if (dist > radiusSP || dist < innerRadiusSP) continue;

      final angle = math.atan2(ny, nx);
      for (var si = 0; si < props.slices.length; si++) {
        final start = sliceAngles[si].start;
        final end = sliceAngles[si].end;
        var a = angle;
        if (a < start) a += 2 * math.pi;
        if (a >= start && a < end) {
          canvases[si].set(sx, sy);
          break;
        }
        a = angle + 2 * math.pi;
        if (a >= start && a < end) {
          canvases[si].set(sx, sy);
          break;
        }
      }
    }
  }

  final offsetX = margins.left;
  final offsetY = margins.top + titleOffset;
  for (var si = 0; si < props.slices.length; si++) {
    final sliceColor = color(
      props.slices[si].color ?? colors[si % colors.length],
    );
    canvases[si].render(fb, offsetX, offsetY, sliceColor, bg);
  }

  if (showLabels) {
    final legendX = margins.left + chartAreaW + 2;
    var legendY = margins.top + titleOffset;
    for (var i = 0; i < props.slices.length; i++) {
      final slice = props.slices[i];
      final pct = ((slice.value / total) * 100).toStringAsFixed(1);
      final sliceColor = color(slice.color ?? colors[i % colors.length]);
      if (legendY >= height - margins.bottom) break;
      fb.setSolid(legendX, legendY, sliceColor);
      final label = showPercentages
          ? ' ${slice.label} ($pct%)'
          : ' ${slice.label}';
      final trimmed = label.length > legendWidth - 2
          ? label.substring(0, legendWidth - 2)
          : label;
      fb.drawText(trimmed, legendX + 1, legendY, color('#AAAAAA'), bg);
      legendY++;
    }
  }

  if (isDonut) {
    final centerTermX = margins.left + chartAreaW ~/ 2;
    final centerTermY = margins.top + titleOffset + chartAreaH ~/ 2;
    final totalStr = formatNumber(total);
    fb.drawText(
      totalStr,
      centerTermX - totalStr.length ~/ 2,
      centerTermY,
      color('#FFFFFF'),
      bg,
    );
  }
}

/// Creates a pie chart surface.
ChartSurface createPieChart(PieChartProps props) {
  return createChartSurface(
    width: props.width,
    height: props.height,
    paint: (fb, w, h) => renderPieChart(fb, w, h, props),
  );
}

/// Updates an existing pie chart surface.
void updatePieChart(ChartSurface surface, PieChartProps props) {
  updateChartSurface(
    surface,
    paint: (fb, w, h) => renderPieChart(fb, w, h, props),
  );
}
