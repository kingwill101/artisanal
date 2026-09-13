import 'cell.dart';

/// Immutable terminal color policy shared by non-ANSI renderers.
///
/// Palette entries are copied on construction. [faintMix] controls how much
/// the effective foreground is mixed toward the background; it is deliberately
/// a color operation rather than backend-specific alpha.
final class UvPaintPolicy {
  UvPaintPolicy({
    this.foreground = const UvRgb(204, 204, 204),
    this.background = const UvRgb(0, 0, 0),
    List<UvRgb>? palette,
    this.faintMix = 0.5,
  }) : palette = palette == null ? null : List<UvRgb>.unmodifiable(palette) {
    if (this.palette != null &&
        this.palette!.length != 16 &&
        this.palette!.length != 256) {
      throw ArgumentError('A terminal palette must have 16 or 256 colors');
    }
    if (faintMix < 0 || faintMix > 1) {
      throw ArgumentError.value(
        faintMix,
        'faintMix',
        'must be between 0 and 1',
      );
    }
  }

  final UvRgb foreground;
  final UvRgb background;
  final List<UvRgb>? palette;
  final double faintMix;

  /// Resolves a style into the colors actually used to paint a cell.
  UvCellPaint resolve(UvStyle style) {
    var fg = resolveColor(style.fg, foreground);
    var bg = resolveColor(style.bg, background);
    if ((style.attrs & Attr.reverse) != 0) (fg, bg) = (bg, fg);
    if ((style.attrs & Attr.faint) != 0) {
      fg = _mix(fg, bg, faintMix);
    }
    if ((style.attrs & Attr.conceal) != 0) fg = bg;
    final underline = resolveColor(style.underlineColor, fg);
    return UvCellPaint(
      foreground: fg,
      background: bg,
      underlineColor: underline,
    );
  }

  /// Resolves a UV color against [fallback], including basic16 and indexed256.
  UvRgb resolveColor(UvColor? color, UvRgb fallback) {
    if (color == null) return fallback;
    final index = switch (color) {
      UvRgb() => null,
      UvBasic16 c when c.index >= 0 && c.index <= 7 =>
        c.index + (c.bright ? 8 : 0),
      UvIndexed256 c when c.index >= 0 && c.index <= 255 => c.index,
      _ => throw ArgumentError('Invalid terminal palette color'),
    };
    if (index == null) return color as UvRgb;
    if (palette != null && index < palette!.length) return palette![index];
    if (index < 16) return _ansiPalette[index];
    if (index >= 232) {
      final v = 8 + (index - 232) * 10;
      return UvRgb(v, v, v);
    }
    final n = index - 16;
    int level(int v) => v == 0 ? 0 : 55 + v * 40;
    return UvRgb(level(n ~/ 36), level((n ~/ 6) % 6), level(n % 6));
  }
}

/// Effective colors for one cell, after attributes and palette resolution.
final class UvCellPaint {
  const UvCellPaint({
    required this.foreground,
    required this.background,
    required this.underlineColor,
  });
  final UvRgb foreground;
  final UvRgb background;
  final UvRgb underlineColor;
}

UvRgb _mix(UvRgb a, UvRgb b, double amount) => UvRgb(
  (a.r * (1 - amount) + b.r * amount).round(),
  (a.g * (1 - amount) + b.g * amount).round(),
  (a.b * (1 - amount) + b.b * amount).round(),
  a: a.a,
);

const _ansiPalette = <UvRgb>[
  UvRgb(0, 0, 0),
  UvRgb(128, 0, 0),
  UvRgb(0, 128, 0),
  UvRgb(128, 128, 0),
  UvRgb(0, 0, 128),
  UvRgb(128, 0, 128),
  UvRgb(0, 128, 128),
  UvRgb(192, 192, 192),
  UvRgb(128, 128, 128),
  UvRgb(255, 0, 0),
  UvRgb(0, 255, 0),
  UvRgb(255, 255, 0),
  UvRgb(0, 0, 255),
  UvRgb(255, 0, 255),
  UvRgb(0, 255, 255),
  UvRgb(255, 255, 255),
];
