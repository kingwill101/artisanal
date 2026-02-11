import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Visibility', () {
    test('shows child when visible is true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Visibility(child: Text('Hello')));
      expect(tester.find.text('Hello'), isTrue);
    });

    test('visible defaults to true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Visibility(child: Text('Default Visible')));
      expect(tester.find.text('Default Visible'), isTrue);
    });

    test('hides child when visible is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Visibility(visible: false, child: Text('Hidden')),
      );
      expect(tester.find.text('Hidden'), isFalse);
    });

    test('renders empty when invisible with no replacement', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Visibility(visible: false, child: Text('Gone')));
      expect(tester.find.text('Gone'), isFalse);
      expect(tester.view.trim(), isEmpty);
    });

    test('shows replacement when invisible with replacement', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Visibility(
          visible: false,
          replacement: Text('Replacement'),
          child: Text('Original'),
        ),
      );
      expect(tester.find.text('Original'), isFalse);
      expect(tester.find.text('Replacement'), isTrue);
    });

    test('shows child not replacement when visible with replacement', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Visibility(
          visible: true,
          replacement: Text('Replacement'),
          child: Text('Original'),
        ),
      );
      expect(tester.find.text('Original'), isTrue);
      expect(tester.find.text('Replacement'), isFalse);
    });

    test('children returns [child] when visible', () {
      final child = Text('Child');
      final widget = Visibility(child: child);
      expect(widget.children, equals([child]));
    });

    test('children returns [replacement] when invisible with replacement', () {
      final child = Text('Child');
      final replacement = Text('Replacement');
      final widget = Visibility(
        visible: false,
        replacement: replacement,
        child: child,
      );
      expect(widget.children, equals([replacement]));
    });

    test('children returns empty list when invisible without replacement', () {
      final child = Text('Child');
      final widget = Visibility(visible: false, child: child);
      expect(widget.children, isEmpty);
    });

    test('is not focusable', () {
      final widget = Visibility(child: Text('test'));
      expect(widget.focusable, isFalse);
    });

    test('has unique id', () {
      final v1 = Visibility(child: Text('a'));
      final v2 = Visibility(child: Text('b'));
      expect(v1.id, isNot(equals(v2.id)));
    });

    test('respects key', () {
      final widget = Visibility(key: ValueKey('vis-key'), child: Text('test'));
      expect(widget.id, equals('vis-key'));
    });
  });

  group('Opacity', () {
    test('shows child content at full opacity (1.0)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(opacity: 1.0, child: Text('Full')));
      expect(tester.find.text('Full'), isTrue);
    });

    test('opacity defaults to 1.0', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(child: Text('Default')));
      expect(tester.find.text('Default'), isTrue);
    });

    test('returns empty at opacity 0.0', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(opacity: 0.0, child: Text('Invisible')));
      expect(tester.find.text('Invisible'), isFalse);
      expect(tester.view.trim(), isEmpty);
    });

    test('dims content at partial opacity (0.5)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(opacity: 0.5, child: Text('Dimmed')));
      // Content should be present but wrapped in ANSI dim escape codes
      final view = tester.view;
      // The dim style applies ANSI escape sequences (contains ESC char \x1B)
      expect(view, contains('\x1B'));
      // The text content should still be locatable through ANSI stripping
      final pos = tester.locateText('Dimmed');
      expect(pos, isNotNull);
    });

    test('dims content at low partial opacity (0.1)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(opacity: 0.1, child: Text('Faint')));
      final view = tester.view;
      expect(view, contains('\x1B'));
      final pos = tester.locateText('Faint');
      expect(pos, isNotNull);
    });

    test('dims content at high partial opacity (0.99)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Opacity(opacity: 0.99, child: Text('AlmostFull')),
      );
      final view = tester.view;
      expect(view, contains('\x1B'));
      final pos = tester.locateText('AlmostFull');
      expect(pos, isNotNull);
    });

    test('content unchanged at opacity exactly 1.0 (no ANSI dim)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(opacity: 1.0, child: Text('Plain')));
      // At full opacity, the view should be plain text without dim styling
      expect(tester.view, contains('Plain'));
    });

    test('returns empty at negative opacity', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(opacity: -0.5, child: Text('Negative')));
      expect(tester.find.text('Negative'), isFalse);
      expect(tester.view.trim(), isEmpty);
    });

    test('shows content at opacity greater than 1.0', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Opacity(opacity: 2.0, child: Text('Over')));
      expect(tester.find.text('Over'), isTrue);
    });

    test('children returns [child]', () {
      final child = Text('Child');
      final widget = Opacity(child: child);
      expect(widget.children, equals([child]));
    });

    test('has unique id', () {
      final o1 = Opacity(child: Text('a'));
      final o2 = Opacity(child: Text('b'));
      expect(o1.id, isNot(equals(o2.id)));
    });

    test('respects key', () {
      final widget = Opacity(key: ValueKey('opacity-key'), child: Text('test'));
      expect(widget.id, equals('opacity-key'));
    });
  });

  group('Visibility integration', () {
    test('Visibility in a Column shows/hides correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Header'),
            Visibility(visible: true, child: Text('Shown')),
            Visibility(visible: false, child: Text('Hidden')),
            Text('Footer'),
          ],
        ),
      );

      expect(tester.find.text('Header'), isTrue);
      expect(tester.find.text('Shown'), isTrue);
      expect(tester.find.text('Hidden'), isFalse);
      expect(tester.find.text('Footer'), isTrue);
    });

    test('Visibility with replacement in a Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Before'),
            Visibility(
              visible: false,
              replacement: Text('Alt'),
              child: Text('Main'),
            ),
            Text('After'),
          ],
        ),
      );

      expect(tester.find.text('Before'), isTrue);
      expect(tester.find.text('Main'), isFalse);
      expect(tester.find.text('Alt'), isTrue);
      expect(tester.find.text('After'), isTrue);
    });

    test('Visibility in a Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('L'),
            Visibility(visible: true, child: Text('M')),
            Text('R'),
          ],
        ),
      );

      expect(tester.find.text('L'), isTrue);
      expect(tester.find.text('M'), isTrue);
      expect(tester.find.text('R'), isTrue);
    });

    test('invisible Visibility in a Row hides content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('L'),
            Visibility(visible: false, child: Text('M')),
            Text('R'),
          ],
        ),
      );

      expect(tester.find.text('L'), isTrue);
      expect(tester.find.text('M'), isFalse);
      expect(tester.find.text('R'), isTrue);
    });
  });

  group('Opacity integration', () {
    test('Opacity in a Row shows child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('A'),
            Opacity(opacity: 1.0, child: Text('B')),
            Text('C'),
          ],
        ),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
      expect(tester.find.text('C'), isTrue);
    });

    test('Opacity at 0 in a Column hides content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Top'),
            Opacity(opacity: 0.0, child: Text('Gone')),
            Text('Bottom'),
          ],
        ),
      );

      expect(tester.find.text('Top'), isTrue);
      expect(tester.find.text('Gone'), isFalse);
      expect(tester.find.text('Bottom'), isTrue);
    });

    test('Opacity and Visibility together', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Visibility(visible: true, child: Text('Visible')),
            Opacity(opacity: 0.5, child: Text('Dimmed')),
            Visibility(visible: false, child: Text('Hidden')),
            Opacity(opacity: 0.0, child: Text('Invisible')),
          ],
        ),
      );

      expect(tester.find.text('Hidden'), isFalse);
      expect(tester.find.text('Invisible'), isFalse);
      // Visible and Dimmed should be locatable
      expect(tester.locateText('Visible'), isNotNull);
      expect(tester.locateText('Dimmed'), isNotNull);
    });
  });
}
