/// Set window title example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;

class SetTitleModel implements tui.Model {
  const SetTitleModel();

  @override
  tui.Cmd? init() => tui.Cmd.setWindowTitle('artisanal Table Example');

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      return (this, tui.Cmd.quit());
    }
    return (this, null);
  }

  @override
  String view() => '\nPress any key to quit.';
}

Future<void> main() async {
  await tui.runProgram(
    const SetTitleModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
