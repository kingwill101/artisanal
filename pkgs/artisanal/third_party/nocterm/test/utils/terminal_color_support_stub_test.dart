import 'package:nocterm/src/utils/terminal_color_support_stub.dart';
import 'package:test/test.dart';

void main() {
  group('supportsTruecolor (stub)', () {
    tearDown(() => setSupportsTruecolorForTesting(null));

    test('defaults to true when not overridden', () {
      expect(supportsTruecolor(), isTrue);
    });

    test('override can force false', () {
      setSupportsTruecolorForTesting(false);
      expect(supportsTruecolor(), isFalse);
    });
  });
}
