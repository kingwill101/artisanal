import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity (scoped subset):
// - `third_party/ultraviolet/key_test.go` (TestReadInput)
void main() {
  group('UV TerminalReader parity (read input subset)', () {
    List<Event> scan(String s) {
      final p = UvEventStreamParser();
      return [...p.parseAll(s.codeUnits, expired: false), ...p.flush()];
    }

    test('non-serialized single esc', () {
      final evs = scan('\x1b');
      expect(evs, hasLength(1));
      expect(evs[0], isA<KeyPressEvent>());
      expect((evs[0] as KeyPressEvent).key().code, keyEscape);
    });

    test('ignored osc sequences (CAN/SUB/cancel)', () {
      final evs = scan(
        '\x1b]11;#123456\x18\x1b]11;#123456\x1a\x1b]11;#123456\x1b',
      );
      expect(evs, isEmpty);
    });

    test('serialized win32 esc (UTF-16 surrogate pairs)', () {
      final evs = scan(
        '\x1b[27;0;27;1;0;1_abc'
        '\x1b[0;0;55357;1;0;1_'
        '\x1b[0;0;56835;1;0;1_ ',
      );

      expect(evs, hasLength(6));

      expect(evs[0], isA<KeyPressEvent>());
      final esc = (evs[0] as KeyPressEvent).key();
      expect(esc.code, keyEscape);
      expect(esc.baseCode, keyEscape);

      expect((evs[1] as KeyPressEvent).key().text, 'a');
      expect((evs[2] as KeyPressEvent).key().text, 'b');
      expect((evs[3] as KeyPressEvent).key().text, 'c');

      expect(evs[4], isA<KeyPressEvent>());
      final emoji = (evs[4] as KeyPressEvent).key();
      expect(emoji.text, '😃');
      expect(emoji.code, '😃'.runes.first);

      expect(evs[5], isA<KeyPressEvent>());
      final sp = (evs[5] as KeyPressEvent).key();
      expect(sp.code, keySpace);
      expect(sp.text, ' ');
    });

    test('ignored apc sequences and broken introducers', () {
      final evs = scan(
        '\x9f\x9c\x1b_hello\x1b\x1b_hello\x18\x1b_abc\x1b\\\x1ba',
      );
      expect(evs, hasLength(3));

      expect(evs[0], isA<UnknownApcEvent>());
      expect((evs[0] as UnknownApcEvent).value, '\x9f\x9c');

      expect(evs[1], isA<UnknownApcEvent>());
      expect((evs[1] as UnknownApcEvent).value, '\x1b_abc\x1b\\');

      expect(evs[2], isA<KeyPressEvent>());
      final k = (evs[2] as KeyPressEvent).key();
      expect(k.code, 'a'.codeUnitAt(0));
      expect(k.mod, KeyMod.alt);
    });

    test('alt+] alt+\'', () {
      final evs = scan('\x1b]\x1b\'');
      expect(evs, hasLength(2));

      expect(evs[0], isA<KeyPressEvent>());
      final k0 = (evs[0] as KeyPressEvent).key();
      expect(k0.code, ']'.codeUnitAt(0));
      expect(k0.mod, KeyMod.alt);

      expect(evs[1], isA<KeyPressEvent>());
      final k1 = (evs[1] as KeyPressEvent).key();
      expect(k1.code, '\''.codeUnitAt(0));
      expect(k1.mod, KeyMod.alt);
    });

    test('alt+^ alt+&', () {
      final evs = scan('\x1b^\x1b&');
      expect(evs, hasLength(2));

      final k0 = (evs[0] as KeyPressEvent).key();
      expect(k0.code, '^'.codeUnitAt(0));
      expect(k0.mod, KeyMod.alt);

      final k1 = (evs[1] as KeyPressEvent).key();
      expect(k1.code, '&'.codeUnitAt(0));
      expect(k1.mod, KeyMod.alt);
    });

    test('a and space', () {
      final a = scan('a');
      expect(a, hasLength(1));
      expect((a[0] as KeyPressEvent).key().text, 'a');

      final sp = scan(' ');
      expect(sp, hasLength(1));
      expect((sp[0] as KeyPressEvent).key().code, keySpace);
      expect((sp[0] as KeyPressEvent).key().text, ' ');
    });

    test('a alt+a a', () {
      final evs = scan(
        'a\x1ba'
        'a',
      );
      expect(evs, hasLength(3));

      expect((evs[0] as KeyPressEvent).key().text, 'a');
      final kAlt = (evs[1] as KeyPressEvent).key();
      expect(kAlt.code, 'a'.codeUnitAt(0));
      expect(kAlt.mod, KeyMod.alt);
      expect((evs[2] as KeyPressEvent).key().text, 'a');
    });

    test('ctrl+a ctrl+b', () {
      final evs = scan(String.fromCharCodes([0x01, 0x02]));
      expect(evs, hasLength(2));

      final a = (evs[0] as KeyPressEvent).key();
      expect(a.code, 'a'.codeUnitAt(0));
      expect(a.mod, KeyMod.ctrl);

      final b = (evs[1] as KeyPressEvent).key();
      expect(b.code, 'b'.codeUnitAt(0));
      expect(b.mod, KeyMod.ctrl);
    });
  });
}
