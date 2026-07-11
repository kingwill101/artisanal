import 'dart:async';

import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import 'mock_terminal.dart' show MockTerminal;

void main() {
  test('mouse interaction does not block key quit in viewport', () async {
    final terminal = MockTerminal();
    final app = WidgetApp(_QuitOnQ());
    final program = Program(
      app,
      options: const ProgramOptions(
        altScreen: false,
        mouse: true,
        useUltravioletRenderer: false,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();

    // Allow initial render.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Send a mouse press/release inside the viewport region.
    const x = 3;
    const y = 4;
    terminal.sendInput(_sgrMouse(0, x, y, release: false));
    terminal.sendInput(_sgrMouse(0, x, y, release: true));

    // Send quit key.
    terminal.sendInput('q'.codeUnits);

    await runFuture.timeout(
      const Duration(seconds: 1),
      onTimeout: () => fail('Program did not quit after key input'),
    );
  });

  test('coalesces mouse bursts so keys are processed', () async {
    final terminal = MockTerminal();
    final app = WidgetApp(_QuitOnQ());
    final program = Program(
      app,
      options: const ProgramOptions(
        altScreen: false,
        mouse: true,
        useUltravioletRenderer: false,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    const x = 3;
    const y = 4;
    final burst = <int>[];
    for (var i = 0; i < 50; i++) {
      burst.addAll(_sgrMouse(64, x, y, release: false));
    }
    terminal.sendInput(burst);
    terminal.sendInput('q'.codeUnits);

    await runFuture.timeout(
      const Duration(seconds: 1),
      onTimeout: () => fail('Program did not quit after burst input'),
    );
  });
}

List<int> _sgrMouse(int button, int x, int y, {required bool release}) {
  final end = release ? 'm' : 'M';
  return '[<$button;$x;$y$end'.codeUnits;
}

class _QuitOnQ extends StatefulWidget {
  _QuitOnQ();

  @override
  State createState() => _QuitOnQState();
}

class _QuitOnQState extends State<_QuitOnQ> {
  final ViewportController _controller = ViewportController();

  @override
  Widget build(BuildContext context) {
    final content = _contentLines(60);
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        gap: 1,
        children: [
          Text('Scroll Test'),
          Container(
            width: 20,
            height: 6,
            child: Viewport(
              content: content,
              width: 18,
              height: 4,
              showScrollbar: true,
              controller: _controller,
              zoneId: 'vp',
            ),
          ),
          Text('Press q to quit'),
        ],
      ),
    );
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg && msg.key.char == 'q') {
      return Cmd.quit();
    }
    return null;
  }
}

String _contentLines(int count) {
  final buffer = StringBuffer();
  for (var i = 0; i < count; i++) {
    buffer.writeln('Item ${i + 1}');
  }
  return buffer.toString().trimRight();
}
