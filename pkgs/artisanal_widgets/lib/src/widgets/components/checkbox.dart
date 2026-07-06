import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/focus/focus.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout_widgets.dart';
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal_widgets/src/widgets/components/component_style.dart';

class Checkbox extends StatefulWidget {
  Checkbox({
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
  State createState() => _CheckboxState();
}

class _CheckboxState extends State<Checkbox> {
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
        key.type == .enter || key.type == .space || key.char == ' ';
    if (!isToggle) return null;
    return _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final mark = widget.value ? 'x' : ' ';
    final boxText = '[$mark]';

    final boxStyle = copyStyle(theme.labelMedium)
      ..foreground(widget.value ? theme.primary : theme.muted);
    if (_hovered || _focused) boxStyle.bold();
    if (!_enabled) boxStyle.dim();

    final labelStyle = copyStyle(theme.bodyMedium)..foreground(theme.onSurface);
    if (!_enabled) labelStyle.dim();

    final row = Row(
      gap: 1,
      children: [
        Text(boxText, style: boxStyle),
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
