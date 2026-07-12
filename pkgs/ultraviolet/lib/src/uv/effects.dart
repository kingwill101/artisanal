/// Color effects and filter utilities for UV buffers.
///
/// This module provides a reusable [ColorMatrix] primitive plus
/// [ColorMatrixFilter], which plugs into the existing [BufferFilter] pipeline.
/// It also exposes named built-in effect filters such as
/// [ColorMatrixFilter.grayscale] and [ColorMatrixFilter.tint].
///
/// Effects operate on cell style colors (foreground/background/underline) while
/// preserving glyph content, width, links, and drawables.
library;

import 'dart:typed_data' show Float32x4;

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

  /// Returns a matrix that applies this transform before [next].
  ColorMatrix followedBy(ColorMatrix next) {
    if (isIdentity) return next;
    if (next.isIdentity) return this;

    final result = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      final nextOffset = row * 5;
      final outOffset = row * 5;
      for (var col = 0; col < 4; col++) {
        result[outOffset + col] =
            (next._values[nextOffset] * _values[col]) +
            (next._values[nextOffset + 1] * _values[5 + col]) +
            (next._values[nextOffset + 2] * _values[10 + col]) +
            (next._values[nextOffset + 3] * _values[15 + col]);
      }
      result[outOffset + 4] =
          next._values[nextOffset + 4] +
          (next._values[nextOffset] * _values[4]) +
          (next._values[nextOffset + 1] * _values[9]) +
          (next._values[nextOffset + 2] * _values[14]) +
          (next._values[nextOffset + 3] * _values[19]);
    }
    return ColorMatrix(result);
  }

  /// Collapses [matrices] into a single matrix in application order.
  static ColorMatrix compose(Iterable<ColorMatrix> matrices) {
    var combined = identity;
    for (final matrix in matrices) {
      combined = combined.followedBy(matrix);
    }
    return combined;
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
    return _transformRgbaF64(r, g, b, a);
  }

  /// SIMD-accelerated single-pixel RGBA transform using Float32x4.
  UvRgb _transformRgbaF64(double r, double g, double b, double a) {
    // Pack RGBA into one Float32x4 for lane-wise dot products.
    final rgba = Float32x4(r, g, b, a);

    // Each row of the 4×4 linear transform (skip bias terms).
    final row0 = Float32x4(_values[0], _values[1], _values[2], _values[3]);
    final row1 = Float32x4(_values[5], _values[6], _values[7], _values[8]);
    final row2 = Float32x4(_values[10], _values[11], _values[12], _values[13]);
    final row3 = Float32x4(_values[15], _values[16], _values[17], _values[18]);

    // Lane-wise multiply: rgba * row → (r×m0, g×m1, b×m2, a×m3)
    // Horizontal sum via shuffle: (x+y+z+w) = (x+z) + (y+w)
    int dot(Float32x4 row, double bias) {
      final p = rgba * row;
      // Shuffle: (x, y, z, w) ↔ (z, w, x, y) → sum pairs
      final s = p + p.shuffle(Float32x4.zwxy);
      // Now s = (x+z, y+w, z+x, w+y). Shuffle again for (x+z)+(y+w).
      final t = s + s.shuffle(Float32x4.yzwx);
      return (t.x + bias).round().clamp(0, 255);
    }

    return UvRgb(
      dot(row0, _values[4]),
      dot(row1, _values[9]),
      dot(row2, _values[14]),
      a: dot(row3, _values[19]),
    );
  }

  /// Batch-transform RGBA values using Float32x4 SIMD.
  ///
  /// Processes [count] RGBA pixels from the parallel input lists and writes
  /// to the parallel output lists.  Uses Float32x4 to process 4 pixels at
  /// once (SoA layout: one Float32x4 holds a single channel across 4 pixels).
  ///
  /// All lists must have at least [count] elements.
  void batchTransformRgba(
    covariant List<int> rIn,
    covariant List<int> gIn,
    covariant List<int> bIn,
    covariant List<int> aIn,
    covariant List<int> rOut,
    covariant List<int> gOut,
    covariant List<int> bOut,
    covariant List<int> aOut,
    int count,
  ) {
    // Pre-load matrix rows as splatted vectors for the 4×4 linear part.
    final mCol0 = Float32x4.splat(_values[0]);
    final mCol1 = Float32x4.splat(_values[1]);
    final mCol2 = Float32x4.splat(_values[2]);
    final mCol3 = Float32x4.splat(_values[3]);
    final biasR = Float32x4.splat(_values[4]);
    final mCol5 = Float32x4.splat(_values[5]);
    final mCol6 = Float32x4.splat(_values[6]);
    final mCol7 = Float32x4.splat(_values[7]);
    final mCol8 = Float32x4.splat(_values[8]);
    final biasG = Float32x4.splat(_values[9]);
    final mCol10 = Float32x4.splat(_values[10]);
    final mCol11 = Float32x4.splat(_values[11]);
    final mCol12 = Float32x4.splat(_values[12]);
    final mCol13 = Float32x4.splat(_values[13]);
    final biasB = Float32x4.splat(_values[14]);
    final mCol15 = Float32x4.splat(_values[15]);
    final mCol16 = Float32x4.splat(_values[16]);
    final mCol17 = Float32x4.splat(_values[17]);
    final mCol18 = Float32x4.splat(_values[18]);
    final biasA = Float32x4.splat(_values[19]);

    var i = 0;
    for (; i + 3 < count; i += 4) {
      // Load 4 pixels in SoA layout.
      final rr = Float32x4(
        rIn[i].toDouble(),
        rIn[i + 1].toDouble(),
        rIn[i + 2].toDouble(),
        rIn[i + 3].toDouble(),
      );
      final gg = Float32x4(
        gIn[i].toDouble(),
        gIn[i + 1].toDouble(),
        gIn[i + 2].toDouble(),
        gIn[i + 3].toDouble(),
      );
      final bb = Float32x4(
        bIn[i].toDouble(),
        bIn[i + 1].toDouble(),
        bIn[i + 2].toDouble(),
        bIn[i + 3].toDouble(),
      );
      final aa = Float32x4(
        aIn[i].toDouble(),
        aIn[i + 1].toDouble(),
        aIn[i + 2].toDouble(),
        aIn[i + 3].toDouble(),
      );

      // Out = row · (r, g, b, a)^T + bias  (all lanes in parallel).
      final outR = rr * mCol0 + gg * mCol1 + bb * mCol2 + aa * mCol3 + biasR;
      final outG = rr * mCol5 + gg * mCol6 + bb * mCol7 + aa * mCol8 + biasG;
      final outB =
          rr * mCol10 + gg * mCol11 + bb * mCol12 + aa * mCol13 + biasB;
      final outA =
          rr * mCol15 + gg * mCol16 + bb * mCol17 + aa * mCol18 + biasA;

      // Extract lanes back to integers.
      rOut[i] = outR.x.round().clamp(0, 255);
      rOut[i + 1] = outR.y.round().clamp(0, 255);
      rOut[i + 2] = outR.z.round().clamp(0, 255);
      rOut[i + 3] = outR.w.round().clamp(0, 255);

      gOut[i] = outG.x.round().clamp(0, 255);
      gOut[i + 1] = outG.y.round().clamp(0, 255);
      gOut[i + 2] = outG.z.round().clamp(0, 255);
      gOut[i + 3] = outG.w.round().clamp(0, 255);

      bOut[i] = outB.x.round().clamp(0, 255);
      bOut[i + 1] = outB.y.round().clamp(0, 255);
      bOut[i + 2] = outB.z.round().clamp(0, 255);
      bOut[i + 3] = outB.w.round().clamp(0, 255);

      aOut[i] = outA.x.round().clamp(0, 255);
      aOut[i + 1] = outA.y.round().clamp(0, 255);
      aOut[i + 2] = outA.z.round().clamp(0, 255);
      aOut[i + 3] = outA.w.round().clamp(0, 255);
    }

    // Scalar tail for remaining <4 pixels.
    for (; i < count; i++) {
      final pixel = _transformRgbaF64(
        rIn[i].toDouble(),
        gIn[i].toDouble(),
        bIn[i].toDouble(),
        aIn[i].toDouble(),
      );
      rOut[i] = pixel.r;
      gOut[i] = pixel.g;
      bOut[i] = pixel.b;
      aOut[i] = pixel.a;
    }
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

  /// An identity effect that preserves all colors.
  factory ColorMatrixFilter.identity({
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    return ColorMatrixFilter(
      ColorMatrix.identity,
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
  }

  /// A grayscale effect using sRGB luminance coefficients.
  factory ColorMatrixFilter.grayscale({
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    return ColorMatrixFilter(
      ColorMatrix.grayscale(),
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
  }

  /// An invert effect that flips RGB channels.
  factory ColorMatrixFilter.invert({
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    return ColorMatrixFilter(
      ColorMatrix.invert(),
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
  }

  /// A gain effect that scales RGB channels by [amount].
  factory ColorMatrixFilter.gain(
    double amount, {
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    return ColorMatrixFilter(
      ColorMatrix.gain(amount),
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
  }

  /// An attenuation effect that scales RGB channels by [amount].
  factory ColorMatrixFilter.attenuation(
    double amount, {
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    return ColorMatrixFilter(
      ColorMatrix.attenuation(amount),
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
  }

  /// A tint effect that blends colors toward [tint].
  factory ColorMatrixFilter.tint(
    UvColor tint, {
    double amount = 0.5,
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    return ColorMatrixFilter(
      ColorMatrix.tint(tint, amount: amount),
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
  }

  /// A multiply-style effect using [color] as the multiplier.
  factory ColorMatrixFilter.multiply(
    UvColor color, {
    bool foreground = true,
    bool background = true,
    bool underlineColor = true,
  }) {
    return ColorMatrixFilter(
      ColorMatrix.multiply(color),
      foreground: foreground,
      background: background,
      underlineColor: underlineColor,
    );
  }

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

/// Amber monochrome display preset built from the UV filter primitives.
///
/// This approximates a warm monochrome monitor by stacking color grading with
/// mild edge falloff and scanlines.
final class AmberTerminalFilter extends CompositeFilter {
  AmberTerminalFilter({double tint = 0.62, double attenuation = 0.96})
    : super([
        ColorMatrixFilter.grayscale(background: false),
        ColorMatrixFilter.tint(
          const UvRgb(255, 191, 96),
          amount: tint,
          background: false,
        ),
        ColorMatrixFilter.attenuation(attenuation, background: false),
        VignetteFilter(strength: 0.08, roundness: 1.08),
        ScanlineFilter(
          lineStrength: 0.02,
          barStrength: 0.0,
          barSpeed: 0.45,
          barHeightFraction: 0.12,
        ),
      ]);
}

/// Green phosphor display preset with a stronger CRT feel.
final class PhosphorFilter extends CompositeFilter {
  PhosphorFilter({double tint = 0.58, double distortion = 0.08})
    : super([
        ColorMatrixFilter.grayscale(background: false),
        ColorMatrixFilter.tint(
          const UvRgb(120, 255, 160),
          amount: tint,
          background: false,
        ),
        ColorMatrixFilter.attenuation(0.92, background: false),
        WaveDistortionFilter(
          xAmplitude: distortion,
          yAmplitude: distortion * 0.08,
          xFrequency: 0.34,
          yFrequency: 0.2,
          speed: 0.36,
        ),
        VignetteFilter(strength: 0.1, roundness: 1.05),
        ScanlineFilter(
          lineStrength: 0.08,
          barStrength: 0.0,
          barSpeed: 0.5,
          barHeightFraction: 0.12,
        ),
      ]);
}

/// Green phosphor preset with a temporal afterimage trail.
///
/// This layers [GhostingFilter] onto the existing phosphor look so moving text
/// or rapidly changing scenes keep a short-lived persistence trail.
final class PhosphorTrailFilter extends CompositeFilter {
  PhosphorTrailFilter({
    double tint = 0.58,
    double distortion = 0.08,
    double persistence = 0.42,
  }) : super([
         PhosphorFilter(tint: tint, distortion: distortion),
         GhostingFilter(persistence: persistence, currentBoost: 0.02),
       ]);
}

/// Warm monochrome preset with a short-lived persistence trail.
final class AmberTrailFilter extends CompositeFilter {
  AmberTrailFilter({
    double tint = 0.62,
    double attenuation = 0.96,
    double persistence = 0.38,
  }) : super([
         AmberTerminalFilter(tint: tint, attenuation: attenuation),
         GhostingFilter(persistence: persistence, currentBoost: 0.01),
       ]);
}

/// CRT-style preset with a short temporal persistence trail.
final class CrtTrailFilter extends CompositeFilter {
  CrtTrailFilter({
    double distortion = 0.22,
    double vignette = 0.16,
    double scanline = 0.1,
    double rollingBar = 0.08,
    double persistence = 0.32,
  }) : super([
         CrtFilter(
           distortion: distortion,
           vignette: vignette,
           scanline: scanline,
           rollingBar: rollingBar,
         ),
         GhostingFilter(persistence: persistence, currentBoost: 0.0),
       ]);
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
