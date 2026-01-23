import 'package:artisanal/src/uv/uv.dart';
import 'package:artisanal/src/unicode/width.dart';
import 'package:test/test.dart';

void main() {
  test('styledStringBounds expands tabs (default width 4)', () {
    final b = styledStringBounds('a\tb', WidthMethod.grapheme);
    expect(b.width, 6);
    expect(b.height, 1);
  });

  test('StyledString.draw expands tabs into space cells', () {
    final screen = ScreenBuffer(10, 1);
    final ss = newStyledString('a\tb');
    ss.draw(screen, rect(0, 0, 10, 1));

    expect(screen.cellAt(0, 0)!.content, 'a');
    for (var x = 1; x <= 4; x++) {
      expect(screen.cellAt(x, 0)!.content, ' ');
    }
    expect(screen.cellAt(5, 0)!.content, 'b');
  });
}
