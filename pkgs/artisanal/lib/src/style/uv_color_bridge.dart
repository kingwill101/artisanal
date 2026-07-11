/// Bridge between [Color] and the ultraviolet [cp.Rgb] conversion layer.
///
/// Provides a unified `toRgb` extension so that helpers like
/// [relativeLuminance] and [blend1D] can resolve any [Color] subtype to raw
/// sRGB without knowing the concrete class.
library;

import '../colorprofile/convert.dart' as cp;
import 'color.dart';

/// Extension that adds [toRgb] to every [Color] subtype.
extension ColorRgbBridge on Color {
  /// Resolves this color to an sRGB triple, or `null` if the color is
  /// terminal-default or otherwise unrepresentable as RGB.
  cp.Rgb? toRgb({bool hasDarkBackground = true}) {
    return switch (this) {
      final BasicColor c => _basicToRgb(c),
      final AnsiColor c => _ansiToRgb(c),
      final AdaptiveColor c => (hasDarkBackground ? c.dark : c.light).toRgb(
        hasDarkBackground: hasDarkBackground,
      ),
      final CompleteColor c => _hexToRgb(c.trueColor),
      final CompleteAdaptiveColor c =>
        (hasDarkBackground ? c.dark : c.light).toRgb(
          hasDarkBackground: hasDarkBackground,
        ),
      _ => null, // DefaultColor, NoColor
    };
  }
}

cp.Rgb? _basicToRgb(BasicColor c) {
  if (c.isHex) {
    return _hexToRgb(c.toHex());
  }
  // ANSI code string (e.g. "196")
  final code = int.tryParse(c.value);
  if (code == null || code < 0 || code > 255) return null;
  return cp.ansi256ToRgb(code);
}

cp.Rgb _ansiToRgb(AnsiColor c) => cp.ansi256ToRgb(c.code);

cp.Rgb? _hexToRgb(String hex) {
  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  if (normalized.length != 6 && normalized.length != 3) return null;
  if (normalized.length == 3) {
    final r = int.tryParse(normalized[0] * 2, radix: 16);
    final g = int.tryParse(normalized[1] * 2, radix: 16);
    final b = int.tryParse(normalized[2] * 2, radix: 16);
    if (r == null || g == null || b == null) return null;
    return cp.Rgb(r, g, b);
  }
  final r = int.tryParse(normalized.substring(0, 2), radix: 16);
  final g = int.tryParse(normalized.substring(2, 4), radix: 16);
  final b = int.tryParse(normalized.substring(4, 6), radix: 16);
  if (r == null || g == null || b == null) return null;
  return cp.Rgb(r, g, b);
}
