/// Debug tracing utilities for TUI rendering and message dispatch.
library;

import 'dart:io' as io;

/// Lightweight debug tracer for TUI frame rendering and message dispatch.
final class TuiTrace {
  static const _flagEnv = 'ARTISANAL_TUI_TRACE';
  static const _pathEnv = 'ARTISANAL_TUI_TRACE_PATH';
  static const _captureEnv = 'ARTISANAL_TUI_TRACE_CAPTURE';
  static const _defaultPath = '/tmp/artisanal_tui_trace.log';

  static String? _path;
  static io.IOSink? _sink;
  static bool? _captureEnabled;

  /// Whether trace logging is enabled (set via `ARTISANAL_TUI_TRACE` env var).
  static bool get enabled {
    _path ??= _resolvePath();
    return _path != null;
  }

  /// Whether dispatch capture logging is enabled.
  static bool get captureDispatchEnabled {
    if (!enabled) return false;
    _captureEnabled ??= _resolveFlag(_captureEnv);
    return _captureEnabled ?? false;
  }

  /// Writes a timestamped trace message to the log file.
  static void log(String message) {
    if (!enabled) return;
    _sink ??= io.File(_path!).openWrite(mode: io.FileMode.append);
    final ts = DateTime.now().toIso8601String();
    _sink!.writeln('[$ts] $message');
  }

  /// Closes the trace log file.
  static void close() {
    if (_sink == null) return;
    _sink!.flush();
    _sink!.close();
    _sink = null;
  }

  static String? _resolvePath() {
    final env = io.Platform.environment;
    final path = env[_pathEnv];
    if (path != null && path.isNotEmpty) return path;
    final flag = env[_flagEnv];
    if (flag == null) return null;
    if (_isEnabledFlag(flag)) {
      return _defaultPath;
    }
    return null;
  }

  static bool _resolveFlag(String envKey) {
    final flag = io.Platform.environment[envKey];
    if (flag == null) return false;
    return _isEnabledFlag(flag);
  }

  static bool _isEnabledFlag(String flag) {
    final lower = flag.toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes';
  }
}
