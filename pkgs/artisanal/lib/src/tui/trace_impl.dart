import 'dart:convert';
import 'dart:io' as io;

/// Trace categories for filtering and grouping trace output.
enum TraceTag {
  input,
  queue,
  dispatch,
  rebuild,
  layout,
  paint,
  render,
  flush,
  focus,
  scroll,
  metrics,
  cmd,
  general,
}

/// Structured trace event names emitted by [TuiTrace.event].
final class TraceEventType {
  const TraceEventType._();

  static const String inputBatch = 'input.batch';
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

  final int timestampUs;
  final TraceTag tag;
  final String type;
  final Map<String, Object?> fields;
}

/// A timing span for hierarchical tracing.
final class TraceSpan {
  TraceSpan._(this._label, this._tag, this._sw, this._extra) {
    _sw.start();
  }

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

  int get elapsedMicroseconds => _sw.elapsedMicroseconds;

  void end({String? extra}) {
    if (_ended) return;
    _ended = true;
    _sw.stop();
    if (!TuiTrace.enabled || !TuiTrace.isTagEnabled(_tag)) return;
    final parts = StringBuffer();
    parts.write('[${_tag.name}] ');
    parts.write(_label);
    if (_extra != null) parts.write(' $_extra');
    if (extra != null) parts.write(' $extra');
    parts.write(' ${_sw.elapsedMicroseconds}us');
    TuiTrace._writeRaw(parts.toString());
  }
}

/// Lightweight debug tracer for TUI frame rendering and message dispatch.
final class TuiTrace {
  static const _flagEnv = 'ARTISANAL_TUI_TRACE';
  static const _pathEnv = 'ARTISANAL_TUI_TRACE_PATH';
  static const _captureEnv = 'ARTISANAL_TUI_TRACE_CAPTURE';
  static const _tagsEnv = 'ARTISANAL_TUI_TRACE_TAGS';
  static const _eventMarker = '@event ';
  static const _eventSchemaVersion = 1;

  static bool? _testEnabled;
  static String? _testPath;
  static bool? _testCaptureEnabled;
  static String? _testTagsRaw;
  static DateTime Function()? _testNowProvider;
  static bool _testOverride = false;
  static String? _path;
  static io.File? _file;
  static bool _headerWritten = false;
  static bool? _captureEnabled;
  static Set<TraceTag>? _enabledTags;
  static bool _resolved = false;
  static final Map<String, TraceTag> _traceTagByName = <String, TraceTag>{
    for (final tag in TraceTag.values) tag.name: tag,
  };

  static bool get enabled {
    if (!_resolved) _resolve();
    return _path != null;
  }

  static bool get captureEnabled {
    if (!_resolved) _resolve();
    return _captureEnabled ?? false;
  }

  static bool get captureDispatchEnabled => captureEnabled;

  static void configureForTest({
    bool? enabled,
    String? path,
    bool captureEnabled = false,
    String? tagsRaw,
    DateTime Function()? nowProvider,
    bool clear = false,
  }) {
    _testOverride = true;
    _testEnabled = enabled;
    _testPath = path;
    _testCaptureEnabled = captureEnabled ? true : null;
    _testTagsRaw = tagsRaw;
    _testNowProvider = nowProvider;
    _resolved = false;
  }

  static void clearTestOverrides() {
    _testOverride = false;
    _testEnabled = null;
    _testPath = null;
    _testCaptureEnabled = null;
    _testTagsRaw = null;
    _testNowProvider = null;
    _resolved = false;
  }

  static bool isTagEnabled(TraceTag tag) {
    final tags = _resolveEnabledTags();
    return tags == null || tags.contains(tag);
  }

  static void log(
    String message, {
    TraceTag tag = TraceTag.general,
    Object? extra,
  }) {
    if (!enabled || !isTagEnabled(tag)) return;
    final parts = StringBuffer();
    parts.write('[${tag.name}] ');
    parts.write(message);
    if (extra != null) parts.write(' $extra');
    _writeRaw(parts.toString());
  }

  static TraceSpan begin(
    String label, {
    TraceTag tag = TraceTag.general,
    String? extra,
  }) {
    if (!enabled || !isTagEnabled(tag)) return TraceSpan.noop;
    return TraceSpan._(label, tag, Stopwatch(), extra);
  }

  static void event(
    String type, {
    TraceTag tag = TraceTag.general,
    Map<String, Object?> fields = const {},
  }) {
    if (!enabled || !isTagEnabled(tag)) return;
    final payload = <String, Object?>{
      'v': _eventSchemaVersion,
      'ts': DateTime.now().microsecondsSinceEpoch,
      'tag': tag.name,
      'type': type,
      if (fields.isNotEmpty) 'fields': fields,
    };
    _writeRaw('$_eventMarker${jsonEncode(payload)}');
  }

  static void logTrace(String line) {
    if (!enabled) return;
    _writeRaw(line);
  }

  static TraceEventRecord? parseEventLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    final markerIndex = trimmed.indexOf(_eventMarker);
    if (markerIndex == -1) return null;
    final prefix = trimmed.substring(0, markerIndex).trimRight();
    final json = trimmed.substring(markerIndex + _eventMarker.length);
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      final data = Map<String, Object?>.from(decoded);
      final version = data['v'];
      if (version is! int || version != _eventSchemaVersion) return null;
      final ts = data['ts'] ?? _parseTimestampUs(prefix);
      if (ts is! int) return null;
      final tagName = data['tag'] ?? _parseTagName(prefix);
      if (tagName is! String) return null;
      final tag = _traceTagByName[tagName];
      if (tag == null) return null;
      final type = data['type'];
      if (type is! String) return null;
      final explicitFields = data['fields'];
      final fields = explicitFields is Map
          ? Map<String, Object?>.from(explicitFields)
          : <String, Object?>{
              for (final entry in data.entries)
                if (entry.key != 'v' &&
                    entry.key != 'ts' &&
                    entry.key != 'tag' &&
                    entry.key != 'type')
                  entry.key: entry.value,
            };
      return TraceEventRecord(
        timestampUs: ts,
        tag: tag,
        type: type,
        fields: fields,
      );
    } catch (_) {
      return null;
    }
  }

  static TraceEventRecord? tryParseEventLine(String line) =>
      parseEventLine(line);

  static void close() {
    _file = null;
    _resolved = false;
  }

  static void _resolve() {
    final flag = _resolveEnabledFlag();
    _path = flag ? _resolvePath() : null;
    _captureEnabled = flag && _resolveCaptureEnabled();
    _resolved = true;
  }

  static bool _resolveEnabledFlag() {
    if (_testOverride) return _testEnabled ?? true;
    final env = io.Platform.environment;
    final flag = env[_flagEnv];
    return flag != null && _isEnabled(flag);
  }

  static String? _resolvePath() {
    if (_testOverride) {
      if (_testPath != null && _testPath!.isNotEmpty) return _testPath;
      return _generateDateBasedPath();
    }
    final env = io.Platform.environment;
    final explicit = env[_pathEnv];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return _generateDateBasedPath();
  }

  static bool _resolveCaptureEnabled() {
    if (_testOverride) return _testCaptureEnabled ?? false;
    final env = io.Platform.environment;
    final flag = env[_captureEnv];
    if (flag == null) return false;
    return _isEnabled(flag);
  }

  static Set<TraceTag>? _resolveEnabledTags() {
    if (_resolved && _enabledTags != null) return _enabledTags;
    final raw = _testTagsRaw ?? io.Platform.environment[_tagsEnv];
    if (raw == null || raw.isEmpty) return null;
    final tags = <TraceTag>{};
    for (final name in raw.split(',')) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      final tag = _traceTagByName[trimmed];
      if (tag != null) tags.add(tag);
    }
    _enabledTags = tags.isNotEmpty ? tags : null;
    return _enabledTags;
  }

  static io.File _openFile() {
    final file = io.File(_path!);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    _file = file;
    return file;
  }

  static void _writeRaw(String message) {
    final file = _file ?? _openFile();
    if (!_headerWritten) {
      _writeHeaderSync(file);
      _headerWritten = true;
    }
    file.writeAsStringSync('$message\n', mode: io.FileMode.append);
  }

  static void _writeHeaderSync(io.File file) {
    final now = _testNowProvider != null ? _testNowProvider!() : DateTime.now();
    final buffer = StringBuffer();
    final header = <String>[
      '# trace start: ${now.toUtc().toIso8601String()}',
      '# pid: ${io.pid}',
      '# cwd: ${io.Directory.current.path}',
      '# executable: ${io.Platform.executable}',
      '# os: ${io.Platform.operatingSystem} ${io.Platform.operatingSystemVersion}',
      '# dart: ${io.Platform.version}',
    ];
    for (final line in header) {
      buffer.writeln(line);
    }
    file.writeAsStringSync(buffer.toString(), mode: io.FileMode.append);
  }

  static String _generateDateBasedPath() {
    final now = _testNowProvider != null ? _testNowProvider!() : DateTime.now();
    final ts =
        '${now.year.toString().padLeft(4, '0')}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}'
        'T${now.hour.toString().padLeft(2, '0')}'
        '-${now.minute.toString().padLeft(2, '0')}'
        '-${now.second.toString().padLeft(2, '0')}';
    final dir = io.Directory('traces');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return 'traces/artisanal-$ts.log';
  }

  static int? _parseTimestampUs(String prefix) {
    final match = RegExp(r'\[\+(\d+)us\]').firstMatch(prefix);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String? _parseTagName(String prefix) {
    final matches = RegExp(r'\[([^\]]+)\]').allMatches(prefix).toList();
    if (matches.isEmpty) return null;
    return matches.last.group(1);
  }

  static bool _isEnabled(String value) {
    final normalized = value.toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
}
