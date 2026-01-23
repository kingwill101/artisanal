/// Sequence example: run commands in order and batch.
library;

import 'dart:async';

import 'package:artisanal/tui.dart' as tui;

class SequenceModel implements tui.Model {
  @override
  tui.Cmd? init() {
    return tui.Cmd.sequence([
      tui.Cmd.batch([
        tui.Cmd.sequence([
          sleepPrintln('1-1-1', 1000),
          sleepPrintln('1-1-2', 1000),
        ]),
        tui.Cmd.batch([
          sleepPrintln('1-2-1', 1500),
          sleepPrintln('1-2-2', 1250),
        ]),
      ]),
      tui.Cmd.println('2'),
      tui.Cmd.sequence([
        tui.Cmd.batch([
          sleepPrintln('3-1-1', 500),
          sleepPrintln('3-1-2', 1000),
        ]),
        tui.Cmd.sequence([
          sleepPrintln('3-2-1', 750),
          sleepPrintln('3-2-2', 500),
        ]),
      ]),
      tui.Cmd.message(const _DoneMsg()),
    ]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      return (this, tui.Cmd.quit());
    }
    if (msg is _DoneMsg) {
      return (this, tui.Cmd.quit());
    }
    return (this, null);
  }

  @override
  String view() => '';
}

class _DoneMsg extends tui.Msg {
  const _DoneMsg();
}

tui.Cmd sleepPrintln(String text, int millis) {
  return tui.Cmd(() async {
    await Future<void>.delayed(Duration(milliseconds: millis));
    return await tui.Cmd.println(text).execute();
  });
}

Future<void> main() async {
  await tui.runProgram(
    SequenceModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
