import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ProgressIndicator
  // ---------------------------------------------------------------------------
  group('ProgressIndicator', () {
    test('at 0% renders all track chars, no fill chars', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ProgressIndicator(value: 0.0, width: 10));

      expect(tester.view, isNotEmpty);
      // ANSI-stripped view should contain 10 track chars and no fill chars.
      final loc = tester.locateText('----------');
      expect(loc, isNotNull, reason: 'Should contain 10 track chars');
      expect(
        tester.locateText('#'),
        isNull,
        reason: 'Should have no fill chars at 0%',
      );
    });

    test('at 100% renders all fill chars, no track chars', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ProgressIndicator(value: 1.0, width: 10));

      expect(tester.view, isNotEmpty);
      final loc = tester.locateText('##########');
      expect(loc, isNotNull, reason: 'Should contain 10 fill chars');
      expect(
        tester.locateText('-'),
        isNull,
        reason: 'Should have no track chars at 100%',
      );
    });

    test('at 50% renders half filled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ProgressIndicator(value: 0.5, width: 10));

      expect(tester.view, isNotEmpty);
      // 50% of 10 = 5 fill chars and 5 track chars.
      final loc = tester.locateText('#####-----');
      expect(loc, isNotNull, reason: 'Should have 5 fill + 5 track chars');
    });

    test('with custom fillChar and trackChar', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(value: 0.5, width: 10, fillChar: '=', trackChar: '.'),
      );

      expect(tester.view, isNotEmpty);
      final loc = tester.locateText('=====.....');
      expect(loc, isNotNull, reason: 'Should use custom fill/track chars');
    });

    test('showLabel=true shows percentage', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(value: 0.75, width: 20, showLabel: true),
      );

      expect(tester.view, isNotEmpty);
      // 75% label should appear.
      final loc = tester.locateText('75%');
      expect(loc, isNotNull, reason: 'Should show 75% label');
    });

    test('with custom label text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(value: 0.3, width: 10, label: 'Loading...'),
      );

      expect(tester.view, isNotEmpty);
      final loc = tester.locateText('Loading...');
      expect(loc, isNotNull, reason: 'Should show custom label');
    });

    test('clamps value > 1.0 to 1.0', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ProgressIndicator(value: 2.0, width: 10));

      expect(tester.view, isNotEmpty);
      // Clamped to 1.0: all fill chars.
      final loc = tester.locateText('##########');
      expect(loc, isNotNull, reason: 'value > 1.0 should clamp to full bar');
      expect(
        tester.locateText('-'),
        isNull,
        reason: 'Should have no track chars when clamped to 1.0',
      );
    });

    test('clamps value < 0.0 to 0.0', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ProgressIndicator(value: -0.5, width: 10));

      expect(tester.view, isNotEmpty);
      // Clamped to 0.0: all track chars.
      final loc = tester.locateText('----------');
      expect(loc, isNotNull, reason: 'value < 0.0 should clamp to empty bar');
      expect(
        tester.locateText('#'),
        isNull,
        reason: 'Should have no fill chars when clamped to 0.0',
      );
    });

    test('has unique id', () {
      final p1 = ProgressIndicator(value: 0.5);
      final p2 = ProgressIndicator(value: 0.5);
      expect(p1.id, isNot(equals(p2.id)));
    });

    test('respects key', () {
      final p = ProgressIndicator(key: ValueKey('progress-key'), value: 0.5);
      expect(p.id, equals('progress-key'));
    });
  });

  // ---------------------------------------------------------------------------
  // Badge
  // ---------------------------------------------------------------------------
  group('Badge', () {
    test('renders label text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Badge('NEW'));

      expect(tester.view, isNotEmpty);
      final loc = tester.locateText('NEW');
      expect(loc, isNotNull, reason: 'Badge should render its label');
    });

    test('renders with custom label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Badge('v2.0'));

      expect(tester.view, isNotEmpty);
      final loc = tester.locateText('v2.0');
      expect(loc, isNotNull, reason: 'Badge should render "v2.0"');
    });

    test('has unique id', () {
      final b1 = Badge('alpha');
      final b2 = Badge('beta');
      expect(b1.id, isNot(equals(b2.id)));
    });

    test('respects key', () {
      final b = Badge('tagged', key: ValueKey('badge-key'));
      expect(b.id, equals('badge-key'));
    });

    test('width includes label and padding', () {
      final b = Badge('OK');
      // "OK" = 2 + left 1 + right 1 = 4
      expect(b.width, equals(4));
    });

    test('width with per-side padding', () {
      final b = Badge('AB', paddingLeft: 3, paddingRight: 2);
      // "AB" = 2 + 3 + 2 = 7
      expect(b.width, equals(7));
    });

    test('width with empty label', () {
      final b = Badge('');
      expect(b.width, equals(2)); // 0 + 1 + 1
    });

    test('width with zero padding via EdgeInsets', () {
      final b = Badge('X', padding: EdgeInsets.zero);
      expect(b.width, equals(1)); // 1 + 0 + 0
    });

    test('paddingLeft overrides padding left side', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Badge(
          'X',
          paddingLeft: 3,
          padding: EdgeInsets.symmetric(horizontal: 1),
        ),
      );

      expect(tester.locateText('X'), isNotNull);
    });

    test('paddingRight overrides padding right side', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Badge(
          'X',
          paddingRight: 3,
          padding: EdgeInsets.symmetric(horizontal: 1),
        ),
      );

      expect(tester.locateText('X'), isNotNull);
    });

    test('renders inside a Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Text('Status:'), Badge('Active')]),
      );

      expect(tester.locateText('Status:'), isNotNull);
      expect(tester.locateText('Active'), isNotNull);
    });

    test('badge in Row renders its own background fill', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Row(children: [Badge('NEW')]));

      final line = tester.view
          .split('\n')
          .firstWhere((entry) => entry.contains('NEW'));
      final before = line.substring(0, line.indexOf('NEW'));
      final bgCodeCount = RegExp(r'48;').allMatches(before).length;
      expect(bgCodeCount, greaterThanOrEqualTo(1), reason: line);
    });
  });

  // ---------------------------------------------------------------------------
  // AlertBox
  // ---------------------------------------------------------------------------
  group('AlertBox', () {
    test('renders message text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AlertBox(message: 'Something happened'));

      expect(tester.view, isNotEmpty);
      final loc = tester.locateText('Something happened');
      expect(loc, isNotNull, reason: 'AlertBox should render its message');
    });

    test('renders title text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AlertBox(title: 'Heads up!', message: 'Please read this.'),
      );

      expect(tester.view, isNotEmpty);
      final titleLoc = tester.locateText('Heads up!');
      expect(titleLoc, isNotNull, reason: 'AlertBox should render its title');
      final msgLoc = tester.locateText('Please read this.');
      expect(msgLoc, isNotNull, reason: 'AlertBox should render its message');
    });

    test('info variant shows "i" marker', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AlertBox(variant: AlertVariant.info, message: 'Info alert'),
      );

      expect(tester.view, isNotEmpty);
      // The marker 'i' appears in the ANSI-stripped view.
      final markerLoc = tester.locateText('i');
      expect(markerLoc, isNotNull, reason: 'Info variant should show "i"');
      expect(tester.locateText('Info alert'), isNotNull);
    });

    test('success variant shows "+" marker', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AlertBox(variant: AlertVariant.success, message: 'Done!'),
      );

      expect(tester.view, isNotEmpty);
      final markerLoc = tester.locateText('+');
      expect(markerLoc, isNotNull, reason: 'Success variant should show "+"');
      expect(tester.locateText('Done!'), isNotNull);
    });

    test('warning variant shows "!" marker', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AlertBox(variant: AlertVariant.warning, message: 'Caution'),
      );

      expect(tester.view, isNotEmpty);
      final markerLoc = tester.locateText('!');
      expect(markerLoc, isNotNull, reason: 'Warning variant should show "!"');
      expect(tester.locateText('Caution'), isNotNull);
    });

    test('error variant shows "x" marker', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AlertBox(variant: AlertVariant.error, message: 'Failed'),
      );

      expect(tester.view, isNotEmpty);
      final markerLoc = tester.locateText('x');
      expect(markerLoc, isNotNull, reason: 'Error variant should show "x"');
      expect(tester.locateText('Failed'), isNotNull);
    });

    test('neutral variant shows "*" marker', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AlertBox(variant: AlertVariant.neutral, message: 'Note'),
      );

      expect(tester.view, isNotEmpty);
      final markerLoc = tester.locateText('*');
      expect(markerLoc, isNotNull, reason: 'Neutral variant should show "*"');
      expect(tester.locateText('Note'), isNotNull);
    });

    test('with child widget renders child instead of message', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AlertBox(
          variant: AlertVariant.info,
          child: Text('Custom child content'),
        ),
      );

      expect(tester.view, isNotEmpty);
      final loc = tester.locateText('Custom child content');
      expect(loc, isNotNull, reason: 'AlertBox should render its child widget');
    });

    test('has unique id', () {
      final a1 = AlertBox(message: 'one');
      final a2 = AlertBox(message: 'two');
      expect(a1.id, isNot(equals(a2.id)));
    });

    test('respects key', () {
      final a = AlertBox(key: ValueKey('alert-key'), message: 'keyed');
      expect(a.id, equals('alert-key'));
    });

    test('AlertVariant enum values exist', () {
      expect(AlertVariant.values, hasLength(5));
      expect(AlertVariant.values, contains(AlertVariant.info));
      expect(AlertVariant.values, contains(AlertVariant.success));
      expect(AlertVariant.values, contains(AlertVariant.warning));
      expect(AlertVariant.values, contains(AlertVariant.error));
      expect(AlertVariant.values, contains(AlertVariant.neutral));
    });
  });
}
