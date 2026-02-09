import 'dart:async';

import 'package:nocterm/src/size.dart';

/// Abstract interface for terminal I/O backends.
///
/// Backends handle platform-specific I/O operations:
/// - StdioBackend: Native terminal via stdin/stdout
/// - SocketBackend: Shell mode via Unix socket
/// - WebBackend: Browser via static bridge for WASM/JS apps
abstract class TerminalBackend {
  /// Write a string directly to the output (immediate, unbuffered).
  void writeRaw(String data);

  /// Get the current terminal size.
  Size getSize();

  /// Whether this backend supports querying terminal size.
  bool get supportsSize;

  /// Get the input stream for reading terminal input.
  /// Returns null if this backend doesn't provide input.
  Stream<List<int>>? get inputStream;

  /// Stream of terminal resize events.
  /// Returns null if this backend doesn't support resize detection.
  Stream<Size>? get resizeStream;

  /// Stream that emits when the app should shut down gracefully.
  /// (e.g., SIGINT/SIGTERM on native, browser tab close on web)
  /// Returns null if not supported.
  Stream<void>? get shutdownStream;

  /// Enable raw input mode (disable echo, line buffering).
  void enableRawMode();

  /// Disable raw input mode (restore echo, line buffering).
  void disableRawMode();

  /// Whether this backend is currently available/connected.
  bool get isAvailable;

  /// Request process/app exit with the given exit code.
  /// On native: calls dart:io exit()
  /// On web: typically a no-op (can't exit browser tab)
  void requestExit([int exitCode = 0]);

  /// Update the size externally (for backends that receive size via protocol).
  /// Default implementation does nothing.
  void notifySizeChanged(Size newSize) {}

  /// Dispose of any resources held by this backend.
  void dispose();
}
