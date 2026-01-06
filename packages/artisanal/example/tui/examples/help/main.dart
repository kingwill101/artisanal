/// Help view example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

class HelpKeys implements tui.KeyMap {
  HelpKeys()
    : up = tui.KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up'),
      down = tui.KeyBinding.withHelp(['down', 'j'], '↓/j', 'move down'),
      left = tui.KeyBinding.withHelp(['left', 'h'], '←/h', 'move left'),
      right = tui.KeyBinding.withHelp(['right', 'l'], '→/l', 'move right'),
      help = tui.KeyBinding.withHelp(['?'], '?', 'toggle help'),
      quit = tui.KeyBinding.withHelp(['q', 'esc', 'ctrl+c'], 'q', 'quit');

  final tui.KeyBinding up;
  final tui.KeyBinding down;
  final tui.KeyBinding left;
  final tui.KeyBinding right;
  final tui.KeyBinding help;
  final tui.KeyBinding quit;

  @override
  List<tui.KeyBinding> shortHelp() => [help, quit];

  @override
  List<List<tui.KeyBinding>> fullHelp() => [
    [up, down, left, right],
    [help, quit],
  ];
}

class HelpModel implements tui.Model {
  HelpModel({
    HelpKeys? keys,
    tui.HelpModel? help,
    this.lastKey = '',
    this.quitting = false,
  }) : keys = keys ?? HelpKeys(),
       help = help ?? tui.HelpModel(),
       inputStyle = Style().foreground(const AnsiColor(204));

  final HelpKeys keys;
  final tui.HelpModel help;
  final String lastKey;
  final bool quitting;
  final Style inputStyle;

  HelpModel copyWith({
    HelpKeys? keys,
    tui.HelpModel? help,
    String? lastKey,
    bool? quitting,
  }) {
    return HelpModel(
      keys: keys ?? this.keys,
      help: help ?? this.help,
      lastKey: lastKey ?? this.lastKey,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.WindowSizeMsg(:final width):
        return (copyWith(help: help.copyWith(width: width)), null);

      case tui.KeyMsg(key: final key):
        if (key.matchesSingle(keys.quit)) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }
        if (key.matchesSingle(keys.help)) {
          return (copyWith(help: help.copyWith(showAll: !help.showAll)), null);
        }

        final last = switch (key) {
          _ when key.matchesSingle(keys.up) => '↑',
          _ when key.matchesSingle(keys.down) => '↓',
          _ when key.matchesSingle(keys.left) => '←',
          _ when key.matchesSingle(keys.right) => '→',
          _ => lastKey,
        };
        return (copyWith(lastKey: last), null);

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    if (quitting) return 'Bye!\n';

    final status = lastKey.isEmpty
        ? 'Waiting for input...'
        : 'You chose: ${inputStyle.render(lastKey)}';

    final helpView = help.view(keys);
    final padLines =
        8 - '\n'.allMatches(status).length - '\n'.allMatches(helpView).length;
    final blankLines = '\n' * (padLines > 0 ? padLines : 0);

    return '\n$status$blankLines$helpView';
  }
}

Future<void> main() async {
  await tui.runProgram(
    HelpModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
