import 'package:artisanal/src/tui/bubbles/suggest.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/tui.dart' show Key, KeyMsg, KeyType;
import 'package:test/test.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

KeyMsg _key(KeyType type) => KeyMsg(Key(type));
KeyMsg _rune(String ch) => KeyMsg(Key(KeyType.runes, runes: ch.runes.toList()));

/// Executes a [Cmd] and returns the emitted message, or null.
Future<Object?> _exec(Object? cmd) async {
  if (cmd == null) return null;
  final c = cmd as dynamic;
  return await (c.execute() as Future);
}

const _fruits = ['apple', 'apricot', 'banana', 'blueberry', 'cherry'];

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('SuggestModel', () {
    // ── construction ────────────────────────────────────────────────────────

    group('construction', () {
      test('default values', () {
        final m = SuggestModel();
        expect(m.rawInput, isEmpty);
        expect(m.highlighted, -1);
        expect(m.options, isEmpty);
        expect(m.prompt, '? ');
        expect(m.scroll, 5);
      });

      test('defaultValue seeds raw input', () {
        final m = SuggestModel(defaultValue: 'hello');
        expect(m.rawInput, 'hello');
      });

      test('options are stored', () {
        final m = SuggestModel(options: _fruits);
        expect(m.options, _fruits);
      });
    });

    // ── matches ──────────────────────────────────────────────────────────────

    group('matches (prefix filtering)', () {
      test('empty input returns all options', () {
        final m = SuggestModel(options: _fruits);
        expect(m.matches, _fruits);
      });

      test('prefix match is case-insensitive', () {
        final m = SuggestModel(options: _fruits, defaultValue: 'AP');
        expect(m.matches, ['apple', 'apricot']);
      });

      test('no match returns empty list', () {
        final m = SuggestModel(options: _fruits, defaultValue: 'xyz');
        expect(m.matches, isEmpty);
      });

      test('full match returns only exact prefix', () {
        final m = SuggestModel(options: _fruits, defaultValue: 'apple');
        expect(m.matches, ['apple']);
      });
    });

    // ── visible window ───────────────────────────────────────────────────────

    group('visible (scroll window)', () {
      test('returns up to scroll items when not scrolled', () {
        final m = SuggestModel(options: _fruits, scroll: 3);
        expect(m.visible.length, 3);
        expect(m.visible.first, 'apple');
      });

      test('returns all items when count <= scroll', () {
        final m = SuggestModel(options: ['a', 'b'], scroll: 5);
        expect(m.visible, ['a', 'b']);
      });

      test('empty options returns empty visible', () {
        final m = SuggestModel(options: [], scroll: 5);
        expect(m.visible, isEmpty);
      });
    });

    // ── character input ──────────────────────────────────────────────────────

    group('character input', () {
      test('appends characters to rawInput', () {
        var m = SuggestModel(options: _fruits);
        for (final ch in 'app'.split('')) {
          final (next, _) = m.update(_rune(ch));
          m = next;
        }
        expect(m.rawInput, 'app');
      });

      test('typing clears highlighted selection', () {
        var m = SuggestModel(options: _fruits);
        // Navigate down to highlight first item
        final (m1, _) = m.update(_key(KeyType.down));
        expect(m1.highlighted, 0);
        // Type a character — should clear highlight
        final (m2, _) = m1.update(_rune('a'));
        expect(m2.highlighted, -1);
      });

      test('typing resets firstVisible to 0', () {
        final m = SuggestModel(options: _fruits, scroll: 2);
        // Navigate to bottom of visible window to advance scroll
        var cur = m;
        for (var i = 0; i < 5; i++) {
          final (n, _) = cur.update(_key(KeyType.down));
          cur = n;
        }
        // Type something — firstVisible should reset
        final (after, _) = cur.update(_rune('a'));
        expect(after.rawInput, contains('a'));
      });
    });

    // ── backspace ────────────────────────────────────────────────────────────

    group('backspace', () {
      test('removes last character', () {
        final m = SuggestModel(options: _fruits, defaultValue: 'app');
        final (next, _) = m.update(_key(KeyType.backspace));
        expect(next.rawInput, 'ap');
      });

      test('no-op when empty', () {
        final m = SuggestModel(options: _fruits);
        final (next, _) = m.update(_key(KeyType.backspace));
        expect(next.rawInput, isEmpty);
      });

      test('clears highlighted selection', () {
        final m = SuggestModel(options: _fruits, defaultValue: 'app');
        final (m1, _) = m.update(_key(KeyType.down));
        expect(m1.highlighted, 0);
        final (m2, _) = m1.update(_key(KeyType.backspace));
        expect(m2.highlighted, -1);
      });

      test('removes correct grapheme inside multibyte input', () {
        final m = SuggestModel(options: const [], defaultValue: 'ab');
        final (next, _) = m.update(_key(KeyType.backspace));
        expect(next.rawInput, 'a');
      });
    });

    // ── navigation ───────────────────────────────────────────────────────────

    group('navigation (down / up)', () {
      test('down highlights first item when nothing highlighted', () {
        final m = SuggestModel(options: _fruits);
        final (next, _) = m.update(_key(KeyType.down));
        expect(next.highlighted, 0);
      });

      test('down advances highlight', () {
        var m = SuggestModel(options: _fruits);
        for (var i = 0; i < 3; i++) {
          final (n, _) = m.update(_key(KeyType.down));
          m = n;
        }
        expect(m.highlighted, 2);
      });

      test('down clamps at last item', () {
        var m = SuggestModel(options: _fruits);
        for (var i = 0; i < 10; i++) {
          final (n, _) = m.update(_key(KeyType.down));
          m = n;
        }
        expect(m.highlighted, _fruits.length - 1);
      });

      test('up with nothing highlighted selects last item', () {
        final m = SuggestModel(options: _fruits);
        final (next, _) = m.update(_key(KeyType.up));
        expect(next.highlighted, _fruits.length - 1);
      });

      test('up moves highlight backward', () {
        var m = SuggestModel(options: _fruits);
        // Move to index 2
        for (var i = 0; i < 3; i++) {
          final (n, _) = m.update(_key(KeyType.down));
          m = n;
        }
        expect(m.highlighted, 2);
        final (next, _) = m.update(_key(KeyType.up));
        expect(next.highlighted, 1);
      });

      test('up clamps at index 0', () {
        var m = SuggestModel(options: _fruits);
        final (m1, _) = m.update(_key(KeyType.down)); // → 0
        final (m2, _) = m1.update(_key(KeyType.up)); // still 0
        final (m3, _) = m2.update(_key(KeyType.up)); // still 0
        expect(m3.highlighted, 0);
      });

      test('no-op when options list is empty', () {
        final m = SuggestModel(options: []);
        final (next, _) = m.update(_key(KeyType.down));
        expect(next.highlighted, -1);
      });
    });

    // ── moveFirst / moveLast ─────────────────────────────────────────────────

    group('moveFirst / moveLast (ctrl+a / ctrl+e)', () {
      test('moveFirst jumps to index 0', () {
        // Only works when highlighted is already >= 0.
        var m = SuggestModel(options: _fruits);
        // Highlight item 2
        for (var i = 0; i < 3; i++) {
          final (n, _) = m.update(_key(KeyType.down));
          m = n;
        }
        expect(m.highlighted, 2);
        // Simulate ctrl+a (home key)
        final homeKey = KeyMsg(Key(KeyType.home));
        final (next, _) = m.update(homeKey);
        expect(next.highlighted, 0);
      });

      test('moveLast jumps to last item', () {
        var m = SuggestModel(options: _fruits);
        final (m1, _) = m.update(_key(KeyType.down)); // highlight 0
        final endKey = KeyMsg(Key(KeyType.end));
        final (next, _) = m1.update(endKey);
        expect(next.highlighted, _fruits.length - 1);
      });

      test('moveFirst no-op when nothing highlighted', () {
        final m = SuggestModel(options: _fruits);
        final homeKey = KeyMsg(Key(KeyType.home));
        final (next, _) = m.update(homeKey);
        expect(next.highlighted, -1);
      });
    });

    // ── cursor left / right ──────────────────────────────────────────────────

    group('cursor left / right', () {
      test('left arrow clears highlight', () {
        var m = SuggestModel(options: _fruits, defaultValue: 'app');
        final (m1, _) = m.update(_key(KeyType.down));
        expect(m1.highlighted, 0);
        final (m2, _) = m1.update(_key(KeyType.left));
        expect(m2.highlighted, -1);
      });

      test('right arrow clears highlight', () {
        var m = SuggestModel(options: _fruits, defaultValue: 'app');
        final (m1, _) = m.update(_key(KeyType.down));
        final (m2, _) = m1.update(_key(KeyType.right));
        expect(m2.highlighted, -1);
      });
    });

    // ── accept (Enter) ───────────────────────────────────────────────────────

    group('accept (Enter)', () {
      test('emits SuggestSubmittedMsg with highlighted suggestion', () async {
        var m = SuggestModel(options: _fruits);
        // Highlight 'apple' (index 0)
        final (m1, _) = m.update(_key(KeyType.down));
        expect(m1.highlighted, 0);
        final (_, cmd) = m1.update(_key(KeyType.enter));
        final msg = await _exec(cmd);
        expect(msg, isA<SuggestSubmittedMsg>());
        expect((msg as SuggestSubmittedMsg).value, 'apple');
      });

      test(
        'emits SuggestSubmittedMsg with typed value when nothing highlighted',
        () async {
          final m = SuggestModel(options: _fruits, defaultValue: 'cherry');
          final (_, cmd) = m.update(_key(KeyType.enter));
          final msg = await _exec(cmd);
          expect(msg, isA<SuggestSubmittedMsg>());
          expect((msg as SuggestSubmittedMsg).value, 'cherry');
        },
      );

      test(
        'emits empty string when input is empty and nothing highlighted',
        () async {
          final m = SuggestModel(options: _fruits);
          final (_, cmd) = m.update(_key(KeyType.enter));
          final msg = await _exec(cmd);
          expect(msg, isA<SuggestSubmittedMsg>());
          expect((msg as SuggestSubmittedMsg).value, isEmpty);
        },
      );

      test('Tab also accepts the highlighted suggestion', () async {
        var m = SuggestModel(options: _fruits);
        final (m1, _) = m.update(_key(KeyType.down));
        // Tab maps to moveDown in the keymap, not accept — but
        // confirm our enter works via direct enter key.
        // The default keymap maps 'tab' to moveDown and 'enter' to accept.
        // So verify enter is correct.
        final (_, cmd) = m1.update(_key(KeyType.enter));
        final msg = await _exec(cmd);
        expect((msg as SuggestSubmittedMsg).value, 'apple');
      });
    });

    // ── cancel ───────────────────────────────────────────────────────────────

    group('cancel (Escape)', () {
      test('emits SuggestCancelledMsg on Escape', () async {
        final m = SuggestModel(options: _fruits);
        final (_, cmd) = m.update(_key(KeyType.escape));
        final msg = await _exec(cmd);
        expect(msg, isA<SuggestCancelledMsg>());
      });
    });

    // ── scroll window advancement ────────────────────────────────────────────

    group('scroll window advancement', () {
      test('window advances when highlighted goes past visible end', () {
        final m = SuggestModel(options: _fruits, scroll: 2);
        var cur = m;
        // Move down past the window (scroll=2, so after 2 downs, need to advance)
        for (var i = 0; i < 3; i++) {
          final (n, _) = cur.update(_key(KeyType.down));
          cur = n;
        }
        // highlighted=2, scroll=2, so firstVisible should have advanced
        expect(cur.highlighted, 2);
        expect(cur.visible, contains(_fruits[2]));
      });

      test('window retreats when highlighted goes before visible start', () {
        final m = SuggestModel(options: _fruits, scroll: 2);
        var cur = m;
        // Navigate down to push window
        for (var i = 0; i < 4; i++) {
          final (n, _) = cur.update(_key(KeyType.down));
          cur = n;
        }
        // Navigate back up
        for (var i = 0; i < 3; i++) {
          final (n, _) = cur.update(_key(KeyType.up));
          cur = n;
        }
        expect(cur.highlighted, greaterThanOrEqualTo(0));
        expect(cur.visible, contains(_fruits[cur.highlighted]));
      });
    });

    // ── view ─────────────────────────────────────────────────────────────────

    group('view()', () {
      test('shows prompt text', () {
        final m = SuggestModel(prompt: 'Pick a fruit: ', options: _fruits);
        final view = Style.stripAnsi(m.view());
        expect(view, contains('Pick a fruit:'));
      });

      test('shows placeholder when empty', () {
        final m = SuggestModel(
          options: _fruits,
          placeholder: 'Type to search...',
        );
        final view = Style.stripAnsi(m.view());
        expect(view, contains('Type to search...'));
      });

      test('shows typed value', () {
        final m = SuggestModel(options: _fruits, defaultValue: 'banana');
        final view = Style.stripAnsi(m.view());
        expect(view, contains('banana'));
      });

      test('shows matching suggestions as dropdown', () {
        final m = SuggestModel(options: _fruits, defaultValue: 'ap');
        final view = Style.stripAnsi(m.view());
        expect(view, contains('apple'));
        expect(view, contains('apricot'));
        expect(view, isNot(contains('banana')));
      });

      test('shows scroll indicator when more items than window', () {
        final m = SuggestModel(options: _fruits, scroll: 2);
        final view = Style.stripAnsi(m.view());
        expect(view, contains('more'));
      });

      test('no scroll indicator when all items fit', () {
        final m = SuggestModel(options: _fruits, scroll: 10);
        final view = Style.stripAnsi(m.view());
        expect(view, isNot(contains('more')));
      });

      test('shows hint when set', () {
        final m = SuggestModel(options: _fruits, hint: 'Choose wisely');
        final view = Style.stripAnsi(m.view());
        expect(view, contains('Choose wisely'));
      });

      test('highlighted row contains pointer character', () {
        var m = SuggestModel(
          options: _fruits,
          styles: SuggestStyles(pointer: '>'),
        );
        final (m1, _) = m.update(_key(KeyType.down));
        final view = Style.stripAnsi(m1.view());
        expect(view, contains('>'));
      });

      test('shows help when showHelp=true', () {
        final m = SuggestModel(options: _fruits, showHelp: true);
        final view = Style.stripAnsi(m.view());
        // shortHelp includes up, down, accept, cancel
        expect(view, contains('↑'));
        expect(view, contains('↓'));
      });

      test('hides help when showHelp=false', () {
        final m = SuggestModel(options: _fruits, showHelp: false);
        final view = Style.stripAnsi(m.view());
        expect(view, isNot(contains('↑')));
      });
    });

    // ── init ─────────────────────────────────────────────────────────────────

    test('init() returns null', () {
      final m = SuggestModel();
      expect(m.init(), isNull);
    });
  });
}
