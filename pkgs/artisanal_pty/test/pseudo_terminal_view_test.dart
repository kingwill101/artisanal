import 'dart:async';
import 'dart:io';

import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/terminal.dart' as terminal_keys show Key, KeyType;
import 'package:artisanal_pty/widgets.dart';
import 'package:artisanal_widgets/testing.dart';
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

  test('normalizes bare line feeds from raw PTY output', () async {
    final pty = _FakePseudoTerminal();
    final focus = FocusController();
    final tester = WidgetTester(screenWidth: 12, screenHeight: 3);
    addTearDown(tester.dispose);
    await tester.pumpWidget(
      PseudoTerminalView(
        pty: pty,
        focusController: focus,
        focusId: 'terminal',
        quitOnExit: false,
      ),
    );
    expect(focus.focusedId, 'terminal');

    pty.emit('abc\nx');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    tester.pump();

    final firstLine = tester.locateText('abc');
    final secondLine = tester.locateText('x');
    expect(firstLine, isNotNull);
    expect(secondLine, isNotNull);
    expect(
      secondLine!.x,
      firstLine!.x,
      reason: 'a raw LF should begin the following line at column zero',
    );
    expect(pty.acknowledgedChunks, 1);

    pty.emit('\ny');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    tester.pump();
    expect(tester.locateText('y')?.x, firstLine.x);
    expect(pty.acknowledgedChunks, 2);

    tester.sendMsg(
      const runtime.KeyMsg(
        terminal_keys.Key(
          terminal_keys.KeyType.runes,
          runes: [0x63],
          ctrl: true,
        ),
      ),
    );
    expect(pty.input, ['\x03']);

    pty.emit('\x1b[?1h\x1b[6n');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    tester.pump();
    expect(
      focus.focusedId,
      'terminal',
      reason: 'negotiating cursor mode must not dispose terminal focus',
    );
    tester.sendMsg(
      const runtime.KeyMsg(terminal_keys.Key(terminal_keys.KeyType.up)),
    );
    expect(pty.input, contains('\x1bOA'));
    expect(
      pty.input,
      contains(matches(RegExp(r'^\x1b\[\d+;\d+R$'))),
      reason: 'cursor position reports should be answered through the PTY',
    );

    pty.emit('\nz');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    tester.pump();
    pty.emit('\x1b[>13u\x1b[?1000h\x1b[?1006h');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    tester.pump();
    expect(
      focus.focusedId,
      'terminal',
      reason: 'negotiating child mouse mode must not dispose terminal focus',
    );
    tester.sendMsg(
      const runtime.KeyMsg(terminal_keys.Key(terminal_keys.KeyType.down)),
    );
    tester.mouseDown(4, 2);
    tester.mouseUp(4, 2);
    tester.sendMsg(
      const runtime.MouseMsg(
        action: runtime.MouseAction.wheel,
        button: runtime.MouseButton.wheelDown,
        x: 4,
        y: 2,
      ),
    );
    expect(pty.input, contains('\x1b[B'));
    expect(pty.input, contains('\x1b[<0;5;3M'));
    expect(pty.input, contains('\x1b[<0;5;3m'));
    expect(pty.input, contains('\x1b[<65;5;3M'));
  });

  test(
    'mouse wheel navigates local scrollback outside child mouse mode',
    () async {
      final pty = _FakePseudoTerminal();
      final tester = WidgetTester(screenWidth: 12, screenHeight: 3);
      addTearDown(tester.dispose);
      await tester.pumpWidget(PseudoTerminalView(pty: pty, quitOnExit: false));

      pty.emit('one\r\ntwo\r\nthree\r\nfour');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      tester.pump();
      expect(tester.view, isNot(contains('one')));

      tester.sendMsg(
        const runtime.MouseMsg(
          action: runtime.MouseAction.wheel,
          button: runtime.MouseButton.wheelUp,
          x: 2,
          y: 1,
        ),
      );

      expect(tester.view, contains('one'));
      expect(pty.input, isEmpty);
    },
  );
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
  int acknowledgedChunks = 0;
  final List<String> input = [];

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
  void ackProcessed() => acknowledgedChunks++;

  @override
  void init() {}

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  void resize(int width, int height) {}

  @override
  void write(String value) => input.add(value);
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
