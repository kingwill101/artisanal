import 'dart:async';
import 'dart:io';

import 'package:nocterm/src/size.dart';

import 'terminal_backend.dart';

/// Backend for native terminal I/O via stdin/stdout.
/// Handles Unix signals (SIGWINCH, SIGINT, SIGTERM) for resize and shutdown.
class StdioBackend implements TerminalBackend {
  StreamController<Size>? _resizeController;
  StreamController<void>? _shutdownController;
  StreamSubscription? _sigwinchSubscription;
  StreamSubscription? _sigintSubscription;
  StreamSubscription? _sigtermSubscription;
  bool _disposed = false;

  StdioBackend() {
    _initializeSignalHandling();
  }

  void _initializeSignalHandling() {
    // Only set up signal handling on Unix systems
    if (Platform.isLinux || Platform.isMacOS) {
      // Resize signal
      _resizeController = StreamController<Size>.broadcast();
      _sigwinchSubscription = ProcessSignal.sigwinch.watch().listen((_) {
        if (!_disposed && stdout.hasTerminal) {
          final size = Size(
            stdout.terminalColumns.toDouble(),
            stdout.terminalLines.toDouble(),
          );
          _resizeController?.add(size);
        }
      });

      // Shutdown signals
      _shutdownController = StreamController<void>.broadcast();
      _sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
        if (!_disposed) {
          _shutdownController?.add(null);
        }
      });
      _sigtermSubscription = ProcessSignal.sigterm.watch().listen((_) {
        if (!_disposed) {
          _shutdownController?.add(null);
        }
      });
    }
  }

  @override
  void writeRaw(String data) {
    stdout.write(data);
  }

  @override
  Size getSize() {
    if (stdout.hasTerminal) {
      return Size(
        stdout.terminalColumns.toDouble(),
        stdout.terminalLines.toDouble(),
      );
    }
    return const Size(80, 24);
  }

  @override
  bool get supportsSize => stdout.hasTerminal;

  @override
  Stream<List<int>>? get inputStream => stdin;

  @override
  Stream<Size>? get resizeStream => _resizeController?.stream;

  @override
  Stream<void>? get shutdownStream => _shutdownController?.stream;

  @override
  void enableRawMode() {
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = false;
        stdin.lineMode = false;
      }
    } catch (e) {
      // Ignore errors in CI/CD or when piping
    }
  }

  @override
  void disableRawMode() {
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = true;
        stdin.lineMode = true;
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  bool get isAvailable => !_disposed;

  @override
  void notifySizeChanged(Size newSize) {
    // StdioBackend doesn't track size via protocol, so this is a no-op.
    // Size changes are detected via SIGWINCH signal which emits on resizeStream.
  }

  @override
  void requestExit([int exitCode = 0]) {
    exit(exitCode);
  }

  @override
  void dispose() {
    _disposed = true;
    _sigwinchSubscription?.cancel();
    _sigintSubscription?.cancel();
    _sigtermSubscription?.cancel();
    _resizeController?.close();
    _shutdownController?.close();
  }
}
