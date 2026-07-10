import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Wrap basics', () {
    test('empty wrap renders empty', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Wrap(children: []));
      expect(tester.view.trim(), isEmpty);
    });

    test('single child renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Wrap(children: [Text('Hello')]));
      expect(tester.find.text('Hello'), isTrue);
    });

    test('multiple children all render', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(children: [Text('A'), Text('B'), Text('C')]),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
      expect(tester.find.text('C'), isTrue);
    });
  });

  group('Wrap horizontal layout', () {
    test('children on same line when unconstrained', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(children: [Text('A'), Text('B'), Text('C')]),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      expect(cPos, isNotNull);

      // All on same row
      expect(aPos!.y, equals(bPos!.y));
      expect(bPos.y, equals(cPos!.y));

      // Positioned left to right
      expect(aPos.x, lessThan(bPos.x));
      expect(bPos.x, lessThan(cPos.x));
    });

    test('children wrap to next line when screen is narrow', () async {
      // screenWidth=4: AAA(3) fits, BBB(3) does not (3+0+3=6>4), wraps.
      final tester = WidgetTester(screenWidth: 4);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Wrap(children: [Text('AAA'), Text('BBB')]));

      final aPos = tester.locateText('AAA');
      final bPos = tester.locateText('BBB');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);

      // On different rows
      expect(aPos!.y, equals(0));
      expect(bPos!.y, equals(1));
    });

    test('partial wrap: some items fit, rest wraps', () async {
      // screenWidth=10: AAAA(4)+BBBB(4)=8<=10, fits on first row.
      // CCCC(4): 8+0+4=12>10, wraps to second row.
      final tester = WidgetTester(screenWidth: 10);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(children: [Text('AAAA'), Text('BBBB'), Text('CCCC')]),
      );

      final aPos = tester.locateText('AAAA');
      final bPos = tester.locateText('BBBB');
      final cPos = tester.locateText('CCCC');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      expect(cPos, isNotNull);

      // A and B on same row
      expect(aPos!.y, equals(bPos!.y));
      // C on next row
      expect(cPos!.y, greaterThan(aPos.y));
      // C starts at x=0
      expect(cPos.x, equals(0));
    });
  });

  group('Wrap spacing', () {
    test('spacing between items on main axis', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(spacing: 2, children: [Text('A'), Text('B')]),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);

      // A(1) + spacing(2) = B starts at x=3
      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(3));
    });

    test('spacing with three items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(spacing: 1, children: [Text('A'), Text('B'), Text('C')]),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      expect(cPos, isNotNull);

      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(2)); // 0+1+1
      expect(cPos!.x, equals(4)); // 2+1+1
    });

    test('runSpacing between rows', () async {
      // screenWidth=5: AAA(3) fits, BBB(3) wraps (3+0+3=6>5).
      final tester = WidgetTester(screenWidth: 5);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(runSpacing: 2, children: [Text('AAA'), Text('BBB')]),
      );

      final aPos = tester.locateText('AAA');
      final bPos = tester.locateText('BBB');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);

      // First row at y=0. Item height=1, runSpacing=2, so second row at y=3.
      expect(aPos!.y, equals(0));
      expect(bPos!.y, equals(3));
    });

    test('spacing zero places items adjacent', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(spacing: 0, children: [Text('A'), Text('B')]),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(1));
    });

    test('spacing affects when items wrap', () async {
      // screenWidth=6: A(1)+spacing(3)+B(1)=5<=6, fits.
      // 5+spacing(3)+C(1)=9>6, C wraps.
      final tester = WidgetTester(screenWidth: 6);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(spacing: 3, children: [Text('A'), Text('B'), Text('C')]),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      expect(cPos, isNotNull);

      // A and B on same row
      expect(aPos!.y, equals(bPos!.y));
      // C on next row
      expect(cPos!.y, greaterThan(aPos.y));
    });
  });

  group('Wrap direction', () {
    test('default direction is horizontal', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Wrap(children: [Text('X'), Text('Y')]));

      final xPos = tester.locateText('X');
      final yPos = tester.locateText('Y');

      expect(xPos, isNotNull);
      expect(yPos, isNotNull);

      // Horizontal: same y, different x
      expect(xPos!.y, equals(yPos!.y));
      expect(xPos.x, lessThan(yPos.x));
    });

    test('vertical direction places items top-to-bottom', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(direction: Axis.vertical, children: [Text('X'), Text('Y')]),
      );

      final xPos = tester.locateText('X');
      final yPos = tester.locateText('Y');

      expect(xPos, isNotNull);
      expect(yPos, isNotNull);

      // Vertical: same x, different y
      expect(xPos!.x, equals(yPos!.x));
      expect(xPos.y, lessThan(yPos.y));
    });

    test('vertical direction wraps to new column when constrained', () async {
      // screenHeight=2: A and B fit vertically, C wraps to new column.
      final tester = WidgetTester(screenWidth: 20, screenHeight: 2);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(
          direction: Axis.vertical,
          children: [Text('A'), Text('B'), Text('C')],
        ),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      expect(cPos, isNotNull);

      // A and B in first column (same x)
      expect(aPos!.x, equals(bPos!.x));
      // C wraps to next column
      expect(cPos!.x, greaterThan(aPos.x));
    });

    test('vertical with spacing', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(
          direction: Axis.vertical,
          spacing: 1,
          children: [Text('A'), Text('B')],
        ),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);

      // Vertical spacing: A at y=0, spacing=1, B at y=2
      expect(aPos!.y, equals(0));
      expect(bPos!.y, equals(2));
    });
  });

  group('Wrap alignment', () {
    test('WrapAlignment.start positions items at the start', () async {
      // Create a scenario with wrapping: first row full, second row shorter.
      // screenWidth=10, first row: AAAAAA(6)+BBBB(4)=10, second row: C+D=2.
      final tester = WidgetTester(screenWidth: 10);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(
          alignment: WrapAlignment.start,
          children: [Text('AAAAAA'), Text('BBBB'), Text('C'), Text('D')],
        ),
      );

      final cPos = tester.locateText('C');
      final dPos = tester.locateText('D');

      expect(cPos, isNotNull);
      expect(dPos, isNotNull);

      // With start alignment, second row starts at x=0
      expect(cPos!.x, equals(0));
      expect(dPos!.x, equals(1));
    });

    test('WrapAlignment.end pushes shorter row to the end', () async {
      final tester = WidgetTester(screenWidth: 10);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(
          alignment: WrapAlignment.end,
          children: [Text('AAAAAA'), Text('BBBB'), Text('C'), Text('D')],
        ),
      );

      final cPos = tester.locateText('C');
      final dPos = tester.locateText('D');

      expect(cPos, isNotNull);
      expect(dPos, isNotNull);

      // With end alignment, C and D pushed to right: C at x=8, D at x=9
      expect(cPos!.x, equals(8));
      expect(dPos!.x, equals(9));
    });

    test('WrapAlignment.center centers shorter row', () async {
      final tester = WidgetTester(screenWidth: 10);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(
          alignment: WrapAlignment.center,
          children: [Text('AAAAAA'), Text('BBBB'), Text('C'), Text('D')],
        ),
      );

      final cPos = tester.locateText('C');
      final dPos = tester.locateText('D');

      expect(cPos, isNotNull);
      expect(dPos, isNotNull);

      // With center alignment, C and D centered: leading = 8~/2 = 4
      expect(cPos!.x, equals(4));
      expect(dPos!.x, equals(5));
    });
  });

  group('Wrap crossAxisAlignment', () {
    test('WrapCrossAlignment.start is default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [Text('X')],
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.y, equals(0));
    });
  });

  group('Wrap properties', () {
    test('respects key', () {
      final wrap = Wrap(key: ValueKey('wrap-key'), children: []);
      expect(wrap.id, equals('wrap-key'));
    });

    test('has unique id without key', () {
      final w1 = Wrap(children: []);
      final w2 = Wrap(children: []);
      expect(w1.id, isNot(equals(w2.id)));
    });

    test('is not focusable', () {
      final wrap = Wrap(children: []);
      expect(wrap.focusable, isFalse);
    });

    test('provides access to children', () {
      final a = Text('A');
      final b = Text('B');
      final wrap = Wrap(children: [a, b]);
      expect(wrap.children, equals([a, b]));
    });

    test('default direction is Axis.horizontal', () {
      final wrap = Wrap(children: []);
      expect(wrap.direction, equals(Axis.horizontal));
    });

    test('default alignment is WrapAlignment.start', () {
      final wrap = Wrap(children: []);
      expect(wrap.alignment, equals(WrapAlignment.start));
    });

    test('default crossAxisAlignment is WrapCrossAlignment.start', () {
      final wrap = Wrap(children: []);
      expect(wrap.crossAxisAlignment, equals(WrapCrossAlignment.start));
    });

    test('default spacing is 0', () {
      final wrap = Wrap(children: []);
      expect(wrap.spacing, equals(0));
    });

    test('default runSpacing is 0', () {
      final wrap = Wrap(children: []);
      expect(wrap.runSpacing, equals(0));
    });

    test('custom properties are stored', () {
      final wrap = Wrap(
        direction: Axis.vertical,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 3,
        runSpacing: 5,
        children: [],
      );
      expect(wrap.direction, equals(Axis.vertical));
      expect(wrap.alignment, equals(WrapAlignment.center));
      expect(wrap.crossAxisAlignment, equals(WrapCrossAlignment.end));
      expect(wrap.spacing, equals(3));
      expect(wrap.runSpacing, equals(5));
    });
  });

  group('Wrap multiple children on same row', () {
    test('three items fit on one line with spacing', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(spacing: 1, children: [Text('A'), Text('B'), Text('C')]),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      expect(cPos, isNotNull);

      // All on same y
      expect(aPos!.y, equals(bPos!.y));
      expect(bPos.y, equals(cPos!.y));

      // A at 0, B at 2 (0+1+1), C at 4 (2+1+1)
      expect(aPos.x, equals(0));
      expect(bPos.x, equals(2));
      expect(cPos.x, equals(4));
    });

    test('items wrap when exceeding constrained width', () async {
      // screenWidth=4: XX(2)+spacing(1)+YY(2)=5>4, second item wraps.
      final tester = WidgetTester(screenWidth: 4);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Wrap(spacing: 1, children: [Text('XX'), Text('YY')]),
      );

      final xxPos = tester.locateText('XX');
      final yyPos = tester.locateText('YY');

      expect(xxPos, isNotNull);
      expect(yyPos, isNotNull);

      // XX on first row, YY on second
      expect(xxPos!.y, equals(0));
      expect(yyPos!.y, greaterThan(0));
    });

    test('all items fit when total equals width exactly', () async {
      // screenWidth=6: AAA(3)+BBB(3)=6<=6, both on first row.
      final tester = WidgetTester(screenWidth: 6);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Wrap(children: [Text('AAA'), Text('BBB')]));

      final aPos = tester.locateText('AAA');
      final bPos = tester.locateText('BBB');

      expect(aPos, isNotNull);
      expect(bPos, isNotNull);

      // Both on same row
      expect(aPos!.y, equals(bPos!.y));
    });
  });

  group('Wrap integration', () {
    test('Wrap inside Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          child: Wrap(
            spacing: 1,
            children: [Text('Tag1'), Text('Tag2'), Text('Tag3')],
          ),
        ),
      );

      expect(tester.find.text('Tag1'), isTrue);
      expect(tester.find.text('Tag2'), isTrue);
      expect(tester.find.text('Tag3'), isTrue);
    });

    test('Wrap inside Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Header'),
            Wrap(children: [Text('W1'), Text('W2')]),
            Text('Footer'),
          ],
        ),
      );

      expect(tester.find.text('Header'), isTrue);
      expect(tester.find.text('W1'), isTrue);
      expect(tester.find.text('W2'), isTrue);
      expect(tester.find.text('Footer'), isTrue);

      final headerPos = tester.locateText('Header');
      final w1Pos = tester.locateText('W1');
      final footerPos = tester.locateText('Footer');

      expect(headerPos, isNotNull);
      expect(w1Pos, isNotNull);
      expect(footerPos, isNotNull);

      // Header above wrap, wrap above footer
      expect(w1Pos!.y, greaterThan(headerPos!.y));
      expect(footerPos!.y, greaterThan(w1Pos.y));
    });

    test('Wrap with wrapping inside Column', () async {
      // Use narrow screen so wrap items flow to next line
      final tester = WidgetTester(screenWidth: 6);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Title'),
            Wrap(children: [Text('AAA'), Text('BBB')]),
          ],
        ),
      );

      expect(tester.find.text('Title'), isTrue);
      expect(tester.find.text('AAA'), isTrue);
      expect(tester.find.text('BBB'), isTrue);
    });

    test('Wrap inside Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('L'),
            Wrap(children: [Text('M'), Text('N')]),
          ],
        ),
      );

      expect(tester.find.text('L'), isTrue);
      expect(tester.find.text('M'), isTrue);
      expect(tester.find.text('N'), isTrue);
    });

    test('Wrap with runSpacing in Column preserves vertical flow', () async {
      final tester = WidgetTester(screenWidth: 5);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Top'),
            Wrap(runSpacing: 1, children: [Text('AAA'), Text('BBB')]),
            Text('Bot'),
          ],
        ),
      );

      expect(tester.find.text('Top'), isTrue);
      expect(tester.find.text('AAA'), isTrue);
      expect(tester.find.text('BBB'), isTrue);
      expect(tester.find.text('Bot'), isTrue);

      final topPos = tester.locateText('Top');
      final botPos = tester.locateText('Bot');

      expect(topPos, isNotNull);
      expect(botPos, isNotNull);
      expect(botPos!.y, greaterThan(topPos!.y));
    });
  });
}
