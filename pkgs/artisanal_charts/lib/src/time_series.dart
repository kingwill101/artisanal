/// Sliding-window time-series buffers for live charts.
library;

import 'types.dart';

/// Options for [TimeSeriesBuffer] / [MultiSeriesBuffer].
final class TimeSeriesBufferOptions {
  const TimeSeriesBufferOptions({this.windowMs, this.maxPoints});

  /// Sliding window duration in milliseconds (default 60_000).
  final int? windowMs;

  /// Maximum points to keep regardless of time (default unlimited).
  final int? maxPoints;
}

final class _TimestampedValue {
  _TimestampedValue(this.t, this.v);
  final int t;
  final double v;
}

/// Sliding-window buffer of timestamped numeric samples.
final class TimeSeriesBuffer {
  TimeSeriesBuffer([TimeSeriesBufferOptions opts = const TimeSeriesBufferOptions()])
    : _windowMs = opts.windowMs ?? 60000,
      _maxPoints = opts.maxPoints ?? -1;

  final List<_TimestampedValue> _entries = [];
  int _windowMs;
  int _maxPoints;

  int get windowMs => _windowMs;
  set windowMs(int ms) {
    _windowMs = ms;
    _trim();
  }

  int get maxPoints => _maxPoints < 0 ? 1 << 30 : _maxPoints;
  set maxPoints(int n) {
    _maxPoints = n;
    _trim();
  }

  int get length => _entries.length;

  void push(double value, [int? timestamp]) {
    _entries.add(_TimestampedValue(timestamp ?? DateTime.now().millisecondsSinceEpoch, value));
    _trim();
  }

  void pushMany(List<double> values) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final v in values) {
      _entries.add(_TimestampedValue(now, v));
    }
    _trim();
  }

  List<double> getData() {
    _trim();
    return _entries.map((e) => e.v).toList(growable: false);
  }

  List<({int time, double value})> getEntries() {
    _trim();
    return _entries
        .map((e) => (time: e.t, value: e.v))
        .toList(growable: false);
  }

  double? last() => _entries.isEmpty ? null : _entries.last.v;

  ({double min, double max, double avg, int count}) stats() {
    _trim();
    if (_entries.isEmpty) {
      return (min: 0, max: 0, avg: 0, count: 0);
    }
    var min = double.infinity;
    var max = double.negativeInfinity;
    var sum = 0.0;
    for (final e in _entries) {
      if (e.v < min) min = e.v;
      if (e.v > max) max = e.v;
      sum += e.v;
    }
    return (
      min: min,
      max: max,
      avg: sum / _entries.length,
      count: _entries.length,
    );
  }

  void clear() => _entries.clear();

  void _trim() {
    final cutoff = DateTime.now().millisecondsSinceEpoch - _windowMs;
    while (_entries.isNotEmpty && _entries.first.t < cutoff) {
      _entries.removeAt(0);
    }
    final cap = _maxPoints < 0 ? 1 << 30 : _maxPoints;
    while (_entries.length > cap) {
      _entries.removeAt(0);
    }
  }
}

/// Manages multiple named [TimeSeriesBuffer]s with a shared window.
final class MultiSeriesBuffer {
  MultiSeriesBuffer([TimeSeriesBufferOptions opts = const TimeSeriesBufferOptions()])
    : _windowMs = opts.windowMs ?? 60000,
      _maxPoints = opts.maxPoints ?? -1;

  final Map<String, TimeSeriesBuffer> _buffers = {};
  int _windowMs;
  int _maxPoints;

  TimeSeriesBuffer series(String name) {
    return _buffers.putIfAbsent(
      name,
      () => TimeSeriesBuffer(
        TimeSeriesBufferOptions(windowMs: _windowMs, maxPoints: _maxPoints < 0 ? null : _maxPoints),
      ),
    );
  }

  void push(String name, double value, [int? timestamp]) {
    series(name).push(value, timestamp);
  }

  List<DataSeries> toDataSeries([Map<String, String>? colorMap]) {
    return _buffers.entries
        .map(
          (e) => DataSeries(
            name: e.key,
            data: e.value.getData(),
            color: colorMap?[e.key],
          ),
        )
        .toList(growable: false);
  }

  set windowMs(int ms) {
    _windowMs = ms;
    for (final buf in _buffers.values) {
      buf.windowMs = ms;
    }
  }

  int get windowMs => _windowMs;

  void clear() {
    for (final buf in _buffers.values) {
      buf.clear();
    }
  }

  List<String> get names => _buffers.keys.toList(growable: false);
}
