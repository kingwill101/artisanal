import 'package:artisanal/src/tui/bubbles/table.dart';
import 'package:test/test.dart';

void main() {
  group('TableModel', () {
    group('New', () {
      test('creates empty table', () {
        final table = TableModel();
        expect(table.columns, isEmpty);
        expect(table.rows, isEmpty);
        expect(table.cursor, 0);
      });

      test('creates with columns', () {
        final table = TableModel(
          columns: [
            Column(title: 'ID', width: 5),
            Column(title: 'Name', width: 20),
          ],
        );
        expect(table.columns.length, 2);
        expect(table.columns[0].title, 'ID');
        expect(table.columns[1].title, 'Name');
      });

      test('creates with rows', () {
        final table = TableModel(
          columns: [Column(title: 'Name', width: 10)],
          rows: [
            ['Alice'],
            ['Bob'],
            ['Charlie'],
          ],
        );
        expect(table.rows.length, 3);
      });

      test('creates with height', () {
        final table = TableModel(height: 10);
        expect(table.height, lessThanOrEqualTo(10));
      });

      test('starts unfocused', () {
        final table = TableModel();
        expect(table.focused, isFalse);
      });

      test('starts focused when specified', () {
        final table = TableModel(focused: true);
        expect(table.focused, isTrue);
      });
    });

    group('FromValues', () {
      test('parses simple values', () {
        final table = TableModel(
          columns: [
            Column(title: 'A', width: 5),
            Column(title: 'B', width: 5),
          ],
        );
        table.fromValues('a,b\nc,d', ',');
        expect(table.rows.length, 2);
        expect(table.rows[0], ['a', 'b']);
        expect(table.rows[1], ['c', 'd']);
      });

      test('parses with custom separator', () {
        final table = TableModel(columns: [Column(title: 'A', width: 5)]);
        table.fromValues('a|b\nc|d', '|');
        expect(table.rows[0], ['a', 'b']);
      });
    });

    group('Cursor', () {
      test('starts at 0', () {
        final table = TableModel(
          rows: [
            ['1'],
            ['2'],
          ],
        );
        expect(table.cursor, 0);
      });

      test('sets cursor position', () {
        final table = TableModel(
          rows: [
            ['1'],
            ['2'],
            ['3'],
          ],
        );
        table.cursor = 2;
        expect(table.cursor, 2);
      });

      test('clamps cursor to valid range', () {
        final table = TableModel(
          rows: [
            ['1'],
            ['2'],
          ],
        );
        table.cursor = 10;
        expect(table.cursor, 1);
        table.cursor = -5;
        expect(table.cursor, 0);
      });
      test('setCursor parity', () {
        final table = TableModel(
          rows: [
            ['1'],
            ['2'],
          ],
        );
        table.setCursor(1);
        expect(table.getCursor(), 1);
      });
    });

    group('Parity Features', () {
      test('setColumns parity', () {
        final table = TableModel();
        table.setColumns([Column(title: 'A', width: 5)]);
        expect(table.getColumns().length, 1);
      });

      test('setRows parity', () {
        final table = TableModel();
        table.setRows([
          ['1'],
        ]);
        expect(table.getRows().length, 1);
      });

      test('selectedRow parity', () {
        final table = TableModel(
          rows: [
            ['1'],
            ['2'],
          ],
        );
        table.setCursor(1);
        expect(table.selectedRow, ['2']);
      });
    });

    group('MoveUp', () {
      test('moves cursor up', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
            ['4'],
          ],
        );
        table.cursor = 2;
        table.moveUp(1);
        expect(table.cursor, 1);
      });

      test('moves cursor up by multiple rows', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
            ['4'],
          ],
        );
        table.cursor = 3;
        table.moveUp(2);
        expect(table.cursor, 1);
      });

      test('clamps to first row', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
          ],
        );
        table.cursor = 1;
        table.moveUp(5);
        expect(table.cursor, 0);
      });
    });

    group('MoveDown', () {
      test('moves cursor down', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
          ],
        );
        table.moveDown(1);
        expect(table.cursor, 1);
      });

      test('moves cursor down by multiple rows', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
            ['4'],
          ],
        );
        table.moveDown(2);
        expect(table.cursor, 2);
      });

      test('clamps to last row', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
          ],
        );
        table.moveDown(10);
        expect(table.cursor, 2);
      });
    });

    group('GotoTop', () {
      test('moves cursor to first row', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
            ['4'],
          ],
        );
        table.cursor = 3;
        table.gotoTop();
        expect(table.cursor, 0);
      });
    });

    group('GotoBottom', () {
      test('moves cursor to last row', () {
        final table = TableModel(
          focused: true,
          rows: [
            ['1'],
            ['2'],
            ['3'],
            ['4'],
          ],
        );
        table.gotoBottom();
        expect(table.cursor, 3);
      });
    });

    group('SelectedRow', () {
      test('returns selected row', () {
        final table = TableModel(
          columns: [Column(title: 'Name', width: 10)],
          rows: [
            ['Alice'],
            ['Bob'],
          ],
        );
        table.cursor = 1;
        expect(table.selectedRow, ['Bob']);
      });

      test('returns null for empty table', () {
        final table = TableModel();
        expect(table.selectedRow, isNull);
      });
    });

    group('Focus', () {
      test('focus sets focused to true', () {
        final table = TableModel();
        table.focus();
        expect(table.focused, isTrue);
      });

      test('blur sets focused to false', () {
        final table = TableModel(focused: true);
        table.blur();
        expect(table.focused, isFalse);
      });

      test('blur does not stop movement', () {
        final table = TableModel(
          focused: false,
          rows: [
            ['1'],
            ['2'],
            ['3'],
            ['4'],
          ],
        );
        table.blur();
        table.moveDown(2);
        expect(table.cursor, 2);
      });
    });

    group('SetRows', () {
      test('sets rows', () {
        final table = TableModel(columns: [Column(title: 'Name', width: 10)]);
        expect(table.rows.length, 0);

        table.rows = [
          ['Alice'],
          ['Bob'],
        ];
        expect(table.rows.length, 2);
      });

      test('adjusts cursor when rows shrink', () {
        final table = TableModel(
          columns: [Column(title: 'Name', width: 10)],
          rows: [
            ['Alice'],
            ['Bob'],
            ['Charlie'],
          ],
        );
        table.cursor = 2;
        table.rows = [
          ['Alice'],
        ];
        expect(table.cursor, 0);
      });
    });

    group('SetColumns', () {
      test('sets columns', () {
        final table = TableModel();
        expect(table.columns.length, 0);

        table.columns = [
          Column(title: 'Foo', width: 10),
          Column(title: 'Bar', width: 15),
        ];
        expect(table.columns.length, 2);
        expect(table.columns[0].title, 'Foo');
        expect(table.columns[1].title, 'Bar');
      });
    });

    group('View', () {
      test('renders table', () {
        final table = TableModel(
          columns: [Column(title: 'Name', width: 10)],
          rows: [
            ['Alice'],
            ['Bob'],
          ],
          height: 5,
        );
        final view = table.view();
        expect(view, contains('Name'));
      });

      test('renders empty table', () {
        final table = TableModel();
        final view = table.view();
        expect(view, isNotEmpty);
      });
    });

    group('Init', () {
      test('returns null', () {
        final table = TableModel();
        expect(table.init(), isNull);
      });
    });
  });

  group('Column', () {
    test('creates with title and width', () {
      final col = Column(title: 'Test', width: 15);
      expect(col.title, 'Test');
      expect(col.width, 15);
    });
  });

  group('TableStyles', () {
    test('creates with defaults', () {
      final styles = TableStyles.defaults();
      expect(styles.header, isNotNull);
      expect(styles.cell, isNotNull);
      expect(styles.selected, isNotNull);
    });
  });

  group('TableKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = TableKeyMap();
      expect(keyMap.lineUp.keys, isNotEmpty);
      expect(keyMap.lineDown.keys, isNotEmpty);
      expect(keyMap.pageUp.keys, isNotEmpty);
      expect(keyMap.pageDown.keys, isNotEmpty);
    });

    test('shortHelp returns bindings', () {
      final keyMap = TableKeyMap();
      final help = keyMap.shortHelp();
      expect(help.length, greaterThanOrEqualTo(2));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = TableKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
    });
  });
}
