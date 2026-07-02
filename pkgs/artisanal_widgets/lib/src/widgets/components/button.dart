part of 'components_widgets.dart';

/// Visual style variants for [Button].
enum ButtonVariant { primary, secondary, outline, ghost, danger }

/// Size variants for [Button].
enum ButtonSize { small, medium, large }

/// Flutter-style button widget for triggering callbacks.
///
/// The [Button] widget is the base button implementation used by
/// [ElevatedButton], [FilledButton], [TextButton], and [OutlinedButton].
/// It supports hover and focus states, keyboard activation, and custom styling
/// through [ButtonVariant] and [ButtonSize].
///
/// The [variant] controls the visual appearance:
/// - [ButtonVariant.primary] - filled with primary color background
/// - [ButtonVariant.secondary] - filled with secondary/surface color
/// - [ButtonVariant.danger] - filled with error color background
/// - [ButtonVariant.outline] - transparent with border outline
/// - [ButtonVariant.ghost] - transparent, no border
///
/// The button is disabled when [enabled] is `false` or when [onPressed] is `null`.
/// Use [autofocus] and [focusController] to control keyboard focus behavior.
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
    final labelStyle = copyStyle(widget.textStyle ?? theme.labelMedium)
      ..foreground(colors.foreground);

    if (!_enabled) {
      labelStyle.dim();
    } else if (_pressed) {
      labelStyle.dim();
    } else if (_hovered || _focused) {
      labelStyle.bold();
    }

    final label = widget.child ?? Text(widget.label ?? '', style: labelStyle);
    var frameBorder = colors.border;
    var frameBorderColor = colors.borderColor;
    Style? frameStyle;

    if (widget.variant == ButtonVariant.outline) {
      frameBorder = null;
      frameBorderColor = null;
      frameStyle = copyStyle(null)
        ..border(
          Border.normal,
          top: false,
          right: true,
          bottom: false,
          left: true,
        )
        ..borderForeground(colors.borderColor ?? theme.border);
    }

    final content = Frame(
      style: frameStyle,
      padding: padding,
      background: colors.background,
      border: frameBorder,
      borderColor: frameBorderColor,
      child: label,
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

/// Flutter-style elevated button wrapper.
///
/// This maps to [ButtonVariant.primary].
class ElevatedButton extends StatelessWidget {
  ElevatedButton({
    required this.child,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.padding,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final Widget child;
  final CmdCallback? onPressed;
  final ButtonSize size;
  final EdgeInsets? padding;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: child,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      padding: padding,
      enabled: enabled,
      autofocus: autofocus,
      focusId: focusId,
      focusController: focusController,
    );
  }
}

/// Flutter-style filled button wrapper.
///
/// The default constructor maps to [ButtonVariant.primary].
/// [FilledButton.tonal] maps to [ButtonVariant.secondary].
class FilledButton extends StatelessWidget {
  FilledButton({
    required this.child,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.padding,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  }) : _tonal = false;

  FilledButton.tonal({
    required this.child,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.padding,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  }) : _tonal = true;

  final Widget child;
  final CmdCallback? onPressed;
  final ButtonSize size;
  final EdgeInsets? padding;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;
  final bool _tonal;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: child,
      onPressed: onPressed,
      variant: _tonal ? ButtonVariant.secondary : ButtonVariant.primary,
      size: size,
      padding: padding,
      enabled: enabled,
      autofocus: autofocus,
      focusId: focusId,
      focusController: focusController,
    );
  }
}

/// Flutter-style text button wrapper.
///
/// This maps to [ButtonVariant.ghost].
class TextButton extends StatelessWidget {
  TextButton({
    required this.child,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.padding,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final Widget child;
  final CmdCallback? onPressed;
  final ButtonSize size;
  final EdgeInsets? padding;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: child,
      onPressed: onPressed,
      variant: ButtonVariant.ghost,
      size: size,
      padding: padding,
      enabled: enabled,
      autofocus: autofocus,
      focusId: focusId,
      focusController: focusController,
    );
  }
}

/// Flutter-style outlined button wrapper.
///
/// This maps to [ButtonVariant.outline].
class OutlinedButton extends StatelessWidget {
  OutlinedButton({
    required this.child,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.padding,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final Widget child;
  final CmdCallback? onPressed;
  final ButtonSize size;
  final EdgeInsets? padding;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: child,
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      padding: padding,
      enabled: enabled,
      autofocus: autofocus,
      focusId: focusId,
      focusController: focusController,
    );
  }
}

/// Flutter-style icon button wrapper.
///
/// This maps to [ButtonVariant.ghost] with a compact default size.
class IconButton extends StatelessWidget {
  IconButton({
    required this.icon,
    this.onPressed,
    this.size = ButtonSize.small,
    this.padding,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final Widget icon;
  final CmdCallback? onPressed;
  final ButtonSize size;
  final EdgeInsets? padding;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  Widget build(BuildContext context) {
    return Button(
      child: icon,
      onPressed: onPressed,
      variant: ButtonVariant.ghost,
      size: size,
      padding: padding,
      enabled: enabled,
      autofocus: autofocus,
      focusId: focusId,
      focusController: focusController,
    );
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
