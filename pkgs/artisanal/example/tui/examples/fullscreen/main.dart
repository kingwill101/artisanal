/// Fullscreen countdown example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;

class TickMsg extends tui.Msg {
  const TickMsg();
}

class FullscreenModel implements tui.Model {
  const FullscreenModel(this.counter);

  final int counter;

  @override
  tui.Cmd? init() => _tick();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (rune == 0x71 ||
            key.type == tui.KeyType.escape ||
            (key.ctrl && rune == 0x63)) {
          return (this, tui.Cmd.quit());
        }
      case TickMsg():
        final next = counter - 1;
        if (next <= 0) {
          return (this, tui.Cmd.quit());
        }
        return (FullscreenModel(next), _tick());
    }
    return (this, null);
  }

  tui.Cmd _tick() =>
      tui.Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg());

  @override
  String view() => '\n\n     Hi. This program will exit in $counter seconds...';
}

Future<void> main() async {
  await tui.runProgram(
    const FullscreenModel(5),
    options: const tui.ProgramOptions(altScreen: true, hideCursor: true),
  );
}
