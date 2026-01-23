/// Send message from outside the program example (Bubble Tea "send-msg").
library;

import 'dart:async';
import 'dart:math';

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/tui.dart' as tui;

final _spinnerStyle = Style().foreground(const AnsiColor(63));
final _helpStyle = Style().foreground(const AnsiColor(241)).margin(1, 0);
final _dotStyle = Style().foreground(const AnsiColor(241)).margin(0);
final _durationStyle = _dotStyle;
final _appStyle = Style().margin(1, 2, 0, 2);

const _numLastResults = 5;

class ResultMsg extends tui.Msg {
  ResultMsg({required this.duration, required this.food});
  final Duration duration;
  final String food;

  @override
  String toString() {
    if (duration == Duration.zero) {
      return _dotStyle.render('.' * 30);
    }
    return '🍔 Ate $food ${_durationStyle.render(duration.toString())}';
  }
}

class SendMsgModel implements tui.Model {
  SendMsgModel({
    required this.spinner,
    required this.results,
    this.quitting = false,
  });

  factory SendMsgModel.initial() {
    return SendMsgModel(
      spinner: tui.SpinnerModel(spinner: tui.Spinners.line),
      results: List.generate(
        _numLastResults,
        (_) => ResultMsg(duration: Duration.zero, food: ''),
      ),
    );
  }

  final tui.SpinnerModel spinner;
  final List<ResultMsg> results;
  final bool quitting;

  @override
  tui.Cmd? init() => spinner.tick();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (copyWith(quitting: true), tui.Cmd.quit());
      case ResultMsg():
        final next = [...results]
          ..removeAt(0)
          ..add(msg);
        return (copyWith(results: next), null);
      case tui.SpinnerTickMsg():
        final (newSpinner, cmd) = spinner.update(msg);
        return (copyWith(spinner: newSpinner), cmd);
    }
    return (this, null);
  }

  SendMsgModel copyWith({
    tui.SpinnerModel? spinner,
    List<ResultMsg>? results,
    bool? quitting,
  }) {
    return SendMsgModel(
      spinner: spinner ?? this.spinner,
      results: results ?? this.results,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  String view() {
    final buffer = StringBuffer();
    if (quitting) {
      buffer.writeln("That’s all for today!");
    } else {
      buffer.writeln('${_spinnerStyle.render(spinner.view())} Eating food...');
    }
    buffer.writeln();
    for (final res in results) {
      buffer.writeln(res.toString());
    }
    if (!quitting) {
      buffer.writeln(_helpStyle.render('Press any key to exit'));
    } else {
      buffer.writeln();
    }
    return _appStyle.render(buffer.toString());
  }
}

final _random = Random();
Duration _randomPause() => Duration(milliseconds: _random.nextInt(900) + 100);

String _randomFood() {
  const foods = [
    'an apple',
    'a pear',
    'a gherkin',
    'a party gherkin',
    'a kohlrabi',
    'some spaghetti',
    'tacos',
    'a currywurst',
    'some curry',
    'a sandwich',
    'some peanut butter',
    'some cashews',
    'some ramen',
  ];
  return foods[_random.nextInt(foods.length)];
}

void _scheduleSends(tui.Program program) {
  void loop() {
    final pause = _randomPause();
    Timer(pause, () {
      // If the program has stopped, sending will be ignored.
      program.send(ResultMsg(duration: pause, food: _randomFood()));
      loop();
    });
  }

  loop();
}

Future<void> main() async {
  final program = tui.Program(SendMsgModel.initial());

  // kick off external sender
  _scheduleSends(program);

  await program.run();
}
