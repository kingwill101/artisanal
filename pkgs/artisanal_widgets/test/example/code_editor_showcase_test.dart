import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/code-editor/main.dart' as example;

void main() {
  test('code editor showcase renders editor and preview', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.CodeEditorDemoScreen());

    expect(tester.view, contains('CodeEditor Demo'));
    expect(tester.view, contains('Blur editor'));
    expect(tester.view, contains('main.dart'));
    expect(tester.view, contains('TextEditor'));
    expect(tester.view, contains('CodeEditor'));
    expect(tester.view, contains('ctrl+f'));
    expect(tester.view, contains('ctrl+g'));
    expect(tester.view, contains('ctrl+s'));
    expect(tester.view, contains('alt+shift+j'));
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
