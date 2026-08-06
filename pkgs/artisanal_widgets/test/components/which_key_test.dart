import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('whichKeyEntriesFromChords', () {
    test('maps bindings to entries', () {
      final bindings = [
        tui.KeyChordBinding(
          id: 'sidebar',
          prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
          key: tui.KeyBinding.withHelp(['b'], 'b', 'toggle sidebar'),
        ),
        tui.KeyChordBinding(
          id: 'models',
          prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
          key: tui.KeyBinding.withHelp(['m'], 'm', 'models'),
        ),
      ];

      final entries = whichKeyEntriesFromChords(bindings);
      expect(entries, hasLength(2));
      expect(entries[0].keyLabel, 'b');
      expect(entries[0].description, 'toggle sidebar');
      expect(entries[0].id, 'sidebar');
      expect(entries[1].keyLabel, 'm');
    });

    test('filters by prefix help key', () {
      final bindings = [
        tui.KeyChordBinding(
          id: 'a',
          prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
          key: tui.KeyBinding.withHelp(['a'], 'a', 'alpha'),
        ),
        tui.KeyChordBinding(
          id: 'b',
          prefix: tui.KeyBinding.withHelp(['ctrl+y'], 'ctrl+y', 'other'),
          key: tui.KeyBinding.withHelp(['b'], 'b', 'beta'),
        ),
      ];
      final entries = whichKeyEntriesFromChords(
        bindings,
        prefixKeyLabel: 'ctrl+x',
      );
      expect(entries, hasLength(1));
      expect(entries.single.id, 'a');
    });
  });

  group('WhichKeyPanel', () {
    test('renders prefix and continuation keys', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: WhichKeyPanel(
            prefixLabel: 'ctrl+x',
            entries: const [
              WhichKeyEntry(keyLabel: 'b', description: 'sidebar', group: 'nav'),
              WhichKeyEntry(keyLabel: 'm', description: 'models', group: 'nav'),
            ],
          ),
        ),
      );

      expect(tester.find.text('which-key'), isTrue);
      expect(tester.find.text('ctrl+x'), isTrue);
      expect(tester.find.text('sidebar'), isTrue);
      expect(tester.find.text('models'), isTrue);
    });

    test('empty entries shows placeholder', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: WhichKeyPanel(entries: const []),
        ),
      );
      expect(tester.find.text('No bindings'), isTrue);
    });
  });
}
