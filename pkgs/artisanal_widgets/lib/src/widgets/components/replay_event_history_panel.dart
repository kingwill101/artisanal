
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';


enum ReplayEventHistoryFilter { all, renderCaptures, custom }

enum ReplayEventHistoryMode { flat, grouped }

final class ReplayEventHistoryState {
  const ReplayEventHistoryState({
    this.filter = ReplayEventHistoryFilter.all,
    this.mode = ReplayEventHistoryMode.flat,
    this.expanded = false,
  });

  final ReplayEventHistoryFilter filter;
  final ReplayEventHistoryMode mode;
  final bool expanded;

  ReplayEventHistoryState copyWith({
    ReplayEventHistoryFilter? filter,
    ReplayEventHistoryMode? mode,
    bool? expanded,
  }) {
    return ReplayEventHistoryState(
      filter: filter ?? this.filter,
      mode: mode ?? this.mode,
      expanded: expanded ?? this.expanded,
    );
  }

  ReplayEventHistoryState withFilter(ReplayEventHistoryFilter filter) =>
      copyWith(filter: filter);

  ReplayEventHistoryState withMode(ReplayEventHistoryMode mode) =>
      copyWith(mode: mode);

  ReplayEventHistoryState withExpanded(bool expanded) =>
      copyWith(expanded: expanded);
}

class ReplayEventHistoryBrowser extends StatelessWidget {
  ReplayEventHistoryBrowser({
    required this.events,
    required this.state,
    required this.onStateChanged,
    this.title = 'Replay History',
    this.maxItems = 5,
    this.showTypeChips = false,
    this.showFilterChips = true,
    this.showModeChips = true,
    this.showExpandToggle = true,
    this.showFilterSummary = true,
    this.showModeSummary = true,
    super.key,
  });

  ReplayEventHistoryBrowser.interactive({
    required this.events,
    required this.state,
    required this.onStateChanged,
    this.title = 'Replay History',
    this.maxItems = 5,
    this.showTypeChips = false,
    super.key,
  }) : showFilterChips = true,
       showModeChips = true,
       showExpandToggle = true,
       showFilterSummary = true,
       showModeSummary = true;

  ReplayEventHistoryBrowser.renderCaptures({
    required this.events,
    required this.state,
    required this.onStateChanged,
    this.title = 'Replay History',
    this.maxItems = 3,
    this.showTypeChips = true,
    super.key,
  }) : showFilterChips = false,
       showModeChips = true,
       showExpandToggle = true,
       showFilterSummary = false,
       showModeSummary = true;

  final List<ReplayEventPresentation> events;
  final ReplayEventHistoryState state;
  final ValueCmdCallback<ReplayEventHistoryState>? onStateChanged;
  final String title;
  final int maxItems;
  final bool showTypeChips;
  final bool showFilterChips;
  final bool showModeChips;
  final bool showExpandToggle;
  final bool showFilterSummary;
  final bool showModeSummary;

  @override
  Widget build(BuildContext context) {
    return ReplayEventHistoryPanel(
      events: events,
      title: title,
      maxItems: maxItems,
      filter: state.filter,
      mode: state.mode,
      expanded: state.expanded,
      showTypeChips: showTypeChips,
      showFilterChips: showFilterChips,
      showModeChips: showModeChips,
      showExpandToggle: showExpandToggle,
      showFilterSummary: showFilterSummary,
      showModeSummary: showModeSummary,
      onFilterSelected: onStateChanged == null
          ? null
          : (filter) => onStateChanged?.call(state.withFilter(filter)),
      onModeSelected: onStateChanged == null
          ? null
          : (mode) => onStateChanged?.call(state.withMode(mode)),
      onExpandedChanged: onStateChanged == null
          ? null
          : (expanded) => onStateChanged?.call(state.withExpanded(expanded)),
    );
  }
}

class ReplayEventHistoryPanel extends StatelessWidget {
  ReplayEventHistoryPanel({
    required this.events,
    this.title = 'Replay History',
    this.maxItems = 5,
    this.filter = ReplayEventHistoryFilter.all,
    this.mode = ReplayEventHistoryMode.flat,
    this.expanded = false,
    this.showTypeChips = false,
    this.showFilterChips = false,
    this.showModeChips = false,
    this.showExpandToggle = false,
    this.showFilterSummary = true,
    this.showModeSummary = true,
    this.onFilterSelected,
    this.onModeSelected,
    this.onExpandedChanged,
    super.key,
  });

  final List<ReplayEventPresentation> events;
  final String title;
  final int maxItems;
  final ReplayEventHistoryFilter filter;
  final ReplayEventHistoryMode mode;
  final bool expanded;
  final bool showTypeChips;
  final bool showFilterChips;
  final bool showModeChips;
  final bool showExpandToggle;
  final bool showFilterSummary;
  final bool showModeSummary;
  final ValueCmdCallback<ReplayEventHistoryFilter>? onFilterSelected;
  final ValueCmdCallback<ReplayEventHistoryMode>? onModeSelected;
  final ValueCmdCallback<bool>? onExpandedChanged;

  bool get isEmpty => events.isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final filteredEvents = events
        .where((event) => _matchesFilter(event))
        .toList(growable: false);
    final effectiveMaxItems = expanded ? filteredEvents.length : maxItems;
    final visibleEvents = filteredEvents
        .take(effectiveMaxItems)
        .toList(growable: false);
    final groupedEvents = _groupEvents(visibleEvents);
    final typeCounts = _typeCounts(filteredEvents);
    final canExpand = filteredEvents.length > maxItems;
    final hiddenCount = filteredEvents.length - visibleEvents.length;
    final hiddenGroupedCount = _groupEvents(
      filteredEvents.skip(effectiveMaxItems).toList(growable: false),
    ).length;
    final totalGroupedCount = _groupEvents(filteredEvents).length;

    return PanelBox(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        gap: 1,
        children: [
          if (showFilterChips)
            Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                for (final candidate in ReplayEventHistoryFilter.values)
                  ChoiceChip(
                    key: ValueKey('replay-history-filter-${candidate.name}'),
                    label: Text(_filterLabel(candidate)),
                    selected: candidate == filter,
                    onSelected: onFilterSelected == null
                        ? null
                        : (selected) {
                            if (!selected) return null;
                            return onFilterSelected?.call(candidate);
                          },
                  ),
              ],
            ),
          if (showModeChips)
            Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                for (final candidate in ReplayEventHistoryMode.values)
                  ChoiceChip(
                    key: ValueKey('replay-history-mode-${candidate.name}'),
                    label: Text(_modeLabel(candidate)),
                    selected: candidate == mode,
                    onSelected: onModeSelected == null
                        ? null
                        : (selected) {
                            if (!selected) return null;
                            return onModeSelected?.call(candidate);
                          },
                  ),
              ],
            ),
          if (showFilterSummary && filter != ReplayEventHistoryFilter.all)
            Text('filter: ${_filterLabel(filter)}', style: theme.labelSmall),
          if (showModeSummary && mode != ReplayEventHistoryMode.flat)
            Text('mode: ${_modeLabel(mode)}', style: theme.labelSmall),
          if (showTypeChips && typeCounts.isNotEmpty)
            Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                for (final entry in typeCounts.entries)
                  Chip(label: Text('${entry.key} ${entry.value}')),
              ],
            ),
          if (showExpandToggle && canExpand)
            Row(
              gap: 1,
              children: [
                ActionChip(
                  key: const ValueKey('replay-history-expand-toggle'),
                  label: Text(
                    _expandLabel(
                      totalEventCount: filteredEvents.length,
                      totalGroupedCount: totalGroupedCount,
                    ),
                  ),
                  onPressed: onExpandedChanged == null
                      ? null
                      : () => onExpandedChanged?.call(!expanded),
                ),
                if (!expanded && hiddenCount > 0)
                  Text(
                    _hiddenSummaryLabel(
                      hiddenCount: hiddenCount,
                      hiddenGroupedCount: hiddenGroupedCount,
                    ),
                    style: theme.labelSmall,
                  ),
              ],
            ),
          if (visibleEvents.isEmpty)
            Text(
              events.isEmpty
                  ? 'No replay events yet.'
                  : 'No matching replay events.',
              style: theme.bodySmall,
            )
          else if (mode == ReplayEventHistoryMode.flat)
            ...visibleEvents.map(
              (event) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                gap: 0,
                children: [
                  Text(event.summary, style: theme.bodySmall),
                  Text(event.statusHint, style: theme.labelSmall),
                ],
              ),
            )
          else
            ...groupedEvents.map(
              (group) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                gap: 0,
                children: [
                  Text(
                    '${group.count}x ${group.summary}',
                    style: theme.bodySmall,
                  ),
                  Text(group.statusHint, style: theme.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesFilter(ReplayEventPresentation event) {
    final type = event.fields['type'];
    return switch (filter) {
      ReplayEventHistoryFilter.all => true,
      ReplayEventHistoryFilter.renderCaptures =>
        type == 'runtime.render_capture',
      ReplayEventHistoryFilter.custom => type != 'runtime.render_capture',
    };
  }

  String _filterLabel(ReplayEventHistoryFilter filter) => switch (filter) {
    ReplayEventHistoryFilter.all => 'all',
    ReplayEventHistoryFilter.renderCaptures => 'render captures',
    ReplayEventHistoryFilter.custom => 'custom events',
  };

  String _modeLabel(ReplayEventHistoryMode mode) => switch (mode) {
    ReplayEventHistoryMode.flat => 'flat',
    ReplayEventHistoryMode.grouped => 'grouped',
  };

  String _hiddenSummaryLabel({
    required int hiddenCount,
    required int hiddenGroupedCount,
  }) {
    if (mode == ReplayEventHistoryMode.grouped) {
      return hiddenGroupedCount == 1
          ? '1 group hidden'
          : '$hiddenGroupedCount groups hidden';
    }
    return hiddenCount == 1 ? '1 hidden' : '$hiddenCount hidden';
  }

  String _expandLabel({
    required int totalEventCount,
    required int totalGroupedCount,
  }) {
    if (expanded) return 'show less';
    if (mode == ReplayEventHistoryMode.grouped) {
      return totalGroupedCount == 1
          ? 'show all 1 group'
          : 'show all $totalGroupedCount groups';
    }
    return 'show all $totalEventCount';
  }

  List<_ReplayEventGroup> _groupEvents(List<ReplayEventPresentation> events) {
    final groups = <String, _ReplayEventGroup>{};
    final order = <String>[];
    for (final event in events) {
      final key =
          '${event.fields['type'] ?? event.summary}|${event.statusHint}';
      final existing = groups[key];
      if (existing == null) {
        groups[key] = _ReplayEventGroup(
          summary: event.summary,
          statusHint: event.statusHint,
          count: 1,
        );
        order.add(key);
      } else {
        groups[key] = _ReplayEventGroup(
          summary: existing.summary,
          statusHint: existing.statusHint,
          count: existing.count + 1,
        );
      }
    }
    return order.map((key) => groups[key]!).toList(growable: false);
  }

  Map<String, int> _typeCounts(List<ReplayEventPresentation> events) {
    if (mode == ReplayEventHistoryMode.grouped) {
      return _groupedTypeCounts(events);
    }
    final counts = <String, int>{};
    for (final event in events) {
      final label = _typeLabel(event);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _groupedTypeCounts(List<ReplayEventPresentation> events) {
    final seen = <String>{};
    final counts = <String, int>{};
    for (final event in events) {
      final typeLabel = _typeLabel(event);
      final key = '$typeLabel|${event.statusHint}';
      if (!seen.add(key)) continue;
      counts[typeLabel] = (counts[typeLabel] ?? 0) + 1;
    }
    return counts;
  }

  String _typeLabel(ReplayEventPresentation event) {
    final type = event.fields['type'];
    if (type is! String || type.isEmpty) return 'unknown';
    return switch (type) {
      'runtime.render_capture' => 'render',
      _ => type,
    };
  }
}

final class _ReplayEventGroup {
  const _ReplayEventGroup({
    required this.summary,
    required this.statusHint,
    required this.count,
  });

  final String summary;
  final String statusHint;
  final int count;
}
