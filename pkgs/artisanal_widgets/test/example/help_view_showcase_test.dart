import 'package:artisanal/style.dart' show BasicColor;
import 'package:artisanal/terminal.dart' show StringTerminal;
import 'package:artisanal/tui.dart' show View, WindowSizeMsg;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

import '../../example/help_view/main.dart';

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for HelpView example render');
}

void main() {
  test('HelpView showcase renders and toggles preview mode', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(HelpViewShowcase(), width: 100, height: 32);
    tester.pump();

    expect(tester.find.text('HelpView Showcase'), isTrue);
    expect(tester.find.text('Compact mode'), isTrue);
    expect(tester.find.text('Compact Footer Style'), isTrue);
    expect(tester.find.text('ctrl+p'), isTrue);
    expect(tester.viewContains('─' * 93), isTrue);
    expect(tester.viewContains('╭'), isFalse);

    tester.sendKey('?');

    expect(tester.find.text('Full grouped mode'), isTrue);
    expect(tester.find.text('toggle help'), isTrue);
  });

  test('HelpView app publishes the current theme as terminal background', () {
    final initialDarkBackground = w.hasDarkBackground;
    addTearDown(() => w.setHasDarkBackground(initialDarkBackground));

    w.setHasDarkBackground(false);
    final app = createHelpViewApp();
    app.update(const WindowSizeMsg(100, 32));

    final view = app.view();
    expect(view, isA<View>());
    expect((view as View).backgroundColor, equals(const BasicColor('#eeeeee')));

    w.setHasDarkBackground(true);
    app.update(const WindowSizeMsg(100, 32));
    final darkView = app.view();
    expect(darkView, isA<View>());
    expect(
      (darkView as View).backgroundColor,
      equals(const BasicColor('#121212')),
    );
  });

  test('HelpView program emits OSC 11 background override', () async {
    final terminal = StringTerminal(terminalWidth: 100, terminalHeight: 32);
    final program = tui.Program<tui.WidgetApp>(
      createHelpViewApp(),
      options: const tui.ProgramOptions(
        useUltravioletRenderer: true,
        altScreen: true,
        signalHandlers: false,
        catchPanics: false,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();
    try {
      await _waitFor(() => terminal.output.contains('\x1b]11;#'));
      expect(terminal.output, contains('\x1b]11;#'));
    } finally {
      program.quit();
      try {
        await runFuture.timeout(const Duration(seconds: 2));
      } catch (_) {
        program.kill();
      }
    }
  });

  test('HelpView program resolves light background before first frame', () async {
    final initialDarkBackground = w.hasDarkBackground;
    addTearDown(() => w.setHasDarkBackground(initialDarkBackground));
    w.setHasDarkBackground(true);

    final terminal = StringTerminal(terminalWidth: 100, terminalHeight: 32);
    final program = tui.Program<tui.WidgetApp>(
      createHelpViewApp(),
      options: const tui.ProgramOptions(
        useUltravioletRenderer: true,
        altScreen: true,
        signalHandlers: false,
        catchPanics: false,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();
    try {
      await _waitFor(() => terminal.output.contains('\x1b]11;?\x07'));
      terminal.simulateInput('\x1b]11;rgb:ffff/ffff/ffff\x07'.codeUnits);

      await _waitFor(() => terminal.output.contains('\x1b]11;#eeeeee\x07'));
      expect(terminal.output, contains('\x1b]11;#eeeeee\x07'));
      expect(terminal.output, isNot(contains('\x1b]11;#121212\x07')));
    } finally {
      program.quit();
      try {
        await runFuture.timeout(const Duration(seconds: 2));
      } catch (_) {
        program.kill();
      }
    }
  });
}
