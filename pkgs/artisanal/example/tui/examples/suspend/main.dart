/// Suspend / resume example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;

class SuspendModel implements tui.Model {
  const SuspendModel({this.quitting = false, this.suspending = false});

  final bool quitting;
  final bool suspending;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.ResumeMsg():
        return (copyWith(suspending: false), null);
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        final isEsc = key.type == tui.KeyType.escape;
        if (isEsc || rune == 0x71) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }
        if (key.ctrl && rune == 0x63) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }
        if (key.ctrl && rune == 0x1a) {
          // Ctrl+Z
          return (copyWith(suspending: true), tui.Cmd.suspend());
        }
    }
    return (this, null);
  }

  SuspendModel copyWith({bool? quitting, bool? suspending}) {
    return SuspendModel(
      quitting: quitting ?? this.quitting,
      suspending: suspending ?? this.suspending,
    );
  }

  @override
  String view() {
    if (suspending || quitting) return '';
    return '\nPress ctrl-z to suspend, ctrl+c to interrupt, q, or esc to exit\n';
  }
}

Future<void> main() async {
  await tui.runProgram(
    const SuspendModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
