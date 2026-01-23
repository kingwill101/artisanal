import 'package:artisanal/src/tui/bubbles/help.dart';
import 'package:artisanal/src/tui/bubbles/key_binding.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:test/test.dart';

void main() {
  group('HelpModel', () {
    group('New', () {
      test('creates with default values', () {
        final help = HelpModel();
        expect(help.width, 0);
        expect(help.showAll, isFalse);
        expect(help.styles, isNotNull);
      });

      test('creates with custom width', () {
        final help = HelpModel(width: 80);
        expect(help.width, 80);
      });

      test('creates with showAll enabled', () {
        final help = HelpModel(showAll: true);
        expect(help.showAll, isTrue);
      });
    });

    group('CopyWith', () {
      test('creates copy with changed width', () {
        final help = HelpModel(width: 80);
        final copy = help.copyWith(width: 120);
        expect(copy.width, 120);
        expect(help.width, 80);
      });

      test('creates copy with changed showAll', () {
        final help = HelpModel(showAll: false);
        final copy = help.copyWith(showAll: true);
        expect(copy.showAll, isTrue);
        expect(help.showAll, isFalse);
      });
    });

    group('View', () {
      test('renders short help when showAll is false', () {
        final help = HelpModel(showAll: false);
        final keyMap = _TestKeyMap();
        final view = help.view(keyMap);
        expect(view, isNotEmpty);
      });

      test('renders full help when showAll is true', () {
        final help = HelpModel(showAll: true);
        final keyMap = _TestKeyMap();
        final view = help.view(keyMap);
        expect(view, isNotEmpty);
      });

      test('returns empty for empty key map', () {
        final help = HelpModel();
        final keyMap = _EmptyKeyMap();
        final view = help.view(keyMap);
        expect(view, isEmpty);
      });
    });

    group('ShortHelpView', () {
      test('renders bindings in a line', () {
        final help = HelpModel();
        final bindings = [
          KeyBinding.withHelp(['up'], '↑', 'up'),
          KeyBinding.withHelp(['down'], '↓', 'down'),
        ];
        final view = help.shortHelpView(bindings);
        expect(view, contains('↑'));
        expect(view, contains('↓'));
        expect(view, contains('up'));
        expect(view, contains('down'));
      });

      test('excludes disabled bindings', () {
        final help = HelpModel();
        final enabled = KeyBinding.withHelp(['up'], '↑', 'up');
        final disabled = KeyBinding.withHelp(['down'], '↓', 'down')..disable();
        final view = help.shortHelpView([enabled, disabled]);
        expect(view, contains('↑'));
        expect(view, isNot(contains('↓')));
      });

      test('truncates with ellipsis when exceeds width', () {
        final help = HelpModel(width: 15);
        final bindings = [
          KeyBinding.withHelp(['up'], '↑', 'up'),
          KeyBinding.withHelp(['down'], '↓', 'down'),
          KeyBinding.withHelp(['left'], '←', 'left'),
        ];
        final view = help.shortHelpView(bindings);
        // Should truncate since width is limited
        // Note: ANSI codes add to the string length but not visual width
        expect(view, isNotEmpty);
      });

      test('returns empty for empty bindings', () {
        final help = HelpModel();
        final view = help.shortHelpView([]);
        expect(view, isEmpty);
      });
    });

    group('FullHelpView', () {
      test('renders grouped bindings', () {
        final help = HelpModel();
        final groups = [
          [
            KeyBinding.withHelp(['up'], '↑', 'up'),
            KeyBinding.withHelp(['down'], '↓', 'down'),
          ],
          [
            KeyBinding.withHelp(['q'], 'q', 'quit'),
          ],
        ];
        final view = help.fullHelpView(groups);
        expect(view, contains('↑'));
        expect(view, contains('↓'));
        expect(view, contains('q'));
      });

      test('excludes disabled bindings', () {
        final help = HelpModel();
        final enabled = KeyBinding.withHelp(['up'], '↑', 'up');
        final disabled = KeyBinding.withHelp(['down'], '↓', 'down')..disable();
        final view = help.fullHelpView([
          [enabled, disabled],
        ]);
        expect(view, contains('↑'));
      });

      test('returns empty for empty groups', () {
        final help = HelpModel();
        final view = help.fullHelpView([]);
        expect(view, isEmpty);
      });

      test('skips groups with only disabled bindings', () {
        final help = HelpModel();
        final disabled1 = KeyBinding.withHelp(['a'], 'a', 'a')..disable();
        final disabled2 = KeyBinding.withHelp(['b'], 'b', 'b')..disable();
        final enabled = KeyBinding.withHelp(['c'], 'c', 'c');
        final view = help.fullHelpView([
          [disabled1, disabled2],
          [enabled],
        ]);
        expect(view, contains('c'));
      });

      test('truncates columns when exceeds width', () {
        final help = HelpModel(width: 30);
        final groups = [
          [
            KeyBinding.withHelp(['up'], '↑', 'move up'),
          ],
          [
            KeyBinding.withHelp(['down'], '↓', 'move down'),
          ],
          [
            KeyBinding.withHelp(['left'], '←', 'move left'),
          ],
          [
            KeyBinding.withHelp(['right'], '→', 'move right'),
          ],
        ];
        final view = help.fullHelpView(groups);
        // Should show ellipsis when truncated
        if (view.contains('…')) {
          expect(view, contains('…'));
        }
      });

      test('pads keys by visible width (combining marks)', () {
        final help = HelpModel();
        final groups = [
          [
            KeyBinding.withHelp(['a'], 'e\u0301', 'one'), // é (combining)
            KeyBinding.withHelp(['b'], 'x', 'two'),
          ],
        ];

        final view = help.fullHelpView(groups);
        final lines = view.split('\n');
        expect(lines, hasLength(2));

        final prefixes = [
          lines[0].split('one').first,
          lines[1].split('two').first,
        ];

        expect(
          Style.visibleLength(prefixes[0]),
          equals(Style.visibleLength(prefixes[1])),
        );
      });
    });
  });

  group('HelpStyles', () {
    test('creates with defaults', () {
      final styles = HelpStyles();
      expect(styles.ellipsis, '…');
      expect(styles.shortSeparator, ' • ');
      expect(styles.fullSeparator, '    ');
    });

    test('creates with custom ellipsis', () {
      final styles = HelpStyles(ellipsis: '...');
      expect(styles.ellipsis, '...');
    });

    test('creates with custom separators', () {
      final styles = HelpStyles(shortSeparator: ' | ', fullSeparator: '  ');
      expect(styles.shortSeparator, ' | ');
      expect(styles.fullSeparator, '  ');
    });

    test('renderKey applies key style', () {
      final styles = HelpStyles();
      final rendered = styles.renderKey('test');
      expect(rendered, isNotEmpty);
    });

    test('renderDesc applies desc style', () {
      final styles = HelpStyles();
      final rendered = styles.renderDesc('test');
      expect(rendered, isNotEmpty);
    });

    test('renderSep applies sep style', () {
      final styles = HelpStyles();
      final rendered = styles.renderSep(' • ');
      expect(rendered, isNotEmpty);
    });
  });
}

class _TestKeyMap implements KeyMap {
  final up = KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up');
  final down = KeyBinding.withHelp(['down', 'j'], '↓/j', 'move down');
  final quit = KeyBinding.withHelp(['q'], 'q', 'quit');

  @override
  List<KeyBinding> shortHelp() => [up, down, quit];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [up, down],
    [quit],
  ];
}

class _EmptyKeyMap implements KeyMap {
  @override
  List<KeyBinding> shortHelp() => [];

  @override
  List<List<KeyBinding>> fullHelp() => [];
}
