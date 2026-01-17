part of '../query_builder.dart';

/// Extension providing utility methods for query inspection and validation.
extension UtilityExtension<T extends OrmEntity> on Query<T> {
  /// Returns the SQL preview without executing the query.
  ///
  /// This method is useful for debugging and understanding the generated SQL.
  ///
  /// Example:
  /// ```dart
  /// final sql = context.query<User>()
  ///   .where('isActive', true)
  ///   .toSql();
  /// print(sql.sqlWithBindings);
  /// ```
  StatementPreview toSql() => context.driver.describeQuery(_buildPlan());

  /// Returns the number of rows that match the current query.
  ///
  /// [expression] is the column or expression to count (defaults to '*').
  ///
  /// Example:
  /// ```dart
  /// final activeUserCount = await context.query<User>()
  ///   .where('isActive', true)
  ///   .count();
  /// print('Active users: $activeUserCount');
  /// ```
  Future<int> count({String expression = '*'}) async {
    final alias = _aggregateAlias('count');
    final aggregateQuery = _copyForAggregation().withAggregate(
      AggregateFunction.count,
      expression,
      alias: alias,
    );
    final plan = aggregateQuery._buildPlan();
    final rows = await context.runSelect(plan);
    if (rows.isEmpty) return 0;
    final value = rows.first[alias];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return rows.length;
    return 0;
  }

  /// Returns `true` if any rows match the current query.
  ///
  /// Example:
  /// ```dart
  /// final hasActiveUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .exists();
  /// print('Are there active users? $hasActiveUsers');
  /// ```
  Future<bool> exists() async {
    final rows = await limit(1).rows();
    return rows.isNotEmpty;
  }

  /// Returns `true` if no rows match the current query.
  ///
  /// Example:
  /// ```dart
  /// final noInactiveUsers = await context.query<User>()
  ///   .where('isActive', false)
  ///   .doesntExist();
  /// print('Are there no inactive users? $noInactiveUsers');
  /// ```
  Future<bool> doesntExist() async => !(await exists());

  /// Returns whether all global scopes have been applied to this query.
  bool get globalScopesApplied => _globalScopesApplied;

  /// Returns whether all global scopes should be ignored for this query.
  bool get ignoreAllGlobalScopes => _ignoreAllGlobalScopes;

  /// Returns the set of global scope identifiers that should be ignored.
  Set<String> get ignoredGlobalScopes => Set<String>.from(_ignoredGlobalScopes);

  /// Returns the list of ad-hoc scopes to apply.
  List<String> get adHocScopes => List<String>.from(_adHocScopes);

  /// Marks this query as having global scopes applied.
  ///
  /// This is used internally by the scope registry to track whether global
  /// scopes have already been applied to prevent duplicate application.
  Query<T> markGlobalScopesApplied() {
    return _copyWith(globalScopesApplied: true);
  }

  /// Conditionally applies a callback to the query.
  ///
  /// If [condition] is `true` (or evaluates to `true` if a function is provided),
  /// the [callback] is applied to the query. Otherwise, the query is returned unchanged.
  ///
  /// The [condition] can be either a boolean value or a function that returns a boolean.
  /// Using a function allows for lazy evaluation of the condition.
  ///
  /// This is useful for building queries conditionally without breaking the
  /// method chain.
  ///
  /// Example:
  /// ```dart
  /// final searchTerm = 'Dart';
  /// final isActive = true;
  ///
  /// final posts = await context.query<Post>()
  ///   .when(searchTerm != null, (q) => q.whereLike('title', '%$searchTerm%'))
  ///   .when(isActive, (q) => q.where('published', true))
  ///   .when(() => user.hasPermission('viewDrafts'), (q) => q.where('status', 'draft'))
  ///   .get();
  /// ```
  Query<T> when(Object condition, Query<T> Function(Query<T> query) callback) {
    final bool shouldApply = condition is bool
        ? condition
        : (condition as bool Function())();

    if (shouldApply) {
      return callback(this);
    }
    return this;
  }

  /// Conditionally applies a callback to the query when the condition is false.
  ///
  /// This is the inverse of [when]. If [condition] is `false` (or evaluates to `false`
  /// if a function is provided), the [callback] is applied to the query.
  /// Otherwise, the query is returned unchanged.
  ///
  /// The [condition] can be either a boolean value or a function that returns a boolean.
  /// Using a function allows for lazy evaluation of the condition.
  ///
  /// Example:
  /// ```dart
  /// final showAll = false;
  ///
  /// final posts = await context.query<Post>()
  ///   .where('published', true)
  ///   .unless(showAll, (q) => q.limit(10))
  ///   .unless(() => user.isAdmin(), (q) => q.where('authorId', user.id))
  ///   .get();
  /// ```
  Query<T> unless(
    Object condition,
    Query<T> Function(Query<T> query) callback,
  ) {
    final bool shouldApply = condition is bool
        ? condition
        : (condition as bool Function())();

    return when(!shouldApply, callback);
  }

  /// Taps into the query chain without modifying it.
  ///
  /// This allows you to perform side effects (like logging or debugging)
  /// without breaking the method chain. The query is passed to the [callback]
  /// and then returned unchanged.
  ///
  /// Example:
  /// ```dart
  /// final posts = await context.query<Post>()
  ///   .where('published', true)
  ///   .tap((q) => print('SQL: ${q.toSql().sql}'))
  ///   .orderBy('createdAt', descending: true)
  ///   .tap((q) => print('With ordering: ${q.toSql().sql}'))
  ///   .get();
  /// ```
  Query<T> tap(void Function(Query<T> query) callback) {
    callback(this);
    return this;
  }
}
