/// Pie and donut chart renderer for UV screens.
library;

import 'dart:math' as math;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';
import 'package:artisanal/style.dart';

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
/// Each cell is sampled at 2x2 sub-cell resolution (upper/lower x left/right)
/// and rendered with quarter/half block glyphs where possible. This improves
/// circular edges (less staircase aliasing) and allows top-bottom or
/// left-right slice blending at boundaries.
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
      final ul = _sampleSlice(
        x,
        y,
        cx,
        cy,
        cellAspect,
        radius,
        innerRadius,
        angles,
        palette.length,
        dxOffset: -0.25,
        dyOffset: -0.25,
      );
      final ur = _sampleSlice(
        x,
        y,
        cx,
        cy,
        cellAspect,
        radius,
        innerRadius,
        angles,
        palette.length,
        dxOffset: 0.25,
        dyOffset: -0.25,
      );
      final ll = _sampleSlice(
        x,
        y,
        cx,
        cy,
        cellAspect,
        radius,
        innerRadius,
        angles,
        palette.length,
        dxOffset: -0.25,
        dyOffset: 0.25,
      );
      final lr = _sampleSlice(
        x,
        y,
        cx,
        cy,
        cellAspect,
        radius,
        innerRadius,
        angles,
        palette.length,
        dxOffset: 0.25,
        dyOffset: 0.25,
      );

      var mask = 0;
      if (ul >= 0) mask |= 0x1;
      if (ur >= 0) mask |= 0x2;
      if (ll >= 0) mask |= 0x4;
      if (lr >= 0) mask |= 0x8;
      if (mask == 0) continue;

      // Fully covered cell. If all quadrants belong to the same slice,
      // preserve the original background-fill path for solid interior output.
      if (mask == 0xF && ul == ur && ul == ll && ul == lr) {
        final baseStyle = palette[ul];
        final useBg =
            useBackground && (baseStyle.bg != null || baseStyle.fg != null);
        final cellStyle = useBg
            ? (baseStyle.bg != null
                  ? baseStyle
                  : baseStyle.copyWith(bg: baseStyle.fg, clearFg: true))
            : baseStyle.copyWith(clearBg: true);
        final drawGlyph = useBg ? glyph : BlockShades.full;
        putCell(screen, x, y, drawGlyph, cellStyle);
        continue;
      }

      // Full cell but split by slice boundary: encode top/bottom or left/right
      // slice pairs when possible using fg/bg block blending.
      if (mask == 0xF && ul == ur && ll == lr && ul != ll) {
        final fg = _sliceColor(palette[ul]);
        final bg = _sliceColor(palette[ll]);
        putCell(screen, x, y, BlockShades.upper, UvStyle(fg: fg, bg: bg));
        continue;
      }
      if (mask == 0xF && ul == ll && ur == lr && ul != ur) {
        final fg = _sliceColor(palette[ul]);
        final bg = _sliceColor(palette[ur]);
        putCell(screen, x, y, BlockShades.left, UvStyle(fg: fg, bg: bg));
        continue;
      }

      final dominant = _dominantSlice(ul, ur, ll, lr);
      if (dominant < 0) continue;
      final color = _sliceColor(palette[dominant]);
      final edgeGlyph = _maskToBlockGlyph(mask);
      if (edgeGlyph.isEmpty) continue;
      putCell(screen, x, y, edgeGlyph, UvStyle(fg: color));
    }
  }
}

int _sampleSlice(
  int x,
  int y,
  double cx,
  double cy,
  double cellAspect,
  double radius,
  double innerRadius,
  List<double> angles,
  int paletteLength, {
  required double dxOffset,
  required double dyOffset,
}) {
  final dx = ((x + dxOffset) - cx) / cellAspect;
  final dy = (y + dyOffset) - cy;
  final dist = math.sqrt(dx * dx + dy * dy);
  var angle = math.atan2(dy, dx);
  if (angle < 0) angle += math.pi * 2;
  return _sliceIndex(dist, angle, radius, innerRadius, angles, paletteLength);
}

UvColor? _sliceColor(UvStyle style) => style.bg ?? style.fg;

int _dominantSlice(int ul, int ur, int ll, int lr) {
  final counts = <int, int>{};
  for (final idx in [ul, ur, ll, lr]) {
    if (idx < 0) continue;
    counts[idx] = (counts[idx] ?? 0) + 1;
  }
  if (counts.isEmpty) return -1;
  var bestIdx = -1;
  var bestCount = -1;
  counts.forEach((idx, count) {
    if (count > bestCount) {
      bestIdx = idx;
      bestCount = count;
    }
  });
  return bestIdx;
}

String _maskToBlockGlyph(int mask) {
  return switch (mask) {
    0x1 => BlockQuadrants.upperLeft, // upper-left
    0x2 => BlockQuadrants.upperRight, // upper-right
    0x3 => BlockShades.upper, // top half
    0x4 => BlockQuadrants.lowerLeft, // lower-left
    0x5 => BlockShades.left, // left half
    0x6 => BlockQuadrants.rightHalves, // upper-right + lower-left
    0x7 => BlockQuadrants.allButLowerRight, // all but lower-right
    0x8 => BlockQuadrants.lowerRight, // lower-right
    0x9 => BlockQuadrants.leftHalves, // upper-left + lower-right
    0xA => BlockShades.right, // right half
    0xB => BlockQuadrants.allButLowerLeft, // all but lower-left
    0xC => BlockShades.lower, // bottom half
    0xD => BlockQuadrants.allButUpperRight, // all but upper-right
    0xE => BlockQuadrants.allButUpperLeft, // all but upper-left
    0xF => BlockShades.full, // full
    _ => '',
  };
}
