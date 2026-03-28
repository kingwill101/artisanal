import 'package:artisanal/testing.dart';
import 'package:artisanal/style.dart' show Style;
import 'package:test/test.dart';

import '../../example/overlay/main.dart' as example;

void main() {
  test('overlay demo renders stacked entries visibly', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.OverlayDemo());

    tester.sendKey('a');
    tester.sendKey('a');

    final view = Style.stripAnsi(tester.view);
    expect(view, contains('Overlay Widget Demo'));
    expect(view, contains('Overlay #0'));
    expect(view, contains('Overlay #1'));

    final first = tester.locateText('Overlay #0');
    final second = tester.locateText('Overlay #1');
    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(second!.x, equals(first!.x));
    expect(second.y, greaterThan(first.y));
  });
}
