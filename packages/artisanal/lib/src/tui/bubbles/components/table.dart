import '../../../style/border.dart' as style_border;
import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// Callback for per-cell styling in tables.
///
/// [row] is the row index (-1 for header row, 0+ for data rows).
/// [col] is the column index.
/// [data] is the cell content as a string.
///
/// Return a [Style] to apply to the cell, or `null` for no styling.
typedef TableStyleFunc = Style? Function(int row, int col, String data);

/// A table component with headers and rows.
///
/// ```dart
/// TableComponent(
///   headers: ['ID', 'Name', 'Status'],
///   rows: [
///     ['1', 'users', 'DONE'],
///     ['2', 'posts', 'PENDING'],
///   ],
///   styleFunc: (row, col, data) {
///     if (data == 'DONE') return Style().foreground(Colors.green);
///     return null;
///   },
/// ).renderln(context);
/// ```
class TableComponent extends DisplayComponent {
  const TableComponent({
    required this.headers,
    required this.rows,
    this.padding = 1,
    this.styleFunc,
    this.renderConfig = const RenderConfig(),
  });

  final List<String> headers;
  final List<List<Object?>> rows;
  final int padding;
  final TableStyleFunc? styleFunc;
  final RenderConfig renderConfig;

  @override
  String render() {
    final normalizedRows = rows
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList(growable: false);

    final columns = headers.length;
    final widths = List<int>.filled(columns, 0);

    // Calculate column widths
    for (var c = 0; c < columns; c++) {
      widths[c] = Style.visibleLength(headers[c]);
    }
    for (final row in normalizedRows) {
      for (var c = 0; c < columns; c++) {
        final cell = c < row.length ? row[c] : '';
        final len = Style.visibleLength(cell);
        if (len > widths[c]) widths[c] = len;
      }
    }

    final pad = ' ' * padding;

    String border() {
      final parts = widths.map((w) => '-' * (w + padding * 2));
      return '+${parts.join('+')}+';
    }

    String rowLine(List<String> cells, int rowIndex) {
      final parts = <String>[];
      for (var c = 0; c < columns; c++) {
        final raw = c < cells.length ? cells[c] : '';
        final visible = Style.visibleLength(raw);
        final fill = widths[c] - visible;
        final fillCount = fill > 0 ? fill : 0;

        var content = raw;
        if (styleFunc != null) {
          final style = styleFunc!(rowIndex, c, raw);
          if (style != null) {
            renderConfig.configureStyle(style);
            content = style.render(raw);
          }
        }

        parts.add('$pad$content${' ' * fillCount}$pad');
      }
      return '|${parts.join('|')}|';
    }

    final buffer = StringBuffer();
    buffer.writeln(border());
    buffer.writeln(rowLine(headers, -1)); // Header row is -1
    buffer.writeln(border());
    for (var i = 0; i < normalizedRows.length; i++) {
      buffer.writeln(rowLine(normalizedRows[i], i));
    }
    buffer.write(border());

    return buffer.toString();
  }
}

/// A horizontal table component (row-as-headers style).
///
/// Unlike a regular table where headers are at the top,
/// this displays data with the first column as headers.
///
/// ```dart
/// HorizontalTableComponent(
///   data: {
///     'Name': 'John Doe',
///     'Email': 'john@example.com',
///   },
/// ).renderln(context);
/// ```
class HorizontalTableComponent extends DisplayComponent {
  const HorizontalTableComponent({
    required this.data,
    this.padding = 1,
    this.separator = '│',
    this.renderConfig = const RenderConfig(),
  });

  final Map<String, Object?> data;
  final int padding;
  final String separator;
  final RenderConfig renderConfig;

  @override
  String render() {
    if (data.isEmpty) return '';

    final headers = data.keys.toList();
    final values = data.values.map((v) => v?.toString() ?? '').toList();

    final maxHeaderWidth = headers
        .map((h) => Style.visibleLength(h))
        .fold<int>(0, (m, v) => v > m ? v : m);

    final buffer = StringBuffer();
    final pad = ' ' * padding;
    final keyStyle = renderConfig.configureStyle(
      Style().foreground(Colors.info),
    );

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      final value = values[i];
      final headerPadding = maxHeaderWidth - Style.visibleLength(header);

      if (i > 0) buffer.writeln();
      buffer.write(
        '$pad${keyStyle.render(header)}${' ' * headerPadding}$pad$separator$pad$value',
      );
    }

    return buffer.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Table Builder
// ─────────────────────────────────────────────────────────────────────────────

/// A fluent builder for creating styled tables.
///
/// Provides a chainable API for table configuration with support for
/// per-cell conditional styling via [styleFunc].
///
/// ```dart
/// final table = Table()
///     .headers(['Name', 'Status', 'Age'])
///     .row(['Alice', 'Active', '25'])
///     .row(['Bob', 'Inactive', '30'])
///     .styleFunc((row, col, data) {
///       if (row == Table.headerRow) {
///         return Style().bold().foreground(Colors.cyan);
///       }
///       if (col == 1 && data == 'Active') {
///         return Style().foreground(Colors.success);
///       }
///       return null;
///     })
///     .border(style_border.Border.rounded)
///     .render();
///
/// print(table);
/// ```
/// A component for rendering styled tables.
///
/// The [Table] component provides a fluent API for building tables with:
/// - Headers and data rows.
/// - Custom borders (rounded, ascii, etc.).
/// - Per-cell styling via [TableStyleFunc].
/// - Automatic column width calculation.
///
/// Example:
/// ```dart
/// final table = Table()
///   .headers(['ID', 'Name'])
///   .rows([
///     ['1', 'Alice'],
///     ['2', 'Bob'],
///   ])
///   .border(Border.rounded);
///
/// print(table.render());
/// ```
class Table extends DisplayComponent {
  /// Creates a new empty table builder.
  Table({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  /// Row index constant for the header row in [styleFunc].
  static const int headerRow = -1;

  final List<String> _headers = [];
  final List<List<String>> _rows = [];
  TableStyleFunc? _styleFunc;
  style_border.Border _border = style_border.Border.normal;
  int _padding = 0;
  int? _width;
  int? _height;
  int _offset = 0;
  bool _wrap = true;
  List<int>? _manualWidths;
  Style? _headerStyle;
  Style? _borderStyle;
  Style? _cellStyle;
  Style? _baseStyle;

  // Border visibility flags
  bool _borderTop = true;
  bool _borderBottom = true;
  bool _borderLeft = true;
  bool _borderRight = true;
  bool _borderHeader = true;
  bool _borderColumn = true;
  bool _borderRow = false;

  Style? _styleForCell(int row, int col, String raw) {
    Style? s;

    if (_styleFunc != null) {
      s = _styleFunc!(row, col, raw);
    }

    if (s == null) {
      if (row == headerRow && _headerStyle != null) {
        s = _headerStyle;
      } else if (_cellStyle != null) {
        s = _cellStyle;
      }
    }

    if (_baseStyle != null) {
      if (s == null) {
        s = _baseStyle;
      } else {
        // Inherit from base style
        s = _baseStyle!.copy()..inherit(s);
      }
    }

    if (s != null) {
      return _renderConfig.configureStyle(s);
    }

    return null;
  }

  String _renderCellValue(int row, int col, String raw, [int? width]) {
    var style = _styleForCell(row, col, raw);
    if (width != null && _wrap && row != headerRow) {
      // Headers are never wrapped in lipgloss v2.
      // We wrap at (width - table padding) so the table's own padding
      // can still be applied around the wrapped content.
      final wrapAt = width - (_padding * 2);
      if (wrapAt > 0) {
        style = (style ?? Style()).width(wrapAt);
      }
    }
    return style?.render(raw) ?? raw;
  }

  /// Sets the table headers.
  Table headers(List<String> headers) {
    _headers.clear();
    _headers.addAll(headers);
    return this;
  }

  /// Adds a row to the table.
  Table row(List<Object?> cells) {
    _rows.add(cells.map((c) => c?.toString() ?? '').toList());
    return this;
  }

  /// Adds multiple rows to the table.
  Table rows(List<List<Object?>> rows) {
    for (final r in rows) {
      row(r);
    }
    return this;
  }

  /// Clears all rows from the table.
  Table clearRows() {
    _rows.clear();
    return this;
  }

  /// Sets manual column widths.
  Table widths(List<int> values) {
    _manualWidths = values;
    return this;
  }

  /// Sets the style function for per-cell conditional styling.
  ///
  /// The function receives [row] (-1 for header), [col], and [data],
  /// and should return a [Style] or `null`.
  Table styleFunc(TableStyleFunc func) {
    _styleFunc = func;
    return this;
  }

  /// Sets the default style for all cells.
  Table style(Style style) {
    _cellStyle = style;
    return this;
  }

  /// Sets the style for the header row.
  Table headerStyle(Style style) {
    _headerStyle = style;
    return this;
  }

  /// Sets the style for the table borders.
  Table borderStyle(Style style) {
    _borderStyle = style;
    return this;
  }

  /// Sets the base style for the whole table.
  Table baseStyle(Style style) {
    _baseStyle = style;
    return this;
  }

  /// Sets the border style.
  Table border(style_border.Border border) {
    _border = border;
    if (border == style_border.Border.none) {
      _borderTop = false;
      _borderBottom = false;
      _borderLeft = false;
      _borderRight = false;
      _borderHeader = false;
      _borderColumn = false;
      _borderRow = false;
    }
    return this;
  }

  /// Sets the cell padding.
  Table padding(int value) {
    _padding = value;
    return this;
  }

  /// Sets the total table width.
  Table width(int value) {
    _width = value;
    return this;
  }

  /// Sets the table height (limits visible rows).
  Table height(int value) {
    _height = value;
    return this;
  }

  /// Sets the row offset (skips first N rows).
  Table offset(int value) {
    _offset = value;
    return this;
  }

  /// Sets whether text should wrap in cells.
  Table wrap(bool value) {
    _wrap = value;
    return this;
  }

  /// Sets the default cell style.
  Table cellStyle(Style style) {
    _cellStyle = style;
    return this;
  }

  /// Sets whether to show the top border.
  Table borderTop(bool value) {
    _borderTop = value;
    return this;
  }

  /// Sets whether to show the bottom border.
  Table borderBottom(bool value) {
    _borderBottom = value;
    return this;
  }

  /// Sets whether to show the left border.
  Table borderLeft(bool value) {
    _borderLeft = value;
    return this;
  }

  /// Sets whether to show the right border.
  Table borderRight(bool value) {
    _borderRight = value;
    return this;
  }

  /// Sets whether to show the header separator.
  Table borderHeader(bool value) {
    _borderHeader = value;
    return this;
  }

  /// Sets whether to show column separators.
  Table borderColumn(bool value) {
    _borderColumn = value;
    return this;
  }

  /// Sets whether to show row separators.
  Table borderRow(bool value) {
    _borderRow = value;
    return this;
  }

  /// Renders the table to a string.
  @override
  String render() {
    if (_headers.isEmpty && _rows.isEmpty) return '';

    final columns = _headers.isNotEmpty
        ? _headers.length
        : (_rows.isNotEmpty ? _rows.first.length : 0);

    // Calculate column widths using rendered cell content so width/align styles are respected.
    final widths = List<int>.filled(columns, 0);
    if (_manualWidths != null) {
      for (var i = 0; i < columns && i < _manualWidths!.length; i++) {
        widths[i] = _manualWidths![i];
      }
    }

    if (_manualWidths == null) {
      void applyWidths(List<String> cells, int rowIndex) {
        for (var c = 0; c < columns; c++) {
          final raw = c < cells.length ? cells[c] : '';
          final rendered = _renderCellValue(rowIndex, c, raw);
          for (final line in rendered.split('\n')) {
            final len = Style.visibleLength(line);
            if (len > widths[c]) widths[c] = len;
          }
        }
      }

      if (_headers.isNotEmpty) {
        applyWidths(_headers, headerRow);
      }

      for (var i = 0; i < _rows.length; i++) {
        applyWidths(_rows[i], i);
      }
    }

    // Adjust for fixed width if specified
    if (_width != null && _manualWidths == null) {
      final totalPadding = _padding * 2 * columns;
      final borderCount = _borderColumn ? columns + 1 : 2;
      final available = _width! - totalPadding - borderCount;
      if (available > 0) {
        final perColumn = available ~/ columns;
        for (var i = 0; i < widths.length; i++) {
          if (widths[i] < perColumn) widths[i] = perColumn;
        }

        // Distribute any remaining width across columns (left-to-right) so the
        // rendered table matches the requested total width.
        final used = widths.fold<int>(0, (sum, w) => sum + w);
        var remaining = available - used;
        var j = 0;
        while (remaining > 0 && widths.isNotEmpty) {
          widths[j % widths.length]++;
          remaining--;
          j++;
        }
      }
    }

    final pad = ' ' * _padding;
    final b = _border;

    // Helper to style border characters
    String styleBorderText(String text) {
      if (_borderStyle == null) return text;
      return _renderConfig.configureStyle(_borderStyle!).render(text);
    }

    // Build horizontal border line
    String buildBorder(String left, String mid, String right, String fill) {
      final parts = widths.map((w) => fill * (w + _padding * 2));
      final leftChar = _borderLeft ? left : '';
      final rightChar = _borderRight ? right : '';
      final midChar = _borderColumn ? mid : '';
      return styleBorderText('$leftChar${parts.join(midChar)}$rightChar');
    }

    // Build a row with optional styling - handles multi-line cells
    List<String> buildRow(List<String> cells, int rowIndex) {
      // First, process each cell and split into lines
      final cellLines = <List<String>>[];
      var maxLines = 1;

      for (var c = 0; c < columns; c++) {
        final raw = c < cells.length ? cells[c] : '';
        final styledContent = _renderCellValue(rowIndex, c, raw, widths[c]);

        // Split by newlines to handle multi-line content
        final lines = styledContent.split('\n');
        cellLines.add(lines);
        if (lines.length > maxLines) maxLines = lines.length;
      }

      // Build output rows
      final outputRows = <String>[];
      for (var lineIdx = 0; lineIdx < maxLines; lineIdx++) {
        final parts = <String>[];
        for (var c = 0; c < columns; c++) {
          final lines = cellLines[c];
          final line = lineIdx < lines.length ? lines[lineIdx] : '';
          final visible = Style.visibleLength(line);
          final fill = widths[c] - visible;
          final fillCount = fill > 0 ? fill : 0;
          final cellContent = '$pad$line${' ' * fillCount}$pad';
          parts.add(cellContent);
        }
        final leftBorder = _borderLeft ? styleBorderText(b.left) : '';
        final rightBorder = _borderRight ? styleBorderText(b.right) : '';
        final colSep = _borderColumn ? styleBorderText(b.left) : '';
        outputRows.add('$leftBorder${parts.join(colSep)}$rightBorder');
      }

      return outputRows;
    }

    final buffer = StringBuffer();

    // Top border
    if (_borderTop) {
      buffer.writeln(
        buildBorder(b.topLeft, b.middleTop ?? b.top, b.topRight, b.top),
      );
    }

    // Header row
    if (_headers.isNotEmpty) {
      for (final line in buildRow(_headers, headerRow)) {
        buffer.writeln(line);
      }
      // Header separator
      if (_borderHeader) {
        buffer.writeln(
          buildBorder(
            b.middleLeft ?? b.left,
            b.middle ?? b.top,
            b.middleRight ?? b.right,
            b.top,
          ),
        );
      }
    }

    // Data rows with offset and height
    final startRow = _offset.clamp(0, _rows.length);
    var endRow = _rows.length;
    if (_height != null) {
      // Calculate available rows based on height
      var usedLines = 0;
      if (_borderTop) usedLines++;
      if (_headers.isNotEmpty) usedLines++;
      if (_borderHeader && _headers.isNotEmpty) usedLines++;
      if (_borderBottom) usedLines++;

      final availableRows = _height! - usedLines;
      if (availableRows > 0 && startRow + availableRows < endRow) {
        endRow = startRow + availableRows;
      }
    }

    for (var i = startRow; i < endRow; i++) {
      for (final line in buildRow(_rows[i], i)) {
        buffer.writeln(line);
      }
      // Row separator (between rows, not after last)
      if (_borderRow && i < endRow - 1) {
        buffer.writeln(
          buildBorder(
            b.middleLeft ?? b.left,
            b.middle ?? b.top,
            b.middleRight ?? b.right,
            b.top,
          ),
        );
      }
    }

    // Bottom border
    if (_borderBottom) {
      buffer.write(
        buildBorder(
          b.bottomLeft,
          b.middleBottom ?? b.bottom,
          b.bottomRight,
          b.bottom,
        ),
      );
    }

    return buffer.toString().trimRight();
  }

  /// Returns the number of lines in the rendered table.
  @override
  int get lineCount {
    var count = 0;
    if (_borderTop) count++;
    if (_borderBottom) count++;
    if (_headers.isNotEmpty) count++; // Header row
    if (_borderHeader && _headers.isNotEmpty) count++; // Header separator

    final startRow = _offset.clamp(0, _rows.length);
    var visibleRows = _rows.length - startRow;
    if (_height != null) {
      var usedLines = count;
      final availableRows = _height! - usedLines;
      if (availableRows > 0 && availableRows < visibleRows) {
        visibleRows = availableRows;
      }
    }
    count += visibleRows;
    if (_borderRow && visibleRows > 1) {
      count += visibleRows - 1; // Row separators
    }
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common table styles.
extension TableFactory on Table {
  /// Creates a simple table from headers and rows.
  static Table fromData(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows);
  }

  /// Creates a table with rounded borders.
  static Table rounded(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.rounded);
  }

  /// Creates a table with double borders.
  static Table doubleBorder(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.double);
  }

  /// Creates a table with styled headers.
  static Table styled(
    List<String> headers,
    List<List<Object?>> rows, {
    Style? headerStyle,
    style_border.Border? border,
  }) {
    final table = Table()
      ..headers(headers)
      ..rows(rows);

    if (headerStyle != null) table.headerStyle(headerStyle);
    if (border != null) table.border(border);

    return table;
  }

  /// Creates an ASCII-compatible table.
  static Table ascii(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.ascii);
  }

  /// Creates a table with status column styling.
  ///
  /// Automatically colors values in the specified column based on content.
  static Table withStatusColumn(
    List<String> headers,
    List<List<Object?>> rows, {
    int statusColumn = -1, // -1 means last column
    Map<String, Color>? statusColors,
  }) {
    final colors =
        statusColors ??
        {
          'active': Colors.success,
          'done': Colors.success,
          'ok': Colors.success,
          'success': Colors.success,
          'inactive': Colors.warning,
          'pending': Colors.warning,
          'waiting': Colors.warning,
          'error': Colors.error,
          'failed': Colors.error,
          'failure': Colors.error,
        };

    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.rounded)
      ..styleFunc((row, col, data) {
        final targetCol = statusColumn < 0
            ? headers.length + statusColumn
            : statusColumn;

        if (row == Table.headerRow) {
          return Style().bold();
        }

        if (col == targetCol) {
          final lowerData = data.toLowerCase();
          for (final entry in colors.entries) {
            if (lowerData.contains(entry.key)) {
              return Style().foreground(entry.value);
            }
          }
        }

        return null;
      });
  }
}
