part of 'components_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final selected = _selectedOption();
    final label = selected?.label ?? placeholder;
    final style = _copyStyle(textStyle ?? theme.bodyMedium)
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
