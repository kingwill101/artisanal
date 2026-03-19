import 'dart:async';

import 'package:artisanal/terminal.dart' show Ansi;

import 'msg.dart';
import 'startup_probe.dart';

/// Best-effort probe for UV startup capability reports before first render.
///
/// This requests a small set of non-visual terminal reports that are useful
/// during startup and cheap to query up front:
/// - secondary device attributes (DA2)
/// - kitty keyboard enhancement support
final class UvCapabilityProbe implements StartupProbe {
  /// Creates a UV startup capability probe.
  UvCapabilityProbe({
    this.timeout = const Duration(milliseconds: 120),
  });

  /// Maximum time to wait for terminal responses.
  final Duration timeout;

  Completer<void> _done = Completer<void>();
  bool _active = false;
  bool _sawSecondaryAttributes = false;
  bool _sawKeyboardEnhancements = false;

  @override
  bool get isActive => _active;

  @override
  bool get gateNonCriticalMessages => false;

  @override
  Future<void> start(StartupProbeContext ctx) async {
    if (_active) return;
    _active = true;
    _done = Completer<void>();
    _sawSecondaryAttributes = false;
    _sawKeyboardEnhancements = false;

    final term = ctx.terminal;
    term.write(Ansi.requestSecondaryDeviceAttributes);
    term.write(Ansi.requestKittyKeyboard);
    await term.flush();

    try {
      await _done.future.timeout(timeout);
    } on TimeoutException {
      // Best-effort only: keep startup moving when the terminal does not
      // answer some or all capability queries.
    } finally {
      _active = false;
    }
  }

  @override
  bool handleMsg(Msg msg, StartupProbeContext ctx) {
    if (!_active || _done.isCompleted) return false;

    if (msg is SecondaryDeviceAttributesMsg) {
      _sawSecondaryAttributes = true;
    } else if (msg is KeyboardEnhancementsMsg) {
      _sawKeyboardEnhancements = true;
    }

    if (_sawSecondaryAttributes && _sawKeyboardEnhancements) {
      _done.complete();
    }

    return false;
  }

  @override
  void abort() {
    if (!_active || _done.isCompleted) return;
    _done.complete();
  }
}
