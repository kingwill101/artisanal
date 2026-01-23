import 'package:artisanal/src/tui/program.dart';
import 'package:artisanal/src/tui/model.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/key.dart';

class DemoModel implements Model {
  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg &&
        msg.key.type == KeyType.runes &&
        msg.key.runes.isNotEmpty) {
      if (String.fromCharCode(msg.key.runes.first) == 'q') {
        return (this, Cmd.quit());
      }
    }
    return (this, null);
  }

  @override
  String view() => 'Ultraviolet TuiRenderer Demo\n\nPress q to quit.';
}

void main() async {
  final p = Program(
    DemoModel(),
    options: const ProgramOptions(
      useUltravioletRenderer: true,
      altScreen: true,
    ),
  );

  await p.run();
}
