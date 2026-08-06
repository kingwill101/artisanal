/// Random tips widget — matches the real OpenCode tips display.
///
/// Shows a random tip with a bullet prefix. Keybinds in the tip
/// text are highlighted.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../theme.dart';

/// A curated selection of tips (subset of the ~100 in the real app).
const _tips = [
  'Press ctrl+p for the command panel',
  'Press ctrl+x then b to toggle the sidebar',
  'Press ctrl+x then l for the session list',
  'Press ctrl+x then m to switch models',
  'Press ctrl+x then t for themes',
  'Press ctrl+x then a for agent overview',
  'Press ctrl+x then d for diff review',
  'Press ctrl+x then n to go home / new session',
  'Type / for slash commands or @ to mention files',
  'Use tab to switch between build and plan',
  'Use up/down arrows for prompt history',
  'Press esc to dismiss dialogs and autocomplete',
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
