import 'dart:convert' show utf8;

import 'package:ultraviolet/src/uv/uv.dart';

import 'package:ultraviolet/src/unicode/grapheme.dart' as uni;
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/decoder_test.go`
// - `third_party/ultraviolet/decoder.go`

UvRgb _rgbFromHex(String hex) {
  final s = hex.startsWith('#') ? hex.substring(1) : hex;
  final r = int.parse(s.substring(0, 2), radix: 16);
  final g = int.parse(s.substring(2, 4), radix: 16);
  final b = int.parse(s.substring(4, 6), radix: 16);
  return UvRgb(r, g, b);
}

void _expectKeyPress(
  Event? ev, {
  required int code,
  String text = '',
  int mod = 0,
  int shiftedCode = 0,
}) {
  expect(ev, isA<KeyPressEvent>());
  final k = (ev as KeyPressEvent).key();
  expect(k.code, code);
  expect(k.text, text);
  expect(k.mod, mod);
  expect(k.shiftedCode, shiftedCode);
}

void main() {
  group('UV decoder parity', () {
    test('LegacyKeyEncoding flag methods', () {
      final all = LegacyKeyEncoding(0xffffffff);
      expect(const LegacyKeyEncoding().ctrlAt(true).has(1 << 0), true);
      expect(all.ctrlAt(false).has(1 << 0), false);

      expect(const LegacyKeyEncoding().ctrlI(true).has(1 << 1), true);
      expect(all.ctrlI(false).has(1 << 1), false);

      expect(const LegacyKeyEncoding().ctrlM(true).has(1 << 2), true);
      expect(all.ctrlM(false).has(1 << 2), false);

      expect(const LegacyKeyEncoding().ctrlOpenBracket(true).has(1 << 3), true);
      expect(all.ctrlOpenBracket(false).has(1 << 3), false);

      expect(const LegacyKeyEncoding().backspace(true).has(1 << 4), true);
      expect(all.backspace(false).has(1 << 4), false);

      expect(const LegacyKeyEncoding().find(true).has(1 << 5), true);
      expect(all.find(false).has(1 << 5), false);

      expect(const LegacyKeyEncoding().select(true).has(1 << 6), true);
      expect(all.select(false).has(1 << 6), false);

      expect(const LegacyKeyEncoding().fKeys(true).has(1 << 7), true);
      expect(all.fKeys(false).has(1 << 7), false);

      expect(const LegacyKeyEncoding().ctrlJ(true).has(1 << 8), true);
      expect(all.ctrlJ(false).has(1 << 8), false);
    });

    test('LF (0x0A) decodes to Enter by default', () {
      final dec = EventDecoder();
      final ev = dec.parseControl(0x0a);
      _expectKeyPress(ev, code: keyEnter);
    });

    test('LF (0x0A) decodes to Ctrl+J when legacy flag is set', () {
      final dec = EventDecoder(legacy: const LegacyKeyEncoding().ctrlJ(true));
      final ev = dec.parseControl(0x0a);
      _expectKeyPress(ev, code: 0x6a /* j */, mod: KeyMod.ctrl);
    });

    test('CR (0x0D) decodes to Enter by default', () {
      final dec = EventDecoder();
      final ev = dec.parseControl(0x0d);
      _expectKeyPress(ev, code: keyEnter);
    });

    test('Device attributes parsing', () {
      final pda = parsePrimaryDevAttrs([62, 1, 2, 6, 9]);
      expect(pda, isA<PrimaryDeviceAttributesEvent>());
      expect((pda as PrimaryDeviceAttributesEvent).attrs, [62, 1, 2, 6, 9]);

      final sda = parseSecondaryDevAttrs([1, 2, 3]);
      expect(sda, isA<SecondaryDeviceAttributesEvent>());
      expect((sda as SecondaryDeviceAttributesEvent).attrs, [1, 2, 3]);

      final tda = parseTertiaryDevAttrs('4368726d'.codeUnits);
      expect(tda, isA<TertiaryDeviceAttributesEvent>());
      expect((tda as TertiaryDeviceAttributesEvent).value, 'Chrm');
    });

    test('Helper functions', () {
      expect(shift(0), 0);
      expect(shift(1), 1);
      expect(shift(0x100), 1);
      expect(shift(0x1000), 0x10);

      expect(colorToHex(const UvRgb(255, 128, 64)), '#ff8040');
      expect(colorToHex(const UvRgb(0, 0, 0)), '#000000');
      expect(colorToHex(const UvRgb(255, 255, 255)), '#ffffff');
      expect(colorToHex(null), '');

      expect(getMaxMin(0.5, 0.3, 0.8), (0.8, 0.3));
      expect(getMaxMin(1.0, 1.0, 1.0), (1.0, 1.0));
      expect(getMaxMin(0.0, 0.0, 0.0), (0.0, 0.0));
      expect(getMaxMin(0.2, 0.5, 0.3), (0.5, 0.2));

      const eps = 0.01;
      final (h1, s1, l1) = rgbToHsl(255, 0, 0);
      expect((h1 - 0).abs() <= eps, true);
      expect((s1 - 1.0).abs() <= eps, true);
      expect((l1 - 0.5).abs() <= eps, true);

      final (h2, s2, l2) = rgbToHsl(0, 255, 0);
      expect((h2 - 120).abs() <= eps, true);
      expect((s2 - 1.0).abs() <= eps, true);
      expect((l2 - 0.5).abs() <= eps, true);

      final (h3, s3, l3) = rgbToHsl(0, 0, 255);
      expect((h3 - 240).abs() <= eps, true);
      expect((s3 - 1.0).abs() <= eps, true);
      expect((l3 - 0.5).abs() <= eps, true);

      final (h4, s4, l4) = rgbToHsl(128, 128, 128);
      expect((h4 - 0).abs() <= eps, true);
      expect((s4 - 0.0).abs() <= eps, true);
      expect((l4 - 0.5).abs() <= eps, true);

      expect(isDarkColor(_rgbFromHex('#ffffff')), false);
      expect(isDarkColor(_rgbFromHex('#000000')), true);
      expect(isDarkColor(_rgbFromHex('#808080')), false);
      expect(isDarkColor(_rgbFromHex('#404040')), true);
      expect(isDarkColor(_rgbFromHex('#c0c0c0')), false);
      expect(isDarkColor(_rgbFromHex('#ff0000')), false);
      expect(isDarkColor(_rgbFromHex('#800000')), true);
    });

    test('parseTermcap', () {
      expect(parseTermcap('524742'.codeUnits).content, 'RGB');
      expect(parseTermcap('436F=323536'.codeUnits).content, 'Co=256');
      expect(parseTermcap(''.codeUnits).content, '');
      expect(parseTermcap('GGGG'.codeUnits).content, '');
      expect(parseTermcap('52474'.codeUnits).content, '');
    });

    test('parseUtf8', () {
      final p = EventDecoder();

      expect(p.parseUtf8(const []), (0, null));

      final (n1, ev1) = p.parseUtf8(const [0x01]);
      expect(n1, 1);
      _expectKeyPress(ev1, code: 0x61, mod: KeyMod.ctrl);

      final (n2, ev2) = p.parseUtf8(const [0x61]);
      expect(n2, 1);
      _expectKeyPress(ev2, code: 0x61, text: 'a');

      final (n3, ev3) = p.parseUtf8(const [0x41]);
      expect(n3, 1);
      _expectKeyPress(
        ev3,
        code: 0x61,
        text: 'A',
        mod: KeyMod.shift,
        shiftedCode: 0x41,
      );

      final (n4, ev4) = p.parseUtf8(const [0x7f]);
      expect(n4, 1);
      _expectKeyPress(
        ev4,
        code: keyBackspace,
      ); // DEL => backspace key (default)

      final (n5, ev5) = p.parseUtf8(utf8.encode('€'));
      expect(n5, 3);
      _expectKeyPress(ev5, code: uni.firstCodePoint('€'), text: '€');

      final cluster = '👨‍👩‍👧‍👦';
      final clusterBytes = utf8.encode(cluster);
      final (n5b, ev5b) = p.parseUtf8(clusterBytes);
      expect(n5b, clusterBytes.length);
      expect(ev5b, isA<KeyPressEvent>());
      final k5b = (ev5b as KeyPressEvent).key();
      expect(k5b.code, keyExtended);
      expect(k5b.text, cluster);

      final (n6, ev6) = p.parseUtf8(const [0xff]);
      expect(n6, 1);
      expect(ev6, isA<UnknownEvent>());
      expect((ev6 as UnknownEvent).value, '\u00ff');
    });

    test('parseControl', () {
      final p = EventDecoder();

      p.legacy = const LegacyKeyEncoding(1 << 0);
      _expectKeyPress(p.parseControl(0x00), code: 0x40, mod: KeyMod.ctrl);

      p.legacy = const LegacyKeyEncoding(0);
      _expectKeyPress(p.parseControl(0x00), code: keySpace, mod: KeyMod.ctrl);

      _expectKeyPress(p.parseControl(0x08), code: 0x68, mod: KeyMod.ctrl);

      p.legacy = const LegacyKeyEncoding(1 << 1);
      _expectKeyPress(p.parseControl(0x09), code: 0x69, mod: KeyMod.ctrl);

      p.legacy = const LegacyKeyEncoding(0);
      _expectKeyPress(p.parseControl(0x09), code: keyTab);

      p.legacy = const LegacyKeyEncoding(1 << 2);
      _expectKeyPress(p.parseControl(0x0d), code: 0x6d, mod: KeyMod.ctrl);

      p.legacy = const LegacyKeyEncoding(0);
      _expectKeyPress(p.parseControl(0x0d), code: keyEnter);

      p.legacy = const LegacyKeyEncoding(1 << 3);
      _expectKeyPress(p.parseControl(0x1b), code: 0x5b, mod: KeyMod.ctrl);

      p.legacy = const LegacyKeyEncoding(0);
      _expectKeyPress(p.parseControl(0x1b), code: keyEscape);

      p.legacy = const LegacyKeyEncoding(1 << 4);
      _expectKeyPress(p.parseControl(0x7f), code: keyDelete);

      p.legacy = const LegacyKeyEncoding(0);
      _expectKeyPress(p.parseControl(0x7f), code: keyBackspace);

      _expectKeyPress(p.parseControl(0x20), code: keySpace, text: ' ');

      _expectKeyPress(p.parseControl(0x01), code: 0x61, mod: KeyMod.ctrl);
      _expectKeyPress(p.parseControl(0x1a), code: 0x7a, mod: KeyMod.ctrl);

      _expectKeyPress(p.parseControl(0x1c), code: 0x5c, mod: KeyMod.ctrl);
      _expectKeyPress(p.parseControl(0x1f), code: 0x5f, mod: KeyMod.ctrl);

      expect(p.parseControl(0x80), isA<UnknownEvent>());
      expect((p.parseControl(0x80) as UnknownEvent).value, '\u0080');
    });

    test('Win32 helper functions', () {
      final key1 = ensureKeyCase(
        const Key(code: 0x61, text: 'A', mod: KeyMod.shift),
        Win32ControlKeyState.shiftPressed,
      );
      expect(key1.code, 0x61);
      expect(key1.shiftedCode, 0x41);
      expect(key1.text, 'A');

      final key2 = ensureKeyCase(const Key(code: 0x61, text: 'a'), 0);
      expect(key2.code, 0x61);
      expect(key2.text, 'a');

      final key3 = ensureKeyCase(const Key(code: 0x41, text: 'A'), 0);
      expect(key3.code, 0x41);
      expect(key3.shiftedCode, 0x61);
      expect(key3.text, 'a');

      final key4 = ensureKeyCase(const Key(code: 0x31, text: '1'), 0);
      expect(key4.code, 0x31);
      expect(key4.text, '1');

      expect(
        translateControlKeyState(Win32ControlKeyState.rightAltPressed),
        KeyMod.alt,
      );
      expect(
        translateControlKeyState(Win32ControlKeyState.leftAltPressed),
        KeyMod.alt,
      );
      expect(
        translateControlKeyState(Win32ControlKeyState.rightCtrlPressed),
        KeyMod.ctrl,
      );
      expect(
        translateControlKeyState(Win32ControlKeyState.leftCtrlPressed),
        KeyMod.ctrl,
      );
      expect(
        translateControlKeyState(Win32ControlKeyState.shiftPressed),
        KeyMod.shift,
      );
      expect(
        translateControlKeyState(Win32ControlKeyState.numLockOn),
        KeyMod.numLock,
      );
      expect(
        translateControlKeyState(Win32ControlKeyState.scrollLockOn),
        KeyMod.scrollLock,
      );
      expect(
        translateControlKeyState(Win32ControlKeyState.capsLockOn),
        KeyMod.capsLock,
      );
      expect(translateControlKeyState(Win32ControlKeyState.enhancedKey), 0);
      expect(
        translateControlKeyState(
          Win32ControlKeyState.rightAltPressed |
              Win32ControlKeyState.rightCtrlPressed |
              Win32ControlKeyState.shiftPressed,
        ),
        KeyMod.alt | KeyMod.ctrl | KeyMod.shift,
      );

      final evPress = parseWin32InputKeyEvent(0x41, 0, 0x61, true, 0, 1);
      expect(evPress, isA<KeyPressEvent>());
      final evRel = parseWin32InputKeyEvent(0x41, 0, 0x61, false, 0, 1);
      expect(evRel, isA<KeyReleaseEvent>());
      final evFn = parseWin32InputKeyEvent(0x70, 0, 0, true, 0, 1);
      expect(evFn, isA<KeyPressEvent>());
      final evEnter = parseWin32InputKeyEvent(0x0d, 0, 0x0d, true, 0, 1);
      expect(evEnter, isA<KeyPressEvent>());
    });
  });
}
