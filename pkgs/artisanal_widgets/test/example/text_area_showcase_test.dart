import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/text-area/main.dart' as example;

void main() {
  test('text area showcase renders the editor and preview', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TextAreaDemoScreen());

    expect(tester.view, contains('TextArea Demo'));
    expect(tester.view, contains('Line one'));
    expect(tester.view, contains('Line two'));
    expect(tester.view, contains('Preview'));
  });

  test('text area showcase quits on ctrl+c after blur', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TextAreaDemoScreen());

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
