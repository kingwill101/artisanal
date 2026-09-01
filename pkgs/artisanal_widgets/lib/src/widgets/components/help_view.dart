import 'dart:math' as math;

import 'package:artisanal/style.dart' show Style;
import 'package:artisanal_widgets/widgets.dart';

/// A widget-side help view for rendering [KeyMap] bindings.
///
/// `HelpView` mirrors the two common Bubble Tea help states:
/// a compact inline summary and a full grouped view.
///
/// ```dart
/// class DemoKeyMap extends KeyMap {
///   DemoKeyMap() {
///     final help = KeyBinding.withHelp(['?'], '?', 'toggle help');
///     final quit = KeyBinding.withHelp(['q'], 'q', 'quit');
///     shortHelp = [help, quit];
///     fullHelp = [
///       [help],
///       [quit],
///     ];
///   }
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
    final resolvedKeyStyle = (keyStyle ?? theme.labelLarge).copy();
    final resolvedDescriptionStyle = (descriptionStyle ?? theme.bodySmall)
        .copy();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);

        if (showAll) {
          final groups = keyMap.fullHelp.map(_visibleBindings).where((group) {
            return group.isNotEmpty;
          }).toList();
          if (groups.isEmpty) return SizedBox.shrink();

          final stackGroups = _shouldStackGroups(groups, maxWidth, columnGap);
          if (stackGroups) {
            return Column(
              gap: math.max(1, rowGap),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in groups)
                  Column(
                    gap: rowGap,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildResponsiveColumn(
                      group,
                      resolvedKeyStyle,
                      resolvedDescriptionStyle,
                      maxWidth,
                    ),
                  ),
              ],
            );
          }

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

        final bindings = _visibleBindings(keyMap.shortHelp);
        if (bindings.isEmpty) return SizedBox.shrink();

        if (_shouldStackBindings(bindings, maxWidth)) {
          return Column(
            gap: math.max(1, runSpacing),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final binding in bindings)
                _buildResponsiveBinding(
                  binding,
                  resolvedKeyStyle,
                  resolvedDescriptionStyle,
                ),
            ],
          );
        }

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
      },
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

  static List<Widget> _buildResponsiveColumn(
    List<KeyBinding> bindings,
    Style keyStyle,
    Style descriptionStyle,
    int maxWidth,
  ) {
    return [
      for (final binding in bindings)
        if (_bindingWidth(binding) > maxWidth)
          _buildResponsiveBinding(binding, keyStyle, descriptionStyle)
        else
          _buildInlineBinding(binding, keyStyle, descriptionStyle),
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

  static Widget _buildResponsiveBinding(
    KeyBinding binding,
    Style keyStyle,
    Style descriptionStyle,
  ) {
    return Text.rich(
      TextSpan(children: _bindingSpans(binding, keyStyle, descriptionStyle)),
      softWrap: true,
    );
  }

  static bool _shouldStackBindings(List<KeyBinding> bindings, int maxWidth) {
    if (maxWidth <= 0) return true;
    return bindings.any((binding) => _bindingWidth(binding) > maxWidth);
  }

  static bool _shouldStackGroups(
    List<List<KeyBinding>> groups,
    int maxWidth,
    int columnGap,
  ) {
    if (maxWidth <= 0) return true;

    var totalWidth = 0;
    for (var i = 0; i < groups.length; i++) {
      if (i > 0) totalWidth += columnGap;
      totalWidth += _groupWidth(groups[i]);
    }
    return totalWidth > maxWidth ||
        groups.any(
          (group) => group.any((binding) => _bindingWidth(binding) > maxWidth),
        );
  }

  static int _groupWidth(List<KeyBinding> bindings) {
    return bindings.fold<int>(0, (maxWidth, binding) {
      final width = _bindingWidth(binding);
      return width > maxWidth ? width : maxWidth;
    });
  }

  static int _bindingWidth(KeyBinding binding) {
    final keyWidth = Style.visibleLength(binding.help.key);
    final desc = binding.help.desc;
    if (desc.isEmpty) return keyWidth;
    return keyWidth + 1 + Style.visibleLength(desc);
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
