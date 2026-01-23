import 'package:test/test.dart';
import 'package:artisanal/src/uv/uv.dart';

void main() {
  group('CursorShape', () {
    test('encode matches upstream parity', () {
      final cases = [
        (CursorShape.block, true, 1),
        (CursorShape.block, false, 2),
        (CursorShape.underline, true, 3),
        (CursorShape.underline, false, 4),
        (CursorShape.bar, true, 5),
        (CursorShape.bar, false, 6),
      ];

      for (final c in cases) {
        final shape = c.$1;
        final blink = c.$2;
        final expected = c.$3;
        expect(
          shape.encode(blink: blink),
          equals(expected),
          reason: 'Shape $shape with blink=$blink should encode to $expected',
        );
      }
    });
  });
}
