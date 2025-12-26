part of '../query_builder.dart';

/// Extension providing additional raw SQL query helpers for advanced use cases.
extension RawQueryExtension<T extends OrmEntity> on Query<T> {
  /// Adds a raw ORDER BY expression.
  ///
  /// This method allows you to add custom SQL to the ORDER BY clause
  /// for database-specific sorting logic.
  ///
  /// Note: [havingRaw], [havingBitwise], and [orHavingBitwise] are available
  /// via the GroupingExtension on Query.
  ///
  /// Example:
  /// ```dart
  /// // Random order (MySQL)
  /// final users = await context.query<User>()
  ///   .orderByRaw('RAND()')
  ///   .get();
  ///
  /// // Complex ordering with CASE
  /// final items = await context.query<Item>()
  ///   .orderByRaw('CASE WHEN status = ? THEN 0 ELSE 1 END', ['active'])
  ///   .get();
  ///
  /// // PostgreSQL specific: natural text sorting
  /// final products = await context.query<Product>()
  ///   .orderByRaw('name COLLATE "C"')
  ///   .get();
  /// ```
  Query<T> orderByRaw(String sql, [List<Object?> bindings = const []]) {
    final expression = RawOrderExpression(sql: sql, bindings: bindings);
    return _copyWith(rawOrders: [..._rawOrders, expression]);
  }

  /// Adds a raw GROUP BY expression.
  ///
  /// This method allows you to add custom SQL to the GROUP BY clause
  /// for database-specific grouping logic. Use this when `groupBy()` with
  /// simple column names isn't sufficient.
  ///
  /// Example:
  /// ```dart
  /// // Group by date truncation (PostgreSQL)
  /// final dailySales = await context.query<Sale>()
  ///   .select(['DATE_TRUNC(\'day\', created_at) as day', 'SUM(amount) as total'])
  ///   .groupByRaw('DATE_TRUNC(\'day\', created_at)')
  ///   .get();
  /// ```
  Query<T> groupByRaw(String sql, [List<Object?> bindings = const []]) {
    final expression = RawGroupByExpression(sql: sql, bindings: bindings);
    return _copyWith(rawGroupBy: [..._rawGroupBy, expression]);
  }
}
