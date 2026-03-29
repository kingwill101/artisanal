/// Color effects and filter utilities for UV buffers.
///
/// This module provides a reusable [ColorMatrix] primitive plus
/// [ColorMatrixFilter], which plugs into the existing [BufferFilter] pipeline.
/// Effects operate on cell style colors (foreground/background/underline) while
/// preserving glyph content, width, links, and drawables.
library;

import '../colorprofile/convert.dart' as cp;
import 'buffer.dart';
import 'cell.dart';
import 'filters.dart';

/// A 4x5 RGBA color matrix.
///
/// Values are stored row-major:
///
/// - row 0 transforms red
/// - row 1 transforms green
/// - row 2 transforms blue
/// - row 3 transforms alpha
///
/// Each row contains four coefficients plus one additive bias term.
final class ColorMatrix {
  ColorMatrix(List<double> values)
    : _values = List<double>.unmodifiable(values) {
    if (values.length != 20) {
      throw ArgumentError.value(
        values.length,
        'values',
        'ColorMatrix requires exactly 20 coefficients.',
      );
    }
  }

  final List<double> _values;

  /// The raw row-major coefficients.
  List<double> get values => _values;

  /// Returns whether this matrix is effectively the identity transform.
  bool get isIdentity {
    const identity = <double>[
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    for (var i = 0; i < identity.length; i++) {
      if ((_values[i] - identity[i]).abs() > 1e-9) return false;
    }
    return true;
  }

  /// The identity color transform.
  static final ColorMatrix identity = ColorMatrix(const <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  /// Returns a grayscale transform using sRGB luminance coefficients.
  factory ColorMatrix.grayscale() {
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;
    return ColorMatrix(const <double>[
      r,
      g,
      b,
      0,
      0,
      r,
      g,
      b,
      0,
      0,
      r,
      g,
      b,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  /// Returns an invert transform.
  factory ColorMatrix.invert() {
    return ColorMatrix(const <double>[
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  /// Returns a gain transform that scales RGB channels by [amount].
  factory ColorMatrix.gain(double amount) {
    final factor = amount.clamp(0.0, double.infinity);
    return ColorMatrix(<double>[
      factor,
      0,
      0,
      0,
      0,
      0,
      factor,
      0,
      0,
      0,
      0,
      0,
      factor,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  /// Returns an attenuation transform that scales RGB channels by [amount].
  factory ColorMatrix.attenuation(double amount) {
    return ColorMatrix.gain(amount.clamp(0.0, 1.0));
  }

  /// Returns a tint transform that blends colors toward [tint].
  factory ColorMatrix.tint(UvColor tint, {double amount = 0.5}) {
    final resolved = _resolveRgb(tint);
    final factor = amount.clamp(0.0, 1.0);
    if (resolved == null || factor <= 0) return identity;
    final keep = 1.0 - factor;
    return ColorMatrix(<double>[
      keep,
      0,
      0,
      0,
      resolved.r * factor,
      0,
      keep,
      0,
      0,
      resolved.g * factor,
      0,
      0,
      keep,
      0,
      resolved.b * factor,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  /// Returns a multiply-style transform using [color] as the multiplier.
  factory ColorMatrix.multiply(UvColor color) {
    final resolved = _resolveRgb(color);
    if (resolved == null) return identity;
    return ColorMatrix(<double>[
      resolved.r / 255.0,
      0,
      0,
      0,
      0,
      0,
      resolved.g / 255.0,
      0,
      0,
      0,
      0,
      0,
      resolved.b / 255.0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  /// Applies this matrix to [style].
  UvStyle transformStyle(
    UvStyle style, {
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    if (style.isZero || isIdentity) return style;
    final fg = foreground ? transformColor(style.fg) : style.fg;
    final bg = background ? transformColor(style.bg) : style.bg;
    final uc = underlineColor
        ? transformColor(style.underlineColor)
        : style.underlineColor;
    if (fg == style.fg && bg == style.bg && uc == style.underlineColor) {
      return style;
    }
    return UvStyle(
      fg: fg,
      bg: bg,
      underlineColor: uc,
      underline: style.underline,
      attrs: style.attrs,
    );
  }

  /// Applies this matrix to [color].
  ///
  /// Palette and indexed colors are resolved to truecolor before the transform
  /// is applied.
  UvColor? transformColor(UvColor? color) {
    if (color == null || isIdentity) return color;
    final rgb = _resolveRgb(color);
    if (rgb == null) return color;
    return _transformRgb(rgb);
  }

  UvRgb _transformRgb(UvRgb color) {
    final r = color.r.toDouble();
    final g = color.g.toDouble();
    final b = color.b.toDouble();
    final a = color.a.toDouble();
    return UvRgb(
      _transformRow(0, r, g, b, a),
      _transformRow(5, r, g, b, a),
      _transformRow(10, r, g, b, a),
      a: _transformRow(15, r, g, b, a),
    );
  }

  int _transformRow(int offset, double r, double g, double b, double a) {
    final result =
        (_values[offset] * r) +
        (_values[offset + 1] * g) +
        (_values[offset + 2] * b) +
        (_values[offset + 3] * a) +
        _values[offset + 4];
    return result.round().clamp(0, 255);
  }
}

/// A [BufferFilter] that applies a [ColorMatrix] to cell style colors.
final class ColorMatrixFilter extends BufferFilter {
  ColorMatrixFilter(
    this.matrix, {
    this.foreground = true,
    this.background = true,
    this.underlineColor = true,
  });

  final ColorMatrix matrix;
  final bool foreground;
  final bool background;
  final bool underlineColor;

  @override
  void apply(Buffer source, Buffer target, double dt) {
    final width = source.width();
    final height = source.height();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = source.lines[y].at(x);
        if (cell == null) continue;
        final transformed = _transformCell(cell);
        target.lines[y].replace(x, transformed);
      }
    }
  }

  Cell _transformCell(Cell cell) {
    final style = matrix.transformStyle(
      cell.style,
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
    if (style == cell.style) return cell.clone();
    final cloned = cell.clone();
    cloned.style = style;
    return cloned;
  }
}

UvRgb? _resolveRgb(UvColor? color) {
  return switch (color) {
    null => null,
    UvRgb() => color,
    UvBasic16(:final index, :final bright) => _toUvRgb(
      cp.ansi256ToRgb((index.clamp(0, 7)) + (bright ? 8 : 0)),
    ),
    UvIndexed256(:final index) => _toUvRgb(cp.ansi256ToRgb(index)),
  };
}

UvRgb _toUvRgb(cp.Rgb rgb) => UvRgb(rgb.r, rgb.g, rgb.b);
