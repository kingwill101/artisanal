import 'dart:async';

import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/artisanal.dart' show WidgetTester;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

import '../example/main.dart' show AppWidget;

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(milliseconds: 500),
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
  group('AppWidget runtime tooltip behavior', () {
    for (final altScreen in [false, true]) {
      test('tooltip appears immediately on hover in the real gallery runtime '
          '(altScreen=$altScreen)', () async {
        final script = await _galleryOverlayCoordinates();

        final terminal = runtime.StringTerminal();
        final program = runtime.Program(
          w.WidgetApp(
            w.Overlay(
              initialEntries: [w.OverlayEntry(builder: (_) => AppWidget())],
            ),
          ),
          options: runtime.ProgramOptions(
            altScreen: altScreen,
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

        await _waitUntil(() => _plainView(program).contains('Layout'));

        _tapAt(program, script.componentsTab);
        await _waitUntil(
          () => _plainView(program).contains('Buttons + Badges'),
        );

        _tapAt(program, script.overlaysTab);
        await _waitUntil(() => _plainView(program).contains('Hover me'));

        final app = program.currentModel!;
        expect(app, isA<w.WidgetApp>());
        expect(
          app.hitTestAt(
            script.hoverTarget.x.toDouble(),
            script.hoverTarget.y.toDouble(),
          ),
          isNotEmpty,
        );

        terminal.clear();
        program.send(
          runtime.MouseMsg(
            action: runtime.MouseAction.motion,
            button: runtime.MouseButton.none,
            x: script.hoverTarget.x,
            y: script.hoverTarget.y,
          ),
        );

        await _waitUntil(
          () => _plainView(program).contains('Hover to preview tooltips'),
          timeout: const Duration(milliseconds: 100),
        );
      });
    }
  });
}

Future<
  ({
    ({int x, int y}) componentsTab,
    ({int x, int y}) overlaysTab,
    ({int x, int y}) hoverTarget,
  })
>
_galleryOverlayCoordinates() async {
  final tester = WidgetTester();
  try {
    await tester.pumpWidget(
      w.Overlay(initialEntries: [w.OverlayEntry(builder: (_) => AppWidget())]),
      width: 80,
      height: 24,
    );
    final componentsTab = _centeredTextTarget(tester, 'Components');
    tester.tapAt(componentsTab.x, componentsTab.y);
    final overlaysTab = _centeredTextTarget(tester, 'Overlays');
    tester.tapAt(overlaysTab.x, overlaysTab.y);
    final hoverTarget = tester.locateText('Hover me');
    expect(hoverTarget, isNotNull);
    return (
      componentsTab: componentsTab,
      overlaysTab: overlaysTab,
      hoverTarget: hoverTarget!,
    );
  } finally {
    tester.dispose();
  }
}

void _tapAt(runtime.Program program, ({int x, int y}) target) {
  program.send(
    runtime.MouseMsg(
      action: runtime.MouseAction.press,
      button: runtime.MouseButton.left,
      x: target.x,
      y: target.y,
    ),
  );
  program.send(
    runtime.MouseMsg(
      action: runtime.MouseAction.release,
      button: runtime.MouseButton.left,
      x: target.x,
      y: target.y,
    ),
  );
}

({int x, int y}) _centeredTextTarget(WidgetTester tester, String text) {
  final loc = tester.locateText(text);
  expect(
    loc,
    isNotNull,
    reason: 'Could not locate "$text" in widget tester view',
  );
  return (x: loc!.x + text.length ~/ 2, y: loc.y);
}

String _plainView(runtime.Program program) {
  return Style.stripAnsi(program.currentModel?.view().toString() ?? '');
}
