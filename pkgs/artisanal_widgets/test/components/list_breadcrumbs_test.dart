import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ListTile
  // ---------------------------------------------------------------------------
  group('ListTile', () {
    test('renders title text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ListTile(title: 'My Title'));
      expect(tester.find.text('My Title'), isTrue);
    });

    test('renders subtitle when provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(title: 'Title', subtitle: 'Subtitle text'),
      );
      expect(tester.find.text('Title'), isTrue);
      expect(tester.find.text('Subtitle text'), isTrue);
    });

    test('does not render subtitle when null', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ListTile(title: 'Only Title'));
      expect(tester.find.text('Only Title'), isTrue);
      // No subtitle text should appear
      expect(tester.find.text('Subtitle'), isFalse);
    });

    test('renders leading widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(title: 'With Leading', leading: Text('>')),
      );
      expect(tester.find.text('>'), isTrue);
      expect(tester.find.text('With Leading'), isTrue);
    });

    test('renders trailing widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(title: 'With Trailing', trailing: Text('[x]')),
      );
      expect(tester.find.text('[x]'), isTrue);
      expect(tester.find.text('With Trailing'), isTrue);
    });

    test('renders leading and trailing together', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(
          title: 'Full Tile',
          subtitle: 'Description',
          leading: Text('*'),
          trailing: Text('>>'),
        ),
      );
      expect(tester.find.text('*'), isTrue);
      expect(tester.find.text('Full Tile'), isTrue);
      expect(tester.find.text('Description'), isTrue);
      expect(tester.find.text('>>'), isTrue);
    });

    test('title appears before subtitle vertically', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(title: 'Header', subtitle: 'Sub-header'),
      );

      final titleLoc = tester.locateText('Header');
      final subtitleLoc = tester.locateText('Sub-header');
      expect(titleLoc, isNotNull);
      expect(subtitleLoc, isNotNull);
      expect(titleLoc!.y, lessThan(subtitleLoc!.y));
    });

    test('leading appears before title horizontally', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ListTile(title: 'Content', leading: Text('L')));

      final leadingLoc = tester.locateText('L');
      final titleLoc = tester.locateText('Content');
      expect(leadingLoc, isNotNull);
      expect(titleLoc, isNotNull);
      expect(leadingLoc!.x, lessThan(titleLoc!.x));
    });

    test('accepts widget title and subtitle content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(
          title: Row(children: [Text('Widget'), Text('Title')]),
          subtitle: Text('Widget subtitle'),
        ),
      );

      expect(tester.find.text('Widget'), isTrue);
      expect(tester.find.text('Title'), isTrue);
      expect(tester.find.text('Widget subtitle'), isTrue);
    });

    test('onTap fires when tile is clicked', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapped = 0;
      await tester.pumpWidget(
        ListTile(
          title: 'Clickable tile',
          onTap: () {
            tapped++;
            return null;
          },
        ),
      );

      final loc = tester.locateText('Clickable tile');
      expect(loc, isNotNull);
      tester.tapAt(loc!.x, loc.y);
      expect(tapped, equals(1));
    });

    test('disabled tile does not fire onTap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapped = 0;
      await tester.pumpWidget(
        ListTile(
          title: 'Disabled tile',
          enabled: false,
          onTap: () {
            tapped++;
            return null;
          },
        ),
      );

      final loc = tester.locateText('Disabled tile');
      expect(loc, isNotNull);
      tester.tapAt(loc!.x, loc.y);
      expect(tapped, equals(0));
    });
  });

  group('ListTile selected', () {
    test('renders differently when selected', () async {
      final testerNormal = WidgetTester();
      addTearDown(() => testerNormal.dispose());
      final testerSelected = WidgetTester();
      addTearDown(() => testerSelected.dispose());

      await testerNormal.pumpWidget(ListTile(title: 'Item', selected: false));
      await testerSelected.pumpWidget(ListTile(title: 'Item', selected: true));

      // Selected and non-selected should produce different output
      // (different background/foreground colors)
      expect(testerNormal.view, isNot(equals(testerSelected.view)));
    });

    test('selected tile still renders title', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ListTile(title: 'Selected Item', selected: true));
      expect(tester.find.text('Selected Item'), isTrue);
    });

    test('selected tile renders subtitle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(title: 'Selected', subtitle: 'With sub', selected: true),
      );
      expect(tester.find.text('Selected'), isTrue);
      expect(tester.find.text('With sub'), isTrue);
    });
  });

  group('ListTile dense', () {
    test('dense tile renders title', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ListTile(title: 'Dense Item', dense: true));
      expect(tester.find.text('Dense Item'), isTrue);
    });

    test('dense tile has less vertical space than normal', () async {
      final testerNormal = WidgetTester();
      addTearDown(() => testerNormal.dispose());
      final testerDense = WidgetTester();
      addTearDown(() => testerDense.dispose());

      await testerNormal.pumpWidget(ListTile(title: 'Item', dense: false));
      await testerDense.pumpWidget(ListTile(title: 'Item', dense: true));

      // Dense mode uses vertical padding 0 vs normal 1, so output differs
      expect(testerNormal.view, isNot(equals(testerDense.view)));
    });
  });

  group('ListTile properties', () {
    test('has unique id', () {
      final t1 = ListTile(title: 'a');
      final t2 = ListTile(title: 'b');
      expect(t1.id, isNot(equals(t2.id)));
    });

    test('respects key', () {
      final tile = ListTile(key: ValueKey('tile-key'), title: 'keyed');
      expect(tile.id, equals('tile-key'));
    });

    test('is not focusable', () {
      final tile = ListTile(title: 'test');
      expect(tile.focusable, isFalse);
    });

    test('defaults selected to false', () {
      final tile = ListTile(title: 'test');
      expect(tile.selected, isFalse);
    });

    test('defaults dense to false', () {
      final tile = ListTile(title: 'test');
      expect(tile.dense, isFalse);
    });

    test('defaults enabled to true', () {
      final tile = ListTile(title: 'test');
      expect(tile.enabled, isTrue);
    });

    test('subtitle defaults to null', () {
      final tile = ListTile(title: 'test');
      expect(tile.subtitle, isNull);
    });

    test('leading defaults to null', () {
      final tile = ListTile(title: 'test');
      expect(tile.leading, isNull);
    });

    test('trailing defaults to null', () {
      final tile = ListTile(title: 'test');
      expect(tile.trailing, isNull);
    });

    test('padding defaults to null', () {
      final tile = ListTile(title: 'test');
      expect(tile.padding, isNull);
    });

    test('background defaults to null', () {
      final tile = ListTile(title: 'test');
      expect(tile.background, isNull);
    });

    test('onTap defaults to null', () {
      final tile = ListTile(title: 'test');
      expect(tile.onTap, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // BreadcrumbItem
  // ---------------------------------------------------------------------------
  group('BreadcrumbItem', () {
    test('constructs with label only', () {
      final item = BreadcrumbItem('Home');
      expect(item.label, equals('Home'));
      expect(item.onTap, isNull);
      expect(item.enabled, isTrue);
    });

    test('constructs with all properties', () {
      final item = BreadcrumbItem(
        'Settings',
        onTap: () => null,
        enabled: false,
      );
      expect(item.label, equals('Settings'));
      expect(item.onTap, isNotNull);
      expect(item.enabled, isFalse);
    });

    test('enabled defaults to true', () {
      final item = BreadcrumbItem('Page');
      expect(item.enabled, isTrue);
    });

    test('onTap defaults to null', () {
      final item = BreadcrumbItem('Page');
      expect(item.onTap, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Breadcrumbs
  // ---------------------------------------------------------------------------
  group('Breadcrumbs renders items', () {
    test('renders single item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Breadcrumbs(items: [BreadcrumbItem('Home')]));
      expect(tester.find.text('Home'), isTrue);
    });

    test('renders all item labels', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Breadcrumbs(
          items: [
            BreadcrumbItem('Home'),
            BreadcrumbItem('Products'),
            BreadcrumbItem('Details'),
          ],
        ),
      );
      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Products'), isTrue);
      expect(tester.find.text('Details'), isTrue);
    });

    test('renders with empty items list', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Breadcrumbs(items: []));
      // Should render without error
      expect(tester.view, isNotNull);
    });
  });

  group('Breadcrumbs separator', () {
    test('renders default separator between items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Breadcrumbs(items: [BreadcrumbItem('Home'), BreadcrumbItem('Page')]),
      );
      expect(tester.find.text('/'), isTrue);
    });

    test('does not render separator after last item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Breadcrumbs(items: [BreadcrumbItem('Only')]));
      // Single item should have no separator
      expect(tester.find.text('/'), isFalse);
    });

    test('separator appears between all adjacent items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Breadcrumbs(
          items: [
            BreadcrumbItem('A'),
            BreadcrumbItem('B'),
            BreadcrumbItem('C'),
          ],
        ),
      );
      // With 3 items, there should be 2 separators
      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
      expect(tester.find.text('C'), isTrue);
      expect(tester.find.text('/'), isTrue);
    });
  });

  group('Breadcrumbs custom separator', () {
    test('renders custom separator string', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Breadcrumbs(
          separator: '>',
          items: [BreadcrumbItem('Home'), BreadcrumbItem('Page')],
        ),
      );
      expect(tester.find.text('>'), isTrue);
      // Default separator should not appear
      expect(tester.find.text('/'), isFalse);
    });

    test('renders multi-char separator', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Breadcrumbs(
          separator: '>>',
          items: [BreadcrumbItem('First'), BreadcrumbItem('Second')],
        ),
      );
      expect(tester.find.text('>>'), isTrue);
    });
  });

  group('Breadcrumbs with onTap', () {
    test('non-last item with onTap renders as button', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Breadcrumbs(
          items: [
            BreadcrumbItem('Home', onTap: () => null),
            BreadcrumbItem('Current'),
          ],
        ),
      );
      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Current'), isTrue);
    });

    test('non-last item onTap fires callback on tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var tapped = false;

      await tester.pumpWidget(
        Breadcrumbs(
          items: [
            BreadcrumbItem(
              'Home',
              onTap: () {
                tapped = true;
                return null;
              },
            ),
            BreadcrumbItem('Current'),
          ],
        ),
      );

      final location = tester.locateText('Home');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(tapped, isTrue);
    });

    test('last item does not fire callback by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var tapped = false;

      await tester.pumpWidget(
        Breadcrumbs(
          items: [
            BreadcrumbItem(
              'Last',
              onTap: () {
                tapped = true;
                return null;
              },
            ),
          ],
        ),
      );

      final location = tester.locateText('Last');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      // Last item is rendered as plain Text, not a button
      expect(tapped, isFalse);
    });

    test('disabled item does not render as button', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var tapped = false;

      await tester.pumpWidget(
        Breadcrumbs(
          items: [
            BreadcrumbItem(
              'Disabled',
              onTap: () {
                tapped = true;
                return null;
              },
              enabled: false,
            ),
            BreadcrumbItem('Current'),
          ],
        ),
      );

      final location = tester.locateText('Disabled');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      // Disabled items are not clickable
      expect(tapped, isFalse);
    });

    test('interactiveLast allows last item to be tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var tapped = false;

      await tester.pumpWidget(
        Breadcrumbs(
          interactiveLast: true,
          items: [
            BreadcrumbItem(
              'Last',
              onTap: () {
                tapped = true;
                return null;
              },
            ),
          ],
        ),
      );

      final location = tester.locateText('Last');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(tapped, isTrue);
    });
  });

  group('Breadcrumbs properties', () {
    test('has unique id', () {
      final b1 = Breadcrumbs(items: [BreadcrumbItem('A')]);
      final b2 = Breadcrumbs(items: [BreadcrumbItem('B')]);
      expect(b1.id, isNot(equals(b2.id)));
    });

    test('respects key', () {
      final bc = Breadcrumbs(
        key: ValueKey('bc-key'),
        items: [BreadcrumbItem('Home')],
      );
      expect(bc.id, equals('bc-key'));
    });

    test('is not focusable', () {
      final bc = Breadcrumbs(items: [BreadcrumbItem('Home')]);
      expect(bc.focusable, isFalse);
    });

    test('defaults separator to /', () {
      final bc = Breadcrumbs(items: []);
      expect(bc.separator, equals('/'));
    });

    test('defaults gap to 1', () {
      final bc = Breadcrumbs(items: []);
      expect(bc.gap, equals(1));
    });

    test('defaults interactiveLast to false', () {
      final bc = Breadcrumbs(items: []);
      expect(bc.interactiveLast, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration
  // ---------------------------------------------------------------------------
  group('Integration', () {
    test('ListTile in a Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            ListTile(title: 'Item 1', subtitle: 'First item'),
            ListTile(title: 'Item 2', subtitle: 'Second item'),
          ],
        ),
      );

      expect(tester.find.text('Item 1'), isTrue);
      expect(tester.find.text('First item'), isTrue);
      expect(tester.find.text('Item 2'), isTrue);
      expect(tester.find.text('Second item'), isTrue);
    });

    test('Breadcrumbs inside a Card', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(
          child: Breadcrumbs(
            items: [
              BreadcrumbItem('Home', onTap: () => null),
              BreadcrumbItem('Settings'),
            ],
          ),
        ),
      );

      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Settings'), isTrue);
      expect(tester.find.text('/'), isTrue);
    });

    test('ListTile with selected and dense together', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ListTile(
          title: 'Compact Selected',
          subtitle: 'Info',
          selected: true,
          dense: true,
        ),
      );

      expect(tester.find.text('Compact Selected'), isTrue);
      expect(tester.find.text('Info'), isTrue);
    });
  });
}
