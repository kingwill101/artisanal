/// Table display components for TUI applications.
///
/// Provides data tables with headers, rows, borders, and per-cell styling.
///
/// ## Basic Usage
///
/// ```dart
/// // Simple table
/// print(TableComponent(
///   headers: ['ID', 'Name', 'Status'],
///   rows: [
///     ['1', 'Alice', 'Active'],
///     ['2', 'Bob', 'Inactive'],
///   ],
/// ).render());
///
/// // Fluent builder API
/// print(Table()
///     .headers(['Name', 'Status'])
///     .row(['Alice', 'Active'])
///     .row(['Bob', 'Inactive'])
///     .border(Border.rounded)
///     .headerStyle(Style().bold())
///     .render());
/// ```
///
/// ## Conditional Styling
///
/// Use [Table.styleFunc] for per-cell conditional styling:
/// ```dart
/// table.styleFunc((row, col, data) {
///   if (data == 'Active') return Style().foreground(Colors.green);
///   if (data == 'Error') return Style().foreground(Colors.red);
///   return null; // No special styling
/// });
/// ```
///
/// {@category TUI}
/// {@category Components}
library;

import '../../../style/border.dart' as style_border;
import '../../../style/blending.dart' as blending;
import '../../../style/color.dart';
import '../../../style/style.dart';
import '../../../colorprofile/convert.dart' as cp;
import 'base.dart';

import 'dart:math' as math;

/// Callback for per-cell styling in tables.
///
/// [row] is the row index (-1 for header row, 0+ for data rows).
/// [col] is the column index.
/// [data] is the cell content as a string.
///
/// Return a [Style] to apply to the cell, or `null` for no styling.
typedef TableStyleFunc = Style? Function(int row, int col, String data);

/// Blend mode used by themed table effects.
enum TableBlendMode {
  /// Replace the destination color with the source color.
  normal,

  /// Multiply blend mode.
  multiply,

  /// Screen blend mode.
  screen,

  /// Overlay blend mode.
  overlay,
}

/// The table section an effect should apply to.
enum TableThemeSection {
  /// Applies to all cells, including header and body.
  all,

  /// Applies to header cells only.
  header,

  /// Applies to body cells only.
  body,
}

/// The axis for sampling gradient colors in a table theme.
enum TableThemeGradientAxis {
  /// Uses column index to sample color.
  horizontal,

  /// Uses row index to sample color.
  vertical,
}

/// A composable style rule for table cells.
///
/// Rules can target all cells, only headers, only body rows, a specific row,
/// or a specific column.
class TableThemeEffect {
  /// Creates a new table theme effect.
  TableThemeEffect({
    this.style,
    this.section = TableThemeSection.all,
    this.row,
    this.column,
    this.gradient = const [],
    this.blendMode = TableBlendMode.normal,
    this.gradientAxis = TableThemeGradientAxis.horizontal,
  });

  /// Optional style to apply when this effect matches a cell.
  final Style? style;

  /// Target section for this effect.
  final TableThemeSection section;

  /// Target row for this effect (`Table.headerRow` allowed).
  final int? row;

  /// Target column for this effect.
  final int? column;

  /// Optional gradient to generate foreground color for matched cells.
  final List<Color> gradient;

  /// Blend mode used when the gradient is combined with theme colors.
  final TableBlendMode blendMode;

  /// Axis used when sampling the gradient.
  final TableThemeGradientAxis gradientAxis;

  bool _matchesSection(TableThemeSection activeSection) {
    return section == TableThemeSection.all || section == activeSection;
  }

  bool _matchesCoordinates(int row, int column) {
    if (this.row != null && this.row != row) return false;
    if (this.column != null && this.column != column) return false;
    return true;
  }

  /// Returns a style when the effect applies to the target cell.
  Style? styleForCell({
    required int row,
    required int column,
    required TableThemeSection section,
    required int rowCount,
    required int columnCount,
    required bool hasHeader,
    required bool hasDarkBackground,
  }) {
    if (!_matchesSection(section) || !_matchesCoordinates(row, column)) {
      return null;
    }
    if (style == null && gradient.isEmpty) return null;

    Style? result = style?.copy();
    if (gradient.isNotEmpty) {
      final sampled = _sampleGradientCellColor(
        row: row,
        column: column,
        rowCount: rowCount,
        columnCount: columnCount,
        hasHeader: hasHeader,
        axis: gradientAxis,
        hasDarkBackground: hasDarkBackground,
        gradientPalette: gradient,
      );
      if (sampled != null) {
        if (result == null) {
          result = Style();
          result.foreground(sampled);
        } else {
          final existing = result.foregroundColor;
          if (existing == null || blendMode == TableBlendMode.normal) {
            result.foreground(sampled);
          } else {
            result.foreground(
              TableTheme.applyBlendMode(
                existing,
                sampled,
                blendMode,
                hasDarkBackground: hasDarkBackground,
              ),
            );
          }
        }
      }
    }
    return result;
  }
}

/// A composable table theme with blend-aware effects and presets.
class TableTheme {
  /// Creates a table theme.
  TableTheme([this.effects = const []]);

  /// Theme effects applied in list order.
  final List<TableThemeEffect> effects;

  /// Default no-op theme.
  static final TableTheme defaultTheme = TableTheme();

  static final Map<String, TableTheme> _presets = {
    'neon': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.header,
        style: Style().bold().foreground(Colors.pink),
      ),
      TableThemeEffect(
        style: Style(),
        gradient: [Colors.pink, Colors.cyan, Colors.magenta],
        section: TableThemeSection.all,
        gradientAxis: TableThemeGradientAxis.horizontal,
      ),
    ]),
    'sunset': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.header,
        style: Style().bold().foreground(Colors.orange),
      ),
      TableThemeEffect(
        section: TableThemeSection.body,
        gradient: [Colors.warning, Colors.error, Colors.pink],
        gradientAxis: TableThemeGradientAxis.vertical,
      ),
    ]),
    'ocean': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.header,
        style: Style().bold().foreground(Colors.cyan),
      ),
      TableThemeEffect(
        section: TableThemeSection.body,
        gradient: [Colors.info, Colors.sky, Colors.cyan],
        gradientAxis: TableThemeGradientAxis.vertical,
      ),
    ]),
    'matrix': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.all,
        style: Style().foreground(Colors.green),
      ),
    ]),
    'mono': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.all,
        style: Style().foreground(Colors.gray),
      ),
    ]),
    'fire': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.header,
        style: Style().bold().foreground(Colors.orange),
      ),
      TableThemeEffect(
        section: TableThemeSection.body,
        gradient: [Colors.orange, Colors.error, Colors.warning],
        gradientAxis: TableThemeGradientAxis.horizontal,
      ),
    ]),
    'forest': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.all,
        gradient: [Colors.green, Colors.teal, Colors.lime],
        gradientAxis: TableThemeGradientAxis.vertical,
      ),
    ]),
    'violet': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.all,
        gradient: [Colors.purple, Colors.indigo, Colors.magenta],
        blendMode: TableBlendMode.overlay,
      ),
    ]),
    'storm': TableTheme([
      TableThemeEffect(
        section: TableThemeSection.header,
        style: Style().bold().foreground(Colors.sky),
      ),
      TableThemeEffect(
        section: TableThemeSection.body,
        gradient: [Colors.gray900, Colors.gray700, Colors.gray600],
        blendMode: TableBlendMode.screen,
        gradientAxis: TableThemeGradientAxis.horizontal,
      ),
    ]),
  };

  /// Preset names in declaration order.
  static List<String> get names => _presets.keys.toList(growable: false);

  /// All preset values in declaration order.
  static List<TableTheme> get values => _presets.values.toList(growable: false);

  /// Looks up a preset by case-insensitive name.
  ///
  /// Returns [defaultTheme] if [name] is not recognized.
  static TableTheme byName(String name) {
    return _presets[name.toLowerCase()] ?? defaultTheme;
  }

  /// Returns a merged style for the given cell.
  Style? styleForCell({
    required int row,
    required int column,
    required TableThemeSection section,
    required int rowCount,
    required int columnCount,
    required bool hasHeader,
    required bool hasDarkBackground,
  }) {
    if (effects.isEmpty) return null;
    Style? styled;
    for (final effect in effects) {
      final candidate = effect.styleForCell(
        row: row,
        column: column,
        section: section,
        rowCount: rowCount,
        columnCount: columnCount,
        hasHeader: hasHeader,
        hasDarkBackground: hasDarkBackground,
      );
      if (candidate == null) continue;
      if (styled == null) {
        styled = candidate;
      } else {
        styled = styled.copy()..inherit(candidate);
      }
    }
    return styled;
  }

  /// Blends [overlay] onto [base] using [mode].
  static Color applyBlendMode(
    Color base,
    Color overlay,
    TableBlendMode mode, {
    required bool hasDarkBackground,
  }) {
    final baseRgb = _toRgb(base, hasDarkBackground: hasDarkBackground);
    final overlayRgb = _toRgb(overlay, hasDarkBackground: hasDarkBackground);
    if (baseRgb == null || overlayRgb == null) return overlay;

    int blendChannel(int baseChannel, int overlayChannel) => switch (mode) {
      TableBlendMode.normal => overlayChannel,
      TableBlendMode.multiply =>
        ((baseChannel * overlayChannel) / 255.0).round(),
      TableBlendMode.screen =>
        (255.0 - (255.0 - baseChannel) * (255.0 - overlayChannel) / 255.0)
            .round(),
      TableBlendMode.overlay =>
        baseChannel < 128
            ? ((2 * baseChannel * overlayChannel) / 255.0).round()
            : (255.0 -
                      (2 * (255 - baseChannel) * (255 - overlayChannel)) /
                          255.0)
                  .round(),
    };

    final rgb = cp.Rgb(
      blendChannel(baseRgb.r, overlayRgb.r).clamp(0, 255),
      blendChannel(baseRgb.g, overlayRgb.g).clamp(0, 255),
      blendChannel(baseRgb.b, overlayRgb.b).clamp(0, 255),
    );
    return BasicColor(
      '#${rgb.r.toRadixString(16).padLeft(2, '0')}'
      '${rgb.g.toRadixString(16).padLeft(2, '0')}'
      '${rgb.b.toRadixString(16).padLeft(2, '0')}',
    );
  }
}

Color? _sampleGradientCellColor({
  required int row,
  required int column,
  required int rowCount,
  required int columnCount,
  required bool hasHeader,
  required TableThemeGradientAxis axis,
  required bool hasDarkBackground,
  required List<Color> gradientPalette,
}) {
  if (gradientPalette.isEmpty) return null;

  final steps = switch (axis) {
    TableThemeGradientAxis.horizontal => math.max(columnCount, 1),
    TableThemeGradientAxis.vertical => math.max(rowCount, 1),
  };

  final index = switch (axis) {
    TableThemeGradientAxis.horizontal => column,
    TableThemeGradientAxis.vertical => (hasHeader ? (row + 1) : row).clamp(
      0,
      steps - 1,
    ),
  };

  final clampedIndex = index.clamp(0, steps - 1);
  final gradient = blending.blend1D(
    steps,
    gradientPalette,
    hasDarkBackground: hasDarkBackground,
  );
  if (gradient.isEmpty) return null;

  return gradient[clampedIndex];
}

cp.Rgb? _toRgb(Color color, {required bool hasDarkBackground}) {
  switch (color) {
    case NoColor():
      return null;
    case AnsiColor(:final code):
      return cp.ansi256ToRgb(code);
    case BasicColor(:final value):
      return _toRgbFromBasic(value);
    case AdaptiveColor(:final light, :final dark):
      return _toRgb(
        hasDarkBackground ? dark : light,
        hasDarkBackground: hasDarkBackground,
      );
    case CompleteColor(:final trueColor):
      return _toRgb(
        BasicColor(trueColor),
        hasDarkBackground: hasDarkBackground,
      );
    case CompleteAdaptiveColor(:final light, :final dark):
      return _toRgb(
        hasDarkBackground ? dark : light,
        hasDarkBackground: hasDarkBackground,
      );
    default:
      return _toRgbFromBasic(color.toHex());
  }
}

cp.Rgb? _toRgbFromBasic(String value) {
  if (value.startsWith('#')) {
    final normalized = _normalizeHex(value);
    final r = _parseHexChannel(normalized.substring(1, 3));
    final g = _parseHexChannel(normalized.substring(3, 5));
    final b = _parseHexChannel(normalized.substring(5, 7));
    return cp.Rgb(r, g, b);
  }

  final ansiCode = int.tryParse(value);
  if (ansiCode == null) return null;
  return cp.ansi256ToRgb(ansiCode);
}

String _normalizeHex(String value) {
  var hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join('');
  }
  return '#$hex';
}

int _parseHexChannel(String value) => int.tryParse(value, radix: 16) ?? 0;

/// Column alignment options for tables.
enum TableAlign {
  /// Align content to the left (default).
  left,

  /// Align content to the center.
  center,

  /// Align content to the right.
  right,
}

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
  final List<TableAlign> _alignments = [];
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
  TableTheme _theme = TableTheme.defaultTheme;

  // Border visibility flags
  bool _borderTop = true;
  bool _borderBottom = true;
  bool _borderLeft = true;
  bool _borderRight = true;
  bool _borderHeader = true;
  bool _borderColumn = true;
  bool _borderRow = false;

  Style? _styleForCell(
    int row,
    int col,
    String raw,
    int rowCount,
    int columnCount,
    bool hasHeader,
  ) {
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

    final themeStyles = _theme.styleForCell(
      row: row,
      column: col,
      section: row == headerRow
          ? TableThemeSection.header
          : TableThemeSection.body,
      rowCount: rowCount,
      columnCount: columnCount,
      hasHeader: hasHeader,
      hasDarkBackground: _renderConfig.hasDarkBackground,
    );

    if (themeStyles != null) {
      if (s == null) {
        s = themeStyles;
      } else {
        s = themeStyles.copy()..inherit(s);
      }
    }

    if (s != null) {
      return _renderConfig.configureStyle(s);
    }

    return null;
  }

  String _renderCellValue(
    int row,
    int col,
    String raw,
    int rowCount,
    int columnCount,
    bool hasHeader, {
    int? width,
  }) {
    var style = _styleForCell(row, col, raw, rowCount, columnCount, hasHeader);
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

  /// Sets column alignments.
  ///
  /// The list should contain one alignment per column. If fewer alignments
  /// are provided than columns exist, remaining columns default to left.
  ///
  /// Example:
  /// ```dart
  /// table.alignments([TableAlign.left, TableAlign.center, TableAlign.right]);
  /// ```
  Table alignments(List<TableAlign> alignments) {
    _alignments.clear();
    _alignments.addAll(alignments);
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
  /// The function receives `row` (-1 for header), `col`, and `data`,
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

  /// Sets a table theme for the table.
  Table theme(TableTheme theme) {
    _theme = theme;
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
    final hasHeader = _headers.isNotEmpty;
    final rowCount = _rows.length + (hasHeader ? 1 : 0);

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
          final rendered = _renderCellValue(
            rowIndex,
            c,
            raw,
            rowCount,
            columns,
            hasHeader,
          );
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
        final styledContent = _renderCellValue(
          rowIndex,
          c,
          raw,
          rowCount,
          columns,
          hasHeader,
          width: widths[c],
        );

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

          // Apply column alignment
          final align = c < _alignments.length
              ? _alignments[c]
              : TableAlign.left;
          final String cellContent;
          switch (align) {
            case TableAlign.left:
              cellContent = '$pad$line${' ' * fillCount}$pad';
            case TableAlign.center:
              final leftPad = fillCount ~/ 2;
              final rightPad = fillCount - leftPad;
              cellContent = '$pad${' ' * leftPad}$line${' ' * rightPad}$pad';
            case TableAlign.right:
              cellContent = '$pad${' ' * fillCount}$line$pad';
          }
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
