import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

void main() {
  group('Buffer.draw clip', () {
    test('default draw is a no-op when destination is out of bounds', () {
      final src = Buffer.create(3, 1);
      src.setCell(0, 0, Cell(content: 'A', width: 1));
      src.setCell(1, 0, Cell(content: 'B', width: 1));
      src.setCell(2, 0, Cell(content: 'C', width: 1));

      final dest = Canvas(3, 1);
      src.draw(dest, rect(-1, 0, 3, 1));
      expect(dest.cellAt(0, 0)!.isEmpty, isTrue);
      dest.dispose();
    });

    test('clipped draw writes the overlapping cells', () {
      final src = Buffer.create(3, 1);
      src.setCell(0, 0, Cell(content: 'A', width: 1));
      src.setCell(1, 0, Cell(content: 'B', width: 1));
      src.setCell(2, 0, Cell(content: 'C', width: 1));

      final dest = Canvas(3, 1);
      src.draw(dest, rect(-1, 0, 3, 1), clip: true);
      expect(dest.cellAt(0, 0)!.content, 'B');
      expect(dest.cellAt(1, 0)!.content, 'C');
      expect(dest.cellAt(2, 0)!.isEmpty, isTrue);
      dest.dispose();
    });

    test('skipEmpty does not wipe destination glyphs', () {
      final src = Buffer.create(2, 1);
      src.setCell(0, 0, Cell(content: 'X', width: 1));
      final dest = Canvas(2, 1);
      dest.setCell(1, 0, Cell(content: 'Y', width: 1));
      src.draw(dest, rect(0, 0, 2, 1), skipEmpty: true);
      expect(dest.cellAt(0, 0)!.content, 'X');
      expect(dest.cellAt(1, 0)!.content, 'Y');
      dest.dispose();
    });
  });

  group('untrimmed render', () {
    test('Buffer.render keeps trailing empty cells when requested', () {
      final b = Buffer.create(4, 1);
      b.setCell(0, 0, Cell(content: 'A', width: 1));
      expect(b.render(), 'A');
      expect(b.render(trimTrailing: false), 'A   ');
    });

    test('Canvas.render keeps trailing empty cells when requested', () {
      final c = Canvas(4, 1);
      c.setCell(0, 0, Cell(content: 'A', width: 1));
      expect(c.render(), 'A');
      expect(c.render(trimTrailing: false), 'A   ');
    });
  });

  group('strokes', () {
    test('drawHorizontal writes a run and clips to bounds', () {
      final dest = Canvas(4, 1);
      drawHorizontal(dest, 1, 0, 4, glyph: '-');
      expect(dest.render(trimTrailing: false), ' ---');
      dest.dispose();
    });

    test('drawVertical writes a run', () {
      final dest = Canvas(1, 3);
      drawVertical(dest, 0, 0, 3, glyph: '|');
      expect(dest.render(), '|\n|\n|');
      dest.dispose();
    });

    test('drawStroke writes a diagonal with a fixed glyph', () {
      final dest = Canvas(3, 3);
      drawStroke(dest, 0, 0, 2, 2, glyph: '\\');
      expect(dest.cellAt(0, 0)!.content, '\\');
      expect(dest.cellAt(1, 1)!.content, '\\');
      expect(dest.cellAt(2, 2)!.content, '\\');
      dest.dispose();
    });
  });
}
