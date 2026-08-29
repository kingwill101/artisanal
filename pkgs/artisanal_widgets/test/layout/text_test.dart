import 'package:artisanal/tui.dart' show Cmd, KeyMsg, Msg;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
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

    test('applies immutable textStyle to text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text(
          'Styled Text',
          textStyle: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      expect(tester.find.text('Styled Text'), isTrue);
      expect(tester.view, contains('\x1b[1m'));
    });

    test('textStyle overlays text properties while preserving Style', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text(
          'Overlay',
          style: Style().bold().italic().padding(0, 1),
          textStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      );

      expect(tester.find.text('Overlay'), isTrue);
      expect(tester.view, contains('\x1b[3m'));
      expect(tester.view, isNot(contains('\x1b[1m')));
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

    test(
      'inherits and explicitly disables nested TextSpan textStyle',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Text.rich(
            const TextSpan(
              text: 'A',
              textStyle: TextStyle(fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'B',
                  textStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );

        expect(tester.locateText('AB'), isNotNull);
        expect(tester.view, contains('\x1b[1m'));
        expect(tester.view, contains('\x1b[3m'));
      },
    );

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

    test('preserves cached view output across widget replacement', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      _CountingCachedWidget.renderCount = 0;

      await tester.pumpWidget(_CacheTransferHarness());
      tester.sendKey('r');
      tester.sendKey('c');

      expect(_CountingCachedWidget.renderCount, equals(2));
      expect(tester.find.text('changed'), isTrue);
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

class _CountingCachedWidget extends Widget {
  _CountingCachedWidget(this.label);

  final String label;
  static int renderCount = 0;

  @override
  Object view() {
    return buildCachedView(() {
      renderCount++;
      return label;
    }, label);
  }
}

class _CacheTransferHarness extends StatefulWidget {
  _CacheTransferHarness();

  @override
  State createState() => _CacheTransferHarnessState();
}

class _CacheTransferHarnessState extends State<_CacheTransferHarness> {
  var _label = 'cache-me';

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is! KeyMsg) return null;
    if (msg.key.char == 'r') {
      setState(() {});
    } else if (msg.key.char == 'c') {
      setState(() {
        _label = 'changed';
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => _CountingCachedWidget(_label);
}
