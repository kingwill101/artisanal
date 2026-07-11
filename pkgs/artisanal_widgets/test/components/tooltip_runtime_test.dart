import 'dart:async';

import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/artisanal.dart' show WidgetTester;
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
  if (!predicate()) fail('Condition not met within $timeout');
}

void main() {
  group('Tooltip runtime overlay behavior', () {
    test('floating tooltip can render immediately when show=true', () async {
      final terminal = runtime.StringTerminal();
      final program = runtime.Program(
        w.WidgetApp(
          w.Overlay(
            initialEntries: [
              w.OverlayEntry(
                builder: (_) => w.Stack(
                  width: 80,
                  height: 24,
                  children: [
                    w.Positioned(
                      left: 0,
                      top: 1,
                      child: w.Tooltip(
                        message: 'Hover to preview tooltips',
                        show: true,
                        child: w.Text('Hover me'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        () => _plainView(program).contains('Hover to preview tooltips'),
      );
      expect(_plainView(program), contains('Hover to preview tooltips'));
    });

    test(
      'floating tooltip appears immediately on hover enter for plain text',
      () async {
        final terminal = runtime.StringTerminal();
        final program = runtime.Program(
          w.WidgetApp(_overlayRoot(child: w.Text('Hover me'))),
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

        final target = await _overlayHoverTarget(child: w.Text('Hover me'));

        terminal.clear();
        program.send(
          runtime.MouseMsg(
            action: runtime.MouseAction.motion,
            button: runtime.MouseButton.none,
            x: target.x,
            y: target.y,
          ),
        );

        await _waitUntil(
          () => _plainView(program).contains('Hover to preview tooltips'),
        );
        expect(_plainView(program), contains('Hover to preview tooltips'));
      },
    );

    test(
      'floating tooltip appears immediately when child has its own MouseRegion',
      () async {
        final terminal = runtime.StringTerminal();
        final program = runtime.Program(
          w.WidgetApp(
            _overlayRoot(
              child: w.MouseRegion(
                onEnter: (_) => runtime.Cmd.repaint(),
                child: w.Button(label: 'Hover me', onPressed: () => null),
              ),
            ),
          ),
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

        final hoverTarget = await _overlayHoverTarget(
          child: w.MouseRegion(
            onEnter: (_) => runtime.Cmd.repaint(),
            child: w.Button(label: 'Hover me', onPressed: () => null),
          ),
        );

        terminal.clear();
        program.send(
          runtime.MouseMsg(
            action: runtime.MouseAction.motion,
            button: runtime.MouseButton.none,
            x: hoverTarget.x,
            y: hoverTarget.y,
          ),
        );

        await _waitUntil(
          () => _plainView(program).contains('Hover to preview tooltips'),
        );
        expect(_plainView(program), contains('Hover to preview tooltips'));
      },
    );

    test('floating tooltip appears immediately on hover enter', () async {
      final terminal = runtime.StringTerminal();
      final program = runtime.Program(
        w.WidgetApp(_overlayRoot()),
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

      final hoverTarget = await _overlayHoverTarget();
      final app = program.currentModel!;
      expect(app, isA<w.WidgetApp>());
      expect(
        app.hitTestAt(hoverTarget.x.toDouble(), hoverTarget.y.toDouble()),
        isNotEmpty,
      );

      terminal.clear();
      program.send(
        runtime.MouseMsg(
          action: runtime.MouseAction.motion,
          button: runtime.MouseButton.none,
          x: hoverTarget.x,
          y: hoverTarget.y,
        ),
      );

      await _waitUntil(
        () => _plainView(program).contains('Hover to preview tooltips'),
      );
      final plain = _plainView(program);
      expect(
        plain,
        contains('Hover to preview tooltips'),
        reason:
            'hover output was: ${terminal.output}\n'
            'view after hover was: $plain',
      );
    });

    test('floating tooltip disappears immediately on hover exit', () async {
      final terminal = runtime.StringTerminal();
      final program = runtime.Program(
        w.WidgetApp(_overlayRoot()),
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

      final hoverTarget = await _overlayHoverTarget();
      final app = program.currentModel!;
      expect(app, isA<w.WidgetApp>());
      expect(
        app.hitTestAt(hoverTarget.x.toDouble(), hoverTarget.y.toDouble()),
        isNotEmpty,
      );

      program.send(
        runtime.MouseMsg(
          action: runtime.MouseAction.motion,
          button: runtime.MouseButton.none,
          x: hoverTarget.x,
          y: hoverTarget.y,
        ),
      );
      await _waitUntil(
        () => _plainView(program).contains('Hover to preview tooltips'),
      );

      terminal.clear();
      program.send(
        const runtime.MouseMsg(
          action: runtime.MouseAction.motion,
          button: runtime.MouseButton.none,
          x: 70,
          y: 20,
        ),
      );

      await _waitUntil(
        () => !_plainView(program).contains('Hover to preview tooltips'),
      );
      final plain = _plainView(program);
      expect(plain, isNot(contains('Hover to preview tooltips')));
      expect(plain, contains('Hover me'));
    });

    test(
      'floating tooltip stays stable without repaint churn while hovered',
      () async {
        final terminal = runtime.StringTerminal();
        final program = runtime.Program(
          w.WidgetApp(_overlayRoot()),
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

        final hoverTarget = await _overlayHoverTarget();

        terminal.clear();
        program.send(
          runtime.MouseMsg(
            action: runtime.MouseAction.motion,
            button: runtime.MouseButton.none,
            x: hoverTarget.x,
            y: hoverTarget.y,
          ),
        );

        await _waitUntil(
          () => _plainView(program).contains('Hover to preview tooltips'),
        );

        final settledOutput = _plainView(program);
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(
          _plainView(program),
          equals(settledOutput),
          reason: 'tooltip output should stay stable without new input',
        );
      },
    );
  });
}

Future<({int x, int y})> _overlayHoverTarget({w.Widget? child}) async {
  final tester = WidgetTester();
  try {
    await tester.pumpWidget(_overlayRoot(child: child), width: 80, height: 24);
    final target = tester.locateText('Hover me');
    expect(target, isNotNull);
    return target!;
  } finally {
    tester.dispose();
  }
}

String _plainView(runtime.Program program) {
  return Style.stripAnsi(program.currentModel?.view().toString() ?? '');
}

w.Widget _overlayRoot({w.Widget? child}) => w.Overlay(
  initialEntries: [w.OverlayEntry(builder: (_) => _TooltipHost(child: child))],
);

class _TooltipHost extends w.StatelessWidget {
  _TooltipHost({this.child});

  final w.Widget? child;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Stack(
      width: 80,
      height: 24,
      children: [
        w.Positioned(
          left: 0,
          top: 1,
          child: w.Tooltip(
            message: 'Hover to preview tooltips',
            child: child ?? w.Button(label: 'Hover me', onPressed: () => null),
          ),
        ),
      ],
    );
  }
}
