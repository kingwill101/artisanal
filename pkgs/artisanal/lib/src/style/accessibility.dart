/// Accessibility helpers for terminal styling.
///
/// These helpers implement WCAG-inspired contrast checks on sRGB colors.
///
/// ## References
/// - WCAG 2.1 contrast ratio formula
///   https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
library;

import 'dart:math' as math;

import '../colorprofile/convert.dart' as cp;
import 'color.dart';

/// Returns WCAG-style relative luminance for a color.
///
/// The result is normalized between 0.0 (black) and 1.0 (white).
double relativeLuminance(Color color, {bool hasDarkBackground = true}) {
  final rgb = _toRgb(color, hasDarkBackground: hasDarkBackground);
  if (rgb == null) {
    throw ArgumentError('Unable to resolve color to RGB for contrast math');
  }
  return _relativeLuminanceFromRgb(rgb.r, rgb.g, rgb.b);
}

/// Computes the WCAG contrast ratio of [foreground] vs [background].
///
/// The returned value is always >= 1.0.
double contrastRatio(
  Color foreground,
  Color background, {
  bool hasDarkBackground = true,
}) {
  final l1 = relativeLuminance(
    foreground,
    hasDarkBackground: hasDarkBackground,
  );
  final l2 = relativeLuminance(
    background,
    hasDarkBackground: hasDarkBackground,
  );
  final high = math.max(l1, l2);
  final low = math.min(l1, l2);
  return (high + 0.05) / (low + 0.05);
}

/// Returns `true` when colors satisfy WCAG AA contrast requirements.
///
/// `largeText` uses the WCAG relaxed threshold (3:1) for normal contrast checks
/// on larger text sizes.
bool meetsWcagAa(
  Color foreground,
  Color background, {
  bool largeText = false,
  bool hasDarkBackground = true,
}) {
  return contrastRatio(
        foreground,
        background,
        hasDarkBackground: hasDarkBackground,
      ) >=
      (largeText ? 3.0 : 4.5);
}

/// Returns `true` when colors satisfy WCAG AAA contrast requirements.
///
/// `largeText` uses the WCAG relaxed threshold (4.5:1) for larger text sizes.
bool meetsWcagAaa(
  Color foreground,
  Color background, {
  bool largeText = false,
  bool hasDarkBackground = true,
}) {
  return contrastRatio(
        foreground,
        background,
        hasDarkBackground: hasDarkBackground,
      ) >=
      (largeText ? 4.5 : 7.0);
}

/// Picks the candidate color with the highest contrast against [background].
///
/// If [candidates] is empty, this returns [Colors.black] by default.
Color bestTextColor(
  Color background, {
  List<Color> candidates = const [Colors.black, Colors.white],
  bool hasDarkBackground = true,
}) {
  if (candidates.isEmpty) return Colors.black;

  Color best = candidates.first;
  var bestRatio = -1.0;
  for (final candidate in candidates) {
    final ratio = contrastRatio(
      candidate,
      background,
      hasDarkBackground: hasDarkBackground,
    );
    if (ratio > bestRatio) {
      best = candidate;
      bestRatio = ratio;
    }
  }
  return best;
}

double _relativeLuminanceFromRgb(int r, int g, int b) {
  final linR = _srgbToLinear(r / 255.0);
  final linG = _srgbToLinear(g / 255.0);
  final linB = _srgbToLinear(b / 255.0);
  return 0.2126 * linR + 0.7152 * linG + 0.0722 * linB;
}

double _srgbToLinear(double channel) {
  if (channel <= 0.03928) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4) as double;
}

cp.Rgb? _toRgb(Color color, {required bool hasDarkBackground}) {
  return switch (color) {
    NoColor() => null,
    AnsiColor(:final code) => cp.ansi256ToRgb(code),
    BasicColor(:final value) when _isHexString(value) => _parseHexColor(value),
    BasicColor(:final value) => cp.ansi256ToRgb(
      (int.tryParse(value) ?? 0).clamp(0, 255),
    ),
    AdaptiveColor(:final light, :final dark) => _toRgb(
      hasDarkBackground ? dark : light,
      hasDarkBackground: hasDarkBackground,
    ),
    CompleteColor(:final trueColor) => _parseHexColor(_toHexValue(trueColor)),
    CompleteAdaptiveColor(:final light, :final dark) => _toRgb(
      hasDarkBackground ? dark : light,
      hasDarkBackground: hasDarkBackground,
    ),
    _ => null,
  };
}

String _toHexValue(String hex) => hex.startsWith('#') ? hex : '#$hex';

String _normalizeHex(String value) {
  var hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  return '#$hex';
}

cp.Rgb? _parseHexColor(String value) {
  final hex = _normalizeHex(value);
  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  if (normalized.length != 6) return null;
  final r = int.tryParse(normalized.substring(0, 2), radix: 16);
  final g = int.tryParse(normalized.substring(2, 4), radix: 16);
  final b = int.tryParse(normalized.substring(4, 6), radix: 16);
  if (r == null || g == null || b == null) return null;
  return cp.Rgb(r, g, b);
}

bool _isHexString(String value) {
  final trimmed = value.startsWith('#') ? value.substring(1) : value;
  if (trimmed.length != 3 && trimmed.length != 6) return false;
  if (trimmed.length == 3 && RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
    return false;
  }
  return int.tryParse(trimmed, radix: 16) != null;
}
