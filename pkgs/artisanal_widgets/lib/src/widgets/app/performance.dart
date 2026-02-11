/// Performance metrics for the widget layer.
///
/// Provides widget-level frame timing, callbacks, and integration with
/// the TUI runtime's [RenderMetrics].
///
/// Inspired by nocterm's 3-layer performance model:
///   Layer 1 — Runtime [RenderMetrics] (FPS, frame/render durations)
///   Layer 2 — Widget [WidgetFrameTiming] (build/layout/paint breakdown)
///   Layer 3 — Combined view via [PerformanceMetricsSnapshot]
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'package:artisanal/tui.dart' show RenderMetrics;

/// Callback for per-frame widget-level timing data.
typedef WidgetFrameTimingCallback = void Function(WidgetFrameTiming timing);

/// Per-frame timing data from the widget layer.
///
/// Captures how long each phase of a widget frame takes:
/// - [buildDuration] — time spent in `BuildOwner.buildScope`
/// - [layoutDuration] — time spent in render object layout
/// - [paintDuration] — time spent in render object paint
/// - [totalDuration] — total `ElementTree.render()` time
///
/// See also [nocterm's FrameTiming] for the reference design.
class WidgetFrameTiming {
  const WidgetFrameTiming({
    required this.frameNumber,
    required this.buildDuration,
    required this.layoutDuration,
    required this.paintDuration,
    required this.totalDuration,
    required this.timestamp,
  });

  /// Monotonically increasing frame counter within the widget layer.
  final int frameNumber;

  /// Time spent rebuilding dirty elements.
  final Duration buildDuration;

  /// Time spent in render object layout.
  final Duration layoutDuration;

  /// Time spent in render object paint.
  final Duration paintDuration;

  /// Total time for the entire `ElementTree.render()` call.
  final Duration totalDuration;

  /// When this frame was produced.
  final DateTime timestamp;

  /// Whether this frame exceeded the 16.67ms budget (60fps target).
  bool get isSlowFrame => totalDuration.inMicroseconds > 16667;

  @override
  String toString() =>
      'WidgetFrameTiming(frame: $frameNumber, '
      'build: ${buildDuration.inMicroseconds}us, '
      'layout: ${layoutDuration.inMicroseconds}us, '
      'paint: ${paintDuration.inMicroseconds}us, '
      'total: ${totalDuration.inMicroseconds}us)';
}

/// Combined snapshot of both runtime and widget-level metrics.
///
/// This merges the TUI runtime's renderer metrics (actual FPS, frame times)
/// with the widget layer's phase breakdown (build/layout/paint).
class PerformanceMetricsSnapshot {
  const PerformanceMetricsSnapshot({
    this.renderMetrics,
    required this.widgetTimings,
    required this.widgetFrameCount,
  });

  /// Runtime-level renderer metrics (may be null if not yet received).
  final RenderMetrics? renderMetrics;

  /// Recent widget-level frame timings.
  final List<WidgetFrameTiming> widgetTimings;

  /// Total widget frames rendered.
  final int widgetFrameCount;

  /// Average widget build duration across recent frames.
  Duration get averageBuildDuration {
    if (widgetTimings.isEmpty) return Duration.zero;
    final total = widgetTimings.fold<int>(
      0,
      (sum, t) => sum + t.buildDuration.inMicroseconds,
    );
    return Duration(microseconds: total ~/ widgetTimings.length);
  }

  /// Average widget layout duration across recent frames.
  Duration get averageLayoutDuration {
    if (widgetTimings.isEmpty) return Duration.zero;
    final total = widgetTimings.fold<int>(
      0,
      (sum, t) => sum + t.layoutDuration.inMicroseconds,
    );
    return Duration(microseconds: total ~/ widgetTimings.length);
  }

  /// Average widget paint duration across recent frames.
  Duration get averagePaintDuration {
    if (widgetTimings.isEmpty) return Duration.zero;
    final total = widgetTimings.fold<int>(
      0,
      (sum, t) => sum + t.paintDuration.inMicroseconds,
    );
    return Duration(microseconds: total ~/ widgetTimings.length);
  }

  /// Average total widget frame duration.
  Duration get averageTotalDuration {
    if (widgetTimings.isEmpty) return Duration.zero;
    final total = widgetTimings.fold<int>(
      0,
      (sum, t) => sum + t.totalDuration.inMicroseconds,
    );
    return Duration(microseconds: total ~/ widgetTimings.length);
  }

  /// Number of slow frames (>16.67ms) in the recent window.
  int get slowFrameCount => widgetTimings.where((t) => t.isSlowFrame).length;

  /// Percentage of slow frames in the recent window.
  double get slowFramePercentage {
    if (widgetTimings.isEmpty) return 0.0;
    return (slowFrameCount / widgetTimings.length) * 100.0;
  }
}
