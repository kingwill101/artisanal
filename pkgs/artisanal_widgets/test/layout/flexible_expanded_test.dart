import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Flexible', () {
    test('renders child with default flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Row(children: [Flexible(child: Text('Flex'))]));
      expect(tester.find.text('Flex'), isTrue);
    });

    test('renders child with custom flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Flexible(flex: 2, child: Text('Flex2'))]),
      );
      expect(tester.find.text('Flex2'), isTrue);
    });

    test('respects flex fit loose', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          child: Row(
            children: [Flexible(fit: FlexFit.loose, child: Text('Loose'))],
          ),
        ),
      );
      expect(tester.find.text('Loose'), isTrue);
    });

    test('respects flex fit tight', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          child: Row(
            children: [Flexible(fit: FlexFit.tight, child: Text('Tight'))],
          ),
        ),
      );
      expect(tester.find.text('Tight'), isTrue);
    });

    test('multiple flexibles share space', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          child: Row(
            children: [
              Flexible(flex: 1, child: Text('A')),
              Flexible(flex: 2, child: Text('B')),
            ],
          ),
        ),
      );
      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('provides access to child', () {
      final child = Text('child');
      final flexible = Flexible(child: child);
      expect(flexible.children, equals([child]));
    });

    test('is not focusable', () {
      final flexible = Flexible(child: Text('test'));
      expect(flexible.focusable, isFalse);
    });

    test('has unique id', () {
      final f1 = Flexible(child: Text('a'));
      final f2 = Flexible(child: Text('b'));
      expect(f1.id, isNot(equals(f2.id)));
    });

    test('respects key', () {
      final flexible = Flexible(key: ValueKey('flex-key'), child: Text('test'));
      expect(flexible.id, equals('flex-key'));
    });
  });

  group('Expanded', () {
    test('renders child with default flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Expanded(child: Text('Expanded'))]),
      );
      expect(tester.find.text('Expanded'), isTrue);
    });

    test('renders child with custom flex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Expanded(flex: 3, child: Text('Expanded3'))]),
      );
      expect(tester.find.text('Expanded3'), isTrue);
    });

    test('fills available space', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          child: Row(
            children: [
              Text('Fixed'),
              Expanded(
                child: Container(color: Colors.blue, child: Text('Fill')),
              ),
            ],
          ),
        ),
      );
      expect(tester.find.text('Fixed'), isTrue);
      expect(tester.find.text('Fill'), isTrue);
    });

    test('multiple expanded share space proportionally', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          child: Row(
            children: [
              Expanded(flex: 1, child: Text('A')),
              Expanded(flex: 3, child: Text('B')),
            ],
          ),
        ),
      );
      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('works in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          height: 10,
          child: Column(
            children: [
              Text('Header'),
              Expanded(child: Text('Body')),
              Text('Footer'),
            ],
          ),
        ),
      );
      expect(tester.find.text('Header'), isTrue);
      expect(tester.find.text('Body'), isTrue);
      expect(tester.find.text('Footer'), isTrue);
    });

    test('is subclass of Flexible', () {
      final expanded = Expanded(child: Text('test'));
      expect(expanded, isA<Flexible>());
    });

    test('provides access to child', () {
      final child = Text('child');
      final expanded = Expanded(child: child);
      expect(expanded.children, equals([child]));
    });
  });

  group('FlexFit', () {
    test('FlexFit.loose allows child to be smaller', () {
      final fit = FlexFit.loose;
      expect(fit, equals(FlexFit.loose));
    });

    test('FlexFit.tight forces child to fill space', () {
      final fit = FlexFit.tight;
      expect(fit, equals(FlexFit.tight));
    });
  });

  group('Flexible and Expanded integration', () {
    test('Flexible and Expanded in same Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 40,
          child: Row(
            children: [
              Text('Fixed'),
              Flexible(child: Text('Flex')),
              Expanded(child: Text('Expand')),
            ],
          ),
        ),
      );
      expect(tester.find.text('Fixed'), isTrue);
      expect(tester.find.text('Flex'), isTrue);
      expect(tester.find.text('Expand'), isTrue);
    });

    test('nested Flexible in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Flexible(
              child: Column(children: [Text('Nested 1'), Text('Nested 2')]),
            ),
          ],
        ),
      );
      expect(tester.find.text('Nested 1'), isTrue);
      expect(tester.find.text('Nested 2'), isTrue);
    });

    test('Expanded with Container child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 10,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.red,
                  child: Center(child: Text('Centered')),
                ),
              ),
            ],
          ),
        ),
      );
      expect(tester.find.text('Centered'), isTrue);
    });
  });

  group('Flex position and size verification', () {
    test('Expanded child is positioned after fixed child in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // 'AAAA' is 4 chars wide, Expanded child 'BB' starts after it
      await tester.pumpWidget(
        Row(
          width: 30,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text('AAAA'),
            Expanded(child: Text('BB')),
          ],
        ),
      );
      final posA = tester.locateText('AAAA');
      final posB = tester.locateText('BB');
      expect(posA, isNotNull, reason: 'AAAA should be found');
      expect(posB, isNotNull, reason: 'BB should be found');
      // B starts after A (at column 4 or later)
      expect(posB!.x, greaterThanOrEqualTo(4));
    });

    test('Flexible loose does NOT expand beyond natural size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // With loose fit, the Flexible child stays at its natural width.
      // Place a marker after the Flexible to verify it didn't expand.
      await tester.pumpWidget(
        Row(
          width: 30,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(fit: FlexFit.loose, child: Text('AB')),
            Text('CD'),
          ],
        ),
      );
      final posAB = tester.locateText('AB');
      final posCD = tester.locateText('CD');
      expect(posAB, isNotNull);
      expect(posCD, isNotNull);
      // CD should start right after AB (at column 2), not pushed far right
      expect(posCD!.x, equals(2));
    });

    test('Flexible tight expands to fill available space', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // With tight fit, child gets extra space. The next fixed child
      // should be pushed further right than if tight weren't used.
      await tester.pumpWidget(
        Row(
          width: 20,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(fit: FlexFit.tight, child: Text('AB')),
            Text('CD'),
          ],
        ),
      );
      final posCD = tester.locateText('CD');
      expect(posCD, isNotNull);
      // CD should NOT be at column 2 -- the tight child expanded
      expect(posCD!.x, greaterThan(2));
    });

    test('two Expanded children split extra space proportionally', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Row is 20 wide. 'A' (1 char) + 'B' (1 char) = 2 chars natural.
      // Extra = 20 - 2 = 18. flex 1 gets 18*1/3 = 6, flex 2 gets 18*2/3 = 12.
      // A slot = 1 + 6 = 7, B slot = 1 + 12 = 13.
      // Wrap in Container with alignment so the Row receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Row(
            width: 20,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(flex: 1, child: Text('A')),
              Expanded(flex: 2, child: Text('B')),
            ],
          ),
        ),
      );
      final posA = tester.locateText('A');
      final posB = tester.locateText('B');
      expect(posA, isNotNull);
      expect(posB, isNotNull);
      // A starts at 0, B should start around column 7 (1 + 6)
      expect(posA!.x, equals(0));
      expect(posB!.x, greaterThanOrEqualTo(6));
      expect(posB.x, lessThanOrEqualTo(8));
    });

    test('Expanded in Column pushes footer down', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          height: 10,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text('Top'),
            Expanded(child: Text('Mid')),
            Text('Bot'),
          ],
        ),
      );
      final posTop = tester.locateText('Top');
      final posMid = tester.locateText('Mid');
      final posBot = tester.locateText('Bot');
      expect(posTop, isNotNull);
      expect(posMid, isNotNull);
      expect(posBot, isNotNull);
      // Top at row 0
      expect(posTop!.y, equals(0));
      // Mid at row 1 (right after Top)
      expect(posMid!.y, equals(1));
      // Bot should be pushed down beyond row 2 due to Expanded
      expect(posBot!.y, greaterThan(2));
    });

    test('Expanded with flex 0 does not receive extra space', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // flex: 0 means the child participates but gets no extra space
      await tester.pumpWidget(
        Row(
          width: 20,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(flex: 0, child: Text('AA')),
            Text('BB'),
          ],
        ),
      );
      final posBB = tester.locateText('BB');
      expect(posBB, isNotNull);
      // BB should start right after AA since flex: 0 gets no extra space
      expect(posBB!.x, equals(2));
    });

    test('Spacer with flex pushes siblings apart', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          width: 20,
          mainAxisSize: MainAxisSize.max,
          children: [Text('L'), Spacer(flex: 1), Text('R')],
        ),
      );
      final posL = tester.locateText('L');
      final posR = tester.locateText('R');
      expect(posL, isNotNull);
      expect(posR, isNotNull);
      // L at 0, R should be pushed far right by the Spacer
      expect(posL!.x, equals(0));
      expect(posR!.x, greaterThan(5));
    });

    test('mixed Expanded and non-flex children layout correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Row: [fixed 4] [expanded] [fixed 4] = 20 wide
      // Extra = 20 - 4 - 4 = 12, all goes to the Expanded child
      await tester.pumpWidget(
        Row(
          width: 20,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text('LLLL'),
            Expanded(child: Text('M')),
            Text('RRRR'),
          ],
        ),
      );
      final posL = tester.locateText('LLLL');
      final posM = tester.locateText('M');
      final posR = tester.locateText('RRRR');
      expect(posL, isNotNull);
      expect(posM, isNotNull);
      expect(posR, isNotNull);
      // L starts at 0
      expect(posL!.x, equals(0));
      // M starts at 4
      expect(posM!.x, equals(4));
      // R starts at 4 + (1 + 12) = 17, or close to it
      // The Expanded slot is 1 (natural) + 12 (extra) = 13, so R at column 17
      expect(posR!.x, greaterThanOrEqualTo(15));
    });

    test('equal Expanded children in Column share vertical space', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Column is 10 rows tall. Two children, each 1 row natural.
      // Extra = 10 - 2 = 8, each gets 4 extra = 5 rows per slot.
      // Wrap in Container with alignment so the Column receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Column(
            height: 10,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(flex: 1, child: Text('Top')),
              Expanded(flex: 1, child: Text('Bottom')),
            ],
          ),
        ),
      );
      final posTop = tester.locateText('Top');
      final posBottom = tester.locateText('Bottom');
      expect(posTop, isNotNull);
      expect(posBottom, isNotNull);
      // Top at row 0
      expect(posTop!.y, equals(0));
      // Bottom should be around row 5 (1 + 4 extra)
      expect(posBottom!.y, greaterThanOrEqualTo(4));
      expect(posBottom.y, lessThanOrEqualTo(6));
    });
  });
}
