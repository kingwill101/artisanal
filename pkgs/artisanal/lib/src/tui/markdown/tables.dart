import 'dart:math' as math;
import 'package:markdown/markdown.dart' show Element;
import '../../style/border.dart' as style_border;
import '../../style/style.dart';
import '../../tui/bubbles/components/table.dart' as table_component;
import 'render_context.dart';


// ─────────────────────────────────────────────────────────────────────────────

// Table Helpers

// ─────────────────────────────────────────────────────────────────────────────



/// Parses a markdown alignment string to [TableAlign].

table_component.TableAlign parseTableAlign(String align) {

  return switch (align.toLowerCase()) {

    'left' => table_component.TableAlign.left,

    'center' => table_component.TableAlign.center,

    'right' => table_component.TableAlign.right,

    _ => table_component.TableAlign.left,

  };

}



/// Renders the collected table using artisanal's Table component.

void renderTable(MarkdownRenderContext ctx) {

  if (ctx.tableHeaders.isEmpty && ctx.tableRows.isEmpty) return;



  final table = table_component.Table()

    ..headers(ctx.tableHeaders)

    ..rows(ctx.tableRows)

    ..border(ctx.options.tableBorder ?? style_border.Border.rounded)

    ..padding(1)

    ..wrap(false); // Disable wrapping to preserve content



  // Apply column alignments if any were specified

  if (ctx.tableAlignments.isNotEmpty) {

    table.alignments(ctx.tableAlignments);

  }



  // Apply header style if specified

  if (ctx.options.tableHeaderStyle != null) {

    table.headerStyle(ctx.options.tableHeaderStyle!);

  } else {

    // Default: bold headers

    table.headerStyle(Style().bold());

  }



  // Apply cell style if specified

  if (ctx.options.tableCellStyle != null) {

    table.cellStyle(ctx.options.tableCellStyle!);

  }



  // Apply border style if specified

  if (ctx.options.tableBorderStyle != null) {

    table.borderStyle(ctx.options.tableBorderStyle!);

  }



  ctx.buffer.write(table.render());

  ctx.buffer.write('\n');

}



// ─────────────────────────────────────────────────────────────────────────────
