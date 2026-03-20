import 'package:artisanal/testing.dart';
import 'package:artisanal/selection.dart' as s;
import 'package:test/test.dart';

import '../../example/selection/main.dart' as example;

void main() {
  test(
    'selection showcase drags across mixed components into one buffer',
    () async {
      final tester = WidgetTester(screenWidth: 110, screenHeight: 90);
      final controller = s.SelectionController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(controller: controller),
      );

      expect(tester.view, contains('Selection Across View Demo'));
      expect(tester.view, contains('Selection snapshot (0 chars)'));

      final start = tester.locateText('Cross-component selection document')!;
      final plain = tester.locateText('Plain text section')!;
      final rich = tester.locateText('Rich text section')!;
      final markdown = tester.locateText('Markdown section')!;
      final view = tester.locateText('VIEW :: Raw View() content joins the')!;
      final editor = tester.locateText('Editor-backed preview')!;
      final footer = tester.locateText(
        'Footer: this line proves the selection can span the full document.',
      )!;

      tester.mouseDown(start.x, start.y);
      tester.mouseMove(plain.x, plain.y);
      tester.mouseMove(rich.x, rich.y);
      tester.mouseMove(markdown.x, markdown.y);
      tester.mouseMove(view.x + 20, view.y);
      tester.mouseMove(editor.x + 10, editor.y);
      tester.mouseMove(footer.x + 20, footer.y);
      tester.mouseUp(footer.x + 20, footer.y);

      final selected = controller.getSelectedRegisteredText();
      expect(selected, contains('Cross-component selection document'));
      expect(selected, contains('Plain text section'));
      expect(selected, contains('Rich text section'));
      expect(selected, contains('Markdown section'));
      expect(selected, contains('Shared markdown'));
      expect(selected, contains('View-backed section'));
      expect(selected, contains('VIEW :: Raw View() content joins the'));
      expect(selected, contains('Editor-backed preview'));
      expect(selected, contains('Footer: this line pr'));
    },
  );

  test(
    'selection showcase triple click selects an entire shared line',
    () async {
      final tester = WidgetTester(screenWidth: 110, screenHeight: 90);
      final controller = s.SelectionController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(controller: controller),
      );

      final line = tester.locateText('Cross-component selection document')!;

      for (var i = 0; i < 3; i++) {
        tester.mouseDown(line.x + 2, line.y);
        tester.mouseUp(line.x + 2, line.y);
      }

      expect(
        controller.getSelectedRegisteredText(),
        equals('Cross-component selection document'),
      );
    },
  );

  test('selection showcase selects editor-backed preview text', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 90);
    final controller = s.SelectionController();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.SelectionShowcase(controller: controller));

    final line = tester.locateText('Editor-backed preview')!;

    tester.mouseDown(line.x, line.y);
    tester.mouseMove(line.x + 13, line.y);
    tester.mouseUp(line.x + 13, line.y);

    expect(controller.getSelectedRegisteredText(), contains('Editor-backed'));
  });
}
