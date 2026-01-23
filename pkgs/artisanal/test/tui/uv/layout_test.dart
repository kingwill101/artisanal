import 'package:test/test.dart';
import 'package:artisanal/src/uv/uv.dart';

void main() {
  group('Layout Parity', () {
    test('Ratio', () {
      final cases = [
        (1, 2, 50),
        (1, 4, 25),
        (3, 4, 75),
        (0, 1, 0),
        (1, 0, 0), // Edge case: denominator is zero
        (5, 5, 100),
        (2, 3, 66), // Integer division
      ];

      for (final c in cases) {
        final result = ratio(c.$1, c.$2);
        expect(result.value, equals(c.$3), reason: 'Ratio(${c.$1}, ${c.$2})');
      }
    });

    test('Percent.apply', () {
      final cases = [
        (50, 200, 100),
        (25, 400, 100),
        (75, 800, 600),
        (0, 100, 0),
        (100, 100, 100),
        (-10, 100, 0), // Edge case: negative percent
        (150, 100, 100), // Edge case: percent greater than 100
      ];

      for (final c in cases) {
        final result = Percent(c.$1).apply(c.$2);
        expect(result, equals(c.$3), reason: 'Percent(${c.$1}).apply(${c.$2})');
      }
    });

    test('Fixed.apply', () {
      final cases = [
        (50, 200, 50),
        (150, 200, 150),
        (250, 200, 200), // Edge case: fixed size greater than available size
        (0, 100, 0),
        (-10, 100, 0), // Edge case: negative fixed size
      ];

      for (final c in cases) {
        final result = Fixed(c.$1).apply(c.$2);
        expect(result, equals(c.$3), reason: 'Fixed(${c.$1}).apply(${c.$2})');
      }
    });

    test('splitVertical', () {
      final area = rect(0, 0, 100, 200);

      // Percent(50)
      final res1 = splitVertical(area, const Percent(50));
      expect(res1.top, equals(rect(0, 0, 100, 100)));
      expect(res1.bottom, equals(rect(0, 100, 100, 100)));

      // Fixed(80)
      final res2 = splitVertical(area, const Fixed(80));
      expect(res2.top, equals(rect(0, 0, 100, 80)));
      expect(res2.bottom, equals(rect(0, 80, 100, 120)));

      // Percent(150)
      final res3 = splitVertical(area, const Percent(150));
      expect(res3.top, equals(rect(0, 0, 100, 200)));
      expect(res3.bottom, equals(rect(0, 200, 100, 0)));
    });

    test('splitHorizontal', () {
      final area = rect(0, 0, 200, 100);

      // Percent(50)
      final res1 = splitHorizontal(area, const Percent(50));
      expect(res1.left, equals(rect(0, 0, 100, 100)));
      expect(res1.right, equals(rect(100, 0, 100, 100)));

      // Fixed(80)
      final res2 = splitHorizontal(area, const Fixed(80));
      expect(res2.left, equals(rect(0, 0, 80, 100)));
      expect(res2.right, equals(rect(80, 0, 120, 100)));

      // Percent(150)
      final res3 = splitHorizontal(area, const Percent(150));
      expect(res3.left, equals(rect(0, 0, 200, 100)));
      expect(res3.right, equals(rect(200, 0, 0, 100)));
    });

    test('Rect positioning functions', () {
      final area = rect(10, 10, 100, 100);
      const w = 20;
      const h = 10;

      expect(centerRect(area, w, h), equals(rect(50, 55, 20, 10)));
      expect(topLeftRect(area, w, h), equals(rect(10, 10, 20, 10)));
      expect(topCenterRect(area, w, h), equals(rect(50, 10, 20, 10)));
      expect(topRightRect(area, w, h), equals(rect(90, 10, 20, 10)));
      expect(rightCenterRect(area, w, h), equals(rect(90, 55, 20, 10)));
      expect(leftCenterRect(area, w, h), equals(rect(10, 55, 20, 10)));
      expect(bottomLeftRect(area, w, h), equals(rect(10, 100, 20, 10)));
      expect(bottomCenterRect(area, w, h), equals(rect(50, 100, 20, 10)));
      expect(bottomRightRect(area, w, h), equals(rect(90, 100, 20, 10)));
    });
  });
}
