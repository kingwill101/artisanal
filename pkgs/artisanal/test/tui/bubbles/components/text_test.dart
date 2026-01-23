import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/tui/bubbles/components/text.dart';
import 'package:artisanal/src/tui/bubbles/components/base.dart';
import 'package:test/test.dart';

void main() {
  group('Rule', () {
    test('centers label using visible width (combining marks)', () {
      final rule = Rule(
        text: 'e\u0301', // combining-mark form of "é"
        renderConfig: const RenderConfig(terminalWidth: 10),
      );

      final out = rule.render();
      expect(Style.visibleLength(out), equals(10));
      expect(out, contains(' e\u0301 '));
    });
  });
}
