import 'dart:convert' show jsonEncode;

import 'package:carbonized/carbonized.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:ormed/src/query/plan/join_definition.dart';
import 'package:ormed/src/query/plan/join_target.dart';
import 'package:ormed/src/query/plan/join_type.dart';

import '../annotations.dart';
import '../core/orm_config.dart';
import '../core/utc_time.dart';
import '../core/sql_null.dart';
import '../events/event_bus.dart';
import '../driver/driver.dart';
import '../exceptions.dart';
import 'package:ormed/src/model/model.dart';
import '../mutation/mutation_input_helper.dart';
import '../mutation/json_update.dart';
import '../contracts.dart';
import 'json_path.dart' as json_path;
import 'query.dart';

part 'builder/aggregate.dart';

part 'builder/batch.dart';

part 'builder/caching.dart';

part 'builder/crud.dart';

part 'builder/distinct.dart';

part 'builder/grouping.dart';

part 'builder/index.dart';

part 'builder/join.dart';

part 'builder/json.dart';

part 'builder/json_builder.dart';

part 'builder/lock.dart';

part 'builder/models.dart';

part 'builder/order.dart';

part 'builder/paginate.dart';

part 'builder/predicate.dart';

part 'builder/predicate_field.dart';

part 'builder/raw.dart';

part 'builder/relation.dart';

part 'builder/scope.dart';

part 'builder/select.dart';

part 'builder/soft_delete.dart';

part 'builder/streaming.dart';

part 'builder/subquery.dart';

part 'builder/union.dart';

part 'builder/utility.dart';

part 'builder/where.dart';

/// Fluent builder for filtering, ordering, paginating, and eager-loading
/// models of type [T].
///
/// The [Query] class provides a powerful and flexible API for constructing
/// database queries in a fluent manner. It supports a wide range of operations
/// including `WHERE` clauses, `JOIN`s, `ORDER BY`, `LIMIT`, `OFFSET`,
/// eager loading of relations, and various aggregation functions.
///
/// Queries are executed against a [QueryContext] which provides the underlying
/// database driver and model definitions.
///
/// Example:
/// ```dart
/// final users = await context.query<User>()
///   .where('active', equals: true)
///   .orderBy('name')
///   .get();
///
/// final activePosts = await context.query<Post>()
///   .joinRelation('author')
///   .where('author.isActive', true)
///   .get();
/// ```
class Query<T extends OrmEntity> {
  Query({
    required this.definition,
    required this.context,
    List<FilterClause>? filters,
    List<OrderClause>? orders,
    List<RawOrderExpression>? rawOrders,
    List<CustomOrderExpression>? customOrders,
    List<RelationLoad>? relations,
    List<JoinDefinition>? joins,
    List<IndexHint>? indexHints,
    List<FullTextWhere>? fullTextWheres,
    List<JsonWhereClause>? jsonWheres,
    List<DateWhereClause>? dateWheres,
    bool randomOrder = false,
    num? randomSeed,
    String? lockClause,
    int? limit,
    int? offset,
    QueryPredicate? predicate,
    List<String>? selects,
    List<RawSelectExpression>? rawSelects,
    List<CustomSelectExpression>? customSelects,
    List<ProjectionOrderEntry>? projectionOrder,
    List<AggregateExpression>? aggregates,
    List<String>? groupBy,
    List<RawGroupByExpression>? rawGroupBy,
    List<CustomGroupByExpression>? customGroupBy,
    QueryPredicate? having,
    List<RelationAggregate>? relationAggregates,
    List<RelationOrder>? relationOrders,
    Map<String, RelationPath>? relationPaths,
    Set<String>? ignoredScopes,
    bool globalScopesApplied = false,
    bool ignoreAllGlobalScopes = false,
    String? tableAlias,
    List<String>? adHocScopes,
    Map<String, RelationJoinRequest>? relationJoinRequests,
    GroupLimit? groupLimit,
    bool distinct = false,
    List<DistinctOnClause>? distinctOn,
    List<QueryUnion>? unions,
    Duration? cacheTtl,
    bool disableCache = false,
    bool suppressEvents = false,
  }) : _filters = filters ?? <FilterClause>[],
       _orders = orders ?? <OrderClause>[],
       _rawOrders = rawOrders ?? <RawOrderExpression>[],
       _customOrders = customOrders ?? <CustomOrderExpression>[],
       _relations = relations ?? <RelationLoad>[],
       _joins = joins ?? <JoinDefinition>[],
       _indexHints = indexHints ?? <IndexHint>[],
       _fullTextWheres = fullTextWheres ?? <FullTextWhere>[],
       _jsonWheres = jsonWheres ?? <JsonWhereClause>[],
       _dateWheres = dateWheres ?? <DateWhereClause>[],
       _randomOrder = randomOrder,
       _randomSeed = randomSeed,
       _lockClause = lockClause,
       _limit = limit,
       _offset = offset,
       _predicate = predicate,
       _selects = selects ?? <String>[],
       _rawSelects = rawSelects ?? <RawSelectExpression>[],
       _customSelects = customSelects ?? <CustomSelectExpression>[],
       _projectionOrder = projectionOrder ?? <ProjectionOrderEntry>[],
       _aggregates = aggregates ?? <AggregateExpression>[],
       _groupBy = groupBy ?? <String>[],
       _rawGroupBy = rawGroupBy ?? <RawGroupByExpression>[],
       _customGroupBy = customGroupBy ?? <CustomGroupByExpression>[],
       _having = having,
       _relationAggregates = relationAggregates ?? <RelationAggregate>[],
       _relationOrders = relationOrders ?? <RelationOrder>[],
       _relationPaths = relationPaths != null
           ? Map<String, RelationPath>.from(relationPaths)
           : <String, RelationPath>{},
       _relationJoinRequests = relationJoinRequests != null
           ? Map<String, RelationJoinRequest>.from(relationJoinRequests)
           : <String, RelationJoinRequest>{},
       _ignoredGlobalScopes = ignoredScopes ?? <String>{},
       _globalScopesApplied = globalScopesApplied,
       _ignoreAllGlobalScopes = ignoreAllGlobalScopes,
       _tableAlias = tableAlias,
       _adHocScopes = List<String>.from(adHocScopes ?? const <String>[]),
       _groupLimit = groupLimit,
       _distinct = distinct,
       _distinctOn = List<DistinctOnClause>.from(
         distinctOn ?? const <DistinctOnClause>[],
       ),
       _unions = unions ?? const <QueryUnion>[],
       _cacheTtl = cacheTtl,
       _disableCache = disableCache,
       _suppressEvents = suppressEvents {
    OrmConfig.ensureInitialized();
  }

  final ModelDefinition<T> definition;
  final QueryContext context;
  final List<FilterClause> _filters;
  final List<OrderClause> _orders;
  final List<RawOrderExpression> _rawOrders;
  final List<CustomOrderExpression> _customOrders;
  final List<RelationLoad> _relations;
  final List<JoinDefinition> _joins;
  final List<IndexHint> _indexHints;
  final List<FullTextWhere> _fullTextWheres;
  final List<JsonWhereClause> _jsonWheres;
  final List<DateWhereClause> _dateWheres;
  final bool _randomOrder;
  final num? _randomSeed;
  final String? _lockClause;
  final int? _limit;
  final int? _offset;
  final QueryPredicate? _predicate;
  final List<String> _selects;
  final List<RawSelectExpression> _rawSelects;
  final List<CustomSelectExpression> _customSelects;
  final List<ProjectionOrderEntry> _projectionOrder;
  final List<AggregateExpression> _aggregates;
  final List<String> _groupBy;
  final List<RawGroupByExpression> _rawGroupBy;
  final List<CustomGroupByExpression> _customGroupBy;
  final QueryPredicate? _having;
  final List<RelationAggregate> _relationAggregates;
  final List<RelationOrder> _relationOrders;
  final Map<String, RelationPath> _relationPaths;
  final Map<String, RelationJoinRequest> _relationJoinRequests;
  final Set<String> _ignoredGlobalScopes;
  final bool _globalScopesApplied;
  final bool _ignoreAllGlobalScopes;
  final String? _tableAlias;
  final List<String> _adHocScopes;
  final GroupLimit? _groupLimit;
  final bool _distinct;
  final List<DistinctOnClause> _distinctOn;
  final List<QueryUnion> _unions;
  final Duration? _cacheTtl;
  final bool _disableCache;
  final bool _suppressEvents;

  static const String _softDeleteScope =
      ScopeRegistry.softDeleteScopeIdentifier;
  static const int _defaultStreamEagerBatchSize = 500;
  static const Object _unset = Object();

  EventBus get _events => context.events;

  /// Lazy-loaded relation resolver instance.
  ///
  /// Reuses the same instance across multiple relation operations
  /// to avoid creating unnecessary objects.
  RelationResolver? _relationResolver;

  RelationResolver get _resolver =>
      _relationResolver ??= RelationResolver(context);

  List<DistinctOnClause> _normalizeDistinctColumns(Iterable<String> columns) {
    if (columns.isEmpty) {
      return const <DistinctOnClause>[];
    }
    final clauses = <DistinctOnClause>[];
    for (final column in columns) {
      if (json_path.hasJsonSelector(column)) {
        final selector = json_path.parseJsonSelectorExpression(column);
        if (selector == null) {
          throw ArgumentError.value(column, 'columns', 'Invalid JSON selector');
        }
        final resolved = _ensureField(selector.column).columnName;
        final normalizedSelector = json_path.JsonSelector(
          resolved,
          selector.path,
          selector.extractsText,
        );
        clauses.add(
          DistinctOnClause(field: resolved, jsonSelector: normalizedSelector),
        );
      } else {
        final resolved = _ensureField(column).columnName;
        clauses.add(DistinctOnClause(field: resolved));
      }
    }
    return clauses;
  }

  /// Selects a subset of columns for the result projection.
  ///

  String _resolveExpression(String expression) {
    final field = definition.fields.firstWhereOrNull(
      (f) => f.name == expression || f.columnName == expression,
    );
    return field?.columnName ?? expression;
  }

  Future<num?> _aggregateScalar(
    AggregateFunction function,
    String expression, {
    String? alias,
  }) async {
    final resolved = _resolveExpression(expression);
    final referenceAlias = alias ?? _aggregateAlias(_aggregateLabel(function));
    final aggregateQuery = _copyForAggregation().withAggregate(
      function,
      resolved,
      alias: referenceAlias,
    );
    final plan = aggregateQuery._buildPlan();
    final rows = await context.runSelect(plan);
    if (rows.isEmpty) {
      return null;
    }
    final value = rows.first[referenceAlias];
    return _normalizeAggregateValue(value);
  }

  String _aggregateLabel(AggregateFunction function) {
    switch (function) {
      case AggregateFunction.count:
        return 'count';
      case AggregateFunction.sum:
        return 'sum';
      case AggregateFunction.avg:
        return 'avg';
      case AggregateFunction.min:
        return 'min';
      case AggregateFunction.max:
        return 'max';
    }
  }

  num? _normalizeAggregateValue(Object? value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  Future<void> _applyRelationHookBatch<R extends OrmEntity>(
    QueryPlan plan,
    List<QueryRow<R>> batch,
  ) async {
    if (batch.isEmpty || (_relations.isEmpty && _relationAggregates.isEmpty)) {
      return;
    }
    final relationHook = context.driver.metadata.relationHook;
    if (relationHook != null) {
      await relationHook.handleRelations(
        context,
        plan,
        definition,
        batch,
        _relations,
      );
      // Copy aggregate values from row to model after relation hook
      // (since aggregates are computed by the relation hook)
      if (plan.relationAggregates.isNotEmpty) {
        for (final queryRow in batch) {
          if (queryRow.model is ModelAttributes) {
            final model = queryRow.model as ModelAttributes;
            for (final aggregate in plan.relationAggregates) {
              if (queryRow.row.containsKey(aggregate.alias)) {
                model.setAttribute(
                  aggregate.alias,
                  queryRow.row[aggregate.alias],
                );
              }
            }
          }
        }
      }
      return;
    }
    if (_relations.isEmpty) {
      return;
    }
    final loader = RelationLoader(context);
    final joinMap = {for (final join in plan.relationJoins) join.pathKey: join};
    await loader.attach(definition, batch, _relations, joinMap: joinMap);
  }

  QueryRow<T> _hydrateRow(Map<String, Object?> row, QueryPlan plan) {
    final model = definition.fromMap(row, registry: context.codecRegistry);
    context.attachRuntimeMetadata(model);

    // Copy aggregate columns (and other extra attributes) that aren't part of the model definition
    // This includes withCount, withSum, withAvg, withMax, withMin, withExists results
    if (plan.relationAggregates.isNotEmpty && model is ModelAttributes) {
      for (final aggregate in plan.relationAggregates) {
        if (row.containsKey(aggregate.alias)) {
          (model as ModelAttributes).setAttribute(
            aggregate.alias,
            row[aggregate.alias],
          );
        }
      }
    }

    // Sync original state for change tracking
    if (model is ModelAttributes) {
      (model as ModelAttributes).syncOriginal();
    }

    if (!_suppressEvents) {
      _events.emit(
        ModelRetrievedEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: model,
        ),
      );
    }

    return QueryRow<T>(model: model, row: _projectionRow(row, plan));
  }

  Map<String, Object?> _projectionRow(
    Map<String, Object?> row,
    QueryPlan plan,
  ) {
    final hasCustomProjection =
        plan.selects.isNotEmpty ||
        plan.rawSelects.isNotEmpty ||
        plan.customSelects.isNotEmpty ||
        plan.aggregates.isNotEmpty;
    if (!hasCustomProjection && plan.distinctOn.isEmpty) {
      return Map<String, Object?>.from(row);
    }
    final filtered = <String, Object?>{};
    for (final column in plan.selects) {
      if (row.containsKey(column)) {
        filtered[column] = row[column];
      }
    }
    for (final raw in plan.rawSelects) {
      final alias = raw.alias;
      if (alias != null && row.containsKey(alias)) {
        filtered[alias] = row[alias];
      }
    }
    for (final custom in plan.customSelects) {
      final alias = custom.alias;
      if (alias != null && row.containsKey(alias)) {
        filtered[alias] = row[alias];
      }
    }
    for (final aggregate in plan.aggregates) {
      final alias = aggregate.alias;
      if (alias != null && row.containsKey(alias)) {
        filtered[alias] = row[alias];
      }
    }
    for (final clause in plan.distinctOn) {
      if (row.containsKey(clause.field)) {
        filtered[clause.field] = row[clause.field];
      }
    }
    if (filtered.isEmpty) {
      return Map<String, Object?>.from(row);
    }
    return filtered;
  }

  /// Exposes the built plan for tests.
  @visibleForTesting
  QueryPlan debugPlan() => _buildPlan();

  QueryPlan _buildPlan() {
    if (!_globalScopesApplied) {
      final scoped = context.scopeRegistry.applyGlobalScopes(this);
      if (!identical(scoped, this)) {
        return scoped._buildPlan();
      }
    }
    final relationJoinEntries = _relationPaths.entries
        .map((entry) {
          final edges = <RelationJoinEdge>[];
          var parentAlias = 'base';
          final aliasBase = entry.key.replaceAll('.', '_');
          final segments = entry.value.segments;
          for (var i = 0; i < segments.length; i++) {
            final segment = segments[i];
            final alias = 'rel_${aliasBase}_$i';
            final pivotAlias = segment.usesPivot
                ? 'pivot_${aliasBase}_$i'
                : null;
            final throughAlias = segment.usesThrough
                ? 'through_${aliasBase}_$i'
                : null;
            edges.add(
              RelationJoinEdge(
                segment: segment,
                parentAlias: parentAlias,
                alias: alias,
                pivotAlias: pivotAlias,
                throughAlias: throughAlias,
              ),
            );
            parentAlias = alias;
          }
          return RelationJoin(pathKey: entry.key, edges: edges);
        })
        .toList(growable: false);
    final relationJoinClauses = _relationJoinRequests.isEmpty
        ? const <JoinDefinition>[]
        : _buildRelationJoinClauses(relationJoinEntries);

    return QueryPlan(
      definition: definition,
      driverName: context.driver.metadata.name,
      tablePrefix: context.connectionTablePrefix,
      filters: _filters,
      orders: _orders,
      rawOrders: _rawOrders,
      customOrders: _customOrders,
      randomOrder: _randomOrder,
      randomSeed: _randomSeed,
      limit: _limit,
      offset: _offset,
      relations: _relations,
      indexHints: _indexHints,
      fullTextWheres: _fullTextWheres,
      jsonWheres: _jsonWheres,
      dateWheres: _dateWheres,
      predicate: _predicate,
      selects: _selects,
      rawSelects: _rawSelects,
      customSelects: _customSelects,
      projectionOrder: _projectionOrder,
      aggregates: _aggregates,
      groupBy: _groupBy,
      rawGroupBy: _rawGroupBy,
      customGroupBy: _customGroupBy,
      having: _having,
      relationAggregates: _relationAggregates,
      relationOrders: _relationOrders,
      relationJoins: relationJoinEntries,
      joins: [..._joins, ...relationJoinClauses],
      tableAlias: _tableAlias,
      lockClause: _lockClause,
      groupLimit: _groupLimit,
      distinct: _distinct,
      distinctOn: _distinctOn,
      unions: _unions,
      cacheTtl: _cacheTtl,
      disableCache: _disableCache,
    );
  }

  List<JoinDefinition> _buildRelationJoinClauses(List<RelationJoin> joins) {
    if (_relationJoinRequests.isEmpty) {
      return const <JoinDefinition>[];
    }
    final lookup = <String, RelationJoin>{
      for (final join in joins) join.pathKey: join,
    };
    final definitions = <JoinDefinition>[];
    _relationJoinRequests.forEach((path, request) {
      final relation = lookup[path];
      if (relation == null) {
        return;
      }
      definitions.addAll(
        _joinDefinitionsForRelation(relation, request.joinType),
      );
    });
    return definitions;
  }

  List<JoinDefinition> _joinDefinitionsForRelation(
    RelationJoin relation,
    JoinType joinType,
  ) {
    final definitions = <JoinDefinition>[];
    for (final edge in relation.edges) {
      final segment = edge.segment;
      if (segment.usesPivot) {
        final pivotAlias = edge.pivotAlias;
        if (pivotAlias == null) {
          continue;
        }
        final pivotConditions = <JoinCondition>[
          JoinCondition.column(
            left: '$pivotAlias.${segment.pivotParentKey!}',
            operator: '=',
            right: '${edge.parentAlias}.${segment.parentKey}',
          ),
        ];
        if (segment.usesMorph && segment.morphOnPivot) {
          pivotConditions.add(
            JoinCondition.value(
              left: '$pivotAlias.${segment.morphTypeColumn!}',
              operator: '=',
              value: segment.morphClass,
            ),
          );
        }
        definitions.add(
          JoinDefinition(
            type: joinType,
            target: JoinTarget.table(segment.pivotTable!),
            alias: pivotAlias,
            conditions: pivotConditions,
          ),
        );
        final childConditions = <JoinCondition>[
          JoinCondition.column(
            left: '${edge.alias}.${segment.childKey}',
            operator: '=',
            right: '$pivotAlias.${segment.pivotRelatedKey!}',
          ),
        ];
        if (segment.usesMorph && !segment.morphOnPivot) {
          childConditions.add(
            JoinCondition.value(
              left: '${edge.alias}.${segment.morphTypeColumn!}',
              operator: '=',
              value: segment.morphClass,
            ),
          );
        }
        definitions.add(
          JoinDefinition(
            type: joinType,
            target: JoinTarget.table(
              _qualifiedRelationTableName(segment.targetDefinition),
            ),
            alias: edge.alias,
            conditions: childConditions,
          ),
        );
        continue;
      }
      if (segment.usesThrough) {
        final throughAlias = edge.throughAlias;
        if (throughAlias == null ||
            segment.throughDefinition == null ||
            segment.throughParentKey == null ||
            segment.throughChildKey == null) {
          continue;
        }
        definitions.add(
          JoinDefinition(
            type: joinType,
            target: JoinTarget.table(
              _qualifiedRelationTableName(segment.throughDefinition!),
            ),
            alias: throughAlias,
            conditions: [
              JoinCondition.column(
                left: '$throughAlias.${segment.throughParentKey!}',
                operator: '=',
                right: '${edge.parentAlias}.${segment.parentKey}',
              ),
            ],
          ),
        );
        definitions.add(
          JoinDefinition(
            type: joinType,
            target: JoinTarget.table(
              _qualifiedRelationTableName(segment.targetDefinition),
            ),
            alias: edge.alias,
            conditions: [
              JoinCondition.column(
                left: '${edge.alias}.${segment.childKey}',
                operator: '=',
                right: '$throughAlias.${segment.throughChildKey!}',
              ),
            ],
          ),
        );
        continue;
      }

      final parentColumn = '${edge.parentAlias}.${segment.parentKey}';
      final childColumn = '${edge.alias}.${segment.childKey}';
      final comparison = segment.foreignKeyOnParent
          ? JoinCondition.column(
              left: parentColumn,
              operator: '=',
              right: childColumn,
            )
          : JoinCondition.column(
              left: childColumn,
              operator: '=',
              right: parentColumn,
            );
      final conditions = <JoinCondition>[comparison];
      if (segment.usesMorph) {
        conditions.add(
          JoinCondition.value(
            left: '${edge.alias}.${segment.morphTypeColumn!}',
            operator: '=',
            value: segment.morphClass,
          ),
        );
      }
      definitions.add(
        JoinDefinition(
          type: joinType,
          target: JoinTarget.table(
            _qualifiedRelationTableName(segment.targetDefinition),
          ),
          alias: edge.alias,
          conditions: conditions,
        ),
      );
    }
    return definitions;
  }

  String _qualifiedRelationTableName(ModelDefinition<OrmEntity> definition) {
    final schema = definition.schema;
    if (schema == null || schema.isEmpty) {
      return definition.tableName;
    }
    return '$schema.${definition.tableName}';
  }

  Query<T> _copyForAggregation() => _copyWith(
    limit: null,
    offset: null,
    orders: const <OrderClause>[],
    rawOrders: const <RawOrderExpression>[],
    customOrders: const <CustomOrderExpression>[],
    aggregates: const <AggregateExpression>[],
    selects: const <String>[],
    rawSelects: const <RawSelectExpression>[],
    customSelects: const <CustomSelectExpression>[],
    projectionOrder: const <ProjectionOrderEntry>[],
    relationAggregates: const <RelationAggregate>[],
    relationOrders: const <RelationOrder>[],
  );

  static int _aggregateAliasCounter = 0;

  String _aggregateAlias(String base) =>
      '__orm_${base}_${_aggregateAliasCounter++}';

  Future<int> _countTotalRows() async {
    const alias = '_aggregate_count';
    final countQuery = _copyForAggregation().withAggregate(
      AggregateFunction.count,
      '*',
      alias: alias,
    );
    final plan = countQuery._buildPlan();
    final rows = await context.runSelect(plan);
    if (rows.isEmpty) {
      return 0;
    }
    final value = rows.first[alias];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      return rows.length;
    }
    return 0;
  }

  String _resolveCursorColumn(String? column) {
    if (column != null && column.isNotEmpty) {
      return _ensureField(column).columnName;
    }
    final pk = definition.primaryKeyField?.columnName;
    if (pk == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return pk;
  }

  FieldDefinition? get _softDeleteField => definition.softDeleteField;

  FieldDefinition _requireSoftDeleteSupport(String method) {
    final field = _softDeleteField;
    if (field == null) {
      throw StateError(
        '$method requires ${definition.modelName} to enable soft deletes.',
      );
    }
    return field;
  }

  UpdatePayload _normalizeUpdateValues(Map<String, Object?> input) {
    final mapped = <String, Object?>{};
    final jsonUpdates = <JsonUpdateClause>[];
    input.forEach((key, value) {
      final selector = json_path.parseJsonSelectorExpression(key);
      if (selector != null) {
        final field = _ensureField(selector.column);
        jsonUpdates.add(
          JsonUpdateClause(
            column: field.columnName,
            path: selector.path,
            value: value,
          ),
        );
        return;
      }
      final field = _ensureField(key);
      final encoded = context.codecRegistry.encodeField(field, value);
      mapped[field.columnName] = encoded;
    });
    return UpdatePayload(mapped, jsonUpdates);
  }

  List<String> _normalizeInsertColumns(Iterable<String> columns) {
    final normalized = <String>[];
    for (final column in columns) {
      final field = _ensureField(column);
      normalized.add(field.columnName);
    }
    return normalized;
  }

  void _ensureSharedContext(Query<dynamic> source, String method) {
    if (!identical(source.context, context)) {
      throw StateError(
        '$method requires the source query to share the same QueryContext.',
      );
    }
  }

  Query<T> applySoftDeleteFilter(FieldDefinition field) {
    final predicate = FieldPredicate(
      field: field.columnName,
      operator: PredicateOperator.isNull,
    );
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    return updated._withFilter(
      FilterClause(
        field: field.columnName,
        operator: FilterOperator.equals,
        value: null,
        compile: false,
      ),
    );
  }

  bool get _supportsQueryDeletes =>
      context.driver.metadata.supportsQueryDeletes;

  Future<int> _applyIncrement(String column, num amount, String feature) async {
    if (amount == 0) {
      return 0;
    }
    final metadata = context.driver.metadata;
    _ensureSupportsCapability(
      DriverCapability.increment,
      metadata.name,
      feature,
    );
    final field = _ensureField(column).columnName;
    final mutation = _buildQueryUpdateMutation(
      queryIncrementValues: {field: amount},
      feature: feature,
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  MutationPlan _buildQueryUpdateMutation({
    Map<String, Object?> values = const {},
    List<JsonUpdateClause> jsonUpdates = const [],
    Map<String, num> queryIncrementValues = const {},
    String feature = 'update',
    bool returning = false,
  }) {
    final pkField = definition.primaryKeyField;
    final metadata = context.driver.metadata;
    final fallbackIdentifier = metadata.queryUpdateRowIdentifier?.column;
    final requiresPk = metadata.requiresPrimaryKeyForQueryUpdate;
    final identifier = pkField?.columnName ?? fallbackIdentifier;
    if (identifier == null && requiresPk) {
      throw StateError(
        '$feature requires ${definition.modelName} to declare a primary key.',
      );
    }
    final plan = _buildPlan();
    final primarySelect = _buildPrimarySelectionPlan(plan, pkField);
    return MutationPlan.queryUpdate(
      definition: definition,
      plan: primarySelect,
      values: values,
      jsonUpdates: jsonUpdates,
      driverName: metadata.name,
      primaryKey: identifier,
      queryIncrementValues: queryIncrementValues,
      returning: returning,
    );
  }

  QueryPlan _buildPrimarySelectionPlan(
    QueryPlan plan,
    FieldDefinition? pkField,
  ) {
    if (pkField != null) {
      return plan.copyWith(
        selects: [pkField.columnName],
        rawSelects: const [],
        customSelects: const [],
        aggregates: const [],
        projectionOrder: const [ProjectionOrderEntry.column(0)],
      );
    }
    return plan.copyWith(
      selects: const <String>[],
      rawSelects: const <RawSelectExpression>[],
      customSelects: const <CustomSelectExpression>[],
      aggregates: const [],
      projectionOrder: const <ProjectionOrderEntry>[],
    );
  }

  bool get globalScopesApplied => _globalScopesApplied;

  bool get ignoreAllGlobalScopes => _ignoreAllGlobalScopes;

  Set<String> get ignoredGlobalScopes => _ignoredGlobalScopes;

  List<String> get adHocScopes => _adHocScopes;

  /// Whether model events are suppressed for this query.
  bool get suppressEvents => _suppressEvents;

  /// Returns a query that suppresses all model lifecycle events.
  ///
  /// Use this for bulk operations where you don't want to trigger
  /// creating/created, saving/saved, updating/updated, or deleting/deleted
  /// events.
  ///
  /// Example:
  /// ```dart
  /// // Insert without triggering events
  /// await User.query().withoutEvents().insertInput(user);
  ///
  /// // Bulk update without events
  /// await User.query().where('status', 'inactive').withoutEvents().update({'archived': true});
  /// ```
  Query<T> withoutEvents() => _copyWith(suppressEvents: true);

  Query<T> _copyWith({
    List<FilterClause>? filters,
    List<OrderClause>? orders,
    List<RawOrderExpression>? rawOrders,
    List<CustomOrderExpression>? customOrders,
    List<RelationLoad>? relations,
    List<JoinDefinition>? joins,
    List<IndexHint>? indexHints,
    List<FullTextWhere>? fullTextWheres,
    List<JsonWhereClause>? jsonWheres,
    List<DateWhereClause>? dateWheres,
    bool? randomOrder,
    Object? randomSeed = _unset,
    String? lockClause,
    int? limit,
    int? offset,
    QueryPredicate? predicate,
    List<String>? selects,
    List<RawSelectExpression>? rawSelects,
    List<CustomSelectExpression>? customSelects,
    List<ProjectionOrderEntry>? projectionOrder,
    List<AggregateExpression>? aggregates,
    List<String>? groupBy,
    List<RawGroupByExpression>? rawGroupBy,
    List<CustomGroupByExpression>? customGroupBy,
    QueryPredicate? having,
    List<RelationAggregate>? relationAggregates,
    List<RelationOrder>? relationOrders,
    Map<String, RelationPath>? relationPaths,
    Map<String, RelationJoinRequest>? relationJoinRequests,
    Set<String>? ignoredScopes,
    bool? globalScopesApplied,
    bool? ignoreAllGlobalScopes,
    String? tableAlias,
    List<String>? adHocScopes,
    GroupLimit? groupLimit,
    bool? distinct,
    List<DistinctOnClause>? distinctOn,
    List<QueryUnion>? unions,
    Duration? cacheTtl,
    bool? disableCache,
    bool? suppressEvents,
  }) => Query(
    definition: definition,
    context: context,
    filters: filters ?? _filters,
    orders: orders ?? _orders,
    rawOrders: rawOrders ?? _rawOrders,
    customOrders: customOrders ?? _customOrders,
    relations: relations ?? _relations,
    joins: joins ?? _joins,
    indexHints: indexHints ?? _indexHints,
    fullTextWheres: fullTextWheres ?? _fullTextWheres,
    jsonWheres: jsonWheres ?? _jsonWheres,
    dateWheres: dateWheres ?? _dateWheres,
    randomOrder: randomOrder ?? _randomOrder,
    randomSeed: identical(randomSeed, _unset)
        ? _randomSeed
        : randomSeed as num?,
    lockClause: lockClause ?? _lockClause,
    limit: limit ?? _limit,
    offset: offset ?? _offset,
    predicate: predicate ?? _predicate,
    selects: selects ?? _selects,
    rawSelects: rawSelects ?? _rawSelects,
    customSelects: customSelects ?? _customSelects,
    projectionOrder: projectionOrder ?? _projectionOrder,
    aggregates: aggregates ?? _aggregates,
    groupBy: groupBy ?? _groupBy,
    rawGroupBy: rawGroupBy ?? _rawGroupBy,
    customGroupBy: customGroupBy ?? _customGroupBy,
    having: having ?? _having,
    relationAggregates: relationAggregates ?? _relationAggregates,
    relationOrders: relationOrders ?? _relationOrders,
    relationPaths: relationPaths ?? _relationPaths,
    relationJoinRequests: relationJoinRequests ?? _relationJoinRequests,
    ignoredScopes: ignoredScopes ?? _ignoredGlobalScopes,
    globalScopesApplied: globalScopesApplied ?? _globalScopesApplied,
    ignoreAllGlobalScopes: ignoreAllGlobalScopes ?? _ignoreAllGlobalScopes,
    tableAlias: tableAlias ?? _tableAlias,
    adHocScopes: adHocScopes ?? _adHocScopes,
    groupLimit: groupLimit ?? _groupLimit,
    distinct: distinct ?? _distinct,
    distinctOn: distinctOn ?? _distinctOn,
    unions: unions ?? _unions,
    cacheTtl: cacheTtl ?? _cacheTtl,
    disableCache: disableCache ?? _disableCache,
    suppressEvents: suppressEvents ?? _suppressEvents,
  );

  Query<T> _join({
    required JoinTarget target,
    required JoinType type,
    Object? constraint,
    Object? operator,
    Object? second,
    bool whereComparison = false,
    bool lateral = false,
    String? alias,
  }) {
    _ensureSupportsCapability(
      DriverCapability.joins,
      '${context.driver.metadata.name} driver',
      'join operations',
    );
    var conditions = <JoinCondition>[];
    if (constraint != null) {
      conditions = _buildJoinConditions(
        constraint,
        operator,
        second,
        whereComparison: whereComparison,
      );
    }
    if (conditions.isEmpty && lateral) {
      conditions = const [JoinCondition.raw(rawSql: 'TRUE')];
    }
    if (conditions.isEmpty && type != JoinType.cross && !lateral) {
      throw ArgumentError(
        'Join clauses require a constraint unless using cross joins.',
      );
    }
    return _copyWith(
      joins: [
        ..._joins,
        JoinDefinition(
          type: type,
          target: target,
          alias: alias,
          conditions: conditions,
          isLateral: lateral,
        ),
      ],
    );
  }

  void _ensureSupportsCapability(
    DriverCapability capability,
    String driverName,
    String feature,
  ) {
    final metadata = context.driver.metadata;
    if (!metadata.supportsCapability(capability)) {
      throw UnsupportedError(
        '$driverName does not support $feature (${capability.name}).',
      );
    }
  }

  Query<T> _addIndexHint(IndexHint hint) =>
      _copyWith(indexHints: [..._indexHints, hint]);

  Query<T> _addUnion(Query<dynamic> query, {required bool all}) {
    _ensureSharedContext(query, 'union');
    final clause = QueryUnion(plan: query._buildPlan(), all: all);
    return _copyWith(unions: [..._unions, clause]);
  }

  List<JoinCondition> _buildJoinConditions(
    Object constraint,
    Object? operator,
    Object? second, {
    required bool whereComparison,
  }) {
    if (constraint is JoinConstraintBuilder) {
      final builder = JoinBuilder._();
      constraint(builder);
      final built = builder._conditions;
      if (built.isEmpty) {
        throw ArgumentError('Join callbacks must add at least one clause.');
      }
      return List<JoinCondition>.unmodifiable(built);
    }
    if (constraint is! String) {
      throw ArgumentError.value(
        constraint,
        'constraint',
        'Expected a column name or callback.',
      );
    }
    if (operator == null || second == null) {
      throw ArgumentError(
        'Join clauses require both an operator and comparison target.',
      );
    }
    final op = _normalizeJoinOperatorToken(operator);
    if (whereComparison) {
      return [
        JoinCondition.value(left: constraint, operator: op, value: second),
      ];
    }
    if (second is! String) {
      throw ArgumentError.value(
        second,
        'second',
        'Column joins require another column reference.',
      );
    }
    return [
      JoinCondition.column(left: constraint, operator: op, right: second),
    ];
  }

  JoinTarget _resolveJoinTarget(Object table) {
    if (table is JoinTarget) {
      return table;
    }
    if (table is String) {
      return JoinTarget.table(table);
    }
    throw ArgumentError.value(table, 'table', 'Unsupported join target.');
  }

  void _assertSubqueryAlias(String alias) {
    if (alias.isEmpty) {
      throw ArgumentError.value(alias, 'alias', 'Alias cannot be empty.');
    }
  }

  JoinTarget _subqueryTarget(Query<dynamic> query) {
    final baseDriver = context.driver.metadata.name;
    final otherDriver = query.context.driver.metadata.name;
    if (baseDriver != otherDriver) {
      throw ArgumentError(
        'Subquery joins require both builders to share the same driver. '
        'Expected $baseDriver but received $otherDriver.',
      );
    }
    final plan = query._buildPlan();
    final preview = query.context.describeQuery(plan);
    if (preview.sql == '<unavailable>' || preview.sql.isEmpty) {
      throw StateError('Unable to produce SQL for the provided subquery.');
    }
    return JoinTarget.subquery(preview.sql, bindings: preview.parameters);
  }

  FilterClause _buildFieldFilter(
    String field,
    FilterOperator op,
    Object? value,
  ) {
    final definition = _ensureField(field);
    return FilterClause(
      field: definition.columnName,
      operator: op,
      value: value,
      compile: false,
    );
  }

  ResolvedField _resolvePredicateField(String field) {
    if (json_path.hasJsonSelector(field)) {
      final selector = json_path.parseJsonSelectorExpression(field);
      if (selector == null) {
        throw ArgumentError.value(field, 'field', 'Invalid JSON selector.');
      }
      final definition = _ensureField(selector.column);
      final column = definition.columnName;
      final normalized = json_path.JsonSelector(
        column,
        selector.path,
        selector.extractsText,
      );
      return ResolvedField(column: column, jsonSelector: normalized);
    }
    final column = _ensureField(field).columnName;
    return ResolvedField(column: column);
  }

  bool _shouldTreatAsJsonBoolean(
    json_path.JsonSelector? selector,
    PredicateOperator operator,
    Object? value,
  ) {
    if (selector == null || selector.extractsText || value is! bool) {
      return false;
    }
    return operator == PredicateOperator.equals ||
        operator == PredicateOperator.notEquals;
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

    // Allow qualified names (e.g. "table.column") if we have joins or if it's referring to the current table.
    // This is common in many-to-many relations and manual joins.
    if (name.contains('.')) {
      final parts = name.split('.');
      if (parts.length == 2) {
        final tableName = parts[0];
        final columnName = parts[1];

        // If it's our own table, check if the column exists
        if (tableName == definition.tableName) {
          final f = definition.fields.firstWhereOrNull(
            (f) => f.columnName == columnName || f.name == columnName,
          );
          if (f != null) return f;
        }

        // Otherwise, assume it's a joined table column or a valid qualified name
        return FieldDefinition(
          name: name,
          columnName: name,
          dartType: 'Object?',
          resolvedType: 'Object?',
          isPrimaryKey: false,
          isNullable: true,
        );
      }
    }

    // Allow arbitrary columns for TableQueryDefinition (table() queries)
    if (definition is TableQueryDefinition) {
      return FieldDefinition(
        name: name,
        columnName: name,
        dartType: 'Object?',
        resolvedType: 'Object?',
        isPrimaryKey: false,
        isNullable: true,
      );
    }
    throw ArgumentError.value(
      name,
      'field',
      'Unknown field on ${definition.modelName}.',
    );
  }

  JsonPathReference _resolveJsonReference(
    String input, {
    String? overridePath,
  }) {
    final trimmedOverride = overridePath?.trim();
    if (trimmedOverride != null && trimmedOverride.isNotEmpty) {
      final base = _baseJsonField(input);
      final column = _ensureField(base).columnName;
      final normalized = json_path.normalizeJsonPath(trimmedOverride);
      return JsonPathReference(column: column, path: normalized);
    }
    final selector = json_path.parseJsonSelectorExpression(input);
    if (selector != null) {
      final column = _ensureField(selector.column).columnName;
      return JsonPathReference(column: column, path: selector.path);
    }
    final base = _baseJsonField(input);
    final column = _ensureField(base).columnName;
    return JsonPathReference(column: column, path: r'$');
  }

  String _baseJsonField(String input) {
    final index = input.indexOf('->');
    if (index == -1) {
      return input;
    }
    return input.substring(0, index);
  }

  String _normalizeLengthOperator(String operator) =>
      _normalizeComparisonOperator(operator, context: 'JSON length comparison');

  String _normalizeComparisonOperator(String operator, {String? context}) {
    final normalized = operator.trim();
    const allowed = {'=', '!=', '<>', '>', '>=', '<', '<='};
    if (!allowed.contains(normalized)) {
      final label = context ?? 'comparison';
      throw ArgumentError.value(
        operator,
        'operator',
        'Unsupported $label operator. Allowed: ${allowed.join(', ')}.',
      );
    }
    return normalized;
  }

  Query<T> _appendDatePredicate(
    String field,
    DateComponent component,
    Object operatorOrValue, [
    Object? comparisonValue,
  ]) {
    final parsed = _normalizeDatePredicateInput(
      operatorOrValue,
      comparisonValue,
    );
    final normalizedValue = _normalizeDatePredicateValue(
      component,
      parsed.value,
    );
    final reference = _resolveJsonReference(field);
    final clause = DateWhereClause(
      column: reference.column,
      path: reference.path,
      component: component,
      operator: parsed.operator,
      value: normalizedValue,
    );
    return _copyWith(dateWheres: [..._dateWheres, clause]);
  }

  DatePredicateInput _normalizeDatePredicateInput(
    Object operatorOrValue,
    Object? comparisonValue,
  ) {
    if (comparisonValue == null) {
      return DatePredicateInput(operator: '=', value: operatorOrValue);
    }
    if (operatorOrValue is! String) {
      throw ArgumentError(
        'Date predicates that specify two arguments must provide a string operator as the first argument.',
      );
    }
    final operator = _normalizeComparisonOperator(
      operatorOrValue,
      context: 'date predicate',
    );
    return DatePredicateInput(operator: operator, value: comparisonValue);
  }

  Object _normalizeDatePredicateValue(DateComponent component, Object value) {
    if (value is DateTime) {
      switch (component) {
        case DateComponent.date:
          return _formatDate(value);
        case DateComponent.time:
          return _formatTime(value);
        case DateComponent.day:
          return value.day;
        case DateComponent.month:
          return value.month;
        case DateComponent.year:
          return value.year;
      }
    }
    switch (component) {
      case DateComponent.date:
        return _coerceDateString(value);
      case DateComponent.time:
        return _coerceTimeString(value);
      case DateComponent.day:
        return _coerceIntComponent(value, 'day', min: 1, max: 31);
      case DateComponent.month:
        return _coerceIntComponent(value, 'month', min: 1, max: 12);
      case DateComponent.year:
        return _coerceIntComponent(value, 'year');
    }
  }

  String _coerceDateString(Object value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw ArgumentError.value(
      value,
      'value',
      'Expected a DateTime or ISO 8601 date string.',
    );
  }

  String _coerceTimeString(Object value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw ArgumentError.value(
      value,
      'value',
      'Expected a DateTime or HH:mm:ss string.',
    );
  }

  int _coerceIntComponent(
    Object value,
    String component, {
    int? min,
    int? max,
  }) {
    final int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num && value % 1 == 0) {
      parsed = value.toInt();
    } else if (value is String) {
      parsed = int.tryParse(value.trim());
    } else {
      parsed = null;
    }
    if (parsed == null) {
      throw ArgumentError.value(
        value,
        'value',
        '$component component must be numeric.',
      );
    }
    if (min != null && parsed < min) {
      throw ArgumentError.value(
        parsed,
        'value',
        '$component component must be >= $min.',
      );
    }
    if (max != null && parsed > max) {
      throw ArgumentError.value(
        parsed,
        'value',
        '$component component must be <= $max.',
      );
    }
    return parsed;
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';

  Query<T> _appendSimpleCondition(
    String field,
    FilterOperator operator,
    Object? value,
  ) {
    final resolved = _resolvePredicateField(field);
    final predicate = _buildFieldPredicateFromFilter(resolved, operator, value);
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    if (resolved.jsonSelector != null) {
      return updated;
    }
    return updated._withFilter(_buildFieldFilter(field, operator, value));
  }

  FieldPredicate _buildFieldPredicateFromFilter(
    ResolvedField resolved,
    FilterOperator filter,
    Object? value,
  ) {
    final operator = _mapFilterToPredicate(filter);
    final jsonBooleanComparison = _shouldTreatAsJsonBoolean(
      resolved.jsonSelector,
      operator,
      value,
    );
    final normalizedValue = jsonBooleanComparison && value is bool
        ? jsonEncode(value)
        : value;
    return _buildFieldPredicate(
      resolved.column,
      operator,
      normalizedValue,
      jsonSelector: resolved.jsonSelector,
      jsonBooleanComparison: jsonBooleanComparison,
    );
  }

  PredicateOperator _mapFilterToPredicate(FilterOperator operator) {
    switch (operator) {
      case FilterOperator.equals:
        return PredicateOperator.equals;
      case FilterOperator.greaterThan:
        return PredicateOperator.greaterThan;
      case FilterOperator.greaterThanOrEqual:
        return PredicateOperator.greaterThanOrEqual;
      case FilterOperator.lessThan:
        return PredicateOperator.lessThan;
      case FilterOperator.lessThanOrEqual:
        return PredicateOperator.lessThanOrEqual;
      case FilterOperator.contains:
        return PredicateOperator.like;
      case FilterOperator.inValues:
        return PredicateOperator.inValues;
      case FilterOperator.isNull:
        return PredicateOperator.isNull;
      case FilterOperator.isNotNull:
        return PredicateOperator.isNotNull;
    }
  }

  FilterOperator _mapPredicateToFilter(PredicateOperator operator) {
    switch (operator) {
      case PredicateOperator.equals:
        return FilterOperator.equals;
      case PredicateOperator.inValues:
        return FilterOperator.inValues;
      case PredicateOperator.greaterThan:
        return FilterOperator.greaterThan;
      case PredicateOperator.greaterThanOrEqual:
        return FilterOperator.greaterThanOrEqual;
      case PredicateOperator.lessThan:
        return FilterOperator.lessThan;
      case PredicateOperator.lessThanOrEqual:
        return FilterOperator.lessThanOrEqual;
      case PredicateOperator.isNull:
        return FilterOperator.isNull;
      case PredicateOperator.isNotNull:
        return FilterOperator.isNotNull;
      default:
        return FilterOperator.equals;
    }
  }

  bool _mirrorsFilter(PredicateOperator operator) {
    switch (operator) {
      case PredicateOperator.equals:
      case PredicateOperator.inValues:
      case PredicateOperator.greaterThan:
      case PredicateOperator.greaterThanOrEqual:
      case PredicateOperator.lessThan:
      case PredicateOperator.lessThanOrEqual:
      case PredicateOperator.isNull:
      case PredicateOperator.isNotNull:
        return true;
      default:
        return false;
    }
  }

  BitwisePredicate _buildBitwisePredicate(
    String field,
    String operator,
    Object value,
  ) {
    final column = _ensureField(field).columnName;
    final normalizedOperator = _normalizeBitwiseOperator(operator);
    return BitwisePredicate(
      field: column,
      operator: normalizedOperator,
      value: value,
    );
  }

  FieldPredicate _buildFieldPredicate(
    String column,
    PredicateOperator operator,
    Object? value, {
    json_path.JsonSelector? jsonSelector,
    bool jsonBooleanComparison = false,
  }) {
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
        jsonSelector: jsonSelector,
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
        jsonSelector: jsonSelector,
      );
    }
    return FieldPredicate(
      field: column,
      operator: operator,
      value: value,
      jsonSelector: jsonSelector,
      jsonBooleanComparison: jsonBooleanComparison,
    );
  }

  RelationAggregate _buildRelationAggregate(
    String relation,
    RelationAggregateType type,
    String? alias,
    PredicateCallback<OrmEntity>? constraint, {
    bool distinct = false,
    String? column,
  }) {
    final path = _resolveRelationPath(relation, allowMorphTo: false);
    final where = _buildRelationPredicateConstraint(path, constraint);
    final sanitized = relation.replaceAll('.', '_');
    final resolvedAlias =
        alias ??
        '${sanitized}_${type == RelationAggregateType.count ? 'count' : 'exists'}';
    return RelationAggregate(
      type: type,
      alias: resolvedAlias,
      path: path,
      where: where,
      distinct: distinct,
      column: column,
    );
  }

  RelationPath _resolveRelationPath(
    String relation, {
    bool allowMorphTo = true,
  }) {
    final path = _resolver.resolvePath(definition, relation);
    if (!allowMorphTo) {
      final morphSegment = path.segments.firstWhereOrNull(
        (segment) => segment.relation.kind == RelationKind.morphTo,
      );
      if (morphSegment != null) {
        throw StateError(
          'Relation $relation cannot be used with morphTo segments (${morphSegment.name}).',
        );
      }
    }
    _relationPaths.putIfAbsent(relation, () => path);
    return path;
  }

  QueryPredicate? _buildRelationPredicateConstraint(
    RelationPath path,
    PredicateCallback<OrmEntity>? constraint,
  ) {
    return _resolver.predicateForPath(path, constraint);
  }

  QueryPredicate? _buildRelationPredicateConstraintTyped<
    TRelated extends OrmEntity
  >(RelationPath path, PredicateCallback<TRelated>? constraint) {
    return _resolver.predicateForPathTyped(path, constraint);
  }

  QueryPredicate? _buildRelationLoadPredicate(
    RelationDefinition relation,
    PredicateCallback<OrmEntity>? constraint,
  ) {
    return _resolver.predicateFor(relation, constraint);
  }

  QueryPredicate? _buildRelationLoadPredicateTyped<TRelated extends OrmEntity>(
    RelationDefinition relation,
    PredicateCallback<TRelated>? constraint,
  ) {
    return _resolver.predicateForTyped(relation, constraint);
  }

  String _resolveHavingField(String field) {
    final aggregate = _aggregates.firstWhereOrNull(
      (agg) => agg.alias != null && agg.alias == field,
    );
    if (aggregate != null) {
      return field;
    }
    return _ensureField(field).columnName;
  }

  Query<T> _appendPredicate(
    QueryPredicate predicate,
    PredicateLogicalOperator logical,
  ) {
    final combined = _combinePredicates(_predicate, predicate, logical);
    return _copyWith(predicate: combined);
  }

  Query<T> _appendHavingPredicate(
    QueryPredicate predicate,
    PredicateLogicalOperator logical,
  ) {
    final combined = _combinePredicates(_having, predicate, logical);
    return _copyWith(having: combined);
  }

  QueryPredicate _combinePredicates(
    QueryPredicate? existing,
    QueryPredicate addition,
    PredicateLogicalOperator logical,
  ) {
    if (existing == null) {
      return addition;
    }

    if (logical == PredicateLogicalOperator.and) {
      return _mergeGroups(existing, addition, PredicateLogicalOperator.and);
    } else {
      return _mergeGroups(existing, addition, PredicateLogicalOperator.or);
    }
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

  Query<T> _withFilter(FilterClause clause) =>
      _copyWith(filters: [..._filters, clause]);
}
