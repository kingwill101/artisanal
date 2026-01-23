import 'package:artisanal/src/tui/bubbles/confirm.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('DestructiveConfirmModel (graphemes)', () {
    test('backspace deletes a full grapheme cluster', () {
      final model = DestructiveConfirmModel(
        prompt: 'Type',
        confirmText: 'e\u0301',
      );

      final (m1, _) = model.update(
        const KeyMsg(Key(KeyType.runes, runes: [0x65, 0x0301])),
      );
      expect(m1.value, equals('e\u0301'));

      final (m2, _) = m1.update(const KeyMsg(Key(KeyType.backspace)));
      expect(m2.value, isEmpty);
    });

    test('view highlights by grapheme index', () {
      final model = DestructiveConfirmModel(
        prompt: 'Type',
        confirmText: 'e\u0301x',
      );

      final (m1, _) = model.update(
        const KeyMsg(Key(KeyType.runes, runes: [0x65, 0x0301])),
      );

      // Should render the composed grapheme as a single styled unit.
      // We don't snapshot ANSI here; just ensure the grapheme is present.
      expect(m1.view(), contains('e\u0301'));
    });
  });
}
