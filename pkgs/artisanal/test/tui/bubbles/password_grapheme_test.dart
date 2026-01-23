import 'package:artisanal/src/tui/bubbles/password.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('PasswordModel (graphemes)', () {
    test('backspace deletes a full grapheme cluster', () {
      final model = PasswordModel();

      // Insert "e\u0301" as a single grapheme cluster (combining mark).
      final (m1, _) = model.update(
        const KeyMsg(Key(KeyType.runes, runes: [0x65, 0x0301])),
      );
      expect(m1.value, equals('e\u0301'));
      expect(m1.length, 1);

      final (m2, _) = m1.update(const KeyMsg(Key(KeyType.backspace)));
      expect(m2.value, isEmpty);
      expect(m2.length, 0);
    });
  });
}
