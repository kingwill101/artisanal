import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('HelpView', () {
    test('renders compact short help by default', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 8);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: HelpView(keyMap: _DemoKeyMap()),
        ),
      );

      expect(tester.find.text('↑/k'), isTrue);
      expect(tester.find.text('move up'), isTrue);
      expect(tester.find.text('?'), isTrue);
      expect(tester.find.text('toggle help'), isTrue);
      expect(tester.find.text('quit'), isTrue);
      expect(tester.find.text('hidden action'), isFalse);
    });

    test('renders grouped full help when showAll is enabled', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 8);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: HelpView(keyMap: _DemoKeyMap(), showAll: true, columnGap: 6),
        ),
      );

      expect(tester.find.text('↑/k'), isTrue);
      expect(tester.find.text('↓/j'), isTrue);
      expect(tester.find.text('move down'), isTrue);
      expect(tester.find.text('q'), isTrue);
      expect(tester.find.text('hidden action'), isFalse);
    });

    test(
      'renders empty output when no visible bindings are available',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: HelpView(keyMap: _EmptyKeyMap()),
          ),
        );

        expect(tester.view.trim(), isEmpty);
      },
    );

    test('supports style overrides', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 8);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: HelpView(
            keyMap: _DemoKeyMap(),
            keyStyle: Style().bold(),
            descriptionStyle: Style().italic(),
          ),
        ),
      );

      expect(tester.find.text('↑/k'), isTrue);
      expect(tester.find.text('move up'), isTrue);
    });

    test('stacks bindings on narrow widths instead of clipping', () async {
      final tester = WidgetTester(screenWidth: 14, screenHeight: 12);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: HelpView(keyMap: _NarrowKeyMap()),
        ),
      );

      expect(tester.find.text('enter'), isTrue);
      expect(tester.find.text('continue'), isTrue);
      expect(tester.find.text('ctrl+c'), isTrue);
      expect(tester.find.text('quit'), isTrue);
    });
  });
}

class _DemoKeyMap extends KeyMap {
  _DemoKeyMap() {
    final up = KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up');
    final down = KeyBinding.withHelp(['down', 'j'], '↓/j', 'move down');
    final help = KeyBinding.withHelp(['?'], '?', 'toggle help');
    final quit = KeyBinding.withHelp(['q'], 'q', 'quit');
    final hidden = KeyBinding.withHelp(['x'], 'x', 'hidden action')..disable();
    shortHelp = [up, help, hidden, quit];
    fullHelp = [
      [up, down, hidden],
      [help, quit],
    ];
  }
}

class _EmptyKeyMap extends KeyMap {
  _EmptyKeyMap() {
    shortHelp = [];
    fullHelp = [];
  }
}

class _NarrowKeyMap extends KeyMap {
  _NarrowKeyMap() {
    final next = KeyBinding.withHelp(['enter'], 'enter', 'continue');
    final quit = KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'quit');
    shortHelp = [next, quit];
    fullHelp = [
      [next],
      [quit],
    ];
  }
}
