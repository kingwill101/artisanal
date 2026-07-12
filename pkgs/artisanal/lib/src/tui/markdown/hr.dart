import '../../style/style.dart';
import 'render_context.dart';

// ─────────────────────────────────────────────────────────────────────────────

// Horizontal Rule

// ─────────────────────────────────────────────────────────────────────────────

void renderHorizontalRule(MarkdownRenderContext ctx) {
  final width = ctx.options.hrWidth ?? ctx.options.width ?? 40;

  final line = ctx.options.hrChar * width;

  final dimStyle = Style().dim();

  ctx.outputBuffer.write(ctx.styleToAnsi(dimStyle));

  ctx.outputBuffer.write(line);

  ctx.outputBuffer.write(MarkdownRenderContext.ansiReset);

  ctx.outputBuffer.write('\n');

  ctx.lastWasBlock = true;
}

// ─────────────────────────────────────────────────────────────────────────────
