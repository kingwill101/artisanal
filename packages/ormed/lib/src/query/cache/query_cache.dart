import '../query.dart';

/// Policies for invalidating cached query results after mutations.
enum QueryCacheInvalidationPolicy {
  /// Leave cached results untouched (manual invalidation).
  none,

  /// Flush the cache after any successful mutation.
  flushOnWrite,
}

/// Portable query result cache with TTL support and event emission.
///
/// Stores query results keyed by SQL + bindings hash, with optional
/// time-to-live. Emits events for cache hits, misses, and mutations.
class QueryCache {
  QueryCache({Duration? defaultTtl})
    : _defaultTtl = defaultTtl ?? const Duration(minutes: 5);

  final Duration _defaultTtl;
  final Map<int, _CacheEntry> _entries = {};
  final List<void Function(CacheEvent)> _listeners = [];

  /// Listen to cache events.
  ///
  /// Example:
  /// ```dart
  /// cache.listen((event) {
  ///   if (event is CacheHitEvent) {
  ///     print('Cache hit: ${event.sql}');
  ///   }
  /// });
  /// ```
  void listen(void Function(CacheEvent) callback) {
    _listeners.add(callback);
  }

  /// Remove a listener.
  void unlisten(void Function(CacheEvent) callback) {
    _listeners.remove(callback);
  }

  /// Emit an event to all listeners.
  void _emit(CacheEvent event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }

  /// Store a query result in cache.
  void put(String sql, List<Object?> bindings, dynamic value, {Duration? ttl}) {
    final key = _hashKey(sql, bindings);
    final duration = ttl ?? _defaultTtl;

    _entries[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(duration),
    );

    // Emit store event
    final rows = value is List ? value.length : 1;
    _emit(
      CacheStoreEvent(
        sql: sql,
        parameters: bindings,
        ttl: duration,
        entryCount: rows,
      ),
    );
  }

  /// Retrieve a cached result if available and not expired.
  T? get<T>(String sql, List<Object?> bindings, {Duration? ttl}) {
    final key = _hashKey(sql, bindings);
    final entry = _entries[key];

    if (entry == null) {
      // Emit miss event
      _emit(
        CacheMissEvent(sql: sql, parameters: bindings, ttl: ttl ?? _defaultTtl),
      );
      return null;
    }

    // Check expiration
    if (entry.isExpired) {
      _entries.remove(key);
      // Emit miss event (expired)
      _emit(
        CacheMissEvent(sql: sql, parameters: bindings, ttl: ttl ?? _defaultTtl),
      );
      return null;
    }

    // Emit hit event
    _emit(
      CacheHitEvent(sql: sql, parameters: bindings, ttl: ttl ?? _defaultTtl),
    );

    return entry.value as T?;
  }

  /// Check if a result is cached.
  bool has(String sql, List<Object?> bindings) {
    return get(sql, bindings) != null;
  }

  /// Remove a specific cache entry.
  void forget(String sql, List<Object?> bindings) {
    final key = _hashKey(sql, bindings);
    _entries.remove(key);

    // Emit forget event
    _emit(CacheForgetEvent(sql: sql, parameters: bindings));
  }

  /// Clear all cache entries.
  void flush() {
    final count = _entries.length;
    _entries.clear();

    // Emit flush event
    _emit(CacheFlushEvent(entriesCleared: count));
  }

  /// Remove expired entries.
  void vacuum() {
    final before = _entries.length;
    _entries.removeWhere((_, entry) => entry.isExpired);
    final after = _entries.length;
    final removed = before - after;

    // Emit vacuum event
    _emit(
      CacheVacuumEvent(
        entriesRemoved: removed,
        totalBefore: before,
        totalAfter: after,
      ),
    );
  }

  /// Get cache statistics.
  CacheStats get stats {
    final expired = _entries.values.where((e) => e.isExpired).length;
    return CacheStats(
      totalEntries: _entries.length,
      activeEntries: _entries.length - expired,
      expiredEntries: expired,
    );
  }

  /// Generate hash key from SQL and bindings.
  int _hashKey(String sql, List<Object?> bindings) {
    return Object.hash(sql, Object.hashAll(bindings));
  }
}

/// A single cache entry with expiration.
class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});

  final dynamic value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Statistics about cache state.
class CacheStats {
  const CacheStats({
    required this.totalEntries,
    required this.activeEntries,
    required this.expiredEntries,
  });

  final int totalEntries;
  final int activeEntries;
  final int expiredEntries;

  @override
  String toString() =>
      'CacheStats(total: $totalEntries, active: $activeEntries, expired: $expiredEntries)';
}
