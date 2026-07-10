import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

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
  fail('Timed out waiting for debug console update');
}

void main() {
  test(
    'DebugConsoleController uses injected nowProvider for entry timestamps',
    () {
      var now = DateTime.utc(2026, 1, 1, 12, 34, 56);
      final controller = DebugConsoleController(nowProvider: () => now);

      controller.info('boot');
      now = now.add(const Duration(seconds: 1));
      controller.warn('warn');

      expect(controller.entries, hasLength(2));
      expect(
        controller.entries.first.timestamp,
        DateTime.utc(2026, 1, 1, 12, 34, 56),
      );
      expect(controller.entries.first.timestampLabel, equals('12:34:56'));
      expect(
        controller.entries.last.timestamp,
        DateTime.utc(2026, 1, 1, 12, 34, 57),
      );
      expect(controller.entries.last.timestampLabel, equals('12:34:57'));
    },
  );

  test('DebugConsole renders controller entries and updates live', () async {
    final controller = DebugConsoleController(maxEntries: 3);
    controller.info('boot');

    final tester = WidgetTester(screenWidth: 70, screenHeight: 16);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: DebugConsole(controller: controller, height: 4, showHelp: false),
      ),
    );

    expect(tester.view, contains('Debug Console'));
    expect(tester.view, contains('INFO'));
    expect(tester.view, contains('boot'));

    controller.warn('warn line');
    await _pumpUntil(tester, () => tester.view.contains('warn line'));
    expect(tester.view, contains('WARN'));
    expect(tester.view, contains('warn line'));

    controller.error('error line');
    controller.debug('debug line');
    await _pumpUntil(tester, () => tester.view.contains('debug line'));

    expect(tester.view, isNot(contains('boot')));
    expect(tester.view, contains('error line'));
    expect(tester.view, contains('debug line'));
  });

  test('DebugConsoleController.runZoned captures prints and errors', () async {
    final controller = DebugConsoleController();

    await expectLater(
      controller.runZoned(() async {
        print('hello console');
        throw StateError('boom');
      }),
      throwsA(isA<StateError>()),
    );

    final messages = controller.entries
        .map((entry) => entry.message)
        .join('\n');
    expect(messages, contains('hello console'));
    expect(messages, contains('Bad state: boom'));
  });
}
