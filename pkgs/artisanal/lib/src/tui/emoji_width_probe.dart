import 'dart:async';

import 'package:artisanal/terminal.dart' show Ansi;

import '../unicode/width.dart' as uni_width;
import 'msg.dart';
import 'startup_probe.dart';
import '../uv/event.dart' as uvev;

/// Best-effort probe to align emoji cell width with the active terminal.
///
/// Some terminals render emoji as 1 cell wide, others as 2. The UV renderer
/// needs to match the terminal's behavior to avoid overwriting graphemes.
final class EmojiWidthProbe implements StartupProbe {
  EmojiWidthProbe({
    this.timeout = const Duration(milliseconds: 180),
    this.probeEmoji = '🍕',
  });

  final Duration timeout;
  final String probeEmoji;

  final Completer<void> _done = Completer<void>();
  int? _startX;
  int? _startY;
  int _stage = 0;
  bool _active = false;

  @override
  bool get isActive => _active;

  @override
  bool get gateNonCriticalMessages => true;

  @override
  Future<void> start(StartupProbeContext ctx) async {
    if (_active) return;
    _active = true;

    final term = ctx.terminal;

    // Enter alt screen early so probing doesn't flash content on the normal
    // screen before the renderer initializes.
    term.enterAltScreen();
    term.hideCursor();
    term.clearScreen();

    // Home cursor and request extended cursor position report (DECXCPR).
    term.write(Ansi.cursorHome);
    term.write(Ansi.requestExtendedCursorPosition);
    await term.flush();

    try {
      await _done.future.timeout(timeout);
    } on TimeoutException {
      // Best-effort: leave defaults.
    } finally {
      _active = false;
      // Clear any probe artifacts before rendering.
      term.clearScreen();
      await term.flush();
    }
  }

  @override
  bool handleMsg(Msg msg, StartupProbeContext ctx) {
    if (!_active) return false;
    if (_done.isCompleted) return false;

    if (msg is! UvEventMsg) return false;
    final ev = msg.event;
    if (ev is! uvev.CursorPositionEvent) return false;

    final term = ctx.terminal;

    if (_stage == 0) {
      _startX = ev.x;
      _startY = ev.y;
      _stage = 1;

      term.write(probeEmoji);
      term.write(Ansi.requestExtendedCursorPosition);
      unawaited(term.flush());
      return true;
    }

    if (_stage == 1) {
      final sx = _startX;
      final sy = _startY;
      if (sx != null && sy != null && ev.y == sy) {
        final delta = ev.x - sx;
        if (delta == 1 || delta == 2) {
          uni_width.setEmojiPresentationWidth(delta);
        }
      }
      _done.complete();
      return true;
    }

    return false;
  }
}
