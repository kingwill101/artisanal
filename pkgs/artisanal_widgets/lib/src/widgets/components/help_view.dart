part of 'components_widgets.dart';

/// A widget-side help view for rendering [KeyMap] bindings.
///
/// `HelpView` mirrors the two common Bubble Tea help states:
/// a compact inline summary and a full grouped view.
///
/// ```dart
/// class DemoKeyMap implements KeyMap {
///   final quit = KeyBinding.withHelp(['q'], 'q', 'quit');
///   final help = KeyBinding.withHelp(['?'], '?', 'toggle help');
///
///   @override
///   List<KeyBinding> shortHelp() => [help, quit];
///
///   @override
///   List<List<KeyBinding>> fullHelp() => [
///     [help],
///     [quit],
///   ];
/// }
///
/// HelpView(keyMap: DemoKeyMap())
/// HelpView(keyMap: DemoKeyMap(), showAll: true)
/// ```
class HelpView extends StatelessWidget {
  HelpView({
    required this.keyMap,
    this.showAll = false,
    this.itemSpacing = 3,
    this.runSpacing = 1,
    this.columnGap = 4,
    this.rowGap = 0,
    this.keyStyle,
    this.descriptionStyle,
    super.key,
  });

  /// Source of the help bindings to render.
  final KeyMap keyMap;

  /// Whether to render the full grouped help instead of the compact summary.
  final bool showAll;

  /// Spacing between compact help items.
  final int itemSpacing;

  /// Vertical spacing between wrapped compact help rows.
  final int runSpacing;

  /// Gap between columns in the full grouped help view.
  final int columnGap;

  /// Gap between rows inside a full grouped help column.
  final int rowGap;

  /// Style override for rendered key labels.
  final Style? keyStyle;

  /// Style override for rendered descriptions.
  final Style? descriptionStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final resolvedKeyStyle = _copyStyle(keyStyle ?? theme.labelLarge);
    final resolvedDescriptionStyle = _copyStyle(
      descriptionStyle ?? theme.bodySmall,
    );

    if (showAll) {
      final groups = keyMap.fullHelp().map(_visibleBindings).where((group) {
        return group.isNotEmpty;
      }).toList();
      if (groups.isEmpty) return SizedBox.shrink();

      return Row(
        gap: columnGap,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups)
            Column(
              gap: rowGap,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildColumn(
                group,
                resolvedKeyStyle,
                resolvedDescriptionStyle,
              ),
            ),
        ],
      );
    }

    final bindings = _visibleBindings(keyMap.shortHelp());
    if (bindings.isEmpty) return SizedBox.shrink();

    return Wrap(
      spacing: itemSpacing,
      runSpacing: runSpacing,
      children: [
        for (final binding in bindings)
          _buildInlineBinding(
            binding,
            resolvedKeyStyle,
            resolvedDescriptionStyle,
          ),
      ],
    );
  }

  static List<KeyBinding> _visibleBindings(List<KeyBinding> bindings) {
    return [
      for (final binding in bindings)
        if (binding.enabled && binding.help.hasContent) binding,
    ];
  }

  static List<Widget> _buildColumn(
    List<KeyBinding> bindings,
    Style keyStyle,
    Style descriptionStyle,
  ) {
    final maxKeyWidth = bindings.fold<int>(0, (maxWidth, binding) {
      final width = Style.visibleLength(binding.help.key);
      return width > maxWidth ? width : maxWidth;
    });

    return [
      for (final binding in bindings)
        Text.rich(
          TextSpan(
            children: _bindingSpans(
              binding,
              keyStyle,
              descriptionStyle,
              paddedKey: _padRightVisible(binding.help.key, maxKeyWidth),
            ),
          ),
          softWrap: false,
        ),
    ];
  }

  static Widget _buildInlineBinding(
    KeyBinding binding,
    Style keyStyle,
    Style descriptionStyle,
  ) {
    return Text.rich(
      TextSpan(children: _bindingSpans(binding, keyStyle, descriptionStyle)),
      softWrap: false,
    );
  }

  static List<TextSpan> _bindingSpans(
    KeyBinding binding,
    Style keyStyle,
    Style descriptionStyle, {
    String? paddedKey,
  }) {
    final keyText = paddedKey ?? binding.help.key;
    final desc = binding.help.desc;

    if (desc.isEmpty) {
      return [TextSpan(text: keyText, style: keyStyle)];
    }

    return [
      TextSpan(text: keyText, style: keyStyle),
      TextSpan(text: ' ', style: descriptionStyle),
      TextSpan(text: desc, style: descriptionStyle),
    ];
  }

  static String _padRightVisible(String text, int targetWidth) {
    final width = Style.visibleLength(text);
    final pad = targetWidth - width;
    if (pad <= 0) return text;
    return '$text${' ' * pad}';
  }
}
