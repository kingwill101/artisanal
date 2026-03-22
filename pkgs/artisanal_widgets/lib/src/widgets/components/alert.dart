part of 'components_widgets.dart';

enum AlertVariant { info, success, warning, error, neutral }

class AlertBox extends StatelessWidget {
  AlertBox({
    this.title,
    this.message,
    this.child,
    this.variant = AlertVariant.info,
    this.padding,
    this.margin,
    this.border,
    this.actions = const [],
    super.key,
  });

  final String? title;
  final String? message;
  final Widget? child;
  final AlertVariant variant;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Border? border;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final accent = _accentFor(theme);

    final markerStyle = _copyStyle(theme.labelMedium)
      ..foreground(accent)
      ..bold();
    final titleStyle = _copyStyle(theme.titleSmall)
      ..foreground(theme.onSurface)
      ..bold();
    final bodyStyle = _copyStyle(theme.bodyMedium)..foreground(theme.onSurface);

    final header = title == null ? null : Text(title!, style: titleStyle);
    final content = child ?? Text(message ?? '', style: bodyStyle);

    final body = Column(
      gap: (header != null && (message != null || child != null)) ? 1 : 0,
      children: [?header, content],
    );

    final row = Row(
      gap: 1,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_markerFor(), style: markerStyle),
        Expanded(child: body),
        if (actions.isNotEmpty) Row(gap: 1, children: actions),
      ],
    );

    return Frame(
      padding: padding ?? const EdgeInsets.all(1),
      margin: margin,
      background: theme.surface,
      border: border ?? Border.normal,
      borderColor: accent,
      child: row,
    );
  }

  Color _accentFor(Theme theme) {
    return switch (variant) {
      AlertVariant.info => theme.primary,
      AlertVariant.success => theme.success,
      AlertVariant.warning => theme.warning,
      AlertVariant.error => theme.error,
      AlertVariant.neutral => theme.border,
    };
  }

  String _markerFor() {
    return switch (variant) {
      AlertVariant.info => 'i',
      AlertVariant.success => '+',
      AlertVariant.warning => '!',
      AlertVariant.error => 'x',
      AlertVariant.neutral => '*',
    };
  }
}
