/// Debounce example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;

const _debounceDuration = Duration(seconds: 1);

class ExitMsg extends tui.Msg {
  const ExitMsg(this.tag);
  final int tag;
}

class DebounceModel implements tui.Model {
  const DebounceModel({this.tag = 0});

  final int tag;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        final nextTag = tag + 1;
        return (
          copyWith(tag: nextTag),
          tui.Cmd.tick(_debounceDuration, (_) => ExitMsg(nextTag)),
        );

      case ExitMsg(:final tag):
        if (tag == this.tag) {
          return (this, tui.Cmd.quit());
        }
    }
    return (this, null);
  }

  DebounceModel copyWith({int? tag}) => DebounceModel(tag: tag ?? this.tag);

  @override
  String view() =>
      'Key presses: $tag\n'
      'To exit press any key, then wait for one second without pressing anything.';
}

Future<void> main() async {
  await tui.runProgram(
    const DebounceModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
