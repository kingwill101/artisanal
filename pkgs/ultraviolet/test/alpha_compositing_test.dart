import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

void main() {
  group('Alpha compositing', () {
    test('full opacity passthrough returns the source color', () {
      expect(
        sourceOver(const UvRgb(255, 0, 0), const UvRgb(0, 0, 255)),
        const UvRgb(255, 0, 0),
      );
    });

    test('full transparency passthrough returns the destination color', () {
      expect(
        sourceOver(const UvRgb(255, 0, 0, a: 0), const UvRgb(0, 0, 255)),
        const UvRgb(0, 0, 255),
      );
    });

    test('semi-transparent source blends over destination', () {
      expect(
        sourceOver(const UvRgb(255, 0, 0, a: 128), const UvRgb(0, 0, 255)),
        const UvRgb(128, 0, 127, a: 255),
      );
    });

    test('buffer setCell composites translucent colors over existing cell', () {
      final buffer = Buffer.create(2, 1);
      buffer.setCell(
        0,
        0,
        Cell(
          content: 'A',
          width: 1,
          style: const UvStyle(bg: UvRgb(0, 0, 255)),
        ),
      );

      buffer.setCell(
        0,
        0,
        Cell(
          content: 'B',
          width: 1,
          style: const UvStyle(bg: UvRgb(255, 0, 0, a: 128)),
        ),
      );

      final cell = buffer.cellAt(0, 0)!;
      expect(cell.content, 'B');
      expect(cell.style.bg, const UvRgb(128, 0, 127, a: 255));
    });

    test(
      'buffer clear resets content and style instead of preserving background',
      () {
        final buffer = Buffer.create(1, 1);
        buffer.setCell(
          0,
          0,
          Cell(
            content: 'A',
            width: 1,
            style: const UvStyle(bg: UvRgb(8, 14, 24)),
          ),
        );

        buffer.clear();

        final cell = buffer.cellAt(0, 0)!;
        expect(cell.content, ' ');
        expect(cell.style, const UvStyle());
      },
    );

    test('non-rgb destination falls back to source replacement', () {
      expect(
        sourceOver(const UvRgb(255, 0, 0, a: 128), const UvIndexed256(42)),
        const UvRgb(255, 0, 0),
      );
    });
  });
}
