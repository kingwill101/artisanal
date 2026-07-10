import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show Cmd, KeyMsg;
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';

class Radio<T> extends StatefulWidget {
  Radio({
    required this.value,
    required this.groupValue,
    this.label,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  });

  final T value;
  final T? groupValue;
  final Widget? label;
  final ValueCmdCallback<T>? onChanged;
  final bool enabled;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  State createState() => _RadioState<T>();
}

class _RadioState<T> extends State<Radio<T>> {
  bool _hovered = false;
  bool _focused = false;

  bool get _selected => widget.value == widget.groupValue;
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

  Cmd? _select() {
    if (!_enabled || _selected) return null;
    return widget.onChanged?.call(widget.value);
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!_enabled) return null;
    final key = msg.key;
    final isSelect =
        key.type == terminal_keys.KeyType.enter ||
        key.type == terminal_keys.KeyType.space ||
        key.char == ' ';
    if (!isSelect) return null;
    return _select();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final mark = _selected ? '*' : ' ';
    final radioText = '($mark)';

    final radioStyle = copyStyle(theme.labelMedium)
      ..foreground(_selected ? theme.primary : theme.muted);
    if (_hovered || _focused) radioStyle.bold();
    if (!_enabled) radioStyle.dim();

    final labelStyle = copyStyle(theme.bodyMedium)..foreground(theme.onSurface);
    if (!_enabled) labelStyle.dim();

    final row = Row(
      gap: 1,
      children: [
        Text(radioText, style: radioStyle),
        if (widget.label != null) widget.label!,
      ],
    );

    Widget result = row;
    if (_enabled) {
      result = GestureDetector(onTap: () => _select(), child: result);
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
