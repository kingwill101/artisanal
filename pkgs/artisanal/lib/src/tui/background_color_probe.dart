import 'dart:async';

import 'package:artisanal/terminal.dart' show Ansi;

import 'msg.dart';
import '../uv/event.dart' as uvev;
import 'startup_probe.dart';

/// Best-effort probe for terminal theme state before the first frame.
///
/// This avoids an initial adaptive-theme flash where widgets default to a dark
/// palette until an OSC 11 or color-scheme response arrives later.
final class BackgroundColorProbe implements StartupProbe {
  /// Creates a background-color probe.
  BackgroundColorProbe({
    this.timeout = const Duration(milliseconds: 120),
  });

  /// Maximum time to wait for a terminal response.
  final Duration timeout;

  Completer<void> _done = Completer<void>();
  bool _active = false;

  @override
  bool get isActive => _active;

  @override
  bool get gateNonCriticalMessages => false;

  @override
  Future<void> start(StartupProbeContext ctx) async {
    if (_active) return;
    _active = true;
    _done = Completer<void>();

    final term = ctx.terminal;
    term.write(Ansi.requestBackgroundColor);
    term.write(Ansi.requestColorScheme);
    await term.flush();

    try {
      await _done.future.timeout(timeout);
    } on TimeoutException {
      // Best-effort only: keep startup moving when the terminal does not
      // answer OSC 11.
    } finally {
      _active = false;
    }
  }

  @override
  bool handleMsg(Msg msg, StartupProbeContext ctx) {
    if (!_active || _done.isCompleted) return false;

    if (msg is BackgroundColorMsg || msg is ColorSchemeMsg) {
      _done.complete();
      return false;
    }

    if (msg case UvEventMsg(event: final ev)) {
      if (ev is uvev.DarkColorSchemeEvent || ev is uvev.LightColorSchemeEvent) {
        _done.complete();
        return false;
      }
    }

    return false;
  }
}
