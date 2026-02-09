import 'package:nocterm/src/utils/unicode_width.dart';
import 'package:test/test.dart';

void main() {
  group('Unicode Width Calculation', () {
    test('sparkles emoji width', () {
      final sparkles = '✨';
      final sparklesCode = sparkles.runes.first;

      // ✨ is U+2728
      expect(sparklesCode, equals(0x2728));

      // Should have width of 2 (double-width)
      expect(UnicodeWidth.runeWidth(sparklesCode), equals(2));

      // String width should also be 2
      expect(UnicodeWidth.stringWidth(sparkles), equals(2));
    });

    test('common emoji widths', () {
      final emojis = {
        '✨': 2, // Sparkles
        '⭐': 2, // Star
        '💫': 2, // Dizzy
        '🌟': 2, // Glowing star
        '☀': 2, // Sun
        '☁': 2, // Cloud
        '🚀': 2, // Rocket
        '💻': 2, // Computer
        '🎯': 2, // Target
        '🔥': 2, // Fire
      };

      emojis.forEach((emoji, expectedWidth) {
        expect(
          UnicodeWidth.stringWidth(emoji),
          equals(expectedWidth),
          reason: 'Emoji $emoji should have width $expectedWidth',
        );
      });
    });

    test('ASCII character widths', () {
      final asciiChars = {
        'A': 1,
        'B': 1,
        '1': 1,
        '!': 1,
        ' ': 1,
        '\t': 1, // Tab counts as 1
      };

      asciiChars.forEach((char, expectedWidth) {
        expect(
          UnicodeWidth.stringWidth(char),
          equals(expectedWidth),
          reason: 'ASCII char "$char" should have width $expectedWidth',
        );
      });
    });

    test('CJK character widths', () {
      final cjkChars = {
        '中': 2, // Chinese
        '日': 2, // Japanese
        '한': 2, // Korean
        '文': 2, // Chinese/Japanese
      };

      cjkChars.forEach((char, expectedWidth) {
        expect(
          UnicodeWidth.stringWidth(char),
          equals(expectedWidth),
          reason: 'CJK char "$char" should have width $expectedWidth',
        );
      });
    });

    test('mixed string widths', () {
      final testCases = {
        'Hello World': 11, // All ASCII
        '✨ Features:': 12, // Emoji (2) + space (1) + ASCII (9)
        'Hello 🌍 World': 14, // ASCII (6) + emoji (2) + ASCII (6)
        'Mixed 💻 text': 13, // ASCII (6) + emoji (2) + ASCII (5)
        '🚀 Rocket': 9, // Emoji (2) + space (1) + ASCII (6)
        'Code 💻 + Coffee ☕ = 🎯': 24, // Complex mix
        '中文text': 8, // CJK (4) + ASCII (4)
      };

      testCases.forEach((text, expectedWidth) {
        expect(
          UnicodeWidth.stringWidth(text),
          equals(expectedWidth),
          reason: 'String "$text" should have width $expectedWidth',
        );
      });
    });

    test('emoji range detection', () {
      // Test specific emoji ranges
      final sparklesCode = 0x2728;

      // Check if it's in the expected range
      expect(sparklesCode >= 0x2700 && sparklesCode <= 0x27BF, isTrue);

      // Other emojis in various ranges
      final testEmojis = [
        ('☀', 0x2600), // Sun - Miscellaneous Symbols
        ('☁', 0x2601), // Cloud - Miscellaneous Symbols
        ('✨', 0x2728), // Sparkles - Dingbats
        ('⭐', 0x2B50), // Star - Miscellaneous Symbols and Arrows
      ];

      for (final (emoji, expectedCode) in testEmojis) {
        final code = emoji.runes.first;
        expect(
          code,
          equals(expectedCode),
          reason:
              'Emoji $emoji should have code U+${expectedCode.toRadixString(16).toUpperCase()}',
        );
      }
    });

    test('zero-width characters', () {
      // Some characters have zero width (combining marks, etc.)
      // These should be handled correctly
      final zeroWidthJoiner = '\u200D';
      expect(UnicodeWidth.stringWidth(zeroWidthJoiner), equals(0));
    });

    test('string with combining characters', () {
      // Test combining emoji sequences
      final familyEmoji = '👨‍👩‍👧‍👦'; // Family emoji with ZWJ
      // This is a complex emoji that might render as one glyph
      // but has multiple codepoints
      final width = UnicodeWidth.stringWidth(familyEmoji);
      expect(width, greaterThanOrEqualTo(2)); // Should be at least 2
    });

    test('bullet point character', () {
      final bullet = '•';
      final bulletCode = bullet.runes.first;

      // • is U+2022 (Bullet)
      expect(bulletCode, equals(0x2022));

      // Bullet might be width 1 or 2 depending on terminal
      final width = UnicodeWidth.runeWidth(bulletCode);
      expect(width, anyOf(equals(1), equals(2)));
    });

    test('text alignment calculation', () {
      // Test that we can calculate proper alignment
      final text1 = 'Hello World!'; // 12 chars, 12 width
      final text2 = '✨ Features:'; // 11 chars, 12 width

      expect(text1.length, equals(12));
      expect(UnicodeWidth.stringWidth(text1), equals(12));

      expect(text2.length, equals(11));
      expect(UnicodeWidth.stringWidth(text2), equals(12));

      // Both should center the same in a 45-width container
      final containerWidth = 45;
      final offset1 = (containerWidth - UnicodeWidth.stringWidth(text1)) ~/ 2;
      final offset2 = (containerWidth - UnicodeWidth.stringWidth(text2)) ~/ 2;

      expect(offset1, equals(offset2));
      expect(offset1, equals(16)); // (45 - 12) / 2 = 16.5 -> 16
    });
  });
}
