import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Text', () {
    test('renders plain text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Text('Hello World'));
      expect(tester.find.text('Hello World'), isTrue);
    });

    test('renders empty string', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Text(''));
      expect(tester.view.trim(), isEmpty);
    });

    test('applies style to text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final style = Style().bold();
      await tester.pumpWidget(Text('Bold Text', style: style));

      expect(tester.find.text('Bold Text'), isTrue);
      final view = tester.view;
      expect(view, contains('['));
    });

    test('respects textAlign left', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Text('Left', textAlign: TextAlign.left));
      expect(tester.find.text('Left'), isTrue);
    });

    test('respects textAlign center', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 20,
          child: Text('Center', textAlign: TextAlign.center),
        ),
      );
      expect(tester.find.text('Center'), isTrue);
    });

    test('respects textAlign right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(width: 20, child: Text('Right', textAlign: TextAlign.right)),
      );
      expect(tester.find.text('Right'), isTrue);
    });

    test('handles softWrap true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text('VeryLongTextThatMightNeedWrapping', softWrap: true),
      );
      expect(tester.find.text('VeryLongTextThatMightNeedWrapping'), isTrue);
    });

    test('handles softWrap false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Text('VeryLongText', softWrap: false));
      expect(tester.find.text('VeryLongText'), isTrue);
    });

    test('handles overflow clip', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 10,
          child: Text(
            'This is a very long text that exceeds the width',
            overflow: TextOverflow.clip,
          ),
        ),
      );
      expect(tester.find.text('This is'), isTrue);
    });

    test('handles overflow ellipsis with maxWidth', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Text with maxWidth: 10 and overflow ellipsis truncates to 10 columns
      await tester.pumpWidget(
        Text(
          'This is a very long text',
          overflow: TextOverflow.ellipsis,
          maxWidth: 10,
        ),
      );
      // Should be truncated: 7 chars + '...' = 10
      expect(tester.locateText('This is...'), isNotNull);
      // Full text should NOT appear
      expect(tester.locateText('This is a very long text'), isNull);
    });

    test('overflow ellipsis without maxWidth is a no-op', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Without maxWidth, ellipsis has no width constraint to truncate against
      await tester.pumpWidget(
        Text('Short text', overflow: TextOverflow.ellipsis),
      );
      // Text renders fully since there's no maxWidth
      expect(tester.locateText('Short text'), isNotNull);
    });

    test('renders rich text with TextSpan', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text.rich(
          TextSpan(
            text: 'Hello ',
            children: [TextSpan(text: 'World', style: Style().bold())],
          ),
        ),
      );
      // Each span is independently styled with ANSI codes, so find.text
      // (which checks raw view with ANSI codes) won't find the combined
      // plain string. Use locateText which strips ANSI before searching.
      final pos = tester.locateText('Hello World');
      expect(pos, isNotNull);
    });

    test('renders nested TextSpans', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text.rich(
          TextSpan(
            text: 'A',
            children: [
              TextSpan(
                text: 'B',
                children: [TextSpan(text: 'C')],
              ),
            ],
          ),
        ),
      );
      expect(tester.find.text('ABC'), isTrue);
    });

    test('renders TextSpan with base style', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text.rich(TextSpan(style: Style().italic(), text: 'Italic')),
      );
      expect(tester.find.text('Italic'), isTrue);
    });

    test('has no children', () async {
      final text = Text('test');
      expect(text.children, isEmpty);
    });

    test('is not focusable', () async {
      final text = Text('test');
      expect(text.focusable, isFalse);
    });

    test('has unique id', () {
      final t1 = Text('a');
      final t2 = Text('b');
      expect(t1.id, isNot(equals(t2.id)));
    });

    test('respects key', () {
      final text = Text('test', key: ValueKey('my-key'));
      expect(text.id, equals('my-key'));
    });
  });

  group('Text integration', () {
    test('Text in Column layout', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(children: [Text('Line 1'), Text('Line 2'), Text('Line 3')]),
      );

      expect(tester.find.text('Line 1'), isTrue);
      expect(tester.find.text('Line 2'), isTrue);
      expect(tester.find.text('Line 3'), isTrue);
    });

    test('Text in Row layout', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Row(children: [Text('A'), Text('B'), Text('C')]));

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
      expect(tester.find.text('C'), isTrue);
    });

    test('styled Text in Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          padding: EdgeInsets.all(1),
          child: Text('Content', style: Style().foreground(Colors.red)),
        ),
      );

      expect(tester.find.text('Content'), isTrue);
    });

    test('multi-line Text rendering', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(width: 10, child: Text('Line1\nLine2\nLine3')),
      );

      final lines = tester.viewLines;
      expect(lines.length, greaterThanOrEqualTo(3));
    });
  });
}
