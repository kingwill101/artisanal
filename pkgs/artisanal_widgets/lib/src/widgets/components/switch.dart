part of 'components_widgets.dart';

class Switch extends StatefulWidget {
  Switch({
    required this.value,
    this.label,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final bool value;
  final Widget? label;
  final ValueCmdCallback<bool>? onChanged;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  State createState() => _SwitchState();
}

class _SwitchState extends State<Switch> {
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() {
      _hovered = value;
    });
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() {
      _focused = value;
    });
  }

  Cmd? _toggle() {
    if (!_enabled) return null;
    return widget.onChanged?.call(!widget.value);
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!_enabled) return null;
    final key = msg.key;
    final isToggle =
        key.type == terminal_keys.KeyType.enter ||
        key.type == terminal_keys.KeyType.space ||
        key.char == ' ';
    if (!isToggle) return null;
    return _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final text = widget.value ? '[ON]' : '[OFF]';
    final toggleStyle = _copyStyle(theme.labelMedium)
      ..foreground(widget.value ? theme.success : theme.muted);
    if (_hovered || _focused) toggleStyle.bold();
    if (!_enabled) toggleStyle.dim();

    final row = Row(
      gap: 1,
      children: [
        Text(text, style: toggleStyle),
        if (widget.label != null) widget.label!,
      ],
    );

    Widget result = row;
    if (_enabled) {
      result = GestureDetector(onTap: () => _toggle(), child: result);
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
}
