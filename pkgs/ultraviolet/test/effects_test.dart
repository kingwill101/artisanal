import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  group('ColorMatrix', () {
    test('invert preserves rgb alpha and flips color channels', () {
      final color = ColorMatrix.invert().transformColor(
        const UvRgb(10, 20, 30, a: 40),
      );

      expect(color, const UvRgb(245, 235, 225, a: 40));
    });

    test('grayscale converts palette colors to truecolor', () {
      final color = ColorMatrix.grayscale().transformColor(const UvBasic16(1));

      expect(color, isA<UvRgb>());
      expect((color as UvRgb).r, equals(color.g));
      expect(color.g, equals(color.b));
    });

    test('multiply scales color channels by multiplier color', () {
      final color = ColorMatrix.multiply(
        const UvRgb(255, 128, 64),
      ).transformColor(const UvRgb(100, 200, 240));

      expect(color, const UvRgb(100, 100, 60));
    });
  });

  group('ColorMatrixFilter', () {
    test('transforms foreground and background through BufferRenderSink', () {
      final source = Buffer.create(1, 1);
      source.lines[0].replace(
        0,
        Cell(
          content: 'A',
          width: 1,
          style: const UvStyle(fg: UvRgb(10, 20, 30), bg: UvRgb(100, 110, 120)),
        ),
      );

      final sink = BufferRenderSink(width: 1, height: 1);
      final filtered = sink.render(source, [
        ColorMatrixFilter(ColorMatrix.invert()),
      ]);
      final cell = filtered.cellAt(0, 0)!;

      expect(cell.content, 'A');
      expect(
        cell.style,
        const UvStyle(fg: UvRgb(245, 235, 225), bg: UvRgb(155, 145, 135)),
      );
    });

    test('can skip background transforms', () {
      final source = Buffer.create(1, 1);
      source.lines[0].replace(
        0,
        Cell(
          content: 'B',
          width: 1,
          style: const UvStyle(fg: UvRgb(10, 20, 30), bg: UvRgb(100, 110, 120)),
        ),
      );

      final sink = BufferRenderSink(width: 1, height: 1);
      final filtered = sink.render(source, [
        ColorMatrixFilter(ColorMatrix.invert(), background: false),
      ]);
      final cell = filtered.cellAt(0, 0)!;

      expect(
        cell.style,
        const UvStyle(fg: UvRgb(245, 235, 225), bg: UvRgb(100, 110, 120)),
      );
    });
  });
}
