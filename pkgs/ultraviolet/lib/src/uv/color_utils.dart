/// Color conversion and manipulation utilities.
///
/// Includes helpers for converting between RGB and HSL, determining color
/// brightness, and formatting colors for ANSI sequences.
///
/// {@category Ultraviolet}
/// {@subCategory Styling}
library;

import 'cell.dart';

int _shift16To8(int x) {
  if (x <= 0) return 0;
  if (x <= 0xff) return x;
  if (x <= 0xffff) return x >> 8;
  return 0xff;
}

/// Shifts a 16-bit color component down to 8-bit.
int shift(int x) => _shift16To8(x);

/// Clamps a color component to the byte range required by SGR truecolor.
int clampRgbChannel(int x) {
  if (x <= 0) return 0;
  if (x >= 0xff) return 0xff;
  return x;
}

/// Formats [c] as a `#RRGGBB` hex string, or empty if null.
String colorToHex(UvRgb? c) {
  if (c == null) return '';
  final r = c.r.clamp(0, 255);
  final g = c.g.clamp(0, 255);
  final b = c.b.clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

/// Returns the max and min of three values.
(double max, double min) getMaxMin(double a, double b, double c) {
  double ma;
  double mi;
  if (a > b) {
    ma = a;
    mi = b;
  } else {
    ma = b;
    mi = a;
  }
  if (c > ma) {
    ma = c;
  } else if (c < mi) {
    mi = c;
  }
  return (ma, mi);
}

double _round3(double x) => (x * 1000).roundToDouble() / 1000;

///
/// Returns `(h, s, l)` where `h` is degrees `[0, 360)`.
(double h, double s, double l) rgbToHsl(int r, int g, int b) {
  final rNot = r / 255.0;
  final gNot = g / 255.0;
  final bNot = b / 255.0;

  final (cMax, cMin) = getMaxMin(rNot, gNot, bNot);
  final delta = cMax - cMin;
  final l = (cMax + cMin) / 2.0;

  double h;
  double s;

  if (delta == 0) {
    h = 0;
    s = 0;
  } else {
    if (cMax == rNot) {
      h = 60 * (((gNot - bNot) / delta) % 6);
    } else if (cMax == gNot) {
      h = 60 * (((bNot - rNot) / delta) + 2);
    } else {
      h = 60 * (((rNot - gNot) / delta) + 4);
    }
    if (h < 0) h += 360;

    s = delta / (1 - (2 * l - 1).abs());
  }

  return (h, _round3(s), _round3(l));
}

/// Returns whether [c] is considered dark using HSL lightness.
bool isDarkColor(UvRgb? c) {
  if (c == null) return true;
  final (_, _, l) = rgbToHsl(c.r, c.g, c.b);
  return l < 0.5;
}

/// Composites [src] over [dst] using Porter-Duff SourceOver.
///
/// When [src] is a translucent [UvRgb], this blends it over [dst] using
/// integer arithmetic and returns an opaque [UvRgb]. Non-RGB colors fall back
/// to source replacement semantics.
UvColor? sourceOver(UvColor? src, UvColor? dst) {
  if (src == null) return dst;
  return switch (src) {
    UvRgb() => _sourceOverRgb(src, dst),
    _ => src,
  };
}

UvColor? _sourceOverRgb(UvRgb src, UvColor? dst) {
  final sa = src.a.clamp(0, 255);
  if (sa <= 0) return dst;
  if (sa >= 255) return UvRgb(src.r, src.g, src.b);
  if (dst == null) {
    return UvRgb(src.r, src.g, src.b, a: sa);
  }
  if (dst case UvRgb(:final r, :final g, :final b, :final a)) {
    final da = a.clamp(0, 255);
    // outA = sa + (da * (255 - sa) + 127) / 255
    // Replace ~/ 255 with (x * 257) >> 16 — an exact integer-division trick
    // that avoids the slow idiv instruction on x86/ARM.
    final outA = sa + ((da * (255 - sa) + 127) * 257 >> 16);
    if (outA <= 0) return const UvRgb(0, 0, 0, a: 0);
    final outDenom = outA * 255;
    final outR =
        ((src.r * sa * 255) + (r * da * (255 - sa)) + (outA ~/ 2)) ~/
        outDenom;
    final outG =
        ((src.g * sa * 255) + (g * da * (255 - sa)) + (outA ~/ 2)) ~/
        outDenom;
    final outB =
        ((src.b * sa * 255) + (b * da * (255 - sa)) + (outA ~/ 2)) ~/
        outDenom;
    return UvRgb(outR, outG, outB, a: outA);
  }
  return UvRgb(src.r, src.g, src.b);
}
