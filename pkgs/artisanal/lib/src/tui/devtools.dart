/// DevTools integration for artisanal TUI programs.
///
/// Provides Timeline events, VM service extensions, and live event
/// streaming (`postEvent`) for the Dart DevTools ecosystem.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal/tui.dart';
///
/// void main() async {
///   await runProgram(
///     MyModel(),
///     options: ProgramOptions(
///       interceptor: ArtisanalDevTools(),
///     ),
///   );
/// }
/// ```
///
/// ## Timeline Events
///
/// When connected to DevTools, the Performance tab shows:
/// - **artisanal.message** — message dispatch through model.update()
/// - **artisanal.render** — view generation and terminal rendering
/// - **artisanal.init** — program initialization
/// - **artisanal.cleanup** — program shutdown
///
/// ## Service Extensions
///
/// The following `ext.artisanal.*` extensions are registered when
/// [ArtisanalDevTools] is active:
///
/// - `ext.artisanal.getState` — returns current model toString, running
///   status, render generation, and queue depth
/// - `ext.artisanal.getMessageLog` — returns the last N dispatched messages
/// - `ext.artisanal.getRenderStats` — returns render timing statistics
/// - `ext.artisanal.getOptions` — returns the active ProgramOptions summary
///
/// ## Live Event Stream
///
/// When a DevTools extension is listening, structured events are emitted
/// via `dart:developer` `postEvent`:
///
/// - `artisanal:message` — each message dispatched
/// - `artisanal:render` — each render frame
/// - `artisanal:state` — model state snapshot after each update
library;

import 'dart:convert';
import 'dart:developer' as dev;

import 'degradation.dart';
import 'msg.dart';
import 'program.dart';
import 'terminal_native_frame.dart';

/// Maximum number of message log entries retained in the ring buffer.
const int _defaultMaxLogEntries = 500;

/// A recorded message dispatch entry for the message log.
final class DevToolsMessageEntry {
  /// Creates a message log entry.
  const DevToolsMessageEntry({
    required this.timestamp,
    required this.messageType,
    required this.summary,
    required this.processingTime,
  });

  /// Wall-clock time when the message was dispatched.
  final DateTime timestamp;

  /// The runtime type name of the message.
  final String messageType;

  /// A short human-readable summary of the message.
  final String summary;

  /// How long the message took to process (from `onProcessed`).
  final Duration processingTime;

  /// Serializes this entry to a JSON-compatible map.
  Map<String, Object?> toJson() => <String, Object?>{
    'timestamp': timestamp.toIso8601String(),
    'messageType': messageType,
    'summary': summary,
    'processingTimeUs': processingTime.inMicroseconds,
  };
}

/// Render timing statistics accumulated over the program lifetime.
final class DevToolsRenderStats {
  int _frameCount = 0;
  int _totalRenderUs = 0;
  int _minRenderUs = 0;
  int _maxRenderUs = 0;
  int _lastRenderUs = 0;
  DegradationLevel _lastDegradation = DegradationLevel.full;
  int? _lastWidth;
  int? _lastHeight;

  /// Records a render frame.
  void record({
    required Duration renderDuration,
    required DegradationLevel degradationLevel,
    int? width,
    int? height,
  }) {
    final us = renderDuration.inMicroseconds;
    _frameCount++;
    _totalRenderUs += us;
    _lastRenderUs = us;
    if (_frameCount == 1) {
      _minRenderUs = us;
      _maxRenderUs = us;
    } else {
      if (us < _minRenderUs) _minRenderUs = us;
      if (us > _maxRenderUs) _maxRenderUs = us;
    }
    _lastDegradation = degradationLevel;
    _lastWidth = width;
    _lastHeight = height;
  }

  /// Serializes current stats to a JSON-compatible map.
  Map<String, Object?> toJson() => <String, Object?>{
    'frameCount': _frameCount,
    'totalRenderUs': _totalRenderUs,
    'avgRenderUs': _frameCount > 0 ? (_totalRenderUs / _frameCount).round() : 0,
    'minRenderUs': _minRenderUs,
    'maxRenderUs': _maxRenderUs,
    'lastRenderUs': _lastRenderUs,
    'lastDegradation': _lastDegradation.name,
    'lastWidth': _lastWidth,
    'lastHeight': _lastHeight,
  };
}

/// DevTools integration for artisanal TUI programs.
///
/// Implements [ProgramInterceptor] to hook into the program lifecycle and
/// provide Timeline events, service extensions, and live event streaming.
///
/// When an existing interceptor is already configured, pass it as [inner]
/// to compose both:
///
/// ```dart
/// final recorder = ProgramRenderRecorder();
/// final devtools = ArtisanalDevTools(inner: recorder);
/// final program = Program(model, options: ProgramOptions(interceptor: devtools));
/// ```
class ArtisanalDevTools extends ProgramInterceptor {
  /// Creates a DevTools bridge.
  ///
  /// [inner] is an optional interceptor to delegate to (decorator pattern).
  /// [maxLogEntries] controls the ring buffer size for the message log.
  /// [enableTimeline] controls whether `dart:developer` Timeline events
  /// are emitted (default: true).
  /// [enablePostEvent] controls whether live `postEvent` streaming is
  /// active (default: true).
  /// [enableServiceExtensions] controls whether `ext.artisanal.*` VM
  /// service extensions are registered (default: true).
  ArtisanalDevTools({
    this.inner,
    this.maxLogEntries = _defaultMaxLogEntries,
    this.enableTimeline = true,
    this.enablePostEvent = true,
    this.enableServiceExtensions = true,
  });

  /// Optional inner interceptor to delegate to.
  final ProgramInterceptor? inner;

  /// Maximum message log entries to retain.
  final int maxLogEntries;

  /// Whether to emit Timeline events.
  final bool enableTimeline;

  /// Whether to emit postEvent for live streaming.
  final bool enablePostEvent;

  /// Whether to register VM service extensions.
  final bool enableServiceExtensions;

  // --- Internal state ---

  void Function(Msg msg)? _send;
  final List<DevToolsMessageEntry> _messageLog = <DevToolsMessageEntry>[];
  final DevToolsRenderStats _renderStats = DevToolsRenderStats();
  int _renderGeneration = 0;
  bool _running = false;
  int _queuedMessageCount = 0;
  String _lastModelString = '';
  bool _extensionsRegistered = false;
  ProgramOptions? _options;

  // Track the last few messages for the pending-message timeline flow.
  Msg? _currentMsg;
  final Stopwatch _messageSw = Stopwatch();

  /// Provides read-only access to render stats for testing.
  DevToolsRenderStats get renderStats => _renderStats;

  /// Provides read-only access to the message log for testing.
  List<DevToolsMessageEntry> get messageLog =>
      List<DevToolsMessageEntry>.unmodifiable(_messageLog);

  /// Whether the DevTools bridge is currently active.
  bool get isRunning => _running;

  // -----------------------------------------------------------------------
  // ProgramInterceptor overrides
  // -----------------------------------------------------------------------

  @override
  bool get wantsNativeFrames => inner?.wantsNativeFrames ?? false;

  @override
  void onStart(void Function(Msg msg) send) {
    _send = send;
    _running = true;
    _messageLog.clear();

    if (enableServiceExtensions && !_extensionsRegistered) {
      _registerServiceExtensions();
      _extensionsRegistered = true;
    }

    if (enablePostEvent) {
      dev.postEvent('artisanal:start', <String, Object?>{
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    inner?.onStart(send);
  }

  @override
  Msg? onSend(Msg msg) {
    _queuedMessageCount++;

    // Let inner interceptor transform/drop the message first.
    final innerResult = inner?.onSend(msg);
    // If the inner interceptor exists and dropped the message, propagate.
    if (inner != null && innerResult == null) return null;
    final transformed = innerResult ?? msg;

    // Begin Timeline span for message processing.
    if (enableTimeline) {
      _currentMsg = transformed;
      _messageSw
        ..reset()
        ..start();
      dev.Timeline.startSync(
        'artisanal.message',
        arguments: <String, String>{
          'type': transformed.runtimeType.toString(),
          'summary': _summarizeMsg(transformed),
        },
      );
    }

    return transformed;
  }

  @override
  void onProcessed(Msg msg, Duration elapsed) {
    // End Timeline span.
    if (enableTimeline && identical(msg, _currentMsg)) {
      dev.Timeline.finishSync();
      _messageSw.stop();
      _currentMsg = null;
    }

    // Record in the message log ring buffer.
    final entry = DevToolsMessageEntry(
      timestamp: DateTime.now(),
      messageType: msg.runtimeType.toString(),
      summary: _summarizeMsg(msg),
      processingTime: elapsed,
    );
    _messageLog.add(entry);
    if (_messageLog.length > maxLogEntries) {
      _messageLog.removeAt(0);
    }

    // Emit live event.
    if (enablePostEvent) {
      dev.postEvent('artisanal:message', <String, Object?>{...entry.toJson()});
    }

    _queuedMessageCount--;
    inner?.onProcessed(msg, elapsed);
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
    _renderGeneration = renderGeneration;
    _renderStats.record(
      renderDuration: renderDuration,
      degradationLevel: degradationLevel,
      width: width,
      height: height,
    );

    if (enableTimeline) {
      dev.Timeline.timeSync(
        'artisanal.render',
        () {},
        arguments: <String, String>{
          'generation': renderGeneration.toString(),
          'durationUs': renderDuration.inMicroseconds.toString(),
          'degradation': degradationLevel.name,
          if (width != null) 'width': width.toString(),
          if (height != null) 'height': height.toString(),
        },
      );
    }

    if (enablePostEvent) {
      dev.postEvent('artisanal:render', <String, Object?>{
        'generation': renderGeneration,
        'durationUs': renderDuration.inMicroseconds,
        'degradation': degradationLevel.name,
        'width': width,
        'height': height,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    inner?.onRendered(
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

  @override
  void onStop() {
    _running = false;

    if (enablePostEvent) {
      dev.postEvent('artisanal:stop', <String, Object?>{
        'timestamp': DateTime.now().toIso8601String(),
        'totalFrames': _renderStats._frameCount,
        'totalMessages': _messageLog.length,
      });
    }

    inner?.onStop();
  }

  // -----------------------------------------------------------------------
  // Service Extensions
  // -----------------------------------------------------------------------

  void _registerServiceExtensions() {
    // ext.artisanal.getState
    dev.registerExtension('ext.artisanal.getState', (
      String method,
      Map<String, String> parameters,
    ) async {
      final result = <String, Object?>{
        'running': _running,
        'renderGeneration': _renderGeneration,
        'pendingMessages': _queuedMessageCount,
        'lastModel': _lastModelString,
      };
      return dev.ServiceExtensionResponse.result(jsonEncode(result));
    });

    // ext.artisanal.getMessageLog
    dev.registerExtension('ext.artisanal.getMessageLog', (
      String method,
      Map<String, String> parameters,
    ) async {
      final count = int.tryParse(parameters['count'] ?? '') ?? 50;
      final start = _messageLog.length > count ? _messageLog.length - count : 0;
      final entries = _messageLog
          .sublist(start)
          .map((e) => e.toJson())
          .toList();
      return dev.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{'entries': entries}),
      );
    });

    // ext.artisanal.getRenderStats
    dev.registerExtension('ext.artisanal.getRenderStats', (
      String method,
      Map<String, String> parameters,
    ) async {
      return dev.ServiceExtensionResponse.result(
        jsonEncode(_renderStats.toJson()),
      );
    });

    // ext.artisanal.getOptions
    dev.registerExtension('ext.artisanal.getOptions', (
      String method,
      Map<String, String> parameters,
    ) async {
      final opts = _options;
      final result = <String, Object?>{
        'altScreen': opts?.altScreen,
        'screenMode': opts?.effectiveScreenMode.name,
        'mouse': opts?.mouse,
        'mouseMode': opts?.mouseMode.name,
        'fps': opts?.fps,
        'frameTick': opts?.frameTick,
        'hideCursor': opts?.hideCursor,
        'bracketedPaste': opts?.bracketedPaste,
        'catchPanics': opts?.catchPanics,
        'hotReload': opts?.hotReload,
        'captureOutput': opts?.captureOutput,
        'useUltravioletRenderer': opts?.useUltravioletRenderer,
        'useUltravioletInputDecoder': opts?.useUltravioletInputDecoder,
        'renderBudget': opts?.renderBudget.toString(),
      };
      return dev.ServiceExtensionResponse.result(jsonEncode(result));
    });

    // ext.artisanal.sendCustomMessage
    dev.registerExtension('ext.artisanal.sendCustomMessage', (
      String method,
      Map<String, String> parameters,
    ) async {
      final send = _send;
      if (send == null || !_running) {
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.extensionError,
          'Program is not running',
        );
      }
      final value = parameters['value'];
      if (value == null || value.isEmpty) {
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.invalidParams,
          'Missing required "value" parameter',
        );
      }
      send(CustomMsg(value));
      return dev.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{'sent': true, 'value': value}),
      );
    });

    // ext.artisanal.requestRepaint
    dev.registerExtension('ext.artisanal.requestRepaint', (
      String method,
      Map<String, String> parameters,
    ) async {
      final send = _send;
      if (send == null || !_running) {
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.extensionError,
          'Program is not running',
        );
      }
      send(const RepaintMsg());
      return dev.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{'repainted': true}),
      );
    });
  }

  // -----------------------------------------------------------------------
  // Configuration hook
  // -----------------------------------------------------------------------

  /// Called by [Program] to pass the resolved options for service extension
  /// queries. This is set internally and should not be called by consumers.
  void bindOptions(ProgramOptions options) {
    _options = options;
  }

  /// Updates the cached model string for `ext.artisanal.getState`.
  ///
  /// Called internally by the program after each model update.
  void updateModelSnapshot(Object? model) {
    _lastModelString = model?.toString() ?? '<null>';
  }

  // -----------------------------------------------------------------------
  // Message summarization
  // -----------------------------------------------------------------------

  static String _summarizeMsg(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key) =>
        'key: ${key.type.name}${key.runes.isNotEmpty ? ' runes=${key.runes}' : ''}',
      MouseMsg(:final action, :final button, :final x, :final y) =>
        'mouse: ${action.name} ${button.name} ($x,$y)',
      WindowSizeMsg(:final width, :final height) => 'resize: ${width}x$height',
      TickMsg() => 'tick',
      FrameTickMsg() => 'frameTick',
      QuitMsg() => 'quit',
      FocusMsg(:final focused) => 'focus: $focused',
      CustomMsg(:final value) => 'custom: $value',
      HotReloadStatusMsg(:final status) => 'hotReload: ${status.name}',
      CapturedOutputMsg(:final line, :final source) =>
        'output(${source.name}): ${line.length > 60 ? '${line.substring(0, 60)}...' : line}',
      RenderMetricsMsg() => 'renderMetrics',
      RenderBudgetMsg() => 'renderBudget',
      RepaintMsg() => 'repaint',
      InterruptMsg() => 'interrupt',
      PasteMsg() => 'paste',
      BatchMsg() => 'batch',
      _ => msg.runtimeType.toString(),
    };
  }
}
