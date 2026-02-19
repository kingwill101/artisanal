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

import 'buffer.dart';
import 'cell.dart';

/// Base class for buffer filters.
abstract class BufferFilter {
  void apply(Buffer source, Buffer target, double dt);
}

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
