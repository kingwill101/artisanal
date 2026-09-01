import 'package:artisanal/runtime.dart';
import '_component_foundation.dart';
import 'button.dart';
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/runtime.dart' show Cmd;

/// An option for use with [Select] or [DropdownButton].
class SelectOption<T> {
  const SelectOption({
    required this.label,
    required this.value,
    this.enabled = true,
  });

  final String label;
  final T value;
  final bool enabled;
}

/// A button-style dropdown selector that cycles through options.
///
/// The [Select] widget displays the currently selected option and cycles
/// to the next enabled option when activated. Use [placeholder] to show text
/// when no value is selected.
///
/// Example:
/// ```dart
/// Select<String>(
///   options: [
///     SelectOption(label: 'Light', value: 'light'),
///     SelectOption(label: 'Dark', value: 'dark'),
///     SelectOption(label: 'Auto', value: 'auto'),
///   ],
///   value: 'dark',
///   onChanged: (mode) => print('Theme: $mode'),
/// )
/// ```
class Select<T> extends StatelessWidget {
  Select({
    required this.options,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.placeholder = 'Select',
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.outline,
    this.textStyle,
    this.selectFirstWhenNull = true,
    super.key,
  });

  final List<SelectOption<T>> options;
  final T? value;
  final ValueCmdCallback<T>? onChanged;
  final bool enabled;
  final String placeholder;
  final ButtonSize size;
  final ButtonVariant variant;
  final Style? textStyle;
  final bool selectFirstWhenNull;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final selected = _selectedOption();
    final label = selected?.label ?? placeholder;
    final style = copyStyle(textStyle ?? theme.bodyMedium)
      ..foreground(theme.onSurface);
    final content = Row(
      gap: 1,
      children: [
        Text(label, style: style),
        Text('v', style: style),
      ],
    );

    return Button(
      child: content,
      size: size,
      variant: variant,
      enabled: enabled && onChanged != null,
      onPressed: _nextValue == null ? null : _selectNext,
    );
  }

  SelectOption<T>? _selectedOption() {
    if (options.isEmpty) return null;
    if (value == null) {
      if (!selectFirstWhenNull) return null;
      return options.firstWhere(
        (option) => option.enabled,
        orElse: () => options.first,
      );
    }
    return options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
  }

  T? get _nextValue {
    if (options.isEmpty) return null;
    var startIndex = options.indexWhere((o) => o.value == value);
    if (startIndex < 0) startIndex = -1;
    for (var step = 1; step <= options.length; step++) {
      final index = (startIndex + step) % options.length;
      final candidate = options[index];
      if (candidate.enabled) return candidate.value;
    }
    return null;
  }

  Cmd? _selectNext() {
    final next = _nextValue;
    if (next == null) return null;
    return onChanged?.call(next);
  }
}

/// A dropdown menu item for use with [DropdownButton].
///
/// The [label] is used for display in the dropdown. If [label] is not
/// provided, the [child] widget's text content is extracted, or the
/// [value] is converted to a string.
class DropdownMenuItem<T> extends StatelessWidget {
  DropdownMenuItem({
    required this.value,
    required this.child,
    this.enabled = true,
    this.label,
    super.key,
  });

  final T value;
  final Widget child;
  final bool enabled;
  final String? label;

  /// Label used by [DropdownButton].
  String get labelText {
    if (label != null && label!.trim().isNotEmpty) {
      return label!.trim();
    }

    if (child is Text) {
      final text = child as Text;
      final data = text.data;
      if (data != null && data.trim().isNotEmpty) {
        return data.trim();
      }
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) => child;
}

/// A button-styled dropdown that displays one [DropdownMenuItem] at a time.
///
/// Unlike [Select] which cycles through options, [DropdownButton] presents
/// a single selected item. Use [items] to provide the options and [hint]
/// to show a placeholder when no value is selected.
class DropdownButton<T> extends StatelessWidget {
  DropdownButton({
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.disabledHint,
    this.enabled = true,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.outline,
    this.textStyle,
    super.key,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueCmdCallback<T>? onChanged;
  final Widget? hint;
  final Widget? disabledHint;
  final bool enabled;
  final ButtonSize size;
  final ButtonVariant variant;
  final Style? textStyle;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onChanged != null;
    final options = items
        .map(
          (item) => SelectOption<T>(
            label: item.labelText,
            value: item.value,
            enabled: item.enabled,
          ),
        )
        .toList(growable: false);

    return Select<T>(
      options: options,
      value: value,
      onChanged: interactive ? onChanged : null,
      enabled: interactive,
      placeholder: _placeholderText(interactive),
      size: size,
      variant: variant,
      textStyle: textStyle,
      selectFirstWhenNull: false,
    );
  }

  String _placeholderText(bool interactive) {
    final candidate = interactive ? hint : (disabledHint ?? hint);
    if (candidate == null) return 'Select';
    return _textFromWidget(candidate) ?? 'Select';
  }

  String? _textFromWidget(Widget widget) {
    if (widget is! Text) return null;
    final data = widget.data;
    if (data == null) return null;
    final trimmed = data.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
