import 'package:artisanal/uv.dart';
import 'package:test/test.dart';

void main() {
  test('artisanal re-exports UV effects primitives', () {
    final filter = ColorMatrixFilter.tint(const UvRgb(255, 0, 0));
    final color = filter.matrix.transformColor(const UvRgb(0, 0, 255));

    expect(color, const UvRgb(128, 0, 128));
  });
}
