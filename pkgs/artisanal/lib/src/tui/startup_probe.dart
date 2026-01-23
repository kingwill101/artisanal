import 'dart:async';

import 'msg.dart';
import 'terminal.dart';

/// Context passed to startup probes.
final class StartupProbeContext {
  StartupProbeContext({required this.terminal});

  final TuiTerminal terminal;
}

/// A small, optional initialization probe that can run before the first render.
///
/// Probes may:
/// - write/read terminal reports (via raw escape sequences + UV input decoding)
/// - temporarily gate/buffer non-critical messages (e.g. mouse motion)
///
/// Probes should be best-effort and time out quickly.
abstract interface class StartupProbe {
  /// Starts the probe.
  ///
  /// Implementations can write escape sequences here, then complete later via
  /// [handleMsg] events (UV events, etc).
  Future<void> start(StartupProbeContext ctx);

  /// Whether the probe is currently active and should receive messages.
  bool get isActive;

  /// When true, the runner buffers non-critical messages while [isActive].
  bool get gateNonCriticalMessages;

  /// Lets the probe observe/intercept messages while active.
  ///
  /// Return true to consume the message.
  bool handleMsg(Msg msg, StartupProbeContext ctx);
}

/// Runs startup probes and optionally buffers messages while they are active.
final class StartupProbeRunner {
  StartupProbeRunner(this._probes);

  final List<StartupProbe> _probes;
  final List<Msg> _buffered = <Msg>[];
  bool _draining = false;

  StartupProbe? get _active => _probes.where((p) => p.isActive).firstOrNull;

  bool get hasBufferedMessages => _buffered.isNotEmpty;

  /// Runs probes sequentially.
  Future<void> runAll(StartupProbeContext ctx) async {
    for (final probe in _probes) {
      await probe.start(ctx);
    }
  }

  /// Intercepts messages while any probe is active.
  ///
  /// Returns true if the runner consumed/buffered the message.
  bool intercept(Msg msg, StartupProbeContext ctx) {
    final probe = _active;
    if (probe == null) return false;

    if (probe.handleMsg(msg, ctx)) return true;

    if (probe.gateNonCriticalMessages && !_isCritical(msg)) {
      _buffered.add(msg);
      return true;
    }

    return false;
  }

  /// Drains buffered messages to [process].
  void drain(void Function(Msg msg) process) {
    if (_draining) return;
    if (_buffered.isEmpty) return;
    _draining = true;
    try {
      final pending = List<Msg>.from(_buffered);
      _buffered.clear();
      for (final m in pending) {
        process(m);
      }
    } finally {
      _draining = false;
    }
  }

  static bool _isCritical(Msg msg) => msg is QuitMsg || msg is InterruptMsg;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final v in this) {
      return v;
    }
    return null;
  }
}
