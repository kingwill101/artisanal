import 'package:artisanal/testing.dart';
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:test/test.dart';

import '../../example/popup_menu_button/main.dart' as example;

void main() {
  test('popup menu button showcase updates selection status after hover + enter', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.PopupMenuButtonShowcase());

    tester.tap(tester.find.textLocation('Action: none'));
    final save = tester.locateText('Save');
    expect(save, isNotNull);

    tester.mouseMove(save!.x, save.y);
    tester.sendSpecialKey(KeyType.enter);

    expect(tester.find.text('Last action: save'), isTrue);
    expect(tester.find.text('Status: selected: save'), isTrue);
  });
}
