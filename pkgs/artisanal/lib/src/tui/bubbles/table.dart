/// Table component for TUI applications.
///
/// This provides an interactive table with row selection, scrolling,
/// and keyboard navigation.
///
/// Based on the Bubble Tea table component.
library;

import '../../style/style.dart';
import '../../style/color.dart';
import '../../style/properties.dart';
import '../../layout/layout.dart';
import '../tui.dart';
import 'key_binding.dart';
import 'runeutil.dart';
import 'viewport.dart';
import 'help.dart';

/// Table column definition.
class Column {
  /// Creates a column.
  Column({required this.title, required this.width});

  /// Column header title.
  final String title;

  /// Column width in characters.
  final int width;
}

/// Table row (list of cell values).
typedef Row = List<String>;

/// Key map for table navigation.
class TableKeyMap implements KeyMap {
  /// Creates a table key map with default bindings.
  TableKeyMap({
    KeyBinding? lineUp,
    KeyBinding? lineDown,
    KeyBinding? pageUp,
    KeyBinding? pageDown,
    KeyBinding? halfPageUp,
    KeyBinding? halfPageDown,
    KeyBinding? gotoTop,
    KeyBinding? gotoBottom,
  }) : lineUp =
           lineUp ??
           KeyBinding(
             keys: ['up', 'k'],
             help: Help(key: '↑/k', desc: 'up'),
           ),
       lineDown =
           lineDown ??
           KeyBinding(
             keys: ['down', 'j'],
             help: Help(key: '↓/j', desc: 'down'),
           ),
       pageUp =
           pageUp ??
           KeyBinding(
             keys: ['b', 'pgup'],
             help: Help(key: 'b/pgup', desc: 'page up'),
           ),
       pageDown =
           pageDown ??
           KeyBinding(
             keys: ['f', 'pgdown', ' '],
             help: Help(key: 'f/pgdn', desc: 'page down'),
           ),
       halfPageUp =
           halfPageUp ??
           KeyBinding(
             keys: ['u', 'ctrl+u'],
             help: Help(key: 'u', desc: '½ page up'),
           ),
       halfPageDown =
           halfPageDown ??
           KeyBinding(
             keys: ['d', 'ctrl+d'],
             help: Help(key: 'd', desc: '½ page down'),
           ),
       gotoTop =
           gotoTop ??
           KeyBinding(
             keys: ['home', 'g'],
             help: Help(key: 'g/home', desc: 'go to start'),
           ),
       gotoBottom =
           gotoBottom ??
           KeyBinding(
             keys: ['end', 'G'],
             help: Help(key: 'G/end', desc: 'go to end'),
           );

  /// Move selection up one row.
  final KeyBinding lineUp;

  /// Move selection down one row.
  final KeyBinding lineDown;

  /// Move selection up one page.
  final KeyBinding pageUp;

  /// Move selection down one page.
  final KeyBinding pageDown;

  /// Move selection up half a page.
  final KeyBinding halfPageUp;

  /// Move selection down half a page.
  final KeyBinding halfPageDown;

  /// Move selection to first row.
  final KeyBinding gotoTop;

  /// Move selection to last row.
  final KeyBinding gotoBottom;

  @override
  List<KeyBinding> shortHelp() => [lineUp, lineDown];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [lineUp, lineDown],
    [gotoTop, gotoBottom],
    [pageUp, pageDown],
    [halfPageUp, halfPageDown],
  ];
}

/// Styles for table rendering.
class TableStyles {
  /// Creates table styles.
  TableStyles({Style? header, Style? cell, Style? selected})
    : header = header ?? Style().bold().padding(0, 1),
      cell = cell ?? Style().padding(0, 1),
      selected = selected ?? Style().bold().foreground(AnsiColor(212));

  /// Style for header cells.
  final Style header;

  /// Style for regular cells.
  final Style cell;

  /// Style for selected row.
  final Style selected;

  /// Creates default styles.
  factory TableStyles.defaults() => TableStyles();
}

/// Table model for interactive tables.
///
/// Features:
/// - Row selection with keyboard navigation
/// - Page up/down scrolling
/// - Configurable columns and styles
/// - Viewport scrolling for large tables
///
/// Example:
/// ```dart
/// final table = TableModel(
///   columns: [
///     Column(title: 'ID', width: 5),
///     Column(title: 'Name', width: 20),
///     Column(title: 'Status', width: 10),
///   ],
///   rows: [
///     ['1', 'Alice', 'Active'],
///     ['2', 'Bob', 'Inactive'],
///   ],
/// );
/// ```
class TableModel extends ViewComponent {
  /// Creates a new table model.
  TableModel({
    List<Column>? columns,
    List<Row>? rows,
    int? height,
    int? width,
    bool focused = false,
    TableKeyMap? keyMap,
    TableStyles? styles,
    HelpModel? help,
  }) : _columns = columns ?? [],
       _rows = rows ?? [],
       _cursor = 0,
       _focused = focused,
       keyMap = keyMap ?? TableKeyMap(),
       styles = styles ?? TableStyles.defaults(),
       help = help ?? HelpModel() {
    _viewport = ViewportModel(width: 0, height: 20);
    if (height != null) setHeight(height);
    if (width != null) setWidth(width);
    updateViewport();
  }

  /// Key bindings.
  TableKeyMap keyMap;

  /// Help model.
  HelpModel help;

  /// Table styles.
  TableStyles styles;
  void setStyles(TableStyles s) {
    styles = s;
    updateViewport();
  }

  List<Column> _columns;
  List<Row> _rows;
  int _cursor;
  bool _focused;
  late ViewportModel _viewport;
  int _start = 0;
  int _end = 0;

  /// Gets the columns.
  List<Column> get columns => _columns;

  /// Sets the columns.
  set columns(List<Column> value) {
    _columns = value;
    updateViewport();
  }

  /// Sets the columns (parity with bubbles).
  void setColumns(List<Column> c) {
    columns = c;
  }

  /// Gets the rows.
  List<Row> get rows => _rows;

  /// Sets the rows.
  set rows(List<Row> value) {
    _rows = value;
    if (_cursor > _rows.length - 1) {
      _cursor = _rows.length - 1;
    }
    updateViewport();
  }

  /// Sets the rows (parity with bubbles).
  void setRows(List<Row> r) {
    rows = r;
  }

  /// Gets the cursor position.
  int get cursor => _cursor;

  /// Sets the cursor position.
  set cursor(int value) {
    _cursor = value.clamp(0, _rows.length - 1);
    updateViewport();
  }

  /// Sets the cursor position (parity with bubbles).
  void setCursor(int n) {
    cursor = n;
  }

  /// Returns the current cursor position (parity with bubbles).
  int getCursor() => _cursor;

  /// Returns the rows (parity with bubbles).
  List<Row> getRows() => _rows;

  /// Returns the columns (parity with bubbles).
  List<Column> getColumns() => _columns;

  /// Whether the table is focused.
  bool get focused => _focused;

  /// Gets the viewport height.
  int get height => _viewport.height ?? 0;

  /// Gets the viewport width.
  int get width => _viewport.width;

  /// Gets the selected row, or null if none.
  Row? get selectedRow {
    if (_cursor < 0 || _cursor >= _rows.length) {
      return null;
    }
    return _rows[_cursor];
  }

  /// Focus the table.
  void focus() {
    _focused = true;
    updateViewport();
  }

  /// Blur the table.
  void blur() {
    _focused = false;
    updateViewport();
  }

  /// Set the width of the table.
  void setWidth(int w) {
    _viewport = _viewport.copyWith(width: w);
    updateViewport();
  }

  /// Set the height of the table.
  void setHeight(int h) {
    final headerHeight = _headersView().split('\n').length;
    _viewport = _viewport.copyWith(height: h - headerHeight);
    updateViewport();
  }

  /// Move selection up by n rows.
  void moveUp(int n) {
    _cursor = (_cursor - n).clamp(0, _rows.length - 1);
    if (_start == 0) {
      _viewport = _viewport.copyWith(
        yOffset: _viewport.yOffset.clamp(0, _cursor),
      );
    } else if (_start < (_viewport.height ?? 0)) {
      _viewport = _viewport.copyWith(
        yOffset: (_viewport.yOffset + n)
            .clamp(0, _cursor)
            .clamp(0, _viewport.height ?? 0),
      );
    } else if (_viewport.yOffset >= 1) {
      _viewport = _viewport.copyWith(
        yOffset: (_viewport.yOffset + n).clamp(1, _viewport.height ?? 0),
      );
    }
    updateViewport();
  }

  /// Move selection down by n rows.
  void moveDown(int n) {
    _cursor = (_cursor + n).clamp(0, _rows.length - 1);
    updateViewport();

    if (_end == _rows.length && _viewport.yOffset > 0) {
      _viewport = _viewport.copyWith(
        yOffset: (_viewport.yOffset - n).clamp(1, _viewport.height ?? 0),
      );
    } else if (_cursor > (_end - _start) ~/ 2 && _viewport.yOffset > 0) {
      _viewport = _viewport.copyWith(
        yOffset: (_viewport.yOffset - n).clamp(1, _cursor),
      );
    } else if (_viewport.yOffset > 1) {
      // Keep current offset
    } else if (_cursor > (_viewport.yOffset + (_viewport.height ?? 0) - 1)) {
      _viewport = _viewport.copyWith(
        yOffset: (_viewport.yOffset + 1).clamp(0, 1),
      );
    }
  }

  /// Move selection to first row.
  void gotoTop() {
    moveUp(_cursor);
  }

  /// Move selection to last row.
  void gotoBottom() {
    moveDown(_rows.length);
  }

  /// Load rows from a string value.
  ///
  /// Uses newlines to separate rows and [separator] to separate fields.
  void fromValues(String value, String separator) {
    final newRows = <Row>[];
    for (final line in value.split('\n')) {
      final row = line.split(separator);
      newRows.add(row);
    }
    rows = newRows;
  }

  /// Update the viewport content.
  void updateViewport() {
    final renderedRows = <String>[];

    if (_cursor >= 0) {
      _start = (_cursor - (_viewport.height ?? 0)).clamp(0, _cursor);
    } else {
      _start = 0;
    }
    _end = (_cursor + (_viewport.height ?? 0)).clamp(_cursor, _rows.length);

    for (var i = _start; i < _end; i++) {
      renderedRows.add(_renderRow(i));
    }

    _viewport = _viewport.setContent(renderedRows.join('\n'));
  }

  String _headersView() {
    final cells = <String>[];
    for (final col in _columns) {
      if (col.width <= 0) continue;

      final widthStyle = Style()
          .inline(true)
          .width(col.width)
          .maxWidth(col.width);
      final rendered = widthStyle.render(truncate(col.title, col.width, '…'));
      cells.add(styles.header.render(rendered));
    }
    return Layout.joinHorizontal(VerticalAlign.top, cells);
  }

  String _renderRow(int r) {
    final cells = <String>[];
    for (var i = 0; i < _columns.length && i < _rows[r].length; i++) {
      final col = _columns[i];
      if (col.width <= 0) continue;

      final value = _rows[r][i];
      final widthStyle = Style()
          .inline(true)
          .width(col.width)
          .maxWidth(col.width);
      final rendered = widthStyle.render(truncate(value, col.width, '…'));
      cells.add(styles.cell.render(rendered));
    }

    final row = Layout.joinHorizontal(VerticalAlign.top, cells);

    if (r == _cursor) {
      return styles.selected.render(row);
    }

    return row;
  }

  @override
  Cmd? init() => null;

  @override
  (TableModel, Cmd?) update(Msg msg) {
    if (!_focused) {
      return (this, null);
    }

    if (msg is KeyMsg) {
      if (keyMatches(msg.key, [keyMap.lineUp])) {
        moveUp(1);
      } else if (keyMatches(msg.key, [keyMap.lineDown])) {
        moveDown(1);
      } else if (keyMatches(msg.key, [keyMap.pageUp])) {
        moveUp(_viewport.height ?? 0);
      } else if (keyMatches(msg.key, [keyMap.pageDown])) {
        moveDown(_viewport.height ?? 0);
      } else if (keyMatches(msg.key, [keyMap.halfPageUp])) {
        moveUp((_viewport.height ?? 0) ~/ 2);
      } else if (keyMatches(msg.key, [keyMap.halfPageDown])) {
        moveDown((_viewport.height ?? 0) ~/ 2);
      } else if (keyMatches(msg.key, [keyMap.gotoTop])) {
        gotoTop();
      } else if (keyMatches(msg.key, [keyMap.gotoBottom])) {
        gotoBottom();
      }
    }

    return (this, null);
  }

  @override
  String view() {
    return '${_headersView()}\n${_viewport.view()}';
  }

  /// Returns the help view for the keymap.
  String helpView() {
    return help.view(keyMap);
  }
}
