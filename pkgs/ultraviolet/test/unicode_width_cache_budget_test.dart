import 'package:test/test.dart';
import 'package:ultraviolet/unicode.dart';

void main() {
  test('width remains correct for oversized uncached keys', () {
    final content = 'a' * 8192;

    expect(stringWidth(content), content.length);
    expect(stringWidth(content), content.length);
  });

  test('width cache eviction preserves measured output', () {
    for (var i = 0; i < 96; i++) {
      final content = ('界' * 1024) + i.toString();
      expect(
        stringWidth(content),
        (content.length - i.toString().length) * 2 + i.toString().length,
      );
    }
  });
}
