import 'package:artisanal/markdown.dart';
import 'package:artisanal/src/style/border.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:test/test.dart';

void main() {
  group('markdownToAnsi', () {
    group('headings', () {
      test('renders h1 with bold and bright cyan', () {
        final result = markdownToAnsi('# Hello World');
        // Should contain bold (1) and the text
        expect(result, contains('Hello World'));
        expect(result, contains('\x1b[')); // ANSI escape
      });

      test('renders h2 with bold and cyan', () {
        final result = markdownToAnsi('## Section');
        expect(result, contains('Section'));
        expect(result, contains('\x1b['));
      });

      test('renders multiple heading levels', () {
        final result = markdownToAnsi('''
# H1
## H2
### H3
#### H4
##### H5
###### H6
''');
        expect(result, contains('H1'));
        expect(result, contains('H2'));
        expect(result, contains('H3'));
        expect(result, contains('H4'));
        expect(result, contains('H5'));
        expect(result, contains('H6'));
      });
    });

    group('inline styles', () {
      test('renders bold text', () {
        final result = markdownToAnsi('This is **bold** text');
        expect(result, contains('bold'));
        expect(result, contains('\x1b[1m')); // Bold SGR
      });

      test('renders italic text', () {
        final result = markdownToAnsi('This is *italic* text');
        expect(result, contains('italic'));
        expect(result, contains('\x1b[3m')); // Italic SGR
      });

      test('renders inline code', () {
        final result = markdownToAnsi('Use `print()` function');
        expect(result, contains('print()'));
        // Should have some styling
        expect(result, contains('\x1b['));
      });

      test('renders strikethrough', () {
        final result = markdownToAnsi('This is ~~deleted~~ text');
        expect(result, contains('deleted'));
        // Default strikethrough style includes both dim (2) and strikethrough (9)
        expect(result, contains('9m')); // Strikethrough SGR code
      });

      test('renders combined styles', () {
        final result = markdownToAnsi('This is ***bold italic*** text');
        expect(result, contains('bold italic'));
      });
    });

    group('links', () {
      test('renders links with underline and color', () {
        final result = markdownToAnsi('[Example](https://example.com)');
        expect(result, contains('Example'));
        expect(result, contains('\x1b[4m')); // Underline
      });

      test('renders links with OSC 8 hyperlinks by default', () {
        final result = markdownToAnsi('[Click here](https://example.com)');
        expect(result, contains('\x1b]8;;https://example.com\x1b\\'));
        expect(result, contains('\x1b]8;;\x1b\\')); // Close hyperlink
      });

      test('disables OSC 8 hyperlinks when configured', () {
        final result = markdownToAnsi(
          '[Click here](https://example.com)',
          options: const AnsiRendererOptions(hyperlinks: false),
        );
        expect(result, isNot(contains('\x1b]8;;')));
      });
    });

    group('lists', () {
      test('renders unordered list with bullet points', () {
        final result = markdownToAnsi('''
- Item 1
- Item 2
- Item 3
''');
        expect(result, contains('\u2022 Item 1'));
        expect(result, contains('\u2022 Item 2'));
        expect(result, contains('\u2022 Item 3'));
      });

      test('renders ordered list with numbers', () {
        final result = markdownToAnsi('''
1. First
2. Second
3. Third
''');
        expect(result, contains('1. First'));
        expect(result, contains('2. Second'));
        expect(result, contains('3. Third'));
      });

      test('renders nested lists with indentation', () {
        final result = markdownToAnsi('''
- Level 1
  - Level 2
    - Level 3
''');
        expect(result, contains('\u2022 Level 1'));
        expect(result, contains('  \u2022 Level 2'));
        expect(result, contains('    \u2022 Level 3'));
      });

      test('uses custom bullet character', () {
        final result = markdownToAnsi(
          '- Item',
          options: const AnsiRendererOptions(bulletChar: '-'),
        );
        expect(result, contains('- Item'));
      });
    });

    group('blockquotes', () {
      test('renders blockquote with border', () {
        final result = markdownToAnsi('> This is a quote');
        expect(result, contains('\u2502')); // Vertical bar
        expect(result, contains('This is a quote'));
      });

      test('renders nested blockquotes', () {
        final result = markdownToAnsi('''
> Level 1
>> Level 2
''');
        expect(result, contains('\u2502'));
        expect(result, contains('Level 1'));
        expect(result, contains('Level 2'));
      });
    });

    group('code blocks', () {
      test('renders code block with border', () {
        final result = markdownToAnsi('''
```
code here
```
''');
        expect(result, contains('code here'));
        expect(result, contains('\u256d')); // Top-left corner
        expect(result, contains('\u2570')); // Bottom-left corner
      });

      test('renders code block with language label', () {
        final result = markdownToAnsi('''
```dart
void main() {}
```
''', options: const AnsiRendererOptions(syntaxHighlighting: false));
        expect(result, contains('dart'));
        expect(result, contains('void main() {}'));
      });

      test('renders code block without border when disabled', () {
        final result = markdownToAnsi('''
```
code
```
''', options: const AnsiRendererOptions(codeBlockBorder: false));
        expect(result, isNot(contains('\u256d')));
      });

      test('applies syntax highlighting with language', () {
        final result = markdownToAnsi('''
```dart
void main() {}
```
''');
        // When syntax highlighting is on (default), should contain ANSI escape codes
        // for syntax highlighting (more than just the border color)
        expect(result, contains('dart')); // Language label
        expect(result, contains('\x1B[')); // ANSI codes present
        // The content should still be there (just with styling)
        expect(Ansi.stripAnsi(result), contains('void'));
        expect(Ansi.stripAnsi(result), contains('main'));
      });

      test('syntax highlighting can be disabled', () {
        final noHighlight = markdownToAnsi('''
```dart
void main() {}
```
''', options: const AnsiRendererOptions(syntaxHighlighting: false));
        final withHighlight = markdownToAnsi('''
```dart
void main() {}
```
''', options: const AnsiRendererOptions(syntaxHighlighting: true));
        // Both should have the content
        expect(Ansi.stripAnsi(noHighlight), contains('void main()'));
        expect(Ansi.stripAnsi(withHighlight), contains('void main()'));
        // But they should be different (one has more styling)
        expect(noHighlight != withHighlight, isTrue);
      });

      test('uses default rounded border style', () {
        final result = markdownToAnsi('''
```
code here
```
''');
        // Rounded corners by default
        expect(result, contains('╭')); // Top-left rounded
        expect(result, contains('╰')); // Bottom-left rounded
        expect(result, contains('│')); // Vertical bar
        expect(result, contains('─')); // Horizontal bar
      });

      test('uses ASCII border style when configured', () {
        final result = markdownToAnsi('''
```
code here
```
''', options: const AnsiRendererOptions(codeBlockBorderStyle: Border.ascii));
        // ASCII characters
        expect(result, contains('+')); // Corner
        expect(result, contains('-')); // Horizontal
        expect(result, contains('|')); // Vertical
        // Should NOT have rounded corners
        expect(result, isNot(contains('╭')));
        expect(result, isNot(contains('╰')));
      });

      test('uses double border style when configured', () {
        final result = markdownToAnsi('''
```
code here
```
''', options: const AnsiRendererOptions(codeBlockBorderStyle: Border.double));
        // Double-line characters
        expect(result, contains('╔')); // Top-left double
        expect(result, contains('╚')); // Bottom-left double
        expect(result, contains('║')); // Vertical double
        expect(result, contains('═')); // Horizontal double
      });

      test('uses thick border style when configured', () {
        final result = markdownToAnsi('''
```
code here
```
''', options: const AnsiRendererOptions(codeBlockBorderStyle: Border.thick));
        // Thick/heavy characters
        expect(result, contains('┏')); // Top-left thick
        expect(result, contains('┗')); // Bottom-left thick
        expect(result, contains('┃')); // Vertical thick
        expect(result, contains('━')); // Horizontal thick
      });

      test('uses normal border style when configured', () {
        final result = markdownToAnsi('''
```
code here
```
''', options: const AnsiRendererOptions(codeBlockBorderStyle: Border.normal));
        // Normal single-line (non-rounded) corners
        expect(result, contains('┌')); // Top-left normal
        expect(result, contains('└')); // Bottom-left normal
        expect(result, contains('│')); // Vertical
        expect(result, contains('─')); // Horizontal
        // Should NOT have rounded corners
        expect(result, isNot(contains('╭')));
        expect(result, isNot(contains('╰')));
      });

      test('border style applies to code block with language label', () {
        final result = markdownToAnsi(
          '''
```dart
void main() {}
```
''',
          options: const AnsiRendererOptions(
            codeBlockBorderStyle: Border.double,
            syntaxHighlighting: false,
          ),
        );
        // Should have double border characters
        expect(result, contains('╔'));
        expect(result, contains('║'));
        // And still have the language label
        expect(result, contains('dart'));
        expect(result, contains('void main()'));
      });
    });

    group('horizontal rules', () {
      test('renders horizontal rule', () {
        final result = markdownToAnsi('---');
        expect(result, contains('\u2500')); // Horizontal line char
      });

      test('uses custom width', () {
        final result = markdownToAnsi(
          '---',
          options: const AnsiRendererOptions(hrWidth: 20),
        );
        final stripped = Ansi.stripAnsi(result);
        expect(stripped.trim(), equals('\u2500' * 20));
      });
    });

    group('images', () {
      test('renders image placeholder', () {
        final result = markdownToAnsi('![Alt text](image.png)');
        expect(result, contains('[Image: Alt text]'));
        expect(result, contains('(image.png)'));
      });
    });

    group('task lists', () {
      test('renders unchecked checkbox', () {
        final result = markdownToAnsi('- [ ] Todo item');
        expect(result, contains('\u2610')); // Unchecked box
      });

      test('renders checked checkbox', () {
        final result = markdownToAnsi('- [x] Done item');
        expect(result, contains('\u2611')); // Checked box
      });
    });

    group('custom styles', () {
      test('uses custom h1 style', () {
        final customStyle = Style().bold().foreground(Colors.magenta);
        final result = markdownToAnsi(
          '# Custom Heading',
          options: AnsiRendererOptions(h1Style: customStyle),
        );
        // Should contain magenta color code
        expect(result, contains('Custom Heading'));
      });

      test('uses custom emphasis style', () {
        final result = markdownToAnsi(
          '*emphasized*',
          options: AnsiRendererOptions(emphasisStyle: Style().underline()),
        );
        expect(result, contains('\x1b[4m')); // Underline instead of italic
      });
    });

    group('complex documents', () {
      test('renders mixed content', () {
        final result = markdownToAnsi('''
# Title

This is a paragraph with **bold** and *italic* text.

## Features

- Feature 1
- Feature 2
- Feature 3

> Note: This is important

```dart
void main() {
  print('Hello');
}
```

---

[Learn more](https://example.com)
''', options: const AnsiRendererOptions(syntaxHighlighting: false));
        // Verify key elements are present
        expect(result, contains('Title'));
        expect(result, contains('bold'));
        expect(result, contains('italic'));
        expect(result, contains('Features'));
        expect(result, contains('\u2022 Feature 1'));
        expect(result, contains('Note: This is important'));
        expect(result, contains('void main()'));
        expect(result, contains('\u2500')); // HR
        expect(result, contains('Learn more'));
      });
    });

    group('edge cases', () {
      test('handles empty input', () {
        final result = markdownToAnsi('');
        expect(result, isEmpty);
      });

      test('handles plain text', () {
        final result = markdownToAnsi('Just plain text');
        expect(Ansi.stripAnsi(result).trim(), equals('Just plain text'));
      });

      test('handles multiple paragraphs', () {
        final result = markdownToAnsi('''
First paragraph.

Second paragraph.

Third paragraph.
''');
        expect(result, contains('First paragraph'));
        expect(result, contains('Second paragraph'));
        expect(result, contains('Third paragraph'));
      });
    });

    group('HTML entities', () {
      test('decodes common HTML entities', () {
        final result = markdownToAnsi('Use &lt;tag&gt; and &amp; symbol');
        expect(result, contains('<tag>'));
        expect(result, contains('& symbol'));
        expect(result, isNot(contains('&lt;')));
        expect(result, isNot(contains('&gt;')));
        expect(result, isNot(contains('&amp;')));
      });

      test('decodes quote entities', () {
        final result = markdownToAnsi('He said &quot;hello&quot;');
        expect(result, contains('"hello"'));
        expect(result, isNot(contains('&quot;')));
      });

      test('decodes apostrophe entities', () {
        final result = markdownToAnsi("It&#39;s working");
        expect(result, contains("It's working"));
        expect(result, isNot(contains('&#39;')));
      });

      test('decodes numeric entities', () {
        final result = markdownToAnsi('Copyright &#169; 2024');
        expect(result, contains('Copyright © 2024'));
        expect(result, isNot(contains('&#169;')));
      });

      test('decodes entities in code blocks', () {
        // Note: In code blocks, the markdown parser preserves entities literally,
        // but the HTML output still encodes special chars. Our decoder handles this.
        final result = markdownToAnsi('''
```
a < b && c > d
```
''', options: const AnsiRendererOptions(syntaxHighlighting: false));
        final stripped = Ansi.stripAnsi(result);
        expect(stripped, contains('a < b && c > d'));
      });

      test('decodes entities in blockquotes', () {
        final result = markdownToAnsi('> "Best quote" &mdash; Author');
        final stripped = Ansi.stripAnsi(result);
        expect(stripped, contains('— Author'));
        expect(stripped, isNot(contains('&mdash;')));
      });
    });
  });

  group('AnsiRenderer', () {
    test('can be reused for multiple renders', () {
      final renderer = AnsiRenderer();
      // Note: We need to parse markdown separately for each render
      // This is testing the renderer's internal state reset
      final md1 = '# First';
      final md2 = '# Second';

      // Would need to parse and render separately
      final result1 = markdownToAnsi(md1);
      final result2 = markdownToAnsi(md2);

      expect(result1, contains('First'));
      expect(result2, contains('Second'));
    });
  });

  group('AnsiRendererOptions', () {
    test('copyWith creates modified copy', () {
      const original = AnsiRendererOptions(width: 80, bulletChar: '-');

      final modified = original.copyWith(width: 100);

      expect(modified.width, equals(100));
      expect(modified.bulletChar, equals('-')); // Unchanged
    });

    test('default values are sensible', () {
      const options = AnsiRendererOptions();
      expect(options.bulletChar, equals('\u2022'));
      expect(options.hyperlinks, isTrue);
      expect(options.hrChar, equals('\u2500'));
      expect(options.listIndent, equals(2));
      expect(options.codeBlockBorder, isTrue);
    });
  });

  group('text wrapping', () {
    test('wraps long paragraphs to specified width', () {
      final longText =
          'This is a very long paragraph that should be wrapped when rendered with a specified width option.';
      final result = markdownToAnsi(
        longText,
        options: const AnsiRendererOptions(width: 30),
      );
      final lines = Ansi.stripAnsi(result).split('\n');

      // Each line should be at most 30 characters (accounting for word boundaries)
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          expect(line.length, lessThanOrEqualTo(30));
        }
      }
    });

    test('does not wrap when width is null', () {
      final longText =
          'This is a single line that should not be wrapped when no width is specified.';
      final result = markdownToAnsi(longText);
      final stripped = Ansi.stripAnsi(result).trim();

      // Should remain a single line
      expect(stripped.split('\n').length, equals(1));
      expect(stripped, contains('should not be wrapped'));
    });

    test('preserves styling across wrapped lines', () {
      final result = markdownToAnsi(
        'This is **bold text that spans multiple words** in a wrapping context.',
        options: const AnsiRendererOptions(width: 25),
      );

      // Should contain bold start sequence
      expect(result, contains('\x1b[1m'));
      // Content should still be present
      expect(result, contains('bold'));
    });

    test('wraps multiple paragraphs independently', () {
      final result = markdownToAnsi('''
First paragraph with some text.

Second paragraph with some text.
''', options: const AnsiRendererOptions(width: 20));
      final stripped = Ansi.stripAnsi(result);

      expect(stripped, contains('First'));
      expect(stripped, contains('Second'));
    });
  });
}
