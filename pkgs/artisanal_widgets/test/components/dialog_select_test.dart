import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('DialogSelectItem', () {
    test('searches additional terms exactly and fuzzily', () {
      const item = DialogSelectItem<String>(
        label: 'Token usage',
        value: 'usage',
        searchTerms: ['throughput'],
      );

      expect(item.matchesQuery('throughput'), isTrue);
      expect(item.searchScore('througput'), greaterThanOrEqualTo(0.7));
      expect(FuzzySearch.score('---', 'searchable text'), 0);
    });
  });

  test('fuzzy filtering ranks results and selects the closest match', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    String? selected;

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: DialogSelect<String>(
          filterThreshold: 0.7,
          items: const [
            DialogSelectItem(label: 'Color mood', value: 'near'),
            DialogSelectItem(label: 'Animations', value: 'unmatched'),
            DialogSelectItem(label: 'Color mode', value: 'exact'),
          ],
          onSelect: (item) => selected = item.value,
        ),
      ),
    );

    tester.typeText('colr mode');
    tester.sendSpecialKey(KeyType.enter);

    expect(selected, 'exact');
  });

  test('search changes report the newly highlighted fuzzy match', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    final highlighted = <String>[];

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: DialogSelect<String>(
          filterThreshold: 0.7,
          items: const [
            DialogSelectItem(label: 'Color mood', value: 'near'),
            DialogSelectItem(label: 'Animations', value: 'unmatched'),
            DialogSelectItem(label: 'Color mode', value: 'exact'),
          ],
          onHighlightChanged: (item) => highlighted.add(item.value!),
        ),
      ),
    );

    tester.typeText('colr mode');

    expect(highlighted, isNotEmpty);
    expect(highlighted.last, 'exact');
  });

  test(
    'search changes clear the highlight when there are no matches',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final highlighted = <String>[];
      var cleared = 0;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: DialogSelect<String>(
            filterThreshold: 0.7,
            items: const [DialogSelectItem(label: 'Color mode', value: 'mode')],
            onHighlightChanged: (item) => highlighted.add(item.value!),
            onHighlightCleared: () => cleared++,
          ),
        ),
      );

      tester.typeText('zzzz');

      expect(highlighted, isEmpty);
      expect(cleared, 1);
    },
  );

  test('DialogSelect.show forwards its fuzzy threshold', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    String? selected;
    BuildContext? homeContext;

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: Navigator(
          home: Builder(
            builder: (context) {
              homeContext = context;
              return Text('Home');
            },
          ),
        ),
      ),
    );

    DialogSelect.show<String>(
      homeContext!,
      filterThreshold: 0.7,
      items: const [
        DialogSelectItem(label: 'Color mood', value: 'near'),
        DialogSelectItem(label: 'Color mode', value: 'exact'),
      ],
      onSelect: (item) => selected = item.value,
    );
    tester.pump();
    tester.typeText('colr mode');
    tester.sendSpecialKey(KeyType.enter);
    tester.pump();

    expect(selected, 'exact');
  });
}
