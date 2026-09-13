import 'package:artisanal/src/tui/markdown/ansi_renderer.dart';
import 'package:artisanal/src/tui/markdown/backend.dart' as backend;
import 'package:artisanal/src/tui/markdown/renderer.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:test/test.dart';

void main() {
  const source = '''
- **901 tests passed; 3 existing tests skipped** ...:
  ```sh
  dart test...
  ```
- Targeted...
''';

  for (final entry in <(String, String Function())>[
    (
      'AnsiRenderer',
      () => AnsiRenderer().render(backend.parseMarkdownNodes(source)),
    ),
    ('MarkdownRenderer', () => MarkdownRenderer().renderToAnsi(source)),
  ]) {
    for (final width in <int?>[null, 24, 80]) {
      for (final quoted in [false, true]) {
        test(
          '${entry.$1} composes nested task code at $width, quoted $quoted',
          () {
            const nested = '''
98. outer

    - [x] before

      ```txt
      nested
      ```

      after
''';
            final input = quoted
                ? nested.split('\n').map((line) => '> $line').join('\n')
                : nested;
            final options = AnsiRendererOptions(width: width);
            final output = Style.stripAnsi(
              entry.$1 == 'AnsiRenderer'
                  ? AnsiRenderer(
                      options: options,
                    ).render(backend.parseMarkdownNodes(input))
                  : MarkdownRenderer(options: options).renderToAnsi(input),
            );
            final prefix = quoted ? '│ ' : '';
            expect(output.split('\n'), contains('$prefix  [x] before'));
            expect(output.split('\n'), contains('$prefix      │ nested'));
            expect(output.split('\n'), contains('$prefix      after'));
          },
        );
      }
    }

    test('${entry.$1} keeps fenced code inside its list item', () {
      final output = Style.stripAnsi(entry.$2());
      final paragraph = output.indexOf('901 tests passed');
      final top = output.indexOf('╭─ sh');
      final command = output.indexOf('dart test...');
      final bottom = output.indexOf('╰───');
      final nextItem = output.indexOf('Targeted...');

      expect(paragraph, greaterThanOrEqualTo(0));
      expect(top, greaterThan(paragraph));
      expect(command, greaterThan(top));
      expect(bottom, greaterThan(command));
      expect(nextItem, greaterThan(bottom));

      final codeLines = output
          .split('\n')
          .where((line) => line.contains('dart test...'))
          .toList();
      expect(codeLines, hasLength(1));
      expect(codeLines.single, '  │ dart test...');
      expect(
        output.split('\n').any((line) => line.startsWith('  ╭─ sh')),
        isTrue,
      );
      expect(
        output.split('\n').any((line) => line.startsWith('  ╰───')),
        isTrue,
      );
    });

    test(
      '${entry.$1} preserves code line widths while wrapping list prose',
      () {
        final output = Style.stripAnsi(
          entry.$1 == 'AnsiRenderer'
              ? AnsiRenderer(
                  options: const AnsiRendererOptions(width: 30),
                ).render(backend.parseMarkdownNodes(source))
              : MarkdownRenderer(
                  options: const AnsiRendererOptions(width: 30),
                ).renderToAnsi(source),
        );
        expect(output.split('\n'), contains('  │ dart test...'));
        expect(output, contains('Targeted...'));
      },
    );

    for (final sample in [
      (marker: '- ', prefix: '• ', sourceIndent: 2, outputIndent: 2),
      (marker: '98. ', prefix: '98. ', sourceIndent: 4, outputIndent: 4),
      (marker: '- [x] ', prefix: '[x] ', sourceIndent: 2, outputIndent: 4),
    ]) {
      for (final width in <int?>[null, 24, 80]) {
        for (final border in [false, true]) {
          test(
            '${entry.$1} resumes ${sample.marker}prose at width $width, border $border',
            () {
              final pad = ' ' * sample.sourceIndent;
              final input =
                  '${sample.marker}before\n\n'
                  '$pad```txt\n'
                  '${pad}aa  bb \n'
                  '$pad```\n\n'
                  '${pad}after\n';
              final options = AnsiRendererOptions(
                width: width,
                codeBlockBorder: border,
              );
              final output = Style.stripAnsi(
                entry.$1 == 'AnsiRenderer'
                    ? AnsiRenderer(
                        options: options,
                      ).render(backend.parseMarkdownNodes(input))
                    : MarkdownRenderer(options: options).renderToAnsi(input),
              );
              final lines = output.split('\n');
              expect(lines, contains('${sample.prefix}before'), reason: output);
              expect(
                lines,
                contains('${' ' * sample.outputIndent}after'),
                reason: output,
              );
              expect(
                lines,
                contains(
                  '${' ' * sample.outputIndent}${border ? '│ ' : ''}aa  bb ',
                ),
                reason: output,
              );
            },
          );
        }
      }
    }
  }
}
