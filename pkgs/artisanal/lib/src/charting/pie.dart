/// Pie and donut chart renderer for UV screens.
library;

import 'dart:math' as math;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Draws a pie (or donut) chart of [values] into [area] on [screen].
void drawPieChart(
  Screen screen,
  Rectangle area,
  List<double> values, {
  List<UvStyle>? styles,
  bool useBackground = true,
  bool donut = false,
  double innerRadiusRatio = 0.45,
  double cellAspect = 2.0,
  String glyph = ' ',
}) {
  if (values.isEmpty) return;
  final width = area.width;
  final height = area.height;
  if (width <= 1 || height <= 1) return;

  final total = values.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return;

  final palette =
      styles ?? List<UvStyle>.generate(values.length, (_) => const UvStyle());

  final cx = area.minX + (width - 1) / 2.0;
  final cy = area.minY + (height - 1) / 2.0;
  final effectiveWidth = width / cellAspect;
  final radius = math.min(effectiveWidth, height) / 2.0 - 0.5;
  final innerRadius = donut ? radius * innerRadiusRatio : 0.0;

  final angles = <double>[];
  var acc = 0.0;
  for (final v in values) {
    acc += (v / total) * math.pi * 2;
    angles.add(acc);
  }

  for (var y = area.minY; y < area.maxY; y++) {
    for (var x = area.minX; x < area.maxX; x++) {
      final dx = (x - cx) / cellAspect;
      final dy = y - cy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > radius || dist < innerRadius) continue;
      var angle = math.atan2(dy, dx);
      if (angle < 0) angle += math.pi * 2;
      var idx = 0;
      while (idx < angles.length && angle > angles[idx]) {
        idx++;
      }
      if (idx >= palette.length) idx = palette.length - 1;
      final baseStyle = palette[idx];
      final useBg =
          useBackground && (baseStyle.bg != null || baseStyle.fg != null);
      final cellStyle = useBg
          ? (baseStyle.bg != null
                ? baseStyle
                : baseStyle.copyWith(bg: baseStyle.fg, clearFg: true))
          : baseStyle.copyWith(clearBg: true);
      final drawGlyph = useBg ? glyph : '●';
      putCell(screen, x, y, drawGlyph, cellStyle);
    }
  }
}
