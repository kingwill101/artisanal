import 'package:artisanal/artisanal.dart';
import 'package:artisanal/src/tui/markdown/ansi_renderer.dart' as legacy;
import 'package:artisanal/src/tui/markdown/backend.dart' as markdown_backend;
import 'package:artisanal/src/tui/markdown/renderer.dart' as modern;
import 'package:test/test.dart';
import 'package:ultraviolet/rendering.dart';

void main() {
  group('MarkdownRenderer parity', () {
    final samples = <String>[
      '# Heading',
      'Plain text paragraph.',
      'This is **bold** and *italic* with `code`.',
      '- Item 1\n- Item 2',
      '1. First\n2. Second',
      '- Parent\n  - Child A\n  - Child B',
      '> Quote line',
      '```dart\nvoid main() {}\n```',
      '| A | B |\n| - | - |\n| 1 | 2 |',
      '<details>\n<summary>Release notes</summary>\nBody\n</details>',
      '- [ ] Todo item\n- [x] Done item',
      '![Alt](https://example.com/image.png)',
    ];

    for (final sample in samples) {
      test('matches legacy output for sample: ${sample.split("\n").first}', () {
        final options = AnsiRendererOptions(width: 80);
        final nodes = markdown_backend.parseMarkdownNodes(sample);
        final legacyOutput = legacy.AnsiRenderer(
          options: options,
        ).render(nodes);
        final modernOutput = modern.MarkdownRenderer(
          options: options,
        ).render(nodes);
        expect(modernOutput, legacyOutput);
      });
    }

    test(
      'balances multiline code pen state without coloring gutters or After',
      () {
        for (final border in [false, true]) {
          for (final source in [
            '```\nplain one\nplain two\n```\n\nAfter',
            '```dart\n/* comment one\ncomment two */\n```\n\nAfter',
            '```dart\n"string one\nstring two"\n```\n\nAfter',
          ]) {
            final options = AnsiRendererOptions(
              codeBlockBorder: border,
              codeBlockStyle: Style().background(Colors.blue),
            );
            final nodes = markdown_backend.parseMarkdownNodes(source);
            final outputs = [
              legacy.AnsiRenderer(options: options).render(nodes),
              modern.MarkdownRenderer(options: options).render(nodes),
            ];

            for (final output in outputs) {
              final screen = ScreenBuffer(80, 20);
              StyledString(output).draw(screen, screen.bounds());
              final firstRow = _rowContaining(screen, 'one');
              final secondRow = _rowContaining(screen, 'two');
              final firstCode = screen.cellAt(
                _columnContaining(screen, firstRow, 'one'),
                firstRow,
              )!;
              final secondCode = screen.cellAt(
                _columnContaining(screen, secondRow, 'two'),
                secondRow,
              )!;
              expect(firstCode.style.isZero, isFalse);
              expect(secondCode.style, firstCode.style);

              if (border) {
                // The space between the left rail and code is a gutter.
                expect(screen.cellAt(1, firstRow)!.style.bg, isNull);
                expect(screen.cellAt(1, secondRow)!.style.bg, isNull);
              }
              final afterRow = _rowContaining(screen, 'After');
              expect(screen.cellAt(0, afterRow)!.style.isZero, isTrue);
            }
          }
        }
      },
    );
  });
}

int _rowContaining(ScreenBuffer screen, String text) {
  for (var y = 0; y < screen.height(); y++) {
    final row = StringBuffer();
    for (var x = 0; x < screen.width(); x++) {
      row.write(screen.cellAt(x, y)?.content ?? ' ');
    }
    if (row.toString().contains(text)) return y;
  }
  fail('Could not find "$text" in rendered screen');
}

int _columnContaining(ScreenBuffer screen, int row, String text) {
  for (var x = 0; x < screen.width(); x++) {
    var matches = true;
    for (var i = 0; i < text.length; i++) {
      if (screen.cellAt(x + i, row)?.content != text[i]) {
        matches = false;
        break;
      }
    }
    if (matches) return x;
  }
  fail('Could not find "$text" on rendered row $row');
}
