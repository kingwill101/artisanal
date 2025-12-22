part of '../query_builder.dart';

/// Fluent builder for constructing complex `JOIN` conditions.
class JoinBuilder {
  JoinBuilder._();

  final List<JoinCondition> _conditions = <JoinCondition>[];

  /// Adds a basic `ON` clause to the join.
  JoinBuilder on(String first, [Object? operator, String? second]) {
    final op = _normalizeJoinOperatorToken(operator);
    if (second == null) {
      throw ArgumentError('Join on clauses require a second column.');
    }
    _conditions.add(
      JoinCondition.column(left: first, operator: op, right: second),
    );
    return this;
  }

  JoinBuilder orOn(String first, [Object? operator, String? second]) {
    final op = _normalizeJoinOperatorToken(operator);
    if (second == null) {
      throw ArgumentError('Join on clauses require a second column.');
    }
    _conditions.add(
      JoinCondition.column(
        left: first,
        operator: op,
        right: second,
        boolean: PredicateLogicalOperator.or,
      ),
    );
    return this;
  }

  JoinBuilder where(String column, Object? value, [Object? operator]) {
    final op = _normalizeJoinOperatorToken(operator);
    _conditions.add(
      JoinCondition.value(left: column, operator: op, value: value),
    );
    return this;
  }

  JoinBuilder orWhere(String column, Object? value, [Object? operator]) {
    final op = _normalizeJoinOperatorToken(operator);
    _conditions.add(
      JoinCondition.value(
        left: column,
        operator: op,
        value: value,
        boolean: PredicateLogicalOperator.or,
      ),
    );
    return this;
  }

  JoinBuilder whereRaw(String sql, [List<Object?> bindings = const []]) {
    _conditions.add(JoinCondition.raw(rawSql: sql, bindings: bindings));
    return this;
  }

  JoinBuilder orWhereRaw(String sql, [List<Object?> bindings = const []]) {
    _conditions.add(
      JoinCondition.raw(
        rawSql: sql,
        bindings: bindings,
        boolean: PredicateLogicalOperator.or,
      ),
    );
    return this;
  }
}
