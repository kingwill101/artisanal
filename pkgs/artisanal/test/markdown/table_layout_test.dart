import 'package:artisanal/markdown.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/src/tui/markdown/backend.dart' as backend;
import 'package:test/test.dart';

void main() {
  for (final modern in [false, true]) {
    group(modern ? 'MarkdownRenderer tables' : 'AnsiRenderer tables', () {
      String render(String source, {int? width = 32}) {
        final options = AnsiRendererOptions(width: width);
        return modern
            ? MarkdownRenderer(options: options).renderToAnsi(source)
            : AnsiRenderer(
                options: options,
              ).render(backend.parseMarkdownNodes(source));
      }

      void fits(String output, int width) {
        for (final line in output.split('\n')) {
          expect(
            Style.visibleLength(line),
            lessThanOrEqualTo(width),
            reason: Style.stripAnsi(line),
          );
        }
      }

      const wide = '''
| Name | State | Notes |
| --- | :---: | ---: |
| alpha | **ready** | A long note with many words and a visible TAIL |
| beta | idle | short |
''';

      test('wraps wide rows without clipping content or border', () {
        final output = render(wide);
        fits(output, 32);
        final plain = Style.stripAnsi(output);
        expect(plain, contains('TAIL'));
        expect(plain, contains('alpha'));
        expect(plain, contains('ready'));
        expect(plain.trimRight(), endsWith('╯'));
      });

      test(
        'wraps headers and unbroken cell text without dropping characters',
        () {
          final output = render(
            '| LongHeaderName |\n| --- |\n| abcdefghijklmnopqrstuvwxyz |',
            width: 12,
          );
          fits(output, 12);
          final content = Style.stripAnsi(
            output,
          ).replaceAll(RegExp(r'[\s│╭╮╰╯─├┤┬┴┼]'), '');
          expect(content, 'LongHeaderNameabcdefghijklmnopqrstuvwxyz');
        },
      );

      test(
        'retains center and right alignment with an implicit left column',
        () {
          final output = render(
            '| L | Mid | Right |\n| --- | :---: | ---: |\n| x | y | z |',
            width: null,
          );
          expect(
            Style.stripAnsi(output).split('\n'),
            contains('│ x │  y  │     z │'),
          );
        },
      );

      test('deducts nested quote prefixes before table layout', () {
        final quoted = wide
            .trimRight()
            .split('\n')
            .map((line) => '> > $line')
            .join('\n');
        final output = render(quoted);
        fits(output, 32);
        for (final line in Style.stripAnsi(output).trimRight().split('\n')) {
          expect(line, startsWith('│ │ '));
        }
        expect(Style.stripAnsi(output), contains('TAIL'));
      });

      test('keeps a table atomic and indented inside a list item', () {
        final source =
            '1. BEFORE\n\n'
            '${wide.trimRight().split('\n').map((line) => '   $line').join('\n')}\n\n'
            '   AFTER\n\n2. NEXT';
        for (final width in <int?>[32, null]) {
          final output = render(source, width: width);
          if (width != null) fits(output, width);
          final plain = Style.stripAnsi(output);
          expect(plain, contains('BEFORE'));
          expect(plain, contains('TAIL'));
          expect(plain, contains('AFTER'));
          expect(plain.indexOf('BEFORE'), lessThan(plain.indexOf('╭')));
          expect(plain.lastIndexOf('╯'), lessThan(plain.indexOf('AFTER')));
          for (final line in plain.split('\n')) {
            if (line.contains('│') ||
                line.contains('╭') ||
                line.contains('╯')) {
              expect(line, startsWith('   '), reason: line);
            }
          }
        }
      });

      test('falls back to readable fields when a grid cannot fit', () {
        final output = render(
          '| Name | State |\n| --- | --- |\n| Ada | ready |',
          width: 4,
        );
        fits(output, 4);
        final content = Style.stripAnsi(output).replaceAll(RegExp(r'\s'), '');
        expect(content, contains('Name:Ada'));
        expect(content, contains('State:ready'));
      });

      test('preserves Unicode widths and hyperlinks through cell wrapping', () {
        final output = render(
          '| Label | Value |\n| --- | --- |\n'
          '| 界 | [界界界界界界](https://example.test/path) |',
          width: 18,
        );
        fits(output, 18);
        expect(
          Style.stripAnsi(output).runes.where((r) => r == 0x754c),
          hasLength(7),
        );
        expect(output, contains('https://example.test/path'));
      });

      test('preserves headerless and ragged HTML rows at tiny widths', () {
        final output = render(
          '<table><thead><tr><th>Name</th></tr></thead><tbody>'
          '<tr><td>Ada</td><td>TAIL</td></tr></tbody></table>',
          width: 4,
        );
        fits(output, 4);
        final plain = Style.stripAnsi(output).replaceAll(RegExp(r'\s'), '');
        expect(plain, contains('Name:Ada'));
        expect(plain, contains('Column2:TAIL'));
        final headerless = render(
          '<table><tr><td>A</td><td>B</td></tr><tr><td>C</td></tr></table>',
          width: 8,
        );
        fits(headerless, 8);
        expect(Style.stripAnsi(headerless), contains('C'));
      });
    });
  }
}
