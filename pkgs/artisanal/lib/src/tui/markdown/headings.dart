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
    'h1' => ctx.options.h1Style ?? _defaultH1Style(),
    'h2' => ctx.options.h2Style ?? _defaultH2Style(),
    'h3' => ctx.options.h3Style ?? _defaultH3Style(),
    'h4' => ctx.options.h4Style ?? _defaultH4Style(),
    'h5' => ctx.options.h5Style ?? _defaultH5Style(),
    'h6' => ctx.options.h6Style ?? _defaultH6Style(),
    _ => Style(),
  };
}

Style _defaultH1Style() => Style().bold().foreground(Colors.brightCyan);
Style _defaultH2Style() => Style().bold().foreground(Colors.cyan);
Style _defaultH3Style() => Style().bold().foreground(Colors.blue);
Style _defaultH4Style() => Style().bold();
Style _defaultH5Style() => Style().bold().dim();
Style _defaultH6Style() => Style().dim();
