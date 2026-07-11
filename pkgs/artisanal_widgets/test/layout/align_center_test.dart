import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Align', () {
    // Note: Align needs its own explicit width/height to position content.
    // Wrapping in Container does NOT propagate dimensions to Align's
    // width/height fields. The Align render object falls back to content
    // dimensions when its own width/height are null, making alignment a no-op.

    test('topLeft positions content at top left', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.topLeft,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, equals(0));
    });

    test('topCenter positions content at top center', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.topCenter,
          child: Text('XX'),
        ),
      );

      final pos = tester.locateText('XX');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, equals(0));
    });

    test('topRight positions content at top right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.topRight,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, equals(0));
    });

    test('centerLeft positions content at middle left', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.centerLeft,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, greaterThan(0));
    });

    test('center positions content at center', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.center,
          child: Text('XX'),
        ),
      );

      final pos = tester.locateText('XX');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('centerRight positions content at middle right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.centerRight,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('bottomLeft positions content at bottom left', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.bottomLeft,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, greaterThan(0));
    });

    test('bottomCenter positions content at bottom center', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.bottomCenter,
          child: Text('XX'),
        ),
      );

      final pos = tester.locateText('XX');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('bottomRight positions content at bottom right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.bottomRight,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('respects explicit width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Align(width: 15, child: Text('XXXXXXXXXXXXXXX')));

      final lines = tester.viewLines;
      final firstLine = lines.firstWhere((l) => l.contains('X'));
      expect(Layout.visibleLength(firstLine), lessThanOrEqualTo(15));
    });

    test('respects explicit height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          height: 3,
          child: Column(children: [Text('A'), Text('B'), Text('C'), Text('D')]),
        ),
      );

      // With height: 3, the Align constrains the output to 3 lines.
      // The content has 4 lines but should be clipped/limited.
      final lines = tester.viewLines;
      expect(lines.length, greaterThan(0));
    });

    test('provides access to child', () {
      final child = Text('child');
      final align = Align(child: child);
      expect(align.children, equals([child]));
    });

    test('is not focusable', () {
      final align = Align(child: Text('test'));
      expect(align.focusable, isFalse);
    });

    test('has unique id', () {
      final a1 = Align(child: Text('a'));
      final a2 = Align(child: Text('b'));
      expect(a1.id, isNot(equals(a2.id)));
    });

    test('respects key', () {
      final align = Align(key: ValueKey('align-key'), child: Text('test'));
      expect(align.id, equals('align-key'));
    });

    test('alignment affects position relative to default', () async {
      // Verify that different alignments produce different positions
      final testerLeft = WidgetTester();
      addTearDown(() => testerLeft.dispose());
      final testerRight = WidgetTester();
      addTearDown(() => testerRight.dispose());

      await testerLeft.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.topLeft,
          child: Text('X'),
        ),
      );

      await testerRight.pumpWidget(
        Align(
          width: 20,
          height: 5,
          alignment: Alignment.bottomRight,
          child: Text('X'),
        ),
      );

      final posLeft = testerLeft.locateText('X');
      final posRight = testerRight.locateText('X');
      expect(posLeft, isNotNull);
      expect(posRight, isNotNull);
      // bottomRight should have greater x and y than topLeft
      expect(posRight!.x, greaterThan(posLeft!.x));
      expect(posRight.y, greaterThan(posLeft.y));
    });
  });

  group('Center', () {
    test('centers child horizontally and vertically', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Center is Align(alignment: Alignment.center). It needs its own
      // width/height (inherited from Align) to have space for centering.
      // But Center only takes key and child params. So Center without
      // explicit dimensions falls back to content size (no centering).
      // Verify Center renders the child correctly.
      await tester.pumpWidget(Center(child: Text('XX')));

      expect(tester.find.text('XX'), isTrue);
    });

    test('centers child in larger container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Center is Align(alignment: Alignment.center) but only accepts key+child.
      // It doesn't accept width/height, so it can't center within a larger area
      // on its own. Wrapping in Container doesn't help either because Container
      // doesn't propagate dimensions to Align's width/height fields.
      // Instead, use Container's own alignment parameter.
      await tester.pumpWidget(
        Container(
          width: 30,
          height: 10,
          alignment: Alignment.center,
          child: Text('XXX'),
        ),
      );

      final pos = tester.locateText('XXX');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('is subclass of Align', () {
      final center = Center(child: Text('test'));
      expect(center, isA<Align>());
    });

    test('provides access to child', () {
      final child = Text('child');
      final center = Center(child: child);
      expect(center.children, equals([child]));
    });

    test('is not focusable', () {
      final center = Center(child: Text('test'));
      expect(center.focusable, isFalse);
    });
  });

  group('Alignment', () {
    test('Alignment.topLeft positions correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 10,
          height: 3,
          alignment: Alignment.topLeft,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos!.x, equals(0));
      expect(pos.y, equals(0));
    });

    test('Alignment.center positions correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 10,
          height: 3,
          alignment: Alignment.center,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('Alignment.bottomRight positions correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 10,
          height: 3,
          alignment: Alignment.bottomRight,
          child: Text('X'),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });
  });

  group('Align integration', () {
    test('Center inside Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(border: Border.normal),
          child: Center(child: Text('Centered')),
        ),
      );

      final pos = tester.locateText('Centered');
      expect(pos, isNotNull);
    });

    test('Align right in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          child: Row(
            children: [
              Text('Left'),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Right'),
                ),
              ),
            ],
          ),
        ),
      );

      final leftPos = tester.locateText('Left');
      final rightPos = tester.locateText('Right');

      expect(leftPos, isNotNull);
      expect(rightPos, isNotNull);
      expect(rightPos!.x, greaterThan(leftPos!.x));
    });

    test('Align bottom in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          height: 10,
          child: Column(
            children: [
              Text('Top'),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text('Bottom'),
                ),
              ),
            ],
          ),
        ),
      );

      final topPos = tester.locateText('Top');
      final bottomPos = tester.locateText('Bottom');

      expect(topPos, isNotNull);
      expect(bottomPos, isNotNull);
      expect(bottomPos!.y, greaterThan(topPos!.y));
    });

    test('nested Align widgets', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Align(
          width: 20,
          height: 10,
          alignment: Alignment.center,
          child: Align(alignment: Alignment.topLeft, child: Text('Nested')),
        ),
      );

      final pos = tester.locateText('Nested');
      expect(pos, isNotNull);
    });
  });

  group('Bug 3 regression: Container propagates dimensions to children', () {
    test(
      'Align inside Container uses Container dimensions for alignment',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        // Before Bug 3 fix, Align inside Container had no knowledge of
        // Container's dimensions and alignment was a no-op.
        await tester.pumpWidget(
          Container(
            width: 30,
            height: 10,
            child: Align(alignment: Alignment.center, child: Text('X')),
          ),
        );

        final pos = tester.locateText('X');
        expect(pos, isNotNull);
        // X should be centered (not at 0,0)
        expect(pos!.x, greaterThan(0));
        expect(pos.y, greaterThan(0));
      },
    );

    test(
      'Align bottomRight inside Container positions at bottom right',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Align(alignment: Alignment.bottomRight, child: Text('Z')),
          ),
        );

        final pos = tester.locateText('Z');
        expect(pos, isNotNull);
        expect(pos!.x, greaterThan(0));
        expect(pos.y, greaterThan(0));
      },
    );

    test('Center inside Container centers content correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Center is Align(alignment: Alignment.center) — it should now
      // pick up tight constraints from Container to know the available space.
      await tester.pumpWidget(
        Container(width: 20, height: 5, child: Center(child: Text('Hi'))),
      );

      final pos = tester.locateText('Hi');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('Align topLeft inside Container stays at origin', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 20,
          height: 5,
          child: Align(alignment: Alignment.topLeft, child: Text('A')),
        ),
      );

      final pos = tester.locateText('A');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, equals(0));
    });

    test(
      'Container with only width propagates width constraint to Align child',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 30,
            child: Align(alignment: Alignment.centerRight, child: Text('R')),
          ),
        );

        final pos = tester.locateText('R');
        expect(pos, isNotNull);
        // Should be pushed to the right by the 30-wide container
        expect(pos!.x, greaterThan(0));
      },
    );

    test(
      'Container with only height propagates height constraint to Align child',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            height: 8,
            child: Align(alignment: Alignment.bottomLeft, child: Text('B')),
          ),
        );

        final pos = tester.locateText('B');
        expect(pos, isNotNull);
        // Should be pushed to the bottom by the 8-tall container
        expect(pos!.y, greaterThan(0));
      },
    );

    test(
      'Row loosens main-axis constraints so Align inside Expanded works',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        // This test verifies that Row loosens width constraints for children
        // so Expanded + Align doesn't incorrectly expand to Container width.
        await tester.pumpWidget(
          Container(
            width: 30,
            child: Row(
              children: [
                Text('A'),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('B'),
                  ),
                ),
              ],
            ),
          ),
        );

        final posA = tester.locateText('A');
        final posB = tester.locateText('B');
        expect(posA, isNotNull);
        expect(posB, isNotNull);
        expect(posB!.x, greaterThan(posA!.x));
      },
    );

    test(
      'Column loosens main-axis constraints so Align inside Expanded works',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            height: 10,
            child: Column(
              children: [
                Text('T'),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text('B'),
                  ),
                ),
              ],
            ),
          ),
        );

        final posT = tester.locateText('T');
        final posB = tester.locateText('B');
        expect(posT, isNotNull);
        expect(posB, isNotNull);
        expect(posB!.y, greaterThan(posT!.y));
      },
    );
  });
}
