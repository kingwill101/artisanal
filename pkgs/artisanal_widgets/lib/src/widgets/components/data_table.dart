
import 'package:artisanal/widgets.dart';

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
    final hStyle = copyStyle(headerStyle ?? theme.titleSmall)
      ..foreground(theme.onSurface)
      ..bold();
    final cStyle = copyStyle(cellStyle ?? theme.bodyMedium)
      ..foreground(theme.onSurface);
    final bStyle = copyStyle(Style())..foreground(bColor);

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

    final chars = _borderChars();
    final hasOuterBorder = chars.topLeft != null;

    // Build a horizontal rule line.
    String buildHRule(String h, String cross, String? left, String? right) {
      final parts = <String>[];
      if (left != null) parts.add(left);
      for (var i = 0; i < colCount; i++) {
        parts.add(h * widths[i]);
        if (i < colCount - 1) {
          parts.add('$h$cross$h');
        }
      }
      if (right != null) parts.add(right);
      return parts.join();
    }

    // Build a content row (header or data).
    Widget buildRow(List<String> values, Style textStyle) {
      final cells = <Widget>[];
      if (hasOuterBorder) {
        cells.add(Text('${chars.v} ', style: bStyle));
      }
      for (var i = 0; i < colCount; i++) {
        final value = i < values.length ? values[i] : '';
        cells.add(Text(value.padRight(widths[i]), style: textStyle));
        if (i < colCount - 1) {
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
    children.add(buildRow(columns, hStyle));

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
    for (final row in rows) {
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
