import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/layout_test.go`
// - `third_party/ultraviolet/layout.go`

void main() {
  group('layout parity', () {
    test('ratio', () {
      expect(ratio(1, 2).value, 50);
      expect(ratio(1, 4).value, 25);
      expect(ratio(3, 4).value, 75);
      expect(ratio(0, 1).value, 0);
      expect(ratio(1, 0).value, 0);
      expect(ratio(5, 5).value, 100);
      expect(ratio(2, 3).value, 66);
    });

    test('Percent.apply', () {
      expect(const Percent(50).apply(200), 100);
      expect(const Percent(25).apply(400), 100);
      expect(const Percent(75).apply(800), 600);
      expect(const Percent(0).apply(100), 0);
      expect(const Percent(100).apply(100), 100);
      expect(const Percent(-10).apply(100), 0);
      expect(const Percent(150).apply(100), 100);
    });

    test('Fixed.apply', () {
      expect(const Fixed(50).apply(200), 50);
      expect(const Fixed(150).apply(200), 150);
      expect(const Fixed(250).apply(200), 200);
      expect(const Fixed(0).apply(100), 0);
      expect(const Fixed(-10).apply(100), 0);
    });

    test('splitVertical', () {
      final area = const Rectangle(minX: 0, minY: 0, maxX: 100, maxY: 200);

      final a = splitVertical(area, const Percent(50));
      expect(a.top, const Rectangle(minX: 0, minY: 0, maxX: 100, maxY: 100));
      expect(
        a.bottom,
        const Rectangle(minX: 0, minY: 100, maxX: 100, maxY: 200),
      );

      final b = splitVertical(area, const Fixed(80));
      expect(b.top, const Rectangle(minX: 0, minY: 0, maxX: 100, maxY: 80));
      expect(
        b.bottom,
        const Rectangle(minX: 0, minY: 80, maxX: 100, maxY: 200),
      );

      final c = splitVertical(area, const Percent(150));
      expect(c.top, const Rectangle(minX: 0, minY: 0, maxX: 100, maxY: 200));
      expect(
        c.bottom,
        const Rectangle(minX: 0, minY: 200, maxX: 100, maxY: 200),
      );
    });

    test('splitHorizontal', () {
      final area = const Rectangle(minX: 0, minY: 0, maxX: 200, maxY: 100);

      final a = splitHorizontal(area, const Percent(50));
      expect(a.left, const Rectangle(minX: 0, minY: 0, maxX: 100, maxY: 100));
      expect(
        a.right,
        const Rectangle(minX: 100, minY: 0, maxX: 200, maxY: 100),
      );

      final b = splitHorizontal(area, const Fixed(80));
      expect(b.left, const Rectangle(minX: 0, minY: 0, maxX: 80, maxY: 100));
      expect(b.right, const Rectangle(minX: 80, minY: 0, maxX: 200, maxY: 100));

      final c = splitHorizontal(area, const Percent(150));
      expect(c.left, const Rectangle(minX: 0, minY: 0, maxX: 200, maxY: 100));
      expect(
        c.right,
        const Rectangle(minX: 200, minY: 0, maxX: 200, maxY: 100),
      );
    });
  });
}
