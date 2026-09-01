import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/text-editor/main.dart' as example;

void main() {
  test('text editor showcase renders editor chrome and content', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 32);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TextEditorDemoScreen());

    expect(tester.view, contains('TextEditor Demo'));
    expect(tester.view, contains('Theme preset: Adaptive core'));
    expect(tester.view, contains('Theme next'));
    expect(tester.view, contains('Roadmap.md'));
    expect(tester.view, contains('Ship TextEditor component'));
    expect(tester.view, contains('saved'));
    expect(tester.view, contains('ctrl+f'));
    expect(tester.view, contains('ctrl+g'));
    expect(tester.view, contains('ctrl+s'));
    expect(tester.view, contains('2~'));
    expect(tester.view, contains('3!'));

    tester.tap(tester.find.textLocation('Theme next'));

    expect(tester.view, contains('Theme preset: Dark core'));
  });

  test('text editor showcase keeps diagnostics live while editing', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 32);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TextEditorDemoScreen());

    tester.sendMsg(runtime.KeyMsg(runtime.Key(runtime.KeyType.enter)));
    for (final char in 'NOTE: capture live diagnostics'.split('')) {
      tester.sendKey(char);
    }

    expect(tester.view, contains('capture live diagnostics'));
    expect(tester.view, contains('4i'));

    tester.sendMsg(
      runtime.KeyMsg(runtime.Key(runtime.KeyType.f8, shift: true)),
    );

    expect(tester.view, contains('info [demo/NOTE001] L4:C1'));
    expect(tester.view, contains('Review NOTE blocks for follow-up context.'));
  });

  test('text editor showcase quits on ctrl+c after blur', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 32);
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
