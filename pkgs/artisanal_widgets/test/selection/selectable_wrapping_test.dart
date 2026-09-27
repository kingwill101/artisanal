import 'package:artisanal_widgets/selection.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  const content =
      'START alpha bravo charlie delta echo foxtrot golf hotel '
      'india juliet kilo lima mike november END_MARKER';
  for (final kind in ['text', 'markdown', 'view']) {
    Widget selectable({int? maxWidth, bool softWrap = true}) => switch (kind) {
      'markdown' => SelectableMarkdownText(
        data: '**$content**',
        maxWidth: maxWidth,
        softWrap: softWrap,
      ),
      'view' => SelectableView(content, maxWidth: maxWidth, softWrap: softWrap),
      _ => SelectableText(content, maxWidth: maxWidth, softWrap: softWrap),
    };

    test('$kind inherits pane width and reflows on resize', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 30);
      addTearDown(tester.dispose);
      for (final width in [30, 60, 30]) {
        await tester.pumpWidget(
          SizedBox(width: width.toDouble(), child: selectable()),
        );
        expect(tester.viewContains('END_MARKER'), isTrue);
        expect(
          tester.locateText('END_MARKER')!.y,
          greaterThan(tester.locateText('START')!.y),
        );
      }
    });

    test('$kind clamps explicit width to the parent', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 30);
      addTearDown(tester.dispose);
      await tester.pumpWidget(
        SizedBox(width: 30, child: selectable(maxWidth: 80)),
      );
      expect(tester.viewContains('END_MARKER'), isTrue);
      await tester.pumpWidget(
        SizedBox(width: 60, child: selectable(maxWidth: 20)),
      );
      expect(tester.viewContains('END_MARKER'), isTrue);
      expect(tester.locateText('END_MARKER')!.y, greaterThan(3));
    });

    test('$kind preserves opt-out of wrapping', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 30);
      addTearDown(tester.dispose);
      await tester.pumpWidget(
        SizedBox(width: 30, child: selectable(softWrap: false)),
      );
      expect(tester.viewContains('START'), isTrue);
      expect(tester.viewContains('END_MARKER'), isFalse);
    });
  }
}
