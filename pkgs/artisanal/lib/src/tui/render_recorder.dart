import 'degradation.dart';
import 'program.dart';
import 'render_feed.dart';
import 'terminal_native_frame.dart';
import 'terminal_render_inspector.dart';
import 'view.dart';

/// One deterministic render snapshot captured by [ProgramRenderRecorder].
final class ProgramRenderSnapshot {
  /// Creates a render snapshot.
  const ProgramRenderSnapshot({
    required this.sequence,
    required this.renderGeneration,
    required this.view,
    required this.frame,
    required this.degradationLevel,
    required this.renderDuration,
    this.width,
    this.height,
    this.nativeFrame,
    this.nativeDelta,
    this.nativeCellDelta,
    this.nativeSpanDelta,
  });

  /// Monotonic snapshot sequence local to one recorder instance.
  final int sequence;

  /// Monotonic render generation from the runtime.
  final int renderGeneration;

  /// Original view object emitted by the program.
  final Object view;

  /// Parsed string-frame inspection for this render.
  final TerminalRenderFrame frame;

  /// Active degradation level for this render.
  final DegradationLevel degradationLevel;

  /// Render duration measured by the runtime.
  final Duration renderDuration;

  /// Terminal width, when known.
  final int? width;

  /// Terminal height, when known.
  final int? height;

  /// Native frame snapshot captured from the renderer, when available.
  final TerminalNativeFrame? nativeFrame;

  /// Native dirty-line delta captured from the renderer, when available.
  final TerminalNativeDeltaFrame? nativeDelta;

  /// Native changed-cell delta captured from the renderer, when available.
  final TerminalNativeCellDeltaFrame? nativeCellDelta;

  /// Span-oriented delta grouped from changed cells, when available.
  final List<TerminalNativeSpanDelta>? nativeSpanDelta;

  /// Plain-text lines extracted from [frame].
  List<String> get lines =>
      frame.lines.map((line) => line.plainText).toList(growable: false);

  /// Aggregated native-change summary for this render.
  ProgramRenderChangeSummary get changeSummary =>
      ProgramRenderChangeSummary.fromNative(
        nativeDelta: nativeDelta,
        nativeCellDelta: nativeCellDelta,
        nativeSpanDelta: nativeSpanDelta,
      );

  /// Converts this snapshot into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'renderGeneration': renderGeneration,
      'degradationLevel': degradationLevel.name,
      'renderDurationUs': renderDuration.inMicroseconds,
      'width': width,
      'height': height,
      'lines': List<String>.unmodifiable(lines),
      'changeSummary': changeSummary.toJson(),
    };
  }

  /// Rebuilds a snapshot from serialized JSON data.
  factory ProgramRenderSnapshot.fromJson(Map<Object?, Object?> json) {
    final lines = _jsonStringList(json['lines']);
    final content = lines.join('\n');
    final view = View(content: content);
    return ProgramRenderSnapshot(
      sequence: _jsonInt(json['sequence']),
      renderGeneration: _jsonInt(json['renderGeneration']),
      view: view,
      frame: TerminalRenderFrame.inspect(view),
      degradationLevel:
          _jsonEnumByName(DegradationLevel.values, json['degradationLevel']) ??
          DegradationLevel.full,
      renderDuration: Duration(
        microseconds: _jsonInt(json['renderDurationUs']),
      ),
      width: _jsonNullableInt(json['width']),
      height: _jsonNullableInt(json['height']),
    );
  }
}

/// Compact summary of the most recent captured render snapshot.
final class ProgramRenderSnapshotSummary {
  /// Creates a snapshot summary.
  const ProgramRenderSnapshotSummary({
    required this.sequence,
    required this.renderGeneration,
    required this.degradationLevel,
    required this.renderDuration,
    required this.width,
    required this.height,
    required this.frameLines,
    required this.changeSummary,
  });

  /// Local capture sequence.
  final int sequence;

  /// Monotonic render generation from the runtime.
  final int renderGeneration;

  /// Degradation level used for this render.
  final DegradationLevel degradationLevel;

  /// Runtime render duration.
  final Duration renderDuration;

  /// Terminal width, when known.
  final int? width;

  /// Terminal height, when known.
  final int? height;

  /// Plain-text frame lines selected for summary output.
  final List<String> frameLines;

  /// Native change summary for this render.
  final ProgramRenderChangeSummary changeSummary;

  /// Builds a summary from a full [ProgramRenderSnapshot].
  factory ProgramRenderSnapshotSummary.fromSnapshot(
    ProgramRenderSnapshot snapshot, {
    int maxFrameLines = 3,
  }) {
    return ProgramRenderSnapshotSummary(
      sequence: snapshot.sequence,
      renderGeneration: snapshot.renderGeneration,
      degradationLevel: snapshot.degradationLevel,
      renderDuration: snapshot.renderDuration,
      width: snapshot.width,
      height: snapshot.height,
      frameLines: snapshot.lines.take(maxFrameLines).toList(growable: false),
      changeSummary: snapshot.changeSummary,
    );
  }

  /// Converts this summary into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'renderGeneration': renderGeneration,
      'degradationLevel': degradationLevel.name,
      'renderDurationUs': renderDuration.inMicroseconds,
      'width': width,
      'height': height,
      'frameLines': List<String>.unmodifiable(frameLines),
      'changeSummary': changeSummary.toJson(),
    };
  }

  /// Rebuilds a snapshot summary from serialized JSON data.
  factory ProgramRenderSnapshotSummary.fromJson(Map<Object?, Object?> json) {
    return ProgramRenderSnapshotSummary(
      sequence: _jsonInt(json['sequence']),
      renderGeneration: _jsonInt(json['renderGeneration']),
      degradationLevel:
          _jsonEnumByName(DegradationLevel.values, json['degradationLevel']) ??
          DegradationLevel.full,
      renderDuration: Duration(
        microseconds: _jsonInt(json['renderDurationUs']),
      ),
      width: _jsonNullableInt(json['width']),
      height: _jsonNullableInt(json['height']),
      frameLines: _jsonStringList(json['frameLines']),
      changeSummary: ProgramRenderChangeSummary.fromJson(
        _jsonObjectOrEmpty(json['changeSummary']),
      ),
    );
  }
}

/// Program interceptor that records deterministic render snapshots.
final class ProgramRenderRecorder extends ProgramInterceptor {
  final List<ProgramRenderSnapshot> _snapshots = <ProgramRenderSnapshot>[];
  int _sequence = 0;

  /// Recorded snapshots in capture order.
  List<ProgramRenderSnapshot> get snapshots =>
      List<ProgramRenderSnapshot>.unmodifiable(_snapshots);

  /// Most recently captured snapshot, if any.
  ProgramRenderSnapshot? get lastSnapshot =>
      _snapshots.isEmpty ? null : _snapshots.last;

  /// Removes all recorded snapshots and resets the local sequence.
  void clear() {
    _snapshots.clear();
    _sequence = 0;
  }

  /// Returns snapshots whose render generation is greater than [generation].
  List<ProgramRenderSnapshot> snapshotsSince(int generation) {
    return List<ProgramRenderSnapshot>.unmodifiable(
      _snapshots.where((snapshot) => snapshot.renderGeneration > generation),
    );
  }

  @override
  void onRendered({
    required int renderGeneration,
    required Object view,
    required DegradationLevel degradationLevel,
    required Duration renderDuration,
    int? width,
    int? height,
    TerminalNativeFrame? nativeFrame,
    TerminalNativeDeltaFrame? nativeDelta,
    TerminalNativeCellDeltaFrame? nativeCellDelta,
    List<TerminalNativeSpanDelta>? nativeSpanDelta,
  }) {
    _snapshots.add(
      ProgramRenderSnapshot(
        sequence: _sequence++,
        renderGeneration: renderGeneration,
        view: view,
        frame: TerminalRenderFrame.inspect(view),
        degradationLevel: degradationLevel,
        renderDuration: renderDuration,
        width: width,
        height: height,
        nativeFrame: nativeFrame,
        nativeDelta: nativeDelta,
        nativeCellDelta: nativeCellDelta,
        nativeSpanDelta: nativeSpanDelta,
      ),
    );
  }
}

/// Structured summary emitted from [ProgramRenderCapture].
final class ProgramRenderCaptureReport {
  /// Creates a capture report.
  const ProgramRenderCaptureReport({
    required this.prefix,
    required this.metricEntries,
    required this.lastRenderGeneration,
    required this.lastWidth,
    required this.lastHeight,
    required this.frameLines,
    this.lastChangeSummary,
  });

  /// Prefix used for formatted metric entries.
  final String prefix;

  /// Formatted aggregate metric entries.
  final Map<String, String> metricEntries;

  /// Last captured render generation, if any.
  final int? lastRenderGeneration;

  /// Last captured render width, if any.
  final int? lastWidth;

  /// Last captured render height, if any.
  final int? lastHeight;

  /// Plain-text lines from the latest snapshot, truncated by the caller.
  final List<String> frameLines;

  /// Last native-change summary observed by the capture, if any.
  final ProgramRenderChangeSummary? lastChangeSummary;

  /// Formats this report as compact diagnostic lines.
  List<String> toLines() {
    final lines = <String>[];
    if (lastRenderGeneration != null) {
      lines.add(
        '$prefix last: generation $lastRenderGeneration '
        '(${lastWidth ?? '?'}x${lastHeight ?? '?'})',
      );
      for (final line in frameLines) {
        lines.add('$prefix frame: $line');
      }
      if (lastChangeSummary != null) {
        lines.add(
          '$prefix changes: '
          'dirty ${lastChangeSummary!.dirtyLineCount}, '
          'lines ${lastChangeSummary!.changedLineCount}, '
          'cells ${lastChangeSummary!.changedCellCount}, '
          'spans ${lastChangeSummary!.changedSpanCount}',
        );
      }
    }
    for (final entry in metricEntries.entries) {
      lines.add('${entry.key}: ${entry.value}');
    }
    return List<String>.unmodifiable(lines);
  }

  /// Converts this report into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'prefix': prefix,
      'lastRenderGeneration': lastRenderGeneration,
      'lastWidth': lastWidth,
      'lastHeight': lastHeight,
      'frameLines': List<String>.unmodifiable(frameLines),
      'lastChangeSummary': lastChangeSummary?.toJson(),
      'metricEntries': Map<String, String>.unmodifiable(metricEntries),
    };
  }

  /// Rebuilds a capture report from serialized JSON data.
  factory ProgramRenderCaptureReport.fromJson(Map<Object?, Object?> json) {
    final metricEntries = <String, String>{};
    final rawEntries = _jsonObjectOrEmpty(json['metricEntries']);
    final lastChangeSummaryJson = _jsonObjectOrNull(json['lastChangeSummary']);
    for (final entry in rawEntries.entries) {
      if (entry.key is String && entry.value is String) {
        metricEntries[entry.key as String] = entry.value as String;
      }
    }
    return ProgramRenderCaptureReport(
      prefix: json['prefix'] as String? ?? 'Render',
      metricEntries: metricEntries,
      lastRenderGeneration: _jsonNullableInt(json['lastRenderGeneration']),
      lastWidth: _jsonNullableInt(json['lastWidth']),
      lastHeight: _jsonNullableInt(json['lastHeight']),
      frameLines: _jsonStringList(json['frameLines']),
      lastChangeSummary: lastChangeSummaryJson == null
          ? null
          : ProgramRenderChangeSummary.fromJson(lastChangeSummaryJson),
    );
  }
}

/// Structured export payload for one [ProgramRenderCapture] state snapshot.
final class ProgramRenderCapturePayload {
  /// Creates a capture payload.
  const ProgramRenderCapturePayload({
    required this.stats,
    required this.report,
    required this.lastSnapshot,
    required this.lastSnapshotSummary,
  });

  /// Aggregate render statistics.
  final ProgramRenderStats stats;

  /// Formatted capture report.
  final ProgramRenderCaptureReport report;

  /// Latest full snapshot, if any.
  final ProgramRenderSnapshot? lastSnapshot;

  /// Latest compact snapshot summary, if any.
  final ProgramRenderSnapshotSummary? lastSnapshotSummary;

  /// Converts this payload into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'stats': stats.toJson(),
      'report': report.toJson(),
      'lastSnapshot': lastSnapshot?.toJson(),
      'lastSnapshotSummary': lastSnapshotSummary?.toJson(),
    };
  }

  /// Rebuilds a capture payload from serialized JSON data.
  factory ProgramRenderCapturePayload.fromJson(Map<Object?, Object?> json) {
    final lastSnapshotJson = _jsonObjectOrNull(json['lastSnapshot']);
    final lastSnapshotSummaryJson = _jsonObjectOrNull(
      json['lastSnapshotSummary'],
    );
    return ProgramRenderCapturePayload(
      stats: ProgramRenderStats.fromJson(_jsonObjectOrEmpty(json['stats'])),
      report: ProgramRenderCaptureReport.fromJson(
        _jsonObjectOrEmpty(json['report']),
      ),
      lastSnapshot: lastSnapshotJson == null
          ? null
          : ProgramRenderSnapshot.fromJson(lastSnapshotJson),
      lastSnapshotSummary: lastSnapshotSummaryJson == null
          ? null
          : ProgramRenderSnapshotSummary.fromJson(lastSnapshotSummaryJson),
    );
  }
}

/// Bundles deterministic snapshot recording with aggregate render monitoring.
///
/// This is useful for tests and tooling that want both frame-by-frame evidence
/// and a compact summary without wiring two interceptors manually.
final class ProgramRenderCapture extends ProgramInterceptor {
  final ProgramRenderRecorder _recorder = ProgramRenderRecorder();
  final ProgramRenderMonitor _monitor = ProgramRenderMonitor();

  /// Recorded snapshots in capture order.
  List<ProgramRenderSnapshot> get snapshots => _recorder.snapshots;

  /// Most recently captured snapshot, if any.
  ProgramRenderSnapshot? get lastSnapshot => _recorder.lastSnapshot;

  /// Current aggregated statistics.
  ProgramRenderStats get stats => _monitor.stats;

  /// Compact summary of the last captured snapshot, if any.
  ProgramRenderSnapshotSummary? lastSnapshotSummary({int maxFrameLines = 3}) {
    final snapshot = lastSnapshot;
    if (snapshot == null) return null;
    return ProgramRenderSnapshotSummary.fromSnapshot(
      snapshot,
      maxFrameLines: maxFrameLines,
    );
  }

  /// Formats aggregate render metrics for diagnostics or overlays.
  Map<String, String> toMetricEntries({String prefix = 'Render'}) {
    return stats.toMetricEntries(prefix: prefix);
  }

  /// Builds a structured summary of the latest capture state.
  ProgramRenderCaptureReport report({
    String prefix = 'Render',
    int maxFrameLines = 3,
  }) {
    final snapshot = lastSnapshot;
    return ProgramRenderCaptureReport(
      prefix: prefix,
      metricEntries: toMetricEntries(prefix: prefix),
      lastRenderGeneration: snapshot?.renderGeneration,
      lastWidth: snapshot?.width,
      lastHeight: snapshot?.height,
      frameLines: snapshot == null
          ? const <String>[]
          : snapshot.lines.take(maxFrameLines).toList(growable: false),
      lastChangeSummary: stats.lastChangeSummary,
    );
  }

  /// Builds a compact text report combining snapshot and aggregate state.
  List<String> toReportLines({
    String prefix = 'Render',
    int maxFrameLines = 3,
  }) {
    return report(prefix: prefix, maxFrameLines: maxFrameLines).toLines();
  }

  /// Builds a serialization-friendly payload for the whole capture state.
  ProgramRenderCapturePayload payload({
    String prefix = 'Render',
    int maxFrameLines = 3,
  }) {
    return ProgramRenderCapturePayload(
      stats: stats,
      report: report(prefix: prefix, maxFrameLines: maxFrameLines),
      lastSnapshot: lastSnapshot,
      lastSnapshotSummary: lastSnapshotSummary(maxFrameLines: maxFrameLines),
    );
  }

  /// Builds a serialization-friendly payload for the whole capture state.
  Map<String, Object?> toJson({
    String prefix = 'Render',
    int maxFrameLines = 3,
  }) {
    return payload(prefix: prefix, maxFrameLines: maxFrameLines).toJson();
  }

  /// Removes all recorded snapshots and resets aggregated monitor state.
  void clear() {
    _recorder.clear();
    _monitor.reset();
  }

  /// Returns snapshots whose render generation is greater than [generation].
  List<ProgramRenderSnapshot> snapshotsSince(int generation) {
    return _recorder.snapshotsSince(generation);
  }

  @override
  void onRendered({
    required int renderGeneration,
    required Object view,
    required DegradationLevel degradationLevel,
    required Duration renderDuration,
    int? width,
    int? height,
    TerminalNativeFrame? nativeFrame,
    TerminalNativeDeltaFrame? nativeDelta,
    TerminalNativeCellDeltaFrame? nativeCellDelta,
    List<TerminalNativeSpanDelta>? nativeSpanDelta,
  }) {
    _recorder.onRendered(
      renderGeneration: renderGeneration,
      view: view,
      degradationLevel: degradationLevel,
      renderDuration: renderDuration,
      width: width,
      height: height,
      nativeFrame: nativeFrame,
      nativeDelta: nativeDelta,
      nativeCellDelta: nativeCellDelta,
      nativeSpanDelta: nativeSpanDelta,
    );
    _monitor.onRendered(
      renderGeneration: renderGeneration,
      view: view,
      degradationLevel: degradationLevel,
      renderDuration: renderDuration,
      width: width,
      height: height,
      nativeFrame: nativeFrame,
      nativeDelta: nativeDelta,
      nativeCellDelta: nativeCellDelta,
      nativeSpanDelta: nativeSpanDelta,
    );
  }
}

Map<Object?, Object?> _jsonObjectOrEmpty(Object? value) {
  if (value is Map<Object?, Object?>) return value;
  if (value is Map) return Map<Object?, Object?>.from(value);
  return const <Object?, Object?>{};
}

Map<Object?, Object?>? _jsonObjectOrNull(Object? value) {
  if (value is Map<Object?, Object?>) return value;
  if (value is Map) return Map<Object?, Object?>.from(value);
  return null;
}

List<String> _jsonStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}

int _jsonInt(Object? value) => switch (value) {
  int v => v,
  num v => v.toInt(),
  _ => 0,
};

int? _jsonNullableInt(Object? value) => switch (value) {
  int v => v,
  num v => v.toInt(),
  _ => null,
};

T? _jsonEnumByName<T extends Enum>(List<T> values, Object? value) {
  if (value is! String || value.isEmpty) return null;
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  return null;
}
