import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

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

    test('splitByLargestRemainder() sums exactly and is deterministic', () {
      final result = splitByLargestRemainder(10, [1, 1, 2]);
      expect(result, equals([3, 2, 5]));
      expect(result.fold(0, (sum, value) => sum + value), equals(10));
    });

    test('splitByLargestRemainder() prefers previous tie-breaker', () {
      const previous = [5, 2, 3];

      final tieBroken = splitByLargestRemainder(10, [
        2,
        1,
        1,
      ], previous: previous);
      expect(tieBroken, equals(previous));
    });

    test('splitByLargestRemainder() remains stable at fixed size', () {
      final first = splitByLargestRemainder(97, [1, 1, 1]);
      final second = splitByLargestRemainder(97, [1, 1, 1], previous: first);
      final third = splitByLargestRemainder(97, [1, 1, 1], previous: second);

      expect(first, equals([33, 32, 32]));
      expect(second, equals(first));
      expect(third, equals(first));
    });

    test('splitHorizontalByLargestRemainder() covers a fixed area', () {
      final area = rect(0, 0, 97, 4);
      var widths = splitByLargestRemainder(97, [1, 2, 3]);
      expect(widths, equals([16, 32, 49]));

      final sections = splitHorizontalByLargestRemainder(area, [1, 2, 3]);
      expect(
        sections.columns,
        equals([rect(0, 0, 16, 4), rect(16, 0, 32, 4), rect(48, 0, 49, 4)]),
      );

      widths = splitByLargestRemainder(97, [1, 2, 3], previous: widths);
      final stabilized = splitHorizontalByLargestRemainder(area, [
        1,
        2,
        3,
      ], previousAllocations: widths);
      expect(
        stabilized.columns.fold(0, (sum, r) => sum + r.width),
        equals(area.width),
      );
      expect(stabilized.columns.last.maxX, equals(area.maxX));
      expect(stabilized.columns.last.minX, equals(48));
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
