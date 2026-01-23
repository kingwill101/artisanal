import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

List<Event> _decodeAll(EventDecoder d, String s) {
  final out = <Event>[];
  var buf = s.codeUnits;
  while (buf.isNotEmpty) {
    final (n, ev) = d.decode(buf, allowIncompleteEsc: true);
    expect(n, greaterThan(0), reason: 'decoder made no progress');
    if (ev is MultiEvent) {
      out.addAll(ev.events);
    } else if (ev != null) {
      out.add(ev);
    }
    buf = buf.sublist(n);
  }
  return out;
}

void main() {
  group('UV decoder parity: Kitty keyboard / CSI u', () {
    test('invalid CSI u', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[u');
      expect(evs, hasLength(1));
      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[u');
    });

    test('basic CSI u keys', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[27;4u'
        '\x1b[127;4u'
        '\x1b[57358;4u'
        '\x1b[9;2u'
        '\x1b[195;u'
        '\x1b[20320;2u'
        '\x1b[195;2:3u'
        '\x1b[97;;229u',
      );

      expect(evs, hasLength(8));

      Key k(int i) => (evs[i] as KeyEvent).key();

      expect(evs[0], isA<KeyPressEvent>());
      expect(k(0).code, keyEscape);
      expect(k(0).mod, KeyMod.shift | KeyMod.alt);

      expect(evs[1], isA<KeyPressEvent>());
      expect(k(1).code, keyBackspace);
      expect(k(1).mod, KeyMod.shift | KeyMod.alt);

      expect(evs[2], isA<KeyPressEvent>());
      expect(k(2).code, keyCapsLock);
      expect(k(2).mod, KeyMod.shift | KeyMod.alt);

      expect(evs[3], isA<KeyPressEvent>());
      expect(k(3).code, keyTab);
      expect(k(3).mod, KeyMod.shift);

      expect(evs[4], isA<KeyPressEvent>());
      expect(k(4).code, 'Ã'.runes.first);
      expect(k(4).text, 'Ã');

      expect(evs[5], isA<KeyPressEvent>());
      expect(k(5).code, '你'.runes.first);
      expect(k(5).text, '你');
      expect(k(5).mod, KeyMod.shift);

      expect(evs[6], isA<KeyReleaseEvent>());
      expect(k(6).code, 'Ã'.runes.first);
      expect(k(6).text, 'Ã');
      expect(k(6).mod, KeyMod.shift);

      expect(evs[7], isA<KeyPressEvent>());
      expect(k(7).code, 'a'.runes.first);
      expect(k(7).text, 'å');
    });

    test('printable lock modifiers', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[97;65u' // caps lock on
        '\x1b[97;2u' // shift
        '\x1b[97;65u' // caps lock on
        '\x1b[97;66u' // caps lock + shift
        '\x1b[97;129u' // num lock on
        '\x1b[97;130u' // num lock + shift
        '\x1b[97;194u', // num lock + caps lock + shift
      );
      expect(evs, hasLength(7));

      Key k(int i) => (evs[i] as KeyPressEvent).key();
      expect(k(0).code, 'a'.runes.first);
      expect(k(0).text, 'A');
      expect(k(0).mod, KeyMod.capsLock);

      expect(k(1).text, 'A');
      expect(k(1).mod, KeyMod.shift);

      expect(k(2).text, 'A');
      expect(k(2).mod, KeyMod.capsLock);

      expect(k(3).text, 'A');
      expect(k(3).mod, KeyMod.capsLock | KeyMod.shift);

      expect(k(4).text, 'a');
      expect(k(4).mod, KeyMod.numLock);

      expect(k(5).text, 'A');
      expect(k(5).mod, KeyMod.numLock | KeyMod.shift);

      expect(k(6).text, 'A');
      expect(k(6).mod, KeyMod.numLock | KeyMod.capsLock | KeyMod.shift);
    });

    test('keypad CSI u gets printable text', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[57399u' // kp0
        '\x1b[57409u' // kpdecimal
        '\x1b[57411u' // kpmultiply
        '\x1b[57413u' // kpplus
        '\x1b[57415u' // kpequal
        '\x1b[57416u', // kpsep
      );
      expect(evs, hasLength(6));

      Key k(int i) => (evs[i] as KeyPressEvent).key();
      expect(k(0).code, keyKp0);
      expect(k(0).text, '0');
      expect(k(1).code, keyKpDecimal);
      expect(k(1).text, '.');
      expect(k(2).code, keyKpMultiply);
      expect(k(2).text, '*');
      expect(k(3).code, keyKpPlus);
      expect(k(3).text, '+');
      expect(k(4).code, keyKpEqual);
      expect(k(4).text, '=');
      expect(k(5).code, keyKpSep);
      expect(k(5).text, ',');
    });
  });

  group('UV decoder parity: Kitty extensions for non-CSI-u', () {
    test('fixterms arrows with repeat/release', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[1;4B' // down shift+alt
        '\x1b[1;4:2B' // down repeat shift+alt
        '\x1b[1;4:3B', // down release shift+alt
      );
      expect(evs, hasLength(3));

      expect(evs[0], isA<KeyPressEvent>());
      final k0 = (evs[0] as KeyPressEvent).key();
      expect(k0.code, keyDown);
      expect(k0.mod, KeyMod.shift | KeyMod.alt);
      expect(k0.isRepeat, false);

      expect(evs[1], isA<KeyPressEvent>());
      final k1 = (evs[1] as KeyPressEvent).key();
      expect(k1.code, keyDown);
      expect(k1.mod, KeyMod.shift | KeyMod.alt);
      expect(k1.isRepeat, true);

      expect(evs[2], isA<KeyReleaseEvent>());
      final k2 = (evs[2] as KeyReleaseEvent).key();
      expect(k2.code, keyDown);
      expect(k2.mod, KeyMod.shift | KeyMod.alt);
    });
  });
}
