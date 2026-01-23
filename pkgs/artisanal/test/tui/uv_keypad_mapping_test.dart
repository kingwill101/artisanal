import 'package:artisanal/src/terminal/keys.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';
import 'package:artisanal/src/uv/uv.dart';

List<int> _bytes(String s) => s.codeUnits;

void main() {
  group('uv: keypad keys map into TUI Key', () {
    test('kitty kp left/right become KeyType.left/right', () {
      final p = UvTuiInputParser();

      final left = p.parseAll(_bytes('\x1b[57417u'));
      expect(left, hasLength(1));
      expect(left.single, isA<KeyMsg>());
      expect((left.single as KeyMsg).key.type, equals(KeyType.left));

      final right = p.parseAll(_bytes('\x1b[57418u'));
      expect(right, hasLength(1));
      expect((right.single as KeyMsg).key.type, equals(KeyType.right));
    });

    test('kitty kp enter becomes KeyType.enter', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll(_bytes('\x1b[57414u'));
      expect(msgs.single, isA<KeyMsg>());
      expect((msgs.single as KeyMsg).key.type, equals(KeyType.enter));
    });

    test('kitty kp plus becomes rune +', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll(_bytes('\x1b[57413u'));
      expect(msgs.single, isA<KeyMsg>());
      final k = (msgs.single as KeyMsg).key;
      expect(k.type, equals(KeyType.runes));
      expect(k.isChar('+'), isTrue);
    });
  });
}
