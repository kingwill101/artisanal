/// Random tips widget — matches the real OpenCode tips display.
///
/// Shows a random tip with a bullet prefix. Keybinds in the tip
/// text are highlighted.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../theme.dart';

/// A curated selection of tips (subset of the ~100 in the real app).
const _tips = [
  'Press ctrl+p to open the command palette',
  'Press ctrl+b to toggle the sidebar',
  'Press ctrl+l to view your session list',
  'Press ctrl+n to start a new session',
  'Use @ to mention files in your prompt',
  'Start with ! for shell mode — run commands directly',
  'Press ctrl+k to switch models mid-conversation',
  'Use tab to switch between agents',
  'Type / for slash command autocomplete',
  'Press ctrl+x e to open an external editor',
  'Use up/down arrows to navigate prompt history',
  'Press esc twice to interrupt a running response',
  'Click on a user message to see message actions',
  'Use ctrl+x f to fork from any message',
  'Press ctrl+x t to open the timeline',
];

/// Displays a random tip with a bullet prefix.
///
/// The tip changes each time the widget is rebuilt (e.g., on route change).
class TipsWidget extends w.StatelessWidget {
  TipsWidget({this.tipIndex, super.key});

  /// If provided, uses this index instead of a random one.
  final int? tipIndex;

  @override
  w.Widget build(w.BuildContext context) {
    final index =
        tipIndex ??
        (DateTime.now().millisecondsSinceEpoch ~/ 10000) % _tips.length;
    final tip = _tips[index % _tips.length];

    return w.Row(
      mainAxisAlignment: w.MainAxisAlignment.center,
      children: [
        w.Text('\u25cf', style: style.Style()..foreground(OC.textMuted)),
        w.SizedBox(width: 1),
        w.Text(
          'Tip',
          style: style.Style()
            ..foreground(OC.textMuted)
            ..bold(),
        ),
        w.SizedBox(width: 1),
        w.Text(tip, style: style.Style()..foreground(OC.textMuted)),
      ],
    );
  }
}
