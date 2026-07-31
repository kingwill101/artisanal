import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

/// Strips all ANSI escape sequences from a string for plain-text comparison.
String stripAnsi(String input) {
  // Matches CSI sequences (e.g., \x1b[0m) and OSC 8 sequences
  return input
      .replaceAll(RegExp(r'\x1b\[[0-9;]*m'), '')
      .replaceAll(RegExp(r'\x1b\]8;[^\\]*\x1b\\'), '');
}

void main() {
  group('nested lists', () {
    test('renders nested unordered list items on separate lines', () {
      final result = markdownToAnsi(
        '- Parent item\n  - Child item A\n  - Child item B\n- Another parent',
      );
      final plain = stripAnsi(result);

      // Each item should be on its own line
      final lines = plain
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(lines.length, greaterThanOrEqualTo(4));
      expect(lines[0], contains('Parent item'));
      expect(lines[1], contains('Child item A'));
      expect(lines[2], contains('Child item B'));
      expect(lines[3], contains('Another parent'));
    });

    test('nested items are indented relative to parent', () {
      final result = markdownToAnsi('- Parent\n  - Child\n    - Grandchild');
      final plain = stripAnsi(result);
      final lines = plain
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      expect(lines.length, greaterThanOrEqualTo(3));
      // Parent has no leading indent
      expect(lines[0], matches(RegExp(r'^\S')));
      // Child has 2-space indent (default listIndent)
      expect(lines[1], matches(RegExp(r'^  \S')));
      // Grandchild has 4-space indent
      expect(lines[2], matches(RegExp(r'^    \S')));
    });

    test('nested ordered list inside unordered list', () {
      final result = markdownToAnsi('- Parent\n  1. First\n  2. Second');
      final plain = stripAnsi(result);
      final lines = plain
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      expect(lines.length, greaterThanOrEqualTo(3));
      expect(lines[0], contains('Parent'));
      expect(lines[1], contains('1.'));
      expect(lines[1], contains('First'));
      expect(lines[2], contains('2.'));
      expect(lines[2], contains('Second'));
    });

    test('multiple parents with nested children', () {
      final result = markdownToAnsi('''- Parent A
  - Child A1
  - Child A2
- Parent B
  - Child B1''');
      final plain = stripAnsi(result);
      final lines = plain
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      expect(lines.length, greaterThanOrEqualTo(5));
      expect(lines[0], contains('Parent A'));
      expect(lines[1], contains('Child A1'));
      expect(lines[2], contains('Child A2'));
      expect(lines[3], contains('Parent B'));
      expect(lines[4], contains('Child B1'));
    });

    test(
      'paragraph list items keep their text attached before nested lists',
      () {
        final result = markdownToAnsi(
          '''* **New Features**
  * Improved raw-mode input handling
  * Mouse input now reaches stdin
* **Bug Fixes**
  * Restored console settings on exit''',
          options: const AnsiRendererOptions(width: 80),
        );
        final plain = stripAnsi(result);
        final lines = plain
            .split('\n')
            .map((line) => line.trimRight())
            .toList();

        expect(lines, isNot(contains('•')));
        expect(lines, contains('• New Features'));
        expect(lines, contains('• Bug Fixes'));
        expect(plain, contains('  • Improved raw-mode input handling'));
        expect(plain, contains('  • Mouse input now reaches stdin'));
        expect(plain, contains('  • Restored console settings on exit'));
      },
    );

    test(
      'renders CodeRabbit release notes summary bullets on the same line',
      () {
        final result = markdownToAnsi('''
<!-- This is an auto-generated comment: release notes by coderabbit.ai -->
## Summary by CodeRabbit

* **New Features**
  * Improved Windows terminal raw-mode input handling by automatically enabling virtual-terminal input when entering raw mode, and restoring the previous console input settings when exiting.
  * Enhances compatibility for advanced console interactions (including mouse input), with changes applied only to the standard input stream.

* **Bug Fixes**
  * Fixed raw-mode lifecycle to preserve and restore Windows console settings correctly, including safe behavior for nested enable/restore scenarios and non-Windows platforms.
<!-- end of auto-generated comment: release notes by coderabbit.ai -->
''', options: const AnsiRendererOptions(width: 80));
        final plain = stripAnsi(result);

        expect(plain, contains('• New Features'));
        expect(plain, contains('• Bug Fixes'));
        expect(plain, isNot(contains('\n•\nNew Features')));
        expect(plain, isNot(contains('\n•\nBug Fixes')));
      },
    );

    test('deeply nested list (3 levels)', () {
      final result = markdownToAnsi('''- Level 1
  - Level 2
    - Level 3a
    - Level 3b
  - Level 2b''');
      final plain = stripAnsi(result);
      final lines = plain
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      expect(lines.length, greaterThanOrEqualTo(5));
      expect(lines[0], contains('Level 1'));
      expect(lines[1], contains('Level 2'));
      expect(lines[2], contains('Level 3a'));
      expect(lines[3], contains('Level 3b'));
      expect(lines[4], contains('Level 2b'));
    });
  });

  group('inline code styling', () {
    test('inline code has ANSI styling without width', () {
      final result = markdownToAnsi('Use `print()` function');
      // Should contain ANSI escape sequences around the code
      expect(result, contains('\x1b['));
      expect(result, contains('print()'));
      expect(result, contains('\x1b[0m'));
    });

    test('inline code has ANSI styling with width', () {
      final result = markdownToAnsi(
        'Inline code: `var x = 42;`',
        options: const AnsiRendererOptions(width: 60),
      );
      // Should contain ANSI escape sequences around the code
      expect(result, contains('\x1b['));
      expect(result, contains('var x = 42;'));
      expect(result, contains('\x1b[0m'));

      // The styling should wrap the code text, not appear separately
      final idx = result.indexOf('var x = 42;');
      expect(idx, greaterThan(0));
      // ANSI open should appear before the code text
      final beforeCode = result.substring(0, idx);
      expect(beforeCode, contains('\x1b['));
    });

    test('inline code styling is identical with and without width', () {
      final md = 'Use `print()` here';
      final withoutWidth = markdownToAnsi(md);
      final withWidth = markdownToAnsi(
        md,
        options: const AnsiRendererOptions(width: 80),
      );

      // Both should contain the styled code.
      expect(withoutWidth, contains('\x1b['));
      expect(withoutWidth, contains('print()'));
      expect(withoutWidth, contains('\x1b[0m'));
      expect(withWidth, contains('\x1b['));
      expect(withWidth, contains('print()'));
      expect(withWidth, contains('\x1b[0m'));
    });

    test('bold text styling preserved with width', () {
      final result = markdownToAnsi(
        'This is **bold** text',
        options: const AnsiRendererOptions(width: 60),
      );
      // Bold ANSI code is \x1b[1m
      expect(result, contains('\x1b[1m'));
      expect(result, contains('bold'));
    });

    test('italic text styling preserved with width', () {
      final result = markdownToAnsi(
        'This is *italic* text',
        options: const AnsiRendererOptions(width: 60),
      );
      // Italic ANSI code is \x1b[3m
      expect(result, contains('\x1b[3m'));
      expect(result, contains('italic'));
    });

    test('link styling preserved with width', () {
      final result = markdownToAnsi(
        'Click [here](https://example.com) now',
        options: const AnsiRendererOptions(width: 60),
      );
      expect(result, contains('here'));
      // Should have link styling (underline + blue)
      expect(result, contains('\x1b['));
    });

    test('mixed inline styles in paragraph with width', () {
      final result = markdownToAnsi(
        'Use **bold**, *italic*, and `code` together',
        options: const AnsiRendererOptions(width: 80),
      );
      final plain = stripAnsi(result);
      expect(plain, contains('bold'));
      expect(plain, contains('italic'));
      expect(plain, contains('code'));
      // Should have multiple ANSI sequences
      expect(RegExp(r'\x1b\[').allMatches(result).length, greaterThan(3));
    });
  });
}
