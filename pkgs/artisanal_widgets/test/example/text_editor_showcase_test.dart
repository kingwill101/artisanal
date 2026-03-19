import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/testing.dart';
import 'package:test/test.dart';

import '../../example/text-editor/main.dart' as example;

void main() {
  test('text editor showcase renders editor chrome and content', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TextEditorDemoScreen());

    expect(tester.view, contains('TextEditor Demo'));
    expect(tester.view, contains('Roadmap.md'));
    expect(tester.view, contains('Ship TextEditor component'));
    expect(tester.view, contains('saved'));
    expect(tester.view, contains('ctrl+f'));
    expect(tester.view, contains('ctrl+g'));
    expect(tester.view, contains('ctrl+s'));
    expect(tester.view, contains('alt+shift+j'));
  });

  test('text editor showcase quits on ctrl+c after blur', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TextEditorDemoScreen());

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
