/// Compact sparkline charts.
library;

import 'dart:math' as math;

import '../frame_buffer.dart';
import '../surface.dart';
import '../types.dart';
import '../utils.dart';

const _sparkBlocks = [' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

/// Renders a sparkline onto [fb].
void renderSparkline(
  ChartFrameBuffer fb,
  int width,
  int height,
  SparklineProps props,
) {
  final bg = color(props.backgroundColor ?? '#000000');
  final fg = color(props.color ?? '#4FC3F7');
  final data = props.data;
  final style = props.style ?? SparklineStyle.line;

  if (data.isEmpty) return;

  fb.fillRect(0, 0, width, height, bg);

  var titleOffset = 0;
  if (props.title != null) {
    fb.drawText(props.title!, 1, 0, color(props.titleColor ?? '#FFFFFF'), bg);
    titleOffset = 1;
  }

  final min = data.reduce(math.min);
  final max = data.reduce(math.max);
  final range = max - min == 0 ? 1.0 : max - min;
  final drawH = height - titleOffset;
  final drawY = titleOffset;
  if (drawH <= 0) return;

  if (style == SparklineStyle.line || style == SparklineStyle.dot) {
    if (drawH == 1) {
      for (var i = 0; i < math.min(data.length, width); i++) {
        final norm = (data[i] - min) / range;
        final level = (norm * 8).round().clamp(0, 8);
        fb.setCell(i, drawY, _sparkBlocks[level], fg, bg);
      }
    } else {
      final colorHex = props.color ?? '#4FC3F7';
      final qc = QuadrantCanvas(width, drawH);
      final subW = width * 2;
      final subH = drawH * 2;

      // One sample per terminal column with linear interpolation.
      final points = <(int, int)>[];
      final n = math.max(2, width);
      for (var col = 0; col < n; col++) {
        final t = data.length == 1 ? 0.0 : col / (n - 1);
        final rawIdx = t * (data.length - 1);
        final i0 = rawIdx.floor().clamp(0, data.length - 1);
        final i1 = math.min(i0 + 1, data.length - 1);
        final frac = rawIdx - i0;
        final val = data[i0] * (1 - frac) + data[i1] * frac;
        final norm = (val - min) / range;
        final sx = ((col / (n - 1)) * (subW - 1)).round();
        final sy = ((1 - norm) * (subH - 1)).round();
        points.add((sx, sy));
      }

      if (style == SparklineStyle.dot) {
        for (final (px, py) in points) {
          qc.set(px, py, colorHex);
        }
      } else {
        for (var i = 0; i < points.length - 1; i++) {
          final (x0, y0) = points[i];
          final (x1, y1) = points[i + 1];
          qc.drawLine(x0, y0, x1, y1, colorHex);
        }
        if (points.length == 1) {
          qc.set(points[0].$1, points[0].$2, colorHex);
        }
      }
      qc.render(fb, 0, drawY, bg);
    }
  } else if (style == SparklineStyle.bar) {
    final barW = math.max(1, width ~/ data.length);
    for (var i = 0; i < data.length; i++) {
      final norm = (data[i] - min) / range;
      final barH = math.max(1, (norm * drawH).round());
      final x = i * barW;
      for (var row = 0; row < barH; row++) {
        for (var bx = 0; bx < barW && x + bx < width; bx++) {
          fb.setSolid(x + bx, drawY + drawH - 1 - row, fg);
        }
      }
    }
  }

  if (props.showMinMax == true) {
    final minStr = formatNumber(min);
    final maxStr = formatNumber(max);
    fb.drawText(
      minStr,
      width - minStr.length,
      drawY + drawH - 1,
      color('#666666'),
      bg,
    );
    fb.drawText(maxStr, width - maxStr.length, drawY, color('#666666'), bg);
  }
}

/// Creates a sparkline surface.
ChartSurface createSparkline(SparklineProps props) {
  final h = props.height ?? 1;
  return createChartSurface(
    width: props.width,
    height: h,
    paint: (fb, w, height) => renderSparkline(fb, w, height, props),
  );
}

/// Updates an existing sparkline surface.
void updateSparkline(ChartSurface surface, SparklineProps props) {
  updateChartSurface(
    surface,
    paint: (fb, w, h) => renderSparkline(fb, w, h, props),
  );
}
