/// Alt screen toggle example.
library;

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/tui.dart' as tui;

class AltScreenModel implements tui.Model {
  AltScreenModel({
    this.altscreen = false,
    this.quitting = false,
    this.suspending = false,
  });

  final bool altscreen;
  final bool quitting;
  final bool suspending;

  AltScreenModel copyWith({bool? altscreen, bool? quitting, bool? suspending}) {
    return AltScreenModel(
      altscreen: altscreen ?? this.altscreen,
      quitting: quitting ?? this.quitting,
      suspending: suspending ?? this.suspending,
    );
  }

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.ResumeMsg():
        return (copyWith(suspending: false), null);
      case tui.KeyMsg(key: final key):
        final isRune = key.type == tui.KeyType.runes && key.runes.isNotEmpty;
        final rune = isRune ? key.runes.first : -1;

        // Quit
        if (key.type == tui.KeyType.escape ||
            (isRune && rune == 0x71) || // q
            (key.ctrl && rune == 0x63)) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }

        // Suspend (ctrl+z)
        if (key.ctrl && rune == 0x7a) {
          return (copyWith(suspending: true), tui.Cmd.suspend());
        }

        // Toggle alt screen on space
        if (key.type == tui.KeyType.space) {
          final entering = !altscreen;
          final cmd = entering
              ? tui.Cmd.enterAltScreen()
              : tui.Cmd.exitAltScreen();
          return (copyWith(altscreen: entering), cmd);
        }
    }
    return (this, null);
  }

  @override
  String view() {
    if (suspending) return '';
    if (quitting) return 'Bye!\n';

    const altscreenMode = ' altscreen mode ';
    const inlineMode = ' inline mode ';
    final mode = altscreen ? altscreenMode : inlineMode;

    final keywordStyle = Style()
        .foreground(const AnsiColor(204))
        .background(const AnsiColor(235));
    final helpStyle = Style().foreground(const AnsiColor(241));

    return '\n\n  You\'re in ${keywordStyle.render(mode)}\n\n\n${helpStyle.render(
          '  space: switch modes • ctrl-z: suspend • q/esc: exit\n',
        )}';
  }
}

Future<void> main() async {
  await tui.runProgram(
    AltScreenModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
