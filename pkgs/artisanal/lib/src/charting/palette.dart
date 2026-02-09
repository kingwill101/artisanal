/// Color ramps and palette utilities for chart rendering.
library;

import '../uv/cell.dart';

/// Discrete color ramp for mapping normalized [0..1] values to colors.
final class ChartRamp {
  /// Creates a ramp from an explicit list of [UvColor]s.
  const ChartRamp(this.colors);

  /// Creates a ramp from a list of hex color strings.
  factory ChartRamp.fromHexes(List<String> hexes) {
    return ChartRamp(hexes.map(uvColorFromHex).toList(growable: false));
  }

  /// A blue-to-red thermal ramp.
  factory ChartRamp.thermal() {
    return ChartRamp(const [
      UvColor.rgb(11, 19, 43),
      UvColor.rgb(21, 43, 82),
      UvColor.rgb(42, 78, 140),
      UvColor.rgb(56, 120, 168),
      UvColor.rgb(92, 189, 196),
      UvColor.rgb(178, 231, 170),
      UvColor.rgb(247, 204, 90),
      UvColor.rgb(244, 120, 54),
      UvColor.rgb(230, 57, 70),
    ]);
  }

  /// The ordered color stops in this ramp.
  final List<UvColor> colors;

  /// Returns the color for a normalized [value] in [0..1].
  UvColor colorFor(double value) {
    if (colors.isEmpty) return const UvBasic16(7);
    final idx = (value.clamp(0, 1) * (colors.length - 1)).round();
    return colors[idx.clamp(0, colors.length - 1)];
  }

  /// Returns a [UvStyle] for a normalized [value], as foreground or background.
  UvStyle styleFor(double value, {bool background = false}) {
    final color = colorFor(value);
    return background ? UvStyle(bg: color) : UvStyle(fg: color);
  }
}

/// Parses a hex color string (e.g. '#ff0000') into a [UvColor].
UvColor uvColorFromHex(String hex, {UvColor fallback = const UvBasic16(7)}) {
  if (hex.isEmpty) return fallback;
  var value = hex.toLowerCase().replaceAll('#', '');
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (value.length != 6) return fallback;
  final r = int.tryParse(value.substring(0, 2), radix: 16) ?? 0;
  final g = int.tryParse(value.substring(2, 4), radix: 16) ?? 0;
  final b = int.tryParse(value.substring(4, 6), radix: 16) ?? 0;
  return UvColor.rgb(r, g, b);
}

/// Creates a [UvStyle] from hex color strings for foreground and optional background.
UvStyle uvStyleFromHex(String hex, {String? backgroundHex, int attrs = 0}) {
  final fg = uvColorFromHex(hex);
  final bg = backgroundHex == null ? null : uvColorFromHex(backgroundHex);
  return UvStyle(fg: fg, bg: bg, attrs: attrs);
}
