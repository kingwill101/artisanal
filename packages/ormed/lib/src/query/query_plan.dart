import 'package:ormed/src/model/model.dart';
import 'package:ormed/src/query/plan/join_definition.dart';

import '../contracts.dart';
import 'json_path.dart';

/// Immutable description of a query that `QueryExecutor` implementations
/// consume.
class QueryPlan {
  QueryPlan({
    required this.definition,
    this.driverName,
    this.tablePrefix,
    List<FilterClause>? filters,
    List<OrderClause>? orders,
    List<RawOrderExpression>? rawOrders,
    this.randomOrder = false,
    this.randomSeed,
    this.limit,
    this.offset,
    List<RelationLoad>? relations,
    List<JoinDefinition>? joins,
    List<IndexHint>? indexHints,
    List<FullTextWhere>? fullTextWheres,
    List<JsonWhereClause>? jsonWheres,
    List<DateWhereClause>? dateWheres,
    this.predicate,
    List<String>? selects,
    List<RawSelectExpression>? rawSelects,
    List<ProjectionOrderEntry>? projectionOrder,
    List<AggregateExpression>? aggregates,
    List<String>? groupBy,
    List<RawGroupByExpression>? rawGroupBy,
    this.having,
    List<RelationAggregate>? relationAggregates,
    List<RelationOrder>? relationOrders,
    List<RelationJoin>? relationJoins,
    this.tableAlias,
    this.lockClause,
    this.groupLimit,
    this.distinct = false,
    List<DistinctOnClause>? distinctOn,
    List<QueryUnion>? unions,
    this.disableAutoHydration = false,
    this.cacheTtl,
    this.disableCache = false,
  }) : filters = List.unmodifiable(filters ?? const []),
       orders = List.unmodifiable(orders ?? const []),
       rawOrders = List.unmodifiable(rawOrders ?? const []),
       relations = List.unmodifiable(relations ?? const []),
       indexHints = List.unmodifiable(indexHints ?? const <IndexHint>[]),
       fullTextWheres = List.unmodifiable(
         fullTextWheres ?? const <FullTextWhere>[],
       ),
       jsonWheres = List.unmodifiable(jsonWheres ?? const <JsonWhereClause>[]),
       dateWheres = List.unmodifiable(dateWheres ?? const <DateWhereClause>[]),
       selects = List.unmodifiable(selects ?? const []),
       rawSelects = List.unmodifiable(rawSelects ?? const []),
       projectionOrder = List.unmodifiable(
         projectionOrder ?? const <ProjectionOrderEntry>[],
       ),
       aggregates = List.unmodifiable(aggregates ?? const []),
       groupBy = List.unmodifiable(groupBy ?? const []),
       rawGroupBy = List.unmodifiable(rawGroupBy ?? const []),
       relationAggregates = List.unmodifiable(
         relationAggregates ?? const <RelationAggregate>[],
       ),
       relationOrders = List.unmodifiable(
         relationOrders ?? const <RelationOrder>[],
       ),
       relationJoins = List.unmodifiable(
         relationJoins ?? const <RelationJoin>[],
       ),
       joins = List.unmodifiable(joins ?? const <JoinDefinition>[]),
       distinctOn = List.unmodifiable(distinctOn ?? const <DistinctOnClause>[]),
       unions = List.unmodifiable(unions ?? const <QueryUnion>[]);

  final ModelDefinition<OrmEntity> definition;
  final String? driverName;
  final String? tablePrefix;
  final List<FilterClause> filters;
  final List<OrderClause> orders;
  final List<RawOrderExpression> rawOrders;
  final bool randomOrder;
  final num? randomSeed;
  final int? limit;
  final int? offset;
  final List<RelationLoad> relations;
  final List<IndexHint> indexHints;
  final List<FullTextWhere> fullTextWheres;
  final List<JsonWhereClause> jsonWheres;
  final List<DateWhereClause> dateWheres;
  final QueryPredicate? predicate;
  final List<String> selects;
  final List<RawSelectExpression> rawSelects;
  final List<ProjectionOrderEntry> projectionOrder;
  final List<AggregateExpression> aggregates;
  final List<String> groupBy;
  final List<RawGroupByExpression> rawGroupBy;
  final QueryPredicate? having;
  final List<RelationAggregate> relationAggregates;
  final List<RelationOrder> relationOrders;
  final List<RelationJoin> relationJoins;
  final List<JoinDefinition> joins;
  final String? tableAlias;
  final String? lockClause;
  final GroupLimit? groupLimit;
  final bool distinct;
  final List<DistinctOnClause> distinctOn;
  final List<QueryUnion> unions;
  final bool disableAutoHydration;
  final Duration? cacheTtl;
  final bool disableCache;

  QueryPlan copyWith({
    List<FilterClause>? filters,
    List<OrderClause>? orders,
    List<RawOrderExpression>? rawOrders,
    bool? randomOrder,
    num? randomSeed,
    int? limit,
    int? offset,
    List<RelationLoad>? relations,
    List<JoinDefinition>? joins,
    List<IndexHint>? indexHints,
    List<FullTextWhere>? fullTextWheres,
    List<JsonWhereClause>? jsonWheres,
    List<DateWhereClause>? dateWheres,
    QueryPredicate? predicate,
    List<String>? selects,
    List<RawSelectExpression>? rawSelects,
    List<ProjectionOrderEntry>? projectionOrder,
    List<AggregateExpression>? aggregates,
    List<String>? groupBy,
    List<RawGroupByExpression>? rawGroupBy,
    QueryPredicate? having,
    List<RelationAggregate>? relationAggregates,
    List<RelationOrder>? relationOrders,
    List<RelationJoin>? relationJoins,
    String? tableAlias,
    String? lockClause,
    GroupLimit? groupLimit,
    bool? distinct,
    List<DistinctOnClause>? distinctOn,
    List<QueryUnion>? unions,
    bool? disableAutoHydration,
    Duration? cacheTtl,
    bool? disableCache,
    String? tablePrefix,
  }) => QueryPlan(
    definition: definition,
    driverName: driverName,
    tablePrefix: tablePrefix ?? this.tablePrefix,
    filters: filters ?? this.filters,
    orders: orders ?? this.orders,
    rawOrders: rawOrders ?? this.rawOrders,
    randomOrder: randomOrder ?? this.randomOrder,
    randomSeed: randomSeed ?? this.randomSeed,
    limit: limit ?? this.limit,
    offset: offset ?? this.offset,
    relations: relations ?? this.relations,
    joins: joins ?? this.joins,
    indexHints: indexHints ?? this.indexHints,
    fullTextWheres: fullTextWheres ?? this.fullTextWheres,
    jsonWheres: jsonWheres ?? this.jsonWheres,
    dateWheres: dateWheres ?? this.dateWheres,
    predicate: predicate ?? this.predicate,
    selects: selects ?? this.selects,
    rawSelects: rawSelects ?? this.rawSelects,
    projectionOrder: projectionOrder ?? this.projectionOrder,
    aggregates: aggregates ?? this.aggregates,
    groupBy: groupBy ?? this.groupBy,
    rawGroupBy: rawGroupBy ?? this.rawGroupBy,
    having: having ?? this.having,
    relationAggregates: relationAggregates ?? this.relationAggregates,
    relationOrders: relationOrders ?? this.relationOrders,
    relationJoins: relationJoins ?? this.relationJoins,
    tableAlias: tableAlias ?? this.tableAlias,
    lockClause: lockClause ?? this.lockClause,
    groupLimit: groupLimit ?? this.groupLimit,
    distinct: distinct ?? this.distinct,
    distinctOn: distinctOn ?? this.distinctOn,
    unions: unions ?? this.unions,
    disableAutoHydration: disableAutoHydration ?? this.disableAutoHydration,
    cacheTtl: cacheTtl ?? this.cacheTtl,
    disableCache: disableCache ?? this.disableCache,
  );

  @override
  String toString() {
    final parts = <String>[
      'QueryPlan(${definition.tableName}',
      if (filters.isNotEmpty) 'filters: ${filters.length}',
      if (orders.isNotEmpty) 'orders: ${orders.length}',
      if (rawOrders.isNotEmpty) 'rawOrders: ${rawOrders.length}',
      if (limit != null) 'limit: $limit',
      if (offset != null) 'offset: $offset',
      if (joins.isNotEmpty) 'joins: ${joins.length}',
      if (relations.isNotEmpty) 'relations: ${relations.length}',
      if (selects.isNotEmpty) 'selects: ${selects.length}',
      if (aggregates.isNotEmpty) 'aggregates: ${aggregates.length}',
      if (rawGroupBy.isNotEmpty) 'rawGroupBy: ${rawGroupBy.length}',
      if (distinct) 'distinct',
    ];
    return '${parts.join(', ')})';
  }
}

class QueryUnion {
  const QueryUnion({required this.plan, this.all = false});

  final QueryPlan plan;
  final bool all;
}

enum IndexHintType { use, force, ignore }

class IndexHint {
  IndexHint(this.type, List<String> indexes)
    : indexes = List.unmodifiable(indexes);

  final IndexHintType type;
  final List<String> indexes;
}

enum FullTextMode { natural, boolean, phrase, websearch }

class FullTextWhere {
  FullTextWhere({
    required List<String> columns,
    required this.value,
    this.language,
    this.mode = FullTextMode.natural,
    this.expanded = false,
  }) : columns = List.unmodifiable(columns);

  final List<String> columns;
  final Object value;
  final String? language;
  final FullTextMode mode;
  final bool expanded;
}

enum JsonPredicateType { contains, overlaps, containsKey, length }

class JsonWhereClause {
  JsonWhereClause.contains({
    required this.column,
    required this.path,
    required this.value,
  }) : type = JsonPredicateType.contains,
       lengthOperator = null,
       lengthValue = null;

  JsonWhereClause.overlaps({
    required this.column,
    required this.path,
    required this.value,
  }) : type = JsonPredicateType.overlaps,
       lengthOperator = null,
       lengthValue = null;

  JsonWhereClause.containsKey({required this.column, required this.path})
    : type = JsonPredicateType.containsKey,
      value = null,
      lengthOperator = null,
      lengthValue = null;

  JsonWhereClause.length({
    required this.column,
    required this.path,
    required this.lengthOperator,
    required this.lengthValue,
  }) : type = JsonPredicateType.length,
       value = null;

  final String column;
  final String path;
  final JsonPredicateType type;
  final Object? value;
  final String? lengthOperator;
  final int? lengthValue;

  bool get targetsRoot => path == r'$';
}

class GroupLimit {
  const GroupLimit({required this.column, required this.limit, this.offset});

  final String column;
  final int limit;
  final int? offset;
}

enum DateComponent { date, day, month, year, time }

class DateWhereClause {
  const DateWhereClause({
    required this.column,
    required this.path,
    required this.component,
    required this.operator,
    required this.value,
  });

  final String column;
  final String path;
  final DateComponent component;
  final String operator;
  final Object value;

  bool get targetsRoot => path == r'$';
}

/// Predicate fragment within a JOIN clause.
class JoinCondition {
  const JoinCondition.column({
    required this.left,
    required this.operator,
    required this.right,
    this.boolean = PredicateLogicalOperator.and,
  }) : value = null,
       rawSql = null,
       bindings = const [];

  const JoinCondition.value({
    required this.left,
    required this.operator,
    required this.value,
    this.boolean = PredicateLogicalOperator.and,
  }) : right = null,
       rawSql = null,
       bindings = const [];

  const JoinCondition.raw({
    required this.rawSql,
    this.bindings = const [],
    this.boolean = PredicateLogicalOperator.and,
  }) : left = null,
       operator = null,
       right = null,
       value = null;

  final String? left;
  final String? operator;
  final String? right;
  final Object? value;
  final String? rawSql;
  final List<Object?> bindings;
  final PredicateLogicalOperator boolean;

  bool get isColumnComparison =>
      left != null && right != null && rawSql == null && value == null;

  bool get isValueComparison => left != null && value != null && rawSql == null;

  bool get isRaw => rawSql != null;
}

/// Filter clause applied to a single column.
class FilterClause {
  const FilterClause({
    required this.field,
    required this.operator,
    required this.value,
    this.compile = true,
  });

  final String field;
  final FilterOperator operator;
  final Object? value;
  final bool compile;
}

/// Supported comparison operators for filters.
enum FilterOperator {
  equals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  contains,
  inValues,
  isNull,
  isNotNull,
}

/// Logical operator used for predicate grouping.
enum PredicateLogicalOperator { and, or }

/// Comparison operators for complex predicates.
enum PredicateOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  between,
  notBetween,
  inValues,
  notInValues,
  like,
  notLike,
  iLike,
  notILike,
  isNull,
  isNotNull,
  columnEquals,
  columnNotEquals,
  raw,
}

class BitwisePredicate extends QueryPredicate {
  const BitwisePredicate({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final String operator;
  final Object value;
}

/// Base type for predicate nodes.
sealed class QueryPredicate {
  const QueryPredicate();
}

/// A group of predicates joined by [logicalOperator].
class PredicateGroup extends QueryPredicate {
  PredicateGroup({
    required this.logicalOperator,
    required List<QueryPredicate> predicates,
  }) : predicates = List.unmodifiable(predicates);

  final PredicateLogicalOperator logicalOperator;
  final List<QueryPredicate> predicates;
}

/// Predicate that targets a specific column.
class FieldPredicate extends QueryPredicate {
  const FieldPredicate({
    required this.field,
    required this.operator,
    this.value,
    this.lower,
    this.upper,
    this.values,
    this.compareField,
    this.caseInsensitive = false,
    this.jsonSelector,
    this.jsonBooleanComparison = false,
  });

  final String field;
  final PredicateOperator operator;
  final Object? value;
  final Object? lower;
  final Object? upper;
  final List<Object?>? values;
  final String? compareField;
  final bool caseInsensitive;
  final JsonSelector? jsonSelector;
  final bool jsonBooleanComparison;
}

/// Raw SQL predicate fragment with optional bindings.
class RawPredicate extends QueryPredicate {
  RawPredicate({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  final String sql;
  final List<Object?> bindings;
}

/// Subquery predicate for WHERE IN, WHERE EXISTS, etc.
class SubqueryPredicate extends QueryPredicate {
  const SubqueryPredicate({
    required this.type,
    required this.subquery,
    this.field,
    this.negate = false,
  });

  final SubqueryType type;
  final QueryPlan subquery;
  final String? field; // Used for IN/NOT IN
  final bool negate;
}

/// Types of subquery predicates.
enum SubqueryType {
  /// WHERE field IN (subquery)
  whereIn,

  /// WHERE EXISTS (subquery)
  exists,
}

/// Raw select expression.
class RawSelectExpression {
  RawSelectExpression({required this.sql, this.alias, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  final String sql;
  final String? alias;
  final List<Object?> bindings;
}

/// Raw ORDER BY expression.
class RawOrderExpression {
  RawOrderExpression({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  final String sql;
  final List<Object?> bindings;
}

/// Raw GROUP BY expression.
class RawGroupByExpression {
  RawGroupByExpression({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  final String sql;
  final List<Object?> bindings;
}

enum ProjectionKind { column, raw }

class ProjectionOrderEntry {
  const ProjectionOrderEntry._(this.kind, this.index);

  const ProjectionOrderEntry.column(int index)
    : this._(ProjectionKind.column, index);

  const ProjectionOrderEntry.raw(int index) : this._(ProjectionKind.raw, index);

  final ProjectionKind kind;
  final int index;
}

/// Supported aggregate functions.
enum AggregateFunction { count, sum, avg, min, max }

/// Aggregate expression descriptor.
class AggregateExpression {
  const AggregateExpression({
    required this.function,
    required this.expression,
    this.alias,
  });

  final AggregateFunction function;
  final String expression;
  final String? alias;
}

/// Ordering rule applied to a column.
class OrderClause {
  const OrderClause({
    required this.field,
    this.descending = false,
    this.jsonSelector,
  });

  final String field;
  final bool descending;
  final JsonSelector? jsonSelector;
}

class DistinctOnClause {
  const DistinctOnClause({required this.field, this.jsonSelector});

  final String field;
  final JsonSelector? jsonSelector;
}

/// Declaration describing an eager-loaded relation request.
class RelationLoad {
  RelationLoad({
    required this.relation,
    this.predicate,
    this.nested = const [],
  });

  final RelationDefinition relation;
  final QueryPredicate? predicate;
  final List<RelationLoad> nested;
}

class RelationPath {
  RelationPath({required List<RelationSegment> segments})
    : segments = List.unmodifiable(segments);

  final List<RelationSegment> segments;

  RelationSegment get leaf => segments.last;
}

class RelationSegment {
  RelationSegment({
    required this.name,
    required this.relation,
    required this.parentDefinition,
    required this.targetDefinition,
    required this.parentKey,
    required this.childKey,
    this.foreignKeyOnParent = false,
    this.throughDefinition,
    this.throughParentKey,
    this.throughChildKey,
    this.pivotTable,
    this.pivotParentKey,
    this.pivotRelatedKey,
    List<String> pivotColumns = const [],
    this.pivotTimestamps = false,
    this.morphTypeColumn,
    this.morphClass,
    this.morphOnPivot = false,
    this.expectSingleResult = false,
  }) : pivotColumns = List.unmodifiable(pivotColumns);

  final String name;
  final RelationDefinition relation;
  final ModelDefinition<OrmEntity> parentDefinition;
  final ModelDefinition<OrmEntity> targetDefinition;
  final String parentKey;
  final String childKey;
  final bool foreignKeyOnParent;
  final ModelDefinition<OrmEntity>? throughDefinition;
  final String? throughParentKey;
  final String? throughChildKey;
  final String? pivotTable;
  final String? pivotParentKey;
  final String? pivotRelatedKey;
  final List<String> pivotColumns;
  final bool pivotTimestamps;
  final String? morphTypeColumn;
  final String? morphClass;
  final bool morphOnPivot;
  final bool expectSingleResult;

  bool get usesThrough => throughDefinition != null;

  bool get usesPivot => pivotTable != null;

  bool get usesMorph => morphTypeColumn != null;
}

/// Captures a join edge between the base table and a related segment the query
/// references. Grammars can reuse this graph across aggregates, ordering, and
/// eager loading helpers.
class RelationJoin {
  RelationJoin({required this.pathKey, required List<RelationJoinEdge> edges})
    : edges = List.unmodifiable(edges);

  /// Dot-notated relation name (e.g. `posts`, `posts.photos`).
  final String pathKey;
  final List<RelationJoinEdge> edges;

  RelationJoinEdge get leaf => edges.last;
}

class RelationJoinEdge {
  RelationJoinEdge({
    required this.segment,
    required this.parentAlias,
    required this.alias,
    this.pivotAlias,
    this.throughAlias,
  });

  final RelationSegment segment;
  final String parentAlias;
  final String alias;
  final String? pivotAlias;
  final String? throughAlias;
}

class RelationPredicate extends QueryPredicate {
  RelationPredicate({
    required this.path,
    this.where,
    this.minimum = 1,
    this.maximum,
  });

  final RelationPath path;
  final QueryPredicate? where;
  final int minimum;
  final int? maximum;
}

enum RelationAggregateType { count, exists, sum, avg, max, min }

class RelationAggregate {
  RelationAggregate({
    required this.type,
    required this.alias,
    required this.path,
    this.where,
    this.distinct = false,
    this.column,
  });

  final RelationAggregateType type;
  final String alias;
  final RelationPath path;
  final QueryPredicate? where;
  final bool distinct;

  /// The column to aggregate (used for sum, avg, max, min).
  final String? column;
}

class RelationOrder {
  RelationOrder({
    required this.path,
    required this.aggregateType,
    this.descending = false,
    this.where,
    this.distinct = false,
  });

  final RelationPath path;
  final RelationAggregateType aggregateType;
  final bool descending;
  final QueryPredicate? where;
  final bool distinct;
}

/// Represents a resolved relation path for joins and aggregates.
