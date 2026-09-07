import 'dart:async';
import 'dart:io';

import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_pty/widgets.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:pty2/pty2.dart';
import 'package:test/test.dart';

void main() {
  test('quits the widget app when the PTY exits', () async {
    final pty = _FakePseudoTerminal();
    final app = WidgetApp(PseudoTerminalView(pty: pty));
    final init = app.init();
    final messages = <runtime.Msg>[];

    _startStreams(init, (message) {
      messages.add(message);
      final result = app.update(message);
      if (result.$2 case final command?) {
        command.execute().then((message) {
          if (message != null) messages.add(message);
        });
      }
    });

    pty.complete(0);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(messages, contains(isA<runtime.QuitMsg>()));
  });

  test('ignores queued output from a replaced PTY', () async {
    final oldPty = _FakePseudoTerminal(syncOutput: true);
    final newPty = _FakePseudoTerminal(syncOutput: true);
    final app = WidgetApp(_PtyHost(initial: oldPty));
    final init = app.init();

    _startStreams(init, (message) => app.update(message));
    oldPty.emit('old');
    app.update(_ReplacePtyMsg(newPty));
    newPty.emit('new');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final view = app.view().toString();
    // The headless app has a 1x1 viewport, so only each chunk's final cell is
    // visible. The new PTY's `w` must win and the stale old PTY's `d` must not.
    expect(view, contains('w'));
    expect(view, isNot(contains('d')));
  });
}

void _startStreams(runtime.Cmd? command, void Function(runtime.Msg) send) {
  switch (command) {
    case runtime.StreamCmd<dynamic> stream:
      stream.start(send);
    case runtime.ParallelCmd parallel:
      for (final child in parallel.commands) {
        _startStreams(child, send);
      }
  }
}

final class _FakePseudoTerminal implements PseudoTerminal {
  _FakePseudoTerminal({bool syncOutput = false})
    : _output = StreamController(sync: syncOutput);

  final StreamController<String> _output;
  final Completer<int> _exit = Completer();

  void emit(String data) => _output.add(data);

  void complete(int exitCode) {
    _output.close();
    _exit.complete(exitCode);
  }

  @override
  Stream<String> get out => _output.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  void ackProcessed() {}

  @override
  void init() {}

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  void resize(int width, int height) {}

  @override
  void write(String input) {}
}

final class _ReplacePtyMsg extends runtime.Msg {
  const _ReplacePtyMsg(this.pty);

  final PseudoTerminal pty;
}

final class _PtyHost extends StatefulWidget {
  _PtyHost({required this.initial});

  final PseudoTerminal initial;

  @override
  State<_PtyHost> createState() => _PtyHostState();
}

final class _PtyHostState extends State<_PtyHost> {
  late PseudoTerminal _pty = widget.initial;

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg case _ReplacePtyMsg(:final pty)) {
      setState(() => _pty = pty);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) =>
      PseudoTerminalView(pty: _pty, quitOnExit: false);
}
