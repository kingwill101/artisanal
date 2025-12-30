part of '../query_builder.dart';

/// Extension providing SELECT clause and projection methods for query results.
extension SelectExtension<T extends OrmEntity> on Query<T> {
  /// Only the specified [columns] will be retrieved from the database.
  ///
  /// Example:
  /// ```dart
  /// final userNames = await context.query<User>()
  ///   .select(['name', 'email'])
  ///   .get();
  /// ```
  Query<T> select(List<String> columns) {
    final mapped = columns
        .map((field) => _ensureField(field).columnName)
        .toList();
    final preservedRaw = _projectionOrder
        .where(
          (entry) =>
              entry.kind == ProjectionKind.raw ||
              entry.kind == ProjectionKind.custom,
        )
        .toList(growable: false);
    final order = <ProjectionOrderEntry>[
      for (var i = 0; i < mapped.length; i++) ProjectionOrderEntry.column(i),
      ...preservedRaw,
    ];
    return _copyWith(selects: mapped, projectionOrder: order);
  }

  /// Adds a single column to the select projection.
  ///
  /// This method allows you to incrementally add columns to the select list.
  ///
  /// Example:
  /// ```dart
  /// final userNamesAndEmails = await context.query<User>()
  ///   .select(['id'])
  ///   .addSelect('name')
  ///   .addSelect('email')
  ///   .get();
  /// ```
  Query<T> addSelect(String column) {
    final mapped = _ensureField(column).columnName;
    final newSelects = [..._selects, mapped];
    final order = [
      ..._projectionOrder,
      ProjectionOrderEntry.column(newSelects.length - 1),
    ];
    return _copyWith(selects: newSelects, projectionOrder: order);
  }

  /// Adds a raw select expression with optional bindings.
  ///
  /// This method allows you to include custom SQL expressions in the `SELECT` clause.
  /// Use `?` for parameter placeholders, and provide [bindings] for security.
  ///
  /// [sql] is the raw SQL expression.
  /// [alias] is an optional alias for the expression in the result.
  /// [bindings] are parameters for the raw SQL expression.
  ///
  /// Example:
  /// ```dart
  /// final usersWithFullName = await context.query<User>()
  ///   .selectRaw("CONCAT(firstName, ' ', lastName) AS fullName", alias: 'fullName')
  ///   .get();
  /// ```
  Query<T> selectRaw(
    String sql, {
    String? alias,
    List<Object?> bindings = const [],
  }) {
    final expression = RawSelectExpression(
      sql: sql,
      alias: alias,
      bindings: bindings,
    );
    final newRaw = [..._rawSelects, expression];
    final order = [
      ..._projectionOrder,
      ProjectionOrderEntry.raw(newRaw.length - 1),
    ];
    return _copyWith(rawSelects: newRaw, projectionOrder: order);
  }

  /// Adds a custom select expression compiled by a driver extension.
  ///
  /// Use [key] to select the registered extension handler, and [payload] to
  /// pass custom parameters to the handler.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .selectExtension('rank', payload: {'weight': 0.8}, alias: 'score')
  ///   .get();
  /// ```
  Query<T> selectExtension(
    String key, {
    Object? payload,
    String? alias,
  }) {
    final expression = CustomSelectExpression(
      key: key,
      payload: payload,
      alias: alias,
    );
    final newCustom = [..._customSelects, expression];
    final order = [
      ..._projectionOrder,
      ProjectionOrderEntry.custom(newCustom.length - 1),
    ];
    return _copyWith(customSelects: newCustom, projectionOrder: order);
  }

  /// Returns the value of [field] from the first row, or `null` when missing.
  ///
  /// This is useful for retrieving a single scalar value from the database.
  ///
  /// Example:
  /// ```dart
  /// final userName = await context.query<User>()
  ///   .where('id', 1)
  ///   .value<String>('name');
  /// print('User name: $userName');
  /// ```
  Future<R?> value<R>(String field) async {
    final column = _ensureField(field).columnName;
    final result = await select(<String>[field]).firstRow();
    return result?.row[column] as R?;
  }
}
