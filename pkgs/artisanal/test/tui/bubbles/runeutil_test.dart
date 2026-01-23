import 'package:artisanal/src/tui/bubbles/runeutil.dart';
import 'package:artisanal/src/unicode/grapheme.dart' as uni;
import 'package:test/test.dart';

void main() {
  group('Sanitizer', () {
    test('passes through normal text', () {
      final sanitizer = createSanitizer();
      final input = uni.codePoints('hello world');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello world');
    });

    test('replaces newlines with default replacement', () {
      final sanitizer = createSanitizer();
      final input = uni.codePoints('hello\nworld');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello\nworld');
    });

    test('replaces carriage return with newline replacement', () {
      final sanitizer = createSanitizer();
      final input = uni.codePoints('hello\rworld');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello\nworld');
    });

    test('replaces tabs with default replacement (4 spaces)', () {
      final sanitizer = createSanitizer();
      final input = uni.codePoints('hello\tworld');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello    world');
    });

    test('replaces newlines with custom replacement', () {
      final sanitizer = createSanitizer(
        SanitizerOptions(newlineReplacement: ' '),
      );
      final input = uni.codePoints('hello\nworld');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello world');
    });

    test('replaces tabs with custom replacement', () {
      final sanitizer = createSanitizer(SanitizerOptions(tabReplacement: ' '));
      final input = uni.codePoints('hello\tworld');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello world');
    });

    test('strips control characters', () {
      final sanitizer = createSanitizer();
      // Include some C0 control characters (bell, backspace)
      final input = [
        0x68,
        0x65,
        0x07,
        0x6C,
        0x08,
        0x6C,
        0x6F,
      ]; // "he\x07l\x08lo"
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello');
    });

    test('strips unicode replacement character', () {
      final sanitizer = createSanitizer();
      final input = [0x68, 0x65, 0xFFFD, 0x6C, 0x6C, 0x6F]; // "he\uFFFDllo"
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello');
    });

    test('handles multiple newlines', () {
      final sanitizer = createSanitizer(
        SanitizerOptions(newlineReplacement: ' '),
      );
      final input = uni.codePoints('a\n\n\nb');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'a   b');
    });

    test('handles multiple tabs', () {
      final sanitizer = createSanitizer(SanitizerOptions(tabReplacement: '-'));
      final input = uni.codePoints('a\t\tb');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'a--b');
    });

    test('handles mixed newlines and tabs', () {
      final sanitizer = createSanitizer(
        SanitizerOptions(newlineReplacement: '|', tabReplacement: '-'),
      );
      final input = uni.codePoints('a\t\nb');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'a-|b');
    });

    test('handles empty input', () {
      final sanitizer = createSanitizer();
      final result = sanitizer([]);
      expect(result, isEmpty);
    });

    test('handles CRLF line endings', () {
      final sanitizer = createSanitizer(
        SanitizerOptions(newlineReplacement: ' '),
      );
      final input = uni.codePoints('hello\r\nworld');
      final result = sanitizer(input);
      expect(String.fromCharCodes(result), 'hello  world');
    });
  });

  group('stringWidth', () {
    test('returns 0 for empty string', () {
      expect(stringWidth(''), 0);
    });

    test('returns correct width for ASCII', () {
      expect(stringWidth('hello'), 5);
    });

    test('returns correct width for CJK characters', () {
      // CJK characters are double-width
      expect(stringWidth('中'), 2);
      expect(stringWidth('中文'), 4);
    });

    test('returns correct width for mixed ASCII and CJK', () {
      expect(stringWidth('hello中'), 7);
      expect(stringWidth('中hello'), 7);
    });

    test('returns correct width for hiragana', () {
      expect(stringWidth('あ'), 2);
      expect(stringWidth('あい'), 4);
    });

    test('returns correct width for katakana', () {
      expect(stringWidth('ア'), 2);
      expect(stringWidth('アイ'), 4);
    });

    test('handles zero-width characters', () {
      // Zero-width space
      expect(stringWidth('a\u200Bb'), 2);
    });
  });

  group('runeWidth', () {
    test('returns 1 for ASCII characters', () {
      expect(runeWidth('a'.codeUnitAt(0)), 1);
      expect(runeWidth('Z'.codeUnitAt(0)), 1);
      expect(runeWidth(' '.codeUnitAt(0)), 1);
      expect(runeWidth(0x00A0), 1, reason: 'NBSP should be normal width');
    });

    test('returns 2 for CJK unified ideographs', () {
      expect(runeWidth(uni.firstCodePoint('中')), 2);
      expect(runeWidth(uni.firstCodePoint('国')), 2);
    });

    test('returns 0 for zero-width space', () {
      expect(runeWidth(0x200B), 0);
    });

    test('returns 0 for zero-width joiner', () {
      expect(runeWidth(0x200D), 0);
    });

    test('returns 0 for zero-width non-joiner', () {
      expect(runeWidth(0x200C), 0);
    });

    test('returns 0 for BOM', () {
      expect(runeWidth(0xFEFF), 0);
    });
  });

  group('truncate', () {
    test('returns empty for width 0', () {
      expect(truncate('hello', 0), '');
    });

    test('returns full string if fits', () {
      expect(truncate('hello', 10), 'hello');
    });

    test('truncates long string', () {
      expect(truncate('hello world', 5), 'hello');
    });

    test('truncates with tail', () {
      expect(truncate('hello world', 8, '...'), 'hello...');
    });

    test('handles width less than tail', () {
      // When width is less than tail, behavior is implementation-dependent
      // The truncate function may return empty or the tail
      final result = truncate('hello', 2, '...');
      expect(result.length, lessThanOrEqualTo(3));
    });

    test('handles CJK characters', () {
      // Each CJK char is width 2
      expect(stringWidth(truncate('中文字', 4)), lessThanOrEqualTo(4));
    });

    test('handles negative width', () {
      expect(truncate('hello', -1), '');
    });
  });

  group('firstGraphemeCluster', () {
    test('returns empty for empty string', () {
      final result = firstGraphemeCluster('');
      expect(result.first, '');
      expect(result.rest, '');
    });

    test('splits single character', () {
      final result = firstGraphemeCluster('a');
      expect(result.first, 'a');
      expect(result.rest, '');
    });

    test('splits multi-character string', () {
      final result = firstGraphemeCluster('abc');
      expect(result.first, 'a');
      expect(result.rest, 'bc');
    });

    test('handles CJK first character', () {
      final result = firstGraphemeCluster('中abc');
      expect(result.first, '中');
      expect(result.rest, 'abc');
    });
  });
}
