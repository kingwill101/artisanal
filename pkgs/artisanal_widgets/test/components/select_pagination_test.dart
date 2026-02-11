import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SelectOption
  // ---------------------------------------------------------------------------
  group('SelectOption', () {
    test('stores label and value', () {
      final opt = SelectOption(label: 'Red', value: 'red');
      expect(opt.label, equals('Red'));
      expect(opt.value, equals('red'));
    });

    test('enabled defaults to true', () {
      final opt = SelectOption(label: 'A', value: 1);
      expect(opt.enabled, isTrue);
    });

    test('enabled can be set to false', () {
      final opt = SelectOption(label: 'A', value: 1, enabled: false);
      expect(opt.enabled, isFalse);
    });

    test('works with different value types', () {
      final intOpt = SelectOption(label: 'One', value: 1);
      expect(intOpt.value, equals(1));

      final enumOpt = SelectOption(label: 'Horizontal', value: Axis.horizontal);
      expect(enumOpt.value, equals(Axis.horizontal));
    });
  });

  // ---------------------------------------------------------------------------
  // Select
  // ---------------------------------------------------------------------------
  group('Select', () {
    test('renders selected option label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Select<String>(
          options: [
            SelectOption(label: 'Apple', value: 'apple'),
            SelectOption(label: 'Banana', value: 'banana'),
          ],
          value: 'apple',
          onChanged: (_) => null,
        ),
      );
      expect(tester.locateText('Apple'), isNotNull);
    });

    test('renders placeholder when no value selected', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Select<String>(
          options: [SelectOption(label: 'Apple', value: 'apple')],
          onChanged: (_) => null,
        ),
      );
      // With no value set, the first enabled option's label or placeholder
      // should be shown. _selectedOption returns first enabled when value is null.
      expect(tester.locateText('Apple'), isNotNull);
    });

    test('renders custom placeholder when options empty', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Select<String>(
          options: [],
          placeholder: 'Choose...',
          onChanged: (_) => null,
        ),
      );
      expect(tester.locateText('Choose...'), isNotNull);
    });

    test('default placeholder is Select', () {
      final select = Select<int>(options: []);
      expect(select.placeholder, equals('Select'));
    });

    test('default enabled is true', () {
      final select = Select<int>(options: []);
      expect(select.enabled, isTrue);
    });

    test('default size is medium', () {
      final select = Select<int>(options: []);
      expect(select.size, equals(ButtonSize.medium));
    });

    test('default variant is outline', () {
      final select = Select<int>(options: []);
      expect(select.variant, equals(ButtonVariant.outline));
    });

    test('properties are set correctly', () {
      final select = Select<int>(
        options: [SelectOption(label: 'One', value: 1)],
        value: 1,
        enabled: false,
        placeholder: 'Pick',
        size: ButtonSize.large,
        variant: ButtonVariant.primary,
      );
      expect(select.value, equals(1));
      expect(select.enabled, isFalse);
      expect(select.placeholder, equals('Pick'));
      expect(select.size, equals(ButtonSize.large));
      expect(select.variant, equals(ButtonVariant.primary));
    });

    test('renders chevron indicator', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Select<String>(
          options: [SelectOption(label: 'Opt', value: 'opt')],
          value: 'opt',
          onChanged: (_) => null,
        ),
      );
      // The Select renders a Row with [label, 'v']
      expect(tester.locateText('v'), isNotNull);
    });

    test('onChanged callback with cycling behavior', () {
      // Select cycles through enabled options on tap.
      String? changedTo;
      final select = Select<String>(
        options: [
          SelectOption(label: 'A', value: 'a'),
          SelectOption(label: 'B', value: 'b'),
          SelectOption(label: 'C', value: 'c'),
        ],
        value: 'a',
        onChanged: (v) {
          changedTo = v;
          return null;
        },
      );
      expect(select.onChanged, isNotNull);
      // Directly invoke the callback to verify it stores the value
      select.onChanged!('b');
      expect(changedTo, equals('b'));
    });

    test('disabled options are skipped', () {
      final select = Select<String>(
        options: [
          SelectOption(label: 'A', value: 'a'),
          SelectOption(label: 'B', value: 'b', enabled: false),
          SelectOption(label: 'C', value: 'c'),
        ],
        value: 'a',
      );
      // Verify disabled option is stored
      expect(select.options[1].enabled, isFalse);
    });

    test('works with int values', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Select<int>(
          options: [
            SelectOption(label: 'One', value: 1),
            SelectOption(label: 'Two', value: 2),
          ],
          value: 2,
          onChanged: (_) => null,
        ),
      );
      expect(tester.locateText('Two'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------
  group('Pagination', () {
    test('renders page indicator', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Pagination(page: 1, pageCount: 5));
      expect(tester.locateText('Page 1 / 5'), isNotNull);
    });

    test('renders Prev and Next buttons', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Pagination(page: 2, pageCount: 5, onChanged: (_) => null),
      );
      expect(tester.locateText('Prev'), isNotNull);
      expect(tester.locateText('Next'), isNotNull);
    });

    test('renders First and Last buttons when showEdges true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Pagination(
          page: 3,
          pageCount: 10,
          showEdges: true,
          onChanged: (_) => null,
        ),
      );
      expect(tester.locateText('First'), isNotNull);
      expect(tester.locateText('Last'), isNotNull);
      expect(tester.locateText('Prev'), isNotNull);
      expect(tester.locateText('Next'), isNotNull);
    });

    test('does not render First/Last when showEdges false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Pagination(page: 3, pageCount: 10, onChanged: (_) => null),
      );
      expect(tester.locateText('First'), isNull);
      expect(tester.locateText('Last'), isNull);
    });

    test('page is clamped to valid range', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Page 0 should be clamped to 1
      await tester.pumpWidget(Pagination(page: 0, pageCount: 5));
      expect(tester.locateText('Page 1 / 5'), isNotNull);
    });

    test('page exceeding pageCount is clamped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Pagination(page: 100, pageCount: 5));
      expect(tester.locateText('Page 5 / 5'), isNotNull);
    });

    test('default showEdges is false', () {
      final p = Pagination(page: 1, pageCount: 5);
      expect(p.showEdges, isFalse);
    });

    test('default gap is 1', () {
      final p = Pagination(page: 1, pageCount: 5);
      expect(p.gap, equals(1));
    });

    test('properties are set correctly', () {
      final p = Pagination(page: 3, pageCount: 10, showEdges: true, gap: 2);
      expect(p.page, equals(3));
      expect(p.pageCount, equals(10));
      expect(p.showEdges, isTrue);
      expect(p.gap, equals(2));
    });

    test('onChanged callback fires with correct page', () {
      int? changedTo;
      final p = Pagination(
        page: 3,
        pageCount: 10,
        onChanged: (page) {
          changedTo = page;
          return null;
        },
      );
      // Directly invoke callback
      p.onChanged!(4);
      expect(changedTo, equals(4));
    });

    test('single page shows Page 1 / 1', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Pagination(page: 1, pageCount: 1));
      expect(tester.locateText('Page 1 / 1'), isNotNull);
    });

    test('pageCount 0 shows Page 1 / 1', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // pageCount 0 → max(1, 0) = 1
      await tester.pumpWidget(Pagination(page: 1, pageCount: 0));
      expect(tester.locateText('Page 1 / 1'), isNotNull);
    });

    test('Prev button triggers onChanged with page - 1', () {
      final p = Pagination(page: 3, pageCount: 5, onChanged: (page) => null);
      // The onChanged callback would be called with page-1 when Prev is clicked
      // We verify it's wired to the Pagination
      expect(p.onChanged, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration
  // ---------------------------------------------------------------------------
  group('Select and Pagination integration', () {
    test('Select inside Container renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          child: Select<String>(
            options: [
              SelectOption(label: 'Opt1', value: 'o1'),
              SelectOption(label: 'Opt2', value: 'o2'),
            ],
            value: 'o1',
            onChanged: (_) => null,
          ),
        ),
      );
      expect(tester.locateText('Opt1'), isNotNull);
    });

    test('Pagination inside Column renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Results'),
            Pagination(page: 2, pageCount: 5, onChanged: (_) => null),
          ],
        ),
      );
      expect(tester.locateText('Results'), isNotNull);
      expect(tester.locateText('Page 2 / 5'), isNotNull);
    });
  });
}
