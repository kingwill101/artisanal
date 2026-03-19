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
  /// Creates an emoji width probe.
  EmojiWidthProbe({
    this.timeout = const Duration(milliseconds: 180),
    this.probeEmoji = '🍕',
  });

  /// Maximum time to wait for terminal response.
  final Duration timeout;

  /// The emoji character used for width probing.
  final String probeEmoji;

  final Completer<void> _done = Completer<void>();
  int? _startX;
  int? _startY;
  int _stage = 0;
  bool _active = false;

  /// Whether the probe is currently running.
  @override
  bool get isActive => _active;

  /// Whether non-critical messages should be gated during probing.
  @override
  bool get gateNonCriticalMessages => true;

  /// Starts the width probe by querying the terminal.
  @override
  Future<void> start(StartupProbeContext ctx) async {
    if (_active) return;
    _active = true;

    final term = ctx.terminal;

    // Save cursor position and move to the last row so probing happens in an
    // area the user won't notice (the content is already rendered above).
    // We do NOT enter alt screen — the renderer has already done that.
    term.saveCursor();

    // Move to the bottom-left of the screen and clear that line so the probe
    // emoji doesn't visually collide with rendered content.
    final (width: _, height: h) = term.size;
    term.write('\x1b[$h;1H'); // Move to last row, col 1
    term.write(Ansi.clearLine);

    // Request cursor position to establish the baseline column.
    term.write(Ansi.requestExtendedCursorPosition);
    await term.flush();

    try {
      await _done.future.timeout(timeout);
    } on TimeoutException {
      // Best-effort: leave defaults.
    } finally {
      _active = false;
      // Erase probe artifacts on the last row and restore cursor.
      term.write('\x1b[$h;1H');
      term.write(Ansi.clearLine);
      term.restoreCursor();
      await term.flush();
    }
  }

  /// Handles terminal response messages during probing.
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

  @override
  void abort() {
    if (!_active || _done.isCompleted) return;
    _done.complete();
  }
}
