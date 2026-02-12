import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/widgets/prompt_input.dart';

void main() {
  test('opencode prompt click does not jump cursor to end', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final ctrl = TextFieldController();
    await tester.pumpWidget(
      Container(
        width: 120,
        height: 12,
        child: PromptInput(controller: ctrl, showPlaceholder: false),
      ),
    );

    for (final c in 'hello world hello world hello world'.split('')) {
      tester.sendKey(c);
    }
    final len = ctrl.text.length;
    expect(ctrl.model.position, equals(len));

    tester.sendSpecialKey(KeyType.home);
    expect(ctrl.model.position, equals(0));

    final pos = tester.locateText('hello');
    expect(pos, isNotNull);

    tester.tapAt(pos!.x + 4, pos.y);

    expect(ctrl.model.position, greaterThan(0));
    expect(ctrl.model.position, lessThan(len));
  });

  test(
    'opencode prompt click in empty right area moves cursor to end',
    () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 120,
          height: 12,
          child: PromptInput(controller: ctrl, showPlaceholder: false),
        ),
      );

      for (final c in 'hello world hello world hello world'.split('')) {
        tester.sendKey(c);
      }

      tester.sendSpecialKey(KeyType.home);
      expect(ctrl.model.position, equals(0));

      final textPos = tester.locateText('hello');
      expect(textPos, isNotNull);

      tester.tapAt(textPos!.x + 70, textPos.y);

      expect(ctrl.model.position, equals(ctrl.text.length));
    },
  );
}
