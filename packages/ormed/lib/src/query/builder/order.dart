part of '../query_builder.dart';

/// Extension providing ordering methods for query results.
extension OrderExtension<T extends OrmEntity> on Query<T> {
  /// Orders results by [field]. Set [descending] to sort in reverse.
  ///
  /// [field] can be a simple column name or a JSON path expression (e.g., 'data->name').
  ///
  /// Examples:
  /// ```dart
  /// // Order users by name ascending
  /// final usersByName = await context.query<User>()
  ///   .orderBy('name')
  ///   .get();
  ///
  /// // Order users by creation date descending
  /// final recentUsers = await context.query<User>()
  ///   .orderBy('createdAt', descending: true)
  ///   .get();
  ///
  /// // Order by a JSON field
  /// final usersByJsonName = await context.query<User>()
  ///   .orderBy('profile->name')
  ///   .get();
  /// ```
  Query<T> orderBy(String field, {bool descending = false}) {
    if (json_path.hasJsonSelector(field)) {
      final selector = json_path.parseJsonSelectorExpression(field);
      if (selector == null) {
        throw ArgumentError.value(field, 'field', 'Invalid JSON selector.');
      }
      final resolved = _ensureField(selector.column).columnName;
      final normalizedSelector = json_path.JsonSelector(
        resolved,
        selector.path,
        selector.extractsText,
      );
      return _copyWith(
        orders: [
          ..._orders,
          OrderClause(
            field: resolved,
            descending: descending,
            jsonSelector: normalizedSelector,
          ),
        ],
      );
    }
    final column = _ensureField(field).columnName;
    return _copyWith(
      orders: [
        ..._orders,
        OrderClause(field: column, descending: descending),
      ],
    );
  }

  /// Orders results randomly.
  ///
  /// This method adds a `ORDER BY RANDOM()` (or equivalent) clause to the query.
  /// An optional [seed] can be provided for reproducible random ordering in some databases.
  ///
  /// Example:
  /// ```dart
  /// final randomUsers = await context.query<User>()
  ///   .orderByRandom()
  ///   .limit(5)
  ///   .get();
  /// ```
  Query<T> orderByRandom([num? seed]) => _copyWith(
    orders: const <OrderClause>[],
    rawOrders: const <RawOrderExpression>[],
    randomOrder: true,
    randomSeed: seed,
  );
}
