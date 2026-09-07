library;

import 'dart:io' as io;

/// Software flow-control (XON/XOFF) management for stdio raw mode.
///
/// Dart's `Stdin.echoMode`/`lineMode` leave the kernel `IXON` flag on, so
/// `Ctrl+S` freezes terminal output (XOFF) and `Ctrl+Q` resumes it before a
/// TUI ever sees the bytes. Full-screen runtimes conventionally disable
/// `IXON` while they own the terminal (ncurses does the same in raw mode).
///
/// dart:io only — import from io implementations only, never from web/stub
/// variants. Every entry point is best-effort and never throws: when there
/// is no TTY, no `stty`, or an unexpected platform, the helpers return
/// without touching anything.

/// Disables `IXON` on [ttyPath] and returns the previous `stty -g` mode.
///
/// Returns `null` when nothing was changed (no TTY, Windows, or `stty`
/// unavailable) and restore must be a no-op. Returns `''` when `IXON` was
/// disabled but the previous mode could not be read, in which case restore
/// re-enables `IXON` explicitly.
String? disableTerminalFlowControl({String ttyPath = '/dev/tty'}) {
  if (io.Platform.isWindows) return null;
  try {
    if (!io.stdin.hasTerminal) return null;
    final saved = _runStty(ttyPath, const ['-g']);
    final mode = saved?.stdout?.toString().trim() ?? '';
    final disabled = _runStty(ttyPath, const ['-ixon']);
    if (disabled == null || disabled.exitCode != 0) return null;
    return mode;
  } catch (_) {
    return null;
  }
}

/// Restores flow control saved by [disableTerminalFlowControl].
///
/// A `null` [saved] is a no-op (nothing was changed). An empty [saved]
/// re-enables `IXON`; otherwise the exact saved mode is restored.
void restoreTerminalFlowControl(String? saved, {String ttyPath = '/dev/tty'}) {
  if (saved == null || io.Platform.isWindows) return;
  try {
    if (saved.isEmpty) {
      _runStty(ttyPath, const ['ixon']);
    } else {
      _runStty(ttyPath, [saved]);
    }
  } catch (_) {}
}

io.ProcessResult? _runStty(String ttyPath, List<String> args) {
  try {
    // Linux `stty` addresses the device with `-F`; macOS/BSD uses `-f`.
    for (final flag in const ['-F', '-f']) {
      final result = io.Process.runSync('stty', [flag, ttyPath, ...args]);
      if (result.exitCode == 0) return result;
    }
  } catch (_) {}
  return null;
}
