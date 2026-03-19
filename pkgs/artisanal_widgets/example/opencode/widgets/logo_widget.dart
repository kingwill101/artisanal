/// OpenCode ASCII logo using marker-based shadow rendering.
///
/// This mirrors OpenCode's logo approach: glyph shapes are hardcoded and
/// special markers in the logo source control per-cell shadow styling.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../theme.dart';

const _left = [
  '                   ',
  '\u2588\u2580\u2580\u2588 \u2588\u2580\u2580\u2588 \u2588\u2580\u2580\u2588 \u2588\u2580\u2580\u2584',
  '\u2588__\u2588 \u2588__\u2588 \u2588^^^ \u2588__\u2588',
  '\u2580\u2580\u2580\u2580 \u2588\u2580\u2580\u2580 \u2580\u2580\u2580\u2580 \u2580~~\u2580',
];

const _right = [
  '             \u2584     ',
  '\u2588\u2580\u2580\u2580 \u2588\u2580\u2580\u2588 \u2588\u2580\u2580\u2588 \u2588\u2580\u2580\u2588',
  '\u2588___ \u2588__\u2588 \u2588__\u2588 \u2588^^^',
  '\u2580\u2580\u2580\u2580 \u2580\u2580\u2580\u2580 \u2580\u2580\u2580\u2580 \u2580\u2580\u2580\u2580',
];

const _marks = '_^~';

style.Color _tint(style.Color base, style.Color target, double ratio) {
  final baseHex = base.toHex();
  final targetHex = target.toHex();
  if (baseHex.isEmpty || targetHex.isEmpty) return OC.shadow;

  int channel(String hex, int offset) =>
      int.parse(hex.substring(offset, offset + 2), radix: 16);

  int mix(int b, int t) => (b + (t - b) * ratio).round().clamp(0, 255);

  final r = mix(channel(baseHex, 1), channel(targetHex, 1));
  final g = mix(channel(baseHex, 3), channel(targetHex, 3));
  final b = mix(channel(baseHex, 5), channel(targetHex, 5));

  final hex =
      '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
  return style.BasicColor(hex);
}

style.Style _logoStyle(style.Color fg, {required bool bold}) {
  final s = style.Style()..foreground(fg);
  if (bold) s.bold();
  return s;
}

List<w.TextSpan> _renderLineSpans(
  String line,
  style.Color fg,
  style.Color shadow, {
  required bool bold,
}) {
  final normal = _logoStyle(fg, bold: bold);
  final topShadow = _logoStyle(shadow, bold: bold);
  final mixedShadow = _logoStyle(fg, bold: bold)..background(shadow);

  final spans = <w.TextSpan>[];
  final plain = StringBuffer();

  void flushPlain() {
    if (plain.isEmpty) return;
    spans.add(w.TextSpan(text: plain.toString(), style: normal.copy()));
    plain.clear();
  }

  for (final ch in line.split('')) {
    if (!_marks.contains(ch)) {
      plain.write(ch);
      continue;
    }

    flushPlain();

    if (ch == '_') {
      spans.add(w.TextSpan(text: ' ', style: mixedShadow.copy()));
      continue;
    }
    if (ch == '^') {
      spans.add(w.TextSpan(text: '\u2580', style: mixedShadow.copy()));
      continue;
    }
    spans.add(w.TextSpan(text: '\u2580', style: topShadow.copy()));
  }

  flushPlain();
  return spans;
}

class LogoWidget extends w.StatelessWidget {
  LogoWidget({super.key});

  @override
  w.Widget build(w.BuildContext context) {
    final leftShadow = _tint(OC.background, OC.textMuted, 0.25);
    final rightShadow = _tint(OC.background, OC.text, 0.25);

    final lines = <w.Widget>[];
    for (var i = 0; i < _left.length; i++) {
      final leftSpan = w.TextSpan(
        children: _renderLineSpans(
          _left[i],
          OC.textMuted,
          leftShadow,
          bold: false,
        ),
      );
      final rightSpan = w.TextSpan(
        children: _renderLineSpans(_right[i], OC.text, rightShadow, bold: true),
      );

      lines.add(
        w.Row(
          mainAxisAlignment: w.MainAxisAlignment.center,
          children: [
            w.Text.rich(leftSpan, softWrap: false),
            w.SizedBox(width: 1),
            w.Text.rich(rightSpan, softWrap: false),
          ],
        ),
      );
    }

    return w.Column(gap: 0, children: lines);
  }
}
