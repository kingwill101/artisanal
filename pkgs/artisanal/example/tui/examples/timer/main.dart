/// Timer example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;

const _timeout = Duration(seconds: 5);

class TimerKeys implements tui.KeyMap {
  TimerKeys()
    : start = tui.KeyBinding.withHelp(['s'], 's', 'start/stop'),
      stop = tui.KeyBinding.withHelp(['s'], 's', 'start/stop'),
      reset = tui.KeyBinding.withHelp(['r'], 'r', 'reset'),
      quit = tui.KeyBinding.withHelp(['q', 'ctrl+c'], 'q', 'quit');

  final tui.KeyBinding start;
  final tui.KeyBinding stop;
  final tui.KeyBinding reset;
  final tui.KeyBinding quit;

  @override
  List<tui.KeyBinding> shortHelp() => [start, reset, quit];

  @override
  List<List<tui.KeyBinding>> fullHelp() => [
    [start, reset, quit],
  ];
}

class TimerExampleModel implements tui.Model {
  TimerExampleModel({
    required this.timer,
    required this.keys,
    required this.help,
    this.quitting = false,
  });

  factory TimerExampleModel.initial() {
    final timer = tui.TimerModel(
      timeout: _timeout,
      interval: const Duration(milliseconds: 100),
    );
    return TimerExampleModel(
      timer: timer,
      keys: TimerKeys(),
      help: tui.HelpModel(),
    );
  }

  final tui.TimerModel timer;
  final TimerKeys keys;
  final tui.HelpModel help;
  final bool quitting;

  @override
  tui.Cmd? init() => timer.start();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.TimerTickMsg():
      case tui.TimerStartStopMsg():
        final (newTimerModel, cmd) = timer.update(msg);
        final tm = newTimerModel;
        final quitCmd = tm.timedOut ? tui.Cmd.quit() : null;
        return (
          copyWith(timer: tm, quitting: quitting || tm.timedOut),
          _batch([cmd, quitCmd]),
        );

      case tui.KeyMsg(key: final key):
        if (key.matches([keys.quit])) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }
        if (key.matches([keys.reset])) {
          final resetTimer = tui.TimerModel(
            timeout: _timeout,
            interval: timer.interval,
          );
          return (
            copyWith(timer: resetTimer, quitting: false),
            resetTimer.start(),
          );
        }
        if (key.matches([keys.start, keys.stop])) {
          return (this, timer.toggle());
        }
    }

    return (this, null);
  }

  TimerExampleModel copyWith({
    tui.TimerModel? timer,
    TimerKeys? keys,
    tui.HelpModel? help,
    bool? quitting,
  }) {
    return TimerExampleModel(
      timer: timer ?? this.timer,
      keys: keys ?? this.keys,
      help: help ?? this.help,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  String view() {
    var s = timer.view();
    if (timer.timedOut) {
      s = 'All done!';
    }
    if (!quitting) {
      s = 'Exiting in $s';
      s += '\n${help.shortHelpView([keys.start, keys.reset, keys.quit])}';
    }
    return '$s\n';
  }
}

tui.Cmd? _batch(List<tui.Cmd?> cmds) {
  final filtered = cmds.whereType<tui.Cmd>().toList();
  return filtered.isEmpty ? null : tui.Cmd.batch(filtered);
}

Future<void> main() async {
  await tui.runProgram(
    TimerExampleModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
