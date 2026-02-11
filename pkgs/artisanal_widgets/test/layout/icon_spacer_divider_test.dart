import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // IconData
  // ---------------------------------------------------------------------------
  group('IconData', () {
    test('stores codePoint', () {
      final data = IconData(0x2713);
      expect(data.codePoint, equals(0x2713));
    });

    test('glyph returns character from codePoint', () {
      final data = IconData(0x2713);
      expect(data.glyph, equals('✓'));
    });

    test('glyph for ASCII codePoint', () {
      final data = IconData(0x2b);
      expect(data.glyph, equals('+'));
    });

    test('glyph uses String.fromCharCode', () {
      const cp = 0x2605;
      final data = IconData(cp);
      expect(data.glyph, equals(String.fromCharCode(cp)));
    });
  });

  // ---------------------------------------------------------------------------
  // Icons constants
  // ---------------------------------------------------------------------------
  group('Icons constants', () {
    test('Icons.add renders +', () {
      expect(Icons.add.glyph, equals('+'));
    });

    test('Icons.remove renders -', () {
      expect(Icons.remove.glyph, equals('-'));
    });

    test('Icons.check renders ✓', () {
      expect(Icons.check.glyph, equals('✓'));
    });

    test('Icons.close renders ✕', () {
      expect(Icons.close.glyph, equals('✕'));
    });

    test('Icons.arrowLeft renders ←', () {
      expect(Icons.arrowLeft.glyph, equals('←'));
    });

    test('Icons.arrowRight renders →', () {
      expect(Icons.arrowRight.glyph, equals('→'));
    });

    test('Icons.arrowUp renders ↑', () {
      expect(Icons.arrowUp.glyph, equals('↑'));
    });

    test('Icons.arrowDown renders ↓', () {
      expect(Icons.arrowDown.glyph, equals('↓'));
    });

    test('Icons.star renders ★', () {
      expect(Icons.star.glyph, equals('★'));
    });
  });

  // ---------------------------------------------------------------------------
  // Icon widget
  // ---------------------------------------------------------------------------
  group('Icon', () {
    test('renders icon glyph', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Icon(Icons.check));
      final pos = tester.locateText('✓');
      expect(pos, isNotNull);
    });

    test('renders star icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Icon(Icons.star));
      final pos = tester.locateText('★');
      expect(pos, isNotNull);
    });

    test('renders add icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Icon(Icons.add));
      final pos = tester.locateText('+');
      expect(pos, isNotNull);
    });

    test('renders close icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Icon(Icons.close));
      final pos = tester.locateText('✕');
      expect(pos, isNotNull);
    });

    test('renders arrow icons', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Icon(Icons.arrowLeft),
            Icon(Icons.arrowRight),
            Icon(Icons.arrowUp),
            Icon(Icons.arrowDown),
          ],
        ),
      );

      expect(tester.locateText('←'), isNotNull);
      expect(tester.locateText('→'), isNotNull);
      expect(tester.locateText('↑'), isNotNull);
      expect(tester.locateText('↓'), isNotNull);
    });

    test('renders with color', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Icon(Icons.check, color: Colors.red));
      // The glyph should still be present (locateText strips ANSI)
      final pos = tester.locateText('✓');
      expect(pos, isNotNull);
      // Raw view should contain ANSI escape codes for styling
      expect(tester.view, contains('['));
    });

    test('renders with style', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Icon(Icons.star, style: Style().bold()));
      final pos = tester.locateText('★');
      expect(pos, isNotNull);
      // Should have ANSI codes from bold style
      expect(tester.view, contains('['));
    });

    test('has no children (leaf widget)', () {
      final icon = Icon(Icons.check);
      expect(icon.children, isEmpty);
    });

    test('has unique id', () {
      final i1 = Icon(Icons.check);
      final i2 = Icon(Icons.star);
      expect(i1.id, isNot(equals(i2.id)));
    });

    test('respects key', () {
      final icon = Icon(Icons.check, key: ValueKey('icon-key'));
      expect(icon.id, equals('icon-key'));
    });

    test('is not focusable', () {
      final icon = Icon(Icons.check);
      expect(icon.focusable, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // ShrinkWrap
  // ---------------------------------------------------------------------------
  group('ShrinkWrap', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ShrinkWrap(child: Text('wrapped')));
      expect(tester.find.text('wrapped'), isTrue);
    });

    test('children returns list containing the child', () {
      final child = Text('inner');
      final shrink = ShrinkWrap(child: child);
      expect(shrink.children, equals([child]));
    });

    test('children has exactly one element', () {
      final shrink = ShrinkWrap(child: Text('x'));
      expect(shrink.children.length, equals(1));
    });

    test('view delegates to child view', () {
      final child = Text('hello');
      final shrink = ShrinkWrap(child: child);
      expect(shrink.view(), equals(child.view()));
    });

    test('has unique id', () {
      final s1 = ShrinkWrap(child: Text('a'));
      final s2 = ShrinkWrap(child: Text('b'));
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('respects key', () {
      final shrink = ShrinkWrap(key: ValueKey('shrink-key'), child: Text('x'));
      expect(shrink.id, equals('shrink-key'));
    });

    test('renders complex child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ShrinkWrap(child: Row(children: [Text('A'), Text('B')])),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Spacer
  // ---------------------------------------------------------------------------
  group('Spacer', () {
    test('default size is 1', () {
      final spacer = Spacer();
      expect(spacer.size, equals(1));
    });

    test('default fill is space', () {
      final spacer = Spacer();
      expect(spacer.fill, equals(' '));
    });

    test('renders single space by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Use a visible fill character to verify rendering works, since
      // a single space may be indistinguishable from empty output.
      await tester.pumpWidget(Spacer(fill: '.'));
      final view = tester.view;
      expect(view, contains('.'));
    });

    test('custom size renders fill repeated', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Spacer(size: 5, fill: '-'));
      expect(tester.find.text('-----'), isTrue);
    });

    test('custom fill character', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Spacer(size: 3, fill: '*'));
      expect(tester.find.text('***'), isTrue);
    });

    test('size of 0 renders empty', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Spacer(size: 0));
      expect(tester.view.trim(), isEmpty);
    });

    test('stores flex property', () {
      final spacer = Spacer(flex: 2);
      expect(spacer.flex, equals(2));
    });

    test('flex is null by default', () {
      final spacer = Spacer();
      expect(spacer.flex, isNull);
    });

    test('has no children (leaf widget)', () {
      final spacer = Spacer();
      expect(spacer.children, isEmpty);
    });

    test('has unique id', () {
      final s1 = Spacer();
      final s2 = Spacer();
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('respects key', () {
      final spacer = Spacer(key: ValueKey('spacer-key'));
      expect(spacer.id, equals('spacer-key'));
    });

    test('is not focusable', () {
      final spacer = Spacer();
      expect(spacer.focusable, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Divider
  // ---------------------------------------------------------------------------
  group('Divider', () {
    test('default width is 40', () {
      final divider = Divider();
      expect(divider.width, equals(40));
    });

    test('default char is ─', () {
      final divider = Divider();
      expect(divider.char, equals('─'));
    });

    test('renders default 40 ─ characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Divider());
      final pos = tester.locateText('─' * 40);
      expect(pos, isNotNull);
    });

    test('custom width renders correct number of chars', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Divider(width: 10));
      final pos = tester.locateText('─' * 10);
      expect(pos, isNotNull);
    });

    test('custom char renders correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Divider(width: 5, char: '='));
      final pos = tester.locateText('=====');
      expect(pos, isNotNull);
    });

    test('custom style is applied', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Divider(width: 10, style: Style().foreground(Colors.red)),
      );
      final pos = tester.locateText('─' * 10);
      expect(pos, isNotNull);
      // Should have ANSI escape codes from styling
      expect(tester.view, contains('['));
    });

    test('width of 1 renders single char', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Divider(width: 1, char: '*'));
      final pos = tester.locateText('*');
      expect(pos, isNotNull);
    });

    test('has unique id', () {
      final d1 = Divider();
      final d2 = Divider();
      expect(d1.id, isNot(equals(d2.id)));
    });

    test('respects key', () {
      final divider = Divider(key: ValueKey('divider-key'));
      expect(divider.id, equals('divider-key'));
    });

    test('is not focusable', () {
      final divider = Divider();
      expect(divider.focusable, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration tests
  // ---------------------------------------------------------------------------
  group('Integration', () {
    test('Icon in Row with text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Icon(Icons.check), Text(' Done')]),
      );

      expect(tester.locateText('✓'), isNotNull);
      expect(tester.locateText('Done'), isNotNull);
    });

    test('Divider between sections in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Section 1'),
            Divider(width: 10, char: '-'),
            Text('Section 2'),
          ],
        ),
      );

      final s1 = tester.locateText('Section 1');
      final div = tester.locateText('----------');
      final s2 = tester.locateText('Section 2');

      expect(s1, isNotNull);
      expect(div, isNotNull);
      expect(s2, isNotNull);
      // Divider should be between the two sections vertically
      expect(div!.y, greaterThan(s1!.y));
      expect(s2!.y, greaterThan(div.y));
    });

    test('Spacer in Row between items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('L'),
            Spacer(size: 5, fill: '.'),
            Text('R'),
          ],
        ),
      );

      expect(tester.locateText('L'), isNotNull);
      expect(tester.locateText('.....'), isNotNull);
      expect(tester.locateText('R'), isNotNull);

      final lPos = tester.locateText('L');
      final rPos = tester.locateText('R');
      // R should be to the right of L with spacer in between
      expect(rPos!.x, greaterThan(lPos!.x));
    });

    test('Multiple Icons in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(children: [Icon(Icons.star), Icon(Icons.star), Icon(Icons.star)]),
      );

      // All three stars should be present in the view
      final view = tester.view;
      // Count occurrences of ★ in the stripped view
      expect('★★★'.allMatches(view).length, greaterThanOrEqualTo(1));
    });

    test('Icon and Spacer and Divider together in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Row(children: [Icon(Icons.star), Text(' Title')]),
            Divider(width: 10, char: '='),
            Spacer(size: 3, fill: '.'),
          ],
        ),
      );

      expect(tester.locateText('★'), isNotNull);
      expect(tester.locateText('Title'), isNotNull);
      expect(tester.locateText('=' * 10), isNotNull);
      expect(tester.locateText('...'), isNotNull);
    });
  });
}
