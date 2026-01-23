import 'dart:convert' show utf8;

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Key', () {
    test('creates rune key', () {
      final key = Key(KeyType.runes, runes: [0x61]);
      expect(key.type, KeyType.runes);
      expect(key.runes, [0x61]);
      expect(key.char, 'a');
      expect(key.isRune, isTrue);
    });

    test('creates special key', () {
      const key = Key(KeyType.enter);
      expect(key.type, KeyType.enter);
      expect(key.runes, isEmpty);
      expect(key.isRune, isFalse);
    });

    test('creates key with modifiers', () {
      const key = Key(KeyType.runes, runes: [0x63], ctrl: true);
      expect(key.ctrl, isTrue);
      expect(key.alt, isFalse);
      expect(key.shift, isFalse);
      expect(key.hasModifier, isTrue);
    });

    test('equality works correctly', () {
      const key1 = Key(KeyType.runes, runes: [0x61]);
      const key2 = Key(KeyType.runes, runes: [0x61]);
      const key3 = Key(KeyType.runes, runes: [0x62]);

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
    });

    test('equality considers modifiers', () {
      const key1 = Key(KeyType.runes, runes: [0x63], ctrl: true);
      const key2 = Key(KeyType.runes, runes: [0x63], ctrl: true);
      const key3 = Key(KeyType.runes, runes: [0x63], ctrl: false);

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
    });

    test('toString formats correctly', () {
      const key1 = Key(KeyType.enter);
      expect(key1.toString(), contains('Enter'));

      const key2 = Key(KeyType.runes, runes: [0x63], ctrl: true);
      expect(key2.toString(), contains('Ctrl'));
    });

    test('copyWith creates modified copy', () {
      const original = Key(KeyType.runes, runes: [0x61]);
      final modified = original.copyWith(ctrl: true);

      expect(modified.type, KeyType.runes);
      expect(modified.runes, [0x61]);
      expect(modified.ctrl, isTrue);
      expect(original.ctrl, isFalse);
    });
  });

  group('Keys constants', () {
    test('provides special key constants', () {
      expect(Keys.enter.type, KeyType.enter);
      expect(Keys.tab.type, KeyType.tab);
      expect(Keys.backspace.type, KeyType.backspace);
      expect(Keys.escape.type, KeyType.escape);
      expect(Keys.space.type, KeyType.space);
    });

    test('provides arrow key constants', () {
      expect(Keys.up.type, KeyType.up);
      expect(Keys.down.type, KeyType.down);
      expect(Keys.left.type, KeyType.left);
      expect(Keys.right.type, KeyType.right);
    });

    test('provides control key constants', () {
      expect(Keys.ctrlC.ctrl, isTrue);
      expect(Keys.ctrlC.runes, [0x63]);

      expect(Keys.ctrlA.ctrl, isTrue);
      expect(Keys.ctrlA.runes, [0x61]);
    });

    test('char helper creates character key', () {
      final key = Keys.char('x');
      expect(key.type, KeyType.runes);
      expect(key.char, 'x');
    });

    test('ctrl helper creates control combination', () {
      final key = Keys.ctrl('s');
      expect(key.ctrl, isTrue);
      expect(key.runes, [0x73]);
    });

    test('alt helper creates alt combination', () {
      final key = Keys.alt('x');
      expect(key.alt, isTrue);
    });
  });

  group('KeyParser', () {
    late KeyParser parser;

    setUp(() {
      parser = KeyParser();
    });

    tearDown(() {
      parser.clear();
    });

    test('parses regular ASCII characters', () {
      final keys = parser.parse([0x61]); // 'a'
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].char, 'a');
    });

    test('parses multiple characters', () {
      final keys = parser.parse([0x61, 0x62, 0x63]); // 'abc'
      expect(keys, hasLength(3));
      expect(keys[0].char, 'a');
      expect(keys[1].char, 'b');
      expect(keys[2].char, 'c');
    });

    test('parses Enter key (LF)', () {
      final keys = parser.parse([0x0a]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.enter);
    });

    test('parses Enter key (CR)', () {
      final keys = parser.parse([0x0d]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.enter);
    });

    test('parses Tab key', () {
      final keys = parser.parse([0x09]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.tab);
    });

    test('parses Backspace key (DEL)', () {
      final keys = parser.parse([0x7f]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.backspace);
    });

    test('parses Escape key', () {
      final keys = parser.parse([0x1b]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.escape);
    });

    test('parses Ctrl+C', () {
      final keys = parser.parse([0x03]); // Ctrl+C = 0x03
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].ctrl, isTrue);
      expect(keys[0].runes, [0x63]); // 'c'
    });

    test('parses Ctrl+A', () {
      final keys = parser.parse([0x01]);
      expect(keys, hasLength(1));
      expect(keys[0].ctrl, isTrue);
      expect(keys[0].runes, [0x61]); // 'a'
    });

    test('parses arrow up', () {
      final keys = parser.parse([0x1b, 0x5b, 0x41]); // ESC [ A
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.up);
    });

    test('parses arrow down', () {
      final keys = parser.parse([0x1b, 0x5b, 0x42]); // ESC [ B
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.down);
    });

    test('parses arrow right', () {
      final keys = parser.parse([0x1b, 0x5b, 0x43]); // ESC [ C
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.right);
    });

    test('parses arrow left', () {
      final keys = parser.parse([0x1b, 0x5b, 0x44]); // ESC [ D
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.left);
    });

    test('parses Home key', () {
      final keys = parser.parse([0x1b, 0x5b, 0x48]); // ESC [ H
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.home);
    });

    test('parses End key', () {
      final keys = parser.parse([0x1b, 0x5b, 0x46]); // ESC [ F
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.end);
    });

    test('parses Delete key', () {
      final keys = parser.parse([0x1b, 0x5b, 0x33, 0x7e]); // ESC [ 3 ~
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.delete);
    });

    test('parses Insert key', () {
      final keys = parser.parse([0x1b, 0x5b, 0x32, 0x7e]); // ESC [ 2 ~
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.insert);
    });

    test('parses Page Up', () {
      final keys = parser.parse([0x1b, 0x5b, 0x35, 0x7e]); // ESC [ 5 ~
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.pageUp);
    });

    test('parses Page Down', () {
      final keys = parser.parse([0x1b, 0x5b, 0x36, 0x7e]); // ESC [ 6 ~
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.pageDown);
    });

    test('parses Shift+Tab', () {
      final keys = parser.parse([0x1b, 0x5b, 0x5a]); // ESC [ Z
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.tab);
      expect(keys[0].shift, isTrue);
    });

    test('parses F1 via SS3', () {
      final keys = parser.parse([0x1b, 0x4f, 0x50]); // ESC O P
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.f1);
    });

    test('parses F2 via SS3', () {
      final keys = parser.parse([0x1b, 0x4f, 0x51]); // ESC O Q
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.f2);
    });

    test('parses F5 via CSI', () {
      final keys = parser.parse([0x1b, 0x5b, 0x31, 0x35, 0x7e]); // ESC [ 1 5 ~
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.f5);
    });

    test('parses Alt+letter', () {
      final keys = parser.parse([0x1b, 0x78]); // ESC x
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].alt, isTrue);
      expect(keys[0].runes, [0x78]);
    });

    test('parses arrow with Shift modifier', () {
      // ESC [ 1 ; 2 A = Shift+Up
      final keys = parser.parse([0x1b, 0x5b, 0x31, 0x3b, 0x32, 0x41]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.up);
      expect(keys[0].shift, isTrue);
    });

    test('parses arrow with Ctrl modifier', () {
      // ESC [ 1 ; 5 A = Ctrl+Up
      final keys = parser.parse([0x1b, 0x5b, 0x31, 0x3b, 0x35, 0x41]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.up);
      expect(keys[0].ctrl, isTrue);
    });

    test('parses arrow with Alt modifier', () {
      // ESC [ 1 ; 3 A = Alt+Up
      final keys = parser.parse([0x1b, 0x5b, 0x31, 0x3b, 0x33, 0x41]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.up);
      expect(keys[0].alt, isTrue);
    });

    test('parses UTF-8 2-byte character', () {
      // 'ñ' = 0xC3 0xB1
      final keys = parser.parse([0xc3, 0xb1]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].char, 'ñ');
    });

    test('parses UTF-8 3-byte character', () {
      // '€' = 0xE2 0x82 0xAC
      final keys = parser.parse([0xe2, 0x82, 0xac]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].char, '€');
    });

    test('parses UTF-8 emoji', () {
      // '😀' = 0xF0 0x9F 0x98 0x80
      final keys = parser.parse([0xf0, 0x9f, 0x98, 0x80]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].char, '😀');
    });

    test('parses UTF-8 grapheme cluster (ZWJ sequence)', () {
      final s = '👨‍👩‍👧‍👦';
      final keys = parser.parse(utf8.encode(s));
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].char, s);
      expect(keys[0].runes.length, greaterThan(1));
    });

    test('parses Alt+UTF-8 grapheme cluster', () {
      final s = '👨‍👩‍👧‍👦';
      final keys = parser.parse([0x1b, ...utf8.encode(s)]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.runes);
      expect(keys[0].alt, isTrue);
      expect(keys[0].char, s);
      expect(keys[0].runes.length, greaterThan(1));
    });

    test('parses space as space key', () {
      final keys = parser.parse([0x20]);
      expect(keys, hasLength(1));
      expect(keys[0].type, KeyType.space);
    });

    test('clear empties buffer', () {
      // Start an incomplete sequence
      parser.parse([0x1b]);
      parser.clear();
      // Now parse a complete character
      final keys = parser.parse([0x61]);
      expect(keys, hasLength(1));
      expect(keys[0].char, 'a');
    });
  });
}
