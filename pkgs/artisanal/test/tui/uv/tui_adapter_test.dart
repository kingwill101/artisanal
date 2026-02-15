import 'package:artisanal/src/terminal/keys.dart' as term;
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/uv/tui_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('UvTuiInputParser', () {
    test('maps key press events to KeyMsg', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[A'.codeUnits); // CSI A (up)
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.up);
    });

    test('maps focus/blur to FocusMsg', () {
      final p = UvTuiInputParser();
      expect(p.parseAll('\x1b[I'.codeUnits), [const FocusMsg(true)]);
      expect(p.parseAll('\x1b[O'.codeUnits), [const FocusMsg(false)]);
    });

    test('emits PasteMsg for bracketed paste content', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[200~hello\x1b[201~'.codeUnits);
      expect(msgs, [const PasteMsg('hello')]);
    });

    test('maps LF (0x0A) to Enter key', () {
      // LF (line feed, 0x0A) should be mapped to Enter, not Ctrl+J
      final p = UvTuiInputParser();
      final msgs = p.parseAll([0x0A]); // LF byte
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.enter);
      // Should not have ctrl modifier since it's Enter, not Ctrl+J
      expect(k.ctrl, false);
    });

    test('maps CR (0x0D) to Enter key', () {
      // CR (carriage return, 0x0D) should be mapped to Enter
      final p = UvTuiInputParser();
      final msgs = p.parseAll([0x0D]); // CR byte
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.enter);
    });

    test('plain j key is distinct from Enter', () {
      // Plain 'j' (0x6A) should remain as 'j', not be confused with Enter
      final p = UvTuiInputParser();
      final msgs = p.parseAll([0x6A]); // 'j' byte
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.runes);
      expect(k.runes, [0x6A]);
      expect(k.ctrl, false);
    });

    test('maps 0x08 (BS/Ctrl+H) to Backspace key', () {
      // 0x08 byte should be mapped to Backspace, not Ctrl+H
      // This matches the TUI parser behavior for consistency
      final p = UvTuiInputParser();
      final msgs = p.parseAll([0x08]); // BS/Ctrl+H byte
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.backspace);
      // Should not have ctrl modifier since it's Backspace, not Ctrl+H
      expect(k.ctrl, false);
    });

    test('preserves meta/hyper/super modifiers from UV events', () {
      // Test that extended modifiers are preserved through the adapter.
      // We test this by directly calling the adapter with a UV Key that has
      // these modifiers set.
      final p = UvTuiInputParser();

      // CSI 1;9 A = Up with Meta modifier (modifier code 9 = meta)
      // CSI u format: \x1b[code;modifiers;event_type u
      // For arrow keys with modifiers: \x1b[1;modifiersA
      // Modifier 9 = 1 + 8 where 8 = meta
      final msgs = p.parseAll('\x1b[1;9A'.codeUnits); // Up + Meta
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.up);
      expect(k.meta, true, reason: 'Meta modifier should be preserved');
    });

    test('Key class supports all extended modifiers', () {
      // Unit test for Key class with new modifiers
      final key = term.Key(
        term.KeyType.runes,
        runes: [0x61], // 'a'
        meta: true,
        hyper: true,
        superKey: true,
      );

      expect(key.meta, true);
      expect(key.hyper, true);
      expect(key.superKey, true);
      expect(key.hasModifier, true);
      expect(key.toString(), contains('Meta'));
      expect(key.toString(), contains('Hyper'));
      expect(key.toString(), contains('Super'));

      // Test copyWith preserves modifiers
      final copy = key.copyWith(ctrl: true);
      expect(copy.meta, true);
      expect(copy.hyper, true);
      expect(copy.superKey, true);
      expect(copy.ctrl, true);

      // Test equality with new modifiers
      final key2 = term.Key(
        term.KeyType.runes,
        runes: [0x61],
        meta: true,
        hyper: true,
        superKey: true,
      );
      expect(key, equals(key2));

      // Keys with different modifiers should not be equal
      final key3 = term.Key(
        term.KeyType.runes,
        runes: [0x61],
        meta: false,
        hyper: true,
        superKey: true,
      );
      expect(key, isNot(equals(key3)));
    });

    test('extended function keys F21-F35 map to proper KeyType', () {
      // Extended function keys F21-F35 are now supported in the TUI KeyType enum.
      // Note: F36-F63 are not in the standard Kitty CSI u table.
      final p = UvTuiInputParser();

      // F21 via CSI u format: ESC [ 57384 u
      final msgsF21 = p.parseAll('\x1b[57384u'.codeUnits);
      expect(msgsF21, hasLength(1));
      expect(msgsF21[0], isA<KeyMsg>());
      expect((msgsF21[0] as KeyMsg).key.type, term.KeyType.f21);

      // F35 via CSI u format: ESC [ 57398 u
      final msgsF35 = p.parseAll('\x1b[57398u'.codeUnits);
      expect(msgsF35, hasLength(1));
      expect((msgsF35[0] as KeyMsg).key.type, term.KeyType.f35);
    });

    test('media keys map to proper KeyType', () {
      // Media keys are now supported in the TUI KeyType enum.
      final p = UvTuiInputParser();

      // Media Play via CSI u format: ESC [ 57428 u
      final msgsPlay = p.parseAll('\x1b[57428u'.codeUnits);
      expect(msgsPlay, hasLength(1));
      expect(msgsPlay[0], isA<KeyMsg>());
      expect((msgsPlay[0] as KeyMsg).key.type, term.KeyType.mediaPlay);

      // Media Stop via CSI u format: ESC [ 57432 u
      final msgsStop = p.parseAll('\x1b[57432u'.codeUnits);
      expect(msgsStop, hasLength(1));
      expect((msgsStop[0] as KeyMsg).key.type, term.KeyType.mediaStop);

      // Media Next via CSI u format: ESC [ 57435 u
      final msgsNext = p.parseAll('\x1b[57435u'.codeUnits);
      expect(msgsNext, hasLength(1));
      expect((msgsNext[0] as KeyMsg).key.type, term.KeyType.mediaNext);
    });

    test('lock keys map to proper KeyType', () {
      // Lock keys are now supported in the TUI KeyType enum.
      final p = UvTuiInputParser();

      // CapsLock via CSI u format: ESC [ 57358 u
      final msgsCaps = p.parseAll('\x1b[57358u'.codeUnits);
      expect(msgsCaps, hasLength(1));
      expect((msgsCaps[0] as KeyMsg).key.type, term.KeyType.capsLock);

      // NumLock via CSI u format: ESC [ 57360 u
      final msgsNum = p.parseAll('\x1b[57360u'.codeUnits);
      expect(msgsNum, hasLength(1));
      expect((msgsNum[0] as KeyMsg).key.type, term.KeyType.numLock);

      // ScrollLock via CSI u format: ESC [ 57359 u
      final msgsScroll = p.parseAll('\x1b[57359u'.codeUnits);
      expect(msgsScroll, hasLength(1));
      expect((msgsScroll[0] as KeyMsg).key.type, term.KeyType.scrollLock);
    });

    test('volume keys map to proper KeyType', () {
      // Volume keys are now supported in the TUI KeyType enum.
      final p = UvTuiInputParser();

      // Volume Down via CSI u format: ESC [ 57438 u
      final msgsDown = p.parseAll('\x1b[57438u'.codeUnits);
      expect(msgsDown, hasLength(1));
      expect((msgsDown[0] as KeyMsg).key.type, term.KeyType.volumeDown);

      // Volume Up via CSI u format: ESC [ 57439 u
      final msgsUp = p.parseAll('\x1b[57439u'.codeUnits);
      expect(msgsUp, hasLength(1));
      expect((msgsUp[0] as KeyMsg).key.type, term.KeyType.volumeUp);

      // Mute via CSI u format: ESC [ 57440 u
      final msgsMute = p.parseAll('\x1b[57440u'.codeUnits);
      expect(msgsMute, hasLength(1));
      expect((msgsMute[0] as KeyMsg).key.type, term.KeyType.mute);
    });

    test('modifier keys as standalone presses map to proper KeyType', () {
      // Modifier keys are now supported in the TUI KeyType enum.
      final p = UvTuiInputParser();

      // Left Shift via CSI u format: ESC [ 57441 u
      final msgsLShift = p.parseAll('\x1b[57441u'.codeUnits);
      expect(msgsLShift, hasLength(1));
      expect((msgsLShift[0] as KeyMsg).key.type, term.KeyType.leftShift);

      // Right Ctrl via CSI u format: ESC [ 57448 u
      final msgsRCtrl = p.parseAll('\x1b[57448u'.codeUnits);
      expect(msgsRCtrl, hasLength(1));
      expect((msgsRCtrl[0] as KeyMsg).key.type, term.KeyType.rightCtrl);

      // Left Meta via CSI u format: ESC [ 57446 u
      final msgsLMeta = p.parseAll('\x1b[57446u'.codeUnits);
      expect(msgsLMeta, hasLength(1));
      expect((msgsLMeta[0] as KeyMsg).key.type, term.KeyType.leftMeta);
    });

    test('F1-F20 map correctly through adapter', () {
      final p = UvTuiInputParser();

      // F1 via CSI u format: ESC [ 57364 u
      final msgsF1 = p.parseAll('\x1b[57364u'.codeUnits);
      expect(msgsF1, hasLength(1));
      expect((msgsF1[0] as KeyMsg).key.type, term.KeyType.f1);

      // F12 via CSI u format: ESC [ 57375 u
      final msgsF12 = p.parseAll('\x1b[57375u'.codeUnits);
      expect(msgsF12, hasLength(1));
      expect((msgsF12[0] as KeyMsg).key.type, term.KeyType.f12);

      // F20 via CSI u format: ESC [ 57383 u
      final msgsF20 = p.parseAll('\x1b[57383u'.codeUnits);
      expect(msgsF20, hasLength(1));
      expect((msgsF20[0] as KeyMsg).key.type, term.KeyType.f20);
    });
  });
}
