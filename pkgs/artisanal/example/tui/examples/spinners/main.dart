/// Multiple spinners example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

final _spinnerDefs = <tui.Spinner>[
  tui.Spinners.line,
  tui.Spinners.dot,
  tui.Spinners.miniDot,
  tui.Spinners.jump,
  tui.Spinners.pulse,
  tui.Spinners.points,
  tui.Spinners.globe,
  tui.Spinners.moon,
  tui.Spinners.monkey,
];

class SpinnersModel implements tui.Model {
  SpinnersModel({required this.index, required this.spinner});

  factory SpinnersModel.initial() {
    final model = SpinnersModel(
      index: 0,
      spinner: tui.SpinnerModel(spinner: _spinnerDefs[0]),
    );
    return model;
  }

  final int index;
  final tui.SpinnerModel spinner;

  @override
  tui.Cmd? init() => spinner.tick();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        if (key.matchesSingle(tui.CommonKeyBindings.quit) ||
            key.type == tui.KeyType.escape) {
          return (this, tui.Cmd.quit());
        }
        if (key.type == tui.KeyType.left || key.runes.firstOrNull == 0x68) {
          return _setIndex(index - 1);
        }
        if (key.type == tui.KeyType.right || key.runes.firstOrNull == 0x6c) {
          return _setIndex(index + 1);
        }
      case tui.SpinnerTickMsg():
        final (newSpinner, cmd) = spinner.update(msg);
        return (copyWith(spinner: newSpinner), cmd);
    }
    return (this, null);
  }

  (tui.Model, tui.Cmd?) _setIndex(int newIndex) {
    final count = _spinnerDefs.length;
    var idx = newIndex;
    if (idx < 0) idx = count - 1;
    if (idx >= count) idx = 0;
    final newSpinner = tui.SpinnerModel(spinner: _spinnerDefs[idx]);
    return (SpinnersModel(index: idx, spinner: newSpinner), newSpinner.tick());
  }

  SpinnersModel copyWith({int? index, tui.SpinnerModel? spinner}) {
    return SpinnersModel(
      index: index ?? this.index,
      spinner: spinner ?? this.spinner,
    );
  }

  @override
  String view() {
    final textStyle = Style().foreground(const AnsiColor(252));
    final spinnerStyle = Style().foreground(const AnsiColor(69));
    final helpStyle = Style().foreground(const AnsiColor(241));

    final gap = index == 1 ? '' : ' ';
    final s = spinnerStyle.render(spinner.view());
    return '\n $s$gap${textStyle.render('Spinning...')}\n\n'
        '${helpStyle.render('h/l, ←/→: change spinner • q: exit')}\n';
  }
}

Future<void> main() async {
  await tui.runProgram(
    SpinnersModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
