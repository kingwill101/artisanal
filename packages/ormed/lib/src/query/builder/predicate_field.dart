part of '../query_builder.dart';

/// Typed field helper for predicate callbacks.
///
/// Provides fluent helpers like `q.email.eq('a@b.com')` that delegate to the
/// underlying [PredicateBuilder].
class PredicateField<T extends OrmEntity, TValue> {
  const PredicateField(this._builder, this._field);

  final PredicateBuilder<T> _builder;
  final String _field;

  PredicateBuilder<T> eq(TValue value) =>
      _builder.where(_field, value, PredicateOperator.equals);

  PredicateBuilder<T> ne(TValue value) =>
      _builder.where(_field, value, PredicateOperator.notEquals);

  PredicateBuilder<T> notEq(TValue value) => ne(value);

  PredicateBuilder<T> gt(TValue value) =>
      _builder.where(_field, value, PredicateOperator.greaterThan);

  PredicateBuilder<T> gte(TValue value) =>
      _builder.where(_field, value, PredicateOperator.greaterThanOrEqual);

  PredicateBuilder<T> lt(TValue value) =>
      _builder.where(_field, value, PredicateOperator.lessThan);

  PredicateBuilder<T> lte(TValue value) =>
      _builder.where(_field, value, PredicateOperator.lessThanOrEqual);

  PredicateBuilder<T> between(TValue lower, TValue upper) =>
      _builder.whereBetween(_field, lower as Object, upper as Object);

  PredicateBuilder<T> notBetween(TValue lower, TValue upper) =>
      _builder.whereNotBetween(_field, lower as Object, upper as Object);

  PredicateBuilder<T> in_(Iterable<TValue> values) =>
      _builder.whereIn(_field, values);

  PredicateBuilder<T> notIn(Iterable<TValue> values) =>
      _builder.whereNotIn(_field, values);

  PredicateBuilder<T> isNull() => _builder.whereNull(_field);

  PredicateBuilder<T> isNotNull() => _builder.whereNotNull(_field);

  PredicateBuilder<T> like(Object value) =>
      _builder.where(_field, value, PredicateOperator.like);

  PredicateBuilder<T> notLike(Object value) =>
      _builder.where(_field, value, PredicateOperator.notLike);

  PredicateBuilder<T> iLike(Object value) =>
      _builder.where(_field, value, PredicateOperator.iLike);

  PredicateBuilder<T> notILike(Object value) =>
      _builder.where(_field, value, PredicateOperator.notILike);
}
