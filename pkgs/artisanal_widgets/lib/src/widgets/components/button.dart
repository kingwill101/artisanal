part of 'components_widgets.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }

enum ButtonSize { small, medium, large }

class Button extends StatefulWidget {
  Button({
    this.label,
    this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.padding,
    this.textStyle,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final String? label;
  final Widget? child;
  final CmdCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final EdgeInsets? padding;
  final Style? textStyle;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  State createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.enabled && widget.onPressed != null;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() {
      _hovered = value;
    });
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() {
      _focused = value;
    });
  }

  Cmd? _activate() {
    if (!_enabled) return null;
    return widget.onPressed?.call();
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!_enabled) return null;
    final key = msg.key;
    final isActivate =
        key.type == terminal_keys.KeyType.enter ||
        key.type == terminal_keys.KeyType.space ||
        key.char == ' ';
    if (!isActivate) return null;
    return _activate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final colors = _ButtonColors.resolve(
      theme: theme,
      variant: widget.variant,
      enabled: _enabled,
    );

    final padding = widget.padding ?? _defaultPadding(widget.size);
    final labelStyle = _copyStyle(widget.textStyle ?? theme.labelMedium)
      ..foreground(colors.foreground);

    if (!_enabled) {
      labelStyle.dim();
    } else if (_pressed) {
      labelStyle.dim();
    } else if (_hovered || _focused) {
      labelStyle.bold();
    }

    final label = widget.child ?? Text(widget.label ?? '', style: labelStyle);
    final content = Frame(
      padding: padding,
      background: colors.background,
      border: colors.border,
      borderColor: colors.borderColor,
      child: Align(alignment: Alignment.center, child: label),
    );

    Widget result = content;
    if (_enabled) {
      result = GestureDetector(
        onTapDown: (_) {
          _setPressed(true);
          return null;
        },
        onTapUp: (_) {
          _setPressed(false);
          return null;
        },
        onTap: () => _activate(),
        child: result,
      );
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

    if (!_enabled) {
      result = Opacity(opacity: 0.6, child: result);
    }

    return result;
  }

  EdgeInsets _defaultPadding(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => const EdgeInsets.symmetric(
        horizontal: 1,
        vertical: 0,
      ),
      ButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 0,
      ),
      ButtonSize.large => const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 1,
      ),
    };
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderColor,
  });

  final Color? background;
  final Color foreground;
  final Border? border;
  final Color? borderColor;

  static _ButtonColors resolve({
    required Theme theme,
    required ButtonVariant variant,
    required bool enabled,
  }) {
    Color? background;
    Color foreground;
    Border? border;
    Color? borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        background = theme.primary;
        foreground = theme.onPrimary;
        break;
      case ButtonVariant.secondary:
        background = theme.surface;
        foreground = theme.onSurface;
        break;
      case ButtonVariant.danger:
        background = theme.error;
        foreground = theme.onError;
        break;
      case ButtonVariant.outline:
        foreground = theme.onSurface;
        border = Border.normal;
        borderColor = theme.border;
        break;
      case ButtonVariant.ghost:
        foreground = theme.primary;
        break;
    }

    if (!enabled) {
      background = background ?? theme.surface;
      foreground = theme.muted;
      borderColor = borderColor ?? theme.border;
    }

    return _ButtonColors(
      background: background,
      foreground: foreground,
      border: border,
      borderColor: borderColor,
    );
  }
}
