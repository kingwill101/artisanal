import 'package:nocterm/src/utils/unicode_width.dart';
import 'package:test/test.dart';

void main() {
  group('Emoji Variation Selector (FE0F) Width', () {
    test('symbols with FE0F should have width 2', () {
      // Symbols with emoji variation selector (U+FE0F) should render as emoji (width 2)
      final symbolsWithFE0F = {
        "⚠️": "Warning sign",
        "❤️": "Red heart",
        "☎️": "Telephone",
        "✔️": "Check mark",
        "☢️": "Radioactive",
        "☣️": "Biohazard",
        "♻️": "Recycling",
        "⚙️": "Gear",
        "⚔️": "Crossed swords",
        "⚖️": "Balance scale",
        "⚗️": "Alembic",
        "⚛️": "Atom symbol",
        "⚜️": "Fleur-de-lis",
        "☀️": "Sun",
        "☁️": "Cloud",
      };

      for (final entry in symbolsWithFE0F.entries) {
        final symbol = entry.key;
        final name = entry.value;
        final width = UnicodeWidth.stringWidth(symbol);

        expect(
          width,
          equals(2),
          reason: '$name ($symbol) with FE0F should have width 2, got $width',
        );
      }
    });

    test('same symbols without FE0F should have width 1', () {
      // Text symbols without emoji variation selector should have width 1
      final textSymbols = {
        "⚠": "Warning sign",
        "❤": "Heart",
        "☎": "Telephone",
        "✔": "Check mark",
        "☢": "Radioactive",
        "☣": "Biohazard",
        "♻": "Recycling",
        "⚙": "Gear",
        "⚔": "Crossed swords",
        "⚖": "Balance scale",
        "⚗": "Alembic",
        "⚛": "Atom symbol",
        "⚜": "Fleur-de-lis",
      };

      for (final entry in textSymbols.entries) {
        final symbol = entry.key;
        final name = entry.value;
        final width = UnicodeWidth.stringWidth(symbol);

        expect(
          width,
          equals(1),
          reason:
              '$name ($symbol) without FE0F should have width 1, got $width',
        );
      }
    });

    test('symbols that are already emoji (no FE0F needed) should have width 2',
        () {
      // These symbols are emoji by default and don't need FE0F
      final defaultEmoji = {
        "⭐": "Star",
        "✨": "Sparkles",
        "⚡": "High voltage",
        "⛔": "No entry",
        "⬛": "Black square",
        "⬜": "White square",
        "🔶": "Orange diamond",
        "🔷": "Blue diamond",
        "✅": "Check mark button",
        "❌": "Cross mark",
      };

      for (final entry in defaultEmoji.entries) {
        final symbol = entry.key;
        final name = entry.value;
        final width = UnicodeWidth.stringWidth(symbol);

        expect(
          width,
          equals(2),
          reason: '$name ($symbol) should have width 2, got $width',
        );
      }
    });

    test('FE0F detection in grapheme', () {
      // Verify FE0F is correctly identified
      final withFE0F = "⚠️";
      final withoutFE0F = "⚠";

      expect(withFE0F.runes.contains(0xFE0F), isTrue);
      expect(withoutFE0F.runes.contains(0xFE0F), isFalse);

      expect(UnicodeWidth.graphemeWidth(withFE0F), equals(2));
      expect(UnicodeWidth.graphemeWidth(withoutFE0F), equals(1));
    });
  });
}
