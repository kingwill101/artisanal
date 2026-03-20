import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/testing.dart';
import 'package:test/test.dart';

import '../../example/markdown-editor/main.dart' as example;

void main() {
  test('markdown editor showcase renders editor and preview', () async {
    final tester = WidgetTester(screenWidth: 104, screenHeight: 60);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.MarkdownEditorDemo());

    expect(tester.view, contains('MarkdownEditor Demo'));
    expect(tester.view, contains('Theme preset: Adaptive core'));
    expect(tester.view, contains('Theme next'));
    expect(tester.view, contains('Blur editor'));
    expect(tester.view, contains('CHANGELOG.md'));
    expect(tester.view, contains('Shipping Notes'));
    expect(tester.view, contains('Preview · markdown'));
    expect(tester.view, contains('ctrl+f'));
    expect(tester.view, contains('ctrl+g'));
    expect(tester.view, contains('ctrl+s'));
    expect(tester.view, contains('f8'));
    expect(tester.view, contains('shift+f8'));

    tester.tap(tester.find.textLocation('Theme next'));

    expect(tester.view, contains('Theme preset: Dark core'));
  });

  test(
    'markdown editor showcase keeps diagnostics live while editing',
    () async {
      final tester = WidgetTester(screenWidth: 104, screenHeight: 60);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(example.MarkdownEditorDemo());

      tester.sendSpecialKey(runtime.KeyType.f8);

      expect(tester.view, contains('warning [demo/TODO001]'));
      expect(tester.view, contains('Address TODO markers before shipping'));

      tester.sendMsg(runtime.KeyMsg(runtime.Key(runtime.KeyType.enter)));
      for (final char in 'NOTE: review markdown diagnostics'.split('')) {
        tester.sendKey(char);
      }

      expect(tester.view, contains('review markdown diagnostics'));

      tester.sendMsg(
        runtime.KeyMsg(runtime.Key(runtime.KeyType.f8, shift: true)),
      );

      expect(tester.view, contains('info [demo/NOTE001]'));
      expect(
        tester.view,
        contains('Review NOTE blocks for follow-up context.'),
      );
    },
  );

  test('markdown editor showcase quits on ctrl+c after blur', () async {
    final tester = WidgetTester(screenWidth: 104, screenHeight: 60);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.MarkdownEditorDemo());

    expect(tester.program!.isRunning, isTrue);
    tester.tap(tester.find.textLocation('Blur editor'));
    tester.sendMsg(
      runtime.KeyMsg(
        runtime.Key(runtime.KeyType.runes, runes: const [0x03], ctrl: true),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(tester.program!.isRunning, isFalse);
  });
}
