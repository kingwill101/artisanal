
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Border, Style, Colors;

/// A debug overlay that displays rendering metrics.
///
/// Reads runtime [RenderMetrics] from [RenderMetricsProvider] (populated
/// by [WidgetApp]) rather than receiving [RenderMetricsMsg] via
/// `handleUpdate`. This avoids dispatching metrics messages through the
/// entire widget tree, which was a major source of unnecessary rebuilds.
///
/// Requires [WidgetApp.enableRenderMetrics] to be `true` (the default) for
/// runtime FPS data. Without it, the overlay still shows widget frame counts.
///
/// ```dart
/// DebugOverlay(
///   enabled: true,
///   child: MyApp(),
/// )

// ignore_for_file: unused_shown_name
/// ```
class DebugOverlay extends StatefulWidget {
  DebugOverlay({
    required this.child,
    this.enabled = true,
    this.position = DebugOverlayPosition.topRight,
    DateTime Function()? nowProvider,
    super.key,
  }) : nowProvider = nowProvider ?? DateTime.now;

  /// The main content underneath the overlay.
  final Widget child;

  /// Whether the overlay is visible.
  final bool enabled;

  /// Where to position the overlay.
  final DebugOverlayPosition position;

  /// Logical clock used for fallback frame/update timing.
  final DateTime Function() nowProvider;

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

/// Position options for the debug overlay.
enum DebugOverlayPosition { topLeft, topRight, bottomLeft, bottomRight }

class _DebugOverlayState extends State<DebugOverlay> {
  // Widget-layer tracking as a fallback / supplement.
  int _widgetFrameCount = 0;
  DateTime? _lastUpdateTime;
  final List<double> _updateIntervals = [];

  @override
  Cmd? handleUpdate(Msg msg) {
    // Track widget-layer update frequency as a supplement.
    final now = widget.nowProvider();
    if (_lastUpdateTime != null) {
      final delta = now.difference(_lastUpdateTime!).inMicroseconds / 1000.0;
      _updateIntervals.add(delta);
      if (_updateIntervals.length > 60) _updateIntervals.removeAt(0);
    }
    _lastUpdateTime = now;
    _widgetFrameCount++;

    return super.handleUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final overlayStyle = Style()
      ..foreground(Colors.green)
      ..dim();

    // Pull latest metrics from RenderMetricsProvider (written in-place
    // by WidgetApp without triggering tree rebuilds).
    final holder = RenderMetricsProvider.maybeOf(context);
    final RenderMetrics? m = holder?.metrics;
    final customMetrics = holder?.customMetrics ?? const <String, String>{};

    final info = StringBuffer();

    if (m != null) {
      final avgFrameMs = m.averageFrameTime.inMicroseconds / 1000.0;
      final avgRenderMs = m.averageRenderDuration.inMicroseconds / 1000.0;
      info.writeln('FPS: ${m.averageFps.toStringAsFixed(1)}');
      info.writeln('Avg frame: ${avgFrameMs.toStringAsFixed(1)}ms');
      info.writeln('Avg render: ${avgRenderMs.toStringAsFixed(1)}ms');
      info.writeln('Frames: ${m.frameCount}');
      if (m.skippedFrames > 0) {
        info.writeln('Skipped: ${m.skippedFrames}');
      }
    } else {
      // Fallback: estimate from update intervals when runtime metrics
      // are not available (e.g., enableRenderMetrics is false or in tests).
      if (_updateIntervals.isNotEmpty) {
        final avgMs =
            _updateIntervals.reduce((a, b) => a + b) / _updateIntervals.length;
        final estimatedFps = avgMs > 0 ? 1000.0 / avgMs : 0.0;
        info.writeln('FPS: ~${estimatedFps.toStringAsFixed(1)}');
        info.writeln('Avg: ${avgMs.toStringAsFixed(1)}ms');
      } else {
        info.writeln('FPS: 0.0');
      }
      info.writeln('Frames: $_widgetFrameCount');
    }

    for (final entry in customMetrics.entries) {
      info.writeln('${entry.key}: ${entry.value}');
    }

    final overlay = Container(
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(color: Colors.black, border: Border.normal),
      child: Text(info.toString().trimRight(), style: overlayStyle),
    );

    final alignment = switch (widget.position) {
      DebugOverlayPosition.topLeft => Alignment.topLeft,
      DebugOverlayPosition.topRight => Alignment.topRight,
      DebugOverlayPosition.bottomLeft => Alignment.bottomLeft,
      DebugOverlayPosition.bottomRight => Alignment.bottomRight,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: Align(alignment: alignment, child: overlay),
        ),
      ],
    );
  }
}

/// A simpler variant of [DebugOverlay] that only shows render timing.
///
/// When runtime [RenderMetrics] data is available (via [RenderMetricsProvider]),
/// shows real frame time and FPS. Otherwise falls back to measuring
/// inter-update intervals.
///
/// ```dart
/// PerformanceOverlay(
///   enabled: true,
///   child: MyApp(),
/// )
/// ```
class PerformanceOverlay extends StatefulWidget {
  PerformanceOverlay({
    required this.child,
    this.enabled = true,
    DateTime Function()? nowProvider,
    super.key,
  }) : nowProvider = nowProvider ?? DateTime.now;

  /// The main content underneath the overlay.
  final Widget child;

  /// Whether the overlay is visible.
  final bool enabled;

  /// Logical clock used for fallback frame/update timing.
  final DateTime Function() nowProvider;

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  // Fallback tracking.
  int _widgetFrameCount = 0;
  DateTime? _lastUpdateTime;
  double _lastUpdateDeltaMs = 0.0;

  @override
  Cmd? handleUpdate(Msg msg) {
    final now = widget.nowProvider();
    if (_lastUpdateTime != null) {
      _lastUpdateDeltaMs =
          now.difference(_lastUpdateTime!).inMicroseconds / 1000.0;
    }
    _lastUpdateTime = now;
    _widgetFrameCount++;

    return super.handleUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final perfStyle = Style()
      ..foreground(Colors.yellow)
      ..dim();

    // Pull latest metrics from RenderMetricsProvider.
    final holder = RenderMetricsProvider.maybeOf(context);
    final RenderMetrics? m = holder?.metrics;

    final String text;
    if (m != null) {
      final lastFrameMs = m.lastFrameTime.inMicroseconds / 1000.0;
      text =
          'Frame ${m.frameCount} | '
          '${lastFrameMs.toStringAsFixed(1)}ms | '
          '${m.averageFps.toStringAsFixed(0)} FPS';
    } else {
      text =
          'Frame $_widgetFrameCount | '
          '${_lastUpdateDeltaMs.toStringAsFixed(1)}ms';
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Text(text, style: perfStyle),
          ),
        ),
      ],
    );
  }
}
