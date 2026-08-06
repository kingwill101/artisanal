/// Ring-buffer prompt history (OpenCode-style up/down recall).
library;

/// Stores recent prompt submissions for arrow-key recall.
class PromptHistory {
  PromptHistory({this.maxEntries = 50});

  /// Maximum retained prompts (oldest dropped first).
  final int maxEntries;

  final List<String> _entries = <String>[];

  /// Index into history while browsing: `0` = newest, larger = older.
  /// `-1` means "not browsing" (live draft).
  int _browseIndex = -1;

  /// Draft text captured when browsing began.
  String _draft = '';

  /// Chronological entries (oldest first).
  List<String> get entries => List.unmodifiable(_entries);

  int get length => _entries.length;

  bool get isBrowsing => _browseIndex >= 0;

  /// Push a submitted prompt. Duplicates of the latest entry are ignored.
  void push(String input) {
    final trimmed = input.trimRight();
    if (trimmed.isEmpty) return;
    if (_entries.isNotEmpty && _entries.last == trimmed) {
      _browseIndex = -1;
      _draft = '';
      return;
    }
    _entries.add(trimmed);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    _browseIndex = -1;
    _draft = '';
  }

  /// Move through history.
  ///
  /// [direction] `-1` = older, `+1` = newer.
  /// [currentInput] is the live field value; used to detect leaving draft.
  ///
  /// Returns the text to show, or `null` if the move is a no-op.
  String? move(int direction, String currentInput) {
    if (_entries.isEmpty) return null;
    if (direction != 1 && direction != -1) return null;

    if (!isBrowsing) {
      if (direction == 1) return null; // already at live draft
      _draft = currentInput;
      _browseIndex = 0;
      return _entries[_entries.length - 1 - _browseIndex];
    }

    // While browsing, only move if field still matches the recalled entry
    // (OpenCode: abort browse if user edited the line).
    final expected = _entries[_entries.length - 1 - _browseIndex];
    if (currentInput != expected && currentInput != _draft) {
      // User edited — stay on current index but sync? OpenCode aborts.
      // We re-anchor from draft if they typed something else.
      if (currentInput.isNotEmpty && currentInput != expected) {
        return null;
      }
    }

    final next = _browseIndex - direction; // -1 older increases index
    if (next < 0) {
      // Back to live draft
      _browseIndex = -1;
      final draft = _draft;
      _draft = '';
      return draft;
    }
    if (next >= _entries.length) return null;

    _browseIndex = next;
    return _entries[_entries.length - 1 - _browseIndex];
  }

  /// Reset browse cursor without clearing history.
  void resetBrowse() {
    _browseIndex = -1;
    _draft = '';
  }

  void clear() {
    _entries.clear();
    resetBrowse();
  }
}
