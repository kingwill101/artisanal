part of 'components_widgets.dart';

/// Flutter-style non-interactive chip.
class Chip extends StatelessWidget {
  Chip({
    required this.label,
    this.avatar,
    this.onDeleted,
    this.deleteIcon,
    this.backgroundColor,
    this.padding,
    this.enabled = true,
    super.key,
  });

  final Widget label;
  final Widget? avatar;
  final CmdCallback? onDeleted;
  final Widget? deleteIcon;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final delete = deleteIcon ?? Text('x', style: theme.labelSmall);

    final children = <Widget>[
      ?avatar,
      _resolveLabel(theme),
      if (onDeleted != null) GestureDetector(onTap: onDeleted, child: delete),
    ];

    Widget chip = Frame(
      border: Border.rounded,
      borderColor: theme.border,
      background: backgroundColor ?? theme.surface,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Row(gap: 1, children: children),
    );

    if (!enabled) {
      chip = Opacity(opacity: 0.7, child: chip);
    }

    return chip;
  }

  Widget _resolveLabel(Theme theme) {
    if (label is Text) {
      final text = label as Text;
      final data = text.data;
      if (data != null) {
        final style = _copyStyle(text.style ?? theme.labelMedium);
        if (!enabled) {
          style.dim();
        }
        return Text(data, style: style);
      }
    }
    return label;
  }
}

/// Flutter-style action chip.
class ActionChip extends StatelessWidget {
  ActionChip({
    required this.label,
    this.avatar,
    this.onPressed,
    this.enabled = true,
    this.size = ButtonSize.small,
    super.key,
  });

  final Widget label;
  final Widget? avatar;
  final CmdCallback? onPressed;
  final bool enabled;
  final ButtonSize size;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: Row(gap: 1, children: [?avatar, label]),
      onPressed: onPressed,
      enabled: enabled,
      variant: ButtonVariant.secondary,
      size: size,
    );
  }
}

/// Flutter-style single-select chip.
class ChoiceChip extends StatelessWidget {
  ChoiceChip({
    required this.label,
    required this.selected,
    this.avatar,
    this.onSelected,
    this.enabled = true,
    this.size = ButtonSize.small,
    super.key,
  });

  final Widget label;
  final bool selected;
  final Widget? avatar;
  final ValueCmdCallback<bool>? onSelected;
  final bool enabled;
  final ButtonSize size;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: Row(gap: 1, children: [?avatar, label]),
      variant: selected ? ButtonVariant.primary : ButtonVariant.outline,
      size: size,
      enabled: enabled && onSelected != null,
      onPressed: onSelected == null
          ? null
          : () {
              return onSelected?.call(!selected);
            },
    );
  }
}

/// Flutter-style multi-select chip.
class FilterChip extends StatelessWidget {
  FilterChip({
    required this.label,
    required this.selected,
    this.avatar,
    this.onSelected,
    this.enabled = true,
    this.showCheckmark = true,
    this.size = ButtonSize.small,
    super.key,
  });

  final Widget label;
  final bool selected;
  final Widget? avatar;
  final ValueCmdCallback<bool>? onSelected;
  final bool enabled;
  final bool showCheckmark;
  final ButtonSize size;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: Row(
        gap: 1,
        children: [?avatar, if (showCheckmark && selected) Text('+'), label],
      ),
      variant: selected ? ButtonVariant.secondary : ButtonVariant.outline,
      size: size,
      enabled: enabled && onSelected != null,
      onPressed: onSelected == null
          ? null
          : () {
              return onSelected?.call(!selected);
            },
    );
  }
}

/// Flutter-style input chip.
///
/// Supports selection, press, and delete actions.
class InputChip extends StatefulWidget {
  InputChip({
    required this.label,
    this.avatar,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.onDeleted,
    this.deleteIcon,
    this.enabled = true,
    this.showCheckmark = false,
    this.backgroundColor,
    this.selectedColor,
    this.padding,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final Widget label;
  final Widget? avatar;
  final bool selected;
  final ValueCmdCallback<bool>? onSelected;
  final CmdCallback? onPressed;
  final CmdCallback? onDeleted;
  final Widget? deleteIcon;
  final bool enabled;
  final bool showCheckmark;
  final Color? backgroundColor;
  final Color? selectedColor;
  final EdgeInsets? padding;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  State createState() => _InputChipState();
}

class _InputChipState extends State<InputChip> {
  bool _hovered = false;
  bool _focused = false;

  bool get _mainEnabled =>
      widget.enabled && (widget.onPressed != null || widget.onSelected != null);

  bool get _deleteEnabled => widget.enabled && widget.onDeleted != null;

  bool get _interactive => _mainEnabled || _deleteEnabled;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  Cmd? _activateMain() {
    if (!_mainEnabled) return null;
    if (widget.onSelected != null) {
      return widget.onSelected?.call(!widget.selected);
    }
    return widget.onPressed?.call();
  }

  Cmd? _activateDelete() {
    if (!_deleteEnabled) return null;
    return widget.onDeleted?.call();
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!widget.enabled) return null;
    final key = msg.key;

    final isActivate =
        key.type == terminal_keys.KeyType.enter ||
        key.type == terminal_keys.KeyType.space ||
        key.char == ' ';
    if (isActivate) {
      return _activateMain();
    }

    final isDelete =
        key.type == terminal_keys.KeyType.delete ||
        key.type == terminal_keys.KeyType.backspace;
    if (isDelete) {
      return _activateDelete();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final selectedBg = widget.selectedColor ?? theme.resolvedHighlight;
    final baseBg = widget.backgroundColor ?? theme.surface;
    final background = widget.selected ? selectedBg : baseBg;
    final foreground = widget.selected
        ? theme.resolvedOnHighlight
        : theme.onSurface;

    final labelStyle = _copyStyle(theme.labelMedium)..foreground(foreground);
    if (_hovered || _focused) {
      labelStyle.bold();
    }
    if (!widget.enabled) {
      labelStyle.dim();
    }

    final children = <Widget>[
      if (widget.avatar != null) widget.avatar!,
      if (widget.showCheckmark && widget.selected)
        Text('+', style: _copyStyle(theme.labelSmall)..foreground(foreground)),
      _styledLabel(widget.label, labelStyle),
      if (widget.onDeleted != null)
        GestureDetector(
          onTap: _activateDelete,
          child: _styledDeleteIcon(theme, foreground),
        ),
    ];

    Widget result = Frame(
      border: Border.rounded,
      borderColor: widget.selected ? selectedBg : theme.border,
      background: background,
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Row(gap: 1, children: children),
    );

    if (_mainEnabled) {
      result = GestureDetector(onTap: _activateMain, child: result);
    }

    if (_interactive) {
      result = MouseRegion(
        onEnter: (_) {
          _setHovered(true);
          return null;
        },
        onExit: (_) {
          _setHovered(false);
          return null;
        },
        child: result,
      );
      result = Focusable(
        controller: widget.focusController ?? FocusScope.of(context),
        focusId: widget.focusId,
        autofocus: widget.autofocus,
        onKey: _handleKey,
        onFocusChange: _setFocused,
        child: result,
      );
    }

    if (!widget.enabled) {
      result = Opacity(opacity: 0.7, child: result);
    }

    return result;
  }

  Widget _styledLabel(Widget label, Style style) {
    if (label is! Text) return label;
    final data = label.data;
    if (data == null) return label;
    return Text(data, style: style);
  }

  Widget _styledDeleteIcon(Theme theme, Color foreground) {
    final icon = widget.deleteIcon ?? Text('x', style: theme.labelSmall);
    if (icon is! Text) return icon;
    final data = icon.data;
    if (data == null) return icon;
    final style = _copyStyle(icon.style ?? theme.labelSmall)
      ..foreground(foreground);
    if (!widget.enabled) style.dim();
    return Text(data, style: style);
  }
}
