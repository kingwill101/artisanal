import 'package:artisanal/style.dart' show Color, Border, Style;
import 'package:artisanal/widgets.dart';

/// Action taken on a [PermissionDock].
enum PermissionAction {
  /// Allow this request once.
  allow,

  /// Remember allow for similar requests.
  always,

  /// Deny the request.
  reject,
}

/// Bottom/session dock for agent permission prompts (OpenCode-style).
///
/// Presentation-only: host wires [onAction] and optional [body] (e.g. a
/// [GitDiffViewer] for edit approvals).
///
/// ```dart
/// PermissionDock(
///   title: 'Edit lib/main.dart',
///   detail: 'Agent wants to apply a patch',
///   body: GitDiffViewer(files: [...]),
///   onAction: (a) { /* reply to agent */ },
/// )
/// ```
class PermissionDock extends StatelessWidget {
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
    super.key,
  });

  /// Short request title (often a path or tool name).
  final String title;

  /// Optional one-line explanation.
  final String? detail;

  /// Optional expanded body (diff, code, metadata).
  final Widget? body;

  /// Which actions to offer (order is preserved).
  final List<PermissionAction> actions;

  /// Invoked when the user activates an action (via host key handling).
  ///
  /// The dock itself is not focus-trapping; use [GestureDetector] on action
  /// chips or handle keys in the host and pass [selectedAction] for highlight.
  final void Function(PermissionAction action)? onAction;

  /// Currently highlighted action (keyboard selection).
  final PermissionAction? selectedAction;

  final Color? background;
  final Color? borderColor;
  final Color? accentColor;
  final Color? dangerColor;
  final Color? mutedColor;

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
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final border = borderColor ?? theme.border;
    final accent = accentColor ?? theme.primary;
    final danger = dangerColor ?? theme.error;
    final muted = mutedColor ?? theme.muted;

    final titleStyle = theme.titleSmall.copy()
      ..foreground(theme.onSurface)
      ..bold();
    final detailStyle = theme.bodySmall.copy()..foreground(muted);

    return Frame(
      background: bg,
      border: Border.rounded,
      borderColor: border,
      padding: const EdgeInsets.all(1),
      child: Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            gap: 1,
            children: [
              Text('permission', style: theme.labelSmall.copy()..foreground(accent)),
              Text('·', style: detailStyle),
              Expanded(
                child: Text(title, style: titleStyle, softWrap: false),
              ),
            ],
          ),
          if (detail != null && detail!.isNotEmpty)
            Text(detail!, style: detailStyle),
          if (body != null) ...[
            Divider(style: Style().foreground(border)),
            body!,
          ],
          Divider(style: Style().foreground(border)),
          Row(
            gap: 2,
            children: [
              for (final action in actions)
                _ActionChip(
                  action: action,
                  selected: selectedAction == action,
                  accent: accent,
                  danger: danger,
                  muted: muted,
                  onTap: onAction == null ? null : () => onAction!(action),
                ),
              Spacer(),
              Text(
                'y allow  a always  n reject',
                style: theme.bodySmall.copy()..foreground(muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  _ActionChip({
    required this.action,
    required this.selected,
    required this.accent,
    required this.danger,
    required this.muted,
    this.onTap,
  });

  final PermissionAction action;
  final bool selected;
  final Color accent;
  final Color danger;
  final Color muted;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final isReject = action == PermissionAction.reject;
    final color = isReject ? danger : accent;
    final label = PermissionDock.labelFor(action);
    final key = PermissionDock.keyHintFor(action);

    final chip = Row(
      gap: 1,
      children: [
        Frame(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          background: selected ? color : muted,
          child: Text(
            key,
            style: theme.labelSmall.copy()
              ..foreground(selected ? theme.onPrimary : theme.onSurface),
          ),
        ),
        Text(
          label,
          style: theme.labelSmall.copy()
            ..foreground(selected ? color : theme.onSurface),
        ),
      ],
    );

    if (onTap == null) return chip;
    return GestureDetector(
      onTap: () {
        onTap!();
        return null;
      },
      child: chip,
    );
  }
}
