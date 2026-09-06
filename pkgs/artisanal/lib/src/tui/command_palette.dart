/// Shared command-palette data and ranking primitives.
library;

import 'cmd.dart';
import '../scoring/scoring.dart';

/// Callback invoked by a command-palette item.
typedef CommandPaletteCallback = Cmd? Function();

/// A portable command-palette item, independent of any widget framework.
final class CommandPaletteItem {
  const CommandPaletteItem({
    required this.label,
    this.description,
    this.shortcut,
    this.group,
    this.tags = const [],
    this.onSelect,
    this.enabled = true,
  });

  final String label;
  final String? description;
  final String? shortcut;
  final String? group;
  final List<String> tags;
  final CommandPaletteCallback? onSelect;
  final bool enabled;
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

/// Shared query and selection controller used by palette presentations.
///
/// Filtering uses Artisanal's incremental Bayesian scorer, including tags and
/// conformal ranking, so TEA and widget hosts observe the same ordering.
final class CommandPaletteController {
  CommandPaletteController({List<CommandPaletteItem> items = const []})
    : _items = List<CommandPaletteItem>.of(items);

  final IncrementalScorer _scorer = IncrementalScorer();
  final ConformalRanker _ranker = const ConformalRanker();
  List<CommandPaletteItem> _items;
  String query = '';
  int selectedIndex = 0;

  List<CommandPaletteItem> get items =>
      List<CommandPaletteItem>.unmodifiable(_items);

  /// Replaces source items and keeps selection in range.
  void updateItems(List<CommandPaletteItem> value) {
    _items = List<CommandPaletteItem>.of(value);
    final count = filteredItems.length;
    selectedIndex = count == 0 ? 0 : selectedIndex.clamp(0, count - 1);
  }

  /// Updates the query and selects the highest-ranked result.
  void updateQuery(String value) {
    query = value;
    selectedIndex = 0;
  }

  /// Enabled items ordered by the shared Bayesian ranking pipeline.
  List<CommandPaletteItem> get filteredItems {
    final enabled = _items.where((item) => item.enabled).toList();
    if (query.isEmpty) return List<CommandPaletteItem>.unmodifiable(enabled);
    final results = _scorer.scoreCorpusWithTags(
      query,
      enabled.map((item) => item.label).toList(),
      enabled.map((item) => item.tags).toList(),
    );
    final ranked = _ranker.rank(results);
    return List<CommandPaletteItem>.unmodifiable([
      for (final rankedItem in ranked.items)
        if (rankedItem.result.matchType != MatchType.noMatch)
          enabled[rankedItem.originalIndex],
    ]);
  }

  /// Selects [index], wrapping around the current result list.
  bool selectIndex(int index) {
    final count = filteredItems.length;
    if (count == 0) {
      selectedIndex = 0;
      return false;
    }
    selectedIndex = index % count;
    return true;
  }

  /// Moves selection by [delta], wrapping at either end.
  bool moveSelection(int delta) => selectIndex(selectedIndex + delta);

  /// Currently selected filtered item.
  CommandPaletteItem? get selectedItem {
    final filtered = filteredItems;
    return filtered.isEmpty ? null : filtered[selectedIndex];
  }
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
