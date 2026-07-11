import '../../style/style.dart';
import '../../style/color.dart';
import 'render_context.dart';


// ─────────────────────────────────────────────────────────────────────────────

// Horizontal Rule

// ─────────────────────────────────────────────────────────────────────────────



void _renderHorizontalRule(MarkdownRenderContext ctx) {

  final width = ctx.options.hrWidth ?? ctx.options.width ?? 40;

  final line = ctx.options.hrChar * width;

  final dimStyle = Style().dim();

  ctx.buffer.write(ctx.styleToAnsi(dimStyle));

  ctx.buffer.write(line);

  ctx.buffer.write(MarkdownRenderContext.ansiReset);

  ctx.buffer.write('\n');

  ctx.lastWasBlock = true;

}



// ─────────────────────────────────────────────────────────────────────────────
