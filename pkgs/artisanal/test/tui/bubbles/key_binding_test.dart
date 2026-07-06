import 'package:artisanal/tui.dart';
import 'package:artisanal/bubbles.dart';
import 'package:test/test.dart';

void main() {
  group('KeyBinding', () {
    group('Creation', () {
      test('creates binding with keys', () {
        final binding = KeyBinding(keys: ['up', 'k']);
        expect(binding.keys, ['up', 'k']);
      });

      test('creates binding with help', () {
        final binding = KeyBinding(
          keys: ['up'],
          help: Help(key: '↑', desc: 'move up'),
        );
        expect(binding.help.key, '↑');
        expect(binding.help.desc, 'move up');
      });

      test('creates binding with factory', () {
        final binding = KeyBinding.withKeys(['a', 'b']);
        expect(binding.keys, ['a', 'b']);
      });

      test('creates binding with help factory', () {
        final binding = KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up');
        expect(binding.keys, ['up', 'k']);
        expect(binding.help.key, '↑/k');
        expect(binding.help.desc, 'move up');
      });
    });

    group('Enabled', () {
      test('returns true when enabled and has keys', () {
        final binding = KeyBinding(keys: ['up']);
        expect(binding.enabled, isTrue);
      });

      test('returns false when disabled', () {
        final binding = KeyBinding(keys: ['up'], disabled: true);
        expect(binding.enabled, isFalse);
      });

      test('returns false when no keys', () {
        final binding = KeyBinding(keys: []);
        expect(binding.enabled, isFalse);
      });

      test('SetEnabled enables binding', () {
        final binding = KeyBinding(keys: ['up'], disabled: true);
        expect(binding.enabled, isFalse);
        binding.enabled = true;
        expect(binding.enabled, isTrue);
      });

      test('SetEnabled disables binding', () {
        final binding = KeyBinding(keys: ['up']);
        expect(binding.enabled, isTrue);
        binding.enabled = false;
        expect(binding.enabled, isFalse);
      });
    });

    group('Disable/Enable', () {
      test('disable disables binding', () {
        final binding = KeyBinding(keys: ['up']);
        binding.disable();
        expect(binding.enabled, isFalse);
      });

      test('enable enables binding', () {
        final binding = KeyBinding(keys: ['up'], disabled: true);
        binding.enable();
        expect(binding.enabled, isTrue);
      });
    });

    group('Unbind', () {
      test('removes keys', () {
        final binding = KeyBinding(keys: ['up', 'k']);
        binding.unbind();
        expect(binding.keys, isEmpty);
      });

      test('removes help', () {
        final binding = KeyBinding(
          keys: ['up'],
          help: Help(key: '↑', desc: 'move up'),
        );
        binding.unbind();
        expect(binding.help.key, '');
        expect(binding.help.desc, '');
      });

      test('disables the binding', () {
        final binding = KeyBinding(keys: ['up']);
        binding.unbind();
        expect(binding.enabled, isFalse);
      });
    });

    group('SetHelp', () {
      test('updates help text', () {
        final binding = KeyBinding(keys: ['up']);
        binding.setHelp('↑', 'move cursor up');
        expect(binding.help.key, '↑');
        expect(binding.help.desc, 'move cursor up');
      });
    });
  });

  group('Help', () {
    test('creates with defaults', () {
      const help = Help();
      expect(help.key, '');
      expect(help.desc, '');
    });

    test('creates with values', () {
      const help = Help(key: '↑', desc: 'up');
      expect(help.key, '↑');
      expect(help.desc, 'up');
    });

    test('hasContent returns false for empty', () {
      const help = Help();
      expect(help.hasContent, isFalse);
    });

    test('hasContent returns true when has key', () {
      const help = Help(key: '↑');
      expect(help.hasContent, isTrue);
    });

    test('hasContent returns true when has desc', () {
      const help = Help(desc: 'up');
      expect(help.hasContent, isTrue);
    });
  });

  group('keyMatches', () {
    test('matches enabled binding with full Key(...) format', () {
      final binding = KeyBinding(keys: ['Key(Up)']);
      final key = Key(KeyType.up);
      expect(keyMatches(key, [binding]), isTrue);
    });

    test('matches enabled binding with key name only', () {
      final binding = KeyBinding(keys: ['up']);
      final key = Key(KeyType.up);
      expect(keyMatches(key, [binding]), isTrue);
    });

    test('matches character key', () {
      final binding = KeyBinding(keys: ['j']);
      final key = Key(KeyType.runes, runes: [0x6a]); // 'j'
      expect(keyMatches(key, [binding]), isTrue);
    });

    test('does not match disabled binding', () {
      final binding = KeyBinding(keys: ['Key(Up)'], disabled: true);
      final key = Key(KeyType.up);
      expect(keyMatches(key, [binding]), isFalse);
    });

    test('matches any of multiple bindings', () {
      final up = KeyBinding(keys: ['Key(Up)']);
      final down = KeyBinding(keys: ['Key(Down)']);
      final key = Key(KeyType.down);
      expect(keyMatches(key, [up, down]), isTrue);
    });

    test('returns false when no match', () {
      final binding = KeyBinding(keys: ['Key(Up)']);
      final key = Key(KeyType.down);
      expect(keyMatches(key, [binding]), isFalse);
    });

    test('returns false for empty bindings list', () {
      final key = Key(KeyType.up);
      expect(keyMatches(key, []), isFalse);
    });

    test('matches space key with literal space character', () {
      final binding = KeyBinding(keys: [' ']);
      final key = Key(KeyType.space);
      expect(keyMatches(key, [binding]), isTrue);
    });

    test('matches space key with "space" string', () {
      final binding = KeyBinding(keys: ['space']);
      final key = Key(KeyType.space);
      expect(keyMatches(key, [binding]), isTrue);
    });

    test('matches tab key with literal tab character', () {
      final binding = KeyBinding(keys: ['\t']);
      final key = Key(KeyType.tab);
      expect(keyMatches(key, [binding]), isTrue);
    });

    test('matches enter key with newline character', () {
      final binding = KeyBinding(keys: ['\n']);
      final key = Key(KeyType.enter);
      expect(keyMatches(key, [binding]), isTrue);
    });

    test('matches enter key with carriage return character', () {
      final binding = KeyBinding(keys: ['\r']);
      final key = Key(KeyType.enter);
      expect(keyMatches(key, [binding]), isTrue);
    });
  });

  group('keyMatchesSingle', () {
    test('matches single binding', () {
      final binding = KeyBinding(keys: ['Key(Enter)']);
      final key = Key(KeyType.enter);
      expect(keyMatchesSingle(key, binding), isTrue);
    });

    test('does not match wrong key', () {
      final binding = KeyBinding(keys: ['Key(Enter)']);
      final key = Key(KeyType.escape);
      expect(keyMatchesSingle(key, binding), isFalse);
    });
  });

  group('KeyMatchExtension', () {
    test('matches with extension method', () {
      final binding = KeyBinding(keys: ['Key(Up)']);
      final key = Key(KeyType.up);
      expect(key.matches([binding]), isTrue);
    });

    test('matchesSingle with extension method', () {
      final binding = KeyBinding(keys: ['Key(Down)']);
      final key = Key(KeyType.down);
      expect(key.matchesSingle(binding), isTrue);
    });
  });

  group('KeyMsgMatchExtension', () {
    test('matches KeyMsg with extension method', () {
      final binding = KeyBinding(keys: ['Key(Up)']);
      final msg = KeyMsg(Key(KeyType.up));
      expect(msg.matches([binding]), isTrue);
    });

    test('matchesSingle KeyMsg with extension method', () {
      final binding = KeyBinding(keys: ['Key(Enter)']);
      final msg = KeyMsg(Key(KeyType.enter));
      expect(msg.matchesSingle(binding), isTrue);
    });
  });

  group('KeyBinding.activate', () {
    test('returns null when no handler', () {
      final binding = KeyBinding(keys: ['up']);
      final msg = KeyMsg(Key(KeyType.up));
      expect(binding.activate(msg), isNull);
    });

    test('returns null when key does not match', () {
      final binding = KeyBinding(keys: ['up'], handler: () => Cmd.quit());
      final msg = KeyMsg(Key(KeyType.down));
      expect(binding.activate(msg), isNull);
    });

    test('returns null when disabled', () {
      final binding = KeyBinding(
        keys: ['up'],
        handler: () => Cmd.quit(),
        disabled: true,
      );
      final msg = KeyMsg(Key(KeyType.up));
      expect(binding.activate(msg), isNull);
    });

    test('calls handler and returns command on match', () {
      var called = false;
      final binding = KeyBinding(keys: ['up'], handler: () {
        called = true;
        return Cmd.quit();
      });
      final msg = KeyMsg(Key(KeyType.up));
      final cmd = binding.activate(msg);
      expect(called, isTrue);
      expect(cmd, isNotNull);
    });
  });

  group('KeyBinding.matches', () {
    test('returns true for matching key', () {
      final binding = KeyBinding(keys: ['up']);
      final msg = KeyMsg(Key(KeyType.up));
      expect(binding.matches(msg), isTrue);
    });

    test('returns false for non-matching key', () {
      final binding = KeyBinding(keys: ['up']);
      final msg = KeyMsg(Key(KeyType.down));
      expect(binding.matches(msg), isFalse);
    });

    test('returns false when disabled', () {
      final binding = KeyBinding(keys: ['up'], disabled: true);
      final msg = KeyMsg(Key(KeyType.up));
      expect(binding.matches(msg), isFalse);
    });
  });

  group('KeyMap', () {
    test('shortHelp defaults to empty', () {
      final keyMap = KeyMap();
      expect(keyMap.shortHelp, isEmpty);
    });

    test('fullHelp defaults to empty', () {
      final keyMap = KeyMap();
      expect(keyMap.fullHelp, isEmpty);
    });

    test('simple factory sets both help lists', () {
      final binding = KeyBinding(keys: ['q']);
      final keyMap = KeyMap.simple([binding]);
      expect(keyMap.shortHelp, [binding]);
      expect(keyMap.fullHelp, [
        [binding],
      ]);
    });

    group('handle', () {
      test('returns null when no bindings', () {
        final keyMap = KeyMap();
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.handle(msg), isNull);
      });

      test('returns null when binding has no handler', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up']),
        ]);
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.handle(msg), isNull);
      });

      test('returns command from matching binding handler', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up'], handler: () => Cmd.quit()),
        ]);
        final msg = KeyMsg(Key(KeyType.up));
        final cmd = keyMap.handle(msg);
        expect(cmd, isNotNull);
      });

      test('returns null for non-matching key', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up'], handler: () => Cmd.quit()),
        ]);
        final msg = KeyMsg(Key(KeyType.down));
        expect(keyMap.handle(msg), isNull);
      });

      test('skips disabled binding', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['q'], handler: () => Cmd.quit(), disabled: true),
        ]);
        final msg = KeyMsg(Key(KeyType.runes, runes: [0x71]));
        expect(keyMap.handle(msg), isNull);
      });
    });

    group('firstMatch', () {
      test('returns matching binding', () {
        final up = KeyBinding(keys: ['up']);
        final keyMap = KeyMap(shortHelp: [up]);
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.firstMatch(msg), same(up));
      });

      test('returns null for no match', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up']),
        ]);
        final msg = KeyMsg(Key(KeyType.enter));
        expect(keyMap.firstMatch(msg), isNull);
      });

      test('skips disabled binding', () {
        final up = KeyBinding(keys: ['up'], disabled: true);
        final keyMap = KeyMap(shortHelp: [up]);
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.firstMatch(msg), isNull);
      });
    });

    group('intercept', () {
      test('returns false when no bindings', () {
        final keyMap = KeyMap();
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.intercept(msg), isFalse);
      });

      test('returns false when binding has no action', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up']),
        ]);
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.intercept(msg), isFalse);
      });

      test('calls action and returns true on match', () {
        var called = false;
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up'], action: () { called = true; }),
        ]);
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.intercept(msg), isTrue);
        expect(called, isTrue);
      });

      test('returns false for non-matching key', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up'], action: () {}),
        ]);
        final msg = KeyMsg(Key(KeyType.down));
        expect(keyMap.intercept(msg), isFalse);
      });

      test('skips disabled binding', () {
        final keyMap = KeyMap(shortHelp: [
          KeyBinding(keys: ['up'], action: () {}, disabled: true),
        ]);
        final msg = KeyMsg(Key(KeyType.up));
        expect(keyMap.intercept(msg), isFalse);
      });
    });

    group('chords', () {
      test('defaults to null', () {
        final keyMap = KeyMap();
        expect(keyMap.chords, isNull);
      });

      test('can be set via constructor', () {
        final prefix = KeyBinding(keys: ['ctrl+x']);
        final sBinding = KeyBinding(keys: ['s']);
        final keyMap = KeyMap(chords: [
          (prefix: prefix, key: sBinding, id: 'save'),
        ]);
        expect(keyMap.chords, hasLength(1));
        expect(keyMap.chords!.first.id, 'save');
        expect(keyMap.chords!.first.prefix, same(prefix));
        expect(keyMap.chords!.first.key, same(sBinding));
      });
    });
  });

  group('CommonKeyBindings', () {
    test('provides up binding', () {
      expect(CommonKeyBindings.up.keys, contains('up'));
      expect(CommonKeyBindings.up.keys, contains('k'));
    });

    test('provides down binding', () {
      expect(CommonKeyBindings.down.keys, contains('down'));
      expect(CommonKeyBindings.down.keys, contains('j'));
    });

    test('provides left binding', () {
      expect(CommonKeyBindings.left.keys, contains('left'));
      expect(CommonKeyBindings.left.keys, contains('h'));
    });

    test('provides right binding', () {
      expect(CommonKeyBindings.right.keys, contains('right'));
      expect(CommonKeyBindings.right.keys, contains('l'));
    });

    test('provides enter binding', () {
      expect(CommonKeyBindings.enter.keys, contains('enter'));
    });

    test('provides escape binding', () {
      expect(CommonKeyBindings.escape.keys, contains('esc'));
    });

    test('provides quit binding', () {
      expect(CommonKeyBindings.quit.keys, contains('q'));
      expect(CommonKeyBindings.quit.keys, contains('ctrl+c'));
    });

    test('provides help binding', () {
      expect(CommonKeyBindings.help.keys, contains('?'));
    });
  });
}
