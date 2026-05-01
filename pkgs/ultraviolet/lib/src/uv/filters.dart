/// Buffer filters and render sink utilities for UV.
///
/// Use [BufferRenderSink] to render into a custom buffer target, then apply
/// a stack of [BufferFilter]s (e.g., [LiquifyFilter]) before sending the
/// final buffer to the terminal renderer.
///
/// Example:
/// ```dart
/// final sink = BufferRenderSink(width: 80, height: 24);
/// final liquify = LiquifyFilter(strength: 1.2);
/// final filtered = sink.render(sourceBuffer, [liquify], dt: 1 / 60);
/// renderer.render(filtered);
/// renderer.flush();
/// ```
library;

import 'dart:math' as math;

import '../colorprofile/convert.dart' as cp;
import 'buffer.dart';
import 'cell.dart';

/// Base class for buffer filters.
abstract class BufferFilter {
  void apply(Buffer source, Buffer target, double dt);
}

/// Runs multiple filters as one reusable filter.
///
/// This is useful for packaging opinionated looks such as CRT-style or
/// atmosphere-style presets without requiring every caller to manually build a
/// filter stack at each render site.
class CompositeFilter extends BufferFilter {
  CompositeFilter(List<BufferFilter> filters)
    : filters = List<BufferFilter>.unmodifiable(filters);

  final List<BufferFilter> filters;

  Buffer? _front;
  Buffer? _back;

  @override
  void apply(Buffer source, Buffer target, double dt) {
    if (filters.isEmpty) {
      _copyBuffer(source, target);
      return;
    }

    _ensureScratch(source.width(), source.height());
    var read = source;
    var useFront = true;

    for (var i = 0; i < filters.length; i++) {
      final filter = filters[i];
      final isLast = i == filters.length - 1;
      final write = isLast ? target : (useFront ? _front! : _back!);
      write.clear();
      filter.apply(read, write, dt);
      if (!isLast) {
        read = write;
        useFront = !useFront;
      }
    }
  }

  void _ensureScratch(int width, int height) {
    if (_front == null ||
        _front!.width() != width ||
        _front!.height() != height) {
      _front = Buffer.create(width, height);
      _back = Buffer.create(width, height);
    }
  }
}

/// Signature for position-aware intensity curves used by spatial filters.
typedef BufferFalloff =
    double Function({
      required double normalizedDistance,
      required int x,
      required int y,
      required int width,
      required int height,
    });

/// Signature for custom buffer allocation.
typedef BufferFactory = Buffer Function(int width, int height);

/// A render sink that owns double-buffered render targets.
///
/// This lets you customize render targets (via [bufferFactory]) and apply
/// filters without mutating the original [Buffer].
final class BufferRenderSink {
  BufferRenderSink({
    int width = 0,
    int height = 0,
    BufferFactory? bufferFactory,
  }) : _bufferFactory = bufferFactory ?? Buffer.create {
    _front = _bufferFactory(width, height);
    _back = _bufferFactory(width, height);
  }

  final BufferFactory _bufferFactory;
  late Buffer _front;
  late Buffer _back;

  /// The last rendered buffer (front buffer).
  Buffer get buffer => _front;

  /// Resize internal buffers.
  void resize(int width, int height) {
    _front.resize(width, height);
    _back.resize(width, height);
  }

  /// Render [source] through [filters] into this sink.
  Buffer render(Buffer source, List<BufferFilter> filters, {double dt = 0}) {
    final width = source.width();
    final height = source.height();
    if (_front.width() != width || _front.height() != height) {
      resize(width, height);
    }

    if (filters.isEmpty) {
      _front.clear();
      _copyBuffer(source, _front);
      return _front;
    }

    var read = source;
    var write = _front;

    for (final filter in filters) {
      write.clear();
      filter.apply(read, write, dt);
      final tmp = read;
      read = write;
      write = (write == _front) ? _back : _front;
      if (identical(tmp, source)) {
        // noop: helps clarity when reading the pipeline loop
      }
    }

    if (!identical(read, _front)) {
      final tmp = _front;
      _front = _back;
      _back = tmp;
    }

    return _front;
  }
}

/// A simple velocity-field liquify filter.
///
/// This is intentionally lightweight: it displaces cells based on a
/// damped noise field. Use [strength] to increase distortion.
final class LiquifyFilter extends BufferFilter {
  LiquifyFilter({
    this.strength = 1.0,
    this.damping = 0.9,
    this.noise = 0.35,
    this.flow = 0.8,
    int? seed,
  }) : _rng = math.Random(seed);

  final double strength;
  final double damping;
  final double noise;
  final double flow;
  final math.Random _rng;

  int _width = 0;
  int _height = 0;
  double _time = 0;
  List<double> _vx = const [];
  List<double> _vy = const [];

  void _ensure(int width, int height) {
    if (width == _width && height == _height) return;
    _width = width;
    _height = height;
    _vx = List<double>.filled(width * height, 0);
    _vy = List<double>.filled(width * height, 0);
  }

  @override
  void apply(Buffer source, Buffer target, double dt) {
    final width = source.width();
    final height = source.height();
    if (width <= 0 || height <= 0) return;
    _ensure(width, height);

    final timeStep = dt <= 0 ? 1 / 60 : dt;
    _time += timeStep;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final nx = math.sin(x * 0.15 + y * 0.07 + _time * 1.3);
        final ny = math.cos(y * 0.17 + x * 0.05 + _time * 1.1);
        final jitterX = (_rng.nextDouble() * 2 - 1) * noise;
        final jitterY = (_rng.nextDouble() * 2 - 1) * noise;
        _vx[i] = (_vx[i] * damping) + (nx * flow + jitterX) * timeStep;
        _vy[i] = (_vy[i] * damping) + (ny * flow + jitterY) * timeStep;
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final dx = _vx[i] * strength;
        final dy = _vy[i] * strength;
        final sx = (x + dx).round().clamp(0, width - 1);
        final sy = (y + dy).round().clamp(0, height - 1);
        final cell = source.cellAt(sx, sy);
        if (cell == null || cell.width == 0) {
          target.setCell(x, y, Cell.emptyCell());
        } else {
          target.setCell(x, y, cell);
        }
      }
    }
  }
}

/// Darkens the edges of the frame while preserving the center.
///
/// This is useful for modal backdrops, camera-like framing, and scene focus.
/// [strength] controls the maximum edge attenuation, while [roundness] lets
/// callers bias the shape toward a circle (`1.0`) or a wider terminal frame.
final class VignetteFilter extends BufferFilter {
  VignetteFilter({
    this.strength = 0.35,
    this.roundness = 1.0,
    BufferFalloff? falloff,
  }) : falloff = falloff ?? _defaultVignetteFalloff;

  /// Maximum edge attenuation in the range `0.0..1.0`.
  final double strength;

  /// Horizontal shape bias. Values above `1.0` stretch the vignette wider.
  final double roundness;

  /// Custom falloff curve for advanced shaping.
  final BufferFalloff falloff;

  @override
  void apply(Buffer source, Buffer target, double dt) {
    final width = source.width();
    final height = source.height();
    if (width <= 0 || height <= 0) return;

    final clampedStrength = strength.clamp(0.0, 1.0);
    if (clampedStrength <= 0) {
      _copyBuffer(source, target);
      return;
    }

    final centerX = (width - 1) / 2.0;
    final centerY = (height - 1) / 2.0;
    final scaleX = math.max(0.0001, centerX * roundness.clamp(0.1, 4.0));
    final scaleY = math.max(0.0001, centerY);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = source.cellAt(x, y);
        if (cell == null) continue;

        final dx = (x - centerX) / scaleX;
        final dy = (y - centerY) / scaleY;
        final distance = math.min(1.0, math.sqrt(dx * dx + dy * dy));
        final attenuation =
            1.0 -
            (clampedStrength *
                falloff(
                  normalizedDistance: distance,
                  x: x,
                  y: y,
                  width: width,
                  height: height,
                ).clamp(0.0, 1.0));
        target.setCell(x, y, _scaleCell(cell, attenuation));
      }
    }
  }
}

/// Adds alternating scanline attenuation with an optional animated rolling bar.
///
/// The filter keeps glyph content intact but modulates cell colors to evoke a
/// CRT-style pass. Use [barStrength] and [barSpeed] to animate a brighter band
/// sweeping vertically through the frame.
final class ScanlineFilter extends BufferFilter {
  ScanlineFilter({
    this.lineStrength = 0.14,
    this.barStrength = 0.18,
    this.barSpeed = 0.9,
    this.barHeightFraction = 0.22,
  });

  /// Alternating row attenuation in the range `0.0..1.0`.
  final double lineStrength;

  /// Additional brightness applied inside the rolling bar.
  final double barStrength;

  /// Vertical speed of the rolling bar, in screens per second.
  final double barSpeed;

  /// Height of the rolling bar as a fraction of the frame height.
  final double barHeightFraction;

  double _phase = 0.0;

  @override
  void apply(Buffer source, Buffer target, double dt) {
    final width = source.width();
    final height = source.height();
    if (width <= 0 || height <= 0) return;

    final effectiveDt = dt <= 0 ? 1 / 60 : dt;
    _phase = (_phase + effectiveDt * barSpeed).remainder(1.0);
    final bandHeight = math.max(
      1.0,
      height * barHeightFraction.clamp(0.02, 1.0),
    );
    final centerY = _phase * height;

    for (var y = 0; y < height; y++) {
      final scanlineFactor = y.isEven
          ? 1.0
          : 1.0 - lineStrength.clamp(0.0, 1.0);
      final distanceToBand = (y - centerY).abs();
      final bandBoost =
          _rollingBand(distanceToBand, bandHeight) *
          barStrength.clamp(0.0, 1.0);
      final factor = (scanlineFactor + bandBoost).clamp(0.0, 2.0);

      for (var x = 0; x < width; x++) {
        final cell = source.cellAt(x, y);
        if (cell == null) continue;
        target.setCell(x, y, _scaleCell(cell, factor));
      }
    }
  }
}

/// Applies a deterministic sine-wave distortion across the buffer.
///
/// Unlike [LiquifyFilter], this effect is stable and repeatable for a given
/// configuration, which makes it a better fit for stylized transitions,
/// underwater shimmer, or low-cost heat-haze style motion.
final class WaveDistortionFilter extends BufferFilter {
  WaveDistortionFilter({
    this.xAmplitude = 1.0,
    this.yAmplitude = 0.0,
    this.xFrequency = 0.55,
    this.yFrequency = 0.35,
    this.speed = 1.0,
    this.phase = 0.0,
  });

  /// Horizontal displacement in terminal cells.
  final double xAmplitude;

  /// Vertical displacement in terminal cells.
  final double yAmplitude;

  /// Frequency used for the vertical-to-horizontal wave lookup.
  final double xFrequency;

  /// Frequency used for the horizontal-to-vertical wave lookup.
  final double yFrequency;

  /// Phase advance in cycles per second.
  final double speed;

  /// Initial phase offset in radians.
  final double phase;

  double _time = 0.0;

  @override
  void apply(Buffer source, Buffer target, double dt) {
    final width = source.width();
    final height = source.height();
    if (width <= 0 || height <= 0) return;

    final effectiveDt = dt <= 0 ? 1 / 60 : dt;
    _time += effectiveDt;
    final phaseOffset = phase + (_time * speed * math.pi * 2.0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final dx = math.sin((y * xFrequency) + phaseOffset) * xAmplitude;
        final dy = math.sin((x * yFrequency) + phaseOffset * 0.73) * yAmplitude;
        final sx = (x + dx).round().clamp(0, width - 1);
        final sy = (y + dy).round().clamp(0, height - 1);
        final cell = source.cellAt(sx, sy);
        if (cell == null || cell.width == 0) {
          target.setCell(x, y, Cell.emptyCell());
        } else {
          target.setCell(x, y, cell);
        }
      }
    }
  }
}

/// Preserves a fading afterimage of recent glyphs.
///
/// This is intended for text-oriented terminal scenes where a light phosphor
/// trail or motion ghost can add atmosphere without smearing backgrounds.
/// Only visible glyph cells persist; empty source cells can briefly inherit a
/// dimmed copy of the previous rendered glyph.
final class GhostingFilter extends BufferFilter {
  GhostingFilter({this.persistence = 0.45, this.currentBoost = 0.08});

  /// Color retention applied to trailing glyphs.
  final double persistence;

  /// Optional brightness boost for currently visible glyphs.
  final double currentBoost;

  Buffer? _history;

  @override
  void apply(Buffer source, Buffer target, double dt) {
    final width = source.width();
    final height = source.height();
    if (width <= 0 || height <= 0) return;

    _ensureHistory(width, height);
    final retained = persistence.clamp(0.0, 1.0);
    final liveBoost = currentBoost.clamp(0.0, 1.0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final current = source.cellAt(x, y) ?? Cell.emptyCell();
        final previous = _history!.cellAt(x, y) ?? Cell.emptyCell();

        if (_isVisibleGlyph(current)) {
          final output = liveBoost <= 0
              ? current
              : _scaleCellChannels(current, 1.0 + liveBoost, background: false);
          target.setCell(x, y, output);
          continue;
        }

        if (_isVisibleGlyph(previous) && retained > 0) {
          final ghost = _scaleCellChannels(
            previous,
            retained,
            background: false,
          );
          target.setCell(
            x,
            y,
            Cell(
              content: ghost.content,
              width: ghost.width,
              style: ghost.style.copyWith(clearBg: true),
              link: ghost.link,
              drawable: ghost.drawable,
            ),
          );
          continue;
        }

        target.setCell(x, y, current);
      }
    }

    _history!
      ..clear()
      ..clearDirtyTracking();
    _copyBuffer(target, _history!);
    _history!.clearDirtyTracking();
  }

  void _ensureHistory(int width, int height) {
    if (_history == null ||
        _history!.width() != width ||
        _history!.height() != height) {
      _history = Buffer.create(width, height);
    }
  }
}

/// Opinionated CRT-style preset built from the UV filter primitives.
///
/// This combines mild distortion, edge falloff, and animated scanlines into a
/// single reusable effect surface.
final class CrtFilter extends CompositeFilter {
  CrtFilter({
    double distortion = 0.22,
    double vignette = 0.16,
    double scanline = 0.1,
    double rollingBar = 0.08,
  }) : super([
         WaveDistortionFilter(
           xAmplitude: distortion,
           yAmplitude: distortion * 0.14,
           xFrequency: 0.38,
           yFrequency: 0.22,
           speed: 0.45,
         ),
         VignetteFilter(strength: vignette, roundness: 1.1),
         ScanlineFilter(
           lineStrength: scanline,
           barStrength: rollingBar,
           barSpeed: 0.48,
           barHeightFraction: 0.12,
         ),
       ]);
}

/// Soft atmosphere-style preset for shimmer/backdrop motion.
///
/// This is gentler than [CrtFilter] and intended for modal backdrops or scene
/// ambience rather than explicit display emulation.
final class AtmosphereFilter extends CompositeFilter {
  AtmosphereFilter({double distortion = 0.12, double vignette = 0.06})
    : super([
        WaveDistortionFilter(
          xAmplitude: distortion,
          yAmplitude: distortion * 0.05,
          xFrequency: 0.24,
          yFrequency: 0.14,
          speed: 0.16,
          phase: math.pi / 6,
        ),
        VignetteFilter(
          strength: vignette,
          roundness: 1.25,
          falloff: _atmosphereVignetteFalloff,
        ),
      ]);
}

double _defaultVignetteFalloff({
  required double normalizedDistance,
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  return normalizedDistance * normalizedDistance;
}

double _rollingBand(double distanceToBand, double bandHeight) {
  if (distanceToBand >= bandHeight) return 0.0;
  final t = 1.0 - (distanceToBand / bandHeight);
  return t * t;
}

double _atmosphereVignetteFalloff({
  required double normalizedDistance,
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  return normalizedDistance * normalizedDistance * normalizedDistance;
}

Cell _scaleCell(Cell cell, double factor) {
  return _scaleCellChannels(cell, factor);
}

Cell _scaleCellChannels(
  Cell cell,
  double factor, {
  bool foreground = true,
  bool background = true,
  bool underline = true,
}) {
  if (cell.style.isZero) {
    return cell;
  }
  final fg = foreground ? _scaleColor(cell.style.fg, factor) : cell.style.fg;
  final bg = background ? _scaleColor(cell.style.bg, factor) : cell.style.bg;
  final underlineColor = underline
      ? _scaleColor(cell.style.underlineColor, factor)
      : cell.style.underlineColor;
  if (fg == cell.style.fg &&
      bg == cell.style.bg &&
      underlineColor == cell.style.underlineColor) {
    return cell;
  }
  return Cell(
    content: cell.content,
    style: UvStyle(
      fg: fg,
      bg: bg,
      underlineColor: underlineColor,
      underline: cell.style.underline,
      attrs: cell.style.attrs,
    ),
    link: cell.link,
    drawable: cell.drawable,
    width: cell.width,
  );
}

UvColor? _scaleColor(UvColor? color, double factor) {
  if (color == null) return null;
  final clamped = factor.clamp(0.0, 2.0);
  return switch (color) {
    UvRgb(:final r, :final g, :final b, :final a) => UvRgb(
      (r * clamped).round().clamp(0, 255),
      (g * clamped).round().clamp(0, 255),
      (b * clamped).round().clamp(0, 255),
      a: a,
    ),
    UvBasic16(:final index, :final bright) => () {
      final rgb = cp.ansi256ToRgb(index + (bright ? 8 : 0));
      return UvRgb(
        (rgb.r * clamped).round().clamp(0, 255),
        (rgb.g * clamped).round().clamp(0, 255),
        (rgb.b * clamped).round().clamp(0, 255),
      );
    }(),
    UvIndexed256(:final index) => () {
      final rgb = cp.ansi256ToRgb(index);
      return UvRgb(
        (rgb.r * clamped).round().clamp(0, 255),
        (rgb.g * clamped).round().clamp(0, 255),
        (rgb.b * clamped).round().clamp(0, 255),
      );
    }(),
  };
}

bool _isVisibleGlyph(Cell cell) =>
    cell.width > 0 && cell.content.trim().isNotEmpty;

void _copyBuffer(Buffer source, Buffer target) {
  final width = source.width();
  final height = source.height();
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final cell = source.cellAt(x, y);
      if (cell == null) continue;
      if (cell.width == 0) continue; // avoid clearing wide cells
      target.setCell(x, y, cell);
    }
  }
}
