import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('DataTable', () {
    test('renders column headers', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DataTable(
          columns: ['Name', 'Age', 'City'],
          rows: [
            ['Alice', '30', 'NYC'],
          ],
        ),
      );

      expect(tester.find.text('Name'), isTrue);
      expect(tester.find.text('Age'), isTrue);
      expect(tester.find.text('City'), isTrue);
    });

    test('renders row data', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DataTable(
          columns: ['Name', 'Age'],
          rows: [
            ['Alice', '30'],
            ['Bob', '25'],
          ],
        ),
      );

      expect(tester.find.text('Alice'), isTrue);
      expect(tester.find.text('30'), isTrue);
      expect(tester.find.text('Bob'), isTrue);
      expect(tester.find.text('25'), isTrue);
    });

    test('renders separator between header and data', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DataTable(
          columns: ['X'],
          rows: [
            ['Y'],
          ],
        ),
      );

      // Normal border uses '─' for horizontal separator.
      expect(tester.find.text('─'), isTrue);
    });

    test('renders multiple columns with vertical separators', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DataTable(
          columns: ['A', 'B'],
          rows: [
            ['1', '2'],
          ],
        ),
      );

      // Normal border uses '│' as vertical separator.
      expect(tester.find.text('│'), isTrue);
    });

    test('handles empty rows', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(DataTable(columns: ['Name', 'Age'], rows: []));

      expect(tester.find.text('Name'), isTrue);
      expect(tester.find.text('Age'), isTrue);
    });

    test('handles rows shorter than column count', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DataTable(
          columns: ['A', 'B', 'C'],
          rows: [
            ['x'], // only one value, B and C should be blank
          ],
        ),
      );

      expect(tester.find.text('x'), isTrue);
      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
      expect(tester.find.text('C'), isTrue);
    });

    test('pads cells to column width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DataTable(
          columns: ['Name', 'Age'],
          rows: [
            ['Al', '5'],
            ['Bobby', '25'],
          ],
        ),
      );

      // 'Bobby' is longer than 'Name', so column width should accommodate.
      expect(tester.find.text('Bobby'), isTrue);
      expect(tester.find.text('Al'), isTrue);
    });

    group('border styles', () {
      test('normal uses basic box chars without outer border', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          DataTable(
            columns: ['A'],
            rows: [
              ['B'],
            ],
            borderStyle: DataTableBorderStyle.normal,
          ),
        );

        expect(tester.find.text('─'), isTrue);
        // Normal has no outer border — no corner chars.
        expect(tester.find.text('╭'), isFalse);
        expect(tester.find.text('╰'), isFalse);
      });

      test('rounded uses full outer border with corner chars', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          DataTable(
            columns: ['A'],
            rows: [
              ['B'],
            ],
            borderStyle: DataTableBorderStyle.rounded,
          ),
        );

        // Rounded has outer border with corner chars.
        expect(tester.find.text('╭'), isTrue);
        expect(tester.find.text('╮'), isTrue);
        expect(tester.find.text('╰'), isTrue);
        expect(tester.find.text('╯'), isTrue);
      });

      test('rounded renders vertical edge borders', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          DataTable(
            columns: ['Name'],
            rows: [
              ['Alice'],
            ],
            borderStyle: DataTableBorderStyle.rounded,
          ),
        );

        // Outer borders include │ on the edges.
        expect(tester.find.text('│'), isTrue);
      });

      test('heavy uses heavy box chars', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          DataTable(
            columns: ['A'],
            rows: [
              ['B'],
            ],
            borderStyle: DataTableBorderStyle.heavy,
          ),
        );

        expect(tester.find.text('━'), isTrue);
      });

      test('dashed uses dashed chars', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          DataTable(
            columns: ['A'],
            rows: [
              ['B'],
            ],
            borderStyle: DataTableBorderStyle.dashed,
          ),
        );

        expect(tester.find.text('╌'), isTrue);
      });

      test('ascii uses plain ASCII chars', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          DataTable(
            columns: ['A', 'B'],
            rows: [
              ['1', '2'],
            ],
            borderStyle: DataTableBorderStyle.ascii,
          ),
        );

        expect(tester.find.text('+'), isTrue);
      });

      test('rounded is visually distinct from normal', () async {
        final normalTester = WidgetTester();
        addTearDown(() => normalTester.dispose());
        final roundedTester = WidgetTester();
        addTearDown(() => roundedTester.dispose());

        await normalTester.pumpWidget(
          DataTable(
            columns: ['X'],
            rows: [
              ['Y'],
            ],
            borderStyle: DataTableBorderStyle.normal,
          ),
        );

        await roundedTester.pumpWidget(
          DataTable(
            columns: ['X'],
            rows: [
              ['Y'],
            ],
            borderStyle: DataTableBorderStyle.rounded,
          ),
        );

        // The rounded table has corner chars that normal does not.
        expect(normalTester.find.text('╭'), isFalse);
        expect(roundedTester.find.text('╭'), isTrue);
      });
    });

    test('DataTableBorderStyle enum has 5 values', () {
      expect(DataTableBorderStyle.values, hasLength(5));
      expect(
        DataTableBorderStyle.values,
        contains(DataTableBorderStyle.normal),
      );
      expect(
        DataTableBorderStyle.values,
        contains(DataTableBorderStyle.rounded),
      );
      expect(DataTableBorderStyle.values, contains(DataTableBorderStyle.heavy));
      expect(
        DataTableBorderStyle.values,
        contains(DataTableBorderStyle.dashed),
      );
      expect(DataTableBorderStyle.values, contains(DataTableBorderStyle.ascii));
    });

    test('has unique id', () {
      final t1 = DataTable(columns: ['A'], rows: []);
      final t2 = DataTable(columns: ['A'], rows: []);
      expect(t1.id, isNot(equals(t2.id)));
    });

    test('respects key', () {
      final t = DataTable(key: ValueKey('table-key'), columns: ['A'], rows: []);
      expect(t.id, equals('table-key'));
    });
  });
}
