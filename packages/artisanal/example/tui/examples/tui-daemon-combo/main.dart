/// TUI + daemon combo example ported from Bubble Tea.
library;

import 'dart:io' as io;
import 'dart:math';

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/src/unicode/grapheme.dart' as uni;

final _helpStyle = Style().foreground(const AnsiColor(241)).render;
final _mainStyle = Style().margin(0, 1, 0, 1);

class ProcessFinishedMsg extends tui.Msg {
  const ProcessFinishedMsg(this.duration);
  final Duration duration;
}

class Result {
  Result({required this.duration, required this.emoji});
  final Duration duration;
  final String emoji;
}

class DaemonComboModel implements tui.Model {
  DaemonComboModel({
    required this.spinner,
    required this.results,
    this.quitting = false,
  });

  factory DaemonComboModel.initial() {
    const showLastResults = 5;
    final sp = tui.SpinnerModel();
    return DaemonComboModel(
      spinner: sp,
      results: List<Result>.generate(
        showLastResults,
        (_) => Result(duration: Duration.zero, emoji: ''),
      ),
    );
  }

  final tui.SpinnerModel spinner;
  final List<Result> results;
  final bool quitting;

  @override
  tui.Cmd? init() {
    return tui.Cmd.batch([
      tui.Cmd.println('Starting work...'),
      spinner.tick(),
      _runPretendProcess(),
    ]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (copyWith(quitting: true), tui.Cmd.quit());
      case tui.SpinnerTickMsg():
        final (newSpin, cmd) = spinner.update(msg);
        return (copyWith(spinner: newSpin), cmd);
      case ProcessFinishedMsg(:final duration):
        final res = Result(duration: duration, emoji: _randomEmoji());
        final nextResults = [...results.skip(1), res];
        return (
          copyWith(results: nextResults),
          tui.Cmd.batch([
            tui.Cmd.println('${res.emoji} Job finished in ${res.duration}'),
            _runPretendProcess(),
          ]),
        );
    }
    return (this, null);
  }

  DaemonComboModel copyWith({
    tui.SpinnerModel? spinner,
    List<Result>? results,
    bool? quitting,
  }) {
    return DaemonComboModel(
      spinner: spinner ?? this.spinner,
      results: results ?? this.results,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  String view() {
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('${spinner.view()} Doing some work...')
      ..writeln();

    for (final res in results) {
      if (res.duration == Duration.zero) {
        buffer.writeln('........................');
      } else {
        buffer.writeln('${res.emoji} Job finished in ${res.duration}');
      }
    }

    buffer.writeln(_helpStyle('\nPress any key to exit\n'));
    if (quitting) buffer.writeln();

    return _mainStyle.render(buffer.toString());
  }
}

tui.Cmd _runPretendProcess() {
  final pause = Duration(milliseconds: Random().nextInt(900) + 100);
  return tui.Cmd.tick(pause, (_) => ProcessFinishedMsg(pause));
}

String _randomEmoji() {
  const emojis = '🍦🧋🍡🤠👾😭🦊🐯🦆🥨🎏🍔🍒🍥🎮📦🦁🐶🐸🍕🥐🧲🚒🥇🏆🌽';
  final clusters = uni.graphemes(emojis).toList();
  final r = Random().nextInt(clusters.length);
  return clusters[r];
}

void _printUsage() {
  tui.Cmd.println('Usage: dart main.dart [-d] [-h]'); // tui:allow-stdout
  tui.Cmd.println(
    // tui:allow-stdout
    '  -d   daemon mode (no TUI, but we still run tasks)',
  );
  tui.Cmd.println('  -h   show this help'); // tui:allow-stdout
}

Future<void> main(List<String> args) async {
  var daemonMode = false;
  var showHelp = false;
  for (final arg in args) {
    if (arg == '-d') daemonMode = true;
    if (arg == '-h' || arg == '--help') showHelp = true;
  }

  if (showHelp) {
    _printUsage();
    return;
  }

  // In daemon mode or when not attached to a TTY, still run but avoid alt screen.
  final options = tui.ProgramOptions(
    altScreen: !(daemonMode || !io.stdout.hasTerminal),
    hideCursor: !(daemonMode || !io.stdout.hasTerminal),
    useUltravioletRenderer: true,
    useUltravioletInputDecoder: true,
  );

  await tui.runProgram(DaemonComboModel.initial(), options: options);
}
