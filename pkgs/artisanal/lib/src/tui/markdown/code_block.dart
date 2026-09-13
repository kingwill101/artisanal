import 'package:markdown/markdown.dart' show Element, Text;

import '../../style/border.dart' as style_border;
import '../../style/color.dart';
import '../../style/style.dart';
import 'package:ultraviolet/rendering.dart' as uv_wrap;
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
    final border =
        ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;
    final borderColor = Colors.gray;
    final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);

    if (ctx.inBlockquote) {
      ctx.outputBuffer.write('\n${renderBlockquotePrefixOnly(ctx)}');
    }

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
    ctx.outputBuffer.write(
      '$borderSeq${border.left}${MarkdownRenderContext.ansiReset} ',
    );
  }

  if (!ctx.options.syntaxHighlighting || ctx.codeBlockLanguage == null) {
    final style = ctx.options.codeBlockStyle ?? defaultCodeBlockStyle();
    ctx.outputBuffer.write(ctx.styleToAnsi(style));
  }
}

void endCodeBlock(MarkdownRenderContext ctx) {
  // Highlighted tokens can span the final physical line too.
  ctx.outputBuffer.write(MarkdownRenderContext.ansiReset);

  ctx.inCodeBlock = false;
  ctx.codeBlockLanguage = null;

  if (ctx.options.codeBlockBorder) {
    final border =
        ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;
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
  final border =
      ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;
  final borderColor = Colors.gray;
  final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);
  final prefix = '$borderSeq${border.left}${MarkdownRenderContext.ansiReset} ';

  final useSyntaxHighlighting =
      ctx.options.syntaxHighlighting && ctx.codeBlockLanguage != null;
  final styleSeq = useSyntaxHighlighting
      ? ''
      : ctx.styleToAnsi(ctx.options.codeBlockStyle ?? defaultCodeBlockStyle());

  final lines = text.split('\n');
  return lines
      .asMap()
      .entries
      .map((entry) {
        final i = entry.key;
        final line = entry.value;
        if (i == 0) return line;
        return '$prefix$styleSeq$line';
      })
      .join('\n');
}

/// Balances ANSI state at physical code lines.
///
/// Newlines do not reset a terminal's current pen. Keep code backgrounds and
/// attributes confined to their row while allowing the normal border prefix
/// or plain block style to start the next row again.
String balanceCodeBlockNewlines(
  MarkdownRenderContext ctx,
  String text, {
  required bool highlighted,
}) {
  final initialStyle = !highlighted
      ? ctx.styleToAnsi(ctx.options.codeBlockStyle ?? defaultCodeBlockStyle())
      : '';
  return balanceAnsiNewlines(text, initialStyle: initialStyle);
}

/// Keeps the ANSI pen state active on both sides of physical line breaks.
///
/// [initialStyle] seeds the state for a plainly styled block. Border prefixes
/// reset the pen before each gutter, and the code style is then reopened.
String balanceAnsiNewlines(String text, {required String initialStyle}) {
  if (!text.contains('\n')) return text;
  final seeded = '$initialStyle$text';
  final balanced = uv_wrap.wrapAnsiPreserving(seeded, 1 << 30);
  if (initialStyle.isNotEmpty && balanced.startsWith(initialStyle)) {
    return balanced.substring(initialStyle.length);
  }
  return balanced;
}

String renderBlockquotePrefixOnly(MarkdownRenderContext ctx) {
  final color = ctx.options.blockquoteBorderColor;
  final depth = ctx.blockquoteDepth;
  if (color == null) {
    return '${'│' * depth} ';
  }
  final seq = color.toAnsi(ColorProfile.trueColor);
  return '$seq${'│' * depth} ${MarkdownRenderContext.ansiReset}';
}
