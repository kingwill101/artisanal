import 'dart:io';

import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/tui/markdown/ansi_renderer.dart';
import 'package:test/test.dart';

File _resolvePackageFile(String relativePath) {
  final candidates = <String>[
    relativePath,
    'pkgs/artisanal/$relativePath',
    'packages/artisanal/$relativePath',
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  throw FileSystemException('Unable to locate test fixture', relativePath);
}

void main() {
  group('Markdown file rendering', () {
    late String markdownContent;
    late String rendered;

    setUpAll(() {
      // Read the comprehensive markdown test file
      final file = _resolvePackageFile(
        'test/markdown/fixtures/comprehensive.md',
      );
      markdownContent = file.readAsStringSync();
      rendered = markdownToAnsi(markdownContent);
    });

    test('renders the file without throwing', () {
      expect(() => markdownToAnsi(markdownContent), returnsNormally);
    });

    test('rendered output is not empty', () {
      expect(rendered, isNotEmpty);
    });

    test('stripped output preserves all text content', () {
      final stripped = Ansi.stripAnsi(rendered);

      // Check that key content from each section is present
      expect(stripped, contains('Artisanal Markdown Renderer Test Document'));
      expect(stripped, contains('Inline Formatting'));
      expect(stripped, contains('bold text'));
      expect(stripped, contains('italic text'));
      expect(stripped, contains('strikethrough'));
    });

    group('headings', () {
      test('renders all heading levels', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('Heading Level 1'));
        expect(stripped, contains('Heading Level 2'));
        expect(stripped, contains('Heading Level 3'));
        expect(stripped, contains('Heading Level 4'));
        expect(stripped, contains('Heading Level 5'));
        expect(stripped, contains('Heading Level 6'));
      });

      test('applies ANSI styling to headings', () {
        // H1 should have bold (1) in its escape sequence
        expect(rendered, contains('\x1b[1m')); // Bold
      });
    });

    group('inline styles', () {
      test('renders bold text with ANSI bold', () {
        // The word "bold" should be wrapped in bold styling
        expect(rendered, contains('\x1b[1m')); // Bold SGR code
      });

      test('renders italic text with ANSI italic', () {
        expect(rendered, contains('\x1b[3m')); // Italic SGR code
      });

      test('renders strikethrough', () {
        expect(rendered, contains('9m')); // Strikethrough SGR code
      });

      test('renders inline code', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('print()'));
        expect(stripped, contains('inline code'));
      });
    });

    group('links', () {
      test('renders link text', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains("Dart's official website"));
        expect(stripped, contains('GitHub'));
      });

      test('includes OSC 8 hyperlinks by default', () {
        expect(rendered, contains('\x1b]8;;https://dart.dev\x1b\\'));
        expect(rendered, contains('\x1b]8;;https://github.com\x1b\\'));
      });

      test('includes hyperlink close sequences', () {
        // OSC 8 close sequence
        expect(rendered, contains('\x1b]8;;\x1b\\'));
      });
    });

    group('images', () {
      test('renders image placeholders', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('[Image: Dart Logo]'));
        expect(
          stripped,
          contains('[Image: Alternative text for accessibility]'),
        );
      });

      test('includes image URLs', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('dart.dev'));
      });
    });

    group('lists', () {
      test('renders unordered list bullets', () {
        expect(rendered, contains('\u2022')); // Bullet character
      });

      test('renders ordered list numbers', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('1.'));
        expect(stripped, contains('2.'));
        expect(stripped, contains('3.'));
      });

      test('renders nested list indentation', () {
        // Nested items should have leading spaces
        final stripped = Ansi.stripAnsi(rendered);
        // Level 2 items have 2-space indent
        expect(stripped, contains('  \u2022 Level 2'));
      });

      test('renders task list checkboxes', () {
        expect(rendered, contains('\u2611')); // Checked checkbox
        expect(rendered, contains('\u2610')); // Unchecked checkbox
      });
    });

    group('blockquotes', () {
      test('renders blockquote border', () {
        expect(rendered, contains('\u2502')); // Vertical bar
      });

      test('renders nested blockquote borders', () {
        // Nested blockquotes should have multiple vertical bars
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('Level 1 quote'));
        expect(stripped, contains('Level 2 quote'));
        expect(stripped, contains('Level 3 quote'));
      });
    });

    group('code blocks', () {
      test('renders code block borders', () {
        expect(rendered, contains('\u256d')); // Top-left corner
        expect(rendered, contains('\u2570')); // Bottom-left corner
      });

      test('renders code block with language labels', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('dart'));
        expect(stripped, contains('javascript'));
        expect(stripped, contains('python'));
        expect(stripped, contains('sql'));
        expect(stripped, contains('bash'));
        expect(stripped, contains('json'));
        expect(stripped, contains('yaml'));
      });

      test('preserves code content', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('void main()'));
        expect(stripped, contains('function fibonacci'));
        expect(stripped, contains('def quicksort'));
        expect(stripped, contains('SELECT'));
      });
    });

    group('horizontal rules', () {
      test('renders horizontal rule characters', () {
        expect(rendered, contains('\u2500')); // Horizontal line
      });
    });

    group('tables', () {
      test('renders table content', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('Name'));
        expect(stripped, contains('Age'));
        expect(stripped, contains('City'));
        expect(stripped, contains('Alice'));
        expect(stripped, contains('Bob'));
        expect(stripped, contains('Charlie'));
      });

      test('renders table header row', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('Language'));
        expect(stripped, contains('Typing'));
        expect(stripped, contains('Paradigm'));
      });

      test('renders table data rows', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('Dart'));
        expect(stripped, contains('Rust'));
        expect(stripped, contains('Go'));
        expect(stripped, contains('Python'));
        expect(stripped, contains('JavaScript'));
      });
    });

    group('unicode', () {
      test('preserves emoji', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('🚀'));
        expect(stripped, contains('🎉'));
        expect(stripped, contains('✨'));
      });

      test('preserves math symbols', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('∑'));
        expect(stripped, contains('∞'));
        expect(stripped, contains('√'));
      });

      test('preserves arrows', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('→'));
        expect(stripped, contains('←'));
        expect(stripped, contains('⇒'));
      });

      test('preserves Greek letters', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('α'));
        expect(stripped, contains('β'));
        expect(stripped, contains('γ'));
      });
    });

    group('edge cases', () {
      test('handles escaped characters', () {
        final stripped = Ansi.stripAnsi(rendered);
        // Escaped asterisks should appear as literal asterisks
        expect(stripped, contains('*This is not italic*'));
        expect(stripped, contains('**This is not bold**'));
      });

      test('handles very long lines', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('extremely long line that goes on and on'));
      });
    });

    group('complex structures', () {
      test('renders conclusion checklist', () {
        final stripped = Ansi.stripAnsi(rendered);
        expect(stripped, contains('✅ Inline formatting'));
        expect(stripped, contains('✅ Links and images'));
        expect(stripped, contains('✅ Lists'));
        expect(stripped, contains('✅ Blockquotes'));
        expect(stripped, contains('✅ Code blocks'));
        expect(stripped, contains('✅ Headings'));
        expect(stripped, contains('✅ Horizontal rules'));
        expect(stripped, contains('✅ Tables'));
      });
    });

    test('custom options can be applied to file rendering', () {
      final customOptions = AnsiRendererOptions(
        hyperlinks: false,
        bulletChar: '-',
        codeBlockBorder: false,
      );

      final customRendered = markdownToAnsi(
        markdownContent,
        options: customOptions,
      );

      // Should use dash instead of bullet
      expect(customRendered, contains('- First item'));

      // Should not have OSC 8 hyperlinks
      expect(customRendered, isNot(contains('\x1b]8;;https://')));

      // Should not have code block borders
      expect(customRendered, isNot(contains('\u256d\u2500 dart')));
    });
  });

  group('Markdown file comparison', () {
    test('multiple renders produce identical output', () {
      final file = _resolvePackageFile(
        'test/markdown/fixtures/comprehensive.md',
      );
      final content = file.readAsStringSync();

      final render1 = markdownToAnsi(content);
      final render2 = markdownToAnsi(content);

      expect(render1, equals(render2));
    });

    test('AnsiRenderer state is properly reset between renders', () {
      final file = _resolvePackageFile(
        'test/markdown/fixtures/comprehensive.md',
      );
      final content = file.readAsStringSync();

      // Render a complex document
      final firstRender = markdownToAnsi(content);

      // Render a simple document
      final simpleRender = markdownToAnsi('# Simple\n\nJust a test.');

      // Render the complex document again
      final secondRender = markdownToAnsi(content);

      // First and second renders of complex doc should be identical
      expect(firstRender, equals(secondRender));

      // Simple render should be much shorter
      expect(simpleRender.length, lessThan(firstRender.length ~/ 10));
    });
  });
}
