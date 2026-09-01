import 'package:ultraviolet/unicode.dart' as w;
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

    test('Dingbats: non-emoji are narrow, emoji-presentation are wide', () {
      // Checkmark: ✓ (U+2713) — text presentation, width 1
      expect(w.runeWidth(0x2713), 1);
      expect(w.stringWidth('✓'), 1);

      // First Dingbat (U+2700) — not in emoji presentation list, width 1
      expect(w.runeWidth(0x2700), 1);

      // Scissors: ✂ (U+2702) — text-default (Emoji_Presentation=No), width 1
      // Becomes width 2 only when followed by FE0F: ✂️
      expect(w.runeWidth(0x2702), 1);
      expect(w.stringWidth('\u2702\uFE0F'), w.emojiPresentationWidth);

      // Check mark: ✅ (U+2705) — emoji presentation, width 2
      expect(w.runeWidth(0x2705), w.emojiPresentationWidth);

      // Cross mark: ❌ (U+274C) — emoji presentation, width 2
      expect(w.runeWidth(0x274C), w.emojiPresentationWidth);

      // Double curly loop: ➿ (U+27BF) — emoji presentation, width 2
      expect(w.runeWidth(0x27BF), w.emojiPresentationWidth);
    });

    test('Miscellaneous Symbols: emoji-presentation are wide', () {
      // Chess pieces: ♔ (U+2654) — text presentation, width 1
      expect(w.runeWidth(0x2654), 1);
      expect(w.stringWidth('♔'), 1);

      // Sun: ☀ (U+2600) — text-default (Emoji_Presentation=No), width 1
      // Becomes width 2 only with FE0F: ☀️
      expect(w.runeWidth(0x2600), 1);
      expect(w.stringWidth('\u2600\uFE0F'), w.emojiPresentationWidth);

      // U+26FF — not in emoji presentation list, width 1
      expect(w.runeWidth(0x26FF), 1);

      // Telephone: ☎ (U+260E) — text-default, width 1
      expect(w.runeWidth(0x260E), 1);
      expect(w.stringWidth('\u260E\uFE0F'), w.emojiPresentationWidth);

      // Hot beverage: ☕ (U+2615) — Emoji_Presentation=Yes, width 2
      expect(w.runeWidth(0x2615), w.emojiPresentationWidth);

      // Warning: ⚠ (U+26A0) — text-default, width 1
      expect(w.runeWidth(0x26A0), 1);
      expect(w.stringWidth('\u26A0\uFE0F'), w.emojiPresentationWidth);

      // Snowman: ⛄ (U+26C4) — Emoji_Presentation=Yes, width 2
      expect(w.runeWidth(0x26C4), w.emojiPresentationWidth);

      // Recycling: ♻ (U+267B) — text-default, width 1
      expect(w.runeWidth(0x267B), 1);
      expect(w.stringWidth('\u267B\uFE0F'), w.emojiPresentationWidth);

      // Star: ⭐ (U+2B50) — Emoji_Presentation=Yes, width 2
      expect(w.runeWidth(0x2B50), w.emojiPresentationWidth);

      // Circle: ⭕ (U+2B55) — Emoji_Presentation=Yes, width 2
      expect(w.runeWidth(0x2B55), w.emojiPresentationWidth);
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

    test('FE0F variation selector upgrades grapheme width to emoji', () {
      // Characters that are width 1 by default, but width 2 when followed
      // by U+FE0F (emoji presentation selector).

      // ❤️ (U+2764 + U+FE0F) — heart with VS16
      // U+2764 is already in emoji presentation list, so width is 2 either way
      expect(w.stringWidth('❤️'), w.emojiPresentationWidth);

      // Characters that are NOT in the emoji presentation list should be
      // upgraded to width 2 when followed by FE0F.
      // Example: ✓️ (U+2713 + U+FE0F) — checkmark with VS16
      final checkWithVs16 = '\u2713\uFE0F';
      expect(
        w.stringWidth(checkWithVs16),
        w.emojiPresentationWidth,
        reason:
            'FE0F should upgrade non-emoji-presentation char to emoji width',
      );
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

    test('ASCII fast path preserves printable and control widths', () {
      expect(w.stringWidth('popup menu'), 10);
      expect(w.stringWidth('a\tb'), 2);
      expect(w.maxLineWidth('Action: open v'), 14);
    });

    test('simple unicode fast path handles BMP border glyphs', () {
      expect(w.stringWidth('╭─╮'), 3);
      expect(w.stringWidth('│中│'), 4);
      expect(w.maxLineWidth('╭─╮\n│中│'), 4);
    });

    test('mixed ASCII and emoji string width', () {
      // "Hello 🌍!" - "Hello " (6) + emoji (2) + "!" (1) = 9
      // Note: The space after "Hello" is 1 character
      final mixed = 'Hello 🌍!';
      // "Hello " = 6 chars, 🌍 = emojiPresentationWidth, "!" = 1
      expect(w.stringWidth(mixed), 6 + w.emojiPresentationWidth + 1);
    });

    test('Kitchen Sink emoji: characters that caused scroll corruption', () {
      // These are the specific characters from the markdown Kitchen Sink tab
      // that previously returned width 1 but terminals render at width 2,
      // causing the cell buffer to get out of sync with the terminal.
      //
      // After correcting _isEmojiPresentation() to only include
      // Emoji_Presentation=Yes code points, text-default chars are width 1
      // and only become width 2 via FE0F in stringWidth().
      final ew = w.emojiPresentationWidth;

      // Emoji_Presentation=Yes — always width 2
      expect(w.runeWidth(0x2615), ew, reason: '☕ hot beverage');
      expect(w.runeWidth(0x26A1), ew, reason: '⚡ lightning');
      expect(w.runeWidth(0x26C5), ew, reason: '⛅ sun behind cloud');
      expect(w.runeWidth(0x26C4), ew, reason: '⛄ snowman');
      expect(w.runeWidth(0x2614), ew, reason: '☔ umbrella');
      expect(w.runeWidth(0x2705), ew, reason: '✅ check mark');
      expect(w.runeWidth(0x274C), ew, reason: '❌ cross mark');
      expect(w.runeWidth(0x2728), ew, reason: '✨ sparkles');
      expect(w.runeWidth(0x2B50), ew, reason: '⭐ star');

      // Text-default (Emoji_Presentation=No) — width 1 without FE0F
      expect(w.runeWidth(0x26A0), 1, reason: '⚠ warning (text-default)');
      expect(w.runeWidth(0x26C8), 1, reason: '⛈ thunder cloud (text-default)');
      expect(w.runeWidth(0x267B), 1, reason: '♻ recycling (text-default)');
      expect(w.runeWidth(0x270C), 1, reason: '✌ victory hand (text-default)');
      expect(
        w.runeWidth(0x261D),
        1,
        reason: '☝ index pointing up (text-default)',
      );
      expect(w.runeWidth(0x2600), 1, reason: '☀ sun (text-default)');

      // Text-default chars become width 2 via FE0F in stringWidth()
      expect(w.stringWidth('\u26A0\uFE0F'), ew, reason: '⚠️ warning + FE0F');
      expect(w.stringWidth('\u26C8\uFE0F'), ew, reason: '⛈️ thunder + FE0F');
      expect(w.stringWidth('\u270C\uFE0F'), ew, reason: '✌️ victory + FE0F');
      expect(w.stringWidth('\u261D\uFE0F'), ew, reason: '☝️ index + FE0F');
      expect(w.stringWidth('\u2600\uFE0F'), ew, reason: '☀️ sun + FE0F');

      // String width for lines containing Emoji_Presentation=Yes characters
      // "Food: ☕🍕🍔" — "Food: " (6) + ☕ (2) + 🍕 (2) + 🍔 (2) = 12
      expect(w.stringWidth('Food: ☕🍕🍔'), 6 + ew * 3);

      // "Weather: ☀⛅⛈" — ☀ and ⛈ are text-default (width 1), ⛅ is emoji (width 2)
      // "Weather: " (9) + ☀(1) + ⛅(2) + ⛈(1) = 13
      expect(w.stringWidth('Weather: ☀⛅⛈'), 9 + 1 + ew + 1);
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

  group('Supplementary emoji ranges', () {
    test('Mahjong and Playing Cards (U+1F000..U+1F0FF)', () {
      final ew = w.emojiPresentationWidth;
      expect(w.runeWidth(0x1F004), ew, reason: '🀄 mahjong red dragon');
      expect(w.runeWidth(0x1F0CF), ew, reason: '🃏 joker');
    });

    test('Enclosed Alphanumerics (U+1F100..U+1F1FF)', () {
      final ew = w.emojiPresentationWidth;
      expect(w.runeWidth(0x1F18E), ew, reason: '🆎 AB button');
      expect(w.runeWidth(0x1F191), ew, reason: '🆑 CL button');
      expect(w.runeWidth(0x1F19A), ew, reason: '🆚 VS button');
      // Regional indicators (flags)
      expect(w.runeWidth(0x1F1E6), ew, reason: '🇦 regional indicator A');
      expect(w.runeWidth(0x1F1FF), ew, reason: '🇿 regional indicator Z');
    });

    test('Enclosed Ideographic Supplement (U+1F200..U+1F2FF)', () {
      final ew = w.emojiPresentationWidth;
      expect(w.runeWidth(0x1F201), ew, reason: '🈁 Japanese "here"');
      expect(w.runeWidth(0x1F21A), ew, reason: '🈚 Japanese "free"');
      expect(w.runeWidth(0x1F22F), ew, reason: '🈯 Japanese "reserved"');
      expect(w.runeWidth(0x1F232), ew, reason: '🈲 Japanese "prohibited"');
      expect(w.runeWidth(0x1F251), ew, reason: '🉑 Japanese "acceptable"');
    });

    test('Geometric Shapes Extended (U+1F7E0..U+1F7FF)', () {
      final ew = w.emojiPresentationWidth;
      expect(w.runeWidth(0x1F7E0), ew, reason: '🟠 orange circle');
      expect(w.runeWidth(0x1F7EB), ew, reason: '🟫 brown square');
      expect(w.runeWidth(0x1F7F0), ew, reason: '🟰 heavy equals sign');
    });
  });
}
