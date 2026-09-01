import 'package:artisanal_widgets/widgets.dart';

import 'package:artisanal/style.dart' show Color, Style;

/// A simple data table widget that renders tabular data with column headers,
/// row separators, and optional theming.
///
/// ```dart
/// DataTable(
///   columns: ['Name', 'Age', 'City'],
///   rows: [
///     ['Alice', '30', 'NYC'],
///     ['Bob', '25', 'London'],
///   ],
/// )
/// ```
class DataTable extends StatelessWidget {
  DataTable({
    required this.columns,
    required this.rows,
    this.headerStyle,
    this.cellStyle,
    this.borderColor,
    this.borderStyle = DataTableBorderStyle.normal,
    super.key,
  }) : _headerCells = columns
           .map((value) => DataTableCell(value))
           .toList(growable: false),
       _cellRows = rows
           .map(
             (row) => row
                 .map((value) => DataTableCell(value))
                 .toList(growable: false),
           )
           .toList(growable: false);

  /// Creates a table with structured cells supporting spans and alignment.
  DataTable.cells({
    required List<DataTableCell> columns,
    required List<List<DataTableCell>> rows,
    this.headerStyle,
    this.cellStyle,
    this.borderColor,
    this.borderStyle = DataTableBorderStyle.normal,
    super.key,
  }) : columns = columns.map((cell) => cell.value).toList(growable: false),
       rows = rows
           .map((row) => row.map((cell) => cell.value).toList(growable: false))
           .toList(growable: false),
       _headerCells = List<DataTableCell>.unmodifiable(columns),
       _cellRows = rows
           .map((row) => List<DataTableCell>.unmodifiable(row))
           .toList(growable: false);

  /// Column header labels.
  final List<String> columns;

  /// Row data. Each inner list must have the same length as [columns].
  final List<List<String>> rows;

  final List<DataTableCell> _headerCells;
  final List<List<DataTableCell>> _cellRows;

  /// Style for header text. Defaults to bold theme title.
  final Style? headerStyle;

  /// Style for cell text. Defaults to theme body.
  final Style? cellStyle;

  /// Border/separator color. Defaults to theme border.
  final Color? borderColor;

  /// Border drawing style.
  final DataTableBorderStyle borderStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bColor = borderColor ?? theme.border;
    final hStyle = copyStyle(headerStyle ?? theme.titleSmall)
      ..foreground(theme.onSurface)
      ..bold();
    final cStyle = copyStyle(cellStyle ?? theme.bodyMedium)
      ..foreground(theme.onSurface);
    final bStyle = copyStyle(Style())..foreground(bColor);

    // Calculate column widths.
    final colCount = columns.length;
    final widths = List<int>.filled(colCount, 0);
    _measureCells(_headerCells, widths);
    for (final row in _cellRows) {
      _measureCells(row, widths);
    }
    _expandWidthsForSpans(_headerCells, widths);
    for (final row in _cellRows) {
      _expandWidthsForSpans(row, widths);
    }

    final chars = _borderChars();
    final hasOuterBorder = chars.topLeft != null;

    // Build a horizontal rule line.
    String buildHRule(String h, String cross, String? left, String? right) {
      final parts = <String>[];
      if (left != null) parts.add('$left$h');
      for (var i = 0; i < colCount; i++) {
        parts.add(h * widths[i]);
        if (i < colCount - 1) {
          parts.add('$h$cross$h');
        }
      }
      if (right != null) parts.add('$h$right');
      return parts.join();
    }

    // Build a content row (header or data).
    Widget buildRow(List<DataTableCell> values, Style textStyle) {
      final cells = <Widget>[];
      if (hasOuterBorder) {
        cells.add(Text('${chars.v} ', style: bStyle));
      }
      var column = 0;
      var cellIndex = 0;
      while (column < colCount) {
        final cell = cellIndex < values.length
            ? values[cellIndex]
            : const DataTableCell('');
        final span = cell.columnSpan.clamp(1, colCount - column);
        final width = _spannedWidth(widths, column, span);
        final value = _align(cell.value, width, cell.textAlign);
        cells.add(Text(value, style: cell.style ?? textStyle));
        column += span;
        cellIndex++;
        if (column < colCount) {
          cells.add(Text(' ${chars.v} ', style: bStyle));
        }
      }
      if (hasOuterBorder) {
        cells.add(Text(' ${chars.v}', style: bStyle));
      }
      return Row(gap: 0, children: cells);
    }

    final children = <Widget>[];

    // Top border (only for styles with outer borders).
    if (hasOuterBorder) {
      children.add(
        Text(
          buildHRule(chars.h, chars.topCross!, chars.topLeft, chars.topRight),
          style: bStyle,
        ),
      );
    }

    // Header row.
    children.add(buildRow(_headerCells, hStyle));

    // Header separator.
    children.add(
      Text(
        buildHRule(
          chars.h,
          chars.cross,
          hasOuterBorder ? chars.leftCross : null,
          hasOuterBorder ? chars.rightCross : null,
        ),
        style: bStyle,
      ),
    );

    // Data rows.
    for (final row in _cellRows) {
      children.add(buildRow(row, cStyle));
    }

    // Bottom border (only for styles with outer borders).
    if (hasOuterBorder) {
      children.add(
        Text(
          buildHRule(
            chars.h,
            chars.bottomCross!,
            chars.bottomLeft,
            chars.bottomRight,
          ),
          style: bStyle,
        ),
      );
    }

    return Column(gap: 0, children: children);
  }

  _TableBorderChars _borderChars() {
    return switch (borderStyle) {
      DataTableBorderStyle.normal => _TableBorderChars(
        h: '─',
        v: '│',
        cross: '┼',
      ),
      DataTableBorderStyle.rounded => _TableBorderChars(
        h: '─',
        v: '│',
        cross: '┼',
        topLeft: '╭',
        topRight: '╮',
        bottomLeft: '╰',
        bottomRight: '╯',
        topCross: '┬',
        bottomCross: '┴',
        leftCross: '├',
        rightCross: '┤',
      ),
      DataTableBorderStyle.heavy => _TableBorderChars(
        h: '━',
        v: '┃',
        cross: '╋',
      ),
      DataTableBorderStyle.dashed => _TableBorderChars(
        h: '╌',
        v: '╎',
        cross: '┼',
      ),
      DataTableBorderStyle.ascii => _TableBorderChars(
        h: '-',
        v: '|',
        cross: '+',
      ),
    };
  }

  static void _measureCells(List<DataTableCell> cells, List<int> widths) {
    var column = 0;
    for (final cell in cells) {
      if (column >= widths.length) break;
      if (cell.columnSpan == 1 && cell.value.length > widths[column]) {
        widths[column] = cell.value.length;
      }
      column += cell.columnSpan;
    }
  }

  static void _expandWidthsForSpans(
    List<DataTableCell> cells,
    List<int> widths,
  ) {
    var column = 0;
    for (final cell in cells) {
      if (column >= widths.length) break;
      final span = cell.columnSpan.clamp(1, widths.length - column);
      final available = _spannedWidth(widths, column, span);
      final deficit = cell.value.length - available;
      if (deficit > 0) {
        widths[column + span - 1] += deficit;
      }
      column += span;
    }
  }

  static int _spannedWidth(List<int> widths, int start, int span) {
    var width = 0;
    for (var i = 0; i < span; i++) {
      width += widths[start + i];
    }
    // A span consumes the padding and separator columns that would otherwise
    // appear between its covered columns.
    return width + (span - 1) * 3;
  }

  static String _align(String value, int width, TextAlign alignment) {
    final remaining = width - value.length;
    if (remaining <= 0) return value;
    return switch (alignment) {
      TextAlign.right => '${' ' * remaining}$value',
      TextAlign.center =>
        '${' ' * (remaining ~/ 2)}$value${' ' * (remaining - remaining ~/ 2)}',
      TextAlign.left || TextAlign.justify => value.padRight(width),
    };
  }
}

/// Structured content for a [DataTable.cells] table.
final class DataTableCell {
  /// Creates a table cell.
  const DataTableCell(
    this.value, {
    this.columnSpan = 1,
    this.textAlign = TextAlign.left,
    this.style,
  }) : assert(columnSpan > 0);

  /// Cell text.
  final String value;

  /// Number of logical columns consumed by this cell.
  final int columnSpan;

  /// Horizontal alignment inside the combined cell width.
  final TextAlign textAlign;

  /// Optional style overriding the table's header or body style.
  final Style? style;
}

/// Border style for [DataTable].
enum DataTableBorderStyle { normal, rounded, heavy, dashed, ascii }

/// Internal border character set for [DataTable].
///
/// When [topLeft] is non-null, the table renders a full outer border
/// (top, bottom, left, right edges with corner pieces).
class _TableBorderChars {
  const _TableBorderChars({
    required this.h,
    required this.v,
    required this.cross,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
    this.topCross,
    this.bottomCross,
    this.leftCross,
    this.rightCross,
  });

  /// Horizontal line character (e.g., '─').
  final String h;

  /// Vertical line character (e.g., '│').
  final String v;

  /// Cross/intersection character (e.g., '┼').
  final String cross;

  /// Top-left corner (e.g., '╭'). Null means no outer border.
  final String? topLeft;

  /// Top-right corner (e.g., '╮').
  final String? topRight;

  /// Bottom-left corner (e.g., '╰').
  final String? bottomLeft;

  /// Bottom-right corner (e.g., '╯').
  final String? bottomRight;

  /// Top edge T-piece (e.g., '┬').
  final String? topCross;

  /// Bottom edge T-piece (e.g., '┴').
  final String? bottomCross;

  /// Left edge T-piece (e.g., '├').
  final String? leftCross;

  /// Right edge T-piece (e.g., '┤').
  final String? rightCross;
}
