/// OpenCode example-local permission dock (not a framework API).
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

/// Action taken on a [PermissionDock].
enum PermissionAction {
  allow,
  always,
  reject,
}

/// Bottom/session dock for agent permission prompts (OpenCode-style).
///
/// Layout adapts to width:
/// - header stacks on narrow terminals
/// - action chips + key hints wrap instead of overflowing
/// - title/detail soft-wrap
class PermissionDock extends w.StatelessWidget {
  PermissionDock({
    required this.title,
    this.detail,
    this.body,
    this.actions = const [
      PermissionAction.allow,
      PermissionAction.always,
      PermissionAction.reject,
    ],
    this.onAction,
    this.selectedAction,
    this.background,
    this.borderColor,
    this.accentColor,
    this.dangerColor,
    this.mutedColor,
    this.narrowBreakpoint = 56,
    super.key,
  });

  final String title;
  final String? detail;
  final w.Widget? body;
  final List<PermissionAction> actions;
  final void Function(PermissionAction action)? onAction;
  final PermissionAction? selectedAction;
  final style.Color? background;
  final style.Color? borderColor;
  final style.Color? accentColor;
  final style.Color? dangerColor;
  final style.Color? mutedColor;

  /// Width at or below which header/actions stack more aggressively.
  final int narrowBreakpoint;

  static String labelFor(PermissionAction action) => switch (action) {
    PermissionAction.allow => 'allow',
    PermissionAction.always => 'always',
    PermissionAction.reject => 'reject',
  };

  static String keyHintFor(PermissionAction action) => switch (action) {
    PermissionAction.allow => 'y',
    PermissionAction.always => 'a',
    PermissionAction.reject => 'n',
  };

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final border = borderColor ?? theme.border;
    final accent = accentColor ?? theme.primary;
    final danger = dangerColor ?? theme.error;
    final muted = mutedColor ?? theme.muted;

    final titleStyle = theme.titleSmall.copy()
      ..foreground(theme.onSurface)
      ..bold();
    final detailStyle = theme.bodySmall.copy()..foreground(muted);
    final labelStyle = theme.labelSmall.copy()..foreground(accent);

    return w.LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (w.MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);
        final narrow = width <= narrowBreakpoint;

        return w.Frame(
          background: bg,
          border: style.Border.rounded,
          borderColor: border,
          padding: const w.EdgeInsets.all(1),
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(
                narrow: narrow,
                labelStyle: labelStyle,
                titleStyle: titleStyle,
                detailStyle: detailStyle,
              ),
              if (detail != null && detail!.isNotEmpty)
                w.Text(detail!, style: detailStyle, softWrap: true),
              if (body != null) ...[
                w.Divider(style: style.Style().foreground(border)),
                body!,
              ],
              w.Divider(style: style.Style().foreground(border)),
              _buildActionBar(
                theme: theme,
                narrow: narrow,
                accent: accent,
                danger: danger,
                muted: muted,
              ),
            ],
          ),
        );
      },
    );
  }

  w.Widget _buildHeader({
    required bool narrow,
    required style.Style labelStyle,
    required style.Style titleStyle,
    required style.Style detailStyle,
  }) {
    final badge = w.Text('permission', style: labelStyle);
    final titleText = w.Text(title, style: titleStyle, softWrap: true);

    if (narrow) {
      return w.Column(
        gap: 0,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          badge,
          titleText,
        ],
      );
    }

    return w.Row(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.start,
      children: [
        badge,
        w.Text('·', style: detailStyle),
        w.Expanded(child: titleText),
      ],
    );
  }

  w.Widget _buildActionBar({
    required w.Theme theme,
    required bool narrow,
    required style.Color accent,
    required style.Color danger,
    required style.Color muted,
  }) {
    final chips = <w.Widget>[
      for (final action in actions)
        _ActionChip(
          action: action,
          selected: selectedAction == action,
          accent: accent,
          danger: danger,
          muted: muted,
          compact: narrow,
          onTap: onAction == null ? null : () => onAction!(action),
        ),
    ];

    final hints = w.Text(
      actions
          .map((a) => '${keyHintFor(a)} ${labelFor(a)}')
          .join(narrow ? '  ' : '  '),
      style: theme.bodySmall.copy()..foreground(muted),
      softWrap: true,
    );

    // Always wrap chips; put hints on a second line when narrow or always
    // below so they never fight for space with buttons.
    return w.Column(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Wrap(
          spacing: 2,
          runSpacing: 1,
          children: chips,
        ),
        hints,
      ],
    );
  }
}

class _ActionChip extends w.StatelessWidget {
  _ActionChip({
    required this.action,
    required this.selected,
    required this.accent,
    required this.danger,
    required this.muted,
    this.compact = false,
    this.onTap,
  });

  final PermissionAction action;
  final bool selected;
  final style.Color accent;
  final style.Color danger;
  final style.Color muted;
  final bool compact;
  final void Function()? onTap;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final isReject = action == PermissionAction.reject;
    final color = isReject ? danger : accent;
    final label = PermissionDock.labelFor(action);
    final key = PermissionDock.keyHintFor(action);

    final chip = w.Frame(
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      background: selected ? color : null,
      border: style.Border.rounded,
      borderColor: selected ? color : muted,
      child: w.Row(
        gap: 1,
        children: [
          w.Text(
            key,
            style: theme.labelSmall.copy()
              ..foreground(selected ? theme.onPrimary : theme.onSurface)
              ..bold(),
          ),
          if (!compact || selected)
            w.Text(
              label,
              style: theme.labelSmall.copy()
                ..foreground(selected ? theme.onPrimary : theme.onSurface),
            ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return w.GestureDetector(
      onTap: () {
        onTap!();
        return null;
      },
      child: chip,
    );
  }
}
