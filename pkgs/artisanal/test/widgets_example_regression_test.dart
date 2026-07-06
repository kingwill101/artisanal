import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

import '../example/tui/examples/widgets/main.dart' show AppWidget;

void main() {
  group('widgets example regressions', () {
    test('overlays panel tooltip appears on hover', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      tester.tap(tester.find.textLocation('Components'));
      tester.tap(tester.find.textLocation('Overlays'));

      expect(tester.find.text('Hover to preview tooltips'), isFalse);

      final hoverTarget = tester.locateText('Hover me');
      expect(hoverTarget, isNotNull);

      tester.mouseMove(hoverTarget!.x, hoverTarget.y);

      expect(tester.find.text('Hover to preview tooltips'), isTrue);
    });
  });
}
