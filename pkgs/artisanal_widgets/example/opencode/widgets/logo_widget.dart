/// OpenCode ASCII logo — matches the real OpenCode TUI logo.
///
/// Renders "open code" in block letters with half-block shadow effects.
/// Left half ("open") uses textMuted, right half ("code") uses text (bold).
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../theme.dart';

// The logo halves. Special markers: _ = shadow cell, ^ = upper half with
// shadow below, ~ = shadow upper half only.
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

/// Renders a single logo line with shadow markers replaced.
///
/// Shadow markers:
/// - `_` → space with shadow background
/// - `^` → ▀ (letter color fg, shadow bg)
/// - `~` → ▀ (shadow color fg)
String _renderLine(String line) {
  final buf = StringBuffer();
  for (final ch in line.split('')) {
    if (ch == '_') {
      buf.write(' ');
    } else if (ch == '^') {
      buf.write('\u2580');
    } else if (ch == '~') {
      buf.write('\u2580');
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

/// The OpenCode ASCII art logo.
///
/// Displays "open code" in two halves: left half in muted text,
/// right half in bold bright text. Shadow markers are rendered
/// as half-block characters for a 3D effect.
class LogoWidget extends w.StatelessWidget {
  LogoWidget({super.key});

  @override
  w.Widget build(w.BuildContext context) {
    // Build each logo line as a Row of left + gap + right
    final lines = <w.Widget>[];

    for (var i = 0; i < _left.length; i++) {
      final leftText = _renderLine(_left[i]);
      final rightText = _renderLine(_right[i]);

      lines.add(
        w.Row(
          mainAxisAlignment: w.MainAxisAlignment.center,
          children: [
            w.Text(leftText, style: style.Style()..foreground(OC.textMuted)),
            w.SizedBox(width: 1),
            w.Text(
              rightText,
              style: style.Style()
                ..foreground(OC.text)
                ..bold(),
            ),
          ],
        ),
      );
    }

    return w.Column(gap: 0, children: lines);
  }
}
