import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Stack basics', () {
    test('renders single child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Stack(children: [Text('Hello')]));

      expect(tester.find.text('Hello'), isTrue);
    });

    test('renders multiple children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(width: 20, height: 5, children: [Text('A'), Text('B')]),
      );

      // Both children should be rendered (B overlaps A at topLeft by default)
      expect(tester.find.text('B'), isTrue);
    });

    test('empty stack renders empty', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Stack(children: []));
      expect(tester.view.trim(), isEmpty);
    });

    test('children are accessible', () {
      final a = Text('A');
      final b = Text('B');
      final stack = Stack(children: [a, b]);
      expect(stack.children, equals([a, b]));
    });
  });

  group('Stack with explicit size', () {
    test('width and height create a canvas of that size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Wrap in Container with alignment so the Stack receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Stack(width: 15, height: 4, children: [Text('X')]),
        ),
      );

      expect(tester.find.text('X'), isTrue);
      // Stack with height 4 — the text must land within the first 4 rows.
      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.y, lessThan(4));
    });

    test('stack without explicit size sizes to children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Stack(children: [Text('AB')]));

      expect(tester.find.text('AB'), isTrue);
    });
  });

  group('Stack alignment', () {
    test('default topLeft aligns child at origin', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(width: 20, height: 5, children: [Text('X')]),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, equals(0));
    });

    test('center alignment positions child in middle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          alignment: Alignment.center,
          children: [Text('X')],
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('bottomRight alignment positions child at bottom right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          alignment: Alignment.bottomRight,
          children: [Text('X')],
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, greaterThan(0));
    });

    test('topRight alignment positions at top right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          alignment: Alignment.topRight,
          children: [Text('X')],
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
      expect(pos.y, equals(0));
    });

    test('bottomLeft alignment positions at bottom left', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          alignment: Alignment.bottomLeft,
          children: [Text('X')],
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, greaterThan(0));
    });

    test('different alignments produce different positions', () async {
      final testerTL = WidgetTester();
      addTearDown(() => testerTL.dispose());
      final testerBR = WidgetTester();
      addTearDown(() => testerBR.dispose());

      await testerTL.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          alignment: Alignment.topLeft,
          children: [Text('X')],
        ),
      );

      await testerBR.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          alignment: Alignment.bottomRight,
          children: [Text('X')],
        ),
      );

      final posTL = testerTL.locateText('X');
      final posBR = testerBR.locateText('X');
      expect(posTL, isNotNull);
      expect(posBR, isNotNull);
      expect(posBR!.x, greaterThan(posTL!.x));
      expect(posBR.y, greaterThan(posTL.y));
    });
  });

  group('Stack with Positioned children', () {
    test('Positioned with left and top', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          children: [Positioned(left: 3, top: 2, child: Text('P'))],
        ),
      );

      final pos = tester.locateText('P');
      expect(pos, isNotNull);
      expect(pos!.x, equals(3));
      expect(pos.y, equals(2));
    });

    test('Positioned with left only', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          children: [Positioned(left: 5, child: Text('L'))],
        ),
      );

      final pos = tester.locateText('L');
      expect(pos, isNotNull);
      expect(pos!.x, equals(5));
    });

    test('Positioned with top only', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          children: [Positioned(top: 3, child: Text('T'))],
        ),
      );

      final pos = tester.locateText('T');
      expect(pos, isNotNull);
      expect(pos!.y, equals(3));
    });

    test('Positioned with right positions from right edge', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Wrap in Container with alignment so the Stack receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Stack(
            width: 20,
            height: 5,
            children: [Positioned(right: 0, child: Text('R'))],
          ),
        ),
      );

      final pos = tester.locateText('R');
      expect(pos, isNotNull);
      // right: 0 means x = 20 - 1 - 0 = 19
      expect(pos!.x, equals(19));
    });

    test('Positioned with bottom positions from bottom edge', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Wrap in Container with alignment so the Stack receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Stack(
            width: 20,
            height: 5,
            children: [Positioned(bottom: 0, child: Text('B'))],
          ),
        ),
      );

      final pos = tester.locateText('B');
      expect(pos, isNotNull);
      // bottom: 0 means y = 5 - 1 - 0 = 4
      expect(pos!.y, equals(4));
    });

    test('Positioned with right and bottom', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Wrap in Container with alignment so the Stack receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Stack(
            width: 20,
            height: 5,
            children: [Positioned(right: 1, bottom: 1, child: Text('C'))],
          ),
        ),
      );

      final pos = tester.locateText('C');
      expect(pos, isNotNull);
      // right: 1 means x = 20 - 1 - 1 = 18
      expect(pos!.x, equals(18));
      // bottom: 1 means y = 5 - 1 - 1 = 3
      expect(pos.y, equals(3));
    });

    test('Positioned at origin with left: 0 and top: 0', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          children: [Positioned(left: 0, top: 0, child: Text('O'))],
        ),
      );

      final pos = tester.locateText('O');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, equals(0));
    });

    test('multiple Positioned children at different locations', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          children: [
            Positioned(left: 0, top: 0, child: Text('A')),
            Positioned(left: 10, top: 3, child: Text('B')),
          ],
        ),
      );

      final posA = tester.locateText('A');
      final posB = tester.locateText('B');
      expect(posA, isNotNull);
      expect(posB, isNotNull);
      expect(posA!.x, equals(0));
      expect(posA.y, equals(0));
      expect(posB!.x, equals(10));
      expect(posB.y, equals(3));
    });
  });

  group('Positioned properties', () {
    test('children returns [child]', () {
      final child = Text('inner');
      final positioned = Positioned(child: child);
      expect(positioned.children, equals([child]));
    });

    test('respects key', () {
      final positioned = Positioned(key: ValueKey('pos-key'), child: Text('X'));
      expect(positioned.id, equals('pos-key'));
    });

    test('has unique id', () {
      final p1 = Positioned(child: Text('A'));
      final p2 = Positioned(child: Text('B'));
      expect(p1.id, isNot(equals(p2.id)));
    });

    test('stores position values', () {
      final positioned = Positioned(
        left: 1,
        right: 2,
        top: 3,
        bottom: 4,
        width: 5,
        height: 6,
        child: Text('X'),
      );
      expect(positioned.left, equals(1));
      expect(positioned.right, equals(2));
      expect(positioned.top, equals(3));
      expect(positioned.bottom, equals(4));
      expect(positioned.width, equals(5));
      expect(positioned.height, equals(6));
    });

    test('position values default to null', () {
      final positioned = Positioned(child: Text('X'));
      expect(positioned.left, isNull);
      expect(positioned.right, isNull);
      expect(positioned.top, isNull);
      expect(positioned.bottom, isNull);
      expect(positioned.width, isNull);
      expect(positioned.height, isNull);
    });

    test('view() delegates to child', () {
      final positioned = Positioned(child: Text('Hello'));
      final childView = Text('Hello').view();
      expect(positioned.view().toString(), equals(childView.toString()));
    });
  });

  group('Stack properties', () {
    test('respects key', () {
      final stack = Stack(key: ValueKey('stack-key'), children: []);
      expect(stack.id, equals('stack-key'));
    });

    test('has unique id', () {
      final s1 = Stack(children: []);
      final s2 = Stack(children: []);
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('is not focusable', () {
      final stack = Stack(children: []);
      expect(stack.focusable, isFalse);
    });

    test('stores alignment', () {
      final stack = Stack(alignment: Alignment.center, children: []);
      expect(stack.alignment.x, equals(Alignment.center.x));
      expect(stack.alignment.y, equals(Alignment.center.y));
    });

    test('stores fit', () {
      final stack = Stack(fit: StackFit.expand, children: []);
      expect(stack.fit, equals(StackFit.expand));
    });

    test('stores clipBehavior', () {
      final stack = Stack(clipBehavior: Overflow.visible, children: []);
      expect(stack.clipBehavior, equals(Overflow.visible));
    });

    test('stores width and height', () {
      final stack = Stack(width: 30, height: 10, children: []);
      expect(stack.width, equals(30));
      expect(stack.height, equals(10));
    });

    test('default values', () {
      final stack = Stack(children: []);
      expect(stack.alignment.x, equals(Alignment.topLeft.x));
      expect(stack.alignment.y, equals(Alignment.topLeft.y));
      expect(stack.fit, equals(StackFit.loose));
      expect(stack.clipBehavior, equals(Overflow.clip));
      expect(stack.width, isNull);
      expect(stack.height, isNull);
    });
  });

  group('Mixed Positioned and non-Positioned children', () {
    test(
      'non-Positioned child uses alignment, Positioned uses offsets',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Stack(
            width: 20,
            height: 5,
            alignment: Alignment.topLeft,
            children: [
              Text('A'),
              Positioned(left: 10, top: 2, child: Text('B')),
            ],
          ),
        );

        final posA = tester.locateText('A');
        final posB = tester.locateText('B');
        expect(posA, isNotNull);
        expect(posB, isNotNull);
        // Non-positioned 'A' uses topLeft alignment → (0, 0)
        expect(posA!.x, equals(0));
        expect(posA.y, equals(0));
        // Positioned 'B' uses explicit offsets → (10, 2)
        expect(posB!.x, equals(10));
        expect(posB.y, equals(2));
      },
    );

    test(
      'non-Positioned child with center alignment and Positioned child',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Stack(
            width: 20,
            height: 5,
            alignment: Alignment.center,
            children: [
              Text('M'),
              Positioned(left: 0, top: 0, child: Text('C')),
            ],
          ),
        );

        final posM = tester.locateText('M');
        final posC = tester.locateText('C');
        expect(posM, isNotNull);
        expect(posC, isNotNull);
        // Non-positioned 'M' uses center alignment → centered in 20x5
        expect(posM!.x, greaterThan(0));
        expect(posM.y, greaterThan(0));
        // Positioned 'C' at (0, 0)
        expect(posC!.x, equals(0));
        expect(posC.y, equals(0));
      },
    );

    test('later children overlap earlier children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Both at same position — last child wins
      await tester.pumpWidget(
        Stack(
          width: 20,
          height: 5,
          children: [
            Positioned(left: 0, top: 0, child: Text('X')),
            Positioned(left: 0, top: 0, child: Text('Y')),
          ],
        ),
      );

      // 'Y' should overlap 'X' — the view should show Y at (0, 0)
      final pos = tester.locateText('Y');
      expect(pos, isNotNull);
      expect(pos!.x, equals(0));
      expect(pos.y, equals(0));
    });

    test('positioned children do not grow a loose stack', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Text('Base'),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('Tall1'), Text('Tall2'), Text('Tall3')],
                    ),
                  ),
                ],
              ),
              Text('After'),
            ],
          ),
        ),
      );

      final after = tester.locateText('After');
      expect(after, isNotNull);
      expect(after!.y, equals(1));
    });
  });

  group('StackFit.expand', () {
    test(
      'children expand to fill stack when given bounded constraints',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 30,
            height: 10,
            child: Stack(fit: StackFit.expand, children: [Text('E')]),
          ),
        );

        expect(tester.find.text('E'), isTrue);
      },
    );

    test('expand with explicit stack size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 25,
          height: 8,
          fit: StackFit.expand,
          children: [Text('F')],
        ),
      );

      expect(tester.find.text('F'), isTrue);
    });
  });

  group('Stack integration', () {
    test('Stack inside Container with explicit stack size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Container does not propagate its dimensions to Stack's width/height
      // fields, so Stack needs its own explicit size to position children.
      await tester.pumpWidget(
        Container(
          width: 30,
          height: 10,
          child: Stack(
            width: 30,
            height: 10,
            children: [Positioned(left: 1, top: 1, child: Text('Inside'))],
          ),
        ),
      );

      expect(tester.find.text('Inside'), isTrue);
    });

    test('Stack inside Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('Before'),
            Stack(width: 10, height: 3, children: [Text('S')]),
          ],
        ),
      );

      expect(tester.find.text('Before'), isTrue);
      expect(tester.find.text('S'), isTrue);
    });

    test('Stack inside Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Top'),
            Stack(
              width: 10,
              height: 3,
              children: [Positioned(left: 2, top: 1, child: Text('S'))],
            ),
            Text('Bot'),
          ],
        ),
      );

      expect(tester.find.text('Top'), isTrue);
      expect(tester.find.text('S'), isTrue);
      expect(tester.find.text('Bot'), isTrue);
    });

    test('nested Stacks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 30,
          height: 10,
          children: [
            Positioned(
              left: 2,
              top: 1,
              child: Stack(
                width: 15,
                height: 5,
                children: [Positioned(left: 1, top: 1, child: Text('N'))],
              ),
            ),
          ],
        ),
      );

      expect(tester.find.text('N'), isTrue);
    });

    test('Positioned with multi-character text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Stack(
          width: 30,
          height: 5,
          children: [Positioned(left: 5, top: 2, child: Text('Hello'))],
        ),
      );

      final pos = tester.locateText('Hello');
      expect(pos, isNotNull);
      expect(pos!.x, equals(5));
      expect(pos.y, equals(2));
    });
  });
}
