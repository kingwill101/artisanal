library;

import 'dart:math' as math;

import '../colorprofile/convert.dart' as cp;
import 'uv_color_bridge.dart';
import 'color.dart';

/// Blends a series of [Color] stops into [steps] colors (1D gradient).
///
/// This is a minimal-first port of lipgloss v2 `Blend1D`, but uses simple
/// RGB interpolation (rather than Lab) to avoid pulling in a large dependency.
///
/// If fewer than 2 blendable stops are provided, returns a list filled with the
/// single stop (or empty if none are blendable).
List<Color> blend1D(
  int steps,
  List<Color> stops, {
  required bool hasDarkBackground,
}) {
  if (steps < 0) steps = 0;
  if (steps == 0) return const [];
  if (stops.isEmpty) return const [];

  final rgbStops = <cp.Rgb>[];
  for (final c in stops) {
    final rgb = c.toRgb(hasDarkBackground: hasDarkBackground);
    if (rgb != null) rgbStops.add(rgb);
  }

  if (rgbStops.isEmpty) return const [];
  if (rgbStops.length == 1) {
    final single = _colorFromRgb(rgbStops[0]);
    return List<Color>.filled(steps, single, growable: false);
  }

  if (steps == 1) {
    return [_colorFromRgb(rgbStops.first)];
  }

  final out = List<Color>.filled(
    steps,
    _colorFromRgb(rgbStops.first),
    growable: false,
  );
  final maxPos = rgbStops.length - 1;

  for (var i = 0; i < steps; i++) {
    final pos = i / (steps - 1);
    final target = pos * maxPos;
    final leftIndex = target.floor().clamp(0, maxPos).toInt();
    final rightIndex = (leftIndex + 1).clamp(0, maxPos).toInt();
    final t = target - leftIndex;

    if (leftIndex == rightIndex) {
      out[i] = _colorFromRgb(rgbStops[leftIndex]);
      continue;
    }

    final from = rgbStops[leftIndex];
    final to = rgbStops[rightIndex];
    out[i] = BasicColor(
      _hexFromRgb(
        _lerp(from.r, to.r, t),
        _lerp(from.g, to.g, t),
        _lerp(from.b, to.b, t),
      ),
    );
  }

  return out;
}

/// Blends a series of [Color] stops into a 2D gradient.
///
/// Returns colors in row-major order: `index = y * width + x`.
///
/// This is a minimal-first port of lipgloss v2 `Blend2D` (but uses RGB
/// interpolation via [blend1D]).
List<Color> blend2D(
  int width,
  int height,
  double angle,
  List<Color> stops, {
  required bool hasDarkBackground,
}) {
  if (width < 1) width = 1;
  if (height < 1) height = 1;

  // Normalize angle to 0-360.
  angle %= 360;
  if (angle < 0) angle += 360;

  if (stops.isEmpty) return const [];
  if (stops.length == 1) {
    return List<Color>.filled(width * height, stops.first, growable: false);
  }

  final diagonalGradient = blend1D(
    math.max(width, height),
    stops,
    hasDarkBackground: hasDarkBackground,
  );
  if (diagonalGradient.isEmpty) return const [];

  final out = List<Color>.filled(width * height, diagonalGradient.first);

  final centerX = (width - 1) / 2.0;
  final centerY = (height - 1) / 2.0;

  final angleRad = angle * math.pi / 180.0;
  final cosAngle = math.cos(angleRad);
  final sinAngle = math.sin(angleRad);

  final diagonalLength = math.sqrt(width * width + height * height);
  final gradLen = diagonalGradient.length - 1;

  for (var y = 0; y < height; y++) {
    final dy = y - centerY;
    for (var x = 0; x < width; x++) {
      final dx = x - centerX;
      final rotX = dx * cosAngle - dy * sinAngle;
      final pos = ((rotX + diagonalLength / 2.0) / diagonalLength).clamp(
        0.0,
        1.0,
      );
      var idx = (pos * gradLen).floor();
      if (idx < 0) idx = 0;
      if (idx > gradLen) idx = gradLen;
      out[y * width + x] = diagonalGradient[idx];
    }
  }

  return out;
}

/// Blends two colors into a single interpolated color.
///
/// This reuses the same RGB interpolation path as [blend1D] and [blend2D].
/// If either color cannot be represented as RGB, the closer endpoint is
/// returned instead of attempting a lossy interpolation.
Color blendColor(
  Color from,
  Color to,
  double t, {
  required bool hasDarkBackground,
}) {
  if (t <= 0.0) return from;
  if (t >= 1.0) return to;

  final fromRgb = from.toRgb(hasDarkBackground: hasDarkBackground);
  final toRgb = to.toRgb(hasDarkBackground: hasDarkBackground);
  if (fromRgb == null || toRgb == null) {
    return t < 0.5 ? from : to;
  }

  return _colorFromRgb(
    cp.Rgb(
      _lerp(fromRgb.r, toRgb.r, t),
      _lerp(fromRgb.g, toRgb.g, t),
      _lerp(fromRgb.b, toRgb.b, t),
    ),
  );
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

String _hexFromRgb(int r, int g, int b) =>
    '#${r.toRadixString(16).padLeft(2, '0')}'
    '${g.toRadixString(16).padLeft(2, '0')}'
    '${b.toRadixString(16).padLeft(2, '0')}';

Color _colorFromRgb(cp.Rgb rgb) => BasicColor(_hexFromRgb(rgb.r, rgb.g, rgb.b));
