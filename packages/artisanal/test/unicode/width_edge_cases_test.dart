import 'package:artisanal/src/unicode/width.dart' as w;
import 'package:test/test.dart';

void main() {
  group('Unicode width edge cases', () {
    test('ZWJ emoji sequences are counted as single grapheme clusters', () {
      // ZWJ (Zero Width Joiner) sequences should be counted as a single
      // grapheme cluster, not as multiple characters.
      //
      // Family emoji: 👨‍👩‍👧‍👦 (man + ZWJ + woman + ZWJ + girl + ZWJ + boy)
      // This is a single grapheme cluster that should have width 2 (emoji width).
      final family = '👨‍👩‍👧‍👦';
      final width = w.stringWidth(family);

      // The width should be emojiPresentationWidth (default 2), not the sum
      // of individual emoji widths (which would be 8 if each was width 2).
      expect(
        width,
        w.emojiPresentationWidth,
        reason:
            'ZWJ sequence should be single cluster with width ${w.emojiPresentationWidth}, got $width',
      );
    });

    test('single emoji has expected width', () {
      // Basic emoji in the 0x1F300-0x1F9FF range
      expect(w.stringWidth('🍕'), w.emojiPresentationWidth); // Pizza
      expect(w.stringWidth('😀'), w.emojiPresentationWidth); // Grinning face
      expect(w.stringWidth('🎉'), w.emojiPresentationWidth); // Party popper
    });

    test('ZWJ profession emoji sequences', () {
      // Woman technologist: 👩‍💻 (woman + ZWJ + laptop)
      final womanTech = '👩‍💻';
      expect(w.stringWidth(womanTech), w.emojiPresentationWidth);

      // Man health worker: 👨‍⚕️ (man + ZWJ + staff of aesculapius + VS16)
      final manHealth = '👨‍⚕️';
      expect(w.stringWidth(manHealth), w.emojiPresentationWidth);
    });

    test('flag sequences (regional indicators)', () {
      // Flags are made of two regional indicator symbols
      // US flag: 🇺🇸 (U+1F1FA U+1F1F8)
      final usFlag = '🇺🇸';
      // Regional indicators are in the emoji range (0x1F1E0-0x1F1FF)
      // Each regional indicator has width emojiPresentationWidth
      // But as a grapheme cluster (flag), it counts as one cluster
      final width = w.stringWidth(usFlag);
      expect(
        width,
        w.emojiPresentationWidth,
        reason: 'Flag emoji should be width ${w.emojiPresentationWidth}',
      );

      // Individual regional indicator symbols
      expect(w.runeWidth(0x1F1FA), w.emojiPresentationWidth); // U (regional)
      expect(w.runeWidth(0x1F1F8), w.emojiPresentationWidth); // S (regional)
    });

    test('skin tone modifiers', () {
      // Hand with skin tone: 👋🏽 (waving hand + medium skin tone)
      final wavingHand = '👋🏽';
      expect(w.stringWidth(wavingHand), w.emojiPresentationWidth);
    });

    test('variation selectors are zero-width', () {
      // Variation selector 16 (VS16) makes preceding char emoji presentation
      // Heart with VS16: ❤️ (U+2764 U+FE0F)
      // The VS16 itself should be zero-width
      expect(w.runeWidth(0xFE0F), 0, reason: 'VS16 should be zero-width');
      // All variation selectors in VS1-VS16 range
      expect(w.runeWidth(0xFE00), 0, reason: 'VS1 should be zero-width');
      // Variation Selectors Supplement (VS17-VS256)
      expect(w.runeWidth(0xE0100), 0, reason: 'VS17 should be zero-width');
      expect(w.runeWidth(0xE01EF), 0, reason: 'VS256 should be zero-width');
    });

    test('combining characters are zero-width', () {
      // Combining acute accent (U+0301)
      expect(w.runeWidth(0x0301), 0);

      // Character with combining mark: é (e + combining acute)
      final eWithAccent = 'e\u0301';
      // This is a single grapheme cluster, width of 'e' = 1
      expect(w.stringWidth(eWithAccent), 1);
    });

    test('CJK characters are wide (width 2)', () {
      // Basic CJK ideographs
      expect(w.runeWidth(0x4E00), 2); // 一 (one)
      expect(w.runeWidth(0x4E2D), 2); // 中 (middle)
      expect(w.runeWidth(0x56FD), 2); // 国 (country)

      // Full string width
      expect(w.stringWidth('中国'), 4);
    });

    test('Hangul syllables are wide (width 2)', () {
      expect(w.runeWidth(0xAC00), 2); // 가 (first Hangul syllable)
      expect(w.runeWidth(0xD7A3), 2); // last Hangul syllable

      expect(w.stringWidth('한글'), 4);
    });

    test('fullwidth ASCII characters are wide', () {
      // Fullwidth 'A' (U+FF21)
      expect(w.runeWidth(0xFF21), 2);
      // Fullwidth '0' (U+FF10)
      expect(w.runeWidth(0xFF10), 2);

      expect(w.stringWidth('ＡＢＣ'), 6);
    });

    test('control characters are zero-width', () {
      expect(w.runeWidth(0x00), 0); // NUL
      expect(w.runeWidth(0x1B), 0); // ESC
      expect(w.runeWidth(0x7F), 0); // DEL
    });

    test('ZWJ and ZWNJ are zero-width', () {
      expect(w.runeWidth(0x200D), 0); // ZWJ
      expect(w.runeWidth(0x200C), 0); // ZWNJ
      expect(w.runeWidth(0x200B), 0); // ZWSP
    });

    test('maxLineWidth handles multiline strings', () {
      expect(w.maxLineWidth('abc\ndef'), 3);
      expect(w.maxLineWidth('中国\nabc'), 4); // 中国 = width 4
      expect(w.maxLineWidth('a\nbb\nccc'), 3);
      expect(w.maxLineWidth(''), 0);
      expect(w.maxLineWidth('single'), 6);
    });

    test('mixed ASCII and emoji string width', () {
      // "Hello 🌍!" - "Hello " (6) + emoji (2) + "!" (1) = 9
      // Note: The space after "Hello" is 1 character
      final mixed = 'Hello 🌍!';
      // "Hello " = 6 chars, 🌍 = emojiPresentationWidth, "!" = 1
      expect(w.stringWidth(mixed), 6 + w.emojiPresentationWidth + 1);
    });
  });

  group('CJK Extension ranges (known limitations)', () {
    // These tests document current behavior for CJK Extension B+ ranges.
    // The current implementation only covers the basic CJK range up to
    // 0x9FFF and 0x20000-0x3FFFF. Some extended ranges may not be covered.

    test('CJK Extension A characters in range', () {
      // CJK Extension A: U+3400..U+4DBF
      // These are within the 0x2E80-0x9FFF range check
      expect(w.runeWidth(0x3400), 2);
      expect(w.runeWidth(0x4DBF), 2);
    });

    test('CJK Extension B characters (in supplementary plane)', () {
      // CJK Extension B: U+20000..U+2A6DF
      // These should be covered by the 0x20000-0x3FFFF range
      expect(w.runeWidth(0x20000), 2);
      expect(w.runeWidth(0x2A6DF), 2);
    });
  });
}
