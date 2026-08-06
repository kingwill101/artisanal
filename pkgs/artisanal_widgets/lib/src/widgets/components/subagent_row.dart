/// Subagent / nested task row (OpenCode session child chrome).
library;

import 'package:artisanal/style.dart' show Color, Border;

import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart';
import '../layout/layout.dart';
import '../theme/theme_scope.dart' show ThemeScope;
import 'frame.dart' show Frame;

/// Lifecycle for a [SubagentRow].
enum SubagentStatus {
  pending,
  running,
  completed,
  error,
}

/// One nested agent / task line for session footers or task lists.
class SubagentRow extends StatelessWidget {
  SubagentRow({
    required this.title,
    this.status = SubagentStatus.running,
    this.index,
    this.total,
    this.detail,
    this.agentLabel,
    this.onOpen,
    this.accentColor,
    this.mutedColor,
    this.errorColor,
    this.background,
    this.borderColor,
    super.key,
  });

  final String title;
  final SubagentStatus status;

  /// 1-based index among siblings (optional).
  final int? index;
  final int? total;

  /// Secondary line (tokens, cost, path…).
  final String? detail;

  /// e.g. "Explore", "Code".
  final String? agentLabel;

  final void Function()? onOpen;
  final Color? accentColor;
  final Color? mutedColor;
  final Color? errorColor;
  final Color? background;
  final Color? borderColor;

  String get _statusGlyph => switch (status) {
    SubagentStatus.pending => '○',
    SubagentStatus.running => '◉',
    SubagentStatus.completed => '✓',
    SubagentStatus.error => '✗',
  };

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final muted = mutedColor ?? theme.muted;
    final err = errorColor ?? theme.error;
    final accent = accentColor ?? theme.primary;
    final statusColor = switch (status) {
      SubagentStatus.pending => muted,
      SubagentStatus.running => accent,
      SubagentStatus.completed => theme.success,
      SubagentStatus.error => err,
    };
    final bg = background ?? theme.surface;
    final border = borderColor ?? theme.border;

    final indexLabel = (index != null && total != null && total! > 0)
        ? '$index/$total'
        : (index != null ? '#$index' : null);

    final body = Column(
      gap: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          gap: 1,
          children: [
            Text(
              _statusGlyph,
              style: theme.labelSmall.copy()..foreground(statusColor),
            ),
            if (agentLabel != null && agentLabel!.isNotEmpty)
              Text(
                agentLabel!,
                style: theme.labelSmall.copy()
                  ..foreground(accent)
                  ..bold(),
              ),
            Expanded(
              child: Text(
                title,
                style: theme.bodySmall.copy()..foreground(theme.onSurface),
                softWrap: false,
              ),
            ),
            if (indexLabel != null)
              Text(
                indexLabel,
                style: theme.labelSmall.copy()..foreground(muted),
              ),
          ],
        ),
        if (detail != null && detail!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              detail!,
              style: theme.bodySmall.copy()..foreground(muted),
              softWrap: false,
            ),
          ),
      ],
    );

    final framed = Frame(
      background: bg,
      border: Border.rounded,
      borderColor: border,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: body,
    );

    if (onOpen == null) return framed;
    return GestureDetector(
      onTap: () {
        onOpen!();
        return null;
      },
      child: framed,
    );
  }
}
