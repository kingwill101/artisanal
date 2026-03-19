import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Row', () {
    test('positions children horizontally without gap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Row(children: [Text('A'), Text('B'), Text('C')]));

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');

      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(1));
      expect(cPos!.x, equals(2));
      expect(aPos.y, equals(bPos.y));
      expect(bPos.y, equals(cPos.y));
    });

    test('applies gap of 2 between children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Row(gap: 2, children: [Text('A'), Text('B')]));

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(3));
    });

    test('applies gap of 0 between children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Row(gap: 0, children: [Text('A'), Text('B')]));

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(1));
    });

    test('renders empty row as empty', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Row(children: []));
      expect(tester.view.trim(), isEmpty);
    });

    test('mainAxisAlignment start positions at left', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Text('XX')],
          ),
        ),
      );

      final pos = tester.locateText('XX');
      expect(pos!.x, equals(0));
    });

    test('mainAxisAlignment center positions in middle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Row needs explicit width + mainAxisSize.max to have extra space,
      // and needs multiple children for _computeSpacing to distribute space.
      await tester.pumpWidget(
        Row(
          width: 20,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('A'), Text('B')],
        ),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      // With center alignment, items should be centered with equal space on sides
      expect(aPos!.x, greaterThan(0));
    });

    test('mainAxisAlignment end positions at right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Row needs explicit width + mainAxisSize.max for end alignment,
      // and needs multiple children for _computeSpacing to work.
      await tester.pumpWidget(
        Row(
          width: 20,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Text('A'), Text('B')],
        ),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      // With end alignment, items should be pushed to the right
      expect(aPos!.x, greaterThan(0));
      expect(bPos!.x, greaterThan(aPos.x));
    });

    test('crossAxisAlignment start positions at top', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          height: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('X')],
          ),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos!.y, equals(0));
    });

    test('crossAxisAlignment center positions in middle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Cross axis alignment needs an explicit cross extent (height for Row)
      // to have space to distribute. Use height param on Row directly.
      // Wrap in Container with alignment so the Row receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Row(
            height: 5,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Text('X')],
          ),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.y, equals(2));
    });

    test('crossAxisAlignment end positions at bottom', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Cross axis alignment needs explicit cross extent (height for Row).
      // Wrap in Container with alignment so the Row receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Row(
            height: 5,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [Text('X')],
          ),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.y, equals(4));
    });

    test('provides access to children', () {
      final a = Text('A');
      final b = Text('B');
      final row = Row(children: [a, b]);
      expect(row.children, equals([a, b]));
    });

    test('is not focusable', () {
      final row = Row(children: []);
      expect(row.focusable, isFalse);
    });

    test('has unique id', () {
      final r1 = Row(children: []);
      final r2 = Row(children: []);
      expect(r1.id, isNot(equals(r2.id)));
    });

    test('respects key', () {
      final row = Row(key: ValueKey('row-key'), children: []);
      expect(row.id, equals('row-key'));
    });
  });

  group('Column', () {
    test('positions children vertically without gap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(children: [Text('A'), Text('B'), Text('C')]),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');

      expect(aPos!.y, equals(0));
      expect(bPos!.y, equals(1));
      expect(cPos!.y, equals(2));
      expect(aPos.x, equals(bPos.x));
      expect(bPos.x, equals(cPos.x));
    });

    test('applies gap of 2 between children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Column(gap: 2, children: [Text('A'), Text('B')]));

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos!.y, equals(0));
      expect(bPos!.y, equals(3));
    });

    test('applies gap of 0 between children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Column(gap: 0, children: [Text('A'), Text('B')]));

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos!.y, equals(0));
      expect(bPos!.y, equals(1));
    });

    test('renders empty column as empty', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Column(children: []));
      expect(tester.view.trim(), isEmpty);
    });

    test('mainAxisAlignment start positions at top', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          height: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Text('X')],
          ),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos!.y, equals(0));
    });

    test('mainAxisAlignment center positions in middle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Column needs explicit height to have extra space,
      // and needs multiple children for _computeSpacing to distribute space.
      await tester.pumpWidget(
        Column(
          height: 10,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('A'), Text('B')],
        ),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      // With center alignment, items should be centered vertically
      expect(aPos!.y, greaterThan(0));
    });

    test('mainAxisAlignment end positions at bottom', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Column needs explicit height for end alignment.
      await tester.pumpWidget(
        Column(
          height: 10,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Text('A'), Text('B')],
        ),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      expect(aPos, isNotNull);
      expect(bPos, isNotNull);
      // With end alignment, items should be pushed to the bottom
      expect(aPos!.y, greaterThan(0));
      expect(bPos!.y, greaterThan(aPos.y));
    });

    test('crossAxisAlignment start positions at left', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('X')],
          ),
        ),
      );

      final pos = tester.locateText('X');
      expect(pos!.x, equals(0));
    });

    test('crossAxisAlignment center positions in middle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Cross axis alignment needs explicit cross extent (width for Column).
      await tester.pumpWidget(
        Column(
          width: 20,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text('X')],
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
    });

    test('crossAxisAlignment end positions at right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Cross axis alignment needs explicit cross extent (width for Column).
      await tester.pumpWidget(
        Column(
          width: 20,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [Text('X')],
        ),
      );

      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
    });

    test('provides access to children', () {
      final a = Text('A');
      final b = Text('B');
      final column = Column(children: [a, b]);
      expect(column.children, equals([a, b]));
    });

    test('is not focusable', () {
      final column = Column(children: []);
      expect(column.focusable, isFalse);
    });

    test('has unique id', () {
      final c1 = Column(children: []);
      final c2 = Column(children: []);
      expect(c1.id, isNot(equals(c2.id)));
    });

    test('respects key', () {
      final column = Column(key: ValueKey('column-key'), children: []);
      expect(column.id, equals('column-key'));
    });
  });

  group('HBox and VBox aliases', () {
    test('HBox behaves like Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(HBox(gap: 2, children: [Text('A'), Text('B')]));

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(3));
    });

    test('VBox behaves like Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(VBox(gap: 1, children: [Text('A'), Text('B')]));

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');

      expect(aPos!.y, equals(0));
      expect(bPos!.y, equals(2));
    });
  });

  group('Row and Column integration', () {
    test('Row inside Column creates grid-like layout', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Header'),
            Row(children: [Text('L'), Text('R')]),
            Text('Footer'),
          ],
        ),
      );

      final headerPos = tester.locateText('Header');
      final lPos = tester.locateText('L');
      final rPos = tester.locateText('R');
      final footerPos = tester.locateText('Footer');

      expect(headerPos!.y, equals(0));
      expect(lPos!.y, equals(1));
      expect(rPos!.y, equals(1));
      expect(footerPos!.y, equals(2));
    });

    test('Column inside Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Column(children: [Text('T'), Text('B')]),
            Text('S'),
          ],
        ),
      );

      final tPos = tester.locateText('T');
      final bPos = tester.locateText('B');
      final sPos = tester.locateText('S');

      expect(tPos!.x, equals(0));
      expect(bPos!.x, equals(0));
      expect(sPos!.x, equals(1));
      expect(tPos.y, equals(0));
      expect(bPos.y, equals(1));
    });

    test('complex nested layout', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Row(children: [Text('A'), Text('B')]),
            Row(children: [Text('C'), Text('D')]),
          ],
        ),
      );

      final aPos = tester.locateText('A');
      final bPos = tester.locateText('B');
      final cPos = tester.locateText('C');
      final dPos = tester.locateText('D');

      expect(aPos!.x, equals(0));
      expect(bPos!.x, equals(1));
      expect(cPos!.x, equals(0));
      expect(dPos!.x, equals(1));
      expect(aPos.y, equals(0));
      expect(cPos.y, equals(1));
    });
  });
}
