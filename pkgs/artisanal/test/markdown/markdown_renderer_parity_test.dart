import 'package:artisanal/artisanal.dart';
import 'package:artisanal/src/tui/markdown/ansi_renderer.dart' as legacy;
import 'package:artisanal/src/tui/markdown/backend.dart' as markdown_backend;
import 'package:artisanal/src/tui/markdown/renderer.dart' as modern;
import 'package:test/test.dart';

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
  });
}
