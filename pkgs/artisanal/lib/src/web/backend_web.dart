import 'dart:async';

import '../style/color.dart';
import '../terminal/backend.dart';
import '../terminal/terminal_base.dart';

/// A [TerminalBackend] for browser/WASM environments.
///
/// This backend:
/// - Discards ANSI output (the [WebUltravioletRenderer] renders directly
///   to a canvas, so terminal escape sequences are unused).
/// - Reports `isTerminal: false` to suppress terminal capability probing.
/// - Exposes [addInput], [notifySizeChanged], and [requestShutdown] for
///   external driving (e.g. from DOM event handlers in the bootstrap).
///
/// Use with [BackendTerminal] to create a full [Terminal] implementation
/// that the TUI runtime can consume.
final class WebTerminalBackend implements TerminalBackend {
  WebTerminalBackend({
    TerminalDimensions initialSize = const (width: 80, height: 24),
  }) : _size = initialSize;

  TerminalDimensions _size;
  bool _disposed = false;
  bool _rawMode = false;

  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();
  final StreamController<TerminalDimensions> _resizeController =
      StreamController<TerminalDimensions>.broadcast();
  final StreamController<void> _shutdownController =
      StreamController<void>.broadcast(sync: true);

  /// Pushes raw input bytes (encoded key events) into the runtime.
  void addInput(List<int> data) {
    if (!_disposed) _inputController.add(data);
  }

  /// Reports a viewport resize to the runtime and updates [size].
  void notifySizeChanged(TerminalDimensions size) {
    if (_disposed) return;
    _size = size;
    _resizeController.add(size);
  }

  /// Signals the runtime to shut down (e.g. on page close).
  void requestShutdown() {
    if (!_disposed) _shutdownController.add(null);
  }

  @override
  void writeRaw(String data) {}

  @override
  Future<void> flush() async {}

  @override
  TerminalDimensions get size => _size;

  @override
  bool get supportsAnsi => true;

  @override
  bool get isTerminal => false;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  Stream<List<int>>? get inputStream => _inputController.stream;

  @override
  Stream<TerminalDimensions>? get resizeStream => _resizeController.stream;

  @override
  Stream<void>? get shutdownStream => _shutdownController.stream;

  @override
  RawModeGuard enableRawMode() {
    _rawMode = true;
    return RawModeGuard(
      wasEchoMode: false,
      wasLineMode: false,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    _rawMode = false;
  }

  @override
  bool get isRawMode => _rawMode;

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      (useTabs: false, useBackspace: true);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _rawMode = false;
    _inputController.close();
    _resizeController.close();
    scheduleMicrotask(() {
      if (!_shutdownController.isClosed) {
        _shutdownController.close();
      }
    });
  }
}
