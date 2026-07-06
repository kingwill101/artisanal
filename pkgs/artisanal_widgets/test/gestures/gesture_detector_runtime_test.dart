import 'dart:async';

import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(milliseconds: 250),
  Duration step = const Duration(milliseconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(step);
  }
  if (!predicate()) {
    fail('Condition not met within $timeout');
  }
}

void main() {
  group('GestureDetector runtime hover commands', () {
    test(
      'hover enter and exit repaint immediately in the real runtime',
      () async {
        final terminal = runtime.StringTerminal();
        final program = runtime.Program(
          w.WidgetApp(_HoverCmdRuntimeWidget()),
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouse: true,
            mouseMode: runtime.MouseMode.allMotion,
            signalHandlers: false,
            frameTick: false,
            startupProbes: false,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        addTearDown(() async {
          program.send(const runtime.QuitMsg());
          await runFuture;
        });

        await _waitUntil(
          () => Style.stripAnsi(terminal.output).contains('not hovered'),
        );

        terminal.clear();
        program.send(
          const runtime.MouseMsg(
            action: runtime.MouseAction.motion,
            button: runtime.MouseButton.none,
            x: 0,
            y: 0,
          ),
        );

        await _waitUntil(
          () => Style.stripAnsi(terminal.output).contains('hovered'),
        );

        terminal.clear();
        program.send(
          const runtime.MouseMsg(
            action: runtime.MouseAction.motion,
            button: runtime.MouseButton.none,
            x: 79,
            y: 23,
          ),
        );

        await _waitUntil(() => terminal.output.isNotEmpty);
        final stripped = Style.stripAnsi(terminal.output);
        expect(stripped, contains('not hovered'));
        expect(
          stripped
              .split('\n')
              .any(
                (line) =>
                    line.contains('hovered') && !line.contains('not hovered'),
              ),
          isFalse,
        );
      },
    );
  });
}

class _HoverCmdMsg extends runtime.Msg {
  const _HoverCmdMsg(this.hovering);

  final bool hovering;
}

class _HoverCmdRuntimeWidget extends w.StatefulWidget {
  @override
  w.State createState() => _HoverCmdRuntimeState();
}

class _HoverCmdRuntimeState extends w.State<_HoverCmdRuntimeWidget> {
  bool _hovering = false;

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is _HoverCmdMsg) {
      setState(() => _hovering = msg.hovering);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Stack(
      width: 80,
      height: 24,
      children: [
        w.Positioned(
          left: 0,
          top: 0,
          child: w.GestureDetector(
            onEnter: (_) => runtime.Cmd.message(const _HoverCmdMsg(true)),
            onExit: (_) => runtime.Cmd.message(const _HoverCmdMsg(false)),
            child: w.Container(
              width: 20,
              height: 1,
              child: w.Text(_hovering ? 'hovered' : 'not hovered'),
            ),
          ),
        ),
      ],
    );
  }
}
