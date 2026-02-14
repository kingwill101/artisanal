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
/// - `ARTISANAL_TUI_TRACE_TAGS=input,dispatch` — optional tag allow-list
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

import 'dart:convert';
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

/// Structured trace event names emitted by [TuiTrace.event].
final class TraceEventType {
  const TraceEventType._();

  /// Batch of parsed input messages from either the UV or key parser.
  static const String inputBatch = 'input.batch';

  /// Terminal window size observed by the runtime.
  static const String windowSize = 'window.size';
}

/// A structured event decoded from one trace log line.
final class TraceEventRecord {
  const TraceEventRecord({
    required this.timestampUs,
    required this.tag,
    required this.type,
    required this.fields,
  });

  /// Monotonic timestamp from trace start.
  final int timestampUs;

  /// Log tag for this event line.
  final TraceTag tag;

  /// Event type string (for example [TraceEventType.inputBatch]).
  final String type;

  /// Event payload fields excluding protocol metadata.
  final Map<String, Object?> fields;
}

final class _ParsedTraceLine {
  const _ParsedTraceLine({
    required this.timestampUs,
    required this.tag,
    required this.message,
  });

  final int timestampUs;
  final TraceTag tag;
  final String message;
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
    if (!TuiTrace.enabled || !TuiTrace.isTagEnabled(_tag)) return;
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
  static const _tagsEnv = 'ARTISANAL_TUI_TRACE_TAGS';
  static const _eventMarker = '@event ';
  static const _eventSchemaVersion = 1;

  static String? _path;
  static io.File? _file;
  static bool _headerWritten = false;
  static bool? _captureEnabled;
  static String? _tagsRaw;
  static Set<TraceTag>? _enabledTags;
  static bool _resolved = false;
  static final Map<String, TraceTag> _traceTagByName = <String, TraceTag>{
    for (final tag in TraceTag.values) tag.name: tag,
  };

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
        _tagsRaw = io.Platform.environment[_tagsEnv];
        _enabledTags = _resolveTagFilter(_tagsRaw);
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

  /// Whether logs for [tag] are currently enabled.
  ///
  /// When `ARTISANAL_TUI_TRACE_TAGS` is unset, all tags are enabled.
  static bool isTagEnabled(TraceTag tag) {
    if (!enabled) return false;
    final enabledTags = _enabledTags;
    if (enabledTags == null) return true;
    return enabledTags.contains(tag);
  }

  /// Writes a timestamped, tagged trace message to the log file.
  ///
  /// [tag] categorizes the message for filtering. Defaults to
  /// [TraceTag.general].
  static void log(String message, {TraceTag tag = TraceTag.general}) {
    if (!enabled || !isTagEnabled(tag)) return;
    _writeRaw('[${tag.name}] $message');
  }

  /// Writes a structured trace event payload.
  ///
  /// The output line format is stable and machine-parseable:
  /// `"[+123us] [input] @event {\"v\":1,\"type\":\"...\",...}"`.
  static void event(
    String type, {
    TraceTag tag = TraceTag.general,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!enabled || !isTagEnabled(tag)) return;
    if (type.trim().isEmpty) return;
    final payload = <String, Object?>{
      'v': _eventSchemaVersion,
      'type': type,
      ...fields,
    };
    _writeRaw('[${tag.name}] $_eventMarker${jsonEncode(payload)}');
  }

  /// Parses one trace line into [TraceEventRecord] when it contains
  /// a structured event emitted by [event].
  ///
  /// Returns `null` when the line is not an event line or is malformed.
  static TraceEventRecord? tryParseEventLine(String line) {
    final parsedLine = _parseLine(line);
    if (parsedLine == null) return null;
    final message = parsedLine.message;
    if (!message.startsWith(_eventMarker)) return null;

    final jsonPayload = message.substring(_eventMarker.length);
    final decoded = _decodeJsonObject(jsonPayload);
    if (decoded == null) return null;

    final version = decoded['v'];
    if (version is! num || version.toInt() != _eventSchemaVersion) {
      return null;
    }
    final type = decoded['type'];
    if (type is! String || type.trim().isEmpty) return null;

    final fields = <String, Object?>{};
    for (final entry in decoded.entries) {
      if (entry.key == 'v' || entry.key == 'type') continue;
      fields[entry.key] = entry.value;
    }
    return TraceEventRecord(
      timestampUs: parsedLine.timestampUs,
      tag: parsedLine.tag,
      type: type,
      fields: fields,
    );
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
    if (!enabled || !isTagEnabled(tag)) return TraceSpan.noop;
    return TraceSpan._(label, tag, Stopwatch(), extra);
  }

  /// Writes a raw line with a monotonic microsecond timestamp.
  static void _writeRaw(String message) {
    final file = _file ??= _openFile();
    if (!_headerWritten) {
      _writeHeader(file);
      _headerWritten = true;
    }
    final us = _clock.elapsedMicroseconds;
    file.writeAsStringSync('[+${us}us] $message\n', mode: io.FileMode.append);
  }

  static _ParsedTraceLine? _parseLine(String line) {
    if (!line.startsWith('[+')) return null;
    final tsEnd = line.indexOf('us]');
    if (tsEnd <= 2) return null;
    final timestampUs = int.tryParse(line.substring(2, tsEnd));
    if (timestampUs == null) return null;

    var index = tsEnd + 3; // position after "us]"
    if (index >= line.length || line[index] != ' ') return null;
    index++; // skip space before tag
    if (line[index] != '[') return null;
    final tagEnd = line.indexOf(']', index + 1);
    if (tagEnd <= index + 1) return null;
    final tagName = line.substring(index + 1, tagEnd);
    final tag = _traceTagByName[tagName];
    if (tag == null) return null;

    if (tagEnd + 1 >= line.length || line[tagEnd + 1] != ' ') return null;
    final messageStart = tagEnd + 2;
    if (messageStart > line.length) return null;
    final message = line.substring(messageStart);
    return _ParsedTraceLine(
      timestampUs: timestampUs,
      tag: tag,
      message: message,
    );
  }

  static Map<String, dynamic>? _decodeJsonObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static io.File _openFile() {
    final file = io.File(_path!);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    return file;
  }

  static void _writeHeader(io.File file) {
    final scriptPath = _resolveScriptPath();
    final lines = <String>[
      '# trace start: $_startWallTime',
      '# timestamps are monotonic microseconds from start',
      '# path: ${file.path}',
      '# pid: ${io.pid}',
      '# cwd: ${io.Directory.current.path}',
      '# executable: ${io.Platform.executable}',
      if (scriptPath != null) '# script: $scriptPath',
      '# os: ${io.Platform.operatingSystem} ${io.Platform.operatingSystemVersion}',
      '# dart: ${io.Platform.version}',
      '# capture_dispatch: ${captureDispatchEnabled}',
      '# trace_tags: ${_describeTagFilter()}',
    ];

    // Write header with wall-clock correlation.
    file.writeAsStringSync('${lines.join('\n')}\n', mode: io.FileMode.append);
  }

  /// Closes the trace log file.
  static void close() {
    _file = null;
    _headerWritten = false;
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

  static String _describeTagFilter() {
    final raw = _tagsRaw?.trim();
    if (raw == null || raw.isEmpty) {
      return 'all';
    }
    final enabledTags = _enabledTags;
    if (enabledTags == null) {
      return 'all (raw="$raw")';
    }
    final names = enabledTags.map((tag) => tag.name).toList()..sort();
    if (names.isEmpty) return 'all';
    return names.join(',');
  }

  static Set<TraceTag>? _resolveTagFilter(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final tokens = value
        .split(RegExp(r'[,\s]+'))
        .map((token) => token.trim().toLowerCase())
        .where((token) => token.isNotEmpty)
        .toSet();
    if (tokens.isEmpty || tokens.contains('*') || tokens.contains('all')) {
      return null;
    }
    final byName = <String, TraceTag>{
      for (final tag in TraceTag.values) tag.name.toLowerCase(): tag,
    };
    final resolved = <TraceTag>{};
    for (final token in tokens) {
      final tag = byName[token];
      if (tag != null) {
        resolved.add(tag);
      }
    }
    if (resolved.isEmpty) return null;
    return resolved;
  }

  static String? _resolveScriptPath() {
    try {
      return io.Platform.script.toFilePath();
    } catch (_) {
      return null;
    }
  }

  static bool _isEnabledFlag(String flag) {
    final lower = flag.toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes';
  }
}
