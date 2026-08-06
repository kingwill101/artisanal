/// UI list for [PromptStash] entries.
library;

import 'package:artisanal/style.dart' show Color, Border, Style;

import '../composer/prompt_stash.dart';
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart';
import '../layout/layout.dart';
import '../theme/theme.dart' show Theme;
import '../theme/theme_scope.dart' show ThemeScope;
import 'frame.dart' show Frame;

/// Scroll-friendly panel listing stashed drafts (newest first).
class PromptStashPanel extends StatelessWidget {
  PromptStashPanel({
    required this.entries,
    this.selectedIndex,
    this.onSelect,
    this.onRemove,
    this.title = 'stash',
    this.emptyLabel = 'No stashed drafts',
    this.maxVisible = 8,
    this.background,
    this.borderColor,
    this.mutedColor,
    this.accentColor,
    super.key,
  });

  final List<PromptStashEntry> entries;

  /// Index in the **display** order (0 = newest).
  final int? selectedIndex;
  final void Function(int storageIndex, PromptStashEntry entry)? onSelect;
  final void Function(int storageIndex, PromptStashEntry entry)? onRemove;
  final String title;
  final String emptyLabel;
  final int maxVisible;
  final Color? background;
  final Color? borderColor;
  final Color? mutedColor;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final border = borderColor ?? theme.border;
    final muted = mutedColor ?? theme.muted;
    final accent = accentColor ?? theme.primary;

    final ordered = entries.reversed.toList();
    final visible = ordered.length > maxVisible
        ? ordered.sublist(0, maxVisible)
        : ordered;

    return Frame(
      background: bg,
      border: Border.rounded,
      borderColor: border,
      padding: const EdgeInsets.all(1),
      child: Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            gap: 1,
            children: [
              Text(
                title,
                style: theme.labelSmall.copy()..foreground(accent),
              ),
              Text('·', style: theme.bodySmall.copy()..foreground(muted)),
              Text(
                '${entries.length}',
                style: theme.bodySmall.copy()..foreground(muted),
              ),
              Spacer(),
              Text(
                'enter restore',
                style: theme.bodySmall.copy()..foreground(muted),
              ),
            ],
          ),
          Divider(style: Style().foreground(border)),
          if (visible.isEmpty)
            Text(
              emptyLabel,
              style: theme.bodySmall.copy()..foreground(muted),
            )
          else
            for (var i = 0; i < visible.length; i++)
              _entryRow(
                theme: theme,
                entry: visible[i],
                storageIndex: entries.length - 1 - i,
                selected: selectedIndex == i,
                muted: muted,
                onSelect: onSelect,
                onRemove: onRemove,
              ),
        ],
      ),
    );
  }

  Widget _entryRow({
    required Theme theme,
    required PromptStashEntry entry,
    required int storageIndex,
    required bool selected,
    required Color muted,
    required void Function(int storageIndex, PromptStashEntry entry)? onSelect,
    required void Function(int storageIndex, PromptStashEntry entry)? onRemove,
  }) {
    final labelStyle = theme.bodySmall.copy()
      ..foreground(selected ? theme.onSurface : muted)
      ..bold(selected);

    final row = Row(
      gap: 1,
      children: [
        Text(selected ? '›' : ' ', style: labelStyle),
        Expanded(
          child: Text(
            entry.displayLabel,
            style: labelStyle,
            softWrap: false,
          ),
        ),
        if (onRemove != null)
          GestureDetector(
            onTap: () {
              onRemove(storageIndex, entry);
              return null;
            },
            child: Text(
              '×',
              style: theme.labelSmall.copy()..foreground(muted),
            ),
          ),
      ],
    );

    final child = selected
        ? Container(color: theme.listRowSelectedBackground, child: row)
        : row;

    if (onSelect == null) return child;
    return GestureDetector(
      onTap: () {
        onSelect(storageIndex, entry);
        return null;
      },
      child: child,
    );
  }
}
