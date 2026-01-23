import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/border_test.go`
// - `third_party/ultraviolet/border.go`

void main() {
  group('UvBorder parity', () {
    test('constructors', () {
      final b = normalBorder();
      expect(b.top.content, '─');
      expect(b.bottom.content, '─');
      expect(b.left.content, '│');
      expect(b.right.content, '│');
      expect(b.topLeft.content, '┌');
      expect(b.topRight.content, '┐');
      expect(b.bottomLeft.content, '└');
      expect(b.bottomRight.content, '┘');

      final r = roundedBorder();
      expect(r.topLeft.content, '╭');
      expect(r.topRight.content, '╮');
      expect(r.bottomLeft.content, '╰');
      expect(r.bottomRight.content, '╯');

      final block = blockBorder();
      expect(block.top.content, '█');
      expect(block.bottomRight.content, '█');

      final outer = outerHalfBlockBorder();
      expect(outer.top.content, '▀');
      expect(outer.bottom.content, '▄');
      expect(outer.left.content, '▌');
      expect(outer.right.content, '▐');
      expect(outer.topLeft.content, '▛');

      final inner = innerHalfBlockBorder();
      expect(inner.top.content, '▄');
      expect(inner.bottom.content, '▀');
      expect(inner.left.content, '▐');
      expect(inner.right.content, '▌');

      final thick = thickBorder();
      expect(thick.top.content, '━');
      expect(thick.left.content, '┃');
      expect(thick.topLeft.content, '┏');

      final dbl = doubleBorder();
      expect(dbl.top.content, '═');
      expect(dbl.left.content, '║');
      expect(dbl.topLeft.content, '╔');

      final hidden = hiddenBorder();
      expect(hidden.top.content, ' ');
      expect(hidden.bottomRight.content, ' ');

      final md = markdownBorder();
      expect(md.left.content, '|');
      expect(md.right.content, '|');
      expect(md.top.content, '');
      expect(md.bottom.content, '');

      final ascii = asciiBorder();
      expect(ascii.top.content, '-');
      expect(ascii.topLeft.content, '+');
    });

    test('style/link do not mutate base', () {
      final base = normalBorder();
      final style = UvStyle(attrs: Attr.bold);
      final link = const Link(url: 'https://example.com', params: 'id=1');

      final b = base.style(style).link(link);
      expect(b.top.style, style);
      expect(b.bottomRight.style, style);
      expect(b.top.link, link);
      expect(b.bottomRight.link, link);

      expect(base.top.style.isZero, true);
      expect(base.top.link.isZero, true);
    });

    test('draw normal', () {
      final dst = ScreenBuffer(20, 10);
      final area = rect(1, 1, 6, 4);
      final b = normalBorder();
      b.draw(dst, area);

      expect(dst.cellAt(1, 1)!.content, '┌');
      expect(dst.cellAt(6, 1)!.content, '┐');
      expect(dst.cellAt(1, 4)!.content, '└');
      expect(dst.cellAt(6, 4)!.content, '┘');

      for (var x = 2; x <= 5; x++) {
        expect(dst.cellAt(x, 1)!.content, '─');
        expect(dst.cellAt(x, 4)!.content, '─');
      }
      for (var y = 2; y <= 3; y++) {
        expect(dst.cellAt(1, y)!.content, '│');
        expect(dst.cellAt(6, y)!.content, '│');
      }

      for (var y = 2; y <= 3; y++) {
        for (var x = 2; x <= 5; x++) {
          expect(dst.cellAt(x, y)!.content, ' ');
        }
      }
    });

    test('draw hidden style/link', () {
      final dst = ScreenBuffer(10, 6);
      final area = rect(2, 2, 5, 3);
      final style = UvStyle(attrs: Attr.bold);
      final link = const Link(url: 'https://example.com');

      final b = hiddenBorder().style(style).link(link);
      b.draw(dst, area);

      final checkPos = <(int, int)>[
        (2, 2),
        (6, 2),
        (2, 4),
        (6, 4),
        for (var x = 3; x <= 5; x++) (x, 2),
        for (var x = 3; x <= 5; x++) (x, 4),
        (2, 3),
        (6, 3),
      ];

      for (final (x, y) in checkPos) {
        final c = dst.cellAt(x, y)!;
        expect(c.content, ' ');
        expect(c.style, style);
        expect(c.link, link);
      }

      final interior = dst.cellAt(4, 3)!;
      expect(interior.content, ' ');
      expect(interior.style.isZero, true);
      expect(interior.link.isZero, true);
    });

    test('draw small areas', () {
      final dst = ScreenBuffer(3, 3);
      final b = normalBorder();

      final area1 = rect(0, 0, 1, 1);
      b.draw(dst, area1);
      expect(dst.cellAt(0, 0)!.content, '┌');

      final area2 = rect(0, 1, 1, 2);
      b.draw(dst, area2);
      expect(dst.cellAt(0, 1)!.content, '┌');
      expect(dst.cellAt(0, 2)!.content, '└');
    });
  });
}
