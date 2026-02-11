import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('SizedBox', () {
    test('renders child with explicit width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(SizedBox(width: 20, child: Text('Fixed')));

      expect(tester.find.text('Fixed'), isTrue);
      final lines = tester.viewLines.where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) {
        expect(Layout.visibleLength(lines.first), lessThanOrEqualTo(20));
      }
    });

    test('renders child with explicit height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(SizedBox(height: 5, child: Text('Fixed')));

      final lines = tester.viewLines;
      expect(lines.length, lessThanOrEqualTo(5));
    });

    test('renders child with explicit width and height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        SizedBox(width: 15, height: 3, child: Text('Fixed')),
      );

      expect(tester.find.text('Fixed'), isTrue);
      final lines = tester.viewLines;
      expect(lines.length, lessThanOrEqualTo(3));
    });

    test('renders empty SizedBox', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Row(children: [Text('A'), SizedBox(width: 5), Text('B')]),
        ),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('renders SizedBox with only width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Text('A'), SizedBox(width: 10), Text('B')]),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('renders SizedBox with only height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(children: [Text('A'), SizedBox(height: 3), Text('B')]),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('renders SizedBox.shrink', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Text('A'), SizedBox.shrink(), Text('B')]),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('renders SizedBox with expand constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 20,
          height: 10,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(width: 20, height: 10),
            child: Text('Expand'),
          ),
        ),
      );

      expect(tester.find.text('Expand'), isTrue);
    });

    test('provides access to child', () {
      final child = Text('child');
      final sizedBox = SizedBox(width: 10, child: child);
      expect(sizedBox.children, equals([child]));
    });

    test('has no children when empty', () {
      final sizedBox = SizedBox(width: 10);
      expect(sizedBox.children, isEmpty);
    });

    test('is not focusable', () {
      final sizedBox = SizedBox(width: 10, child: Text('test'));
      expect(sizedBox.focusable, isFalse);
    });

    test('has unique id', () {
      final s1 = SizedBox(width: 10);
      final s2 = SizedBox(width: 10);
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('respects key', () {
      final sizedBox = SizedBox(key: ValueKey('sizedbox-key'), width: 10);
      expect(sizedBox.id, equals('sizedbox-key'));
    });
  });

  group('ConstrainedBox', () {
    test('renders child with constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 10,
            maxWidth: 20,
            minHeight: 2,
            maxHeight: 5,
          ),
          child: Text('Constrained'),
        ),
      );

      expect(tester.find.text('Constrained'), isTrue);
    });

    test('renders child with min constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 15, minHeight: 3),
          child: Text('Min'),
        ),
      );

      expect(tester.find.text('Min'), isTrue);
    });

    test('renders child with max constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 10, maxHeight: 4),
          child: Text('Max'),
        ),
      );

      expect(tester.find.text('Max'), isTrue);
    });

    test('renders child with tight constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ConstrainedBox(
          constraints: BoxConstraints.tight(Size(15, 5)),
          child: Text('Tight'),
        ),
      );

      expect(tester.find.text('Tight'), isTrue);
    });

    test('renders child with expand constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ConstrainedBox(
          constraints: BoxConstraints.expand(width: 20, height: 8),
          child: Text('Expanded'),
        ),
      );

      expect(tester.find.text('Expanded'), isTrue);
    });

    test('provides access to child', () {
      final child = Text('child');
      final constrainedBox = ConstrainedBox(
        constraints: BoxConstraints(minWidth: 10),
        child: child,
      );
      expect(constrainedBox.children, equals([child]));
    });

    test('is not focusable', () {
      final constrainedBox = ConstrainedBox(
        constraints: BoxConstraints(minWidth: 10),
        child: Text('test'),
      );
      expect(constrainedBox.focusable, isFalse);
    });

    test('has unique id', () {
      final c1 = ConstrainedBox(
        constraints: BoxConstraints(minWidth: 10),
        child: Text('a'),
      );
      final c2 = ConstrainedBox(
        constraints: BoxConstraints(minWidth: 10),
        child: Text('b'),
      );
      expect(c1.id, isNot(equals(c2.id)));
    });
  });

  group('BoxConstraints', () {
    test('creates constraints with all values', () {
      final constraints = BoxConstraints(
        minWidth: 10,
        maxWidth: 20,
        minHeight: 5,
        maxHeight: 15,
      );
      expect(constraints.minWidth, equals(10));
      expect(constraints.maxWidth, equals(20));
      expect(constraints.minHeight, equals(5));
      expect(constraints.maxHeight, equals(15));
    });

    test('creates tight constraints', () {
      final constraints = BoxConstraints.tight(Size(15, 10));
      expect(constraints.minWidth, equals(15));
      expect(constraints.maxWidth, equals(15));
      expect(constraints.minHeight, equals(10));
      expect(constraints.maxHeight, equals(10));
    });

    test('creates expand constraints', () {
      final constraints = BoxConstraints.expand(width: 25, height: 15);
      expect(constraints.minWidth, equals(25));
      expect(constraints.maxWidth, equals(25));
      expect(constraints.minHeight, equals(15));
      expect(constraints.maxHeight, equals(15));
    });

    test('creates expand with only width', () {
      final constraints = BoxConstraints.expand(width: 20);
      expect(constraints.minWidth, equals(20));
      expect(constraints.maxWidth, equals(20));
    });

    test('creates expand with only height', () {
      final constraints = BoxConstraints.expand(height: 10);
      expect(constraints.minHeight, equals(10));
      expect(constraints.maxHeight, equals(10));
    });

    test('constrains width within bounds', () {
      final constraints = BoxConstraints(minWidth: 10, maxWidth: 20);
      expect(constraints.constrainWidth(5), equals(10));
      expect(constraints.constrainWidth(15), equals(15));
      expect(constraints.constrainWidth(25), equals(20));
    });

    test('constrains height within bounds', () {
      final constraints = BoxConstraints(minHeight: 5, maxHeight: 15);
      expect(constraints.constrainHeight(3), equals(5));
      expect(constraints.constrainHeight(10), equals(10));
      expect(constraints.constrainHeight(20), equals(15));
    });

    test('hasBoundedWidth returns correct value', () {
      final bounded = BoxConstraints(maxWidth: 20);
      final unbounded = BoxConstraints();
      expect(bounded.hasBoundedWidth, isTrue);
      expect(unbounded.hasBoundedWidth, isFalse);
    });

    test('hasBoundedHeight returns correct value', () {
      final bounded = BoxConstraints(maxHeight: 20);
      final unbounded = BoxConstraints();
      expect(bounded.hasBoundedHeight, isTrue);
      expect(unbounded.hasBoundedHeight, isFalse);
    });

    test('isTight returns true when min equals max', () {
      final tight = BoxConstraints.tight(Size(10, 10));
      final loose = BoxConstraints(minWidth: 5, maxWidth: 10);
      expect(tight.isTight, isTrue);
      expect(loose.isTight, isFalse);
    });
  });

  group('SizedBox and ConstrainedBox integration', () {
    test('SizedBox as spacer in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Text('Left'), SizedBox(width: 10), Text('Right')]),
      );
      expect(tester.find.text('Left'), isTrue);
      expect(tester.find.text('Right'), isTrue);
    });

    test('SizedBox as spacer in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(children: [Text('Top'), SizedBox(height: 3), Text('Bottom')]),
      );
      expect(tester.find.text('Top'), isTrue);
      expect(tester.find.text('Bottom'), isTrue);
    });

    test('ConstrainedBox in Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 15, maxWidth: 25),
            child: Text('Constrained'),
          ),
        ),
      );
      expect(tester.find.text('Constrained'), isTrue);
    });

    test('nested SizedBox and ConstrainedBox', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Wrap in Container with alignment so the SizedBox receives loose constraints.
      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 30,
            height: 10,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 20),
              child: Center(child: Text('Nested')),
            ),
          ),
        ),
      );
      expect(tester.find.text('Nested'), isTrue);
    });
  });
}
