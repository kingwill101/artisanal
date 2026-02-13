part of 'components_widgets.dart';

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
  });

  /// Column header labels.
  final List<String> columns;

  /// Row data. Each inner list must have the same length as [columns].
  final List<List<String>> rows;

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
    final hStyle = _copyStyle(headerStyle ?? theme.titleSmall)
      ..foreground(theme.onSurface)
      ..bold();
    final cStyle = _copyStyle(cellStyle ?? theme.bodyMedium)
      ..foreground(theme.onSurface);
    final bStyle = _copyStyle(Style())..foreground(bColor);

    // Calculate column widths.
    final colCount = columns.length;
    final widths = List<int>.filled(colCount, 0);
    for (var i = 0; i < colCount; i++) {
      widths[i] = columns[i].length;
    }
    for (final row in rows) {
      for (var i = 0; i < colCount && i < row.length; i++) {
        if (row[i].length > widths[i]) {
          widths[i] = row[i].length;
        }
      }
    }

    final (hChar, vChar, crossChar) = _borderChars();

    // Build header row.
    final headerCells = <Widget>[];
    for (var i = 0; i < colCount; i++) {
      headerCells.add(Text(columns[i].padRight(widths[i]), style: hStyle));
      if (i < colCount - 1) {
        headerCells.add(Text(' $vChar ', style: bStyle));
      }
    }

    // Build separator.
    final sepParts = <String>[];
    for (var i = 0; i < colCount; i++) {
      sepParts.add(hChar * widths[i]);
      if (i < colCount - 1) {
        sepParts.add('$hChar$crossChar$hChar');
      }
    }
    final separator = Text(sepParts.join(), style: bStyle);

    // Build data rows.
    final dataRows = <Widget>[];
    for (final row in rows) {
      final cells = <Widget>[];
      for (var i = 0; i < colCount; i++) {
        final value = i < row.length ? row[i] : '';
        cells.add(Text(value.padRight(widths[i]), style: cStyle));
        if (i < colCount - 1) {
          cells.add(Text(' $vChar ', style: bStyle));
        }
      }
      dataRows.add(Row(gap: 0, children: cells));
    }

    return Column(
      gap: 0,
      children: [
        Row(gap: 0, children: headerCells),
        separator,
        ...dataRows,
      ],
    );
  }

  (String, String, String) _borderChars() {
    return switch (borderStyle) {
      DataTableBorderStyle.normal => ('─', '│', '┼'),
      DataTableBorderStyle.rounded => ('─', '│', '┼'),
      DataTableBorderStyle.heavy => ('━', '┃', '╋'),
      DataTableBorderStyle.dashed => ('╌', '╎', '┼'),
      DataTableBorderStyle.ascii => ('-', '|', '+'),
    };
  }
}

/// Border style for [DataTable].
enum DataTableBorderStyle { normal, rounded, heavy, dashed, ascii }
