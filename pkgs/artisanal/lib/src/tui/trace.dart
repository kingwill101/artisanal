/// Debug tracing utilities for TUI rendering and message dispatch.
///
/// Provides structured, span-based tracing with categories for filtering
/// and hierarchical timing. Uses [Stopwatch] for high-resolution timing
/// in hot paths (avoids `DateTime.now()` syscall overhead).
///
/// ## Environment Variables
///
/// - `ARTISANAL_TUI_TRACE=1` — enable tracing (writes to `./traces/`)
/// - `ARTISANAL_TUI_TRACE_PATH=/path/to/file.log` — explicit log path
/// - `ARTISANAL_TUI_TRACE_CAPTURE=1` — enable dispatch capture logging
///
/// ## Usage
///
/// ```dart
/// // Simple tagged log
/// TuiTrace.log('my message', tag: TraceTag.render);
///
/// // Span-based timing (auto-logs duration on end)
/// final span = TuiTrace.begin('view', tag: TraceTag.render);
/// // ... do work ...
/// span.end(); // logs: [render] view 1234us
///
/// // Nested spans
/// final outer = TuiTrace.begin('frame', tag: TraceTag.render);
/// final inner = TuiTrace.begin('layout', tag: TraceTag.layout);
/// inner.end();
/// outer.end();
/// ```
library;

import 'dart:io' as io;

/// Trace categories for filtering and grouping trace output.
///
/// Each tag represents a phase or subsystem in the render pipeline.
enum TraceTag {
  /// Terminal input parsing and message coalescing.
  input,

  /// Message queue management and drain loop.
  queue,

  /// Message dispatch to the widget/element tree.
  dispatch,

  /// Widget tree rebuild (dirty element marking, createElement).
  rebuild,

  /// Layout constraint propagation and size computation.
  layout,

  /// Paint phase (RenderObject.paint → Canvas).
  paint,

  /// View generation (Canvas → ANSI string serialization).
  render,

  /// UV renderer: ANSI string parsing, buffer draw, diff, flush.
  flush,

  /// Focus system operations (register, request, trap).
  focus,

  /// Scroll operations and scroll optimization.
  scroll,

  /// Render metrics and FPS tracking.
  metrics,

  /// Command execution.
  cmd,

  /// General / uncategorized.
  general,
}

/// A timing span for hierarchical tracing.
///
/// Created via [TuiTrace.begin]. Call [end] to log the elapsed duration.
/// Spans are lightweight and allocation-free when tracing is disabled
/// (returns [TraceSpan.noop]).
final class TraceSpan {
  TraceSpan._(this._label, this._tag, this._sw, this._extra) {
    _sw.start();
  }

  /// A no-op span returned when tracing is disabled.
  static final TraceSpan noop = TraceSpan._noop();

  TraceSpan._noop()
    : _label = '',
      _tag = TraceTag.general,
      _sw = Stopwatch(),
      _extra = null;

  final String _label;
  final TraceTag _tag;
  final Stopwatch _sw;
  final String? _extra;
  bool _ended = false;

  /// The elapsed microseconds since the span was created.
  ///
  /// Returns 0 if this is a noop span.
  int get elapsedMicroseconds => _sw.elapsedMicroseconds;

  /// Ends the span and logs the elapsed duration.
  ///
  /// If [extra] is provided, it is appended to the log message.
  /// Calling [end] multiple times is safe — subsequent calls are ignored.
  void end({String? extra}) {
    if (_ended) return;
    _ended = true;
    _sw.stop();
    if (!TuiTrace.enabled) return;
    final parts = StringBuffer();
    parts.write('[${_tag.name}] ');
    parts.write(_label);
    if (_extra != null) {
      parts.write(' $_extra');
    }
    if (extra != null) {
      parts.write(' $extra');
    }
    parts.write(' ${_sw.elapsedMicroseconds}us');
    TuiTrace._writeRaw(parts.toString());
  }
}

/// Lightweight debug tracer for TUI frame rendering and message dispatch.
///
/// All methods are static and gated behind [enabled], which is resolved
/// once from environment variables. When disabled, all methods are no-ops
/// with negligible overhead.
final class TuiTrace {
  static const _flagEnv = 'ARTISANAL_TUI_TRACE';
  static const _pathEnv = 'ARTISANAL_TUI_TRACE_PATH';
  static const _captureEnv = 'ARTISANAL_TUI_TRACE_CAPTURE';

  static String? _path;
  static io.IOSink? _sink;
  static bool? _captureEnabled;
  static bool _resolved = false;

  /// A monotonic stopwatch started when tracing is first enabled.
  ///
  /// Used instead of [DateTime.now()] for timestamps to avoid syscall
  /// overhead in hot paths. The wall-clock start time is recorded once
  /// at initialization for correlation.
  static final Stopwatch _clock = Stopwatch();
  static String? _startWallTime;

  /// Whether trace logging is enabled (set via `ARTISANAL_TUI_TRACE` env var).
  static bool get enabled {
    if (!_resolved) {
      _path = _resolvePath();
      _resolved = true;
      if (_path != null) {
        _clock.start();
        _startWallTime = DateTime.now().toIso8601String();
      }
    }
    return _path != null;
  }

  /// Whether dispatch capture logging is enabled.
  static bool get captureDispatchEnabled {
    if (!enabled) return false;
    _captureEnabled ??= _resolveFlag(_captureEnv);
    return _captureEnabled ?? false;
  }

  /// Writes a timestamped, tagged trace message to the log file.
  ///
  /// [tag] categorizes the message for filtering. Defaults to
  /// [TraceTag.general].
  static void log(String message, {TraceTag tag = TraceTag.general}) {
    if (!enabled) return;
    _writeRaw('[${tag.name}] $message');
  }

  /// Begins a named timing span.
  ///
  /// Returns a [TraceSpan] that logs its duration when [TraceSpan.end]
  /// is called. When tracing is disabled, returns [TraceSpan.noop] to
  /// avoid allocation overhead.
  ///
  /// [extra] is an optional string appended to the log when the span ends.
  static TraceSpan begin(
    String label, {
    TraceTag tag = TraceTag.general,
    String? extra,
  }) {
    if (!enabled) return TraceSpan.noop;
    return TraceSpan._(label, tag, Stopwatch(), extra);
  }

  /// Writes a raw line with a monotonic microsecond timestamp.
  static void _writeRaw(String message) {
    _sink ??= _openSink();
    final us = _clock.elapsedMicroseconds;
    _sink!.writeln('[+${us}us] $message');
  }

  static io.IOSink _openSink() {
    final sink = io.File(_path!).openWrite(mode: io.FileMode.append);
    // Write header with wall-clock correlation.
    sink.writeln('# trace start: $_startWallTime');
    sink.writeln('# timestamps are monotonic microseconds from start');
    return sink;
  }

  /// Closes the trace log file.
  static void close() {
    if (_sink == null) return;
    _sink!.flush();
    _sink!.close();
    _sink = null;
  }

  static String? _resolvePath() {
    final env = io.Platform.environment;
    final path = env[_pathEnv];
    if (path != null && path.isNotEmpty) return path;
    final flag = env[_flagEnv];
    if (flag == null) return null;
    if (_isEnabledFlag(flag)) {
      return _generateDateBasedPath();
    }
    return null;
  }

  /// Generates a date-based trace file path under `./traces/` in the CWD.
  ///
  /// Creates the `traces/` directory if it doesn't exist. The filename is
  /// sortable by date: `artisanal-YYYY-MM-DDTHH-MM-SS.log`.
  static String _generateDateBasedPath() {
    final now = DateTime.now();
    final ts =
        '${now.year.toString().padLeft(4, '0')}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}'
        'T${now.hour.toString().padLeft(2, '0')}'
        '-${now.minute.toString().padLeft(2, '0')}'
        '-${now.second.toString().padLeft(2, '0')}';
    final dir = io.Directory('traces');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return 'traces/artisanal-$ts.log';
  }

  static bool _resolveFlag(String envKey) {
    final flag = io.Platform.environment[envKey];
    if (flag == null) return false;
    return _isEnabledFlag(flag);
  }

  static bool _isEnabledFlag(String flag) {
    final lower = flag.toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes';
  }
}
