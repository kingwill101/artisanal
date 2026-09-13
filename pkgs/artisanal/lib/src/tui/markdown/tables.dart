import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:ultraviolet/rendering.dart' as uv_wrap;

import '../../style/border.dart' as style_border;
import '../../style/style.dart';
import '../../tui/bubbles/components/table.dart' as table_component;
import 'options.dart';
import 'render_context.dart';

/// Parses a Markdown cell alignment, including an unspecified left alignment.
table_component.TableAlign parseTableAlign(String? align) =>
    switch (align?.toLowerCase()) {
      'center' => table_component.TableAlign.center,
      'right' => table_component.TableAlign.right,
      _ => table_component.TableAlign.left,
    };

/// Emits a completed table as an atomic block, not reflowable list-item text.
void renderTable(MarkdownRenderContext ctx) {
  final item = ctx.listItemStack.isEmpty ? null : ctx.listItemStack.last;
  final indent = item?.continuationIndent ?? 0;
  final content = renderTableContent(
    headers: ctx.tableHeaders,
    rows: ctx.tableRows,
    alignments: ctx.tableAlignments,
    options: ctx.options,
    indent: indent,
  );
  if (content.isEmpty) return;
  for (final line in content.split('\n')) {
    ctx.buffer.writeln('${' ' * indent}$line');
  }
  if (item != null) item.hasFlushedContent = true;
  ctx.lastWasBlock = true;
}

/// Lays out Markdown and normalized HTML tables using one width policy.
///
/// The general Table component's width is a minimum, not a maximum, and its
/// headers deliberately do not wrap for Lip Gloss parity. Markdown therefore
/// allocates explicit column widths and wraps styled cells before delegating
/// border/alignment rendering to that component.
///
/// Natural-width tables are unchanged. Constrained tables share the content
/// budget fairly, retaining shorter columns at their natural width. If even
/// the minimum grid cannot fit, labeled fields preserve the data vertically.
String renderTableContent({
  required List<String> headers,
  required List<List<String>> rows,
  required List<table_component.TableAlign> alignments,
  required AnsiRendererOptions options,
  int indent = 0,
}) {
  final columns = rows.fold<int>(
    headers.length,
    (count, row) => math.max(count, row.length),
  );
  if (columns == 0) return '';
  final width = options.width == null
      ? null
      : math.max(1, options.width! - indent);
  final border = options.tableBorder ?? style_border.Border.rounded;
  final headerStyle = options.tableHeaderStyle ?? Style().bold();
  final styledHeaders = headers.isEmpty
      ? <String>[]
      : [
          for (var c = 0; c < columns; c++)
            headerStyle.render(c < headers.length ? headers[c] : ''),
        ];
  final styledRows = [
    for (final row in rows)
      [
        for (var c = 0; c < columns; c++)
          options.tableCellStyle?.render(c < row.length ? row[c] : '') ??
              (c < row.length ? row[c] : ''),
      ],
  ];
  final natural = List<int>.filled(columns, 0);
  final minimum = List<int>.filled(columns, 1);
  for (final row in [
    if (styledHeaders.isNotEmpty) styledHeaders,
    ...styledRows,
  ]) {
    for (var c = 0; c < columns; c++) {
      for (final line in row[c].split('\n')) {
        natural[c] = math.max(natural[c], Style.visibleLength(line));
      }
      for (final grapheme in Style.stripAnsi(row[c]).characters) {
        minimum[c] = math.max(minimum[c], Style.visibleLength(grapheme));
      }
    }
  }

  var padding = 1;
  var widths = List<int>.of(natural);
  String grid(List<String> header, List<List<String>> body) {
    final table = table_component.Table()
      ..headers(header)
      ..rows(body)
      ..widths(widths)
      ..alignments(alignments)
      ..border(border)
      ..padding(padding)
      ..wrap(false)
      // Styles were applied before measuring and wrapping, exactly once.
      ..headerStyle(Style())
      ..cellStyle(Style());
    if (options.tableBorderStyle != null) {
      table.borderStyle(options.tableBorderStyle!);
    }
    return table.render();
  }

  // Table renders vertical column separators with border.left.
  final edgeWidth = border == style_border.Border.none
      ? 0
      : _maximumGlyphWidth([border.left, border.topLeft, border.bottomLeft]) +
            _maximumGlyphWidth([
              border.right,
              border.topRight,
              border.bottomRight,
            ]) +
            (columns - 1) *
                _maximumGlyphWidth([
                  border.left,
                  border.middleTop ?? border.top,
                  border.middle ?? border.top,
                  border.middleBottom ?? border.bottom,
                ]);
  final naturalWidth =
      natural.fold<int>(0, (sum, value) => sum + value) +
      edgeWidth +
      padding * 2 * columns;
  if (width == null) return grid(styledHeaders, styledRows);
  if (naturalWidth <= width) {
    final original = grid(styledHeaders, styledRows);
    if (_maximumLineWidth(original) <= width) return original;
  }
  // Do not build a potentially enormous natural-width grid just to find out
  // that it cannot fit. Narrow layout allocates before padding every row.
  final minimumContent = minimum.fold<int>(0, (sum, value) => sum + value);
  if (width - edgeWidth - padding * 2 * columns < minimumContent) padding = 0;
  final available = width - edgeWidth - padding * 2 * columns;
  if (available < minimumContent) {
    return _stackedFields(styledHeaders, styledRows, width);
  }
  widths = _allocateWidths(natural, minimum, available);
  String wrap(String text, int column) =>
      uv_wrap.wrapAnsiPreserving(text, widths[column]);
  final result = grid(
    [for (var c = 0; c < styledHeaders.length; c++) wrap(styledHeaders[c], c)],
    [
      for (final row in styledRows)
        [for (var c = 0; c < columns; c++) wrap(row[c], c)],
    ],
  );
  // Custom multi-cell border glyphs or border styles may themselves require
  // more room. Do not quietly clip data to accommodate decoration.
  return _maximumLineWidth(result) <= width
      ? result
      : _stackedFields(styledHeaders, styledRows, width);
}

int _maximumGlyphWidth(List<String> glyphs) => glyphs.fold<int>(
  0,
  (max, glyph) => math.max(max, Style.visibleLength(glyph)),
);

int _maximumLineWidth(String text) => _maximumGlyphWidth(text.split('\n'));

List<int> _allocateWidths(List<int> natural, List<int> minimum, int available) {
  final widths = List<int>.of(minimum);
  var remaining = available - widths.fold<int>(0, (sum, w) => sum + w);
  // Grow a common waterline in batches. Work depends on the column count,
  // not on arbitrarily long cell content or a very large requested width.
  while (remaining > 0) {
    final active = [
      for (var c = 0; c < widths.length; c++)
        if (widths[c] < natural[c]) c,
    ];
    if (active.isEmpty) break;
    final share = math.max(1, remaining ~/ active.length);
    for (final c in active) {
      final growth = math.min(
        remaining,
        math.min(share, natural[c] - widths[c]),
      );
      widths[c] += growth;
      remaining -= growth;
      if (remaining == 0) break;
    }
  }
  return widths;
}

String _stackedFields(
  List<String> headers,
  List<List<String>> rows,
  int width,
) {
  if (rows.isEmpty) {
    return headers
        .map((text) => uv_wrap.wrapAnsiPreserving(text, width))
        .join('\n');
  }
  return rows
      .map(
        (row) => [
          for (var c = 0; c < row.length; c++)
            uv_wrap.wrapAnsiPreserving(
              '${headers.isEmpty || Style.stripAnsi(headers[c]).isEmpty ? 'Column ${c + 1}' : headers[c]}: ${row[c]}',
              width,
            ),
        ].join('\n'),
      )
      .join('\n\n');
}
