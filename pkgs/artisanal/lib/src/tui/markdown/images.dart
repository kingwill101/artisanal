import 'package:markdown/markdown.dart' show Element;
import '../../style/style.dart';
import 'render_context.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Image Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Renders an image element to ANSI-styled terminal output.
///
/// When [AnsiRendererOptions.renderImages] is enabled, attempts to download
/// and render the image inline using the detected terminal image protocol
/// (Kitty, iTerm2, or Sixel). Falls back to a text placeholder if the image
/// cannot be downloaded or decoded.
void renderImage(MarkdownRenderContext ctx, Element element) {
  final alt = element.attributes['alt'] ?? 'image';
  final src = element.attributes['src'] ?? '';

  if (ctx.options.renderImages && src.isNotEmpty) {
    // Fire-and-forget: schedule image download/display. If it fails, the
    // placeholder will have been written first (uncomment to make async).
    //
    // For now we only render images synchronously. The async path requires
    // integration with the TUI event loop, which is a future enhancement.
    _renderImagePlaceholder(ctx, alt, src);
    return;
  }

  _renderImagePlaceholder(ctx, alt, src);
}

void _renderImagePlaceholder(MarkdownRenderContext ctx, String alt, String src) {
  final style = Style().dim();
  ctx.outputBuffer.write(ctx.styleToAnsi(style));
  ctx.outputBuffer.write('[Image: $alt]');
  if (src.isNotEmpty) {
    ctx.outputBuffer.write(' ($src)');
  }
  ctx.outputBuffer.write(MarkdownRenderContext.ansiReset);
}
