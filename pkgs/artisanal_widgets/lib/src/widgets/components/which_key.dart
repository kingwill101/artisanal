import 'dart:math' as math;

import 'package:artisanal/style.dart' show Color, Border, Style;
import 'package:artisanal/runtime.dart' show KeyChordBinding, ShortcutContinuation;
import 'package:artisanal_widgets/widgets.dart';

/// Layout mode for [WhichKeyPanel].
enum WhichKeyLayout {
  /// Compact bottom dock (default).
  dock,

  /// Taller bordered panel for overlays / help.
  overlay,
}

/// A single continuation entry shown while a key chord is pending.
final class WhichKeyEntry {
  const WhichKeyEntry({
    required this.keyLabel,
    required this.description,
    this.group = 'Commands',
    this.id,
  });

  /// Key glyph(s) to press (e.g. `b`, `ctrl+p`).
  final String keyLabel;

  /// Human-readable action description.
  final String description;

  /// Optional group tab/section label.
  final String group;

  /// Optional chord / command id for selection callbacks.
  final String? id;
}

/// Builds [WhichKeyEntry]s from [KeyChordBinding]s that share a prefix.
///
/// When [prefixKeyLabel] is non-null, only bindings whose prefix help key
/// matches are included (case-insensitive). Otherwise all bindings are used.
List<WhichKeyEntry> whichKeyEntriesFromChords(
  Iterable<KeyChordBinding> bindings, {
  String? prefixKeyLabel,
}) {
  final prefix = prefixKeyLabel?.toLowerCase();
  final entries = <WhichKeyEntry>[];
  for (final b in bindings) {
    final pHelp = b.prefix.help;
    if (prefix != null &&
        pHelp.key.isNotEmpty &&
        pHelp.key.toLowerCase() != prefix) {
      continue;
    }
    final cont = b.key.help;
    final keyLabel = cont.key.isNotEmpty
        ? cont.key
        : (b.key.keys.isNotEmpty ? b.key.keys.first : b.id);
    final desc = cont.desc.isNotEmpty ? cont.desc : b.id;
    final group = pHelp.desc.isNotEmpty ? pHelp.desc : 'Commands';
    entries.add(
      WhichKeyEntry(
        id: b.id,
        keyLabel: keyLabel,
        description: desc,
        group: group,
      ),
    );
  }
  return entries;
}

/// Builds [WhichKeyEntry]s from hub [ShortcutContinuation]s.
List<WhichKeyEntry> whichKeyEntriesFromContinuations(
  Iterable<ShortcutContinuation> continuations,
) {
  return [
    for (final c in continuations)
      WhichKeyEntry(
        id: c.actionId,
        keyLabel: c.keyLabel,
        description: c.description,
        group: c.group,
      ),
  ];
}

/// Pending-chord discoverability panel (which-key style).
///
/// Pure presentation: apps feed [entries] from [KeyChordBinding]s (via
/// [whichKeyEntriesFromChords]) when a [KeyChordPrefixMsg] is active.
///
/// ```dart
/// if (chordActive)
///   Align(
///     alignment: Alignment.bottomCenter,
///     child: WhichKeyPanel(
///       prefixLabel: 'ctrl+x',
///       entries: whichKeyEntriesFromChords(bindings),
///     ),
///   )
/// ```
class WhichKeyPanel extends StatelessWidget {
  WhichKeyPanel({
    required this.entries,
    this.prefixLabel,
    this.title,
    this.layout = WhichKeyLayout.dock,
    this.selectedGroup,
    this.maxHeight,
    this.columnGap = 4,
    this.rowGap = 0,
    this.background,
    this.borderColor,
    this.keyBackground,
    this.keyForeground,
    this.descriptionForeground,
    this.mutedForeground,
    this.accentForeground,
    super.key,
  });

  /// Continuation keys to display.
  final List<WhichKeyEntry> entries;

  /// Active prefix label (e.g. `ctrl+x`), shown in the header.
  final String? prefixLabel;

  /// Optional header title (defaults to "which-key").
  final String? title;

  /// Visual density / chrome.
  final WhichKeyLayout layout;

  /// When set, only show entries in this group.
  final String? selectedGroup;

  /// Max rows for the body (scrolls via truncation with a footer note).
  final int? maxHeight;

  final int columnGap;
  final int rowGap;

  final Color? background;
  final Color? borderColor;
  final Color? keyBackground;
  final Color? keyForeground;
  final Color? descriptionForeground;
  final Color? mutedForeground;
  final Color? accentForeground;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final border = borderColor ?? theme.border;
    final muted = mutedForeground ?? theme.muted;
    final accent = accentForeground ?? theme.primary;
    final descFg = descriptionForeground ?? theme.onSurface;
    final kBg = keyBackground ?? theme.muted;
    final kFg = keyForeground ?? theme.onSurface;

    final visible = selectedGroup == null
        ? entries
        : entries.where((e) => e.group == selectedGroup).toList();

    final groups = <String>[];
    for (final e in entries) {
      if (!groups.contains(e.group)) groups.add(e.group);
    }

    final headerStyle = theme.labelSmall.copy()..foreground(muted);
    final titleStyle = theme.labelLarge.copy()
      ..foreground(accent)
      ..bold();
    final emptyStyle = theme.bodySmall.copy()..foreground(muted);

    final headerBits = <Widget>[
      Text(title ?? 'which-key', style: titleStyle),
      if (prefixLabel != null && prefixLabel!.isNotEmpty) ...[
        Text('·', style: headerStyle),
        Frame(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          background: kBg,
          child: Text(
            prefixLabel!,
            style: theme.labelSmall.copy()..foreground(kFg),
          ),
        ),
        Text('then…', style: headerStyle),
      ],
      if (groups.length > 1) ...[
        Spacer(),
        Text(
          groups.map((g) => g == (selectedGroup ?? groups.first) ? '[$g]' : g)
              .join('  '),
          style: headerStyle,
        ),
      ],
    ];

    final body = visible.isEmpty
        ? Text('No bindings', style: emptyStyle)
        : _buildColumns(context, visible, kBg, kFg, descFg, muted);

    final pad = layout == WhichKeyLayout.overlay
        ? const EdgeInsets.all(1)
        : const EdgeInsets.symmetric(horizontal: 1, vertical: 0);

    return Frame(
      padding: pad,
      background: bg,
      border: Border.rounded,
      borderColor: border,
      child: Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(gap: 1, children: headerBits),
          Divider(style: Style().foreground(border)),
          body,
          if (layout == WhichKeyLayout.overlay)
            Text(
              'esc cancel',
              style: headerStyle,
            ),
        ],
      ),
    );
  }

  Widget _buildColumns(
    BuildContext context,
    List<WhichKeyEntry> items,
    Color kBg,
    Color kFg,
    Color descFg,
    Color muted,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);

        // Aim for ~28–36 char columns like OpenCode which-key.
        const minCol = 28;
        final cols = math.max(1, math.min(3, maxW ~/ (minCol + columnGap)));
        final colWidth = math.max(
          minCol,
          (maxW - columnGap * (cols - 1)) ~/ cols,
        );

        final perCol = (items.length + cols - 1) ~/ cols;
        final columns = <Widget>[];
        for (var c = 0; c < cols; c++) {
          final start = c * perCol;
          if (start >= items.length) break;
          final end = math.min(items.length, start + perCol);
          final slice = items.sublist(start, end);
          columns.add(
            SizedBox(
              width: colWidth.toDouble(),
              child: Column(
                gap: rowGap,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in slice)
                    _WhichKeyRow(
                      entry: e,
                      maxWidth: colWidth,
                      keyBackground: kBg,
                      keyForeground: kFg,
                      descriptionForeground: descFg,
                      mutedForeground: muted,
                    ),
                ],
              ),
            ),
          );
        }

        return Row(
          gap: columnGap,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns,
        );
      },
    );
  }
}

class _WhichKeyRow extends StatelessWidget {
  _WhichKeyRow({
    required this.entry,
    required this.maxWidth,
    required this.keyBackground,
    required this.keyForeground,
    required this.descriptionForeground,
    required this.mutedForeground,
  });

  final WhichKeyEntry entry;
  final int maxWidth;
  final Color keyBackground;
  final Color keyForeground;
  final Color descriptionForeground;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final keyStyle = theme.labelSmall.copy()..foreground(keyForeground);
    final descStyle = theme.bodySmall.copy()..foreground(descriptionForeground);

    final keyW = entry.keyLabel.length + 2; // frame padding
    final descBudget = math.max(4, maxWidth - keyW - 1);
    var desc = entry.description;
    if (desc.length > descBudget) {
      desc = '${desc.substring(0, descBudget - 1)}…';
    }

    return Row(
      gap: 1,
      children: [
        Frame(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          background: keyBackground,
          child: Text(entry.keyLabel, style: keyStyle),
        ),
        Text(desc, style: descStyle, softWrap: false),
      ],
    );
  }
}
