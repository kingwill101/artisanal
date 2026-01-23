library;

import 'dart:math' as math;

import '../colorprofile/convert.dart' as cp;
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

  // If they requested <= number of stops, return the stops (like upstream).
  if (steps <= stops.length) {
    return stops.take(steps).toList(growable: false);
  }

  final rgbStops = <cp.Rgb>[];
  for (final c in stops) {
    final rgb = _toRgb(c, hasDarkBackground: hasDarkBackground);
    if (rgb != null) rgbStops.add(rgb);
  }

  if (rgbStops.isEmpty) return const [];
  if (rgbStops.length == 1) {
    final single = _colorFromRgb(rgbStops[0]);
    return List<Color>.filled(steps, single, growable: false);
  }

  final numSegments = rgbStops.length - 1;
  final defaultSize = steps ~/ numSegments;
  final remaining = steps % numSegments;

  final out = List<Color>.filled(
    steps,
    _colorFromRgb(rgbStops.first),
    growable: false,
  );

  var outIndex = 0;
  for (var i = 0; i < numSegments; i++) {
    final from = rgbStops[i];
    final to = rgbStops[i + 1];
    var segmentSize = defaultSize;
    if (i < remaining) segmentSize++;

    final divisor = segmentSize > 1 ? (segmentSize - 1) : 1;
    for (var j = 0; j < segmentSize; j++) {
      final t = segmentSize > 1 ? (j / divisor) : 0.0;
      final r = _lerp(from.r, to.r, t);
      final g = _lerp(from.g, to.g, t);
      final b = _lerp(from.b, to.b, t);
      out[outIndex++] = BasicColor(_hexFromRgb(r, g, b));
      if (outIndex >= steps) break;
    }
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

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

String _hexFromRgb(int r, int g, int b) =>
    '#${r.toRadixString(16).padLeft(2, '0')}'
    '${g.toRadixString(16).padLeft(2, '0')}'
    '${b.toRadixString(16).padLeft(2, '0')}';

Color _colorFromRgb(cp.Rgb rgb) => BasicColor(_hexFromRgb(rgb.r, rgb.g, rgb.b));

cp.Rgb? _toRgb(Color c, {required bool hasDarkBackground}) {
  switch (c) {
    case NoColor():
      return null;
    case AnsiColor(:final code):
      return cp.ansi256ToRgb(code);
    case BasicColor(:final value):
      if (!c.isHex) {
        final code = (int.tryParse(value) ?? 0).clamp(0, 255);
        return cp.ansi256ToRgb(code);
      }
      final hex = _normalizeHex(value);
      final r = int.parse(hex.substring(1, 3), radix: 16);
      final g = int.parse(hex.substring(3, 5), radix: 16);
      final b = int.parse(hex.substring(5, 7), radix: 16);
      return cp.Rgb(r, g, b);
    case AdaptiveColor(:final light, :final dark):
      return _toRgb(
        hasDarkBackground ? dark : light,
        hasDarkBackground: hasDarkBackground,
      );
    case CompleteColor(:final trueColor):
      return _toRgb(
        BasicColor(trueColor),
        hasDarkBackground: hasDarkBackground,
      );
    case CompleteAdaptiveColor(:final light, :final dark):
      return _toRgb(
        hasDarkBackground ? dark : light,
        hasDarkBackground: hasDarkBackground,
      );
    default:
      return null;
  }
}

String _normalizeHex(String value) {
  var hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  return '#$hex';
}
