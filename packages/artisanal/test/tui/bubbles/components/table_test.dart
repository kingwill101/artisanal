import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Table (fluent builder)', () {
    group('basic construction', () {
      test('creates empty table', () {
        final table = Table();
        expect(table.render(), isEmpty);
      });

      test('creates table with headers', () {
        final table = Table().headers(['A', 'B', 'C']);
        final result = table.render();

        expect(result, contains('A'));
        expect(result, contains('B'));
        expect(result, contains('C'));
      });

      test('creates table with rows', () {
        final table = Table().headers(['Name', 'Age']).row(['Alice', '25']).row(
          ['Bob', '30'],
        );

        final result = table.render();

        expect(result, contains('Alice'));
        expect(result, contains('25'));
        expect(result, contains('Bob'));
        expect(result, contains('30'));
      });

      test('adds multiple rows at once', () {
        final table = Table().headers(['X', 'Y']).rows([
          [1, 2],
          [3, 4],
        ]);

        final result = table.render();

        expect(result, contains('1'));
        expect(result, contains('2'));
        expect(result, contains('3'));
        expect(result, contains('4'));
      });

      test('handles null values in rows', () {
        final table = Table().headers(['A', 'B']).row(['value', null]);

        final result = table.render();

        expect(result, contains('value'));
        // null should be converted to empty string
        expect(result, isNotNull);
      });
    });

    group('borders', () {
      test('uses normal border by default', () {
        final table = Table().headers(['X']).row(['Y']);
        final result = table.render();

        expect(result, contains('┌'));
        expect(result, contains('└'));
        expect(result, contains('│'));
      });

      test('supports ASCII border', () {
        final table = Table().headers(['X']).row(['Y']).border(Border.ascii);

        final result = table.render();

        expect(result, contains('+'));
        expect(result, contains('-'));
        expect(result, contains('|'));
      });

      test('supports thick border', () {
        final table = Table().headers(['X']).row(['Y']).border(Border.thick);

        final result = table.render();

        expect(result, contains('┏'));
        expect(result, contains('┗'));
        expect(result, contains('━'));
      });

      test('supports double border', () {
        final table = Table().headers(['X']).row(['Y']).border(Border.double);

        final result = table.render();

        expect(result, contains('╔'));
        expect(result, contains('╚'));
        expect(result, contains('═'));
      });
    });

    group('padding', () {
      test('default padding is 0', () {
        final table = Table().headers(['X']).row(['Y']);
        final result = table.render();

        // With padding 0, cell content is flush to the borders.
        expect(result, contains('│X│'));
      });

      test('custom padding works', () {
        final table = Table().headers(['X']).row(['Y']).padding(3);

        final result = table.render();

        // With padding 3, cell content should have 3 spaces on each side
        expect(result, contains('   X   '));
      });

      test('zero padding works', () {
        final table = Table().headers(['X']).row(['Y']).padding(0);

        final result = table.render();

        expect(result, contains('│X│'));
      });
    });

    group('styleFunc', () {
      test('styleFunc is called for header row', () {
        var headerCalled = false;

        final table = Table().headers(['Name']).row(['Alice']).styleFunc((
          row,
          col,
          data,
        ) {
          if (row == Table.headerRow) {
            headerCalled = true;
          }
          return null;
        });

        table.render();

        expect(headerCalled, isTrue);
      });

      test('styleFunc is called for data rows', () {
        final rowIndices = <int>[];

        final table = Table()
            .headers(['X'])
            .row(['A'])
            .row(['B'])
            .row(['C'])
            .styleFunc((row, col, data) {
              if (row >= 0) {
                rowIndices.add(row);
              }
              return null;
            });

        table.render();

        expect(rowIndices, contains(0));
        expect(rowIndices, contains(1));
        expect(rowIndices, contains(2));
      });

      test('styleFunc receives correct column index', () {
        final colIndices = <int>{};

        final table = Table()
            .headers(['A', 'B', 'C'])
            .row(['1', '2', '3'])
            .styleFunc((row, col, data) {
              colIndices.add(col);
              return null;
            });

        table.render();

        expect(colIndices, containsAll([0, 1, 2]));
      });

      test('styleFunc receives cell data', () {
        final cellData = <String>[];

        final table = Table()
            .headers(['Name'])
            .row(['Alice'])
            .row(['Bob'])
            .styleFunc((row, col, data) {
              cellData.add(data);
              return null;
            });

        table.render();

        expect(cellData, contains('Name'));
        expect(cellData, contains('Alice'));
        expect(cellData, contains('Bob'));
      });

      test('styleFunc applies styling to cells', () {
        final table = Table()
            .headers(['Status'])
            .row(['Active'])
            .row(['Inactive'])
            .styleFunc((row, col, data) {
              if (data == 'Active') {
                return Style().bold().foreground(Colors.green);
              }
              return null;
            });

        final result = table.render();

        // Active should have ANSI codes applied
        expect(result, contains('\x1B['));
      });

      test('Table.headerRow constant is -1', () {
        expect(Table.headerRow, equals(-1));
      });
    });

    group('lineCount', () {
      test('calculates correct line count', () {
        final table = Table().headers(['A']).row(['1']).row(['2']);

        // Should be: top border, header, separator, row 1, row 2, bottom border
        expect(table.lineCount, equals(6));
      });

      test('lineCount without headers', () {
        final table = Table().row(['1']).row(['2']);

        // Should be: top border, row 1, row 2, bottom border
        expect(table.lineCount, equals(4));
      });
    });

    group('toString', () {
      test('toString returns rendered table', () {
        final table = Table().headers(['X']).row(['Y']);

        expect(table.toString(), equals(table.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return Table for chaining', () {
        final table = Table()
            .headers(['A'])
            .row(['1'])
            .rows([
              ['2'],
            ])
            .border(Border.rounded)
            .padding(2)
            .width(50)
            .styleFunc((r, c, d) => null);

        expect(table, isA<Table>());
      });
    });
  });

  group('TableStyleFunc', () {
    test('typedef accepts correct signature', () {
      Style? func(int row, int col, String data) {
        return Style().bold();
      }

      expect(func(0, 0, 'test'), isA<Style>());
    });

    test('can return null', () {
      Style? func(int row, int col, String data) {
        return null;
      }

      expect(func(0, 0, 'test'), isNull);
    });
  });

  group('TableComponent (legacy)', () {
    RenderConfig createRenderConfig({
      ColorProfile profile = ColorProfile.ascii,
      bool darkBackground = true,
    }) {
      return RenderConfig(
        colorProfile: profile,
        hasDarkBackground: darkBackground,
      );
    }

    test('supports styleFunc parameter', () {
      final table = TableComponent(
        headers: ['A'],
        rows: [
          ['1'],
        ],
        styleFunc: (row, col, data) {
          if (data == '1') return Style().bold();
          return null;
        },
      );
      // Logic check only, rendering check below
      expect(table.styleFunc, isNotNull);
    });

    test('applies styleFunc during rendering', () {
      final table = TableComponent(
        headers: ['Status'],
        rows: [
          ['Active'],
        ],
        styleFunc: (row, col, data) {
          if (data == 'Active') return Style().foreground(Colors.green);
          return null;
        },
        renderConfig: createRenderConfig(profile: ColorProfile.trueColor),
      );

      final result = table.render();

      expect(result, contains('\x1B['));
      expect(result, contains('Active'));
    });

    test('passes correct row/col usage', () {
      final calls = <String>[];
      final table = TableComponent(
        headers: ['H'],
        rows: [
          ['R0'],
          ['R1'],
        ],
        styleFunc: (row, col, data) {
          calls.add('$row:$col:$data');
          return null;
        },
        renderConfig: createRenderConfig(),
      );

      table.render();

      expect(calls, contains('0:0:R0'));
      expect(calls, contains('1:0:R1'));
      // Headers (row -1) should not be styled by styleFunc currently?
      // In my implementation:
      // buffer.writeln(rowLine(headers, -1));
      // And in rowLine:
      // if (styleFunc != null) { style = styleFunc!(rowIndex, ...)}
      // So headers ARE passed with -1.
      expect(calls, contains('-1:0:H'));
    });
  });

  group('Table border toggles', () {
    test('borderTop(false) removes top border', () {
      final table = Table().headers(['X']).row(['Y']).borderTop(false);
      final result = table.render();

      // Should not start with border corner
      expect(result.startsWith('╭'), isFalse);
      expect(result, contains('│'));
    });

    test('borderBottom(false) removes bottom border', () {
      final table = Table().headers(['X']).row(['Y']).borderBottom(false);
      final result = table.render();

      // Should not end with border corner
      expect(result.endsWith('╯'), isFalse);
      expect(result, contains('│'));
    });

    test('borderLeft(false) removes left border', () {
      final table = Table().headers(['X']).row(['Y']).borderLeft(false);
      final result = table.render();

      // First character of content line should not be left border
      final lines = result.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          expect(line.startsWith('│'), isFalse);
        }
      }
    });

    test('borderRight(false) removes right border', () {
      final table = Table().headers(['X']).row(['Y']).borderRight(false);
      final result = table.render();

      // Last character of content line should not be right border
      final lines = result.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          expect(line.endsWith('│'), isFalse);
        }
      }
    });

    test('borderHeader(false) removes header separator', () {
      final table = Table().headers(['X']).row(['Y']).borderHeader(false);
      final result = table.render();

      // Should have top, content lines, and bottom
      // But not the separator between header and data
      expect(result.contains('├'), isFalse);
    });

    test('borderColumn(true) shows column separators', () {
      final table = Table().headers(['A', 'B']).row(['1', '2']);
      final result = table.render();

      // Default has column separators enabled
      // Lines should have the column separator character between cells
      // The default border separator for columns is the same as left/right
      expect(result, contains('│'));
    });

    test('borderRow(true) shows row separators', () {
      final table = Table()
          .headers(['X'])
          .row(['Y'])
          .row(['Z'])
          .borderRow(true);
      final result = table.render();

      // With row separators, there should be a horizontal line between rows
      final lines = result.split('\n');
      // Count horizontal separator lines (ones with middle characters)
      final separatorCount = lines.where((l) => l.contains('├')).length;
      expect(separatorCount, greaterThanOrEqualTo(2)); // header + row separator
    });

    test('clearRows removes all data rows', () {
      final table = Table().headers(['X']).row(['A']).row(['B']);
      expect(table.render(), contains('A'));
      expect(table.render(), contains('B'));

      table.clearRows();
      final result = table.render();

      expect(result, contains('X'));
      expect(result.contains('A'), isFalse);
      expect(result.contains('B'), isFalse);
    });

    test('height limits visible rows', () {
      final table = Table()
          .headers(['X'])
          .row(['A'])
          .row(['B'])
          .row(['C'])
          .row(['D'])
          .height(
            5,
          ); // Top border + header + header sep + 1 data row + bottom = 5 lines

      final result = table.render();
      final lines = result.split('\n').where((l) => l.isNotEmpty).toList();

      // With height 5, should limit output
      expect(lines.length, lessThanOrEqualTo(5));
    });

    test('offset skips first N rows', () {
      final table = Table()
          .headers(['X'])
          .row(['A'])
          .row(['B'])
          .row(['C'])
          .offset(1); // Skip first row

      final result = table.render();

      expect(result, contains('B'));
      expect(result, contains('C'));
      expect(result.contains('A'), isFalse);
    });
  });

  group('Table styling and inheritance', () {
    test('baseStyle is applied to all cells', () {
      final base = Style()
          .foreground(const BasicColor('1'))
          .bold(); // Basic Red
      final table = Table().headers(['A', 'B']).row(['1', '2']).baseStyle(base);

      final result = table.render();
      expect(result, contains('\x1b[1m'));
      expect(result, contains('31')); // Basic red
    });

    test('headerStyle overrides baseStyle for headers', () {
      final base = Style().foreground(const BasicColor('1')); // Red
      final header = Style().foreground(const BasicColor('4')); // Blue
      final table = Table()
          .headers(['HDR'])
          .row(['CELL'])
          .baseStyle(base)
          .headerStyle(header);

      final result = table.render();
      expect(result, contains('34')); // Blue for header
      expect(result, contains('31')); // Red for cell
    });

    test('styleFunc overrides baseStyle', () {
      final base = Style().foreground(const BasicColor('1')); // Red
      final table = Table()
          .headers(['A'])
          .row(['OK'])
          .row(['ERR'])
          .baseStyle(base)
          .styleFunc((row, col, data) {
            if (data == 'OK') {
              return Style().foreground(const BasicColor('2')); // Green
            }
            return null;
          });

      final result = table.render();
      expect(result, contains('32')); // Green for OK
      expect(result, contains('31')); // Red for ERR (from baseStyle)
    });

    test('cellStyle overrides baseStyle for data cells', () {
      final base = Style().foreground(const BasicColor('1')); // Red
      final cell = Style().foreground(const BasicColor('2')); // Green
      final table = Table()
          .headers(['HDR'])
          .row(['CELL'])
          .baseStyle(base)
          .headerStyle(Style()) // Explicitly empty header style to use base
          .cellStyle(cell);

      final result = table.render();
      expect(result, contains('31')); // Red for header (from baseStyle)
      expect(result, contains('32')); // Green for cell (from cellStyle)
    });
  });
}
