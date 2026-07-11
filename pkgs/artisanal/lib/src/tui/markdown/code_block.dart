import 'package:markdown/markdown.dart' show Element, Text;
import '../../style/border.dart' as style_border;
import '../../style/style.dart';
import '../../style/color.dart';
import 'render_context.dart';


Style defaultCodeBlockStyle() => Style().foreground(Colors.brightYellow);

// ─────────────────────────────────────────────────────────────────────────────

// Code Block Helpers

// ─────────────────────────────────────────────────────────────────────────────



void startCodeBlock(MarkdownRenderContext ctx, Element element) {

  ctx.inCodeBlock = true;

  ctx.codeBlockLanguage = null;



  // Get the language hint if available

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

    // Get the border style (default to rounded)

    final border =

        ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;

    final borderColor = Colors.gray;

    final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);



    if (ctx.codeBlockLanguage != null) {

      ctx.buffer.write(

        '$borderSeq${border.topLeft}${border.top} $ctx.codeBlockLanguage $MarkdownRenderContext.ansiReset\n',

      );

    } else {

      ctx.buffer.write(

        '$borderSeq${border.topLeft}${border.top}${border.top}${border.top}$MarkdownRenderContext.ansiReset\n',

      );

    }

    ctx.buffer.write('$borderSeq${border.left}$MarkdownRenderContext.ansiReset ');

  }



  // Only apply default code style if syntax highlighting is disabled

  // or if no language is specified

  if (!ctx.options.syntaxHighlighting || ctx.codeBlockLanguage == null) {

    final style = ctx.options.codeBlockStyle ?? defaultCodeBlockStyle();

    ctx.buffer.write(ctx.styleToAnsi(style));

  }

}



void endCodeBlock(MarkdownRenderContext ctx) {

  // Only close style if we opened it (no syntax highlighting)

  if (!ctx.options.syntaxHighlighting || ctx.codeBlockLanguage == null) {

    ctx.buffer.write(MarkdownRenderContext.ansiReset);

  }

  ctx.inCodeBlock = false;

  ctx.codeBlockLanguage = null;



  if (ctx.options.codeBlockBorder) {

    final border =

        ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;

    final borderColor = Colors.gray;

    final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);

    // Close the last line and draw bottom border

    ctx.buffer.write(

      '\n$borderSeq${border.bottomLeft}${border.bottom}${border.bottom}${border.bottom}$MarkdownRenderContext.ansiReset\n',

    );

  } else {

    ctx.buffer.write('\n');

  }

}



/// Applies the code block border prefix to each line of content.

String applyCodeBlockPrefix(MarkdownRenderContext ctx, String text) {

  final border = ctx.options.codeBlockBorderStyle ?? style_border.Border.rounded;

  final borderColor = Colors.gray;

  final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);

  final prefix = '$borderSeq${border.left}$MarkdownRenderContext.ansiReset ';



  // Only re-apply code style if syntax highlighting is not active

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

        if (i == 0) {

          return line; // First line already has prefix from _startCodeBlock

        }

        // For subsequent lines, add border prefix and optionally re-apply code style

        return '$prefix$styleSeq$line';

      })

      .join('\n');

}



// ─────────────────────────────────────────────────────────────────────────────
