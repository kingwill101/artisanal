import 'dart:collection';

/// FIFO cache for layout measurements with count and UTF-16 key budgets.
///
/// This is intentionally an internal implementation type.  The counters are
/// useful to package tests without adding cache details to the public API.
final class BoundedStringIntCache {
  BoundedStringIntCache({required this.maxEntries, required this.maxKeyBytes});

  final int maxEntries;
  final int maxKeyBytes;
  final LinkedHashMap<String, int> _entries = LinkedHashMap<String, int>();
  int _keyBytes = 0;

  int? operator [](String key) => _entries[key];

  void operator []=(String key, int value) {
    final keyBytes = key.length * 2;
    if (keyBytes > maxKeyBytes) return;
    if (_entries.containsKey(key)) {
      _entries[key] = value;
      return;
    }
    while (_entries.isNotEmpty &&
        (_entries.length >= maxEntries || _keyBytes + keyBytes > maxKeyBytes)) {
      final oldest = _entries.keys.first;
      _entries.remove(oldest);
      _keyBytes -= oldest.length * 2;
    }
    _entries[key] = value;
    _keyBytes += keyBytes;
  }

  /// Number of currently retained entries.
  int get entryCount => _entries.length;

  /// UTF-16 bytes retained by the current keys.
  int get retainedKeyBytes => _keyBytes;

  /// A snapshot of keys in FIFO order, intended for internal tests.
  List<String> get keys => List<String>.unmodifiable(_entries.keys);

  void clear() {
    _entries.clear();
    _keyBytes = 0;
  }
}
