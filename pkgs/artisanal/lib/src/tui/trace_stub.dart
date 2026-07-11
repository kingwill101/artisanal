// ignore_for_file: unused_field, unused_element

/// Debug tracing utilities — web stub with no-op tracer.
library;

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
  }
}

/// Lightweight debug tracer — web stub, all methods are no-ops.
final class TuiTrace {
  static const _flagEnv = 'ARTISANAL_TUI_TRACE';
  static const _pathEnv = 'ARTISANAL_TUI_TRACE_PATH';
  static const _captureEnv = 'ARTISANAL_TUI_TRACE_CAPTURE';
  static const _tagsEnv = 'ARTISANAL_TUI_TRACE_TAGS';
  static const _eventMarker = '@event ';
  static const _eventSchemaVersion = 1;

  static bool? _testEnabled;
  static String? _testPath;
  static String? _testBaseDirectory;
  static bool? _testCaptureEnabled;
  static String? _testTagsRaw;
  static DateTime Function()? _testNowProvider;
  static final bool _testOverride = false;

  static bool get enabled => false;
  static bool get captureEnabled => false;
  static bool get captureDispatchEnabled => false;

  static void configureForTest({
    bool? enabled,
    String? path,
    String? baseDirectory,
    bool captureEnabled = false,
    String? tagsRaw,
    DateTime Function()? nowProvider,
    bool clear = false,
  }) {}

  static void clearTestOverrides() {}

  static bool isTagEnabled(TraceTag tag) => false;

  static void log(
    String message, {
    TraceTag tag = TraceTag.general,
    Object? extra,
  }) {}

  static TraceSpan begin(
    String label, {
    TraceTag tag = TraceTag.general,
    String? extra,
  }) => TraceSpan.noop;

  static void event(
    String type, {
    TraceTag tag = TraceTag.general,
    Map<String, Object?> fields = const {},
  }) {}

  static void logTrace(String line) {}

  static TraceEventRecord? parseEventLine(String line) => null;

  static TraceEventRecord? tryParseEventLine(String line) =>
      parseEventLine(line);

  static void close() {}
}
