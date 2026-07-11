/// Bubble Tea "simple" example ported to artisanal.
///
/// Counts down from 5 and exits. Press `q`, `esc`, or `Ctrl+C` to quit early
/// and `Ctrl+Z` to suspend (if your shell supports it).
library;

import 'package:artisanal/tui.dart';

// #region custom_msg
/// Message fired every second.
class TickMsg extends Msg {
  const TickMsg();
}
// #endregion

// #region cmd_tick
class SimpleModel implements Model {
  const SimpleModel(this.seconds, {this.quitting = false});

  final int seconds;
  final bool quitting;

  @override
  Cmd? init() => Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg());
  // #endregion

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(key: Key(ctrl: true, runes: [0x63])): // Ctrl+C
      case KeyMsg(key: Key(type: KeyType.escape)):
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])): // q
        return (SimpleModel(seconds, quitting: true), Cmd.quit());

      case KeyMsg(key: Key(ctrl: true, runes: [0x7a])): // Ctrl+Z
        return (this, Cmd.suspend());

      case TickMsg():
        if (seconds <= 1) {
          return (SimpleModel(0, quitting: true), Cmd.quit());
        }
        return (
          SimpleModel(seconds - 1),
          Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg()),
        );

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    final quitHint = quitting ? '\n' : '';
    return 'Hi. This program will exit in $seconds seconds.\n\n'
        'To quit sooner press Ctrl+C, q, or Esc.\n'
        'Press Ctrl+Z to suspend...\n'
        '$quitHint';
  }
}

Future<void> main() async {
  await runProgram(
    const SimpleModel(5),
    options: const ProgramOptions(altScreen: false, hideCursor: false),
  );
}
