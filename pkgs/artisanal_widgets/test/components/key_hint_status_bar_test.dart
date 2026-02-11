import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('KeyHint', () {
    test('renders key label and description', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: KeyHint(keyLabel: 'esc', description: 'quit'),
        ),
      );
      expect(tester.find.text('esc'), isTrue);
      expect(tester.find.text('quit'), isTrue);
    });

    test('renders multi-key labels', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: KeyHint(keyLabel: 'ctrl+p', description: 'commands'),
        ),
      );
      expect(tester.find.text('ctrl+p'), isTrue);
      expect(tester.find.text('commands'), isTrue);
    });

    test('has correct default gap', () {
      final hint = KeyHint(keyLabel: 'a', description: 'b');
      expect(hint.gap, equals(1));
    });

    test('stores custom gap', () {
      final hint = KeyHint(keyLabel: 'a', description: 'b', gap: 3);
      expect(hint.gap, equals(3));
    });

    test('stores key property', () {
      final k = ValueKey<String>('my-hint');
      final hint = KeyHint(keyLabel: 'x', description: 'y', key: k);
      expect(hint.key, equals(k));
    });

    test('stores all color overrides', () {
      final hint = KeyHint(
        keyLabel: 'a',
        description: 'b',
        keyBackground: const BasicColor('#ff0000'),
        keyForeground: const BasicColor('#00ff00'),
        descriptionForeground: const BasicColor('#0000ff'),
      );
      expect(hint.keyBackground, isNotNull);
      expect(hint.keyForeground, isNotNull);
      expect(hint.descriptionForeground, isNotNull);
    });
  });

  group('StatusBar', () {
    test('renders items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: StatusBar(
            items: [
              KeyHint(keyLabel: 'esc', description: 'quit'),
              KeyHint(keyLabel: 'ctrl+p', description: 'palette'),
            ],
          ),
        ),
      );
      expect(tester.find.text('esc'), isTrue);
      expect(tester.find.text('quit'), isTrue);
      expect(tester.find.text('ctrl+p'), isTrue);
      expect(tester.find.text('palette'), isTrue);
    });

    test('renders leading widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: StatusBar(
            leading: Text('OpenCode'),
            items: [KeyHint(keyLabel: 'q', description: 'quit')],
          ),
        ),
      );
      expect(tester.find.text('OpenCode'), isTrue);
      expect(tester.find.text('quit'), isTrue);
    });

    test('renders trailing widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: StatusBar(
            items: [KeyHint(keyLabel: 'q', description: 'quit')],
            trailing: Text('v1.0'),
          ),
        ),
      );
      expect(tester.find.text('quit'), isTrue);
      expect(tester.find.text('v1.0'), isTrue);
    });

    test('renders separator between items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: StatusBar(
            separator: '|',
            items: [
              KeyHint(keyLabel: 'a', description: 'alpha'),
              KeyHint(keyLabel: 'b', description: 'beta'),
            ],
          ),
        ),
      );
      expect(tester.find.text('|'), isTrue);
    });

    test('default gap is 2', () {
      final bar = StatusBar();
      expect(bar.gap, equals(2));
    });

    test('default items is empty', () {
      final bar = StatusBar();
      expect(bar.items, isEmpty);
    });

    test('stores custom properties', () {
      final bar = StatusBar(
        gap: 4,
        separator: ' | ',
        background: const BasicColor('#112233'),
        foreground: const BasicColor('#aabbcc'),
        padding: const EdgeInsets.all(2),
      );
      expect(bar.gap, equals(4));
      expect(bar.separator, equals(' | '));
      expect(bar.background, isNotNull);
      expect(bar.foreground, isNotNull);
      expect(bar.padding, isNotNull);
    });
  });
}
