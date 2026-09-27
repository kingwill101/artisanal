import 'package:artisanal_widgets/selection.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  for (final kind in ['text', 'markdown', 'rich', 'view', 'adapter']) {
    test('$kind reports changes and completion as plain text', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 8);
      addTearDown(tester.dispose);
      final controller = SelectionController();
      final changes = <String>[];
      final completed = <String>[];
      var notifications = 0;
      controller.addListener(() => notifications++);
      final widget = switch (kind) {
        'markdown' => SelectableMarkdownText(
          data: '**alpha** beta',
          controller: controller,
          onSelectionChanged: changes.add,
          onSelectionEnd: completed.add,
        ),
        'rich' => SelectableRichText(
          text: TextSpan(text: 'alpha beta'),
          controller: controller,
          onSelectionChanged: changes.add,
          onSelectionEnd: completed.add,
        ),
        'view' => SelectableView(
          'alpha beta',
          controller: controller,
          onSelectionChanged: changes.add,
          onSelectionEnd: completed.add,
        ),
        'adapter' => Text('alpha beta').selectable(
          controller: controller,
          onSelectionChanged: changes.add,
          onSelectionEnd: completed.add,
        ),
        _ => SelectableText(
          'alpha beta',
          controller: controller,
          onSelectionChanged: changes.add,
          onSelectionEnd: completed.add,
        ),
      };
      await tester.pumpWidget(widget);
      tester.mouseDown(0, 0);
      tester.mouseMove(5, 0);
      expect(completed, isEmpty);
      expect(changes, contains('alpha'));
      expect(notifications, greaterThan(0));
      tester.mouseUp(5, 0);
      expect(completed, ['alpha']);
      controller.clearSelection();
      expect(changes.last, '');
      controller.setSelection(start: (x: 0, y: 0), end: (x: 10, y: 0));
      expect(changes.last, 'alpha beta');
      expect(completed, ['alpha']);
      await tester.pumpWidget(Text('unmounted'));
      final count = changes.length;
      controller.clearSelection();
      expect(changes, hasLength(count));
    });
  }

  test('word and line selections finish once; empty clicks do not', () async {
    final tester = WidgetTester(screenWidth: 40, screenHeight: 8);
    addTearDown(tester.dispose);
    final completed = <String>[];
    await tester.pumpWidget(
      SelectableText('alpha beta', onSelectionEnd: completed.add),
    );
    tester.mouseDown(2, 0);
    tester.mouseUp(2, 0);
    expect(completed, isEmpty);
    tester.mouseDown(2, 0);
    tester.mouseUp(2, 0);
    expect(completed, ['alpha']);
    tester.mouseDown(2, 0);
    tester.mouseUp(2, 0);
    expect(completed, ['alpha', 'alpha beta']);
  });

  test(
    'area reports combined text once, even when the callback clears it',
    () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 8);
      addTearDown(tester.dispose);
      final controller = SelectionController();
      final completed = <String>[];
      final fragments = <String>[];
      await tester.pumpWidget(
        SelectionArea(
          controller: controller,
          onSelectionEnd: (text) {
            completed.add(text);
            controller.clearSelection();
          },
          child: Column(
            children: [
              SelectableText('alpha', onSelectionEnd: fragments.add),
              SelectableText('beta', onSelectionEnd: fragments.add),
            ],
          ),
        ),
      );
      tester.mouseDown(0, 0);
      tester.mouseMove(4, 1);
      tester.mouseUp(4, 1);
      expect(completed, ['alpha\nbeta']);
      expect(fragments, ['alpha', 'beta']);
      expect(controller.hasSelection, isFalse);
    },
  );

  test('rebinding a controller detaches callback listeners', () async {
    final tester = WidgetTester(screenWidth: 40, screenHeight: 8);
    addTearDown(tester.dispose);
    final first = SelectionController();
    final second = SelectionController();
    final changes = <String>[];
    for (final controller in [first, second]) {
      await tester.pumpWidget(
        SelectableText(
          'alpha beta',
          controller: controller,
          onSelectionChanged: changes.add,
        ),
      );
    }
    first.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
    expect(changes, isEmpty);
    second.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
    expect(changes, ['alpha']);
  });
}
