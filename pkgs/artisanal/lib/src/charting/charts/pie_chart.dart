/// Pie and donut charts.
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

import '../core.dart' hide drawLegend;
import '../types.dart';
import '../util.dart';

/// Renders a pie chart onto [screen] within [area].
void renderPieChart(
  Screen screen,
  Rectangle area,
  PieChartProps props,
) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0 || props.slices.isEmpty) return;

  final bg = fg(props.backgroundColor ?? '#1A1A2E');
  final margins = resolveMargins(props.margins);
  final donut = props.donut ?? false;
  final colors = props.colors ?? defaultColors;

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

  final chartW = width - margins.left - margins.right;
  final chartH = height - margins.top - margins.bottom - titleOffset;
  if (chartW < 4 || chartH < 3) return;

  final legendW = props.legend?.show == false ? 0 : math.min(24, chartW ~/ 3);
  final pieW = chartW - legendW;
  final pieH = chartH;

  final centerX = margins.left + pieW ~/ 2;
  final centerY = margins.top + titleOffset + pieH ~/ 2;
  final radius =
      math.min((pieW - 2) / 2, (pieH - 2) / 2).clamp(1.0, 1000.0).toDouble();
  final innerR = donut ? radius * 0.45 : 0.0;

  final total = props.slices.fold<double>(
    0.0,
    (acc, s) => acc + s.value,
  );
  if (total <= 0) return;

  var startAngle = -math.pi / 2;
  for (var si = 0; si < props.slices.length; si++) {
    final slice = props.slices[si];
    final sweep = (slice.value / total) * 2 * math.pi;
    final endAngle = startAngle + sweep;
    final hex = slice.color ?? colors[si % colors.length];
    final sliceColor = fg(hex);
    final shade = dimFg(hex, 0.5);

    for (var sy = 0; sy < pieH * 2; sy++) {
      for (var sx = 0; sx < pieW * 2; sx++) {
        final nx = sx + 0.5 - pieW;
        final ny = sy + 0.5 - pieH;
        final dist = math.sqrt(nx * nx + ny * ny);
        if (dist > radius * 2 || dist < innerR * 2) continue;
        var angle = math.atan2(ny, nx);
        if (angle < startAngle) angle += 2 * math.pi;

        final px = centerX + sx ~/ 2 - pieW ~/ 2;
        final py = centerY + sy ~/ 2 - pieH ~/ 2;
        if (angle >= startAngle && angle < endAngle) {
          final char = (dist > radius * 1.4)
              ? Block.shadeLight
              : (dist > radius * 1.7 ? Block.shadeMedium : Block.full);
          if (char == Block.full) {
            putSolidChartCell(
              screen,
              px,
              py,
              sliceColor,
              Block.full,
            );
          } else {
            putCell(screen, px, py, char, mergeStyle(shade, bg));
          }
        }
      }
    }
    startAngle = endAngle;
  }

  if (props.showPercentages ?? false) {
    var largest = props.slices.first;
    for (final s in props.slices) {
      if (s.value > largest.value) largest = s;
    }
    final pct = (largest.value / total * 100).round();
    final label = '$pct%';
    putText(
      screen,
      area,
      centerX - label.length ~/ 2,
      centerY,
      label,
      mergeStyle(fg('#FFFFFF'), bg),
    );
  }

  if (props.legend?.show != false) {
    final items = [
      for (var i = 0; i < props.slices.length; i++)
        (
          name: props.slices[i].label,
          color: props.slices[i].color ?? colors[i % colors.length],
        ),
    ];
    drawLegend(
      screen,
      area,
      items,
      margins.left + pieW + 1,
      margins.top + titleOffset,
      legendW - 2,
      bg,
      vertical: true,
    );
  }
}

/// Creates a pie chart and returns it rendered as a multi-line string.
String createPieChart(PieChartProps props) {
  return renderChart(
    props.width,
    props.height,
    (screen, area) => renderPieChart(screen, area, props),
  );
}
