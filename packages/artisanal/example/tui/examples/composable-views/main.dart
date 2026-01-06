/// Composable views example ported from Bubble Tea.
library;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

enum SessionState { timer, spinner }

const _defaultTime = Duration(minutes: 1);

final _spinners = <tui.Spinner>[
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

final _modelStyle = Style()
    .width(15)
    .height(5)
    .align(HorizontalAlign.center, VerticalAlign.center)
    .border(Border.hidden);

final _focusedModelStyle = Style()
    .width(15)
    .height(5)
    .align(HorizontalAlign.center, VerticalAlign.center)
    .border(Border.normal)
    .borderForeground(const AnsiColor(69));

final _spinnerStyle = Style().foreground(const AnsiColor(69));
final _helpStyle = Style().foreground(const AnsiColor(241));

class ComposableViewsModel implements tui.Model {
  ComposableViewsModel({
    required this.state,
    required this.timer,
    required this.spinner,
    required this.index,
  });

  factory ComposableViewsModel.initial() {
    return ComposableViewsModel(
      state: SessionState.timer,
      timer: tui.TimerModel(
        timeout: _defaultTime,
        interval: const Duration(seconds: 1),
      ),
      spinner: tui.SpinnerModel(),
      index: 0,
    );
  }

  final SessionState state;
  final tui.TimerModel timer;
  final tui.SpinnerModel spinner;
  final int index;

  @override
  tui.Cmd? init() => tui.Cmd.batch([timer.start(), spinner.tick()]);

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    var model = this;
    final cmds = <tui.Cmd?>[];

    switch (msg) {
      case tui.KeyMsg(key: final key):
        model = model._handleKey(key, cmds);
        // Let the focused model process the key as well.
        final (updated, cmd) = model._updateFocused(msg);
        model = updated;
        cmds.add(cmd);
      case tui.SpinnerTickMsg():
        final (newSpinner, cmd) = spinner.update(msg);
        model = model.copyWith(spinner: newSpinner);
        cmds.add(cmd);
      case tui.TimerTickMsg():
      case tui.TimerStartStopMsg():
        final (newTimer, cmd) = timer.update(msg);
        model = model.copyWith(timer: newTimer);
        cmds.add(cmd);
    }

    return (model, _batch(cmds));
  }

  ComposableViewsModel _handleKey(tui.Key key, List<tui.Cmd?> cmds) {
    var model = this;
    final rune = key.runes.isNotEmpty ? key.runes.first : -1;

    // Quit on q or ctrl+c.
    if ((rune == 0x71 && key.type == tui.KeyType.runes) ||
        (key.ctrl && rune == 0x63)) {
      cmds.add(tui.Cmd.quit());
      return model;
    }

    // Toggle focus.
    if (key.type == tui.KeyType.tab) {
      model = model.copyWith(
        state: state == SessionState.timer
            ? SessionState.spinner
            : SessionState.timer,
      );
    }

    // New timer/spinner.
    if (key.type == tui.KeyType.runes && rune == 0x6e) {
      if (state == SessionState.timer) {
        final resetTimer = tui.TimerModel(
          timeout: _defaultTime,
          interval: timer.interval,
        );
        model = model.copyWith(timer: resetTimer);
        cmds.add(resetTimer.start());
      } else {
        final nextIndex = (index + 1) % _spinners.length;
        final newSpinner = tui.SpinnerModel(spinner: _spinners[nextIndex]);
        model = model.copyWith(index: nextIndex, spinner: newSpinner);
        cmds.add(newSpinner.tick());
      }
    }

    return model;
  }

  (ComposableViewsModel, tui.Cmd?) _updateFocused(tui.Msg msg) {
    switch (state) {
      case SessionState.spinner:
        final (newSpinner, cmd) = spinner.update(msg);
        return (copyWith(spinner: newSpinner), cmd);
      case SessionState.timer:
        final (newTimer, cmd) = timer.update(msg);
        return (copyWith(timer: newTimer), cmd);
    }
  }

  ComposableViewsModel copyWith({
    SessionState? state,
    tui.TimerModel? timer,
    tui.SpinnerModel? spinner,
    int? index,
  }) {
    return ComposableViewsModel(
      state: state ?? this.state,
      timer: timer ?? this.timer,
      spinner: spinner ?? this.spinner,
      index: index ?? this.index,
    );
  }

  String _currentFocusedLabel() {
    return state == SessionState.timer ? 'timer' : 'spinner';
  }

  @override
  String view() {
    final timerText = timer.view().padLeft(4);
    final timerBox = state == SessionState.timer
        ? _focusedModelStyle.render(timerText)
        : _modelStyle.render(timerText);

    final spinnerText = _spinnerStyle.render(spinner.view());
    final spinnerBox = state == SessionState.spinner
        ? _focusedModelStyle.render(spinnerText)
        : _modelStyle.render(spinnerText);

    final row = Layout.joinHorizontal(VerticalAlign.top, [
      timerBox,
      spinnerBox,
    ]);

    final help = _helpStyle.render(
      '\ntab: focus next • n: new ${_currentFocusedLabel()} • q: exit\n',
    );

    return '$row$help';
  }
}

tui.Cmd? _batch(List<tui.Cmd?> cmds) {
  final filtered = cmds.whereType<tui.Cmd>().toList();
  if (filtered.isEmpty) return null;
  return tui.Cmd.batch(filtered);
}

Future<void> main() async {
  await tui.runProgram(
    ComposableViewsModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: true),
  );
}
