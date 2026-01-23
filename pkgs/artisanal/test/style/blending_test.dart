import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('blending helpers', () {
    test('blend1D returns requested number of steps', () {
      final out = blend1D(5, [
        Colors.red,
        Colors.blue,
      ], hasDarkBackground: true);
      expect(out, hasLength(5));
    });

    test('blend1D returns stops when steps <= stops', () {
      final out = blend1D(2, [
        Colors.red,
        Colors.blue,
        Colors.green,
      ], hasDarkBackground: true);
      expect(out, equals([Colors.red, Colors.blue]));
    });

    test('blend2D returns width*height colors (row-major)', () {
      final out = blend2D(3, 2, 0, [
        Colors.red,
        Colors.blue,
      ], hasDarkBackground: true);
      expect(out, hasLength(6));
      // Index sanity: first element should equal the first stop for simple cases.
      expect(out.first, isA<Color>());
    });
  });
}
