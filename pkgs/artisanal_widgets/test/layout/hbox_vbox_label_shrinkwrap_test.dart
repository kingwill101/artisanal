library;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // HBox
  // ---------------------------------------------------------------------------
  group('HBox', () {
    test('lays out children horizontally', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(HBox(children: [Text('A'), Text('B')]));
        final posA = tester.locateText('A');
        final posB = tester.locateText('B');
        expect(posA, isNotNull);
        expect(posB, isNotNull);
        // Same row
        expect(posA!.y, equals(posB!.y));
        // B to the right of A
        expect(posB.x, greaterThan(posA.x));
      } finally {
        await tester.dispose();
      }
    });

    test('default gap is 1', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(HBox(children: [Text('X'), Text('Y')]));
        final posX = tester.locateText('X');
        final posY = tester.locateText('Y');
        expect(posX, isNotNull);
        expect(posY, isNotNull);
        // X is 1 char, gap is 1, so Y starts at x=2
        expect(posY!.x, equals(posX!.x + 1 + 1));
      } finally {
        await tester.dispose();
      }
    });

    test('custom gap works', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(HBox(gap: 3, children: [Text('X'), Text('Y')]));
        final posX = tester.locateText('X');
        final posY = tester.locateText('Y');
        expect(posX, isNotNull);
        expect(posY, isNotNull);
        // X is 1 char, gap is 3, so Y starts at x=4
        expect(posY!.x, equals(posX!.x + 1 + 3));
      } finally {
        await tester.dispose();
      }
    });

    test('gap 0 places children adjacent', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(HBox(gap: 0, children: [Text('A'), Text('B')]));
        final posA = tester.locateText('A');
        final posB = tester.locateText('B');
        expect(posB!.x, equals(posA!.x + 1));
      } finally {
        await tester.dispose();
      }
    });

    test('VerticalAlign.top is default (start)', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          HBox(children: [Text('Short'), Text('Line1\nLine2\nLine3')]),
        );
        final posShort = tester.locateText('Short');
        final posLine1 = tester.locateText('Line1');
        // Both should start at y=0 (top aligned)
        expect(posShort!.y, equals(0));
        expect(posLine1!.y, equals(0));
      } finally {
        await tester.dispose();
      }
    });

    test('VerticalAlign.center centers shorter child', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        // Wrap in Container with alignment so the HBox receives loose constraints.
        await tester.pumpWidget(
          Container(
            alignment: Alignment.topLeft,
            child: HBox(
              align: VerticalAlign.center,
              children: [Text('Mid'), Text('L1\nL2\nL3')],
            ),
          ),
        );
        final posMid = tester.locateText('Mid');
        final posL1 = tester.locateText('L1');
        // 3-line child starts at y=0, 1-line child should be centered at y=1
        expect(posL1!.y, equals(0));
        expect(posMid!.y, equals(1));
      } finally {
        await tester.dispose();
      }
    });

    test('VerticalAlign.bottom bottom-aligns shorter child', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        // Wrap in Container with alignment so the HBox receives loose constraints.
        await tester.pumpWidget(
          Container(
            alignment: Alignment.topLeft,
            child: HBox(
              align: VerticalAlign.bottom,
              children: [Text('Bot'), Text('L1\nL2\nL3')],
            ),
          ),
        );
        final posBot = tester.locateText('Bot');
        final posL1 = tester.locateText('L1');
        // 3-line child starts at y=0, 1-line child should be at y=2
        expect(posL1!.y, equals(0));
        expect(posBot!.y, equals(2));
      } finally {
        await tester.dispose();
      }
    });

    test('multiple children renders all', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          HBox(children: [Text('A'), Text('B'), Text('C'), Text('D')]),
        );
        expect(tester.find.text('A'), isTrue);
        expect(tester.find.text('B'), isTrue);
        expect(tester.find.text('C'), isTrue);
        expect(tester.find.text('D'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // VBox
  // ---------------------------------------------------------------------------
  group('VBox', () {
    test('lays out children vertically', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(VBox(children: [Text('Top'), Text('Bottom')]));
        final posTop = tester.locateText('Top');
        final posBot = tester.locateText('Bottom');
        expect(posTop, isNotNull);
        expect(posBot, isNotNull);
        // Same column
        expect(posTop!.x, equals(posBot!.x));
        // Bottom below Top
        expect(posBot.y, greaterThan(posTop.y));
      } finally {
        await tester.dispose();
      }
    });

    test('default gap is 0', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(VBox(children: [Text('R1'), Text('R2')]));
        final posR1 = tester.locateText('R1');
        final posR2 = tester.locateText('R2');
        expect(posR1, isNotNull);
        expect(posR2, isNotNull);
        // Adjacent rows: gap=0
        expect(posR2!.y, equals(posR1!.y + 1));
      } finally {
        await tester.dispose();
      }
    });

    test('custom gap works', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          VBox(gap: 2, children: [Text('R1'), Text('R2')]),
        );
        final posR1 = tester.locateText('R1');
        final posR2 = tester.locateText('R2');
        expect(posR2!.y, equals(posR1!.y + 1 + 2));
      } finally {
        await tester.dispose();
      }
    });

    test('HorizontalAlign.left is default (start)', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          VBox(children: [Text('Short'), Text('LongWord')]),
        );
        final posShort = tester.locateText('Short');
        final posLong = tester.locateText('LongWord');
        // Both left-aligned at x=0
        expect(posShort!.x, equals(0));
        expect(posLong!.x, equals(0));
      } finally {
        await tester.dispose();
      }
    });

    test('HorizontalAlign.center centers shorter child', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        // Wrap in Container with alignment so the VBox receives loose constraints.
        await tester.pumpWidget(
          Container(
            alignment: Alignment.topLeft,
            child: VBox(
              align: HorizontalAlign.center,
              children: [Text('AB'), Text('ABCDEF')],
            ),
          ),
        );
        final posAB = tester.locateText('AB');
        final posABCDEF = tester.locateText('ABCDEF');
        // Longer child starts at x=0; shorter centered
        expect(posABCDEF!.x, equals(0));
        expect(posAB!.x, equals(2)); // (6-2)/2 = 2
      } finally {
        await tester.dispose();
      }
    });

    test('HorizontalAlign.right right-aligns shorter child', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        // Wrap in Container with alignment so the VBox receives loose constraints.
        await tester.pumpWidget(
          Container(
            alignment: Alignment.topLeft,
            child: VBox(
              align: HorizontalAlign.right,
              children: [Text('AB'), Text('ABCDEF')],
            ),
          ),
        );
        final posAB = tester.locateText('AB');
        final posABCDEF = tester.locateText('ABCDEF');
        // Longer child starts at x=0; shorter right-aligned
        expect(posABCDEF!.x, equals(0));
        expect(posAB!.x, equals(4)); // 6-2 = 4
      } finally {
        await tester.dispose();
      }
    });

    test('multiple children renders all', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          VBox(children: [Text('V1'), Text('V2'), Text('V3')]),
        );
        expect(tester.find.text('V1'), isTrue);
        expect(tester.find.text('V2'), isTrue);
        expect(tester.find.text('V3'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Label
  // ---------------------------------------------------------------------------
  group('Label', () {
    test('renders text like Text widget', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(Label('Hello Label'));
        expect(tester.find.text('Hello Label'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders at correct position', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(Label('Pos'));
        final pos = tester.locateText('Pos');
        expect(pos, isNotNull);
        expect(pos!.x, equals(0));
        expect(pos.y, equals(0));
      } finally {
        await tester.dispose();
      }
    });

    test('Label.styled requires style parameter', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        final style = Style().foreground(Colors.red);
        await tester.pumpWidget(Label.styled('Styled', style: style));
        // Use locateText since styled text has ANSI codes
        final pos = tester.locateText('Styled');
        expect(pos, isNotNull);
      } finally {
        await tester.dispose();
      }
    });

    test('Label with optional style', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        final style = Style().bold(true);
        await tester.pumpWidget(Label('Bold', style: style));
        final pos = tester.locateText('Bold');
        expect(pos, isNotNull);
      } finally {
        await tester.dispose();
      }
    });

    test('Label inside HBox renders correctly', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          HBox(children: [Label('Left'), Label('Right')]),
        );
        expect(tester.find.text('Left'), isTrue);
        final posR = tester.locateText('Right');
        expect(posR, isNotNull);
        expect(posR!.x, greaterThan(0));
      } finally {
        await tester.dispose();
      }
    });

    test('Label inside VBox renders correctly', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          VBox(children: [Label('Line1'), Label('Line2')]),
        );
        final pos1 = tester.locateText('Line1');
        final pos2 = tester.locateText('Line2');
        expect(pos1!.y, equals(0));
        expect(pos2!.y, equals(1));
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ShrinkWrap
  // ---------------------------------------------------------------------------
  group('ShrinkWrap', () {
    test('renders child unchanged', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(ShrinkWrap(child: Text('Wrapped')));
        expect(tester.find.text('Wrapped'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('children getter returns the single child', () {
      final child = Text('inner');
      final sw = ShrinkWrap(child: child);
      expect(sw.children, hasLength(1));
      expect(sw.children.first, same(child));
    });

    test('view delegates to child.view', () {
      final child = Text('content');
      final sw = ShrinkWrap(child: child);
      // Both should produce the same rendered output
      expect(sw.view(), equals(child.view()));
    });

    test('nested ShrinkWrap passes through', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ShrinkWrap(child: ShrinkWrap(child: Text('Deep'))),
        );
        expect(tester.find.text('Deep'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('ShrinkWrap inside Container renders child', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Container(
            width: 20,
            height: 3,
            child: ShrinkWrap(child: Text('InContainer')),
          ),
        );
        expect(tester.find.text('InContainer'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('ShrinkWrap inside Row renders correctly', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Row(
            children: [
              ShrinkWrap(child: Text('SW')),
              Text('After'),
            ],
          ),
        );
        expect(tester.find.text('SW'), isTrue);
        expect(tester.find.text('After'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });
}
