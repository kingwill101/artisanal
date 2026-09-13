import 'dart:collection';

/// Internal FIFO cache with entry, UTF-16 length, and byte budgets.
final class BoundedStringIntCache {
  BoundedStringIntCache({
    required this.maxEntries,
    required this.maxKeyLength,
    required this.maxKeyBytes,
  });

  final int maxEntries;
  final int maxKeyLength;
  final int maxKeyBytes;
  final LinkedHashMap<String, int> _entries = LinkedHashMap<String, int>();
  int _keyBytes = 0;

  int? operator [](String key) => _entries[key];

  void operator []=(String key, int value) {
    final keyBytes = key.length * 2;
    if (key.length > maxKeyLength || keyBytes > maxKeyBytes) return;
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

  int get entryCount => _entries.length;

  int get retainedKeyBytes => _keyBytes;

  List<String> get keys => List<String>.unmodifiable(_entries.keys);

  void clear() {
    _entries.clear();
    _keyBytes = 0;
  }
}
