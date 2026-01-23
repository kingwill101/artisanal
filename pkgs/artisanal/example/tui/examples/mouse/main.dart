/// Mouse events example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart';

class MouseModel implements Model {
  const MouseModel({this.lastEvent});

  final String? lastEvent;

  MouseModel copyWith({String? lastEvent}) {
    return MouseModel(lastEvent: lastEvent ?? this.lastEvent);
  }

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) || // q
          KeyMsg(key: Key(ctrl: true, runes: [0x63])) || // Ctrl+C
          KeyMsg(key: Key(type: KeyType.escape)):
        return (this, Cmd.quit());

      case MouseMsg(:final x, :final y):
        final desc = '(X: $x, Y: $y) $msg';
        return (copyWith(lastEvent: desc), Cmd.printf('%s', [desc]));

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    final eventLine = lastEvent != null ? 'Last: $lastEvent\n' : '';
    return "Do mouse stuff. When you're done press q to quit.\n$eventLine";
  }
}

Future<void> main() async {
  await runProgram(
    const MouseModel(),
    options: const ProgramOptions(
      mouse: true,
      altScreen: false, // keep prints visible
      hideCursor: false,
    ),
  );
}
