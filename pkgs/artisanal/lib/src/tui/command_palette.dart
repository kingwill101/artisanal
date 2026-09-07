/// Shared command-palette data, ranking, and viewport primitives.
library;

import 'cmd.dart';

/// Callback invoked by a command-palette item.
typedef CommandPaletteCallback = Cmd? Function();

/// A portable command-palette item, independent of any widget framework.
final class CommandPaletteItem {
  const CommandPaletteItem({
    required this.label,
    this.id,
    this.payload,
    this.description,
    this.shortcut,
    this.group,
    this.tags = const [],
    this.onSelect,
    this.enabled = true,
  });

  /// Stable identity used to map items across rebuilds.
  ///
  /// Editor commands should supply their command ID. When omitted, hosts may
  /// fall back to [label] or object identity.
  final String? id;

  /// Host-defined payload such as an editor command or completion item.
  final Object? payload;

  final String label;
  final String? description;
  final String? shortcut;
  final String? group;
  final List<String> tags;
  final CommandPaletteCallback? onSelect;
  final bool enabled;

  /// Identity used for selection restoration. Prefers [id], then [label].
  String get identity => id ?? label;
}

/// A scored palette match with deterministic ranking evidence.
final class CommandPaletteMatch {
  const CommandPaletteMatch({
    required this.item,
    required this.score,
    required this.evidence,
    required this.originalIndex,
  });

  final CommandPaletteItem item;
  final double score;
  final Map<String, double> evidence;
  final int originalIndex;
}

/// Inclusive-exclusive window of filtered items that should stay on screen.
final class CommandPaletteWindow {
  const CommandPaletteWindow({
    required this.start,
    required this.end,
    required this.selectedIndex,
    required this.itemCount,
    required this.viewportSize,
  });

  /// First visible item index, inclusive.
  final int start;

  /// Last visible item index, exclusive.
  final int end;

  final int selectedIndex;
  final int itemCount;
  final int viewportSize;

  bool get isEmpty => start >= end;
  bool get hasMoreAbove => start > 0;
  bool get hasMoreBelow => end < itemCount;
  int get length => end - start;
}

/// Shared query, ranking, selection, and viewport controller.
///
/// Filtering always goes through [matchCommandPaletteItems] so static
/// matching, TEA rendering, and widget rendering produce identical order.
final class CommandPaletteController {
  CommandPaletteController({
    List<CommandPaletteItem> items = const [],
    this.viewportSize = 7,
  }) : _items = List<CommandPaletteItem>.of(items);

  List<CommandPaletteItem> _items;
  String query = '';
  int selectedIndex = 0;

  /// Number of result rows a host intends to show.
  int viewportSize;

  List<CommandPaletteItem>? _filterSource;
  String? _filterQuery;
  List<CommandPaletteMatch>? _cachedMatches;

  List<CommandPaletteItem> get items =>
      List<CommandPaletteItem>.unmodifiable(_items);

  /// Replaces source items and keeps the previously selected identity in view.
  void updateItems(List<CommandPaletteItem> value) {
    final selectedId = selectedItem?.identity;
    _items = List<CommandPaletteItem>.of(value);
    _invalidateFilter();
    final filtered = filteredItems;
    if (filtered.isEmpty) {
      selectedIndex = 0;
      return;
    }
    if (selectedId != null) {
      final index = filtered.indexWhere((item) => item.identity == selectedId);
      if (index >= 0) {
        selectedIndex = index;
        return;
      }
    }
    selectedIndex = selectedIndex.clamp(0, filtered.length - 1);
  }

  /// Updates the query and selects the highest-ranked result.
  void updateQuery(String value) {
    query = value;
    _invalidateFilter();
    selectedIndex = 0;
  }

  /// Ranked matches for the current query, including scoring evidence.
  List<CommandPaletteMatch> get matches {
    if (_cachedMatches != null &&
        identical(_filterSource, _items) &&
        _filterQuery == query) {
      return _cachedMatches!;
    }
    _filterSource = _items;
    _filterQuery = query;
    _cachedMatches = matchCommandPaletteItems(_items, query);
    return _cachedMatches!;
  }

  /// Enabled items ordered by the shared ranking pipeline.
  List<CommandPaletteItem> get filteredItems =>
      List<CommandPaletteItem>.unmodifiable([
        for (final match in matches) match.item,
      ]);

  /// Visible slice of [filteredItems] that keeps [selectedIndex] on screen.
  CommandPaletteWindow visibleWindow({int? viewportSize}) {
    final filtered = filteredItems;
    return commandPaletteVisibleWindow(
      itemCount: filtered.length,
      selectedIndex: selectedIndex,
      viewportSize: viewportSize ?? this.viewportSize,
    );
  }

  /// Items inside [visibleWindow].
  List<CommandPaletteItem> visibleItems({int? viewportSize}) {
    final filtered = filteredItems;
    final window = visibleWindow(viewportSize: viewportSize);
    return List<CommandPaletteItem>.unmodifiable(
      filtered.sublist(window.start, window.end),
    );
  }

  /// Selects [index], wrapping around the current result list.
  bool selectIndex(int index) {
    final count = filteredItems.length;
    if (count == 0) {
      selectedIndex = 0;
      return false;
    }
    selectedIndex = index % count;
    if (selectedIndex < 0) selectedIndex += count;
    return true;
  }

  /// Moves selection by [delta], wrapping at either end.
  bool moveSelection(int delta) => selectIndex(selectedIndex + delta);

  /// Currently selected filtered item.
  CommandPaletteItem? get selectedItem {
    final filtered = filteredItems;
    return filtered.isEmpty ? null : filtered[selectedIndex];
  }

  void _invalidateFilter() {
    _filterSource = null;
    _filterQuery = null;
    _cachedMatches = null;
  }
}

/// Centers [selectedIndex] inside a window of [viewportSize] items.
CommandPaletteWindow commandPaletteVisibleWindow({
  required int itemCount,
  required int selectedIndex,
  required int viewportSize,
}) {
  final size = viewportSize < 1 ? 1 : viewportSize;
  if (itemCount <= 0) {
    return CommandPaletteWindow(
      start: 0,
      end: 0,
      selectedIndex: 0,
      itemCount: 0,
      viewportSize: size,
    );
  }
  final selected = selectedIndex.clamp(0, itemCount - 1);
  final maxStart = (itemCount - size).clamp(0, itemCount);
  final start = (selected - size ~/ 2).clamp(0, maxStart);
  final end = (start + size).clamp(start, itemCount);
  return CommandPaletteWindow(
    start: start,
    end: end,
    selectedIndex: selected,
    itemCount: itemCount,
    viewportSize: size,
  );
}

/// Renders the shared query, rows, and overflow footer used by TEA hosts.
List<String> renderCommandPaletteBody({
  required String query,
  required List<CommandPaletteItem> items,
  required int selectedIndex,
  required CommandPaletteWindow window,
  String emptyLabel = 'No matching commands',
}) {
  final lines = <String>['> $query', ''];
  for (var index = window.start; index < window.end; index++) {
    final selected = index == selectedIndex;
    lines.add('${selected ? '❯' : ' '} ${items[index].label}');
  }
  if (items.isEmpty) lines.add('  $emptyLabel');
  if (items.length > window.viewportSize) {
    lines.add(
      '  ${selectedIndex + 1}/${items.length}'
      '${window.hasMoreAbove ? '  ↑ more' : ''}'
      '${window.hasMoreBelow ? '  ↓ more' : ''}',
    );
  }
  return lines;
}

/// Filters and ranks [items] using the established palette matching contract.
List<CommandPaletteMatch> matchCommandPaletteItems(
  List<CommandPaletteItem> items,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  final matches = <CommandPaletteMatch>[];
  for (var index = 0; index < items.length; index++) {
    final item = items[index];
    if (!item.enabled) continue;
    final evidence = <String, double>{};
    final label = item.label.toLowerCase();
    final description = item.description?.toLowerCase();
    final group = item.group?.toLowerCase();
    double score = 0;
    if (normalizedQuery.isEmpty) {
      evidence['query:empty'] = 1;
    } else {
      if (label == normalizedQuery) {
        score += 10000;
        evidence['label:exact'] = 10000;
      }
      if (label.startsWith(normalizedQuery)) {
        score += 6000;
        evidence['label:prefix'] = 6000;
      }
      if (label.contains(normalizedQuery)) {
        score += 4000;
        evidence['label:contains'] = 4000;
      }
      if (description?.contains(normalizedQuery) ?? false) {
        score += 1800;
        evidence['description:contains'] = 1800;
      }
      if (group?.contains(normalizedQuery) ?? false) {
        score += 1200;
        evidence['group:contains'] = 1200;
      }
      for (final tag in item.tags) {
        final normalizedTag = tag.toLowerCase();
        if (normalizedTag == normalizedQuery) {
          score += 2200;
          evidence['tag:exact'] = 2200;
          break;
        }
        if (normalizedTag.contains(normalizedQuery)) {
          score += 1500;
          evidence['tag:contains'] = 1500;
          break;
        }
      }
      final subsequence = _subsequenceScore(normalizedQuery, label);
      if (subsequence > 0) {
        score += subsequence;
        evidence['label:subsequence'] = subsequence;
      }
      final typo = _typoScore(normalizedQuery, label);
      if (typo > 0) {
        score += typo;
        evidence['label:typo'] = typo;
      }
    }
    if (normalizedQuery.isEmpty || score > 0) {
      matches.add(
        CommandPaletteMatch(
          item: item,
          score: score,
          evidence: Map<String, double>.unmodifiable(evidence),
          originalIndex: index,
        ),
      );
    }
  }
  matches.sort((left, right) {
    if (normalizedQuery.isEmpty) {
      return left.originalIndex.compareTo(right.originalIndex);
    }
    final score = right.score.compareTo(left.score);
    if (score != 0) return score;
    final label = left.item.label.compareTo(right.item.label);
    return label != 0
        ? label
        : left.originalIndex.compareTo(right.originalIndex);
  });
  return List<CommandPaletteMatch>.unmodifiable(matches);
}

double _subsequenceScore(String query, String target) {
  if (query.isEmpty) return 0;
  var queryIndex = 0;
  var firstMatchIndex = -1;
  var lastMatchIndex = -1;
  for (
    var targetIndex = 0;
    targetIndex < target.length && queryIndex < query.length;
    targetIndex++
  ) {
    if (target[targetIndex] != query[queryIndex]) continue;
    if (queryIndex == 0) firstMatchIndex = targetIndex;
    queryIndex++;
    lastMatchIndex = targetIndex;
  }
  if (queryIndex != query.length) return 0;
  final span = lastMatchIndex - firstMatchIndex + 1;
  final score =
      1500.0 - (span - query.length) * 6.0 - firstMatchIndex.toDouble();
  return score <= 0 ? 20 : score;
}

double _typoScore(String query, String target) {
  if (query.length < 2 || query.length > 8) return 0;
  if ((target.length - query.length).abs() > 2) return 0;
  final distance = _levenshtein(query, target);
  return distance == 0 || distance > 2 ? 0 : 2400 - distance * 800;
}

int _levenshtein(String left, String right) {
  if (left == right) return 0;
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;
  var previous = List<int>.generate(right.length + 1, (index) => index);
  var current = List<int>.filled(right.length + 1, 0);
  for (var leftIndex = 1; leftIndex <= left.length; leftIndex++) {
    current[0] = leftIndex;
    for (var rightIndex = 1; rightIndex <= right.length; rightIndex++) {
      final substitution = left[leftIndex - 1] == right[rightIndex - 1] ? 0 : 1;
      current[rightIndex] = [
        previous[rightIndex] + 1,
        current[rightIndex - 1] + 1,
        previous[rightIndex - 1] + substitution,
      ].reduce((a, b) => a < b ? a : b);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[right.length];
}
