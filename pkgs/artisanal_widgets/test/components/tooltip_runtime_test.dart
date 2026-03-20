import 'dart:async';

import 'package:artisanal/runtime.dart' as runtime;
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

      await _waitUntil(() => terminal.output.isNotEmpty);
      expect(
        Style.stripAnsi(terminal.output),
        contains('Hover to preview tooltips'),
      );
    });

    test('floating tooltip appears immediately on hover enter for plain text', () async {
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

      await _waitUntil(
        () => Style.stripAnsi(terminal.output).contains('Hover me'),
      );

      final hoverTarget = _locateText(Style.stripAnsi(terminal.output), 'Hover me');
      expect(hoverTarget, isNotNull);
      final target = hoverTarget!;

      terminal.clear();
      program.send(
        runtime.MouseMsg(
          action: runtime.MouseAction.motion,
          button: runtime.MouseButton.none,
          x: target.x,
          y: target.y,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        Style.stripAnsi(terminal.output),
        contains('Hover to preview tooltips'),
      );
    });

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

      await _waitUntil(
        () => Style.stripAnsi(terminal.output).contains('Hover me'),
      );

      final hoverTarget = _locateText(Style.stripAnsi(terminal.output), 'Hover me');
      expect(hoverTarget, isNotNull);
      final app = program.currentModel!;
      expect(app, isA<w.WidgetApp>());
      expect(
        app.hitTestAt(
          hoverTarget!.x.toDouble(),
          hoverTarget.y.toDouble(),
        ),
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

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final plain = Style.stripAnsi(terminal.output);
      final viewAfterHover = Style.stripAnsi(
        program.currentModel!.view().toString(),
      );
      expect(
        plain,
        contains('Hover to preview tooltips'),
        reason:
            'hover output was: ${terminal.output}\n'
            'view after hover was: $viewAfterHover',
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

      await _waitUntil(
        () => Style.stripAnsi(terminal.output).contains('Hover me'),
      );

      final hoverTarget = _locateText(Style.stripAnsi(terminal.output), 'Hover me');
      expect(hoverTarget, isNotNull);
      final app = program.currentModel!;
      expect(app, isA<w.WidgetApp>());
      expect(
        app.hitTestAt(
          hoverTarget!.x.toDouble(),
          hoverTarget.y.toDouble(),
        ),
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
        () => Style.stripAnsi(terminal.output).contains('Hover to preview tooltips'),
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

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final plain = Style.stripAnsi(terminal.output);
      expect(plain, isNot(contains('Hover to preview tooltips')));
      expect(plain, contains('Hover me'));
    });
  });
}

({int x, int y})? _locateText(String view, String text) {
  final lines = view.split('\n');
  for (var row = 0; row < lines.length; row++) {
    final col = lines[row].indexOf(text);
    if (col >= 0) return (x: col, y: row);
  }
  return null;
}

w.Widget _overlayRoot({w.Widget? child}) => w.Overlay(
  initialEntries: [
    w.OverlayEntry(builder: (_) => _TooltipHost(child: child)),
  ],
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
