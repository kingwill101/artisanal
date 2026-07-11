import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

import '../../example/code-editor/main.dart' as example;

void main() {
  test('code editor showcase renders editor and preview', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 44);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.CodeEditorDemoScreen());

    expect(tester.view, contains('CodeEditor Demo'));
    expect(tester.view, contains('Theme preset: Adaptive core'));
    expect(tester.view, contains('Theme next'));
    expect(tester.view, contains('Blur editor'));
    expect(tester.view, contains('main.dart'));
    expect(tester.view, contains('TextEditor'));
    expect(tester.view, contains('CodeEditor'));
    expect(tester.view, contains('ctrl+f'));
    expect(tester.view, contains('ctrl+g'));
    expect(tester.view, contains('ctrl+s'));
    expect(tester.view, contains('alt+shift+j'));
    expect(tester.view, contains('2~'));
    expect(tester.view, contains('5.'));

    tester.tap(tester.find.textLocation('Theme next'));

    expect(tester.view, contains('Theme preset: Dark core'));
  });

  test('code editor showcase keeps diagnostics live while editing', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.CodeEditorDemoScreen());

    for (final char in '// FIXME: promote this demo to real lint output'.split(
      '',
    )) {
      tester.sendKey(char);
    }

    expect(tester.view, contains('promote this demo to real lint output'));

    tester.sendMsg(
      runtime.KeyMsg(runtime.Key(runtime.KeyType.f8, shift: true)),
    );

    expect(tester.view, contains('error [demo/FIX001]'));
    expect(
      tester.view,
      contains('Resolve FIXME markers before treating this draft as ready.'),
    );
  });

  test('code editor showcase quits on ctrl+c after blur', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.CodeEditorDemoScreen());

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
