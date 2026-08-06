import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('FrecencyStore', () {
    test('touch increases score and ranks recent higher', () {
      final clock = <DateTime>[
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 10),
        DateTime.utc(2026, 1, 10),
      ];
      var i = 0;
      final store = FrecencyStore(clock: () => clock[i++]);

      store.touch('old');
      store.touch('new');
      store.touch('new');

      expect(store.score('new', now: DateTime.utc(2026, 1, 10)), greaterThan(0));
      final ranked = store.sortByFrecency(['old', 'new'], (s) => s,
          now: DateTime.utc(2026, 1, 10));
      expect(ranked.first, 'new');
    });
  });

  group('PromptHistory', () {
    test('push and browse older/newer', () {
      final h = PromptHistory(maxEntries: 3);
      h.push('one');
      h.push('two');
      h.push('three');

      expect(h.move(-1, ''), 'three');
      expect(h.move(-1, 'three'), 'two');
      expect(h.move(-1, 'two'), 'one');
      expect(h.move(1, 'one'), 'two');
      expect(h.move(1, 'two'), 'three');
      expect(h.move(1, 'three'), ''); // back to draft
    });

    test('ignores duplicate consecutive push', () {
      final h = PromptHistory();
      h.push('same');
      h.push('same');
      expect(h.length, 1);
    });
  });

  group('detectAutocompleteQuery', () {
    test('detects slash and mention', () {
      final slash = detectAutocompleteQuery('/he');
      expect(slash?.trigger, AutocompleteTrigger.slash);
      expect(slash?.query, 'he');

      final mention = detectAutocompleteQuery('see @lib/');
      expect(mention?.trigger, AutocompleteTrigger.mention);
      expect(mention?.query, 'lib/');
    });

    test('null without trigger token', () {
      expect(detectAutocompleteQuery('hello world'), isNull);
    });
  });

  group('filterAutocompleteItems', () {
    const items = [
      AutocompleteItem(id: 'a', label: '/help', description: 'docs'),
      AutocompleteItem(id: 'b', label: '/clear', description: 'reset'),
      AutocompleteItem(id: 'c', label: '/model', description: 'switch'),
    ];

    test('filters by query', () {
      final r = filterAutocompleteItems(items, 'cl');
      expect(r.map((e) => e.id), ['b']);
    });
  });

  group('applyAutocompleteInsertion', () {
    test('replaces trigger token', () {
      final q = detectAutocompleteQuery('run /he')!;
      final next = applyAutocompleteInsertion('run /he', q, '/help');
      expect(next, 'run /help ');
    });
  });

  group('AutocompleteOverlay', () {
    test('renders items and selection', () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 16);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AutocompleteOverlay(
            title: '/',
            query: 'h',
            selectedIndex: 0,
            items: const [
              AutocompleteItem(id: 'a', label: '/help', description: 'docs'),
              AutocompleteItem(id: 'b', label: '/clear'),
            ],
          ),
        ),
      );

      expect(tester.find.text('/help'), isTrue, reason: tester.view);
      expect(tester.find.text('autocomplete'), isFalse);
      expect(tester.view.contains('/'), isTrue);
    });
  });

  group('PromptStash', () {
    test('push pop and remove', () {
      final s = PromptStash(maxEntries: 2);
      s.push('first');
      s.push('second');
      s.push('third');
      expect(s.length, 2);
      expect(s.newest?.input, 'third');
      expect(s.pop()?.input, 'third');
      expect(s.pop()?.input, 'second');
      expect(s.pop(), isNull);
    });
  });

  group('StatusSection / SubagentRow', () {
    test('StatusSection renders title and children', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 12);
      addTearDown(() => tester.dispose());
      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: StatusSection(
            title: 'MCP',
            count: 2,
            items: [
              ConnectionBadge(
                label: 'filesystem',
                status: ConnectionStatus.connected,
              ),
            ],
          ),
        ),
      );
      expect(tester.find.text('MCP'), isTrue, reason: tester.view);
      expect(tester.find.text('filesystem'), isTrue, reason: tester.view);
    });

    test('SubagentRow renders status', () async {
      final tester = WidgetTester(screenWidth: 50, screenHeight: 10);
      addTearDown(() => tester.dispose());
      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: SubagentRow(
            title: 'Explore layout',
            agentLabel: 'Explore',
            status: SubagentStatus.running,
            index: 1,
            total: 2,
          ),
        ),
      );
      expect(tester.find.text('Explore layout'), isTrue, reason: tester.view);
      expect(tester.find.text('Explore'), isTrue, reason: tester.view);
      expect(tester.find.text('1/2'), isTrue, reason: tester.view);
    });
  });
}
