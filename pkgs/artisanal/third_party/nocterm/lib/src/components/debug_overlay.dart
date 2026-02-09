import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:nocterm/nocterm.dart';

/// Global debug mode state for nocterm applications.
///
/// When debug mode is enabled, the [DebugOverlay] will display performance
/// metrics and the framework will enable extended logging.
///
/// Debug mode can be toggled at runtime using [Ctrl+G].
///
/// Example:
/// ```dart
/// // Check if debug mode is enabled
/// if (debugMode) {
///   print('Debug logging enabled');
/// }
///
/// // Programmatically toggle debug mode
/// debugMode = true;
/// ```
bool debugMode = false;

/// Callback signature for debug mode changes.
typedef DebugModeCallback = void Function(bool enabled);

/// Listeners for debug mode changes.
final List<DebugModeCallback> _debugModeListeners = [];

/// Add a listener for debug mode changes.
void addDebugModeListener(DebugModeCallback callback) {
  _debugModeListeners.add(callback);
}

/// Remove a listener for debug mode changes.
void removeDebugModeListener(DebugModeCallback callback) {
  _debugModeListeners.remove(callback);
}

/// Toggle debug mode and notify listeners.
void toggleDebugMode() {
  debugMode = !debugMode;
  for (final listener in _debugModeListeners) {
    listener(debugMode);
  }
  if (debugMode) {
    // Enable repaint rainbow when entering debug mode
    debugRepaintRainbowEnabled = true;
    // Start detailed profiling
    try {
      final binding = NoctermBinding.instance;
      if (binding is TerminalBinding) {
        binding.startDetailedProfiling();
      }
    } catch (_) {}
  } else {
    // Disable repaint rainbow when leaving debug mode
    debugRepaintRainbowEnabled = false;
    // Stop detailed profiling
    try {
      final binding = NoctermBinding.instance;
      if (binding is TerminalBinding) {
        binding.stopDetailedProfiling();
      }
    } catch (_) {}
  }
}

/// A visual overlay that displays real-time debug information and performance metrics.
///
/// This overlay is designed to be used during development to understand
/// performance characteristics and debug rendering issues.
///
/// The overlay shows:
/// - Current frame number and frame time
/// - FPS (actual and target)
/// - Build/layout/paint phase timings
/// - Slow frame count and warnings
/// - Repaint rainbow status
///
/// ## Automatic Integration
///
/// **Every nocterm app automatically has debug overlay support!**
/// Just press [Ctrl+G] at any time to toggle the debug overlay.
/// No manual wrapping required - it's built into [runApp].
///
/// ## Debug Key
///
/// The debug key is [Ctrl+G]. This sends a unique control character (0x07)
/// that is rarely used by applications.
///
/// ## Extended Logging
///
/// When debug mode is enabled, detailed profiling information is logged
/// every 5 seconds. View logs using `nocterm logs` in another terminal.
///
/// ## Manual Usage (Optional)
///
/// If you need custom configuration, you can still wrap components manually:
///
/// ```dart
/// DebugOverlay(
///   maxSamples: 200,  // Keep more frame samples
///   child: MyComponent(),
/// )
/// ```
class DebugOverlay extends StatefulComponent {
  const DebugOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.maxSamples = 120,
  });

  /// The child widget to wrap.
  final Component child;

  /// Whether the debug overlay feature is enabled.
  ///
  /// When false, the overlay cannot be toggled and the key combination
  /// is ignored. Defaults to true.
  final bool enabled;

  /// Maximum number of frame samples to keep for averaging.
  final int maxSamples;

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  final Queue<FrameTiming> _recentFrames = Queue<FrameTiming>();
  FrameTiming? _lastFrame;
  int _slowFrameCount = 0;
  FrameTimingCallback? _frameCallback;
  DebugModeCallback? _debugModeCallback;
  Timer? _updateTimer;

  /// Track actual FPS (frames counted per update interval)
  int _frameCountSinceLastUpdate = 0;
  double _actualFps = 0.0;

  /// Track CPU usage (frame time as % of wall time)
  int _frameMicrosecondsSinceLastUpdate = 0;
  double _cpuUsagePercent = 0.0;

  /// Update interval for the overlay display (1 second).
  /// Frame data is still collected every frame, but UI only updates periodically
  /// to avoid causing an infinite render loop.
  static const _updateInterval = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _frameCallback = _onFrameTiming;
    _debugModeCallback = _onDebugModeChanged;
    SchedulerBinding.instance.addFrameTimingCallback(_frameCallback!);
    addDebugModeListener(_debugModeCallback!);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    if (_frameCallback != null) {
      SchedulerBinding.instance.removeFrameTimingCallback(_frameCallback!);
    }
    if (_debugModeCallback != null) {
      removeDebugModeListener(_debugModeCallback!);
    }
    super.dispose();
  }

  void _onDebugModeChanged(bool enabled) {
    if (enabled) {
      // Start periodic updates when debug mode is enabled
      _updateTimer?.cancel();
      _frameCountSinceLastUpdate = 0;
      _frameMicrosecondsSinceLastUpdate = 0;
      _updateTimer = Timer.periodic(_updateInterval, (_) {
        if (debugMode && _lastFrame != null) {
          // Calculate actual FPS based on frames counted in the last interval
          _actualFps = _frameCountSinceLastUpdate.toDouble();

          // Calculate CPU usage as frame processing time / wall clock time
          // _updateInterval is 1 second = 1,000,000 microseconds
          _cpuUsagePercent =
              _frameMicrosecondsSinceLastUpdate / 10000.0; // Convert to %

          _frameCountSinceLastUpdate = 0;
          _frameMicrosecondsSinceLastUpdate = 0;
          setState(() {});
        }
      });
    } else {
      // Stop timer and clear stats when debug mode is disabled
      _updateTimer?.cancel();
      _updateTimer = null;
      _recentFrames.clear();
      _slowFrameCount = 0;
      _lastFrame = null;
      _frameCountSinceLastUpdate = 0;
      _frameMicrosecondsSinceLastUpdate = 0;
      _actualFps = 0.0;
      _cpuUsagePercent = 0.0;
    }
    // Immediate setState to show/hide overlay
    setState(() {});
  }

  void _onFrameTiming(FrameTiming timing) {
    if (!debugMode) return;

    // Collect data without triggering a rebuild
    // UI updates happen via the periodic timer instead
    _lastFrame = timing;
    _recentFrames.add(timing);
    _frameCountSinceLastUpdate++;
    _frameMicrosecondsSinceLastUpdate += timing.totalDuration.inMicroseconds;
    if (timing.isSlowFrame) {
      _slowFrameCount++;
    }
    while (_recentFrames.length > component.maxSamples) {
      _recentFrames.removeFirst();
    }
  }

  double get _averageFrameTime {
    if (_recentFrames.isEmpty) return 0.0;
    final total = _recentFrames.fold<int>(
      0,
      (sum, frame) => sum + frame.totalDuration.inMicroseconds,
    );
    return total / _recentFrames.length / 1000.0; // Convert to ms
  }

  @override
  Component build(BuildContext context) {
    // Always use Stack to preserve the child widget tree.
    // If we conditionally switch between returning child directly vs wrapping
    // it in a Stack, the child will rebuild from scratch when debug mode toggles.
    // Instead, we always wrap in Stack and conditionally show/hide the overlay.
    final showOverlay = debugMode && component.enabled;

    return Stack(
      fit: StackFit.expand,
      children: [
        component.child,
        if (showOverlay)
          Positioned(
            top: 0,
            right: 0,
            child: _buildOverlay(),
          ),
      ],
    );
  }

  Component _buildOverlay() {
    final stats = _buildStatsText();
    final lines = stats.split('\n');
    final maxWidth =
        lines.map((l) => l.length).reduce((a, b) => a > b ? a : b) + 2;
    final totalHeight = lines.length + 2;

    return Container(
      width: maxWidth.toDouble(),
      height: totalHeight.toDouble(),
      decoration: const BoxDecoration(
        color: Color(0xDD000000),
        border: BoxBorder(
          left: BorderSide(color: Color(0xFFFFFF00)),
          bottom: BorderSide(color: Color(0xFFFFFF00)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Text(
          stats,
          style: const TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  String _buildStatsText() {
    final buffer = StringBuffer();

    buffer.writeln('🔧 DEBUG MODE (Ctrl+G to close)');
    buffer.writeln('─' * 36);

    if (_lastFrame == null) {
      buffer.writeln('Waiting for frames...');
      return buffer.toString();
    }

    // Current frame
    final lastFrameMs = _lastFrame!.totalDuration.inMicroseconds / 1000.0;
    final frameStatus = _lastFrame!.isSlowFrame ? '🔴 SLOW' : '🟢 OK';
    buffer.writeln(
        'Frame #${_lastFrame!.frameNumber}: ${lastFrameMs.toStringAsFixed(2)}ms $frameStatus');

    // FPS info - show actual measured FPS
    final targetFps = SchedulerBinding.instance.targetFps.toStringAsFixed(0);
    final limiting = SchedulerBinding.instance.enableFrameRateLimiting;
    buffer.writeln(
        'FPS: ${_actualFps.toStringAsFixed(0)} / ${limiting ? targetFps : "∞"} target');
    buffer.writeln('Avg frame: ${_averageFrameTime.toStringAsFixed(2)}ms');

    // Slow frame count
    if (_slowFrameCount > 0) {
      final slowPct =
          (_slowFrameCount / _recentFrames.length * 100).toStringAsFixed(1);
      buffer.writeln('⚠️  Slow frames: $_slowFrameCount ($slowPct%)');
    }

    buffer.writeln('─' * 36);

    // Phase breakdown
    final buildMs = _lastFrame!.buildDuration.inMicroseconds / 1000.0;
    final layoutMs = _lastFrame!.layoutDuration.inMicroseconds / 1000.0;
    final paintMs = _lastFrame!.paintDuration.inMicroseconds / 1000.0;
    buffer.writeln('Build:  ${buildMs.toStringAsFixed(2)}ms');
    buffer.writeln('Layout: ${layoutMs.toStringAsFixed(2)}ms');
    buffer.writeln('Paint:  ${paintMs.toStringAsFixed(2)}ms');

    buffer.writeln('─' * 36);

    // CPU usage (frame processing time as % of wall time)
    final cpuStr = _cpuUsagePercent.toStringAsFixed(1);
    final cpuIndicator =
        _cpuUsagePercent > 50 ? '🔴' : (_cpuUsagePercent > 20 ? '🟡' : '🟢');
    buffer.writeln('CPU: $cpuStr% $cpuIndicator (frame time)');

    // Memory usage
    final currentRss = ProcessInfo.currentRss;
    final maxRss = ProcessInfo.maxRss;
    buffer.writeln('Memory: ${_formatBytes(currentRss)}');
    buffer.writeln('Peak:   ${_formatBytes(maxRss)}');

    buffer.writeln('─' * 36);

    // Debug features status
    buffer.writeln(
        'Repaint rainbow: ${debugRepaintRainbowEnabled ? "ON 🌈" : "OFF"}');
    buffer.write('Samples: ${_recentFrames.length}/${component.maxSamples}');

    return buffer.toString();
  }
}
