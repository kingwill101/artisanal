/// Accessibility helpers for terminal styling.
///
/// These helpers implement WCAG-inspired contrast checks on sRGB colors.
///
/// ## References
/// - WCAG 2.1 contrast ratio formula
///   https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
library;

import 'dart:math' as math;

import 'uv_color_bridge.dart';
import 'color.dart';

/// Returns WCAG-style relative luminance for a color.
///
/// The result is normalized between 0.0 (black) and 1.0 (white).
double relativeLuminance(Color color, {bool hasDarkBackground = true}) {
  final rgb = color.toRgb(hasDarkBackground: hasDarkBackground);
  if (rgb == null) {
    throw ArgumentError('Unable to resolve color to RGB for contrast math');
  }
  return relativeLuminanceRgb(rgb.r, rgb.g, rgb.b);
}

/// Returns WCAG-style relative luminance for explicit sRGB channels.
///
/// The result is normalized between 0.0 (black) and 1.0 (white).
double relativeLuminanceRgb(int red, int green, int blue) {
  return _relativeLuminanceFromRgb(red, green, blue);
}

/// Returns `true` when the supplied sRGB color is dark enough to prefer white text.
bool isDarkColorRgb({required int red, required int green, required int blue}) {
  return relativeLuminanceRgb(red, green, blue) < 0.179128784747792;
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
