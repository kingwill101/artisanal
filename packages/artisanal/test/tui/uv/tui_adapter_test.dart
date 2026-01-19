import 'package:artisanal/src/terminal/keys.dart' as term;
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/uv/uv.dart';
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

    test('extended function keys (F21+) map to unknown KeyType', () {
      // Extended function keys F21-F63 are defined in UV but the TUI KeyType
      // enum only has F1-F20. Keys beyond F20 should gracefully fall back
      // to KeyType.unknown rather than crash.
      //
      // This is documented behavior: applications that need F21+ should use
      // the raw UV events directly via UvEventMsg.
      final p = UvTuiInputParser();

      // F21 via CSI escape sequence: ESC [ 1 ; modifier P  (21~)
      // Actually F21 in xterm-style is ESC [ 21 ~
      // But in CSI u format (Kitty protocol): ESC [ 57384 u
      final msgs = p.parseAll('\x1b[57384u'.codeUnits); // F21 in CSI u format
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      // F21 maps to unknown since KeyType only has F1-F20
      expect(k.type, term.KeyType.unknown);
    });

    test('media keys map to unknown KeyType', () {
      // Media keys (play, pause, etc.) are defined in UV but not in TUI KeyType.
      // They should gracefully fall back to KeyType.unknown.
      final p = UvTuiInputParser();

      // Media Play via CSI u format: ESC [ 57428 u
      final msgs = p.parseAll('\x1b[57428u'.codeUnits);
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.unknown);
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
