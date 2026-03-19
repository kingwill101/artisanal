import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Tooltip', () {
    test('shows message when show=true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tooltip(message: 'Help text', show: true, child: Text('Hover me')),
      );

      expect(tester.find.text('Help text'), isTrue);
      expect(tester.find.text('Hover me'), isTrue);
    });

    test('hides message when show=false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tooltip(message: 'Hidden tip', show: false, child: Text('Child only')),
      );

      expect(tester.find.text('Child only'), isTrue);
      expect(tester.find.text('Hidden tip'), isFalse);
    });

    test('hides message by default (no show, not hovered)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tooltip(message: 'Default tip', child: Text('Default child')),
      );

      expect(tester.find.text('Default child'), isTrue);
      expect(tester.find.text('Default tip'), isFalse);
    });

    test('shows message on hover for plain text child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tooltip(message: 'Hover tip', child: Text('Hover target')),
      );

      expect(tester.find.text('Hover tip'), isFalse);
      final target = tester.locateText('Hover target');
      expect(target, isNotNull);

      tester.mouseMove(target!.x, target.y);

      expect(tester.find.text('Hover tip'), isTrue);
    });

    test(
      'shows message below child when position=below and show=true',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Tooltip(
            message: 'Below tip',
            show: true,
            position: TooltipPosition.below,
            child: Text('Target'),
          ),
        );

        expect(tester.find.text('Below tip'), isTrue);
        expect(tester.find.text('Target'), isTrue);

        // With position=below, the child should appear before the tooltip
        final childLoc = tester.locateText('Target');
        final tipLoc = tester.locateText('Below tip');
        expect(childLoc, isNotNull);
        expect(tipLoc, isNotNull);
        expect(tipLoc!.y, greaterThan(childLoc!.y));
      },
    );

    test(
      'shows message above child when position=above and show=true',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Tooltip(
            message: 'Above tip',
            show: true,
            position: TooltipPosition.above,
            child: Text('Target'),
          ),
        );

        expect(tester.find.text('Above tip'), isTrue);
        expect(tester.find.text('Target'), isTrue);

        final childLoc = tester.locateText('Target');
        final tipLoc = tester.locateText('Above tip');
        expect(childLoc, isNotNull);
        expect(tipLoc, isNotNull);
        expect(tipLoc!.y, lessThan(childLoc!.y));
      },
    );

    test('does not show tooltip when disabled even with show=true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tooltip(
          message: 'Disabled tip',
          show: true,
          enabled: false,
          child: Text('Disabled target'),
        ),
      );

      expect(tester.find.text('Disabled target'), isTrue);
      expect(tester.find.text('Disabled tip'), isFalse);
    });

    test('is not focusable by default', () {
      final tooltip = Tooltip(message: 'tip', child: Text('child'));
      expect(tooltip.focusable, isFalse);
    });

    test('has unique id', () {
      final t1 = Tooltip(message: 'a', child: Text('a'));
      final t2 = Tooltip(message: 'b', child: Text('b'));
      expect(t1.id, isNot(equals(t2.id)));
    });

    test('respects key', () {
      final tooltip = Tooltip(
        key: ValueKey('tooltip-key'),
        message: 'tip',
        child: Text('child'),
      );
      expect(tooltip.id, equals('tooltip-key'));
    });
  });

  group('TooltipPosition', () {
    test('above exists', () {
      expect(TooltipPosition.above, isNotNull);
    });

    test('below exists', () {
      expect(TooltipPosition.below, isNotNull);
    });

    test('has exactly two values', () {
      expect(TooltipPosition.values.length, equals(2));
    });
  });

  group('Tooltip integration', () {
    test('tooltip wrapping a Button', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tooltip(
          message: 'Click to submit',
          show: true,
          child: Button(label: 'Submit', onPressed: () => null),
        ),
      );

      expect(tester.find.text('Click to submit'), isTrue);
      expect(tester.find.text('Submit'), isTrue);
    });

    test('tooltip wrapping a Button shows on hover', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tooltip(
          message: 'Hover button tip',
          child: Button(label: 'Submit', onPressed: () => null),
        ),
      );

      expect(tester.find.text('Hover button tip'), isFalse);
      final target = tester.locateText('Submit');
      expect(target, isNotNull);

      tester.mouseMove(target!.x, target.y);

      expect(tester.find.text('Hover button tip'), isTrue);
    });

    test('tooltip inside a Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Tooltip(message: 'First tip', show: true, child: Text('First')),
            Tooltip(message: 'Second tip', child: Text('Second')),
          ],
        ),
      );

      expect(tester.find.text('First tip'), isTrue);
      expect(tester.find.text('First'), isTrue);
      expect(tester.find.text('Second'), isTrue);
      // Second tooltip not shown (no show=true, not hovered)
      expect(tester.find.text('Second tip'), isFalse);
    });
  });
}
