import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/key_test.go` (TestParseSequence additional cases)

List<Event> _decodeAll(EventDecoder d, List<int> bytes) {
  final out = <Event>[];
  var buf = List<int>.from(bytes);
  while (buf.isNotEmpty) {
    final (n, ev) = d.decode(buf, allowIncompleteEsc: false);
    expect(n, greaterThan(0), reason: 'decoder made no progress');
    if (ev case MultiEvent(:final events)) {
      out.addAll(events);
    } else if (ev != null) {
      out.add(ev);
    }
    buf = buf.sublist(n);
  }
  return out;
}

void main() {
  group('UV parse sequence parity (more)', () {
    test('Invalid XTerm modifyOtherKeys key sequence', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[27;3~'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[27;3~');
    });

    test('XTerm modifyOtherKeys key sequences', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        ('\x1b[27;3;20320~'
                '\x1b[27;3;65~'
                '\x1b[27;3;8~'
                '\x1b[27;3;27~'
                '\x1b[27;3;127~')
            .codeUnits,
      );
      expect(evs, hasLength(5));

      void expectKey(Event ev, int code, int mod) {
        expect(ev, isA<KeyPressEvent>());
        final k = (ev as KeyPressEvent).key();
        expect(k.code, code);
        expect(k.mod, mod);
      }

      expectKey(evs[0], '你'.runes.single, KeyMod.alt);
      expectKey(evs[1], 'A'.codeUnitAt(0), KeyMod.alt);
      expectKey(evs[2], keyBackspace, KeyMod.alt);
      expectKey(evs[3], keyEscape, KeyMod.alt);
      expectKey(evs[4], keyBackspace, KeyMod.alt);
    });

    test('ModifyOtherKeys response (CSI > 4 ; <mode> m)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[>4;1m\x1b[>4m\x1b[>3m'.codeUnits);
      expect(evs, hasLength(3));

      expect(evs[0], isA<ModifyOtherKeysEvent>());
      expect((evs[0] as ModifyOtherKeysEvent).mode, 1);

      expect(evs[1], isA<UnknownCsiEvent>());
      expect((evs[1] as UnknownCsiEvent).value, '\x1b[>4m');

      expect(evs[2], isA<UnknownCsiEvent>());
      expect((evs[2] as UnknownCsiEvent).value, '\x1b[>3m');
    });

    test('Kitty Keyboard enhancements response (CSI ? <flags> u)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[?16u\x1b[?u'.codeUnits);
      expect(evs, hasLength(2));

      expect(evs[0], isA<KeyboardEnhancementsEvent>());
      expect((evs[0] as KeyboardEnhancementsEvent).flags, 16);

      expect(evs[1], isA<KeyboardEnhancementsEvent>());
      expect((evs[1] as KeyboardEnhancementsEvent).flags, 0);
    });

    test('F3+modifier ambiguity vs cursor position report', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[1;5R\x1b[1;5;7R'.codeUnits);
      expect(evs, hasLength(3));

      expect(evs[0], isA<KeyPressEvent>());
      final k = (evs[0] as KeyPressEvent).key();
      expect(k.code, keyF3);
      expect(k.mod, KeyMod.ctrl);

      expect(evs[1], isA<CursorPositionEvent>());
      final pos = evs[1] as CursorPositionEvent;
      expect(pos.y, 0);
      expect(pos.x, 4);

      expect(evs[2], isA<UnknownCsiEvent>());
      expect((evs[2] as UnknownCsiEvent).value, '\x1b[1;5;7R');
    });

    test('Cursor position report variants', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[?12;34R\x1b[?14R'.codeUnits);
      expect(evs, hasLength(2));

      expect(evs[0], isA<CursorPositionEvent>());
      final pos = evs[0] as CursorPositionEvent;
      expect(pos.y, 11);
      expect(pos.x, 33);

      expect(evs[1], isA<UnknownCsiEvent>());
      expect((evs[1] as UnknownCsiEvent).value, '\x1b[?14R');
    });

    test('Win32 input mode key sequences', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[65;0;97;1;0;1_\x1b[0;0;0_'.codeUnits);
      expect(evs, hasLength(2));

      expect(evs[0], isA<KeyPressEvent>());
      final k = (evs[0] as KeyPressEvent).key();
      expect(k.code, 'a'.codeUnitAt(0));
      expect(k.baseCode, 'a'.codeUnitAt(0));
      expect(k.text, 'a');

      expect(evs[1], isA<UnknownCsiEvent>());
      expect((evs[1] as UnknownCsiEvent).value, '\x1b[0;0;0_');
    });

    test('Incomplete CSI returns UnknownEvent (no final byte)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[?2004;1\$'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<UnknownEvent>());
      expect((evs[0] as UnknownEvent).value, '\x1b[?2004;1\$');
    });

    test('Invalid CSI sequence still returns a parsed event', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[?2004;1\$y'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<ModeReportEvent>());
      final mr = evs[0] as ModeReportEvent;
      expect(mr.mode, 2004);
      expect(mr.value, ModeSetting.set);
    });

    test('Light/dark color scheme reports (CSI ? 997 ; <n> n)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[?997;1n\x1b[?997;2n'.codeUnits);
      expect(evs, hasLength(2));
      expect(evs[0], isA<DarkColorSchemeEvent>());
      expect(evs[1], isA<LightColorSchemeEvent>());
    });

    test('OSC 11 background color report (ST)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b]11;#123456\x1b\\'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<BackgroundColorEvent>());
      expect(
        (evs[0] as BackgroundColorEvent).color,
        const UvRgb(0x12, 0x34, 0x56),
      );
    });

    test('OSC 11 response (BEL)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b]11;rgb:ffff/0000/ffff\x07'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<BackgroundColorEvent>());
      final bg = evs[0] as BackgroundColorEvent;
      expect(bg.color, const UvRgb(255, 0, 255));
    });

    test('Tertiary Device Attributes (DA3)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1bP!|4368726d\x1b\\'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<TertiaryDeviceAttributesEvent>());
      expect((evs[0] as TertiaryDeviceAttributesEvent).value, 'Chrm');
    });

    test('XTGETTCAP response', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1bP1+r524742\x1b\\'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<CapabilityEvent>());
      expect((evs[0] as CapabilityEvent).content, 'RGB');
    });

    test('Unknown sequences', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[z\x1bOz\x1bO2 \x1bP?1;2:3+zABC\x1b\\'.codeUnits,
      );
      expect(evs, hasLength(5));
      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[z');
      expect(evs[1], isA<UnknownSs3Event>());
      expect((evs[1] as UnknownSs3Event).value, '\x1bOz');
      expect(evs[2], isA<UnknownEvent>());
      expect((evs[2] as UnknownEvent).value, '\x1bO2');
      expect(evs[3], isA<KeyPressEvent>());
      expect((evs[3] as KeyPressEvent).key().code, keySpace);
      expect(evs[4], isA<UnknownDcsEvent>());
      expect((evs[4] as UnknownDcsEvent).value, '\x1bP?1;2:3+zABC\x1b\\');
    });

    test('OSC 52 read clipboard', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b]52\x1b\\\x1b]52;c;!\x1b\\\x1b]52;c;aGk=\x1b\\'.codeUnits,
      );
      expect(evs, hasLength(3));
      expect(evs[0], isA<ClipboardEvent>());
      expect((evs[0] as ClipboardEvent).content, '');
      expect(evs[1], isA<ClipboardEvent>());
      expect((evs[1] as ClipboardEvent).content, '!');
      expect(evs[2], isA<ClipboardEvent>());
      expect((evs[2] as ClipboardEvent).content, 'hi');
      expect((evs[2] as ClipboardEvent).selection, ClipboardSelection.system);
    });

    test('Empty @ ^ ~', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[@\x1b[^\x1b[~'.codeUnits);
      expect(evs, hasLength(3));
      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[@');
      expect(evs[1], isA<UnknownCsiEvent>());
      expect((evs[1] as UnknownCsiEvent).value, '\x1b[^');
      expect(evs[2], isA<UnknownCsiEvent>());
      expect((evs[2] as UnknownCsiEvent).value, '\x1b[~');
    });

    test('Report mode responses', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[2;1\$y\x1b[\$y\x1b[2\$y\x1b[2;\$y'.codeUnits,
      );
      expect(evs, hasLength(4));
      expect(evs[0], isA<ModeReportEvent>());
      expect((evs[0] as ModeReportEvent).mode, 2);
      expect((evs[0] as ModeReportEvent).value, ModeSetting.set);
      expect(evs[1], isA<UnknownCsiEvent>());
      expect(evs[2], isA<UnknownCsiEvent>());
      expect(evs[3], isA<ModeReportEvent>());
      expect((evs[3] as ModeReportEvent).value, ModeSetting.notRecognized);
    });

    test('Short X10 mouse input', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[M !'.codeUnits);
      expect(evs, hasLength(3));
      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[M');
      expect(evs[1], isA<KeyPressEvent>());
      expect((evs[1] as KeyPressEvent).key().code, keySpace);
      expect(evs[2], isA<KeyPressEvent>());
      expect((evs[2] as KeyPressEvent).key().code, '!'.codeUnitAt(0));
    });

    test('Invalid report mode responses', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[?\$y\x1b[?1049\$y\x1b[?1049;\$y'.codeUnits,
      );
      expect(evs, hasLength(3));
      expect(evs[0], isA<UnknownCsiEvent>());
      expect(evs[1], isA<UnknownCsiEvent>());
      expect(evs[2], isA<ModeReportEvent>());
      expect((evs[2] as ModeReportEvent).mode, 1049);
      expect((evs[2] as ModeReportEvent).value, ModeSetting.notRecognized);
    });

    test('Unknown CSI sequence', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[10;2;3c'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[10;2;3c');
    });

    test('Secondary Device Attributes (DA2)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[>1;2;3c'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<SecondaryDeviceAttributesEvent>());
      expect((evs[0] as SecondaryDeviceAttributesEvent).attrs, [1, 2, 3]);
    });

    test('Primary Device Attributes (DA1)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[?1;2;3c'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<PrimaryDeviceAttributesEvent>());
      expect((evs[0] as PrimaryDeviceAttributesEvent).attrs, [1, 2, 3]);
    });

    test('esc followed by non-key event sequence', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b\x1b[?2004;1\$y'.codeUnits);
      expect(evs, hasLength(2));
      expect(evs[0], isA<KeyPressEvent>());
      expect((evs[0] as KeyPressEvent).key().code, keyEscape);
      expect(evs[1], isA<ModeReportEvent>());
      expect((evs[1] as ModeReportEvent).mode, 2004);
      expect((evs[1] as ModeReportEvent).value, ModeSetting.set);
    });

    test('8-bit sequences', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, [
        0x9b, 0x41, // CSI A
        0x8f, 0x41, // SS3 A
        0x90,
        0x3e,
        0x7c,
        ...'Ultraviolet'.codeUnits,
        0x1b,
        0x5c, // DCS >|Ultraviolet ST
        0x9d,
        0x31,
        0x31,
        0x3b,
        ...'#123456'.codeUnits,
        0x9c, // OSC 11 ; #123456 ST
        0x98, ...'hi'.codeUnits, 0x9c, // SOS hi ST
        0x9f, ...'hello'.codeUnits, 0x9c, // APC hello ST
        0x9e, ...'bye'.codeUnits, 0x9c, // PM bye ST
      ]);
      expect(evs, hasLength(7));
      expect(evs[0], isA<KeyPressEvent>());
      expect((evs[0] as KeyPressEvent).key().code, keyUp);
      expect(evs[1], isA<KeyPressEvent>());
      expect((evs[1] as KeyPressEvent).key().code, keyUp);
      expect(evs[2], isA<TerminalVersionEvent>());
      expect((evs[2] as TerminalVersionEvent).name, 'Ultraviolet');
      expect(evs[3], isA<BackgroundColorEvent>());
      expect(evs[4], isA<UnknownSosEvent>());
      expect((evs[4] as UnknownSosEvent).value, '\x98hi\x9c');
      expect(evs[5], isA<UnknownApcEvent>());
      expect((evs[5] as UnknownApcEvent).value, '\x9fhello\x9c');
      expect(evs[6], isA<UnknownPmEvent>());
      expect((evs[6] as UnknownPmEvent).value, '\x9ebye\x9c');
    });
  });
}
