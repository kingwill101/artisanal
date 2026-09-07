import 'dart:async';

import 'bubbles/debug_overlay.dart';
import 'devtools.dart';
import 'key.dart' show KeyType;
import 'key_binding.dart';
import 'model.dart' show OutputLogEntry;
import 'msg.dart';
import 'view.dart';

/// Configuration for the universal in-app program diagnostics overlay.
final class ProgramDiagnosticsOptions {
  ProgramDiagnosticsOptions({
    this.initiallyVisible = false,
    KeyBinding? toggleBinding,
    this.maxMessages = 8,
    this.position = ProgramDiagnosticsPosition.topRight,
    this.captureOutput = true,
  }) : toggleBinding =
           toggleBinding ??
           KeyBinding.withHelp(['f12'], 'F12', 'toggle developer tools');

  /// Whether the overlay starts visible.
  final bool initiallyVisible;

  /// Binding consumed by [Program] to toggle the overlay.
  final KeyBinding toggleBinding;

  /// Maximum number of recent runtime messages displayed.
  final int maxMessages;

  final ProgramDiagnosticsPosition position;

  /// Whether `print()` calls are captured into the diagnostics session.
  final bool captureOutput;
}

enum ProgramDiagnosticsPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Shared registry for metrics contributed by applications and frameworks.
abstract final class ProgramDiagnosticsMetrics {
  static final Map<String, String> _values = {};
  static final StreamController<Map<String, String>> _changes =
      StreamController<Map<String, String>>.broadcast(sync: true);

  /// Current custom metrics.
  static Map<String, String> get values => Map.unmodifiable(_values);

  /// Emits a snapshot whenever custom metrics change.
  static Stream<Map<String, String>> get changes => _changes.stream;

  /// Adds or updates one metric.
  static void setMetric(String key, Object? value) {
    _values[key] = value?.toString() ?? 'null';
    _emit();
  }

  /// Adds or updates multiple metrics.
  static void setMetrics(Map<String, Object?> values, {bool replace = false}) {
    if (replace) _values.clear();
    for (final entry in values.entries) {
      _values[entry.key] = entry.value?.toString() ?? 'null';
    }
    _emit();
  }

  /// Removes one metric.
  static void removeMetric(String key) {
    if (_values.remove(key) != null) _emit();
  }

  /// Removes all custom metrics.
  static void clear() {
    if (_values.isEmpty) return;
    _values.clear();
    _emit();
  }

  static void _emit() => _changes.add(values);
}

/// The single diagnostics data store owned by one running [Program].
final class ProgramDiagnostics {
  ProgramDiagnostics({this.messageCapacity = 500});

  final int messageCapacity;
  final DevToolsRenderStats renderStats = DevToolsRenderStats();
  final List<DevToolsMessageEntry> _messages = [];
  final List<OutputLogEntry> _output = [];
  Map<String, String> _customMetrics = const {};

  List<DevToolsMessageEntry> get messages => List.unmodifiable(_messages);
  List<OutputLogEntry> get output => List.unmodifiable(_output);
  Map<String, String> get customMetrics => _customMetrics;

  void reset() {
    _messages.clear();
    _output.clear();
  }

  void recordMessage(Msg msg, Duration elapsed) {
    _messages.add(
      DevToolsMessageEntry(
        timestamp: DateTime.now(),
        messageType: msg.runtimeType.toString(),
        summary: ArtisanalDevTools.summarizeMessage(msg),
        processingTime: elapsed,
      ),
    );
    if (_messages.length > messageCapacity) _messages.removeAt(0);
    if (msg case CapturedOutputMsg(:final line, :final source)) {
      _output.add(
        OutputLogEntry(line: line, source: source, timestamp: DateTime.now()),
      );
      if (_output.length > messageCapacity) _output.removeAt(0);
    }
  }

  void updateCustomMetrics(Map<String, String> metrics) {
    _customMetrics = Map.unmodifiable(metrics);
  }
}

/// Program-owned state for the universal diagnostics overlay.
final class ProgramDevToolsController {
  ProgramDevToolsController(
    ProgramDiagnosticsOptions options, {
    ProgramDiagnostics? diagnostics,
  }) : _options = options,
       diagnostics = diagnostics ?? ProgramDiagnostics(),
       _overlay = DebugOverlayModel.initial(
         enabled: options.initiallyVisible,
         title: 'Artisanal DevTools',
       );

  final ProgramDiagnosticsOptions _options;
  final ProgramDiagnostics diagnostics;
  DebugOverlayModel _overlay;
  int _revision = 0;
  int _messageOffset = 0;
  int _outputOffset = 0;

  /// Changes whenever visible overlay content changes.
  int get revision => _revision;

  /// Handles overlay input and runtime data. Returns whether [msg] was consumed.
  bool handle(Msg msg) {
    if (msg case KeyMsg() when _options.toggleBinding.matches(msg)) {
      _overlay = _overlay.toggle();
      _revision++;
      return true;
    }

    if (_overlay.enabled && msg is KeyMsg) {
      final key = msg.key;
      if (key.type == KeyType.tab) {
        final modes = DebugOverlayMode.values;
        final delta = key.shift ? -1 : 1;
        final index = (_overlay.mode.index + delta) % modes.length;
        _overlay = _overlay.copyWith(
          mode: modes[index],
          panelX: null,
          panelY: null,
        );
        _positionOverlay();
        _revision++;
        return true;
      }
      final delta = switch (key.type) {
        KeyType.up => -1,
        KeyType.down => 1,
        KeyType.pageUp => -_options.maxMessages,
        KeyType.pageDown => _options.maxMessages,
        KeyType.home => -0x7fffffff,
        KeyType.end => 0x7fffffff,
        _ => 0,
      };
      if (delta != 0) {
        _scroll(delta);
        _revision++;
        return true;
      }
    }

    final update = _overlay.update(msg);
    _overlay = update.model;
    if (msg is WindowSizeMsg) _positionOverlay();
    _syncSession();
    if (_overlay.enabled) _revision++;
    return update.consumed;
  }

  /// Applies application-contributed metrics.
  void updateCustomMetrics(Map<String, String> metrics) {
    diagnostics.updateCustomMetrics(metrics);
    _syncSession();
    if (_overlay.enabled) _revision++;
  }

  void diagnosticsChanged() {
    _syncSession();
    if (_overlay.enabled) _revision++;
  }

  /// Composes the overlay over a model's view while preserving metadata.
  Object compose(Object view) {
    if (!_overlay.enabled) return view;
    if (view case View value) {
      return View(
        content: _overlay.compose(value.content),
        onMouse: value.onMouse,
        cursor: value.cursor,
        backgroundColor: value.backgroundColor,
        foregroundColor: value.foregroundColor,
        windowTitle: value.windowTitle,
        progressBar: value.progressBar,
        altScreen: value.altScreen,
        reportFocus: value.reportFocus,
        bracketedPaste: value.bracketedPaste,
        mouseMode: value.mouseMode,
        keyboardEnhancements: value.keyboardEnhancements,
        degradation: value.degradation,
      );
    }
    return _overlay.compose(view.toString());
  }

  void _syncSession() {
    _overlay = _overlay.copyWith(
      customMetrics: diagnostics.customMetrics,
      messageEntries: diagnostics.messages.reversed
          .skip(_messageOffset)
          .take(_options.maxMessages)
          .toList(growable: false),
      outputEntries: diagnostics.output.reversed
          .skip(_outputOffset)
          .take(_options.maxMessages)
          .toList(growable: false),
    );
  }

  void _scroll(int delta) {
    final outputMode = _overlay.mode == DebugOverlayMode.output;
    final length = outputMode
        ? diagnostics.output.length
        : diagnostics.messages.length;
    final maxOffset = (length - _options.maxMessages).clamp(0, length);
    if (outputMode) {
      _outputOffset = (_outputOffset + delta).clamp(0, maxOffset);
    } else {
      _messageOffset = (_messageOffset + delta).clamp(0, maxOffset);
    }
    _syncSession();
  }

  void _positionOverlay() {
    final width = _overlay.terminalWidth;
    final height = _overlay.terminalHeight;
    final maxX = (width - _overlay.panelWidth).clamp(0, width);
    final maxY = (height - _overlay.panelHeight).clamp(0, height);
    final (x, y) = switch (_options.position) {
      ProgramDiagnosticsPosition.topLeft => (0, 0),
      ProgramDiagnosticsPosition.topRight => (maxX, 0),
      ProgramDiagnosticsPosition.bottomLeft => (0, maxY),
      ProgramDiagnosticsPosition.bottomRight => (maxX, maxY),
    };
    _overlay = _overlay.copyWith(panelX: x, panelY: y);
  }
}
