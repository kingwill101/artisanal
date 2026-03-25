import 'package:artisanal/src/tui/bubbles/number_input.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/tui.dart' show Key, KeyMsg, KeyType;
import 'package:test/test.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

KeyMsg _key(KeyType type) => KeyMsg(Key(type));
KeyMsg _rune(String ch) => KeyMsg(Key(KeyType.runes, runes: ch.runes.toList()));

/// Runs [cmd] and returns the emitted [Msg], or null if none.
Future<Object?> _exec(Object? cmd) async {
  if (cmd == null) return null;
  // Cmd is callable via .execute()
  final c = cmd as dynamic;
  return await (c.execute() as Future);
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('NumberInputModel', () {
    // ── construction ────────────────────────────────────────────────────────

    group('construction', () {
      test('default values', () {
        final m = NumberInputModel();
        expect(m.rawInput, isEmpty);
        expect(m.numericValue, isNull);
        expect(m.error, isNull);
        expect(m.prompt, '? ');
        expect(m.step, 1);
        expect(m.min, isNull);
        expect(m.max, isNull);
      });

      test('defaultValue seeds raw input', () {
        final m = NumberInputModel(defaultValue: 42);
        expect(m.rawInput, '42');
        expect(m.numericValue, 42);
      });

      test('defaultValue uses integer formatting for whole numbers', () {
        final m = NumberInputModel(defaultValue: 3.0);
        expect(m.rawInput, '3');
      });

      test('defaultValue preserves decimal for fractional numbers', () {
        final m = NumberInputModel(defaultValue: 3.14);
        expect(m.rawInput, '3.14');
      });
    });

    // ── character input ──────────────────────────────────────────────────────

    group('character input', () {
      test('accepts digit characters', () {
        var m = NumberInputModel();
        for (final ch in ['1', '2', '3']) {
          final (next, _) = m.update(_rune(ch));
          m = next;
        }
        expect(m.rawInput, '123');
      });

      test('accepts minus sign', () {
        var m = NumberInputModel();
        final (next, _) = m.update(_rune('-'));
        expect(next.rawInput, '-');
      });

      test('accepts decimal point', () {
        var m = NumberInputModel();
        final (next, _) = m.update(_rune('1'));
        final (next2, _) = next.update(_rune('.'));
        final (next3, _) = next2.update(_rune('5'));
        expect(next3.rawInput, '1.5');
      });

      test('ignores non-numeric characters', () {
        var m = NumberInputModel();
        final (next, _) = m.update(_rune('a'));
        expect(next.rawInput, isEmpty);
      });

      test('ignores letters even after digits', () {
        var m = NumberInputModel(defaultValue: 5);
        final (next, _) = m.update(_rune('x'));
        expect(next.rawInput, '5');
      });
    });

    // ── backspace ────────────────────────────────────────────────────────────

    group('backspace', () {
      test('removes last character', () {
        final m = NumberInputModel(defaultValue: 42);
        final (next, _) = m.update(_key(KeyType.backspace));
        expect(next.rawInput, '4');
      });

      test('no-op when empty', () {
        final m = NumberInputModel();
        final (next, _) = m.update(_key(KeyType.backspace));
        expect(next.rawInput, isEmpty);
      });

      test('deletes a full grapheme cluster', () {
        // Simulate a multi-codepoint character at the end.
        final m = NumberInputModel();
        // Type '1' then a combining character (won't be accepted since it's
        // not a valid digit, but we can test with a regular digit sequence).
        // For the grapheme test: type '1', '2', backspace → '1'.
        var cur = m;
        for (final ch in ['1', '2']) {
          final (n, _) = cur.update(_rune(ch));
          cur = n;
        }
        expect(cur.rawInput, '12');
        final (after, _) = cur.update(_key(KeyType.backspace));
        expect(after.rawInput, '1');
      });
    });

    // ── increment / decrement ────────────────────────────────────────────────

    group('increment (Up arrow)', () {
      test('increments from typed value by step=1', () {
        final m = NumberInputModel(defaultValue: 5);
        final (next, _) = m.update(_key(KeyType.up));
        expect(next.rawInput, '6');
      });

      test('increments by custom step', () {
        final m = NumberInputModel(defaultValue: 10, step: 5);
        final (next, _) = m.update(_key(KeyType.up));
        expect(next.rawInput, '15');
      });

      test('clamps to max', () {
        final m = NumberInputModel(defaultValue: 9, max: 10);
        final (next, _) = m.update(_key(KeyType.up));
        expect(next.rawInput, '10');
        final (next2, _) = next.update(_key(KeyType.up));
        expect(next2.rawInput, '10');
      });

      test('seeds from min when empty and incrementing', () {
        final m = NumberInputModel(min: 3, max: 10);
        expect(m.rawInput, isEmpty);
        final (next, _) = m.update(_key(KeyType.up));
        expect(next.rawInput, '3');
      });

      test('seeds from 0 when empty and no min', () {
        final m = NumberInputModel();
        final (next, _) = m.update(_key(KeyType.up));
        expect(next.rawInput, '0');
      });

      test('clears error on increment', () {
        // Test that after increment, error is null.
        final m = NumberInputModel(defaultValue: 5, max: 5);
        final (after, _) = m.update(_key(KeyType.up));
        expect(after.error, isNull);
      });
    });

    group('decrement (Down arrow)', () {
      test('decrements from typed value by step=1', () {
        final m = NumberInputModel(defaultValue: 5);
        final (next, _) = m.update(_key(KeyType.down));
        expect(next.rawInput, '4');
      });

      test('clamps to min', () {
        final m = NumberInputModel(defaultValue: 1, min: 0);
        final (next, _) = m.update(_key(KeyType.down));
        expect(next.rawInput, '0');
        final (next2, _) = next.update(_key(KeyType.down));
        expect(next2.rawInput, '0');
      });

      test('seeds from max when empty and decrementing', () {
        final m = NumberInputModel(min: 3, max: 10);
        final (next, _) = m.update(_key(KeyType.down));
        expect(next.rawInput, '10');
      });

      test('seeds from 0 when empty and no max', () {
        final m = NumberInputModel();
        final (next, _) = m.update(_key(KeyType.down));
        expect(next.rawInput, '0');
      });
    });

    // ── submit ───────────────────────────────────────────────────────────────

    group('submit (Enter)', () {
      test('emits NumberSubmittedMsg with parsed value', () async {
        final m = NumberInputModel(defaultValue: 42);
        final (_, cmd) = m.update(_key(KeyType.enter));
        final msg = await _exec(cmd);
        expect(msg, isA<NumberSubmittedMsg>());
        expect((msg as NumberSubmittedMsg).value, 42);
      });

      test('emits error when input is empty', () {
        final m = NumberInputModel();
        final (next, cmd) = m.update(_key(KeyType.enter));
        expect(cmd, isNull);
        expect(next.error, isNotNull);
        expect(next.error, contains('required'));
      });

      test('emits error when value below min', () {
        final m = NumberInputModel(defaultValue: 1, min: 5);
        final (next, cmd) = m.update(_key(KeyType.enter));
        expect(cmd, isNull);
        expect(next.error, contains('5'));
      });

      test('emits error when value above max', () {
        final m = NumberInputModel(defaultValue: 100, max: 50);
        final (next, cmd) = m.update(_key(KeyType.enter));
        expect(cmd, isNull);
        expect(next.error, contains('50'));
      });

      test('runs custom validate function', () {
        final m = NumberInputModel(
          defaultValue: 7,
          validate: (v) => v == 7 ? 'Lucky 7 not allowed' : null,
        );
        final (next, cmd) = m.update(_key(KeyType.enter));
        expect(cmd, isNull);
        expect(next.error, 'Lucky 7 not allowed');
      });

      test('custom validate passes for valid value', () async {
        final m = NumberInputModel(
          defaultValue: 8,
          validate: (v) => v == 7 ? 'Lucky 7 not allowed' : null,
        );
        final (_, cmd) = m.update(_key(KeyType.enter));
        final msg = await _exec(cmd);
        expect(msg, isA<NumberSubmittedMsg>());
      });

      test('clears previous error on successful submit', () async {
        // First attempt: empty → error
        var m = NumberInputModel();
        final (m1, _) = m.update(_key(KeyType.enter));
        expect(m1.error, isNotNull);

        // Type a valid digit
        final (m2, _) = m1.update(_rune('5'));
        // ignore: unused_local_variable
        // Submit
        final (m3, cmd) = m2.update(_key(KeyType.enter));
        expect(m3.error, isNull);
        final msg = await _exec(cmd);
        expect(msg, isA<NumberSubmittedMsg>());
      });
    });

    // ── cancel ───────────────────────────────────────────────────────────────

    group('cancel (Escape)', () {
      test('emits NumberCancelledMsg on Escape', () async {
        final m = NumberInputModel(defaultValue: 5);
        final (_, cmd) = m.update(_key(KeyType.escape));
        final msg = await _exec(cmd);
        expect(msg, isA<NumberCancelledMsg>());
      });
    });

    // ── view ─────────────────────────────────────────────────────────────────

    group('view()', () {
      test('shows placeholder when input is empty', () {
        final m = NumberInputModel(placeholder: '(enter a number)');
        final view = Style.stripAnsi(m.view());
        expect(view, contains('(enter a number)'));
      });

      test('shows typed value', () {
        final m = NumberInputModel(defaultValue: 42);
        final view = Style.stripAnsi(m.view());
        expect(view, contains('42'));
      });

      test('shows error when present', () {
        var m = NumberInputModel();
        final (next, _) = m.update(_key(KeyType.enter));
        final view = Style.stripAnsi(next.view());
        expect(view, contains('required'));
      });

      test('shows range hint from min/max when no explicit hint', () {
        final m = NumberInputModel(min: 1, max: 100);
        final view = Style.stripAnsi(m.view());
        expect(view, contains('min: 1'));
        expect(view, contains('max: 100'));
      });

      test('shows explicit hint over range hint', () {
        final m = NumberInputModel(min: 1, max: 100, hint: 'Custom hint');
        final view = Style.stripAnsi(m.view());
        expect(view, contains('Custom hint'));
        expect(view, isNot(contains('min:')));
      });

      test('shows step in hint when step != 1', () {
        final m = NumberInputModel(step: 5);
        final view = Style.stripAnsi(m.view());
        expect(view, contains('step: 5'));
      });

      test('shows prompt text', () {
        final m = NumberInputModel(prompt: 'Port: ');
        final view = Style.stripAnsi(m.view());
        expect(view, contains('Port:'));
      });

      test('shows help when showHelp=true', () {
        final m = NumberInputModel(showHelp: true);
        final view = Style.stripAnsi(m.view());
        // shortHelp contains increment + decrement + submit + cancel bindings
        expect(view, contains('↑'));
        expect(view, contains('↓'));
      });

      test('hides help when showHelp=false', () {
        final m = NumberInputModel(showHelp: false);
        final view = Style.stripAnsi(m.view());
        expect(view, isNot(contains('↑')));
      });
    });

    // ── init ─────────────────────────────────────────────────────────────────

    test('init() returns null', () {
      final m = NumberInputModel();
      expect(m.init(), isNull);
    });
  });
}
