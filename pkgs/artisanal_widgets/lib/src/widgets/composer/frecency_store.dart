/// In-memory frecency ranking (OpenCode-style frequency / recency).
///
/// Score = frequency / (1 + ageInDays). Higher is better.
library;

/// Single frecency observation for a key.
final class FrecencyEntry {
  const FrecencyEntry({required this.frequency, required this.lastOpen});

  final int frequency;
  final DateTime lastOpen;

  FrecencyEntry touch({DateTime? now}) {
    final at = now ?? DateTime.now();
    return FrecencyEntry(frequency: frequency + 1, lastOpen: at);
  }
}

/// Tracks how often and how recently keys are used for ranking lists.
class FrecencyStore {
  FrecencyStore({this.maxEntries = 1000, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Soft cap on retained keys (oldest lastOpen dropped first).
  final int maxEntries;
  final DateTime Function() _clock;

  final Map<String, FrecencyEntry> _data = {};

  /// Snapshot of tracked entries.
  Map<String, FrecencyEntry> get data => Map.unmodifiable(_data);

  /// Record a use of [key].
  void touch(String key, {DateTime? now}) {
    final at = now ?? _clock();
    final prev = _data[key];
    _data[key] = prev == null
        ? FrecencyEntry(frequency: 1, lastOpen: at)
        : prev.touch(now: at);
    _trim();
  }

  /// Frecency score for [key] (0 if unknown).
  double score(String key, {DateTime? now}) {
    final entry = _data[key];
    if (entry == null) return 0;
    final at = now ?? _clock();
    final ageDays =
        at.difference(entry.lastOpen).inMilliseconds / 86400000.0;
    return entry.frequency / (1 + (ageDays < 0 ? 0 : ageDays));
  }

  /// Sort [items] by descending frecency of [keyOf], stable for ties.
  List<T> sortByFrecency<T>(
    Iterable<T> items,
    String Function(T item) keyOf, {
    DateTime? now,
  }) {
    final at = now ?? _clock();
    final list = items.toList();
    list.sort((a, b) {
      final sa = score(keyOf(a), now: at);
      final sb = score(keyOf(b), now: at);
      final cmp = sb.compareTo(sa);
      if (cmp != 0) return cmp;
      return keyOf(a).compareTo(keyOf(b));
    });
    return list;
  }

  void clear() => _data.clear();

  void _trim() {
    if (_data.length <= maxEntries) return;
    final sorted = _data.entries.toList()
      ..sort((a, b) => b.value.lastOpen.compareTo(a.value.lastOpen));
    _data
      ..clear()
      ..addEntries(sorted.take(maxEntries));
  }
}
