import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('TabItem', () {
    test('constructs with label only', () {
      final item = TabItem('Home');
      expect(item.label, equals('Home'));
      expect(item.icon, isNull);
      expect(item.enabled, isTrue);
    });

    test('constructs with label and icon', () {
      final icon = Text('*');
      final item = TabItem('Settings', icon: icon);
      expect(item.label, equals('Settings'));
      expect(item.icon, equals(icon));
      expect(item.enabled, isTrue);
    });

    test('constructs with enabled set to false', () {
      final item = TabItem('Disabled', enabled: false);
      expect(item.label, equals('Disabled'));
      expect(item.enabled, isFalse);
    });

    test('constructs with all parameters', () {
      final icon = Text('#');
      final item = TabItem('All', icon: icon, enabled: false);
      expect(item.label, equals('All'));
      expect(item.icon, equals(icon));
      expect(item.enabled, isFalse);
    });
  });

  group('Tabs', () {
    test('renders all tab labels', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(
          tabs: [TabItem('Home'), TabItem('Profile'), TabItem('Settings')],
          index: 0,
        ),
      );

      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Profile'), isTrue);
      expect(tester.find.text('Settings'), isTrue);
    });

    test('renders single tab', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Tabs(tabs: [TabItem('Only')], index: 0));

      expect(tester.find.text('Only'), isTrue);
    });

    test(
      'onChanged fires with correct index when tapping non-selected tab',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());
        int? selectedIndex;

        await tester.pumpWidget(
          Tabs(
            tabs: [TabItem('Tab A'), TabItem('Tab B'), TabItem('Tab C')],
            index: 0,
            onChanged: (index) {
              selectedIndex = index;
              return null;
            },
          ),
        );

        // Tap the second tab (Tab B)
        final location = tester.locateText('Tab B');
        expect(location, isNotNull);
        tester.tapAt(location!.x, location.y);
        expect(selectedIndex, equals(1));
      },
    );

    test('onChanged fires with correct index for third tab', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      int? selectedIndex;

      await tester.pumpWidget(
        Tabs(
          tabs: [TabItem('First'), TabItem('Second'), TabItem('Third')],
          index: 0,
          onChanged: (index) {
            selectedIndex = index;
            return null;
          },
        ),
      );

      final location = tester.locateText('Third');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(selectedIndex, equals(2));
    });

    test('onChanged fires when tapping already selected tab', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      int? selectedIndex;

      await tester.pumpWidget(
        Tabs(
          tabs: [TabItem('Tab A'), TabItem('Tab B')],
          index: 0,
          onChanged: (index) {
            selectedIndex = index;
            return null;
          },
        ),
      );

      final location = tester.locateText('Tab A');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(selectedIndex, equals(0));
    });

    test('disabled tab renders but does not fire onChanged', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      int? selectedIndex;

      await tester.pumpWidget(
        Tabs(
          tabs: [TabItem('Enabled'), TabItem('Disabled', enabled: false)],
          index: 0,
          onChanged: (index) {
            selectedIndex = index;
            return null;
          },
        ),
      );

      // The disabled tab label should still render
      expect(tester.find.text('Disabled'), isTrue);

      // Tapping it should not fire onChanged
      final location = tester.locateText('Disabled');
      if (location != null) {
        tester.tapAt(location.x, location.y);
      }
      expect(selectedIndex, isNull);
    });

    test('tabs without onChanged renders but tapping does nothing', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(tabs: [TabItem('Alpha'), TabItem('Beta')], index: 0),
      );

      expect(tester.find.text('Alpha'), isTrue);
      expect(tester.find.text('Beta'), isTrue);

      // Tapping should not throw even without onChanged
      final location = tester.locateText('Beta');
      if (location != null) {
        tester.tapAt(location.x, location.y);
      }
    });

    test('renders with custom gap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(tabs: [TabItem('Left'), TabItem('Right')], index: 0, gap: 3),
      );

      expect(tester.find.text('Left'), isTrue);
      expect(tester.find.text('Right'), isTrue);
    });

    test('renders with zero gap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(tabs: [TabItem('A'), TabItem('B')], index: 0, gap: 0),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('respects key', () {
      final tabs = Tabs(
        key: ValueKey('my-tabs'),
        tabs: [TabItem('X')],
        index: 0,
      );
      expect(tabs.id, equals('my-tabs'));
    });

    test('has unique id without key', () {
      final t1 = Tabs(tabs: [TabItem('A')], index: 0);
      final t2 = Tabs(tabs: [TabItem('B')], index: 0);
      expect(t1.id, isNot(equals(t2.id)));
    });

    test('is not focusable', () {
      final tabs = Tabs(tabs: [TabItem('X')], index: 0);
      expect(tabs.focusable, isFalse);
    });

    test('renders tab with icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(
          tabs: [
            TabItem('Home', icon: Text('H')),
            TabItem('Settings'),
          ],
          index: 0,
        ),
      );

      expect(tester.find.text('H'), isTrue);
      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Settings'), isTrue);
    });

    test('renders multiple tabs with icons', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(
          tabs: [
            TabItem('Files', icon: Text('F')),
            TabItem('Edit', icon: Text('E')),
            TabItem('View', icon: Text('V')),
          ],
          index: 1,
        ),
      );

      expect(tester.find.text('F'), isTrue);
      expect(tester.find.text('Files'), isTrue);
      expect(tester.find.text('E'), isTrue);
      expect(tester.find.text('Edit'), isTrue);
      expect(tester.find.text('V'), isTrue);
      expect(tester.find.text('View'), isTrue);
    });

    test('supports different button sizes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(tabs: [TabItem('Small')], index: 0, size: ButtonSize.small),
      );
      expect(tester.find.text('Small'), isTrue);
    });

    test('supports medium button size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(tabs: [TabItem('Medium')], index: 0, size: ButtonSize.medium),
      );
      expect(tester.find.text('Medium'), isTrue);
    });

    test('supports large button size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tabs(tabs: [TabItem('Large')], index: 0, size: ButtonSize.large),
      );
      expect(tester.find.text('Large'), isTrue);
    });

    test('mix of enabled and disabled tabs', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final tappedIndices = <int>[];

      await tester.pumpWidget(
        Tabs(
          tabs: [
            TabItem('One'),
            TabItem('Two', enabled: false),
            TabItem('Three'),
            TabItem('Four', enabled: false),
          ],
          index: 0,
          onChanged: (index) {
            tappedIndices.add(index);
            return null;
          },
        ),
      );

      // All labels should render
      expect(tester.find.text('One'), isTrue);
      expect(tester.find.text('Two'), isTrue);
      expect(tester.find.text('Three'), isTrue);
      expect(tester.find.text('Four'), isTrue);

      // Tap enabled tab 'Three'
      final loc3 = tester.locateText('Three');
      expect(loc3, isNotNull);
      tester.tapAt(loc3!.x, loc3.y);
      expect(tappedIndices, contains(2));

      // Tap disabled tab 'Two' — should not fire
      final loc2 = tester.locateText('Two');
      if (loc2 != null) {
        tester.tapAt(loc2.x, loc2.y);
      }
      // Only the one tap on 'Three' should have registered
      expect(tappedIndices, equals([2]));
    });
  });
}
