import '../../style/style.dart';
import '../../style/color.dart';
import 'render_context.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Heading Rendering
// ─────────────────────────────────────────────────────────────────────────────

void renderHeading(MarkdownRenderContext ctx, String tag) {
  final style = headingStyle(ctx, tag);
  ctx.buffer.write(ctx.styleToAnsi(style));
}

void endHeading(MarkdownRenderContext ctx) {
  ctx.buffer.write(MarkdownRenderContext.ansiReset);
}

Style headingStyle(MarkdownRenderContext ctx, String tag) {
  return switch (tag) {
    'h1' => ctx.options.h1Style ?? defaultH1Style(),
    'h2' => ctx.options.h2Style ?? defaultH2Style(),
    'h3' => ctx.options.h3Style ?? defaultH3Style(),
    'h4' => ctx.options.h4Style ?? defaultH4Style(),
    'h5' => ctx.options.h5Style ?? defaultH5Style(),
    'h6' => ctx.options.h6Style ?? defaultH6Style(),
    _ => Style(),
  };
}

Style defaultH1Style() => Style().bold().foreground(Colors.brightCyan);
Style defaultH2Style() => Style().bold().foreground(Colors.cyan);
Style defaultH3Style() => Style().bold().foreground(Colors.blue);
Style defaultH4Style() => Style().bold();
Style defaultH5Style() => Style().bold().dim();
Style defaultH6Style() => Style().dim();
