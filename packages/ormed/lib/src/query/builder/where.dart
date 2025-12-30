part of '../query_builder.dart';

extension WhereExtension<T extends OrmEntity> on Query<T> {
  /// Adds an `IN` comparison for [field] using [values].
  ///
  /// This method adds a `WHERE field IN (value1, value2, ...)` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersInCities = await context.query<User>()
  ///   .whereIn('city', ['New York', 'London'])
  ///   .get();
  /// ```
  Query<T> whereIn(String field, Iterable<Object?> values) =>
      _appendSimpleCondition(field, FilterOperator.inValues, values.toList());

  /// Adds an equality comparison for the column mapped by [field].
  ///
  /// This method adds a `WHERE field = value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final activeUsers = await context.query<User>()
  ///   .whereEquals('isActive', true)
  ///   .get();
  /// ```
  Query<T> whereEquals(String field, Object? value) =>
      _appendSimpleCondition(field, FilterOperator.equals, value);

  /// Adds a `NOT IN` comparison for [field] using [values].
  ///
  /// This method adds a `WHERE field NOT IN (value1, value2, ...)` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersNotInCities = await context.query<User>()
  ///   .whereNotIn('city', ['Paris', 'Tokyo'])
  ///   .get();
  /// ```
  Query<T> whereNotIn(String field, Iterable<Object?> values) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: PredicateOperator.notInValues,
        values: List<Object?>.from(values),
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a `>` comparison for [field].
  ///
  /// This method adds a `WHERE field > value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersOlderThan18 = await context.query<User>()
  ///   .whereGreaterThan('age', 18)
  ///   .get();
  /// ```
  Query<T> whereGreaterThan(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.greaterThan, value);

  /// Adds a `>=` comparison for [field].
  ///
  /// This method adds a `WHERE field >= value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersAtLeast18 = await context.query<User>()
  ///   .whereGreaterThanOrEqual('age', 18)
  ///   .get();
  /// ```
  Query<T> whereGreaterThanOrEqual(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.greaterThanOrEqual, value);

  /// Adds a typed predicate callback to the query.
  ///
  /// Use this when you want typed predicate field accessors inside the callback:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .whereTyped((q) => q.email.eq('alice@example.com'))
  ///   .get();
  /// ```
  Query<T> whereTyped(PredicateCallback<T> callback) => _addWhere(
    callback,
    null,
    PredicateOperator.equals,
    logical: PredicateLogicalOperator.and,
  );

  /// Adds a typed predicate callback with `OR` logic.
  Query<T> orWhereTyped(PredicateCallback<T> callback) => _addWhere(
    callback,
    null,
    PredicateOperator.equals,
    logical: PredicateLogicalOperator.or,
  );

  /// Adds a custom WHERE predicate compiled by a driver extension.
  Query<T> whereExtension(String key, [Object? payload]) {
    final predicate = CustomPredicate(
      kind: DriverExtensionKind.where,
      key: key,
      payload: payload,
    );
    return _appendPredicate(predicate, PredicateLogicalOperator.and);
  }

  /// Adds a custom WHERE predicate using OR logic.
  Query<T> orWhereExtension(String key, [Object? payload]) {
    final predicate = CustomPredicate(
      kind: DriverExtensionKind.where,
      key: key,
      payload: payload,
    );
    return _appendPredicate(predicate, PredicateLogicalOperator.or);
  }

  /// Adds a `<` comparison for [field].
  ///
  /// This method adds a `WHERE field < value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersYoungerThan18 = await context.query<User>()
  ///   .whereLessThan('age', 18)
  ///   .get();
  /// ```
  Query<T> whereLessThan(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.lessThan, value);

  /// Adds a `<=` comparison for [field].
  ///
  /// This method adds a `WHERE field <= value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersUpTo18 = await context.query<User>()
  ///   .whereLessThanOrEqual('age', 18)
  ///   .get();
  /// ```
  Query<T> whereLessThanOrEqual(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.lessThanOrEqual, value);

  /// Joins a relation path without eager loading it.
  ///
  /// This method allows you to join related tables to the main query without
  /// necessarily loading the related models into the result. This is useful
  /// for filtering or ordering based on related data.
  ///
  /// [relation] is the name of the relation to join (e.g., 'posts', 'author.profile').
  /// [type] is the type of join to perform (defaults to [JoinType.inner]).
  ///
  /// Example:
  /// ```dart
  /// final usersWithPosts = await context.query<User>()
  ///   .joinRelation('posts')
  ///   .where('posts.title', 'LIKE', '%Dart%')
  ///   .get();
  /// ```
  Query<T> joinRelation(String relation, {JoinType type = JoinType.inner}) {
    _resolveRelationPath(relation, allowMorphTo: false);
    final updated = Map<String, RelationJoinRequest>.from(_relationJoinRequests)
      ..[relation] = RelationJoinRequest(joinType: type);
    return _copyWith(relationJoinRequests: updated);
  }

  /// Adds a `!=` comparison for the column mapped by [field].
  ///
  /// This method adds a `WHERE field != value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersNotActive = await context.query<User>()
  ///   .whereNotEquals('isActive', true)
  ///   .get();
  /// ```
  Query<T> whereNotEquals(String field, Object? value) =>
      where(field, value, PredicateOperator.notEquals);

  /// Generic `where` that accepts either a column comparison or a grouped
  /// predicate callback.
  ///
  /// When [fieldOrCallback] is a [String], it represents the column name.
  /// [value] and [operator] are used for simple comparisons.
  ///
  /// When [fieldOrCallback] is a [PredicateCallback], it allows for grouping
  /// multiple `WHERE` conditions using `AND` logic.
  ///
  /// Examples:
  /// ```dart
  /// // Simple equality comparison
  /// final activeUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .get();
  ///
  /// // Comparison with a different operator
  /// final usersOlderThan18 = await context.query<User>()
  ///   .where('age', 18, PredicateOperator.greaterThan)
  ///   .get();
  ///
  /// // Using a Partial (Type-safe)
  /// final users = await context.query<User>()
  ///   .where(UserPartial(email: 'test@example.com'))
  ///   .get();
  ///
  /// // Grouped conditions
  /// final complexUsers = await context.query<User>()
  ///   .where((query) {
  ///     query.where('age', 18, PredicateOperator.greaterThan)
  ///          .orWhere('status', 'admin');
  ///   })
  ///   .get();
  ///
  /// For typed predicate field accessors inside the callback, prefer
  /// [whereTyped].
  /// ```
  Query<T> where(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    return _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.and,
    );
  }

  /// `OR` variant of [where].
  ///
  /// This method is similar to [where] but applies `OR` logic when grouping
  /// conditions or combining with previous `WHERE` clauses.
  ///
  /// Examples:
  /// ```dart
  /// // Simple OR comparison
  /// final activeOrAdminUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .orWhere('role', 'admin')
  ///   .get();
  ///
  /// // Grouped OR conditions
  /// final complexUsers = await context.query<User>()
  ///   .where('status', 'pending')
  ///   .orWhere((query) {
  ///     query.where('age', 60, PredicateOperator.greaterThanOrEqual)
  ///          .where('isRetired', true);
  ///   })
  ///   .get();
  /// ```
  Query<T> orWhere(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    return _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.or,
    );
  }

  /// Adds a `WHERE BETWEEN` predicate.
  ///
  /// This method adds a `WHERE field BETWEEN lower AND upper` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersInAgeRange = await context.query<User>()
  ///   .whereBetween('age', 18, 30)
  ///   .get();
  /// ```
  Query<T> whereBetween(String field, Object lower, Object upper) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: PredicateOperator.between,
        lower: lower,
        upper: upper,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a `WHERE NOT BETWEEN` predicate.
  ///
  /// This method adds a `WHERE field NOT BETWEEN lower AND upper` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersOutsideAgeRange = await context.query<User>()
  ///   .whereNotBetween('age', 18, 30)
  ///   .get();
  /// ```
  Query<T> whereNotBetween(String field, Object lower, Object upper) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: PredicateOperator.notBetween,
        lower: lower,
        upper: upper,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a predicate comparing two columns.
  ///
  /// This method adds a `WHERE left_column OPERATOR right_column` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersWithMatchingIds = await context.query<User>()
  ///   .whereColumn('users.id', 'profiles.user_id')
  ///   .get();
  ///
  /// final usersWithDifferentNames = await context.query<User>()
  ///   .whereColumn('firstName', 'lastName', operator: PredicateOperator.columnNotEquals)
  ///   .get();
  /// ```
  Query<T> whereColumn(
    String left,
    String right, {
    PredicateOperator operator = PredicateOperator.columnEquals,
  }) {
    final leftResolved = _resolvePredicateField(left);

    // For correlated subqueries, allow table-qualified column names
    // like "users.id" or "posts.authorId"
    String rightColumn;
    if (right.contains('.')) {
      // Table-qualified reference (e.g., "users.id" in a correlated subquery)
      // Just use it as-is - don't try to resolve as a field
      rightColumn = right;
    } else {
      // Try to resolve it as a field on the current model
      try {
        rightColumn = _ensureField(right).columnName;
      } catch (e) {
        // If field doesn't exist on current model, use as-is
        // This handles correlated subqueries where the right side refers to the outer query
        rightColumn = right;
      }
    }

    return _appendPredicate(
      FieldPredicate(
        field: leftResolved.column,
        compareField: rightColumn,
        operator: operator,
        jsonSelector: leftResolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a NULL predicate.
  ///
  /// This method adds a `WHERE field IS NULL` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersWithoutEmail = await context.query<User>()
  ///   .whereNull('email')
  ///   .get();
  /// ```
  Query<T> whereNull(String field) {
    final resolved = _resolvePredicateField(field);
    final predicate = FieldPredicate(
      field: resolved.column,
      operator: PredicateOperator.isNull,
      jsonSelector: resolved.jsonSelector,
    );
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    if (resolved.jsonSelector != null) {
      return updated;
    }
    return updated._withFilter(
      _buildFieldFilter(field, FilterOperator.isNull, null),
    );
  }

  /// Adds a NOT NULL predicate.
  Query<T> whereNotNull(String field) {
    final resolved = _resolvePredicateField(field);
    final predicate = FieldPredicate(
      field: resolved.column,
      operator: PredicateOperator.isNotNull,
      jsonSelector: resolved.jsonSelector,
    );
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    if (resolved.jsonSelector != null) {
      return updated;
    }
    return updated._withFilter(
      _buildFieldFilter(field, FilterOperator.isNotNull, null),
    );
  }

  /// Compares the DATE portion of [field]. Defaults to equality comparisons
  /// when only a single value is supplied.
  ///
  /// This method adds a `WHERE DATE(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created on a specific date
  /// final postsOnDate = await context.query<Post>()
  ///   .whereDate('createdAt', DateTime(2023, 1, 1))
  ///   .get();
  ///
  /// // Find posts created after a specific date
  /// final recentPosts = await context.query<Post>()
  ///   .whereDate('createdAt', '>', DateTime(2023, 1, 1))
  ///   .get();
  /// ```
  Query<T> whereDate(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.date, valueOrOperator, value);

  /// Filters by calendar day (1-31) regardless of timezone.
  ///
  /// This method adds a `WHERE DAY(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created on the 15th day of any month
  /// final postsOn15th = await context.query<Post>()
  ///   .whereDay('createdAt', 15)
  ///   .get();
  /// ```
  Query<T> whereDay(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.day, valueOrOperator, value);

  /// Filters by calendar month (1-12).
  ///
  /// This method adds a `WHERE MONTH(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created in January (month 1)
  /// final januaryPosts = await context.query<Post>()
  ///   .whereMonth('createdAt', 1)
  ///   .get();
  /// ```
  Query<T> whereMonth(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.month, valueOrOperator, value);

  /// Filters by four-digit calendar year.
  ///
  /// This method adds a `WHERE YEAR(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created in 2023
  /// final postsIn2023 = await context.query<Post>()
  ///   .whereYear('createdAt', 2023)
  ///   .get();
  /// ```
  Query<T> whereYear(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.year, valueOrOperator, value);

  /// Compares the HH:mm:ss component of [field].
  ///
  /// This method adds a `WHERE TIME(field) OPERATOR value` clause to the query.
  /// The [value] should be a [String] in 'HH:mm:ss' format.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created at exactly 10:00:00
  /// final postsAt10AM = await context.query<Post>()
  ///   .whereTime('createdAt', '10:00:00')
  ///   .get();
  /// ```
  Query<T> whereTime(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.time, valueOrOperator, value);

  /// Adds a `LIKE` predicate.
  ///
  /// This method adds a `WHERE field LIKE value` clause to the query.
  /// Use `%` as a wildcard character in [value].
  ///
  /// [caseInsensitive] (defaults to `false`) can be set to `true` to use `ILIKE`
  /// or a dialect-specific case-insensitive LIKE operator.
  ///
  /// Examples:
  /// ```dart
  /// // Find users whose name starts with 'J'
  /// final usersStartingWithJ = await context.query<User>()
  ///   .whereLike('name', 'J%')
  ///   .get();
  ///
  /// // Case-insensitive search for names containing 'smith'
  /// final smithUsers = await context.query<User>()
  ///   .whereLike('name', '%smith%', caseInsensitive: true)
  ///   .get();
  /// ```
  Query<T> whereLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: caseInsensitive
            ? PredicateOperator.iLike
            : PredicateOperator.like,
        value: value,
        caseInsensitive: caseInsensitive,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a NOT LIKE predicate.
  ///
  /// This method adds a `WHERE field NOT LIKE value` clause to the query.
  /// Use `%` as a wildcard character in [value].
  ///
  /// [caseInsensitive] (defaults to `false`) can be set to `true` to use `NOT ILIKE`
  /// or a dialect-specific case-insensitive NOT LIKE operator.
  ///
  /// Examples:
  /// ```dart
  /// // Find users whose name does not start with 'J'
  /// final usersNotStartingWithJ = await context.query<User>()
  ///   .whereNotLike('name', 'J%')
  ///   .get();
  /// ```
  Query<T> whereNotLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: caseInsensitive
            ? PredicateOperator.notILike
            : PredicateOperator.notLike,
        value: value,
        caseInsensitive: caseInsensitive,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds an ILIKE predicate.
  ///
  /// This is a convenience method for [whereLike] with `caseInsensitive` set to `true`.
  ///
  /// Example:
  /// ```dart
  /// final smithUsers = await context.query<User>()
  ///   .whereILike('name', '%smith%')
  ///   .get();
  /// ```
  Query<T> whereILike(String field, Object value) =>
      whereLike(field, value, caseInsensitive: true);

  /// Adds a NOT ILIKE predicate.
  ///
  /// This is a convenience method for [whereNotLike] with `caseInsensitive` set to `true`.
  ///
  /// Example:
  /// ```dart
  /// final nonSmithUsers = await context.query<User>()
  ///   .whereNotILike('name', '%smith%')
  ///   .get();
  /// ```
  Query<T> whereNotILike(String field, Object value) =>
      whereNotLike(field, value, caseInsensitive: true);

  /// Adds a raw predicate fragment.
  ///
  /// This method allows you to inject raw SQL into the `WHERE` clause.
  /// Use `?` for parameter placeholders, and provide [bindings] for security.
  ///
  /// Example:
  /// ```dart
  /// final customFilteredUsers = await context.query<User>()
  ///   .whereRaw('LENGTH(name) > ?', [5])
  ///   .get();
  /// ```
  Query<T> whereRaw(String sql, [List<Object?> bindings = const []]) =>
      _appendPredicate(
        RawPredicate(sql: sql, bindings: bindings),
        PredicateLogicalOperator.and,
      );

  /// Adds a bitwise predicate.
  ///
  /// This method allows you to apply bitwise operations (e.g., `&`, `|`, `^`)
  /// in the `WHERE` clause.
  ///
  /// [field] is the column to apply the bitwise operation on.
  /// [operator] is the bitwise operator (e.g., '&', '|', '^').
  /// [value] is the value to compare with.
  ///
  /// Example:
  /// ```dart
  /// // Find users with a specific permission bit set
  /// final usersWithPermission = await context.query<User>()
  ///   .whereBitwise('permissions', '&', 4) // Assuming 4 is a permission bit
  ///   .get();
  /// ```
  Query<T> whereBitwise(String field, String operator, Object value) =>
      _appendPredicate(
        BitwisePredicate(
          field: _ensureField(field).columnName,
          operator: _normalizeBitwiseOperator(operator),
          value: value,
        ),
        PredicateLogicalOperator.and,
      );

  /// Adds a bitwise predicate with `OR` chaining.
  ///
  /// This method is similar to [whereBitwise] but applies `OR` logic when
  /// combining with previous `WHERE` clauses.
  ///
  /// Example:
  /// ```dart
  /// // Find users with permission A or permission B
  /// final usersWithPermissionAOrB = await context.query<User>()
  ///   .whereBitwise('permissions', '&', 1)
  ///   .orWhereBitwise('permissions', '&', 2)
  ///   .get();
  /// ```
  Query<T> orWhereBitwise(String field, String operator, Object value) =>
      _appendPredicate(
        BitwisePredicate(
          field: _ensureField(field).columnName,
          operator: _normalizeBitwiseOperator(operator),
          value: value,
        ),
        PredicateLogicalOperator.or,
      );

  /// Adds a full-text predicate.
  ///
  /// This method allows you to perform full-text searches on specified columns.
  /// The behavior depends on the underlying database driver's full-text capabilities.
  ///
  /// [columns] are the columns to search within.
  /// [value] is the search query.
  /// [language] is an optional language for the full-text search.
  /// [mode] specifies the full-text search mode (e.g., [FullTextMode.natural]).
  /// [expanded] indicates whether to expand the search query.
  /// [indexName] optionally targets a specific full-text index (SQLite FTS).
  ///
  /// Example:
  /// ```dart
  /// final relevantPosts = await context.query<Post>()
  ///   .whereFullText(['title', 'body'], 'Dart programming')
  ///   .get();
  /// ```
  Query<T> whereFullText(
    List<String> columns,
    Object value, {
    String? language,
    FullTextMode mode = FullTextMode.natural,
    bool expanded = false,
    String? indexName,
  }) {
    if (columns.isEmpty) {
      throw ArgumentError.value(columns, 'columns', 'must not be empty.');
    }
    final clause = FullTextWhere(
      columns: columns,
      value: value,
      language: language,
      mode: mode,
      expanded: expanded,
      tableName: definition.tableName,
      tablePrefix: context.connectionTablePrefix,
      tableAlias: _tableAlias,
      indexName: indexName,
      schema: definition.schema,
    );
    return _copyWith(fullTextWheres: [..._fullTextWheres, clause]);
  }

  /// Adds an `OR WHERE HAS` clause for a relation.
  ///
  /// This method is similar to [whereHas] but applies `OR` logic.
  ///
  /// [relation] is the name of the relation.
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// // Find users who are active OR have at least one post
  /// final activeOrPostedUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .orWhereHas('posts')
  ///   .get();
  /// ```
  Query<T> orWhereHas(
    String relation, [
    PredicateCallback<OrmEntity>? constraint,
  ]) => _addRelationWhere(
    relation,
    constraint,
    logical: PredicateLogicalOperator.or,
  );

  /// Adds a `WHERE HAS` clause for a relation.
  ///
  /// This method filters the parent models based on the existence of related models
  /// that satisfy an optional constraint.
  ///
  /// [relation] is the name of the relation.
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// // Find users who have at least one post
  /// final usersWithPosts = await context.query<User>()
  ///   .whereHas('posts')
  ///   .get();
  ///
  /// // Find users who have at least one published post
  /// final usersWithPublishedPosts = await context.query<User>()
  ///   .whereHas('posts', (query) => query.where('isPublished', true))
  ///   .get();
  /// ```
  Query<T> whereHas(
    String relation, [
    PredicateCallback<OrmEntity>? constraint,
  ]) => _addRelationWhere(
    relation,
    constraint,
    logical: PredicateLogicalOperator.and,
  );

  /// Typed variant of [whereHas] that accepts a typed predicate callback.
  Query<T> whereHasTyped<TRelated extends OrmEntity>(
    String relation, [
    PredicateCallback<TRelated>? constraint,
  ]) => _addRelationWhereTyped(
    relation,
    constraint,
    logical: PredicateLogicalOperator.and,
  );

  /// Typed variant of [orWhereHas] that accepts a typed predicate callback.
  Query<T> orWhereHasTyped<TRelated extends OrmEntity>(
    String relation, [
    PredicateCallback<TRelated>? constraint,
  ]) => _addRelationWhereTyped(
    relation,
    constraint,
    logical: PredicateLogicalOperator.or,
  );

  Query<T> _addWhere(
    Object fieldOrCallback,
    Object? value,
    PredicateOperator operator, {
    required PredicateLogicalOperator logical,
  }) {
    if (fieldOrCallback is String) {
      final resolved = _resolvePredicateField(fieldOrCallback);
      final jsonBooleanComparison = _shouldTreatAsJsonBoolean(
        resolved.jsonSelector,
        operator,
        value,
      );
      final normalizedValue = jsonBooleanComparison && value is bool
          ? jsonEncode(value)
          : value;
      final predicate = _buildFieldPredicate(
        resolved.column,
        operator,
        normalizedValue,
        jsonSelector: resolved.jsonSelector,
        jsonBooleanComparison: jsonBooleanComparison,
      );
      final updated = _appendPredicate(predicate, logical);
      final canMirrorFilter =
          _mirrorsFilter(operator) && resolved.jsonSelector == null;
      if (canMirrorFilter) {
        // Maintain backwards compatibility for the in-memory executor.
        return updated._withFilter(
          _buildFieldFilter(
            fieldOrCallback,
            _mapPredicateToFilter(operator),
            value,
          ),
        );
      }
      return updated;
    }

    if (fieldOrCallback is PartialEntity<T>) {
      final data = fieldOrCallback.toMap();
      var current = this;
      for (final entry in data.entries) {
        current = current.where(entry.key, entry.value);
      }
      return current;
    }

    if (fieldOrCallback is Symbol) {
      final name = fieldOrCallback.toString().split('"')[1];
      return where(name, value, operator);
    }

    if (fieldOrCallback is PredicateCallback<T>) {
      final builder = PredicateBuilder<T>(definition);
      fieldOrCallback(builder);
      final nested = builder.build();
      if (nested == null) {
        return this;
      }
      return _appendPredicate(nested, logical);
    }

    throw ArgumentError.value(
      fieldOrCallback,
      'fieldOrCallback',
      'Must be a column name or predicate callback.',
    );
  }

  Query<T> _addRelationWhere(
    String relation,
    PredicateCallback<OrmEntity>? constraint, {
    required PredicateLogicalOperator logical,
  }) {
    final path = _resolveRelationPath(relation, allowMorphTo: false);
    final where = _buildRelationPredicateConstraint(path, constraint);
    final predicate = RelationPredicate(path: path, where: where);
    return _appendPredicate(predicate, logical);
  }

  Query<T> _addRelationWhereTyped<TRelated extends OrmEntity>(
    String relation,
    PredicateCallback<TRelated>? constraint, {
    required PredicateLogicalOperator logical,
  }) {
    final path = _resolveRelationPath(relation, allowMorphTo: false);
    final where = _buildRelationPredicateConstraintTyped(path, constraint);
    final predicate = RelationPredicate(path: path, where: where);
    return _appendPredicate(predicate, logical);
  }
}
