import 'package:markdown/markdown.dart' show Element, Text;

import '../../style/border.dart' as style_border;
import '../../style/color.dart';
import '../../style/style.dart';
import 'render_context.dart';

Style defaultCodeBlockStyle() => Style().foreground(Colors.brightYellow);

void startCodeBlock(MarkdownRenderContext ctx, Element element) {
  ctx.inCodeBlock = true;
  ctx.codeBlockLanguage = null;

  final codeElement = element.children?.firstWhere(
    (n) => n is Element && n.tag == 'code',
    orElse: () => Text(''),
  );
  if (codeElement is Element) {
    final classes = codeElement.attributes['class']?.split(' ') ?? [];
    for (final cls in classes) {
      if (cls.startsWith('language-')) {
        ctx.codeBlockLanguage = cls.substring(9);
        break;
      }
    }
  }

  if (ctx.options.codeBlockBorder) {
    final border = ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;
    final borderColor = Colors.gray;
    final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);

    if (ctx.codeBlockLanguage != null) {
      ctx.outputBuffer.write(
        '$borderSeq${border.topLeft}${border.top} ${ctx.codeBlockLanguage} '
        '${MarkdownRenderContext.ansiReset}\n',
      );
    } else {
      ctx.outputBuffer.write(
        '$borderSeq${border.topLeft}${border.top}${border.top}${border.top}'
        '${MarkdownRenderContext.ansiReset}\n',
      );
    }
    ctx.outputBuffer.write('$borderSeq${border.left}${MarkdownRenderContext.ansiReset} ');
  }

  if (!ctx.options.syntaxHighlighting || ctx.codeBlockLanguage == null) {
    final style = ctx.options.codeBlockStyle ?? defaultCodeBlockStyle();
    ctx.outputBuffer.write(ctx.styleToAnsi(style));
  }
}

void endCodeBlock(MarkdownRenderContext ctx) {
  if (!ctx.options.syntaxHighlighting || ctx.codeBlockLanguage == null) {
    ctx.outputBuffer.write(MarkdownRenderContext.ansiReset);
  }

  ctx.inCodeBlock = false;
  ctx.codeBlockLanguage = null;

  if (ctx.options.codeBlockBorder) {
    final border = ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;
    final borderColor = Colors.gray;
    final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);
    ctx.outputBuffer.write(
      '\n$borderSeq${border.bottomLeft}${border.bottom}${border.bottom}${border.bottom}'
      '${MarkdownRenderContext.ansiReset}\n',
    );
  } else {
    ctx.outputBuffer.write('\n');
  }
}

String applyCodeBlockPrefix(MarkdownRenderContext ctx, String text) {
  final border = ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;
  final borderColor = Colors.gray;
  final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);
  final prefix = '$borderSeq${border.left}${MarkdownRenderContext.ansiReset} ';

  final useSyntaxHighlighting =
      ctx.options.syntaxHighlighting && ctx.codeBlockLanguage != null;
  final styleSeq = useSyntaxHighlighting
      ? ''
      : ctx.styleToAnsi(ctx.options.codeBlockStyle ?? defaultCodeBlockStyle());

  final lines = text.split('\n');
  return lines.asMap().entries.map((entry) {
    final i = entry.key;
    final line = entry.value;
    if (i == 0) return line;
    return '$prefix$styleSeq$line';
  }).join('\n');
}
