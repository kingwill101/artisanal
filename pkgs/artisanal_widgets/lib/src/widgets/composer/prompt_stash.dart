/// Labeled prompt draft stash (OpenCode-style save/restore).
library;

/// One stashed prompt draft.
final class PromptStashEntry {
  const PromptStashEntry({
    required this.input,
    required this.timestamp,
    this.label,
  });

  final String input;
  final DateTime timestamp;

  /// Optional short label (defaults to a preview of [input]).
  final String? label;

  String get displayLabel {
    final l = label?.trim();
    if (l != null && l.isNotEmpty) return l;
    final oneLine = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.length <= 40) return oneLine;
    return '${oneLine.substring(0, 39)}…';
  }

  PromptStashEntry copyWith({String? input, DateTime? timestamp, String? label}) {
    return PromptStashEntry(
      input: input ?? this.input,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
    );
  }
}

/// In-memory stack of stashed drafts (newest last).
class PromptStash {
  PromptStash({this.maxEntries = 50, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final int maxEntries;
  final DateTime Function() _clock;
  final List<PromptStashEntry> _entries = <PromptStashEntry>[];

  List<PromptStashEntry> get entries => List.unmodifiable(_entries);

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  /// Push a draft. Empty input is ignored.
  PromptStashEntry? push(String input, {String? label, DateTime? timestamp}) {
    final text = input.trimRight();
    if (text.isEmpty) return null;
    final entry = PromptStashEntry(
      input: text,
      timestamp: timestamp ?? _clock(),
      label: label,
    );
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    return entry;
  }

  /// Pop the newest entry, or `null` if empty.
  PromptStashEntry? pop() {
    if (_entries.isEmpty) return null;
    return _entries.removeLast();
  }

  /// Peek newest without removing.
  PromptStashEntry? get newest =>
      _entries.isEmpty ? null : _entries[_entries.length - 1];

  /// Remove by index (0 = oldest).
  PromptStashEntry? removeAt(int index) {
    if (index < 0 || index >= _entries.length) return null;
    return _entries.removeAt(index);
  }

  void clear() => _entries.clear();
}
