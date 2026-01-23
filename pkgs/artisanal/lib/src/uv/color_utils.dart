/// Color conversion and manipulation utilities.
///
/// Includes helpers for converting between RGB and HSL, determining color
/// brightness, and formatting colors for ANSI sequences.
///
/// {@category Ultraviolet}
/// {@subCategory Styling}
library;

import 'cell.dart';

int _shift16To8(int x) => x > 0xff ? (x >> 8) : x;

/// Upstream: `third_party/ultraviolet/decoder.go` (`shift`).
/// Shifts a 16-bit color component down to 8-bit.
int shift(int x) => _shift16To8(x);

/// Upstream: `third_party/ultraviolet/decoder.go` (`colorToHex`).
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

/// Upstream: `third_party/ultraviolet/decoder.go` (`getMaxMin`).
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

/// Upstream: `third_party/ultraviolet/decoder.go` (`rgbToHSL`).
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

/// Upstream: `third_party/ultraviolet/decoder.go` (`isDarkColor`).
/// Returns whether [c] is considered dark using HSL lightness.
bool isDarkColor(UvRgb? c) {
  if (c == null) return true;
  final (_, _, l) = rgbToHsl(c.r, c.g, c.b);
  return l < 0.5;
}
