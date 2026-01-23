import 'package:artisanal/src/terminal/keys.dart';
import 'package:test/test.dart';

void main() {
  group('Key accept helpers', () {
    test('isChar defaults to requiring no modifiers', () {
      expect(Key.char('j').isChar('j'), isTrue);
      expect(
        const Key(KeyType.runes, runes: [0x6a], ctrl: true).isChar('j'),
        isFalse,
      );
    });

    test('isEnterLike matches KeyType.enter', () {
      expect(const Key(KeyType.enter).isEnterLike, isTrue);
    });

    test('isEnterLike matches Ctrl+J and Ctrl+M', () {
      expect(Keys.ctrlJ.isEnterLike, isTrue);
      expect(Keys.ctrlM.isEnterLike, isTrue);
    });

    test('isEnterLike matches raw CR/LF runes', () {
      expect(Key.char('\n').isEnterLike, isTrue);
      expect(Key.char('\r').isEnterLike, isTrue);
    });

    test('isSpaceLike matches KeyType.space and plain space rune', () {
      expect(const Key(KeyType.space).isSpaceLike, isTrue);
      expect(Key.char(' ').isSpaceLike, isTrue);
    });

    test('isAccept matches Enter or Space', () {
      expect(const Key(KeyType.enter).isAccept, isTrue);
      expect(Keys.ctrlJ.isAccept, isTrue);
      expect(Keys.ctrlM.isAccept, isTrue);
      expect(const Key(KeyType.space).isAccept, isTrue);
      expect(Key.char(' ').isAccept, isTrue);
    });

    test('isSpaceLike does not match modified space rune', () {
      expect(
        const Key(KeyType.runes, runes: [0x20], ctrl: true).isSpaceLike,
        isFalse,
      );
      expect(
        const Key(KeyType.runes, runes: [0x20], alt: true).isSpaceLike,
        isFalse,
      );
      expect(
        const Key(KeyType.runes, runes: [0x20], shift: true).isSpaceLike,
        isFalse,
      );
    });
  });
}
