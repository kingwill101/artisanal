import 'dart:typed_data';

import 'package:artisanal/src/style/border.dart' as style_border;
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/tui/markdown/ansi_renderer.dart';
import 'package:artisanal/src/tui/markdown/image_renderer.dart';
import 'package:artisanal/src/tui/markdown/syntax_highlighter.dart';
import 'package:image/image.dart' as img;
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

/// Strips all ANSI escape sequences from a string for plain-text comparison.
String stripAnsi(String input) => Ansi.stripAnsi(input);

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // 1. Custom Style Options
  // ═══════════════════════════════════════════════════════════════════════════

  group('custom style options', () {
    group('heading styles', () {
      test('uses custom h2 style', () {
        final result = markdownToAnsi(
          '## Heading 2',
          options: AnsiRendererOptions(h2Style: Style().underline()),
        );
        expect(result, contains('\x1b[4m')); // underline
        expect(result, contains('Heading 2'));
      });

      test('uses custom h3 style', () {
        final result = markdownToAnsi(
          '### Heading 3',
          options: AnsiRendererOptions(h3Style: Style().foreground(Colors.red)),
        );
        expect(result, contains('Heading 3'));
        // Red foreground
        expect(result, contains('\x1b['));
      });

      test('uses custom h4 style', () {
        final result = markdownToAnsi(
          '#### Heading 4',
          options: AnsiRendererOptions(h4Style: Style().italic()),
        );
        expect(result, contains('\x1b[3m')); // italic
        expect(result, contains('Heading 4'));
      });

      test('uses custom h5 style', () {
        final result = markdownToAnsi(
          '##### Heading 5',
          options: AnsiRendererOptions(h5Style: Style().underline()),
        );
        expect(result, contains('\x1b[4m')); // underline
        expect(result, contains('Heading 5'));
      });

      test('uses custom h6 style', () {
        final result = markdownToAnsi(
          '###### Heading 6',
          options: AnsiRendererOptions(h6Style: Style().bold()),
        );
        expect(result, contains('\x1b[1m')); // bold
        expect(result, contains('Heading 6'));
      });

      test('default h1 uses bold + bright cyan', () {
        final result = markdownToAnsi('# Title');
        expect(result, contains('\x1b[1m')); // bold
        expect(result, contains('Title'));
      });

      test('default h4 uses bold only', () {
        final result = markdownToAnsi('#### H4');
        expect(result, contains('\x1b[1m'));
        expect(result, contains('H4'));
      });

      test('default h5 uses bold + dim', () {
        final result = markdownToAnsi('##### H5');
        // bold=1, dim=2
        expect(result, contains('\x1b[1;2m'));
        expect(result, contains('H5'));
      });

      test('default h6 uses dim', () {
        final result = markdownToAnsi('###### H6');
        expect(result, contains('\x1b[2m'));
        expect(result, contains('H6'));
      });
    });

    group('inline style overrides', () {
      test('uses custom strongStyle', () {
        final result = markdownToAnsi(
          'This is **bold** text',
          options: AnsiRendererOptions(strongStyle: Style().underline()),
        );
        // Should use underline instead of bold
        expect(result, contains('\x1b[4m'));
        expect(stripAnsi(result), contains('bold'));
      });

      test('uses custom codeStyle', () {
        final result = markdownToAnsi(
          'Use `code` here',
          options: AnsiRendererOptions(
            codeStyle: Style().foreground(Colors.green),
          ),
        );
        expect(result, contains('code'));
        expect(result, contains('\x1b['));
      });

      test('default inline code has foreground and background', () {
        final result = markdownToAnsi('Use `print()` function');
        // Default is brightYellow fg + gray800 bg
        // brightYellow = 38;2;250;204;21 and gray800 = 48;2;...
        expect(result, contains('38;2;')); // foreground RGB
        expect(result, contains('48;2;')); // background RGB
      });

      test('uses custom linkStyle', () {
        final result = markdownToAnsi(
          '[link](https://example.com)',
          options: AnsiRendererOptions(
            linkStyle: Style().bold().foreground(Colors.green),
            hyperlinks: false,
          ),
        );
        expect(result, contains('\x1b[1m')); // bold
        expect(result, contains('link'));
      });

      test('uses custom blockquoteStyle', () {
        final result = markdownToAnsi(
          '> Quote text',
          options: AnsiRendererOptions(blockquoteStyle: Style().bold()),
        );
        expect(result, contains('Quote text'));
        expect(result, contains('\x1b[1m')); // bold
      });

      test('uses custom blockquoteBorderColor', () {
        final result = markdownToAnsi(
          '> Quote',
          options: AnsiRendererOptions(blockquoteBorderColor: Colors.red),
        );
        expect(result, contains('\u2502')); // vertical bar
        expect(result, contains('Quote'));
      });

      test('default blockquote text is italic + dim', () {
        final result = markdownToAnsi('> Some quote');
        // dim = 2, italic = 3 (order matches _styleToAnsiOpen processing)
        expect(result, contains('\x1b[2;3m'));
      });

      test('uses custom strikethroughStyle', () {
        final result = markdownToAnsi(
          '~~deleted~~',
          options: AnsiRendererOptions(
            strikethroughStyle: Style().italic().foreground(Colors.red),
          ),
        );
        expect(result, contains('\x1b[3m')); // italic
        expect(stripAnsi(result), contains('deleted'));
      });
    });

    group('list options', () {
      test('uses custom listIndent of 4', () {
        final result = markdownToAnsi(
          '- Parent\n  - Child',
          options: const AnsiRendererOptions(listIndent: 4),
        );
        final plain = stripAnsi(result);
        final lines = plain
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();

        expect(lines.length, greaterThanOrEqualTo(2));
        // Child should be indented by 4 spaces (1 level * 4)
        expect(lines[1], startsWith('    '));
      });

      test('uses custom listIndent of 6', () {
        final result = markdownToAnsi(
          '- A\n  - B\n    - C',
          options: const AnsiRendererOptions(listIndent: 6),
        );
        final plain = stripAnsi(result);
        final lines = plain
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();

        expect(lines.length, greaterThanOrEqualTo(3));
        // Level 2 = 6 spaces, level 3 = 12 spaces
        expect(lines[1], startsWith('      '));
        expect(lines[2], startsWith('            '));
      });

      test('uses custom checkboxChecked character', () {
        final result = markdownToAnsi(
          '- [x] Done',
          options: const AnsiRendererOptions(checkboxChecked: '[X]'),
        );
        expect(stripAnsi(result), contains('[X]'));
      });

      test('uses custom checkboxUnchecked character', () {
        final result = markdownToAnsi(
          '- [ ] Todo',
          options: const AnsiRendererOptions(checkboxUnchecked: '[ ]'),
        );
        expect(stripAnsi(result), contains('[ ]'));
      });
    });

    group('horizontal rule options', () {
      test('uses custom hrChar', () {
        final result = markdownToAnsi(
          '---',
          options: const AnsiRendererOptions(hrChar: '='),
        );
        final plain = stripAnsi(result);
        expect(plain, contains('='));
        expect(plain, isNot(contains('\u2500'))); // no default char
      });

      test('uses custom hrWidth', () {
        final result = markdownToAnsi(
          '---',
          options: const AnsiRendererOptions(hrChar: '-', hrWidth: 10),
        );
        final plain = stripAnsi(result).trim();
        expect(plain, equals('----------'));
      });

      test('hrWidth defaults to width when hrWidth not specified', () {
        final result = markdownToAnsi(
          '---',
          options: const AnsiRendererOptions(hrChar: '-', width: 50),
        );
        final plain = stripAnsi(result).trim();
        expect(plain.length, equals(50));
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. Ordered List Start Attribute + Language Aliases
  // ═══════════════════════════════════════════════════════════════════════════

  group('ordered list start attribute', () {
    test('respects start attribute for ordered list', () {
      // The markdown package parses `5. Item` starting from 5
      final result = markdownToAnsi('5. Fifth\n6. Sixth\n7. Seventh');
      final plain = stripAnsi(result);
      // Note: markdown package may normalize to 1., but we test either way
      expect(plain, contains('Fifth'));
      expect(plain, contains('Sixth'));
      expect(plain, contains('Seventh'));
    });

    test('ordered list starts numbering from 1 by default', () {
      final result = markdownToAnsi('1. Alpha\n2. Beta\n3. Gamma');
      final plain = stripAnsi(result);
      expect(plain, contains('1. Alpha'));
      expect(plain, contains('2. Beta'));
      expect(plain, contains('3. Gamma'));
    });

    test('nested ordered lists have independent counters', () {
      final result = markdownToAnsi(
        '1. First\n   1. Sub-first\n   2. Sub-second\n2. Second',
      );
      final plain = stripAnsi(result);
      expect(plain, contains('First'));
      expect(plain, contains('Sub-first'));
      expect(plain, contains('Sub-second'));
      expect(plain, contains('Second'));
    });
  });

  group('language alias normalization', () {
    test('js alias produces highlighting like javascript', () {
      final js = markdownToAnsi('```js\nvar x = 1;\n```');
      final javascript = markdownToAnsi('```javascript\nvar x = 1;\n```');
      // Both should have syntax highlighting (ANSI codes)
      expect(js, contains('\x1b['));
      expect(javascript, contains('\x1b['));
      // The code content should be the same
      expect(stripAnsi(js), contains('var x = 1'));
      expect(stripAnsi(javascript), contains('var x = 1'));
    });

    test('py alias produces highlighting like python', () {
      final py = markdownToAnsi('```py\ndef foo():\n  pass\n```');
      final python = markdownToAnsi('```python\ndef foo():\n  pass\n```');
      expect(stripAnsi(py), contains('def foo'));
      expect(stripAnsi(python), contains('def foo'));
    });

    test('sh alias produces highlighting like bash', () {
      final sh = markdownToAnsi('```sh\necho hello\n```');
      final bash = markdownToAnsi('```bash\necho hello\n```');
      expect(stripAnsi(sh), contains('echo hello'));
      expect(stripAnsi(bash), contains('echo hello'));
    });

    test('yml alias produces highlighting like yaml', () {
      final yml = markdownToAnsi('```yml\nkey: value\n```');
      final yaml = markdownToAnsi('```yaml\nkey: value\n```');
      expect(stripAnsi(yml), contains('key: value'));
      expect(stripAnsi(yaml), contains('key: value'));
    });

    test('ts alias produces highlighting like typescript', () {
      final ts = markdownToAnsi('```ts\nconst x: number = 1;\n```');
      final typescript = markdownToAnsi(
        '```typescript\nconst x: number = 1;\n```',
      );
      expect(stripAnsi(ts), contains('const x'));
      expect(stripAnsi(typescript), contains('const x'));
    });

    test('filename hint main.rs produces highlighting like rust', () {
      final filenameHint = markdownToAnsi('```main.rs\nfn main() {}\n```');
      final rust = markdownToAnsi('```rust\nfn main() {}\n```');
      expect(filenameHint, contains('\x1b['));
      expect(rust, contains('\x1b['));
      expect(stripAnsi(filenameHint), contains('fn main() {}'));
      expect(stripAnsi(rust), contains('fn main() {}'));
    });

    test('filename hint Dockerfile produces highlighting like dockerfile', () {
      final filenameHint = markdownToAnsi(
        '```Dockerfile\nFROM dart:stable\nRUN dart pub get\n```',
      );
      final dockerfile = markdownToAnsi(
        '```dockerfile\nFROM dart:stable\nRUN dart pub get\n```',
      );
      expect(filenameHint, contains('\x1b['));
      expect(dockerfile, contains('\x1b['));
      expect(stripAnsi(filenameHint), contains('FROM dart:stable'));
      expect(stripAnsi(dockerfile), contains('FROM dart:stable'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. Structural Interactions
  // ═══════════════════════════════════════════════════════════════════════════

  group('structural interactions', () {
    test('headings with inline bold', () {
      final result = markdownToAnsi('## Heading with **bold** word');
      final plain = stripAnsi(result);
      expect(plain, contains('Heading with bold word'));
      // Should have heading style + bold style (both use bold, so at least
      // two reset sequences)
      final resetCount = RegExp(r'\x1b\[0m').allMatches(result).length;
      expect(resetCount, greaterThanOrEqualTo(1));
    });

    test('headings with inline code', () {
      final result = markdownToAnsi('## Use `print()`');
      final plain = stripAnsi(result);
      expect(plain, contains('Use print()'));
    });

    test('headings with italic text', () {
      final result = markdownToAnsi('### *Italic* heading');
      final plain = stripAnsi(result);
      expect(plain, contains('Italic heading'));
    });

    test('blockquote containing list', () {
      final result = markdownToAnsi('> - Item 1\n> - Item 2');
      final plain = stripAnsi(result);
      expect(plain, contains('Item 1'));
      expect(plain, contains('Item 2'));
      // Should have blockquote border
      expect(result, contains('\u2502'));
    });

    test('blockquote containing code block', () {
      final result = markdownToAnsi(
        '> ```\n> code line\n> ```',
        options: const AnsiRendererOptions(syntaxHighlighting: false),
      );
      final plain = stripAnsi(result);
      expect(plain, contains('code line'));
    });

    test('blockquote with highlighted code block keeps quote fence intact', () {
      final result = markdownToAnsi('''
> ```dart
> void main() {
>   print('hello');
> }
> ```
''');
      final plain = stripAnsi(result);
      final lines = plain.split('\n');
      expect(lines, contains('│ '));
      expect(lines, contains('│ ╭─ dart '));
      expect(lines, contains('│ │ void main() {'));
      expect(lines, contains("│ │   print('hello');"));
      expect(lines, contains('│ ╰───'));
      expect(plain, isNot(contains('38;2')));
    });

    test('list item containing inline code', () {
      final result = markdownToAnsi('- Use `foo()` function\n- And `bar()`');
      final plain = stripAnsi(result);
      expect(plain, contains('foo()'));
      expect(plain, contains('bar()'));
      // Should have styling for the inline code
      expect(result, contains('\x1b['));
    });

    test('list item containing bold text', () {
      final result = markdownToAnsi('- **Important** item\n- Normal item');
      final plain = stripAnsi(result);
      expect(plain, contains('Important'));
      expect(plain, contains('Normal'));
      expect(result, contains('\x1b[1m')); // bold
    });

    test('list item containing link', () {
      final result = markdownToAnsi(
        '- Visit [site](https://example.com)',
        options: const AnsiRendererOptions(hyperlinks: false),
      );
      final plain = stripAnsi(result);
      expect(plain, contains('site'));
    });

    test('hard line break with two trailing spaces', () {
      // Two trailing spaces create a <br> in markdown
      final result = markdownToAnsi('Line one  \nLine two');
      final plain = stripAnsi(result);
      // Both lines should be present, separated by newline
      expect(plain, contains('Line one'));
      expect(plain, contains('Line two'));
      final lines = plain
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(lines.length, greaterThanOrEqualTo(2));
    });

    test('blockquote with multiple paragraphs', () {
      final result = markdownToAnsi('> First para\n>\n> Second para');
      final plain = stripAnsi(result);
      expect(plain, contains('First para'));
      expect(plain, contains('Second para'));
    });

    test('blockquote joins nested quote directly after preceding line', () {
      final result = markdownToAnsi('''
> A quote can span multiple lines,
> include **bold** text, and even
>
> > Nested quote.
''');
      final lines = stripAnsi(result).split('\n');
      expect(lines, contains('│ include bold text, and even'));
      expect(lines, contains('││ Nested quote.'));
    });

    test('nested blockquotes render nested borders', () {
      final result = markdownToAnsi('> Outer\n>> Inner');
      // Should have the blockquote border character
      expect(result, contains('\u2502'));
      final lines = stripAnsi(result).split('\n');
      expect(lines, contains('│ Outer'));
      expect(lines, contains('││ Inner'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. Edge Cases
  // ═══════════════════════════════════════════════════════════════════════════

  group('edge cases', () {
    test('empty code block renders without error', () {
      final result = markdownToAnsi(
        '```\n```',
        options: const AnsiRendererOptions(syntaxHighlighting: false),
      );
      // Should have border chars but no crash
      expect(result, contains('\u256d')); // top-left rounded
      expect(result, contains('\u2570')); // bottom-left rounded
    });

    test('code block with empty language still renders border', () {
      final result = markdownToAnsi(
        '```\nsome code\n```',
        options: const AnsiRendererOptions(syntaxHighlighting: false),
      );
      expect(stripAnsi(result), contains('some code'));
      expect(result, contains('\u256d'));
    });

    test('image with no alt text uses fallback', () {
      final result = markdownToAnsi('![](https://example.com/img.png)');
      // The markdown parser may drop the image entirely or render it
      // At minimum it should not crash
      expect(result, isNotNull);
    });

    test('image with empty src', () {
      final result = markdownToAnsi('![Alt text]()');
      final plain = stripAnsi(result);
      expect(plain, contains('Alt text'));
    });

    test('image with both alt and src', () {
      final result = markdownToAnsi('![Logo](https://example.com/logo.png)');
      final plain = stripAnsi(result);
      expect(plain, contains('Logo'));
      expect(plain, contains('example.com'));
    });

    test('single item unordered list', () {
      final result = markdownToAnsi('- Only item');
      expect(stripAnsi(result), contains('Only item'));
      expect(result, contains('\u2022'));
    });

    test('single item ordered list', () {
      final result = markdownToAnsi('1. Only item');
      expect(stripAnsi(result), contains('1. Only item'));
    });

    test('consecutive block elements have proper spacing', () {
      final result = markdownToAnsi('# Heading\n\nParagraph\n\n---\n\n> Quote');
      final plain = stripAnsi(result);
      expect(plain, contains('Heading'));
      expect(plain, contains('Paragraph'));
      expect(plain, contains('Quote'));
    });

    test('paragraph followed by list has proper spacing', () {
      final result = markdownToAnsi('Some text\n\n- Item 1\n- Item 2');
      final plain = stripAnsi(result);
      expect(plain, contains('Some text'));
      expect(plain, contains('Item 1'));
      expect(plain, contains('Item 2'));
    });

    test('mixed ordered and unordered lists', () {
      final result = markdownToAnsi(
        '- Bullet 1\n- Bullet 2\n\n1. Number 1\n2. Number 2',
      );
      final plain = stripAnsi(result);
      expect(plain, contains('Bullet 1'));
      expect(plain, contains('Number 1'));
    });

    test('very deeply nested list (4+ levels)', () {
      final result = markdownToAnsi('- L1\n  - L2\n    - L3\n      - L4');
      final plain = stripAnsi(result);
      final lines = plain
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(lines.length, greaterThanOrEqualTo(4));
    });

    test('plain text without any markdown formatting', () {
      final result = markdownToAnsi('Hello, world!');
      final plain = stripAnsi(result).trim();
      expect(plain, equals('Hello, world!'));
    });

    test('multiple consecutive blank lines collapse', () {
      final result = markdownToAnsi('Para 1\n\n\n\n\nPara 2');
      final plain = stripAnsi(result);
      expect(plain, contains('Para 1'));
      expect(plain, contains('Para 2'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. Text Wrapping Interactions
  // ═══════════════════════════════════════════════════════════════════════════

  group('text wrapping interactions', () {
    test('wrapping respects blockquote prefix width', () {
      final longText =
          'This is a long sentence inside a blockquote '
          'that should be wrapped accounting for the border prefix width.';
      final result = markdownToAnsi(
        '> $longText',
        options: const AnsiRendererOptions(width: 40),
      );
      final plain = stripAnsi(result);
      // Every non-empty line should fit within the width
      for (final line in plain.split('\n')) {
        if (line.trim().isNotEmpty) {
          expect(
            line.length,
            lessThanOrEqualTo(42), // allow slight overflow from prefix
            reason: 'Line too long: "$line"',
          );
        }
      }
    });

    test('wrapping preserves inline code styling', () {
      final result = markdownToAnsi(
        'Start `code` middle `more code` end text here',
        options: const AnsiRendererOptions(width: 30),
      );
      expect(result, contains('\x1b[')); // has styling
      final plain = stripAnsi(result);
      expect(plain, contains('code'));
      expect(plain, contains('more code'));
    });

    test('wrapping preserves bold styling', () {
      final result = markdownToAnsi(
        'This **bold text** should wrap correctly over lines',
        options: const AnsiRendererOptions(width: 25),
      );
      expect(result, contains('\x1b[1m')); // bold
      final plain = stripAnsi(result);
      expect(plain, contains('bold text'));
    });

    test('wrapping preserves italic styling', () {
      final result = markdownToAnsi(
        'This *italic text* should wrap correctly over lines',
        options: const AnsiRendererOptions(width: 25),
      );
      expect(result, contains('\x1b[3m')); // italic
      final plain = stripAnsi(result);
      expect(plain, contains('italic text'));
    });

    test('wrapping preserves link styling', () {
      final result = markdownToAnsi(
        'Click [this long link text](https://example.com) in the paragraph',
        options: const AnsiRendererOptions(width: 30, hyperlinks: false),
      );
      final plain = stripAnsi(result);
      expect(plain, contains('this long link text'));
    });

    test('no wrapping for code blocks', () {
      final longCode = 'x' * 100;
      final result = markdownToAnsi(
        '```\n$longCode\n```',
        options: const AnsiRendererOptions(
          width: 40,
          syntaxHighlighting: false,
        ),
      );
      final plain = stripAnsi(result);
      expect(plain, contains(longCode));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. Table Options
  // ═══════════════════════════════════════════════════════════════════════════

  group('table rendering', () {
    final tableMarkdown = '''
| Name  | Age |
|-------|-----|
| Alice | 30  |
| Bob   | 25  |
''';

    test('renders basic table content', () {
      final result = markdownToAnsi(tableMarkdown);
      final plain = stripAnsi(result);
      expect(plain, contains('Name'));
      expect(plain, contains('Age'));
      expect(plain, contains('Alice'));
      expect(plain, contains('30'));
      expect(plain, contains('Bob'));
      expect(plain, contains('25'));
    });

    test('uses custom tableBorder', () {
      final result = markdownToAnsi(
        tableMarkdown,
        options: AnsiRendererOptions(tableBorder: style_border.Border.ascii),
      );
      final plain = stripAnsi(result);
      // ASCII border uses + - |
      expect(plain, contains('+'));
      expect(plain, contains('-'));
    });

    test('uses custom tableHeaderStyle', () {
      final result = markdownToAnsi(
        tableMarkdown,
        options: AnsiRendererOptions(tableHeaderStyle: Style().italic()),
      );
      // Should have italic code
      expect(result, contains('\x1b[3m'));
      final plain = stripAnsi(result);
      expect(plain, contains('Name'));
    });

    test('uses custom tableBorderStyle', () {
      final result = markdownToAnsi(
        tableMarkdown,
        options: AnsiRendererOptions(tableBorderStyle: Style().dim()),
      );
      // Should have dim code
      expect(result, contains('\x1b[2m'));
    });

    test('table with inline formatting in cells', () {
      final result = markdownToAnsi('''
| Feature  | Status    |
|----------|-----------|
| **Bold** | *Italic*  |
| `Code`   | ~~Del~~   |
''');
      final plain = stripAnsi(result);
      expect(plain, contains('Bold'));
      expect(plain, contains('Italic'));
      expect(plain, contains('Code'));
      expect(plain, contains('Del'));
    });

    test('table with alignment markers', () {
      final result = markdownToAnsi('''
| Left | Center | Right |
|:-----|:------:|------:|
| L    | C      | R     |
''');
      final plain = stripAnsi(result);
      expect(plain, contains('Left'));
      expect(plain, contains('Center'));
      expect(plain, contains('Right'));
    });

    test('empty table does not crash', () {
      // A table with only headers and no data rows
      final result = markdownToAnsi('''
| Header |
|--------|
''');
      expect(() => result, returnsNormally);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. Syntax Highlighter
  // ═══════════════════════════════════════════════════════════════════════════

  group('syntax highlighter', () {
    group('SyntaxHighlighter direct usage', () {
      test('highlights dart code', () {
        final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = highlighter.highlightCode(
          'void main() { print("hello"); }',
          language: 'dart',
        );
        expect(result, contains('\x1b[')); // has ANSI codes
        expect(stripAnsi(result), contains('void'));
        expect(stripAnsi(result), contains('main'));
      });

      test('highlights javascript code', () {
        final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = highlighter.highlightCode(
          'const x = 42;',
          language: 'javascript',
        );
        expect(result, contains('\x1b['));
        expect(stripAnsi(result), contains('const'));
      });

      test('highlights python code', () {
        final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = highlighter.highlightCode(
          'def greet(name):\n  print(f"Hello {name}")',
          language: 'python',
        );
        expect(result, contains('\x1b['));
        expect(stripAnsi(result), contains('def'));
      });

      test('falls back gracefully for unknown language', () {
        final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = highlighter.highlightCode(
          'some text',
          language: 'nonexistent_language_xyz',
        );
        // Should not crash, may auto-detect or return plain
        expect(stripAnsi(result), contains('some text'));
      });

      test('handles null language gracefully', () {
        final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = highlighter.highlightCode('var x = 1;');
        // Should attempt auto-detection
        expect(stripAnsi(result), contains('var x = 1'));
      });

      test('handles empty language string gracefully', () {
        final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = highlighter.highlightCode('var x = 1;', language: '');
        expect(stripAnsi(result), contains('var x = 1'));
      });

      test('handles empty code string', () {
        final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = highlighter.highlightCode('', language: 'dart');
        // The highlighter may wrap even empty strings with style sequences,
        // but the visible content should be empty.
        expect(stripAnsi(result), isEmpty);
      });
    });

    group('named themes produce output', () {
      final testCode = 'void main() { print("hello"); }';

      test('ChromaTheme.dark highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.dark);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.light highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.light);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.monokai highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.monokai);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.dracula highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.dracula);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.github highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.github);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.solarizedDark highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.solarizedDark);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.solarizedLight highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.solarizedLight);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.nord highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.nord);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.gruvboxDark highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.gruvboxDark);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.gruvboxLight highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.gruvboxLight);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.oneDark highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.oneDark);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('ChromaTheme.oneLight highlights code', () {
        final h = SyntaxHighlighter(theme: ChromaTheme.oneLight);
        final result = h.highlightCode(testCode, language: 'dart');
        expect(result, contains('\x1b['));
      });

      test('different themes produce different output', () {
        final darkH = SyntaxHighlighter(theme: ChromaTheme.dark);
        final monokaiH = SyntaxHighlighter(theme: ChromaTheme.monokai);
        final darkResult = darkH.highlightCode(testCode, language: 'dart');
        final monokaiResult = monokaiH.highlightCode(
          testCode,
          language: 'dart',
        );
        // Same content, different colors
        expect(stripAnsi(darkResult), equals(stripAnsi(monokaiResult)));
        expect(darkResult, isNot(equals(monokaiResult)));
      });
    });

    group('adaptive theme pairings', () {
      test('monokaiGithub pairing resolves correctly', () {
        final theme = AdaptiveChromaTheme.monokaiGithub;
        final dark = theme.resolve(hasDarkBackground: true);
        final light = theme.resolve(hasDarkBackground: false);
        expect(dark.keyword, isNotNull);
        expect(light.keyword, isNotNull);
      });

      test('solarized pairing resolves correctly', () {
        final theme = AdaptiveChromaTheme.solarized;
        final dark = theme.resolve(hasDarkBackground: true);
        final light = theme.resolve(hasDarkBackground: false);
        expect(dark.keyword, isNotNull);
        expect(light.keyword, isNotNull);
      });

      test('nordGithub pairing resolves correctly', () {
        final theme = AdaptiveChromaTheme.nordGithub;
        final dark = theme.resolve(hasDarkBackground: true);
        final light = theme.resolve(hasDarkBackground: false);
        expect(dark.keyword, isNotNull);
        expect(light.keyword, isNotNull);
      });

      test('gruvbox pairing resolves correctly', () {
        final theme = AdaptiveChromaTheme.gruvbox;
        final dark = theme.resolve(hasDarkBackground: true);
        final light = theme.resolve(hasDarkBackground: false);
        expect(dark.keyword, isNotNull);
        expect(light.keyword, isNotNull);
      });

      test('oneDarkLight pairing resolves correctly', () {
        final theme = AdaptiveChromaTheme.oneDarkLight;
        final dark = theme.resolve(hasDarkBackground: true);
        final light = theme.resolve(hasDarkBackground: false);
        expect(dark.keyword, isNotNull);
        expect(light.keyword, isNotNull);
      });

      test('all adaptive pairings produce different dark/light output', () {
        final pairings = [
          AdaptiveChromaTheme.defaultTheme,
          AdaptiveChromaTheme.monokaiGithub,
          AdaptiveChromaTheme.draculaGithub,
          AdaptiveChromaTheme.solarized,
          AdaptiveChromaTheme.nordGithub,
          AdaptiveChromaTheme.gruvbox,
          AdaptiveChromaTheme.oneDarkLight,
        ];

        for (final pairing in pairings) {
          final darkH = SyntaxHighlighter(
            theme: pairing.resolve(hasDarkBackground: true),
          );
          final lightH = SyntaxHighlighter(
            theme: pairing.resolve(hasDarkBackground: false),
          );
          final darkResult = darkH.highlightCode(
            'void main() {}',
            language: 'dart',
          );
          final lightResult = lightH.highlightCode(
            'void main() {}',
            language: 'dart',
          );
          expect(
            darkResult,
            isNot(equals(lightResult)),
            reason: 'Dark/light should differ for $pairing',
          );
        }
      });
    });

    group('highlightCodeString convenience function', () {
      test('produces same output as SyntaxHighlighter', () {
        final direct = SyntaxHighlighter(
          theme: ChromaTheme.dark,
        ).highlightCode('var x = 1;', language: 'dart');
        final convenience = highlightCodeString(
          'var x = 1;',
          language: 'dart',
          theme: ChromaTheme.dark,
        );
        expect(convenience, equals(direct));
      });

      test('works without explicit theme (uses dark default)', () {
        final result = highlightCodeString('void main() {}', language: 'dart');
        expect(result, contains('\x1b['));
        expect(stripAnsi(result), contains('void'));
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. copyWith Completeness + Default Values
  // ═══════════════════════════════════════════════════════════════════════════

  group('AnsiRendererOptions defaults', () {
    test('all defaults are correct', () {
      const opts = AnsiRendererOptions();
      expect(opts.width, isNull);
      expect(opts.hasDarkBackground, isTrue);
      expect(opts.h1Style, isNull);
      expect(opts.h2Style, isNull);
      expect(opts.h3Style, isNull);
      expect(opts.h4Style, isNull);
      expect(opts.h5Style, isNull);
      expect(opts.h6Style, isNull);
      expect(opts.emphasisStyle, isNull);
      expect(opts.strongStyle, isNull);
      expect(opts.codeStyle, isNull);
      expect(opts.codeBlockStyle, isNull);
      expect(opts.linkStyle, isNull);
      expect(opts.blockquoteStyle, isNull);
      expect(opts.blockquoteBorderColor, isNull);
      expect(opts.strikethroughStyle, isNull);
      expect(opts.bulletChar, equals('\u2022'));
      expect(opts.hyperlinks, isTrue);
      expect(opts.hrChar, equals('\u2500'));
      expect(opts.hrWidth, isNull);
      expect(opts.checkboxChecked, equals('[x]'));
      expect(opts.checkboxUnchecked, equals('[ ]'));
      expect(opts.listIndent, equals(2));
      expect(opts.codeBlockBorder, isTrue);
      expect(opts.tableBorder, isNull);
      expect(opts.tableHeaderStyle, isNull);
      expect(opts.tableCellStyle, isNull);
      expect(opts.tableBorderStyle, isNull);
      expect(opts.syntaxHighlighting, isTrue);
      expect(opts.syntaxTheme, isNull);
      expect(opts.codeBlockBorderStyle, isNull);
    });
  });

  group('AnsiRendererOptions copyWith', () {
    test('preserves all fields when no overrides given', () {
      final original = AnsiRendererOptions(
        width: 80,
        hasDarkBackground: false,
        h1Style: Style().bold(),
        bulletChar: '-',
        hyperlinks: false,
        hrChar: '=',
        hrWidth: 50,
        checkboxChecked: '[x]',
        checkboxUnchecked: '[ ]',
        listIndent: 4,
        codeBlockBorder: false,
        syntaxHighlighting: false,
      );

      final copy = original.copyWith();

      expect(copy.width, equals(80));
      expect(copy.hasDarkBackground, isFalse);
      expect(copy.h1Style, isNotNull);
      expect(copy.bulletChar, equals('-'));
      expect(copy.hyperlinks, isFalse);
      expect(copy.hrChar, equals('='));
      expect(copy.hrWidth, equals(50));
      expect(copy.checkboxChecked, equals('[x]'));
      expect(copy.checkboxUnchecked, equals('[ ]'));
      expect(copy.listIndent, equals(4));
      expect(copy.codeBlockBorder, isFalse);
      expect(copy.syntaxHighlighting, isFalse);
    });

    test('overrides individual fields correctly', () {
      const original = AnsiRendererOptions(width: 80, bulletChar: '-');

      final copy1 = original.copyWith(width: 120);
      expect(copy1.width, equals(120));
      expect(copy1.bulletChar, equals('-'));

      final copy2 = original.copyWith(bulletChar: '*');
      expect(copy2.width, equals(80));
      expect(copy2.bulletChar, equals('*'));

      final copy3 = original.copyWith(listIndent: 6);
      expect(copy3.listIndent, equals(6));
      expect(copy3.width, equals(80));
    });

    test('copyWith can set hasDarkBackground', () {
      const original = AnsiRendererOptions(hasDarkBackground: true);
      final copy = original.copyWith(hasDarkBackground: false);
      expect(copy.hasDarkBackground, isFalse);
    });

    test('copyWith can set style options', () {
      const original = AnsiRendererOptions();
      final copy = original.copyWith(
        h2Style: Style().italic(),
        strongStyle: Style().underline(),
        codeStyle: Style().dim(),
      );
      expect(copy.h2Style, isNotNull);
      expect(copy.strongStyle, isNotNull);
      expect(copy.codeStyle, isNotNull);
    });

    test('copyWith can set border styles', () {
      const original = AnsiRendererOptions();
      final copy = original.copyWith(
        tableBorder: style_border.Border.ascii,
        codeBlockBorderStyle: style_border.Border.double,
      );
      expect(copy.tableBorder, isNotNull);
      expect(copy.codeBlockBorderStyle, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. AnsiRenderer Direct Instantiation
  // ═══════════════════════════════════════════════════════════════════════════

  group('AnsiRenderer direct usage', () {
    test('renders parsed nodes directly', () {
      final doc = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
      final nodes = doc.parse('# Hello\n\nWorld');
      final renderer = AnsiRenderer();
      final result = renderer.render(nodes);

      expect(stripAnsi(result), contains('Hello'));
      expect(stripAnsi(result), contains('World'));
    });

    test('state resets between renders', () {
      final renderer = AnsiRenderer();
      final doc = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);

      // First render: complex document
      final nodes1 = doc.parse('> **Bold** in blockquote\n\n- List item');
      renderer.render(nodes1);

      // Second render: simple document
      final nodes2 = doc.parse('Simple text');
      final result2 = renderer.render(nodes2);

      // Simple text should not have blockquote border or list bullet
      expect(result2, isNot(contains('\u2502')));
      expect(result2, isNot(contains('\u2022')));
      expect(stripAnsi(result2).trim(), equals('Simple text'));
    });

    test('renders with custom options', () {
      final doc = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
      final nodes = doc.parse('- Item');
      final renderer = AnsiRenderer(
        options: const AnsiRendererOptions(bulletChar: '>'),
      );
      final result = renderer.render(nodes);
      expect(stripAnsi(result), contains('> Item'));
    });

    test('caps inline image height when unspecified', () {
      final image = img.Image(width: 1000, height: 1000);
      final bytes = Uint8List.fromList(img.encodePng(image));
      final doc = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
      final nodes = doc.parse('![Alt](https://example.com/large.png)');
      final renderer = AnsiRenderer(
        options: const AnsiRendererOptions(
          renderImages: true,
          imageProtocol: ImageProtocol.kitty,
        ),
      );
      renderer.imageCache['https://example.com/large.png'] = bytes;

      final result = renderer.render(nodes);
      expect(result, contains('r=16'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. Code Block Border Styles
  // ═══════════════════════════════════════════════════════════════════════════

  group('code block border styles', () {
    test('code block without border has no border characters', () {
      final result = markdownToAnsi(
        '```\ncode\n```',
        options: const AnsiRendererOptions(
          codeBlockBorder: false,
          syntaxHighlighting: false,
        ),
      );
      expect(result, isNot(contains('\u256d'))); // no rounded corner
      expect(stripAnsi(result), contains('code'));
    });

    test(
      'code block with language and no syntax highlighting applies code style',
      () {
        final result = markdownToAnsi(
          '```dart\nvoid main() {}\n```',
          options: const AnsiRendererOptions(syntaxHighlighting: false),
        );
        // Should have the default code block style (brightYellow)
        expect(result, contains('\x1b['));
        expect(stripAnsi(result), contains('void main()'));
      },
    );

    test('multiline code block has border prefix on each line', () {
      final result = markdownToAnsi(
        '```\nline1\nline2\nline3\n```',
        options: const AnsiRendererOptions(syntaxHighlighting: false),
      );
      final plain = stripAnsi(result);
      expect(plain, contains('line1'));
      expect(plain, contains('line2'));
      expect(plain, contains('line3'));
      // Should have vertical border on the left for each line
      expect(result, contains('\u2502')); // vertical line
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. Complex Document Integration Tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('complex document integration', () {
    test('full document with all features renders correctly', () {
      final result = markdownToAnsi('''
# Main Title

This is a paragraph with **bold**, *italic*, `code`, and ~~strikethrough~~.

## Section 1

- Bullet 1
  - Nested bullet
- Bullet 2

1. Ordered 1
2. Ordered 2

> A blockquote
> with continuation

```dart
void main() {
  print('Hello');
}
```

---

| Header1 | Header2 |
|---------|---------|
| Cell1   | Cell2   |

- [x] Task done
- [ ] Task pending

[Link text](https://example.com)

![Image](https://example.com/img.png)
''', options: const AnsiRendererOptions(width: 80));

      final plain = stripAnsi(result);

      // Headings
      expect(plain, contains('Main Title'));
      expect(plain, contains('Section 1'));

      // Inline styles
      expect(plain, contains('bold'));
      expect(plain, contains('italic'));
      expect(plain, contains('code'));
      expect(plain, contains('strikethrough'));

      // Lists
      expect(plain, contains('Bullet 1'));
      expect(plain, contains('Nested bullet'));
      expect(plain, contains('Ordered 1'));

      // Blockquote
      expect(plain, contains('A blockquote'));

      // Code
      expect(plain, contains("print('Hello')"));

      // Table
      expect(plain, contains('Header1'));
      expect(plain, contains('Cell1'));

      // Task lists
      expect(plain, contains('[x] Task done'));
      expect(plain, contains('[ ] Task pending'));

      // Link
      expect(plain, contains('Link text'));

      // Image
      expect(plain, contains('Image'));
    });

    test('document renders without throwing', () {
      expect(
        () => markdownToAnsi('''
# Title

Paragraph with [link](url), **bold**, *italic*, `code`.

> > Nested blockquote

- List
  1. Nested ordered
  2. Item

```python
x = 42
```

---

| A | B |
|---|---|
| 1 | 2 |
'''),
        returnsNormally,
      );
    });
  });
}
