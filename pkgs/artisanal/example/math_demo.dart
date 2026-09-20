/// Minimal markdown math demo.
///
/// The markdown renderer parses the document and automatically renders the
/// delimited math. No direct `renderMath` call is needed.
///
///     dart run pkgs/artisanal/example/math_demo.dart
library;

import 'package:artisanal/markdown.dart';

const _document = r'''
# Markdown math

Inline math: \(E = mc^2\).

Display math:

$$
\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
$$

The markdown parser also handles matrices:

\[
\begin{pmatrix} a & b \\ c & d \end{pmatrix}
\]
''';

void main() {
  final rendered = MarkdownRenderer(
    options: const AnsiRendererOptions(width: 72),
  ).renderToAnsi(_document);
  print(rendered);
}
