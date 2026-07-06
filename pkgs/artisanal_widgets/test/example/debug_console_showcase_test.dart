import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/debug_console/main.dart' as example;

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    tester.pump();
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for debug console showcase render');
}

void main() {
  test('debug console showcase logs through the app console scope', () async {
    final controller = DebugConsoleController(initiallyVisible: true);
    final tester = WidgetTester(screenWidth: 84, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: DebugConsoleHost(
          controller: controller,
          child: example.DebugConsoleShowcaseScreen(),
        ),
      ),
    );

    await _pumpUntil(
      tester,
      () => tester.view.contains('Debug console ready.'),
    );

    expect(tester.view, contains('Debug Console'));
    expect(tester.view, contains('Debug console ready.'));
    expect(tester.view, contains('Press space to add logs.'));
  });
}
