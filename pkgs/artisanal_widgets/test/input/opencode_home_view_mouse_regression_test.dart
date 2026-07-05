import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/models/chat_model.dart';
import '../../example/opencode/screens/home.dart';

void main() {
  test('home view click maps to expected character index', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final ctrl = TextFieldController();
    final model = ChatModel(route: AppRoute.home);

    await tester.pumpWidget(
      Container(
        width: 190,
        height: 40,
        child: HomeView(model: model, promptController: ctrl),
      ),
    );

    const text = 'This is the text i am testing';
    for (final c in text.split('')) {
      tester.sendKey(c);
    }

    tester.sendSpecialKey(KeyType.home);
    expect(ctrl.model.position, equals(0));

    final pos = tester.locateText(text);
    expect(pos, isNotNull);

    // Click on the first 't' in "text" (index 12).
    final clickPos = pos!;
    tester.tapAt(clickPos.x + 12, clickPos.y);

    expect(ctrl.model.position, equals(12));
  });

  test('home view click on first character maps to index 0', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final ctrl = TextFieldController();
    final model = ChatModel(route: AppRoute.home);

    await tester.pumpWidget(
      Container(
        width: 190,
        height: 40,
        child: HomeView(model: model, promptController: ctrl),
      ),
    );

    const text = 'This is the text i am testing';
    for (final c in text.split('')) {
      tester.sendKey(c);
    }

    tester.sendSpecialKey(KeyType.home);
    final pos = tester.locateText(text);
    expect(pos, isNotNull);

    final clickPos = pos!;
    tester.tapAt(clickPos.x, clickPos.y);

    expect(ctrl.model.position, equals(0));
  });

  test('home view click on rendered text places cursor by mouse', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final ctrl = TextFieldController();
    final model = ChatModel(route: AppRoute.home);

    await tester.pumpWidget(
      Container(
        width: 190,
        height: 40,
        child: HomeView(model: model, promptController: ctrl),
      ),
    );

    for (final c in 'hello world'.split('')) {
      tester.sendKey(c);
    }
    final len = ctrl.text.length;
    expect(ctrl.model.position, equals(len));

    tester.sendSpecialKey(KeyType.home);
    expect(ctrl.model.position, equals(0));

    final pos = tester.locateText('hello world');
    expect(pos, isNotNull);
    final clickPos = pos!;

    tester.tapAt(clickPos.x + 4, clickPos.y);

    expect(ctrl.model.position, greaterThan(0));
    expect(ctrl.model.position, lessThan(len));
  });
}
