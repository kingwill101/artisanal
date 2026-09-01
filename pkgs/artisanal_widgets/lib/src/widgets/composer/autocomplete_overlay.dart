/// Floating autocomplete list for prompt composers (OpenCode-style @ /).
library;

import 'package:artisanal/style.dart' show Color, Border, Style;

import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart';
import '../layout/_layout_core.dart';
import '../theme/theme.dart' show Theme;
import '../theme/theme_scope.dart' show ThemeScope;
import '../components/frame.dart' show Frame;
import 'frecency_store.dart';

/// One row in an [AutocompleteOverlay].
final class AutocompleteItem {
  const AutocompleteItem({
    required this.id,
    required this.label,
    this.description,
    this.group,
    this.insertText,
    this.disabled = false,
  });

  final String id;
  final String label;
  final String? description;
  final String? group;

  /// Text inserted on select; defaults to [label].
  final String? insertText;
  final bool disabled;

  String get textToInsert => insertText ?? label;
}

/// Trigger kind detected in a prompt field.
enum AutocompleteTrigger {
  /// `@file` mentions.
  mention,

  /// `/slash` commands.
  slash,
}

/// Result of scanning prompt text for an autocomplete query.
final class AutocompleteQuery {
  const AutocompleteQuery({
    required this.trigger,
    required this.triggerIndex,
    required this.query,
  });

  final AutocompleteTrigger trigger;

  /// Index of `@` or `/` in the source string.
  final int triggerIndex;

  /// Text after the trigger (may be empty).
  final String query;
}

/// Scan [text] for a trailing `@…` or `/…` token (OpenCode-style).
///
/// Only the token that ends at [cursor] (or end of string) is considered.
AutocompleteQuery? detectAutocompleteQuery(String text, {int? cursor}) {
  final end = cursor ?? text.length;
  if (end <= 0 || end > text.length) return null;

  // Walk back to token start.
  var i = end - 1;
  while (i >= 0) {
    final ch = text[i];
    if (ch == ' ' || ch == '\n' || ch == '\t') break;
    i--;
  }
  final start = i + 1;
  if (start >= end) return null;

  final token = text.substring(start, end);
  if (token.startsWith('@')) {
    return AutocompleteQuery(
      trigger: AutocompleteTrigger.mention,
      triggerIndex: start,
      query: token.substring(1),
    );
  }
  if (token.startsWith('/')) {
    return AutocompleteQuery(
      trigger: AutocompleteTrigger.slash,
      triggerIndex: start,
      query: token.substring(1),
    );
  }
  return null;
}

/// Case-insensitive substring filter; optional frecency re-rank.
List<AutocompleteItem> filterAutocompleteItems(
  Iterable<AutocompleteItem> items,
  String query, {
  FrecencyStore? frecency,
  int limit = 12,
}) {
  final q = query.trim().toLowerCase();
  var list = items.where((item) {
    if (item.disabled) return false;
    if (q.isEmpty) return true;
    final hay = [
      item.label,
      item.id,
      ?item.description,
      ?item.group,
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }).toList();

  if (frecency != null) {
    list = frecency.sortByFrecency(list, (i) => i.id);
  } else {
    list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  if (list.length > limit) return list.sublist(0, limit);
  return list;
}

/// Replace the active trigger token in [text] with [insertion].
String applyAutocompleteInsertion(
  String text,
  AutocompleteQuery query,
  String insertion, {
  int? cursor,
}) {
  final end = cursor ?? text.length;
  final before = text.substring(0, query.triggerIndex);
  final after = end < text.length ? text.substring(end) : '';
  final needsSpace = after.isEmpty || !after.startsWith(' ');
  final mid = insertion + (needsSpace ? ' ' : '');
  return before + mid + after;
}

/// Docked autocomplete panel for composer fields.
class AutocompleteOverlay extends StatelessWidget {
  AutocompleteOverlay({
    required this.items,
    this.selectedIndex = 0,
    this.title,
    this.query,
    this.maxVisible = 8,
    this.background,
    this.borderColor,
    this.selectedBackground,
    this.selectedForeground,
    this.mutedForeground,
    this.accentForeground,
    super.key,
  });

  final List<AutocompleteItem> items;
  final int selectedIndex;
  final String? title;
  final String? query;
  final int maxVisible;
  final Color? background;
  final Color? borderColor;
  final Color? selectedBackground;
  final Color? selectedForeground;
  final Color? mutedForeground;
  final Color? accentForeground;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final border = borderColor ?? theme.border;
    final selBg = selectedBackground ?? theme.listRowSelectedBackground;
    final selFg = selectedForeground ?? theme.listRowSelectedForeground;
    final muted = mutedForeground ?? theme.muted;
    final accent = accentForeground ?? theme.primary;

    final headerStyle = theme.labelSmall.copy()..foreground(accent);
    final mutedStyle = theme.bodySmall.copy()..foreground(muted);
    final visible = items.length > maxVisible
        ? items.sublist(0, maxVisible)
        : items;
    final sel = items.isEmpty
        ? 0
        : selectedIndex.clamp(0, items.length - 1);

    return Frame(
      background: bg,
      border: Border.rounded,
      borderColor: border,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Column(
        gap: 0,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            gap: 1,
            children: [
              Text(title ?? 'autocomplete', style: headerStyle),
              if (query != null && query!.isNotEmpty) ...[
                Text('·', style: mutedStyle),
                Expanded(
                  child: Text(
                    query!,
                    style: mutedStyle,
                    softWrap: false,
                  ),
                ),
              ] else
                Spacer(),
              Text(
                items.isEmpty ? 'no matches' : '${sel + 1}/${items.length}',
                style: mutedStyle,
              ),
            ],
          ),
          Divider(style: Style().foreground(border)),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Text('type to filter', style: mutedStyle),
            )
          else
            for (var i = 0; i < visible.length; i++)
              _row(
                theme: theme,
                item: visible[i],
                selected: i == sel,
                selBg: selBg,
                selFg: selFg,
                muted: muted,
              ),
          if (items.length > maxVisible)
            Text(
              '… ${items.length - maxVisible} more',
              style: mutedStyle,
            ),
        ],
      ),
    );
  }

  Widget _row({
    required Theme theme,
    required AutocompleteItem item,
    required bool selected,
    required Color selBg,
    required Color selFg,
    required Color muted,
  }) {
    final labelStyle = theme.bodySmall.copy()
      ..foreground(selected ? selFg : theme.onSurface)
      ..bold(selected);
    final descStyle = theme.bodySmall.copy()
      ..foreground(selected ? selFg : muted);

    final row = Row(
      gap: 1,
      children: [
        Text(
          selected ? '›' : ' ',
          style: labelStyle,
        ),
        Expanded(
          child: Text(item.label, style: labelStyle, softWrap: false),
        ),
        if (item.description != null && item.description!.isNotEmpty)
          Flexible(
            child: Text(
              item.description!,
              style: descStyle,
              softWrap: false,
            ),
          ),
      ],
    );

    if (!selected) return row;
    return Container(
      color: selBg,
      child: row,
    );
  }
}
