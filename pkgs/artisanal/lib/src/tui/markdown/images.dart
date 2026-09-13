import 'package:image/image.dart' as img;
import 'package:markdown/markdown.dart' show Element;

import '../../style/style.dart';
import 'image_renderer.dart'
    show
        ImageProtocol,
        detectImageProtocol,
        imageCellDimensions,
        renderImageToAnsi;
import 'render_context.dart';
import 'github_images.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Image Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Renders an image element to ANSI-styled terminal output.
///
/// When [AnsiRendererOptions.renderImages] is enabled and the image URL is
/// present in [MarkdownRenderContext.imageCache], the image is decoded and
/// displayed inline using the detected terminal image protocol (Kitty, iTerm2,
/// or Sixel). Falls back to a text placeholder if the image cannot be loaded.
void renderImage(MarkdownRenderContext ctx, Element element) {
  final alt = element.attributes['alt'] ?? 'image';
  final src = element.attributes['src'] ?? '';
  final linked =
      ctx.elementStack.length > 1 &&
      ctx.elementStack[ctx.elementStack.length - 2].tag == 'a';
  if (!githubImageVariantVisible(
    src,
    hasDarkBackground: ctx.options.hasDarkBackground,
  )) {
    return;
  }

  if (ctx.options.renderImages && src.isNotEmpty) {
    final key = githubImageCacheKey(src);
    final bytes = ctx.imageCache[src] ?? ctx.imageCache[key];
    if (bytes != null) {
      final image = img.decodeImage(bytes);
      if (image != null) {
        _renderTerminalImage(ctx, image);
        return;
      }
    }
  }

  _renderImagePlaceholder(ctx, alt, githubImageCacheKey(src), linked: linked);
}

void _renderTerminalImage(MarkdownRenderContext ctx, img.Image image) {
  final protocol = ctx.options.imageProtocol ?? detectImageProtocol();
  if (protocol == ImageProtocol.none) {
    ctx.outputBuffer.write('[Image: ${image.width}x${image.height}px]');
    return;
  }

  final (cols, rows) = imageCellDimensions(
    image,
    maxColumns: ctx.options.imageMaxWidth,
    maxRows: ctx.options.imageMaxHeight,
  );
  final escaped = renderImageToAnsi(image, protocol, columns: cols, rows: rows);
  if (escaped != null) {
    ctx.outputBuffer.write(escaped);
  } else {
    ctx.outputBuffer.write('[Image: ${image.width}x${image.height}px]');
  }
}

void _renderImagePlaceholder(
  MarkdownRenderContext ctx,
  String alt,
  String src, {
  bool linked = false,
}) {
  final style = Style().dim();
  ctx.outputBuffer.write(ctx.styleToAnsi(style));
  ctx.outputBuffer.write('[Image: $alt]');
  // A linked image already has its destination in the surrounding OSC 8
  // sequence. Repeating the SVG URL makes GitHub review buttons unreadable.
  if (src.isNotEmpty && !linked) {
    ctx.outputBuffer.write(' ($src)');
  }
  ctx.outputBuffer.write(MarkdownRenderContext.ansiReset);
}
