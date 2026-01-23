/// Window size example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;

class WindowSizeModel implements tui.Model {
  const WindowSizeModel();

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(
            key: tui.Key(type: tui.KeyType.runes, runes: [0x71]),
          ) || // q
          tui.KeyMsg(key: tui.Key(ctrl: true, runes: [0x63])) || // Ctrl+C
          tui.KeyMsg(key: tui.Key(type: tui.KeyType.escape)):
        return (this, tui.Cmd.quit());

      case tui.KeyMsg():
        return (this, tui.Cmd.windowSize());

      case tui.WindowSizeMsg(:final width, :final height):
        return (this, tui.Cmd.printf('%dx%d', [width, height]));

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    return "Press any key to query window size. Press q/esc/Ctrl+C to quit.\n";
  }
}

Future<void> main() async {
  await tui.runProgram(
    const WindowSizeModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
