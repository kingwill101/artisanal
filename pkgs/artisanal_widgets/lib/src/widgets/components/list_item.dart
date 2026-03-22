part of 'components_widgets.dart';

class ListTile extends StatelessWidget {
  /// Creates a Material-style list tile.
  ///
  /// [title] and [subtitle] accept either a [Widget] or plain text (`String`).
  /// Passing strings is a convenience; widgets provide full control.
  ListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.padding,
    this.background,
    this.selectedBackground,
    this.foreground,
    this.selectedForeground,
    this.titleStyle,
    this.subtitleStyle,
    this.gap = 1,
    this.minLeadingWidth = 0,
    super.key,
  });

  /// Primary content.
  final Object title;

  /// Secondary content below [title].
  final Object? subtitle;

  final Widget? leading;
  final Widget? trailing;

  /// Called when the tile is tapped.
  final CmdCallback? onTap;

  /// Whether the tile is interactive.
  final bool enabled;

  final bool selected;
  final bool dense;

  /// Padding inside the tile.
  final EdgeInsets? padding;

  /// Base background color when not selected.
  final Color? background;

  /// Background color when [selected] is true.
  final Color? selectedBackground;

  /// Foreground color for title/content when not selected.
  final Color? foreground;

  /// Foreground color for title/content when [selected] is true.
  final Color? selectedForeground;

  /// Optional title text style override.
  final Style? titleStyle;

  /// Optional subtitle text style override.
  final Style? subtitleStyle;

  /// Horizontal gap between leading/content/trailing.
  final int gap;

  /// Reserved width for the leading slot.
  final int minLeadingWidth;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final active = enabled && onTap != null;
    final fg = selected
        ? (selectedForeground ?? theme.onPrimary)
        : (foreground ?? (enabled ? theme.onSurface : theme.muted));
    final secondaryFg = selected
        ? (selectedForeground ?? theme.onPrimary)
        : (enabled ? theme.muted : theme.muted);
    final bg = selected
        ? (selectedBackground ?? theme.primary)
        : (background ?? theme.surface);

    final resolvedTitleStyle = _copyStyle(titleStyle ?? theme.bodyMedium)
      ..foreground(fg);
    final resolvedSubtitleStyle = _copyStyle(subtitleStyle ?? theme.bodySmall)
      ..foreground(secondaryFg);
    if (!enabled) {
      resolvedTitleStyle.dim();
      resolvedSubtitleStyle.dim();
    }

    final titleWidget = _slotWidget(title, resolvedTitleStyle);
    final subtitleWidget = subtitle == null
        ? null
        : _slotWidget(subtitle!, resolvedSubtitleStyle);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: subtitleWidget == null ? 0 : 1,
      children: [titleWidget, ?subtitleWidget],
    );

    Widget tile = Container(
      padding:
          padding ??
          EdgeInsets.symmetric(horizontal: 2, vertical: dense ? 0 : 1),
      color: bg,
      child: Row(
        gap: gap,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null)
            minLeadingWidth > 0
                ? Container(width: minLeadingWidth, child: leading)
                : leading!,
          Expanded(child: body),
          ?trailing,
        ],
      ),
    );

    if (active) {
      tile = GestureDetector(onTap: onTap, child: tile);
    }

    if (!enabled) {
      tile = Opacity(opacity: 0.7, child: tile);
    }

    return tile;
  }

  Widget _slotWidget(Object value, Style style) {
    if (value is Widget) return value;
    return Text(value.toString(), style: style);
  }
}

/// Position of the control in list-tile-style rows.
enum ListTileControlAffinity {
  /// Places the control in the leading slot.
  leading,

  /// Places the control in the trailing slot.
  trailing,
}

/// Flutter-style checkbox list tile.
class CheckboxListTile extends StatelessWidget {
  CheckboxListTile({
    required this.value,
    required this.title,
    this.subtitle,
    this.onChanged,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.secondary,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.contentPadding,
    super.key,
  });

  final bool value;
  final Object title;
  final Object? subtitle;
  final ValueCmdCallback<bool>? onChanged;
  final ListTileControlAffinity controlAffinity;
  final Widget? secondary;
  final bool enabled;
  final bool selected;
  final bool dense;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onChanged != null;
    final control = Checkbox(
      value: value,
      onChanged: interactive ? onChanged : null,
      enabled: enabled,
    );

    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: controlAffinity == ListTileControlAffinity.leading
          ? control
          : secondary,
      trailing: controlAffinity == ListTileControlAffinity.trailing
          ? control
          : secondary,
      selected: selected,
      dense: dense,
      enabled: enabled,
      padding: contentPadding,
      onTap: interactive
          ? () {
              return onChanged?.call(!value);
            }
          : null,
    );
  }
}

/// Flutter-style switch list tile.
class SwitchListTile extends StatelessWidget {
  SwitchListTile({
    required this.value,
    required this.title,
    this.subtitle,
    this.onChanged,
    this.controlAffinity = ListTileControlAffinity.trailing,
    this.secondary,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.contentPadding,
    super.key,
  });

  final bool value;
  final Object title;
  final Object? subtitle;
  final ValueCmdCallback<bool>? onChanged;
  final ListTileControlAffinity controlAffinity;
  final Widget? secondary;
  final bool enabled;
  final bool selected;
  final bool dense;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onChanged != null;
    final control = Switch(
      value: value,
      onChanged: interactive ? onChanged : null,
      enabled: enabled,
    );

    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: controlAffinity == ListTileControlAffinity.leading
          ? control
          : secondary,
      trailing: controlAffinity == ListTileControlAffinity.trailing
          ? control
          : secondary,
      selected: selected,
      dense: dense,
      enabled: enabled,
      padding: contentPadding,
      onTap: interactive
          ? () {
              return onChanged?.call(!value);
            }
          : null,
    );
  }
}

/// Flutter-style radio list tile.
class RadioListTile<T> extends StatelessWidget {
  RadioListTile({
    required this.value,
    required this.groupValue,
    required this.title,
    this.subtitle,
    this.onChanged,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.secondary,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.contentPadding,
    super.key,
  });

  final T value;
  final T? groupValue;
  final Object title;
  final Object? subtitle;
  final ValueCmdCallback<T>? onChanged;
  final ListTileControlAffinity controlAffinity;
  final Widget? secondary;
  final bool enabled;
  final bool selected;
  final bool dense;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final interactive = enabled && onChanged != null;
    final control = Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: interactive ? onChanged : null,
      enabled: enabled,
    );

    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: controlAffinity == ListTileControlAffinity.leading
          ? control
          : secondary,
      trailing: controlAffinity == ListTileControlAffinity.trailing
          ? control
          : secondary,
      selected: selected || isSelected,
      dense: dense,
      enabled: enabled,
      padding: contentPadding,
      onTap: interactive && !isSelected
          ? () {
              return onChanged?.call(value);
            }
          : null,
    );
  }
}

/// Flutter-style expansion tile built on top of [ListTile].
class ExpansionTile extends StatefulWidget {
  ExpansionTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.children = const <Widget>[],
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.enabled = true,
    this.dense = false,
    this.tilePadding,
    this.childrenPadding,
    super.key,
  });

  final Object title;
  final Object? subtitle;
  final Widget? leading;
  final Widget? trailing;
  @override
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueCmdCallback<bool>? onExpansionChanged;
  final bool enabled;
  final bool dense;
  final EdgeInsets? tilePadding;
  final EdgeInsets? childrenPadding;

  @override
  State createState() => _ExpansionTileState();
}

class _ExpansionTileState extends State<ExpansionTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  Cmd? _toggleExpanded() {
    if (!widget.enabled) return null;
    final nextExpanded = !_expanded;
    setState(() {
      _expanded = nextExpanded;
    });
    return widget.onExpansionChanged?.call(nextExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final indicator =
        widget.trailing ??
        Text(
          _expanded ? 'v' : '>',
          style: _copyStyle(theme.labelMedium)..foreground(theme.muted),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: _expanded && widget.children.isNotEmpty ? 1 : 0,
      children: [
        ListTile(
          title: widget.title,
          subtitle: widget.subtitle,
          leading: widget.leading,
          trailing: indicator,
          dense: widget.dense,
          enabled: widget.enabled,
          padding: widget.tilePadding,
          onTap: widget.enabled ? _toggleExpanded : null,
        ),
        if (_expanded && widget.children.isNotEmpty)
          Padding(
            padding: widget.childrenPadding ?? const EdgeInsets.only(left: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}
