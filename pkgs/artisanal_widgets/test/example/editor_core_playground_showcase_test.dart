import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/testing.dart';
import 'package:test/test.dart';

import '../../example/editor-core-playground/main.dart' as example;

void main() {
  test(
    'editor core playground renders shared editor surfaces and overlays',
    () async {
      final tester = WidgetTester(screenWidth: 140, screenHeight: 42);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(example.EditorCorePlaygroundScreen());

      expect(tester.view, contains('Editor Core Playground'));
      expect(tester.view, contains('Overlay Controls'));
      expect(tester.view, contains('Raw TextArea'));
      expect(tester.view, contains('TextEditor'));
      expect(tester.view, contains('CodeEditor'));
      expect(tester.view, contains('Theme preset: Adaptive core'));
      expect(tester.view, contains('Search matches: raw 2'));
      expect(tester.view, contains('notes 1'));
      expect(tester.view, contains('code 1'));
      expect(tester.view, contains('Diagnostics: raw 4'));
      expect(tester.view, contains('review lines 2'));
      expect(tester.view, contains('3~'));

      tester.tap(tester.find.textLocation('Theme next'));

      expect(tester.view, contains('Switched playground theme to Dark core.'));
      expect(tester.view, contains('Theme preset: Dark core'));

      tester.tap(tester.find.textLocation('Focus code'));
      tester.tap(tester.find.textLocation('Diag next'));

      expect(tester.view, contains('Selected next diagnostic in CodeEditor.'));
      expect(
        tester.view,
        contains('Focused diagnostic: warning [playground/TODO001] L3:C6'),
      );
      expect(
        tester.view,
        contains('Address TODO markers before shipping this sample.'),
      );

      tester.tap(tester.find.textLocation('Search on'));

      expect(tester.view, contains('Disabled playground search overlays.'));
      expect(tester.view, contains('Search matches: raw 0'));
      expect(tester.view, contains('notes 0'));
      expect(tester.view, contains('code 0'));
    },
  );

  test('editor core playground quits on ctrl+c after blur', () async {
    final tester = WidgetTester(screenWidth: 140, screenHeight: 42);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.EditorCorePlaygroundScreen());

    expect(tester.program!.isRunning, isTrue);
    tester.tap(tester.find.textLocation('Blur'));
    tester.sendMsg(
      runtime.KeyMsg(
        runtime.Key(runtime.KeyType.runes, runes: const [0x03], ctrl: true),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(tester.program!.isRunning, isFalse);
  });
}
