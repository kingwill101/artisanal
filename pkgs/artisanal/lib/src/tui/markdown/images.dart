import 'package:markdown/markdown.dart' show Element;
import '../../style/style.dart';
import 'render_context.dart';


// ─────────────────────────────────────────────────────────────────────────────

// Image Helpers

// ─────────────────────────────────────────────────────────────────────────────



void renderImage(MarkdownRenderContext ctx, Element element) {

  final alt = element.attributes['alt'] ?? 'image';

  final src = element.attributes['src'] ?? '';



  // Render as [Image: alt] (url) in terminal

  final style = Style().dim();

  ctx.outputBuffer.write(ctx.styleToAnsi(style));

  ctx.outputBuffer.write('[Image: $alt]');

  if (src.isNotEmpty) {

    ctx.outputBuffer.write(' ($src)');

  }

  ctx.outputBuffer.write(MarkdownRenderContext.ansiReset);

}



// ─────────────────────────────────────────────────────────────────────────────
