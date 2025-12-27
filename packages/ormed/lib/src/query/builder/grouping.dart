part of '../query_builder.dart';

/// Extension providing GROUP BY and HAVING clause methods for query results.
extension GroupingExtension<T extends OrmEntity> on Query<T> {
  /// Limits the number of rows returned per group.
  ///
  /// This applies a window function over [column] and caps the number of rows
  /// returned for each group. Use [offset] to skip the first rows per group.
  ///
  /// Example:
  /// ```dart
  /// final latestPostsPerAuthor = await context.query<Post>()
  ///   .orderBy('publishedAt', descending: true)
  ///   .limitPerGroup(2, 'authorId')
  ///   .get();
  /// ```
  Query<T> limitPerGroup(int limit, String column, {int? offset}) {
    final resolved = _ensureField(column).columnName;
    return _copyWith(
      groupLimit: GroupLimit(column: resolved, limit: limit, offset: offset),
    );
  }

  /// Groups rows by the provided [columns].
  ///
  /// This method adds a `GROUP BY` clause to the query, often used in conjunction
  /// with aggregate functions.
  ///
  /// Example:
  /// ```dart
  /// final userCountsByCity = await context.query<User>()
  ///   .select(['city'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['city'])
  ///   .get();
  /// ```
  Query<T> groupBy(List<String> columns) {
    final mapped = columns
        .map((field) => _ensureField(field).columnName)
        .toList();
    return _copyWith(groupBy: [..._groupBy, ...mapped]);
  }

  /// Adds a HAVING predicate over grouped rows.
  ///
  /// This method is similar to `where` but applies conditions to the results
  /// of aggregate functions after grouping.
  ///
  /// Example:
  /// ```dart
  /// final citiesWithManyUsers = await context.query<User>()
  ///   .select(['city'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['city'])
  ///   .having('userCount', PredicateOperator.greaterThan, 10)
  ///   .get();
  /// ```
  Query<T> having(String field, PredicateOperator operator, Object? value) {
    final column = _resolveHavingField(field);
    final predicate = FieldPredicate(
      field: column,
      operator: operator,
      value: value,
    );
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.and);
  }

  /// Adds a raw HAVING fragment.
  ///
  /// This method allows you to inject raw SQL into the `HAVING` clause.
  /// Use `?` for parameter placeholders, and provide [bindings] for security.
  ///
  /// Example:
  /// ```dart
  /// final customHaving = await context.query<User>()
  ///   .select(['city'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['city'])
  ///   .havingRaw('SUM(age) > ?', [100])
  ///   .get();
  /// ```
  Query<T> havingRaw(String sql, [List<Object?> bindings = const []]) {
    final predicate = RawPredicate(sql: sql, bindings: bindings);
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.and);
  }

  /// Adds a raw HAVING fragment using OR logic.
  ///
  /// This method is similar to [havingRaw] but applies `OR` logic when
  /// combining with previous `HAVING` clauses.
  ///
  /// Example:
  /// ```dart
  /// final customHaving = await context.query<User>()
  ///   .select(['city'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['city'])
  ///   .havingRaw('COUNT(*) > ?', [100])
  ///   .orHavingRaw('SUM(age) > ?', [500])
  ///   .get();
  /// ```
  Query<T> orHavingRaw(String sql, [List<Object?> bindings = const []]) {
    final predicate = RawPredicate(sql: sql, bindings: bindings);
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.or);
  }

  /// Adds a HAVING clause with a bitwise operator.
  ///
  /// This method allows you to apply bitwise operations in the `HAVING` clause.
  ///
  /// Example:
  /// ```dart
  /// final groupedByPermissions = await context.query<User>()
  ///   .select(['permissions'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['permissions'])
  ///   .havingBitwise('permissions', '&', 4)
  ///   .get();
  /// ```
  Query<T> havingBitwise(String field, String operator, Object value) {
    final predicate = _buildBitwisePredicate(field, operator, value);
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.and);
  }

  /// Adds a HAVING clause with a bitwise operator using OR chaining.
  ///
  /// This method is similar to [havingBitwise] but applies `OR` logic when
  /// combining with previous `HAVING` clauses.
  ///
  /// Example:
  /// ```dart
  /// final groupedByPermissions = await context.query<User>()
  ///   .select(['permissions'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['permissions'])
  ///   .havingBitwise('permissions', '&', 1)
  ///   .orHavingBitwise('permissions', '&', 2)
  ///   .get();
  /// ```
  Query<T> orHavingBitwise(String field, String operator, Object value) {
    final predicate = _buildBitwisePredicate(field, operator, value);
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.or);
  }
}
