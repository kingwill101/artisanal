import 'package:artisanal/src/tui/bubbles/components/tree.dart';
import 'package:test/test.dart';

void main() {
  group('tree: enumerator presets map to v2 funcs', () {
    String renderWith(TreeEnumerator e) {
      return (Tree()
            ..root('Root')
            ..child('A')
            ..child('B'))
          .enumerator(e)
          .render();
    }

    test('ascii', () {
      expect(renderWith(TreeEnumerator.ascii), equals('Root\n+-- A\n`-- B'));
    });

    test('bullet', () {
      expect(renderWith(TreeEnumerator.bullet), equals('Root\n•  A\n•  B'));
    });

    test('heavy', () {
      expect(renderWith(TreeEnumerator.heavy), equals('Root\n┣━━ A\n┗━━ B'));
    });

    test('doubleLine', () {
      expect(
        renderWith(TreeEnumerator.doubleLine),
        equals('Root\n╠══ A\n╚══ B'),
      );
    });
  });
}
