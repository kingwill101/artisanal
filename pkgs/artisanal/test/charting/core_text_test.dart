import 'package:artisanal/artisanal.dart';
import 'package:artisanal/uv.dart';
import 'package:test/test.dart';

void main() {
  test('putText preserves ASCII placement and rendering', () {
    final canvas = Canvas(5, 1);

    putText(canvas, canvas.bounds(), 1, 0, 'abc', const UvStyle());

    expect(canvas.render(), ' abc');
    expect(
      canvas.buffer.lines.single.cells.map((cell) => cell.content).toList(),
      [' ', 'a', 'b', 'c', ' '],
    );
  });

  test('putText stores wide graphemes and their placeholder cell', () {
    final canvas = Canvas(4, 1);
    const style = UvStyle(fg: UvColor.rgb(12, 34, 56));

    putText(canvas, canvas.bounds(), 0, 0, '界A', style);

    final cells = canvas.buffer.lines.single.cells;
    expect(cells[0].content, '界');
    expect(cells[0].width, 2);
    expect(cells[0].style, style);
    expect(cells[1].width, 0);
    expect(cells[1].content, isEmpty);
    expect(cells[2].content, 'A');
  });

  test('putText keeps combining clusters in one cell', () {
    final canvas = Canvas(3, 1);

    putText(canvas, canvas.bounds(), 0, 0, 'e\u0301x', const UvStyle());

    final cells = canvas.buffer.lines.single.cells;
    expect(cells[0].content, 'e\u0301');
    expect(cells[0].width, 1);
    expect(cells[1].content, 'x');
  });

  test('putText clips whole wide graphemes on both viewport edges', () {
    final left = Canvas(5, 1);
    putText(left, rect(1, 0, 4, 1), 0, 0, '界A', const UvStyle());
    expect(left.buffer.lines.single.cells[1].content, ' ');
    expect(left.buffer.lines.single.cells[2].content, 'A');

    final right = Canvas(5, 1);
    putText(right, rect(0, 0, 3, 1), 2, 0, '界A', const UvStyle());
    expect(right.buffer.lines.single.cells[2].content, ' ');
    expect(right.buffer.lines.single.cells[3].content, ' ');
  });

  test('putText clips emoji as a wide grapheme', () {
    final canvas = Canvas(4, 1);

    putText(canvas, rect(1, 0, 3, 1), 1, 0, '🙂', const UvStyle());

    expect(canvas.buffer.lines.single.cells[1].content, '🙂');
    expect(canvas.buffer.lines.single.cells[1].width, 2);
    expect(canvas.buffer.lines.single.cells[2].width, 0);
  });
}
