import 'dart:math' as math;

import 'package:markdown/markdown.dart';

import '../../style/color.dart';
import '../../style/style.dart';
import 'options.dart';

/// Renders a quote as a container, after laying out its children.
///
/// Every row, including blank separators and code/table borders, belongs to
/// the quote. Keeping the prefix outside child layout avoids wrapping it as
/// content or losing it when a child writes to a different output buffer.
String renderBlockquote(
  Element element,
  AnsiRendererOptions options,
  String Function(List<Node> nodes, AnsiRendererOptions options) renderChildren,
) {
  final quoteStyle = options.blockquoteStyle ?? Style().italic().dim();
  final textStyle = quoteStyle.copy();
  if (options.textStyle != null) {
    textStyle.inherit(options.textStyle!);
  }
  final content = renderChildren(
    element.children ?? const [],
    options.copyWith(
      width: options.width == null ? null : math.max(1, options.width! - 2),
      textStyle: textStyle,
    ),
  );
  if (content.isEmpty) return '';

  final color = options.blockquoteBorderColor ?? Colors.gray;
  final prefix = '${color.toAnsi(ColorProfile.trueColor)}│ \x1b[0m';
  // The final newline terminates the last row; it is not another empty row.
  final body = content.endsWith('\n')
      ? content.substring(0, content.length - 1)
      : content;
  return '${body.split('\n').map((line) => '$prefix$line\x1b[0m').join('\n')}\n';
}
