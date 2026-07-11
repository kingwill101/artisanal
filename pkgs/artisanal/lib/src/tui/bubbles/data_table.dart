import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import '../view.dart';
import 'package:artisanal/style.dart';
import 'key_binding.dart';
import 'textinput.dart';
import 'paginator.dart';
import 'table.dart';
import 'search.dart';

/// Message sent when a data table row is selected.
class DataTableSelectionMadeMsg<T> extends Msg {
  const DataTableSelectionMadeMsg(this.item, this.index);

  /// The selected item.
  final T item;

  /// The original index of the selected item.
  final int index;

  @override
  String toString() => 'DataTableSelectionMadeMsg($item, index: $index)';
}

/// Styles for the interactive data table.
class DataTableStyles {
  DataTableStyles({
    Style? title,
    Style? prompt,
    Style? tableHeader,
    Style? tableCell,
    Style? tableSelected,
    Style? dimmed,
    Style? noResults,
  }) : title = title ?? Style().bold(),
       prompt = prompt ?? Style().foreground(AnsiColor(11)),
       tableHeader = tableHeader ?? Style().bold().padding(0, 1),
       tableCell = tableCell ?? Style().padding(0, 1),
       tableSelected =
           tableSelected ?? Style().bold().foreground(AnsiColor(212)),
       dimmed = dimmed ?? Style().foreground(AnsiColor(8)),
       noResults = noResults ?? Style().foreground(AnsiColor(8)).italic();

  final Style title;
  final Style prompt;
  final Style tableHeader;
  final Style tableCell;
  final Style tableSelected;
  final Style dimmed;
  final Style noResults;
}

/// A hybrid interactive data table model.
///
/// Combines a search input, a paginated table, and fuzzy filtering.
class DataTableModel<T> extends ViewComponent {
  DataTableModel({
    required List<T> items,
    required List<Column> columns,
    required List<String> Function(T) rowBuilder,
    this.title = '',
    this.placeholder = 'Type to filter...',
    this.noResultsText = 'No matching rows found',
    this.showTitle = true,
    this.showHelp = true,
    int pageSize = 10,
    DataTableStyles? styles,
  }) : _items = items,
       _rowBuilder = rowBuilder,
       styles = styles ?? DataTableStyles() {
    _input = TextInputModel(prompt: '🔍 ', placeholder: placeholder);

    // Compute total table width from columns (each column has 2 chars padding
    // from TableStyles.cell default which adds padding(0, 1) = left+right).
    final totalWidth = columns.fold(0, (sum, c) => sum + c.width + 2);

    _table = TableModel(
      columns: columns,
      rows: [],
      height: pageSize + 2, // +1 for header, +1 to account for setHeight offset
      styles: TableStyles(
        header: this.styles.tableHeader,
        cell: this.styles.tableCell,
        selected: this.styles.tableSelected,
      ),
    )..focus();

    // Width MUST be set after construction so viewport gets a non-zero width.
    _table.setWidth(totalWidth);

    _paginator = PaginatorModel(
      perPage: pageSize,
      type: PaginationType.dots,
      activeDot: PaginationDots.active,
      inactiveDot: PaginationDots.inactive,
    );

    _runFilter();
  }

  final String title;
  final String placeholder;
  final String noResultsText;
  final bool showTitle;
  final bool showHelp;
  final DataTableStyles styles;

  final List<T> _items;
  final List<String> Function(T) _rowBuilder;

  late TextInputModel _input;
  late TableModel _table;
  late PaginatorModel _paginator;

  List<FilteredSearchItem<T>> _filteredItems = [];

  // ── Test accessors (intentionally non-private for unit testing) ──────────

  /// Current row cursor within the visible page. Exposed for testing.
  int get tableCursor => _table.cursor;

  /// Current page number (0-based). Exposed for testing.
  int get currentPage => _paginator.page;

  /// The rows currently shown in the table. Exposed for testing.
  List<List<String>> get tableRows => _table.rows;

  void _runFilter() {
    final query = _input.value;
    _filteredItems = defaultSearchFilter(
      query,
      _items,
      (item) => _rowBuilder(item).join(' '),
    );

    _updateTableData();
  }

  void _updateTableData() {
    // Update paginator with new count
    _paginator = _paginator.setTotalPages(_filteredItems.length);

    // Reset page if out of bounds
    if (_paginator.page >= _paginator.totalPages) {
      _paginator = _paginator.goToPage(0);
    }

    final (start, end) = _paginator.getSliceBounds(_filteredItems.length);
    final pageItems = _filteredItems.sublist(start, end);

    _table.rows = pageItems.map((fi) => _rowBuilder(fi.item)).toList();

    // Ensure table cursor is valid for current page
    if (_table.cursor >= _table.rows.length) {
      _table.cursor = 0;
    }
  }

  @override
  Cmd? init() => _input.focus();

  @override
  (DataTableModel<T>, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      final key = msg.key;

      // Global navigation (PgUp/PgDown)
      if (keyMatches(key, [_table.keyMap.pageUp, _table.keyMap.pageDown])) {
        final (newTable, cmd) = _table.update(msg);
        _table = newTable;
        return (this, cmd);
      }

      // Selection
      if (keyMatches(key, [
        KeyBinding(keys: ['enter']),
      ])) {
        if (_table.rows.isNotEmpty) {
          final (start, _) = _paginator.getSliceBounds(_filteredItems.length);
          final selectedIdxInFiltered = start + _table.cursor;
          final selected = _filteredItems[selectedIdxInFiltered];
          return (
            this,
            Cmd.message(
              DataTableSelectionMadeMsg<T>(selected.item, selected.index),
            ),
          );
        }
      }

      // Table navigation intercepts (Up/Down)
      if (keyMatches(key, [_table.keyMap.lineUp, _table.keyMap.lineDown])) {
        _handleNavigate(up: keyMatches(key, [_table.keyMap.lineUp]));
        return (this, null);
      }

      // Cancel
      if (keyMatches(key, [
        KeyBinding(keys: ['esc']),
      ])) {
        return (this, Cmd.message(const SearchCancelledMsg()));
      }
    }

    // Mouse wheel scroll.
    //
    // Terminal decoders (key.dart _decodeX10Button / _decodeSgrButton) produce
    // wheel events with action=press, NOT action=wheel — so match on button
    // only.  We also accept action=wheel for forward-compatibility.
    if (msg is MouseMsg &&
        (msg.button == MouseButton.wheelUp ||
            msg.button == MouseButton.wheelDown)) {
      _handleNavigate(up: msg.button == MouseButton.wheelUp);
      return (this, null);
    }

    // Forward to input for filtering
    final oldQuery = _input.value;
    final (newInput, inputCmd) = _input.update(msg);
    _input = newInput;

    if (_input.value != oldQuery) {
      _runFilter();
    }

    return (this, inputCmd);
  }

  /// Moves the selection up (when [up] is true) or down one row,
  /// wrapping across page boundaries and list edges.
  void _handleNavigate({required bool up}) {
    if (_filteredItems.isEmpty) return;

    final oldCursor = _table.cursor;

    if (up) {
      if (oldCursor == 0 && _paginator.page == 0) {
        // Wrap to very last item on the very last page.
        _paginator = _paginator.goToPage(_paginator.totalPages - 1);
        _updateTableData();
        _table.cursor = _table.rows.length - 1;
      } else if (oldCursor == 0 && _paginator.page > 0) {
        // Cross page boundary upward.
        _paginator = _paginator.prevPage();
        _updateTableData();
        _table.cursor = _table.rows.length - 1;
      } else {
        _table.moveUp(1);
      }
    } else {
      if (oldCursor == _table.rows.length - 1 && _paginator.onLastPage) {
        // Wrap to very first item on the very first page.
        _paginator = _paginator.goToPage(0);
        _updateTableData();
        _table.cursor = 0;
      } else if (oldCursor == _table.rows.length - 1 &&
          !_paginator.onLastPage) {
        // Cross page boundary downward.
        _paginator = _paginator.nextPage();
        _updateTableData();
        _table.cursor = 0;
      } else {
        _table.moveDown(1);
      }
    }
  }

  @override
  String view() {
    final buffer = StringBuffer();

    if (showTitle && title.isNotEmpty) {
      buffer.writeln(styles.title.render(title));
    }

    final inputView = _input.view();
    buffer.writeln(
      inputView is View
          ? inputView.content.trimRight()
          : inputView.toString().trimRight(),
    );

    if (_filteredItems.isEmpty) {
      buffer.writeln(styles.noResults.render('  $noResultsText'));
    } else {
      buffer.writeln(_table.view());
    }

    if (_paginator.totalPages > 1) {
      buffer.writeln(styles.dimmed.render(_paginator.view()));
    }

    if (showHelp) {
      final help =
          '${Arrows.up}/${Arrows.down} navigate  ${KeyboardChars.enter} select  esc cancel';
      buffer.writeln(styles.dimmed.render(help));
    }

    return buffer.toString();
  }
}
