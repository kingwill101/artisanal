import 'package:artisanal/src/tui/bubbles/anticipate.dart';
import 'package:artisanal/tui.dart' show Key, KeyMsg, KeyType;
import 'package:test/test.dart';

void main() {
  group('AnticipateModel', () {
    test('backspace deletes a full grapheme cluster', () {
      final model = AnticipateModel().focus();

      final (m1, _) = model.update(
        KeyMsg(Key(KeyType.runes, runes: 'e\u0301'.runes.toList())),
      );
      final (m2, _) = m1.update(KeyMsg(const Key(KeyType.backspace)));

      expect((m2).value, isEmpty);
    });

    test('minCharsToSearch counts graphemes (combining marks)', () {
      final model = AnticipateModel(
        suggestions: const ['e\u0301clair', 'echo'],
        config: const AnticipateConfig(minCharsToSearch: 1),
      ).focus();

      final (m1, _) = model.update(
        KeyMsg(Key(KeyType.runes, runes: 'e\u0301'.runes.toList())),
      );

      final view = (m1).view();
      expect(view, contains('e\u0301clair'));
    });
  });
}
