import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/markdown-editor/main.dart' as example;

void main() {
  test('markdown editor showcase renders editor and preview', () async {
    final tester = WidgetTester(screenWidth: 104, screenHeight: 52);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.MarkdownEditorDemo());

    expect(tester.view, contains('MarkdownEditor Demo'));
    expect(tester.view, contains('Blur editor'));
    expect(tester.view, contains('CHANGELOG.md'));
    expect(tester.view, contains('Shipping Notes'));
    expect(tester.view, contains('Preview · markdown'));
    expect(tester.view, contains('ctrl+f'));
    expect(tester.view, contains('ctrl+g'));
    expect(tester.view, contains('ctrl+s'));
  });

  test('markdown editor showcase quits on ctrl+c after blur', () async {
    final tester = WidgetTester(screenWidth: 104, screenHeight: 52);
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
