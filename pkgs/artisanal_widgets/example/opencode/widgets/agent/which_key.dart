/// OpenCode example-local which-key panel (not a framework API).
///
/// Used to explore agent/chord UX patterns. Prefer promoting only
/// generic pieces into artisanal_widgets after they prove broadly useful.
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui show KeyChordBinding;
import 'package:artisanal_widgets/widgets.dart' as w;

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

  final String keyLabel;
  final String description;
  final String group;
  final String? id;
}

/// Builds [WhichKeyEntry]s from [tui.KeyChordBinding]s.
List<WhichKeyEntry> whichKeyEntriesFromChords(
  Iterable<tui.KeyChordBinding> bindings, {
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

/// Pending-chord discoverability panel (OpenCode which-key style).
class WhichKeyPanel extends w.StatelessWidget {
  WhichKeyPanel({
    required this.entries,
    this.prefixLabel,
    this.title,
    this.layout = WhichKeyLayout.dock,
    this.selectedGroup,
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

  final List<WhichKeyEntry> entries;
  final String? prefixLabel;
  final String? title;
  final WhichKeyLayout layout;
  final String? selectedGroup;
  final int columnGap;
  final int rowGap;
  final style.Color? background;
  final style.Color? borderColor;
  final style.Color? keyBackground;
  final style.Color? keyForeground;
  final style.Color? descriptionForeground;
  final style.Color? mutedForeground;
  final style.Color? accentForeground;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
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

    final headerBits = <w.Widget>[
      w.Text(title ?? 'which-key', style: titleStyle),
      if (prefixLabel != null && prefixLabel!.isNotEmpty) ...[
        w.Text('·', style: headerStyle),
        w.Frame(
          padding: const w.EdgeInsets.symmetric(horizontal: 1),
          background: kBg,
          child: w.Text(
            prefixLabel!,
            style: theme.labelSmall.copy()..foreground(kFg),
          ),
        ),
        w.Text('then…', style: headerStyle),
      ],
      if (groups.length > 1) ...[
        w.Spacer(),
        w.Text(
          groups
              .map(
                (g) => g == (selectedGroup ?? groups.first) ? '[$g]' : g,
              )
              .join('  '),
          style: headerStyle,
        ),
      ],
    ];

    final body = visible.isEmpty
        ? w.Text('No bindings', style: emptyStyle)
        : _buildColumns(context, visible, kBg, kFg, descFg);

    final pad = layout == WhichKeyLayout.overlay
        ? const w.EdgeInsets.all(1)
        : const w.EdgeInsets.symmetric(horizontal: 1, vertical: 0);

    return w.Frame(
      padding: pad,
      background: bg,
      border: style.Border.rounded,
      borderColor: border,
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Row(gap: 1, children: headerBits),
          w.Divider(style: style.Style().foreground(border)),
          body,
          if (layout == WhichKeyLayout.overlay)
            w.Text('esc cancel', style: headerStyle),
        ],
      ),
    );
  }

  w.Widget _buildColumns(
    w.BuildContext context,
    List<WhichKeyEntry> items,
    style.Color kBg,
    style.Color kFg,
    style.Color descFg,
  ) {
    return w.LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (w.MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);

        const minCol = 28;
        final cols = math.max(1, math.min(3, maxW ~/ (minCol + columnGap)));
        final colWidth = math.max(
          minCol,
          (maxW - columnGap * (cols - 1)) ~/ cols,
        );

        final perCol = (items.length + cols - 1) ~/ cols;
        final columns = <w.Widget>[];
        for (var c = 0; c < cols; c++) {
          final start = c * perCol;
          if (start >= items.length) break;
          final end = math.min(items.length, start + perCol);
          final slice = items.sublist(start, end);
          columns.add(
            w.SizedBox(
              width: colWidth.toDouble(),
              child: w.Column(
                gap: rowGap,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: [
                  for (final e in slice)
                    _WhichKeyRow(
                      entry: e,
                      maxWidth: colWidth,
                      keyBackground: kBg,
                      keyForeground: kFg,
                      descriptionForeground: descFg,
                    ),
                ],
              ),
            ),
          );
        }

        return w.Row(
          gap: columnGap,
          crossAxisAlignment: w.CrossAxisAlignment.start,
          children: columns,
        );
      },
    );
  }
}

class _WhichKeyRow extends w.StatelessWidget {
  _WhichKeyRow({
    required this.entry,
    required this.maxWidth,
    required this.keyBackground,
    required this.keyForeground,
    required this.descriptionForeground,
  });

  final WhichKeyEntry entry;
  final int maxWidth;
  final style.Color keyBackground;
  final style.Color keyForeground;
  final style.Color descriptionForeground;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final keyStyle = theme.labelSmall.copy()..foreground(keyForeground);
    final descStyle = theme.bodySmall.copy()..foreground(descriptionForeground);

    final keyW = entry.keyLabel.length + 2;
    final descBudget = math.max(4, maxWidth - keyW - 1);
    var desc = entry.description;
    if (desc.length > descBudget) {
      desc = '${desc.substring(0, descBudget - 1)}…';
    }

    return w.Row(
      gap: 1,
      children: [
        w.Frame(
          padding: const w.EdgeInsets.symmetric(horizontal: 1),
          background: keyBackground,
          child: w.Text(entry.keyLabel, style: keyStyle),
        ),
        w.Text(desc, style: descStyle, softWrap: false),
      ],
    );
  }
}
