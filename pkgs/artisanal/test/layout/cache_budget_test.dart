import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  test(
    'layout sizing remains correct for keys larger than the cache budget',
    () {
      final content = 'a' * (256 * 1024);

      expect(Layout.visibleLength(content), content.length);
      expect(Layout.getWidth(content), content.length);
      expect(Layout.getHeight(content), 1);
    },
  );

  test('layout cache eviction does not change sizing results', () {
    for (var i = 0; i < 96; i++) {
      final content = ('x' * (8 * 1024)) + i.toString();
      expect(Layout.getWidth(content), content.length);
      expect(Layout.getHeight(content), 1);
    }
  });
}
