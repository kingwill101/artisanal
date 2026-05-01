import 'package:artisanal/testing.dart';
import 'package:artisanal/selection.dart' as s;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/widgets.dart';
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
    'selection showcase double click selects the current word only',
    () async {
      final tester = WidgetTester(screenWidth: 110, screenHeight: 90);
      final controller = s.SelectionController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(controller: controller),
      );

      final line = tester.locateText('Cross-component selection document')!;
      final wordX = line.x + 'Cross-component '.length;

      for (var i = 0; i < 2; i++) {
        tester.mouseDown(wordX, line.y);
        tester.mouseUp(wordX, line.y);
      }

      expect(controller.getSelectedRegisteredText(), equals('selection'));
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

  test(
    'selection showcase reverse drags across mixed components into one buffer',
    () async {
      final tester = WidgetTester(screenWidth: 110, screenHeight: 90);
      final controller = s.SelectionController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(controller: controller),
      );

      final start = tester.locateText(
        'Footer: this line proves the selection can span the full document.',
      )!;
      final editor = tester.locateText('Editor-backed preview')!;
      final view = tester.locateText('VIEW :: Raw View() content joins the')!;
      final markdown = tester.locateText('Markdown section')!;
      final rich = tester.locateText('Rich text section')!;
      final plain = tester.locateText('Plain text section')!;
      final end = tester.locateText('Cross-component selection document')!;

      tester.mouseDown(start.x + 20, start.y);
      tester.mouseMove(editor.x + 10, editor.y);
      tester.mouseMove(view.x + 20, view.y);
      tester.mouseMove(markdown.x, markdown.y);
      tester.mouseMove(rich.x, rich.y);
      tester.mouseMove(plain.x, plain.y);
      tester.mouseMove(end.x, end.y);
      tester.mouseUp(end.x, end.y);

      final selected = controller.getSelectedRegisteredText();
      expect(selected, contains('Footer: this line pr'));
      expect(selected, contains('Editor-backed preview'));
      expect(selected, contains('VIEW :: Raw View() content joins the'));
      expect(selected, contains('Markdown section'));
      expect(selected, contains('Rich text section'));
      expect(selected, contains('Plain text section'));
      expect(selected, contains('Cross-component selection document'));
    },
  );

  test(
    'selection showcase auto-scrolls while dragging toward the footer',
    () async {
      final tester = WidgetTester(screenWidth: 90, screenHeight: 24);
      final controller = s.SelectionController();
      final scrollController = WidgetScrollController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(
          controller: controller,
          scrollController: scrollController,
        ),
      );

      final start = tester.locateText('Cross-component selection document')!;
      final bottomEdgeY = 22;

      tester.mouseDown(start.x, start.y);
      for (var i = 0; i < 96; i++) {
        tester.mouseMove(start.x + 10, bottomEdgeY);
      }
      tester.mouseUp(start.x + 10, bottomEdgeY);

      expect(scrollController.offset, greaterThan(0));
      final selected = controller.getSelectedRegisteredText();
      expect(selected, contains('Cross-component selection document'));
      expect(selected, contains('Editor-backed preview'));
      expect(selected, contains('Footer: this line pr'));
    },
  );

  test(
    'selection showcase auto-scrolls upward while dragging toward the header',
    () async {
      final tester = WidgetTester(screenWidth: 90, screenHeight: 24);
      final controller = s.SelectionController();
      final scrollController = WidgetScrollController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(
          controller: controller,
          scrollController: scrollController,
        ),
      );

      final initialOffset = scrollController.maxOffset;
      expect(initialOffset, greaterThan(0));
      scrollController.jumpTo(initialOffset);
      tester.sendMsg(const tui.RepaintMsg());

      final footer = tester.locateText(
        'Footer: this line proves the selection can span the full document.',
      )!;
      final topEdgeY = 1;

      tester.mouseDown(footer.x + 20, footer.y);
      for (var i = 0; i < 96; i++) {
        tester.mouseMove(footer.x + 10, topEdgeY);
      }
      tester.mouseUp(footer.x + 10, topEdgeY);

      expect(scrollController.offset, lessThan(initialOffset));
      final selected = controller.getSelectedRegisteredText();
      expect(selected, contains('Footer: this line pr'));
      expect(selected, contains('Cross-component selection document'));
    },
  );

  test(
    'selection showcase keeps selection active while using the mouse wheel',
    () async {
      final tester = WidgetTester(screenWidth: 90, screenHeight: 24);
      final controller = s.SelectionController();
      final scrollController = WidgetScrollController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(
          controller: controller,
          scrollController: scrollController,
        ),
      );

      final start = tester.locateText('Cross-component selection document')!;

      tester.mouseDown(start.x, start.y);
      tester.mouseMove(start.x + 10, start.y);
      for (var i = 0; i < 4; i++) {
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.press,
            button: tui.MouseButton.wheelDown,
            x: start.x + 10,
            y: start.y,
          ),
        );
      }
      tester.mouseMove(start.x + 10, 22);
      tester.mouseUp(start.x + 10, 22);

      expect(scrollController.offset, greaterThan(0));
      final selected = controller.getSelectedRegisteredText();
      expect(selected, contains('Cross-component selection document'));
      expect(selected, isNotEmpty);
    },
  );

  test(
    'selection showcase can start dragging from beside the text row',
    () async {
      final tester = WidgetTester(screenWidth: 110, screenHeight: 90);
      final controller = s.SelectionController();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        example.SelectionShowcase(controller: controller),
      );

      final plain = tester.locateText('Plain text section')!;

      tester.mouseDown(plain.x + 24, plain.y);
      tester.mouseMove(plain.x + 10, plain.y);
      tester.mouseUp(plain.x + 10, plain.y);

      expect(controller.getSelectedRegisteredText(), contains('section'));
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
