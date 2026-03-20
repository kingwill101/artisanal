import 'package:artisanal/testing.dart';
import 'package:artisanal/selection.dart' as s;
import 'package:test/test.dart';

import '../../example/selection/main.dart' as example;

void main() {
  test(
    'selection showcase drags across mixed components into one buffer',
    () async {
      final tester = WidgetTester(screenWidth: 110, screenHeight: 50);
      final controller = s.SelectionController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(controller: controller),
      );

      expect(tester.view, contains('Selection Across View Demo'));
      expect(tester.view, contains('Selection snapshot (0 chars)'));

      final start = tester.locateText('Cross-component selection document')!;
      final end = tester.locateText(
        '- Ctrl+C copies the shared selection buffer.',
      )!;

      tester.mouseDown(start.x, start.y);
      tester.mouseMove(end.x + 40, end.y);
      tester.mouseUp(end.x + 40, end.y);

      final selected = controller.getSelectedRegisteredText();
      expect(selected, contains('Cross-component selection document'));
      expect(selected, contains('Plain text section'));
      expect(selected, contains('Rich text section'));
      expect(selected, contains('Markdown section'));
      expect(selected, contains('Shared markdown'));
      expect(selected, contains('View-backed section'));
      expect(selected, contains('VIEW :: Raw View() content joins the sam'));
    },
  );

  test(
    'selection showcase triple click selects an entire shared line',
    () async {
      final tester = WidgetTester(screenWidth: 110, screenHeight: 50);
      final controller = s.SelectionController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(controller: controller),
      );

      final line = tester.locateText('View-backed section')!;

      for (var i = 0; i < 3; i++) {
        tester.mouseDown(line.x + 2, line.y);
        tester.mouseUp(line.x + 2, line.y);
      }

      expect(
        controller.getSelectedRegisteredText(),
        equals('View-backed section'),
      );
    },
  );
}
