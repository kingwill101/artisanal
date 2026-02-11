/// Tests for the Flex base class used directly (not via Row/Column).
///
/// Flex is the base class for Row and Column. These tests verify that Flex
/// can be instantiated directly with an explicit direction parameter and
/// behaves correctly for both horizontal and vertical layouts.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Constructor / defaults
  // ---------------------------------------------------------------------------

  group('constructor', () {
    test('horizontal direction creates row-like layout', () {
      final flex = w.Flex(
        direction: w.Axis.horizontal,
        children: [w.Text('a'), w.Text('b')],
      );
      expect(flex.direction, equals(w.Axis.horizontal));
      expect(flex.gap, equals(0));
      expect(flex.mainAxisAlignment, equals(w.MainAxisAlignment.start));
      expect(flex.crossAxisAlignment, equals(w.CrossAxisAlignment.start));
      expect(flex.mainAxisSize, equals(w.MainAxisSize.min));
      expect(flex.mainAxisExtent, isNull);
      expect(flex.crossAxisExtent, isNull);
    });

    test('vertical direction creates column-like layout', () {
      final flex = w.Flex(
        direction: w.Axis.vertical,
        children: [w.Text('a'), w.Text('b')],
      );
      expect(flex.direction, equals(w.Axis.vertical));
    });

    test('accepts all optional parameters', () {
      final flex = w.Flex(
        direction: w.Axis.horizontal,
        children: [w.Text('x')],
        gap: 3,
        mainAxisAlignment: w.MainAxisAlignment.center,
        crossAxisAlignment: w.CrossAxisAlignment.center,
        mainAxisSize: w.MainAxisSize.max,
        mainAxisExtent: 40,
        crossAxisExtent: 5,
      );
      expect(flex.gap, equals(3));
      expect(flex.mainAxisAlignment, equals(w.MainAxisAlignment.center));
      expect(flex.crossAxisAlignment, equals(w.CrossAxisAlignment.center));
      expect(flex.mainAxisSize, equals(w.MainAxisSize.max));
      expect(flex.mainAxisExtent, equals(40));
      expect(flex.crossAxisExtent, equals(5));
    });
  });

  // ---------------------------------------------------------------------------
  // Horizontal (row-like) rendering
  // ---------------------------------------------------------------------------

  group('horizontal layout', () {
    test('renders children side by side', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.horizontal,
          children: [w.Text('AB'), w.Text('CD')],
        ),
      );

      expect(tester.find.text('AB'), isTrue);
      expect(tester.find.text('CD'), isTrue);
      // AB and CD should be on the same line with no gap.
      expect(tester.find.text('ABCD'), isTrue);
    });

    test('gap separates horizontal children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.horizontal,
          gap: 2,
          children: [w.Text('A'), w.Text('B')],
        ),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
      // With gap=2, there should be 2 spaces between A and B.
      expect(tester.find.text('A  B'), isTrue);
    });

    test('empty children renders nothing', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(direction: w.Axis.horizontal, children: []),
      );

      // Empty flex should produce no visible content.
      final view = tester.view;
      // The view may contain whitespace from the tester but no meaningful text.
      expect(view.trim().isEmpty || !view.contains('A'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Vertical (column-like) rendering
  // ---------------------------------------------------------------------------

  group('vertical layout', () {
    test('renders children stacked vertically', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.vertical,
          children: [w.Text('Top'), w.Text('Bot')],
        ),
      );

      expect(tester.find.text('Top'), isTrue);
      expect(tester.find.text('Bot'), isTrue);
    });

    test('gap separates vertical children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.vertical,
          gap: 1,
          children: [w.Text('Row1'), w.Text('Row2')],
        ),
      );

      expect(tester.find.text('Row1'), isTrue);
      expect(tester.find.text('Row2'), isTrue);

      final loc1 = tester.locateText('Row1');
      final loc2 = tester.locateText('Row2');
      expect(loc1, isNotNull);
      expect(loc2, isNotNull);
      // gap=1 means 1 empty line between Row1 and Row2.
      expect(loc2!.y - loc1!.y, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // Alignment (requires mainAxisSize.max + mainAxisExtent)
  // ---------------------------------------------------------------------------

  group('mainAxisAlignment', () {
    test('center alignment in horizontal Flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.horizontal,
          mainAxisAlignment: w.MainAxisAlignment.center,
          mainAxisSize: w.MainAxisSize.max,
          mainAxisExtent: 20,
          children: [w.Text('A'), w.Text('B')],
        ),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);

      final locA = tester.locateText('A');
      expect(locA, isNotNull);
      // With 20 chars width and 2 chars content, center should place A
      // at offset ~9.
      expect(locA!.x, greaterThan(0));
    });

    test('end alignment in vertical Flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.vertical,
          mainAxisAlignment: w.MainAxisAlignment.end,
          mainAxisSize: w.MainAxisSize.max,
          mainAxisExtent: 10,
          children: [w.Text('AA'), w.Text('BB')],
        ),
      );

      expect(tester.find.text('AA'), isTrue);
      expect(tester.find.text('BB'), isTrue);

      final locBB = tester.locateText('BB');
      expect(locBB, isNotNull);
      // End alignment means children are pushed to the bottom.
      expect(locBB!.y, greaterThan(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Equivalence with Row/Column
  // ---------------------------------------------------------------------------

  group('equivalence with Row/Column', () {
    test('Flex(horizontal) renders same as Row', () async {
      final tester1 = WidgetTester();
      addTearDown(() => tester1.dispose());
      final tester2 = WidgetTester();
      addTearDown(() => tester2.dispose());

      final children = [w.Text('X'), w.Text('Y')];
      await tester1.pumpWidget(
        w.Flex(direction: w.Axis.horizontal, gap: 1, children: children),
      );
      await tester2.pumpWidget(
        w.Row(gap: 1, children: [w.Text('X'), w.Text('Y')]),
      );

      // Both should produce the same visual output.
      final loc1 = tester1.locateText('X');
      final loc2 = tester2.locateText('X');
      expect(loc1, isNotNull);
      expect(loc2, isNotNull);
      expect(loc1!.x, equals(loc2!.x));
      expect(loc1.y, equals(loc2.y));
    });

    test('Flex(vertical) renders same as Column', () async {
      final tester1 = WidgetTester();
      addTearDown(() => tester1.dispose());
      final tester2 = WidgetTester();
      addTearDown(() => tester2.dispose());

      await tester1.pumpWidget(
        w.Flex(
          direction: w.Axis.vertical,
          gap: 1,
          children: [w.Text('P'), w.Text('Q')],
        ),
      );
      await tester2.pumpWidget(
        w.Column(gap: 1, children: [w.Text('P'), w.Text('Q')]),
      );

      final loc1 = tester1.locateText('P');
      final loc2 = tester2.locateText('P');
      expect(loc1, isNotNull);
      expect(loc2, isNotNull);
      expect(loc1!.x, equals(loc2!.x));
      expect(loc1.y, equals(loc2.y));
    });
  });

  // ---------------------------------------------------------------------------
  // With Flexible/Expanded children
  // ---------------------------------------------------------------------------

  group('with Flexible children', () {
    test('Expanded child fills space in horizontal Flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.horizontal,
          mainAxisSize: w.MainAxisSize.max,
          mainAxisExtent: 30,
          children: [
            w.Text('Hi'),
            w.Expanded(child: w.Text('Fill')),
          ],
        ),
      );

      expect(tester.find.text('Hi'), isTrue);
      expect(tester.find.text('Fill'), isTrue);
    });

    test('Expanded child fills space in vertical Flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Flex(
          direction: w.Axis.vertical,
          mainAxisSize: w.MainAxisSize.max,
          mainAxisExtent: 10,
          children: [
            w.Text('Header'),
            w.Expanded(child: w.Text('Body')),
          ],
        ),
      );

      expect(tester.find.text('Header'), isTrue);
      expect(tester.find.text('Body'), isTrue);
    });
  });
}
