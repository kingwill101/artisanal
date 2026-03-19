/// Session header widget — shows title, context tokens, and cost.
///
/// Matches the real OpenCode header: left ┃ border, backgroundPanel,
/// `# {title}` on left, `{tokens}  {percentage}% ($cost)` on right.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../theme.dart';

class SessionHeader extends w.StatelessWidget {
  SessionHeader({
    required this.title,
    this.contextTokens = 0,
    this.contextPercentage = 0,
    this.cost = 0.0,
    super.key,
  });

  final String title;
  final int contextTokens;
  final int contextPercentage;
  final double cost;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);

    final contextText = contextTokens > 0
        ? '${_formatTokens(contextTokens)}  $contextPercentage% '
              '(\$${cost.toStringAsFixed(2)})'
        : '';

    return w.Container(
      color: OC.backgroundPanel,
      padding: const w.EdgeInsets.only(left: 2, right: 1, top: 1, bottom: 1),
      child: w.Row(
        children: [
          // Left accent + title
          w.Container(color: theme.border, width: 1),
          w.SizedBox(width: 1),
          w.Text(
            '# $title',
            style: style.Style()
              ..foreground(OC.text)
              ..bold(),
          ),
          w.Spacer(),
          if (contextText.isNotEmpty)
            w.Text(
              contextText,
              style: style.Style()..foreground(OC.textMuted),
              softWrap: false,
            ),
        ],
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(0)},${(tokens % 1000).toString().padLeft(3, '0')}';
    }
    return '$tokens';
  }
}
