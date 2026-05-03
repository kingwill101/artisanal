import 'dart:async';

import 'degradation.dart';
import 'program.dart';
import 'terminal_native_frame.dart';

/// Aggregated native-change summary for one render.
final class ProgramRenderChangeSummary {
  /// Creates a change summary.
  const ProgramRenderChangeSummary({
    required this.dirtyLineCount,
    required this.changedLineCount,
    required this.changedCellCount,
    required this.changedSpanCount,
  });

  /// Number of dirty lines reported by the native renderer.
  final int dirtyLineCount;

  /// Number of lines containing changed cells.
  final int changedLineCount;

  /// Total changed cells across all changed lines.
  final int changedCellCount;

  /// Total grouped semantic spans across all changed lines.
  final int changedSpanCount;

  /// Whether the render exposed any native changes at all.
  bool get hasChanges =>
      dirtyLineCount > 0 ||
      changedLineCount > 0 ||
      changedCellCount > 0 ||
      changedSpanCount > 0;

  /// Converts this summary into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dirtyLineCount': dirtyLineCount,
      'changedLineCount': changedLineCount,
      'changedCellCount': changedCellCount,
      'changedSpanCount': changedSpanCount,
      'hasChanges': hasChanges,
    };
  }

  /// Rebuilds a change summary from serialized JSON data.
  factory ProgramRenderChangeSummary.fromJson(Map<Object?, Object?> json) {
    return ProgramRenderChangeSummary(
      dirtyLineCount: _jsonInt(json['dirtyLineCount']),
      changedLineCount: _jsonInt(json['changedLineCount']),
      changedCellCount: _jsonInt(json['changedCellCount']),
      changedSpanCount: _jsonInt(json['changedSpanCount']),
    );
  }

  /// Builds a summary from native render deltas.
  factory ProgramRenderChangeSummary.fromNative({
    TerminalNativeDeltaFrame? nativeDelta,
    TerminalNativeCellDeltaFrame? nativeCellDelta,
    List<TerminalNativeSpanDelta>? nativeSpanDelta,
  }) {
    final changedLines =
        nativeCellDelta?.lines ?? const <TerminalNativeLineDelta>[];
    final spanLines = nativeSpanDelta ?? const <TerminalNativeSpanDelta>[];
    return ProgramRenderChangeSummary(
      dirtyLineCount: nativeDelta?.lines.length ?? 0,
      changedLineCount: changedLines.length,
      changedCellCount: changedLines.fold<int>(
        0,
        (sum, line) => sum + line.cells.length,
      ),
      changedSpanCount: spanLines.fold<int>(
        0,
        (sum, line) => sum + line.spans.length,
      ),
    );
  }
}

/// One live render event emitted by [ProgramRenderFeed].
final class ProgramRenderEvent {
  /// Creates a render event.
  const ProgramRenderEvent({
    required this.renderGeneration,
    required this.view,
    required this.degradationLevel,
    required this.renderDuration,
    this.width,
    this.height,
    this.nativeFrame,
    this.nativeDelta,
    this.nativeCellDelta,
    this.nativeSpanDelta,
  });

  /// Monotonic render generation from the program runtime.
  final int renderGeneration;

  /// The rendered view object.
  final Object view;

  /// Active degradation level for this render.
  final DegradationLevel degradationLevel;

  /// Render duration measured by the program runtime.
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

  /// Aggregated native-change summary for this render.
  ProgramRenderChangeSummary get changeSummary =>
      ProgramRenderChangeSummary.fromNative(
        nativeDelta: nativeDelta,
        nativeCellDelta: nativeCellDelta,
        nativeSpanDelta: nativeSpanDelta,
      );
}

/// Program interceptor that publishes live render events.
final class ProgramRenderFeed extends ProgramInterceptor {
  final StreamController<ProgramRenderEvent> _controller =
      StreamController<ProgramRenderEvent>.broadcast();

  @override
  bool get wantsNativeFrames => true;

  /// Broadcast stream of live render events.
  Stream<ProgramRenderEvent> get stream => _controller.stream;

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
    if (_controller.isClosed) return;
    _controller.add(
      ProgramRenderEvent(
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
      ),
    );
  }

  @override
  void onStop() {
    unawaited(_controller.close());
  }
}

/// Aggregated render activity across one program run.
final class ProgramRenderStats {
  /// Creates render stats.
  const ProgramRenderStats({
    required this.totalRenders,
    required this.changedRenders,
    required this.totalChangedCells,
    required this.totalChangedSpans,
    required this.maxDirtyLines,
    required this.maxChangedCells,
    required this.maxChangedSpans,
    required this.totalRenderDuration,
    this.lastRenderGeneration,
    this.lastDegradationLevel,
    this.lastChangeSummary,
  });

  /// Number of completed renders observed by the monitor.
  final int totalRenders;

  /// Number of renders that carried native changes.
  final int changedRenders;

  /// Cumulative changed-cell count across all renders.
  final int totalChangedCells;

  /// Cumulative grouped-span count across all renders.
  final int totalChangedSpans;

  /// Highest dirty-line count seen on any one render.
  final int maxDirtyLines;

  /// Highest changed-cell count seen on any one render.
  final int maxChangedCells;

  /// Highest changed-span count seen on any one render.
  final int maxChangedSpans;

  /// Sum of all render durations seen by the monitor.
  final Duration totalRenderDuration;

  /// Last render generation observed by the monitor.
  final int? lastRenderGeneration;

  /// Last degradation level observed by the monitor.
  final DegradationLevel? lastDegradationLevel;

  /// Last native-change summary observed by the monitor.
  final ProgramRenderChangeSummary? lastChangeSummary;

  /// Number of renders without native changes.
  int get unchangedRenders => totalRenders - changedRenders;

  /// Average render duration across all observed renders.
  Duration get averageRenderDuration => totalRenders == 0
      ? Duration.zero
      : Duration(
          microseconds: totalRenderDuration.inMicroseconds ~/ totalRenders,
        );

  /// Ratio of renders that carried native changes.
  double get changedRenderRatio =>
      totalRenders == 0 ? 0.0 : changedRenders / totalRenders;

  /// Formats this summary as compact key-value lines for debug overlays.
  Map<String, String> toMetricEntries({String prefix = 'Render'}) {
    final averageMs = averageRenderDuration.inMicroseconds / 1000.0;
    final ratioPercent = (changedRenderRatio * 100).toStringAsFixed(0);
    return <String, String>{
      '$prefix renders':
          '$totalRenders ($changedRenders changed, $ratioPercent%)',
      '$prefix avg': '${averageMs.toStringAsFixed(1)}ms',
      '$prefix cells': '$totalChangedCells total / $maxChangedCells peak',
      '$prefix spans': '$totalChangedSpans total / $maxChangedSpans peak',
      '$prefix dirty': '$maxDirtyLines peak',
      if (lastDegradationLevel != null)
        '$prefix level': lastDegradationLevel!.name,
    };
  }

  /// Converts this aggregate summary into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'totalRenders': totalRenders,
      'changedRenders': changedRenders,
      'unchangedRenders': unchangedRenders,
      'changedRenderRatio': changedRenderRatio,
      'totalChangedCells': totalChangedCells,
      'totalChangedSpans': totalChangedSpans,
      'maxDirtyLines': maxDirtyLines,
      'maxChangedCells': maxChangedCells,
      'maxChangedSpans': maxChangedSpans,
      'totalRenderDurationUs': totalRenderDuration.inMicroseconds,
      'averageRenderDurationUs': averageRenderDuration.inMicroseconds,
      'lastRenderGeneration': lastRenderGeneration,
      'lastDegradationLevel': lastDegradationLevel?.name,
      'lastChangeSummary': lastChangeSummary?.toJson(),
    };
  }

  /// Rebuilds aggregate render stats from serialized JSON data.
  factory ProgramRenderStats.fromJson(Map<Object?, Object?> json) {
    final lastChangeSummaryJson = _jsonObjectOrNull(json['lastChangeSummary']);
    return ProgramRenderStats(
      totalRenders: _jsonInt(json['totalRenders']),
      changedRenders: _jsonInt(json['changedRenders']),
      totalChangedCells: _jsonInt(json['totalChangedCells']),
      totalChangedSpans: _jsonInt(json['totalChangedSpans']),
      maxDirtyLines: _jsonInt(json['maxDirtyLines']),
      maxChangedCells: _jsonInt(json['maxChangedCells']),
      maxChangedSpans: _jsonInt(json['maxChangedSpans']),
      totalRenderDuration: Duration(
        microseconds: _jsonInt(json['totalRenderDurationUs']),
      ),
      lastRenderGeneration: _jsonNullableInt(json['lastRenderGeneration']),
      lastDegradationLevel: _jsonEnumByName(
        DegradationLevel.values,
        json['lastDegradationLevel'],
      ),
      lastChangeSummary: lastChangeSummaryJson == null
          ? null
          : ProgramRenderChangeSummary.fromJson(lastChangeSummaryJson),
    );
  }
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

Map<Object?, Object?>? _jsonObjectOrNull(Object? value) {
  if (value is Map<Object?, Object?>) return value;
  if (value is Map) return Map<Object?, Object?>.from(value);
  return null;
}

T? _jsonEnumByName<T extends Enum>(List<T> values, Object? value) {
  if (value is! String || value.isEmpty) return null;
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  return null;
}

/// Higher-level render activity monitor built on the live render hook.
final class ProgramRenderMonitor extends ProgramInterceptor {
  int _totalRenders = 0;
  int _changedRenders = 0;
  int _totalChangedCells = 0;
  int _totalChangedSpans = 0;
  int _maxDirtyLines = 0;
  int _maxChangedCells = 0;
  int _maxChangedSpans = 0;
  Duration _totalRenderDuration = Duration.zero;
  int? _lastRenderGeneration;
  DegradationLevel? _lastDegradationLevel;
  ProgramRenderChangeSummary? _lastChangeSummary;

  @override
  bool get wantsNativeFrames => true;

  /// Current aggregated statistics.
  ProgramRenderStats get stats => ProgramRenderStats(
    totalRenders: _totalRenders,
    changedRenders: _changedRenders,
    totalChangedCells: _totalChangedCells,
    totalChangedSpans: _totalChangedSpans,
    maxDirtyLines: _maxDirtyLines,
    maxChangedCells: _maxChangedCells,
    maxChangedSpans: _maxChangedSpans,
    totalRenderDuration: _totalRenderDuration,
    lastRenderGeneration: _lastRenderGeneration,
    lastDegradationLevel: _lastDegradationLevel,
    lastChangeSummary: _lastChangeSummary,
  );

  /// Clears all accumulated render activity.
  void reset() {
    _totalRenders = 0;
    _changedRenders = 0;
    _totalChangedCells = 0;
    _totalChangedSpans = 0;
    _maxDirtyLines = 0;
    _maxChangedCells = 0;
    _maxChangedSpans = 0;
    _totalRenderDuration = Duration.zero;
    _lastRenderGeneration = null;
    _lastDegradationLevel = null;
    _lastChangeSummary = null;
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
    final summary = ProgramRenderChangeSummary.fromNative(
      nativeDelta: nativeDelta,
      nativeCellDelta: nativeCellDelta,
      nativeSpanDelta: nativeSpanDelta,
    );
    _totalRenders += 1;
    if (summary.hasChanges) {
      _changedRenders += 1;
    }
    _totalChangedCells += summary.changedCellCount;
    _totalChangedSpans += summary.changedSpanCount;
    if (summary.dirtyLineCount > _maxDirtyLines) {
      _maxDirtyLines = summary.dirtyLineCount;
    }
    if (summary.changedCellCount > _maxChangedCells) {
      _maxChangedCells = summary.changedCellCount;
    }
    if (summary.changedSpanCount > _maxChangedSpans) {
      _maxChangedSpans = summary.changedSpanCount;
    }
    _totalRenderDuration += renderDuration;
    _lastRenderGeneration = renderGeneration;
    _lastDegradationLevel = degradationLevel;
    _lastChangeSummary = summary;
  }
}
