part of '../query_builder.dart';

/// Lightweight builder used for nested predicate callbacks.
class PredicateBuilder<T extends OrmEntity> {
  /// Creates a new [PredicateBuilder].
  PredicateBuilder(this.definition);

  /// The model definition for the entity being queried.
  final ModelDefinition<T> definition;
  QueryPredicate? _predicate;

  /// Adds a basic `WHERE` clause to the predicate.
  PredicateBuilder<T> where(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.and,
    );
    return this;
  }

  PredicateBuilder<T> orWhere(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.or,
    );
    return this;
  }

  PredicateBuilder<T> whereBetween(String field, Object lower, Object upper) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: PredicateOperator.between,
        lower: lower,
        upper: upper,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereNotBetween(
    String field,
    Object lower,
    Object upper,
  ) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: PredicateOperator.notBetween,
        lower: lower,
        upper: upper,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereIn(String field, Iterable<Object?> values) =>
      where(field, values.toList(), PredicateOperator.inValues);

  PredicateBuilder<T> whereNotIn(String field, Iterable<Object?> values) =>
      where(field, values.toList(), PredicateOperator.notInValues);

  PredicateBuilder<T> whereNull(String field) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(field: column, operator: PredicateOperator.isNull),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereNotNull(String field) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(field: column, operator: PredicateOperator.isNotNull),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: caseInsensitive
            ? PredicateOperator.iLike
            : PredicateOperator.like,
        value: value,
        caseInsensitive: caseInsensitive,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereILike(String field, Object value) =>
      whereLike(field, value, caseInsensitive: true);

  PredicateBuilder<T> whereNotILike(String field, Object value) =>
      whereNotLike(field, value, caseInsensitive: true);

  PredicateBuilder<T> whereNotLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: caseInsensitive
            ? PredicateOperator.notILike
            : PredicateOperator.notLike,
        value: value,
        caseInsensitive: caseInsensitive,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereColumn(
    String left,
    String right, {
    PredicateOperator operator = PredicateOperator.columnEquals,
  }) {
    final leftColumn = _ensureField(left).columnName;
    final rightColumn = _ensureField(right).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: leftColumn,
        compareField: rightColumn,
        operator: operator,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereRaw(
    String sql, [
    List<Object?> bindings = const [],
  ]) => _appendPredicate(
    RawPredicate(sql: sql, bindings: bindings),
    PredicateLogicalOperator.and,
  );

  PredicateBuilder<T> whereBitwise(
    String field,
    String operator,
    Object value,
  ) => _appendPredicate(
    BitwisePredicate(
      field: _ensureField(field).columnName,
      operator: _normalizeBitwiseOperator(operator),
      value: value,
    ),
    PredicateLogicalOperator.and,
  );

  PredicateBuilder<T> orWhereBitwise(
    String field,
    String operator,
    Object value,
  ) => _appendPredicate(
    BitwisePredicate(
      field: _ensureField(field).columnName,
      operator: _normalizeBitwiseOperator(operator),
      value: value,
    ),
    PredicateLogicalOperator.or,
  );

  QueryPredicate? build() => _predicate;

  PredicateBuilder<T> _appendPredicate(
    QueryPredicate predicate,
    PredicateLogicalOperator logical,
  ) {
    _predicate = _combinePredicates(_predicate, predicate, logical);
    return this;
  }

  void _addWhere(
    Object fieldOrCallback,
    Object? value,
    PredicateOperator operator, {
    required PredicateLogicalOperator logical,
  }) {
    if (fieldOrCallback is String) {
      final column = _ensureField(fieldOrCallback).columnName;
      final predicate = _buildFieldPredicate(column, operator, value);
      _predicate = _combinePredicates(_predicate, predicate, logical);
      return;
    }

    if (fieldOrCallback is PredicateCallback<T>) {
      final nestedBuilder = PredicateBuilder<T>(definition);
      fieldOrCallback(nestedBuilder);
      final nested = nestedBuilder.build();
      if (nested != null) {
        _predicate = _combinePredicates(_predicate, nested, logical);
      }
      return;
    }

    throw ArgumentError.value(
      fieldOrCallback,
      'fieldOrCallback',
      'Must be a column name or predicate callback.',
    );
  }

  FieldDefinition _ensureField(String name) {
    final field = definition.fields.firstWhereOrNull(
      (f) => f.name == name || f.columnName == name,
    );
    if (field != null) {
      return field;
    }
    if (definition is AdHocModelDefinition) {
      return (definition as AdHocModelDefinition).fieldFor(name);
    }
    throw ArgumentError.value(
      name,
      'field',
      'Unknown field on ${definition.modelName}.',
    );
  }

  FieldPredicate _buildFieldPredicate(
    String column,
    PredicateOperator operator,
    Object? value,
  ) {
    if (operator == PredicateOperator.columnEquals ||
        operator == PredicateOperator.columnNotEquals) {
      if (value is! String) {
        throw ArgumentError.value(
          value,
          'value',
          'Column comparisons require another column name.',
        );
      }
      final compare = _ensureField(value).columnName;
      return FieldPredicate(
        field: column,
        operator: operator,
        compareField: compare,
      );
    }
    if (operator == PredicateOperator.inValues ||
        operator == PredicateOperator.notInValues) {
      if (value is! Iterable) {
        throw ArgumentError.value(
          value,
          'value',
          'Iterable required for $operator predicates.',
        );
      }
      final Iterable<Object?> iterable = value;
      return FieldPredicate(
        field: column,
        operator: operator,
        values: List<Object?>.from(iterable),
      );
    }
    return FieldPredicate(field: column, operator: operator, value: value);
  }

  QueryPredicate _combinePredicates(
    QueryPredicate? existing,
    QueryPredicate addition,
    PredicateLogicalOperator logical,
  ) {
    if (existing == null) {
      return addition;
    }
    return _mergeGroups(existing, addition, logical);
  }

  QueryPredicate _mergeGroups(
    QueryPredicate left,
    QueryPredicate right,
    PredicateLogicalOperator logical,
  ) {
    if (left is PredicateGroup && left.logicalOperator == logical) {
      return PredicateGroup(
        logicalOperator: logical,
        predicates: [...left.predicates, right],
      );
    }
    if (right is PredicateGroup && right.logicalOperator == logical) {
      return PredicateGroup(
        logicalOperator: logical,
        predicates: [left, ...right.predicates],
      );
    }
    return PredicateGroup(logicalOperator: logical, predicates: [left, right]);
  }
}
