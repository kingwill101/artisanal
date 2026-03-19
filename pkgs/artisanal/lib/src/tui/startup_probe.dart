import 'dart:async';

import 'cmd.dart';
import 'key.dart';
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

  /// Aborts the probe early.
  ///
  /// This is used for critical lifecycle messages such as quit/interrupt so
  /// startup probing does not sit out its timeout once shutdown is already in
  /// flight.
  void abort();
}

/// Runs startup probes and optionally buffers messages while they are active.
final class StartupProbeRunner {
  StartupProbeRunner(this._probes);

  final List<StartupProbe> _probes;
  final List<Msg> _buffered = <Msg>[];
  bool _draining = false;
  bool _aborted = false;

  StartupProbe? get _active => _probes.where((p) => p.isActive).firstOrNull;

  /// Whether any startup probe is currently active.
  bool get hasActiveProbe => _active != null;

  bool get hasBufferedMessages => _buffered.isNotEmpty;

  bool get wasAborted => _aborted;

  /// Runs probes sequentially.
  Future<void> runAll(StartupProbeContext ctx) async {
    _aborted = false;
    for (final probe in _probes) {
      if (_aborted) break;
      await probe.start(ctx);
      if (_aborted) break;
    }
  }

  /// Intercepts messages while any probe is active.
  ///
  /// Returns true if the runner consumed/buffered the message.
  bool intercept(Msg msg, StartupProbeContext ctx) {
    final probe = _active;
    if (probe == null) return false;

    if (probe.handleMsg(msg, ctx)) return true;

    if (isCriticalStartupProbeMsg(msg)) {
      _aborted = true;
      probe.abort();
      return false;
    }

    if (probe.gateNonCriticalMessages) {
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

  /// Aborts the currently active probe, if any.
  void abort() {
    _aborted = true;
    _active?.abort();
  }

}

bool isCriticalStartupProbeMsg(Msg msg) =>
    msg is QuitMsg ||
    msg is SuspendMsg ||
    msg is ExecProcessMsg ||
    msg is InterruptMsg ||
    (msg is KeyMsg &&
        (msg.key.isCtrlC ||
            (msg.key.type == KeyType.runes &&
                msg.key.runes.length == 1 &&
                msg.key.runes.first == 0x03)));

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final v in this) {
      return v;
    }
    return null;
  }
}
