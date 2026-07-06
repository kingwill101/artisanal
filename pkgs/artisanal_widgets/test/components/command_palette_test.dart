import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('CommandPaletteItem', () {
    test('stores required label', () {
      final item = CommandPaletteItem(label: 'Open File');
      expect(item.label, equals('Open File'));
    });

    test('stores all optional properties', () {
      final item = CommandPaletteItem(
        label: 'Save',
        description: 'Save the current file',
        shortcut: 'ctrl+s',
        group: 'File',
        enabled: false,
      );
      expect(item.description, equals('Save the current file'));
      expect(item.shortcut, equals('ctrl+s'));
      expect(item.group, equals('File'));
      expect(item.enabled, isFalse);
    });

    test('enabled defaults to true', () {
      final item = CommandPaletteItem(label: 'Test');
      expect(item.enabled, isTrue);
    });
  });

  group('CommandPalette', () {
    test('renders child when closed', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            items: [CommandPaletteItem(label: 'Action')],
            child: Text('Background Content'),
          ),
        ),
      );
      expect(tester.find.text('Background Content'), isTrue);
      // Palette items should not be visible when closed
      expect(tester.find.text('Action'), isFalse);
    });

    test('shows items when open', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'Open File'),
              CommandPaletteItem(label: 'Close File'),
            ],
            child: Text('bg'),
          ),
        ),
      );
      expect(tester.find.text('Open File'), isTrue);
      expect(tester.find.text('Close File'), isTrue);
    });

    test('shows title when provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            title: 'Commands',
            items: [CommandPaletteItem(label: 'Test')],
            child: Text('bg'),
          ),
        ),
      );
      expect(tester.find.text('Commands'), isTrue);
    });

    test('shows group section headers', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'Open', group: 'File'),
              CommandPaletteItem(label: 'Save', group: 'File'),
              CommandPaletteItem(label: 'Find', group: 'Edit'),
            ],
            child: Text('bg'),
          ),
        ),
      );
      expect(tester.find.text('File'), isTrue);
      expect(tester.find.text('Edit'), isTrue);
    });

    test('filters out disabled items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'Enabled Action'),
              CommandPaletteItem(label: 'Disabled Action', enabled: false),
            ],
            child: Text('bg'),
          ),
        ),
      );
      expect(tester.find.text('Enabled Action'), isTrue);
      expect(tester.find.text('Disabled Action'), isFalse);
    });

    test('escape dismisses the palette', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var dismissed = false;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [CommandPaletteItem(label: 'Item')],
            onDismiss: () {
              dismissed = true;
              return null;
            },
            child: Text('bg'),
          ),
        ),
      );
      expect(tester.find.text('Item'), isTrue);

      tester.sendSpecialKey(KeyType.escape);
      expect(dismissed, isTrue);
    });

    test('enter selects the current item via onSelect', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      CommandPaletteItem? selectedItem;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'First'),
              CommandPaletteItem(label: 'Second'),
            ],
            onSelect: (item) {
              selectedItem = item;
              return null;
            },
            child: Text('bg'),
          ),
        ),
      );

      // First item is selected by default (index 0)
      tester.sendSpecialKey(KeyType.enter);
      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('First'));
    });

    test('down arrow moves selection to next item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      CommandPaletteItem? selectedItem;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'Alpha'),
              CommandPaletteItem(label: 'Beta'),
              CommandPaletteItem(label: 'Gamma'),
            ],
            onSelect: (item) {
              selectedItem = item;
              return null;
            },
            child: Text('bg'),
          ),
        ),
      );

      // Move down once to select "Beta"
      tester.sendSpecialKey(KeyType.down);
      tester.sendSpecialKey(KeyType.enter);
      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('Beta'));
    });

    test('up arrow moves selection to previous item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      CommandPaletteItem? selectedItem;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'Alpha'),
              CommandPaletteItem(label: 'Beta'),
              CommandPaletteItem(label: 'Gamma'),
            ],
            onSelect: (item) {
              selectedItem = item;
              return null;
            },
            child: Text('bg'),
          ),
        ),
      );

      // Move down twice to Gamma, then up once back to Beta
      tester.sendSpecialKey(KeyType.down);
      tester.sendSpecialKey(KeyType.down);
      tester.sendSpecialKey(KeyType.up);
      tester.sendSpecialKey(KeyType.enter);
      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('Beta'));
    });

    test('down arrow wraps around to first item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      CommandPaletteItem? selectedItem;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'First'),
              CommandPaletteItem(label: 'Last'),
            ],
            onSelect: (item) {
              selectedItem = item;
              return null;
            },
            child: Text('bg'),
          ),
        ),
      );

      // Move down twice past the last item — should wrap to First
      tester.sendSpecialKey(KeyType.down);
      tester.sendSpecialKey(KeyType.down);
      tester.sendSpecialKey(KeyType.enter);
      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('First'));
    });

    test('keyboard navigation scrolls selected item into view', () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 18);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            maxHeight: 8,
            items: [
              for (var i = 0; i < 4; i++)
                CommandPaletteItem(label: 'Repo $i', group: 'Repository'),
              for (var i = 0; i < 4; i++)
                CommandPaletteItem(label: 'Nav $i', group: 'Navigation'),
            ],
            child: Text('bg'),
          ),
        ),
      );

      expect(tester.view, contains('Repo 0'));
      expect(tester.view, isNot(contains('Nav 3')));

      for (var i = 0; i < 7; i++) {
        tester.sendSpecialKey(KeyType.down);
      }

      expect(tester.view, contains('Nav 3'));
      expect(tester.view, isNot(contains('Repo 0')));
    });

    test('up arrow wraps around to last item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      CommandPaletteItem? selectedItem;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'First'),
              CommandPaletteItem(label: 'Last'),
            ],
            onSelect: (item) {
              selectedItem = item;
              return null;
            },
            child: Text('bg'),
          ),
        ),
      );

      // Move up from index 0 — should wrap to Last
      tester.sendSpecialKey(KeyType.up);
      tester.sendSpecialKey(KeyType.enter);
      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('Last'));
    });

    test('hover updates highlighted item without selecting it', () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 18);
      addTearDown(() => tester.dispose());
      CommandPaletteItem? selectedItem;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(label: 'Alpha'),
              CommandPaletteItem(label: 'Beta'),
            ],
            onSelect: (item) {
              selectedItem = item;
              return null;
            },
            child: Text('bg'),
          ),
        ),
      );

      final lines = tester.view.split('\n');
      final betaY = lines.indexWhere((line) => line.contains('Beta'));
      expect(betaY, greaterThanOrEqualTo(0));
      final betaX = lines[betaY].indexOf('Beta');
      expect(betaX, greaterThanOrEqualTo(0));

      tester.mouseMove(betaX, betaY);
      tester.sendSpecialKey(KeyType.enter);

      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('Beta'));
    });

    test('stores widget properties', () {
      final palette = CommandPalette(
        open: true,
        title: 'Test',
        hint: 'Search...',
        width: 50,
        maxHeight: 20,
        items: [CommandPaletteItem(label: 'a')],
        child: Text('bg'),
      );
      expect(palette.open, isTrue);
      expect(palette.title, equals('Test'));
      expect(palette.hint, equals('Search...'));
      expect(palette.width, equals(50));
      expect(palette.maxHeight, equals(20));
      expect(palette.items, hasLength(1));
    });

    test('item onSelect callback fires when selected', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var itemCallbackFired = false;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [
              CommandPaletteItem(
                label: 'Action',
                onSelect: () {
                  itemCallbackFired = true;
                  return null;
                },
              ),
            ],
            child: Text('bg'),
          ),
        ),
      );

      tester.sendSpecialKey(KeyType.enter);
      expect(itemCallbackFired, isTrue);
    });

    test('shows search placeholder text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: CommandPalette(
            open: true,
            items: [CommandPaletteItem(label: 'Item')],
            child: Text('bg'),
          ),
        ),
      );
      // Focused TextField renders a cursor cell at the first character.
      expect(tester.find.text('Search') || tester.find.text('earch'), isTrue);
    });

    test('shortcut property is stored on item', () {
      final item = CommandPaletteItem(label: 'Save', shortcut: 'ctrl+s');
      expect(item.shortcut, equals('ctrl+s'));
    });

    test('open defaults to false', () {
      final palette = CommandPalette(
        items: [CommandPaletteItem(label: 'a')],
        child: Text('bg'),
      );
      expect(palette.open, isFalse);
    });

    test('ranks exact matches above prefix matches', () {
      final matches = CommandPalette.matchItems([
        CommandPaletteItem(label: 'Open Folder'),
        CommandPaletteItem(label: 'Open'),
        CommandPaletteItem(label: 'Close'),
      ], 'open');

      expect(matches, hasLength(2));
      expect(matches.first.item.label, equals('Open'));
      expect(matches[1].item.label, equals('Open Folder'));
      expect(matches.first.evidence, containsPair('label:exact', 10000));
    });

    test('sorting is deterministic for equal-score matches', () {
      final matches = CommandPalette.matchItems([
        CommandPaletteItem(label: 'Alpine'),
        CommandPaletteItem(label: 'Alpha'),
        CommandPaletteItem(label: 'Almanac'),
      ], 'al');

      expect(matches, hasLength(3));
      final labels = matches.map((match) => match.item.label).toList();
      expect(labels, equals(['Almanac', 'Alpha', 'Alpine']));
      expect(matches.first.score, equals(matches[1].score));
    });

    test(
      'populates evidence ledger on match and preserves deterministic ordering',
      () {
        final typoMatches = CommandPalette.matchItems([
          CommandPaletteItem(label: 'Save'),
          CommandPaletteItem(label: 'Close'),
        ], 'svae');

        expect(typoMatches, hasLength(1));
        expect(typoMatches.first.item.label, equals('Save'));
        expect(typoMatches.first.evidence.keys, contains('label:typo'));
      },
    );
  });
}
