/// Pie and donut chart renderer for UV screens.
library;

import 'dart:math' as math;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Returns the slice index for a point at distance [dist] from the center
/// at the given [angle], or -1 if outside the pie.
int _sliceIndex(
  double dist,
  double angle,
  double radius,
  double innerRadius,
  List<double> angles,
  int paletteLength,
) {
  if (dist > radius || dist < innerRadius) return -1;
  var idx = 0;
  while (idx < angles.length && angle > angles[idx]) {
    idx++;
  }
  if (idx >= paletteLength) idx = paletteLength - 1;
  return idx;
}

/// Draws a pie (or donut) chart of [values] into [area] on [screen].
///
/// Each cell is tested at two vertical sub-positions (upper and lower half)
/// to produce half-block anti-aliasing at the circle boundary.  This gives
/// 2× vertical resolution, significantly reducing jagged staircase edges.
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
      // Test upper half of cell (y - 0.25) and lower half (y + 0.25).
      final dxRaw = (x - cx) / cellAspect;

      final dyUpper = (y - 0.25) - cy;
      final distUpper = math.sqrt(dxRaw * dxRaw + dyUpper * dyUpper);
      var angleUpper = math.atan2(dyUpper, dxRaw);
      if (angleUpper < 0) angleUpper += math.pi * 2;
      final upperIdx = _sliceIndex(
        distUpper,
        angleUpper,
        radius,
        innerRadius,
        angles,
        palette.length,
      );

      final dyLower = (y + 0.25) - cy;
      final distLower = math.sqrt(dxRaw * dxRaw + dyLower * dyLower);
      var angleLower = math.atan2(dyLower, dxRaw);
      if (angleLower < 0) angleLower += math.pi * 2;
      final lowerIdx = _sliceIndex(
        distLower,
        angleLower,
        radius,
        innerRadius,
        angles,
        palette.length,
      );

      if (upperIdx == -1 && lowerIdx == -1) continue;

      if (upperIdx == lowerIdx) {
        // Both halves same slice — full cell.
        final baseStyle = palette[upperIdx];
        final useBg =
            useBackground && (baseStyle.bg != null || baseStyle.fg != null);
        final cellStyle = useBg
            ? (baseStyle.bg != null
                  ? baseStyle
                  : baseStyle.copyWith(bg: baseStyle.fg, clearFg: true))
            : baseStyle.copyWith(clearBg: true);
        final drawGlyph = useBg ? glyph : '●';
        putCell(screen, x, y, drawGlyph, cellStyle);
      } else if (upperIdx == -1) {
        // Only lower half is inside the pie — draw ▄.
        final baseStyle = palette[lowerIdx];
        final fgColor = baseStyle.bg ?? baseStyle.fg;
        putCell(screen, x, y, '▄', UvStyle(fg: fgColor));
      } else if (lowerIdx == -1) {
        // Only upper half is inside the pie — draw ▀.
        final baseStyle = palette[upperIdx];
        final fgColor = baseStyle.bg ?? baseStyle.fg;
        putCell(screen, x, y, '▀', UvStyle(fg: fgColor));
      } else {
        // Two different slices — upper half ▀ with fg=upper, bg=lower.
        final upperSty = palette[upperIdx];
        final lowerSty = palette[lowerIdx];
        final fg = upperSty.bg ?? upperSty.fg;
        final bg = lowerSty.bg ?? lowerSty.fg;
        putCell(screen, x, y, '▀', UvStyle(fg: fg, bg: bg));
      }
    }
  }
}
