import 'package:test/test.dart';
import 'package:ultraviolet/rendering.dart';

void main() {
  test('clips wide glyphs to spaces without moving the cell boundaries', () {
    expect(clipAnsiByCells('A界B', 0, 2), 'A ');
    expect(clipAnsiByCells('A界B', 2, 4), ' B');
    expect(clipAnsiByCells('A界B', 1, 3), '界');
    expect(clipAnsiByCells('A界B', 1, 2), ' ');
    // Existing snapping semantics remain available for whole-grapheme slicing.
    expect(cutAnsiByCells('A界B', 2, 4), '界B');
  });

  test('restores style and hyperlink on a blank partial-glyph cell', () {
    for (final terminator in ['\x07', '\x1b\\']) {
      final source =
          'A\x1b[31;44m\x1b]8;;https://example.test$terminator'
          '界\x1b[0m\x1b]8;;${terminator}B';
      final screen = ScreenBuffer(2, 1);
      StyledString(clipAnsiByCells(source, 2, 4)).draw(screen, screen.bounds());
      expect(screen.cellAt(0, 0)!.content, ' ');
      expect(screen.cellAt(0, 0)!.style.fg, const UvBasic16(1));
      expect(screen.cellAt(0, 0)!.style.bg, const UvBasic16(4));
      expect(screen.cellAt(0, 0)!.link.url, 'https://example.test');
      expect(screen.cellAt(1, 0)!.content, 'B');
      expect(screen.cellAt(1, 0)!.style.isZero, isTrue);
      expect(screen.cellAt(1, 0)!.link.isZero, isTrue);
    }
  });

  test('keeps combining sequences and emoji graphemes atomic', () {
    expect(clipAnsiByCells('ae\u0301b', 1, 2), 'e\u0301');
    expect(clipAnsiByCells('A🚧B', 0, 2), 'A ');
    expect(clipAnsiByCells('A🚧B', 2, 4), ' B');
  });

  test('uses the shared SGR parser for colored underline restoration', () {
    for (final color in ['58;2;10;20;30', '58:2::10:20:30']) {
      final source = '\x1b[4:3;${color}mABC\x1b[59mD';
      for (final cut in [clipAnsiByCells, cutAnsiByCells]) {
        final screen = ScreenBuffer(2, 1);
        StyledString(cut(source, 2, 4)).draw(screen, screen.bounds());
        expect(screen.cellAt(0, 0)!.style.underline, UnderlineStyle.curly);
        expect(
          screen.cellAt(0, 0)!.style.underlineColor,
          const UvRgb(10, 20, 30),
        );
        expect(screen.cellAt(1, 0)!.style.underlineColor, isNull);
      }
    }
  });

  test('never emits fragments of a terminal graphics payload', () {
    const image = '\x1b_Ga=T,c=4;AAAA\x1b\\';
    expect(clipAnsiByCells(image, 0, 4), image);
    expect(clipAnsiByCells(image, 1, 3), '  ');
    expect(clipAnsiByCells('A${image}B', 3, 6), '  B');
  });

  test('handles empty, negative, and out-of-range intervals', () {
    expect(clipAnsiByCells('', 0, 2), '');
    expect(clipAnsiByCells('abc', -2, 2), 'ab');
    expect(clipAnsiByCells('abc', 2, 9), 'c');
    expect(clipAnsiByCells('abc', 9, 12), '');
    expect(clipAnsiByCells('abc', 2, 1), '');
  });
}
