import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity (scoped):
// - `third_party/ultraviolet/key_test.go`:
//   - TestMatchStrings
//   - TestKeyMatchString
//   - TestKeystroke (+ coverage)
//   - TestKeyStringMore

void main() {
  group('UV parity: Key.matchStrings', () {
    test('MatchStrings() matches any pattern', () {
      final tests = <({String name, Key key, List<String> inputs, bool want})>[
        (
          name: 'matches first string',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl),
          inputs: const ['ctrl+a', 'ctrl+b', 'ctrl+c'],
          want: true,
        ),
        (
          name: 'matches middle string',
          key: const Key(code: 0x62 /* b */, mod: KeyMod.ctrl),
          inputs: const ['ctrl+a', 'ctrl+b', 'ctrl+c'],
          want: true,
        ),
        (
          name: 'matches last string',
          key: const Key(code: 0x63 /* c */, mod: KeyMod.ctrl),
          inputs: const ['ctrl+a', 'ctrl+b', 'ctrl+c'],
          want: true,
        ),
        (
          name: 'no match',
          key: const Key(code: 0x64 /* d */, mod: KeyMod.ctrl),
          inputs: const ['ctrl+a', 'ctrl+b', 'ctrl+c'],
          want: false,
        ),
        (
          name: 'empty inputs',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl),
          inputs: const [],
          want: false,
        ),
      ];

      for (final tc in tests) {
        expect(tc.key.matchStrings(tc.inputs), tc.want, reason: tc.name);
      }
    });
  });

  group('UV parity: Key.matchString', () {
    test('MatchString() matches key patterns', () {
      final cases = <({String name, Key key, String input, bool want})>[
        (
          name: 'ctrl+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl),
          input: 'ctrl+a',
          want: true,
        ),
        (
          name: 'ctrl+alt+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl | KeyMod.alt),
          input: 'ctrl+alt+a',
          want: true,
        ),
        (
          name: 'ctrl+alt+shift+a',
          key: const Key(
            code: 0x61 /* a */,
            mod: KeyMod.ctrl | KeyMod.alt | KeyMod.shift,
          ),
          input: 'ctrl+alt+shift+a',
          want: true,
        ),
        (
          name: 'H',
          key: const Key(code: 0x48 /* H */, text: 'H'),
          input: 'H',
          want: true,
        ),
        (
          name: 'shift+h (text override)',
          key: const Key(code: 0x68 /* h */, mod: KeyMod.shift, text: 'H'),
          input: 'H',
          want: true,
        ),
        (
          name: '?',
          key: const Key(code: 0x2f /* / */, mod: KeyMod.shift, text: '?'),
          input: '?',
          want: true,
        ),
        (
          name: 'shift+/',
          key: const Key(code: 0x2f /* / */, mod: KeyMod.shift, text: '?'),
          input: 'shift+/',
          want: true,
        ),
        (
          name: 'capslock+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.capsLock, text: 'A'),
          input: 'A',
          want: true,
        ),
        (
          name: 'ctrl+capslock+a does not match ctrl+a',
          key: const Key(
            code: 0x61 /* a */,
            mod: KeyMod.ctrl | KeyMod.capsLock,
          ),
          input: 'ctrl+a',
          want: false,
        ),
        (
          name: 'space',
          key: const Key(code: keySpace, text: ' '),
          input: 'space',
          want: true,
        ),
        (
          name: 'whitespace',
          key: const Key(code: keySpace, text: ' '),
          input: ' ',
          want: true,
        ),
        (
          name: 'ctrl+space',
          key: const Key(code: keySpace, mod: KeyMod.ctrl),
          input: 'ctrl+space',
          want: true,
        ),
        (
          name: 'shift+whitespace (text override)',
          key: const Key(code: keySpace, mod: KeyMod.shift, text: ' '),
          input: ' ',
          want: true,
        ),
        (
          name: 'shift+space',
          key: const Key(code: keySpace, mod: KeyMod.shift, text: ' '),
          input: 'shift+space',
          want: true,
        ),
        (
          name: 'meta modifier',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.meta),
          input: 'meta+a',
          want: true,
        ),
        (
          name: 'hyper modifier',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.hyper),
          input: 'hyper+a',
          want: true,
        ),
        (
          name: 'super modifier',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.superKey),
          input: 'super+a',
          want: true,
        ),
        (
          name: 'scrolllock modifier',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.scrollLock),
          input: 'scrolllock+a',
          want: true,
        ),
        (
          name: 'numlock modifier',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.numLock),
          input: 'numlock+a',
          want: true,
        ),
        (
          name: 'multi-rune key',
          key: const Key(code: keyExtended, text: 'hello'),
          input: 'hello',
          want: true,
        ),
        (
          name: 'enter key',
          key: const Key(code: keyEnter),
          input: 'enter',
          want: true,
        ),
        (
          name: 'tab key',
          key: const Key(code: keyTab),
          input: 'tab',
          want: true,
        ),
        (
          name: 'escape key',
          key: const Key(code: keyEscape),
          input: 'esc',
          want: true,
        ),
        (name: 'f1 key', key: const Key(code: keyF1), input: 'f1', want: true),
        (
          name: 'backspace key',
          key: const Key(code: keyBackspace),
          input: 'backspace',
          want: true,
        ),
        (
          name: 'delete key',
          key: const Key(code: keyDelete),
          input: 'delete',
          want: true,
        ),
        (
          name: 'home key',
          key: const Key(code: keyHome),
          input: 'home',
          want: true,
        ),
        (
          name: 'end key',
          key: const Key(code: keyEnd),
          input: 'end',
          want: true,
        ),
        (
          name: 'pgup key',
          key: const Key(code: keyPgUp),
          input: 'pgup',
          want: true,
        ),
        (
          name: 'pgdown key',
          key: const Key(code: keyPgDown),
          input: 'pgdown',
          want: true,
        ),
        (
          name: 'up arrow',
          key: const Key(code: keyUp),
          input: 'up',
          want: true,
        ),
        (
          name: 'down arrow',
          key: const Key(code: keyDown),
          input: 'down',
          want: true,
        ),
        (
          name: 'left arrow',
          key: const Key(code: keyLeft),
          input: 'left',
          want: true,
        ),
        (
          name: 'right arrow',
          key: const Key(code: keyRight),
          input: 'right',
          want: true,
        ),
        (
          name: 'insert key',
          key: const Key(code: keyInsert),
          input: 'insert',
          want: true,
        ),
        (
          name: 'single printable character',
          key: const Key(code: 0x31 /* 1 */, text: '1'),
          input: '1',
          want: true,
        ),
        (
          name: 'uppercase letter without shift',
          key: const Key(code: 0x41 /* A */, text: 'A'),
          input: 'A',
          want: true,
        ),
        (
          name: 'no match different key',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl),
          input: 'ctrl+b',
          want: false,
        ),
        (
          name: 'no match different modifier',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl),
          input: 'alt+a',
          want: false,
        ),
        (
          name: 'unknown key name',
          key: const Key(code: 0x78 /* x */),
          input: 'unknownkey',
          want: false,
        ),
        (
          name: 'multi-rune string that does not match',
          key: const Key(code: 0x61 /* a */),
          input: 'hello',
          want: false,
        ),
        (
          name: 'printable character with ctrl modifier does not match a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl),
          input: 'a',
          want: false,
        ),
        (
          name: 'lowercase letter with shift',
          key: const Key(code: 0x68 /* h */, mod: KeyMod.shift),
          input: 'shift+h',
          want: true,
        ),
        (
          name: 'uppercase letter with capslock',
          key: const Key(code: 0x68 /* h */, mod: KeyMod.capsLock),
          input: 'capslock+h',
          want: true,
        ),
      ];

      for (var i = 0; i < cases.length; i++) {
        final tc = cases[i];
        expect(tc.key.matchString(tc.input), tc.want, reason: '$i: ${tc.name}');
      }
    });
  });

  group('UV parity: Key.keystroke', () {
    test('Keystroke() string formatting matches upstream', () {
      final tests = <({String name, Key key, String want})>[
        (name: 'simple key', key: const Key(code: 0x61 /* a */), want: 'a'),
        (
          name: 'ctrl+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.ctrl),
          want: 'ctrl+a',
        ),
        (
          name: 'alt+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.alt),
          want: 'alt+a',
        ),
        (
          name: 'shift+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.shift),
          want: 'shift+a',
        ),
        (
          name: 'meta+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.meta),
          want: 'meta+a',
        ),
        (
          name: 'hyper+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.hyper),
          want: 'hyper+a',
        ),
        (
          name: 'super+a',
          key: const Key(code: 0x61 /* a */, mod: KeyMod.superKey),
          want: 'super+a',
        ),
        (
          name: 'ctrl+alt+shift+a',
          key: const Key(
            code: 0x61 /* a */,
            mod: KeyMod.ctrl | KeyMod.alt | KeyMod.shift,
          ),
          want: 'ctrl+alt+shift+a',
        ),
        (
          name: 'all modifiers',
          key: const Key(
            code: 0x61 /* a */,
            mod:
                KeyMod.ctrl |
                KeyMod.alt |
                KeyMod.shift |
                KeyMod.meta |
                KeyMod.hyper |
                KeyMod.superKey,
          ),
          want: 'ctrl+alt+shift+meta+hyper+super+a',
        ),
        (name: 'space key', key: const Key(code: keySpace), want: 'space'),
        (
          name: 'extended key with text',
          key: const Key(code: keyExtended, text: 'hello'),
          want: 'hello',
        ),
        (name: 'enter key', key: const Key(code: keyEnter), want: 'enter'),
        (name: 'tab key', key: const Key(code: keyTab), want: 'tab'),
        (name: 'escape key', key: const Key(code: keyEscape), want: 'esc'),
        (name: 'f1 key', key: const Key(code: keyF1), want: 'f1'),
        (
          name: 'backspace key',
          key: const Key(code: keyBackspace),
          want: 'backspace',
        ),
        (
          name: 'left ctrl key alone',
          key: const Key(code: keyLeftCtrl, mod: KeyMod.ctrl),
          want: 'leftctrl',
        ),
        (
          name: 'right ctrl key alone',
          key: const Key(code: keyRightCtrl, mod: KeyMod.ctrl),
          want: 'rightctrl',
        ),
        (
          name: 'left alt key alone',
          key: const Key(code: keyLeftAlt, mod: KeyMod.alt),
          want: 'leftalt',
        ),
        (
          name: 'right alt key alone',
          key: const Key(code: keyRightAlt, mod: KeyMod.alt),
          want: 'rightalt',
        ),
        (
          name: 'left shift key alone',
          key: const Key(code: keyLeftShift, mod: KeyMod.shift),
          want: 'leftshift',
        ),
        (
          name: 'right shift key alone',
          key: const Key(code: keyRightShift, mod: KeyMod.shift),
          want: 'rightshift',
        ),
        (
          name: 'left meta key alone',
          key: const Key(code: keyLeftMeta, mod: KeyMod.meta),
          want: 'leftmeta',
        ),
        (
          name: 'right meta key alone',
          key: const Key(code: keyRightMeta, mod: KeyMod.meta),
          want: 'rightmeta',
        ),
        (
          name: 'left hyper key alone',
          key: const Key(code: keyLeftHyper, mod: KeyMod.hyper),
          want: 'lefthyper',
        ),
        (
          name: 'right hyper key alone',
          key: const Key(code: keyRightHyper, mod: KeyMod.hyper),
          want: 'righthyper',
        ),
        (
          name: 'left super key alone',
          key: const Key(code: keyLeftSuper, mod: KeyMod.superKey),
          want: 'leftsuper',
        ),
        (
          name: 'right super key alone',
          key: const Key(code: keyRightSuper, mod: KeyMod.superKey),
          want: 'rightsuper',
        ),
        (
          name: 'key with base code',
          key: const Key(code: 0x41 /* A */, baseCode: 0x61 /* a */),
          want: 'a',
        ),
        (
          name: 'unknown key with base code',
          key: const Key(code: 99999, baseCode: 0x78 /* x */),
          want: 'x',
        ),
        (
          name: 'printable rune',
          key: const Key(code: 0x20ac /* € */),
          want: '€',
        ),
        (
          name: 'unknown key without base code',
          key: const Key(code: 99999),
          want: '𘚟',
        ),
        (
          name: 'coverage: unknown key with baseCode=space',
          key: const Key(code: 999999, baseCode: keySpace),
          want: 'space',
        ),
      ];

      for (final tc in tests) {
        expect(tc.key.keystroke(), tc.want, reason: tc.name);
      }
    });
  });

  group('UV parity: Key.toString', () {
    test('String() mirrors upstream', () {
      final tests = <({String name, Key key, String want})>[
        (
          name: 'space character',
          key: const Key(code: keySpace, text: ' '),
          want: 'space',
        ),
        (name: 'empty text', key: const Key(code: 0x61 /* a */), want: 'a'),
        (
          name: 'text with multiple characters',
          key: const Key(code: keyExtended, text: 'hello'),
          want: 'hello',
        ),
      ];

      for (final tc in tests) {
        expect(tc.key.toString(), tc.want, reason: tc.name);
      }
    });
  });
}
