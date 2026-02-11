import 'dart:async';

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

import 'mock_terminal.dart' show MockTerminal;

void main() {
  setUp(() {
    tui.initGlobalZone();
  });

  tearDown(() {
    tui.closeGlobalZone();
  });

  test('mouse interaction does not block key quit in viewport', () async {
    final terminal = MockTerminal();
    final app = tui.WidgetApp(_QuitOnQ(), scanZones: true);
    final program = tui.Program(
      app,
      options: const tui.ProgramOptions(
        altScreen: false,
        mouse: true,
        useUltravioletRenderer: false,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();

    // Allow initial render + zone scan.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final zoneInfo = tui.zone.get('vp');
    expect(zoneInfo, isNotNull);

    // Send a mouse press/release inside the viewport zone.
    final x = zoneInfo!.startX + 1;
    final y = zoneInfo.startY + 1;
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
    final app = tui.WidgetApp(_QuitOnQ(), scanZones: true);
    final program = tui.Program(
      app,
      options: const tui.ProgramOptions(
        altScreen: false,
        mouse: true,
        useUltravioletRenderer: false,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final zoneInfo = tui.zone.get('vp');
    expect(zoneInfo, isNotNull);

    final x = zoneInfo!.startX + 1;
    final y = zoneInfo.startY + 1;
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

class _QuitOnQ extends w.StatefulWidget {
  _QuitOnQ();

  @override
  w.State createState() => _QuitOnQState();
}

class _QuitOnQState extends w.State<_QuitOnQ> {
  final w.ViewportController _controller = w.ViewportController();

  @override
  w.Widget build(w.BuildContext context) {
    final content = _contentLines(60);
    return w.Container(
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        children: [
          w.Text('Scroll Test'),
          w.Container(
            width: 20,
            height: 6,
            child: w.Viewport(
              content: content,
              width: 18,
              height: 4,
              showScrollbar: true,
              controller: _controller,
              zoneId: 'vp',
            ),
          ),
          w.Text('Press q to quit'),
        ],
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
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
