import 'package:nocterm/src/utils/terminal_color_support.dart';
import 'package:test/test.dart';

void main() {
  group('supportsTruecolor (io)', () {
    tearDown(() => setSupportsTruecolorForTesting(null));

    test('override forces truecolor on', () {
      setSupportsTruecolorForTesting(true);
      expect(supportsTruecolor(), isTrue);
    });

    test('override forces truecolor off', () {
      setSupportsTruecolorForTesting(false);
      expect(supportsTruecolor(), isFalse);
    });

    test('cached value is used when no override', () {
      setSupportsTruecolorForTesting(null);
      final first = supportsTruecolor();
      final second = supportsTruecolor();
      expect(second, equals(first));
    });
  });
}
