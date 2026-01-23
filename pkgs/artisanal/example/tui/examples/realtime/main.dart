/// Real-time external activity example ported from Bubble Tea.
library;

import 'dart:async';
import 'dart:math';

import 'package:artisanal/tui.dart' as tui;

class ResponseMsg extends tui.Msg {}

class RealtimeModel implements tui.Model {
  RealtimeModel({
    required this.sub,
    required this.spinner,
    this.responses = 0,
    this.quitting = false,
  });

  final StreamController<void> sub;
  final tui.SpinnerModel spinner;
  final int responses;
  final bool quitting;

  @override
  tui.Cmd? init() => tui.Cmd.batch([
    spinner.tick(),
    tui.Cmd.listen<void>(sub.stream, onData: (_) => ResponseMsg()),
  ]);

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (copyWith(quitting: true), tui.Cmd.quit());
      case ResponseMsg():
        return (copyWith(responses: responses + 1), null);
      case tui.SpinnerTickMsg():
        final (newSpinner, cmd) = spinner.update(msg);
        return (copyWith(spinner: newSpinner), cmd);
    }
    return (this, null);
  }

  RealtimeModel copyWith({
    StreamController<void>? sub,
    tui.SpinnerModel? spinner,
    int? responses,
    bool? quitting,
  }) {
    return RealtimeModel(
      sub: sub ?? this.sub,
      spinner: spinner ?? this.spinner,
      responses: responses ?? this.responses,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  String view() {
    var s =
        '\n ${spinner.view()} Events received: $responses\n\n Press any key to exit\n';
    if (quitting) {
      s += '\n';
    }
    return s;
  }
}

void _startProducer(StreamController<void> sub) {
  final rand = Random();
  void loop() {
    if (sub.isClosed) return;
    final pause = Duration(milliseconds: rand.nextInt(900) + 100);
    Timer(pause, () {
      if (sub.isClosed) return;
      sub.add(null);
      loop();
    });
  }

  loop();
}

Future<void> main() async {
  final sub = StreamController<void>();
  final program = tui.Program(
    RealtimeModel(sub: sub, spinner: tui.SpinnerModel()),
  );

  _startProducer(sub);
  await program.run();
  await sub.close();
}
