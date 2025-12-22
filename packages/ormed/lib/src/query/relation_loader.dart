import 'package:ormed/src/model/model.dart';

import '../annotations.dart';
import '../contracts.dart';
import '../value_codec.dart';
import 'query.dart';

/// Hydrates eager-loaded relations after the base query executes.
class RelationLoader {
  /// Creates a new [RelationLoader].
  RelationLoader(this.context);

  /// The query context.
  final QueryContext context;

  ModelRegistry get _registry => context.registry;

  ValueCodecRegistry get _codecRegistry => context.codecRegistry;

  String get _driverName => context.driver.metadata.name;
  String? get _tablePrefix => context.connectionTablePrefix;

  /// Populates [parents] with the relations declared in [relations].
  ///
  /// This method is called by the query builder after the base query has
  /// executed. It iterates over the requested relations and loads them
  /// into the parent models.
  ///
  /// Example:
  /// ```dart
  /// final userRows = await query.get();
  /// await relationLoader.attach(userDefinition, userRows, [
  ///   RelationLoad(relation: postsRelation),
  /// ]);
  /// final user = userRows.first.model;
  /// final posts = userRows.first.relationList<Post>('posts');
  /// ```
  Future<void> attach<T extends OrmEntity>(
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    List<RelationLoad> relations, {
    Map<String, RelationJoin> joinMap = const {},
  }) async {
    for (final load in relations) {
      final segment = _segmentForRelation(parentDefinition, load, joinMap);
      switch (load.relation.kind) {
        case RelationKind.hasOne:
        case RelationKind.hasMany:
          await _loadHasMany(parentDefinition, parents, load, segment);
          break;
        case RelationKind.morphOne:
          await _loadMorphMany(
            parentDefinition,
            parents,
            load,
            segment: segment,
            singleResult: true,
          );
          break;
        case RelationKind.morphMany:
          await _loadMorphMany(
            parentDefinition,
            parents,
            load,
            segment: segment,
            singleResult: false,
          );
          break;
        case RelationKind.belongsTo:
          await _loadBelongsTo(parentDefinition, parents, load, segment);
          break;
        case RelationKind.manyToMany:
          await _loadManyToMany(parentDefinition, parents, load, segment);
          break;
      }
      // Sync relations to model cache
      _syncRelationsToModels(parents, load.relation.name);

      // Load nested relations
      if (load.nested.isNotEmpty) {
        final targetDefinition = segment.targetDefinition;
        final children = <QueryRow<OrmEntity>>[];

        for (final parent in parents) {
          final value = parent.relations[load.relation.name];
          if (value == null) continue;

          if (value is List) {
            for (final item in value) {
              children.add(
                QueryRow(
                  model: item as OrmEntity,
                  row: targetDefinition.toMap(item, registry: _codecRegistry),
                ),
              );
            }
          } else {
            children.add(
              QueryRow(
                model: value as OrmEntity,
                row: targetDefinition.toMap(value, registry: _codecRegistry),
              ),
            );
          }
        }

        if (children.isNotEmpty) {
          await attach(targetDefinition, children, load.nested);
        }
      }
    }
  }

  /// Syncs a loaded relation from QueryRow to the model's relation cache.
  void _syncRelationsToModels<T extends OrmEntity>(
    List<QueryRow<T>> rows,
    String relationName,
  ) {
    for (final row in rows) {
      if (row.model is ModelRelations) {
        final model = row.model as ModelRelations;
        final relationValue = row.relations[relationName];
        model.setRelation(relationName, relationValue);
      }
    }
  }

  /// Loads a `has-one` or `has-many` relation.
  Future<void> _loadHasMany<T extends OrmEntity>(
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    RelationLoad load,
    RelationSegment segment,
  ) async {
    final relation = load.relation;
    final singleResult = segment.expectSingleResult;
    final parentKey = segment.parentKey;
    final targetDefinition = segment.targetDefinition;
    final foreignKey = segment.childKey;

    final parentKeyValues = parents
        .map((row) => row.row[parentKey])
        .where((value) => value != null)
        .toSet();
    if (parentKeyValues.isEmpty) {
      for (final row in parents) {
        row.relations[relation.name] = singleResult ? null : const <dynamic>[];
      }
      return;
    }

    final childPlan = QueryPlan(
      definition: targetDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: [
        FilterClause(
          field: foreignKey,
          operator: FilterOperator.inValues,
          value: parentKeyValues.toList(),
        ),
      ],
      predicate: load.predicate,
    );
    final childRows = await context.driver.execute(childPlan);
    final grouped = <Object?, List<dynamic>>{};
    for (final childRow in childRows) {
      final model = targetDefinition.fromMap(
        childRow,
        registry: _codecRegistry,
      );
      context.attachRuntimeMetadata(model);
      final key = childRow[foreignKey];
      if (key == null) continue;
      grouped.putIfAbsent(key, () => <dynamic>[]).add(model);
    }

    for (final row in parents) {
      final key = row.row[parentKey];
      final models = grouped[key] ?? const <dynamic>[];
      if (singleResult) {
        row.relations[relation.name] = models.isEmpty ? null : models.first;
      } else {
        row.relations[relation.name] = List.unmodifiable(models);
      }
    }
  }

  /// Loads a `belongs-to` relation.
  Future<void> _loadBelongsTo<T extends OrmEntity>(
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    RelationLoad load,
    RelationSegment segment,
  ) async {
    final relation = load.relation;
    final localForeignKey = segment.parentKey;
    final targetDefinition = segment.targetDefinition;
    final ownerKey = segment.childKey;

    final fkValues = parents
        .map((row) => row.row[localForeignKey])
        .where((value) => value != null)
        .toSet();
    if (fkValues.isEmpty) {
      for (final row in parents) {
        row.relations[relation.name] = null;
      }
      return;
    }

    final targetPlan = QueryPlan(
      definition: targetDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: [
        FilterClause(
          field: ownerKey,
          operator: FilterOperator.inValues,
          value: fkValues.toList(),
        ),
      ],
      predicate: load.predicate,
    );
    final targetRows = await context.driver.execute(targetPlan);
    final lookup = <Object?, dynamic>{};
    for (final row in targetRows) {
      final model = targetDefinition.fromMap(row, registry: _codecRegistry);
      context.attachRuntimeMetadata(model);
      lookup[row[ownerKey]] = model;
    }

    for (final row in parents) {
      final fk = row.row[localForeignKey];
      row.relations[relation.name] = lookup[fk];
    }
  }

  /// Loads a `many-to-many` relation.
  Future<void> _loadManyToMany<T extends OrmEntity>(
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    RelationLoad load,
    RelationSegment segment,
  ) async {
    final relation = load.relation;
    final parentKey = segment.parentKey;
    final targetDefinition = segment.targetDefinition;
    final pivotTable = segment.pivotTable;
    final pivotParentColumn = segment.pivotParentKey;
    final pivotTargetColumn = segment.pivotRelatedKey;
    if (pivotTable == null ||
        pivotParentColumn == null ||
        pivotTargetColumn == null) {
      throw StateError('Relation ${relation.name} requires pivot metadata.');
    }

    final parentIds = parents
        .map((row) => row.row[parentKey])
        .where((value) => value != null)
        .toSet();
    if (parentIds.isEmpty) {
      for (final row in parents) {
        row.relations[relation.name] = const <dynamic>[];
      }
      return;
    }

    final pivotDefinition = _pivotDefinition(
      pivotTable,
      pivotParentColumn,
      pivotTargetColumn,
    );
    final pivotPlan = QueryPlan(
      definition: pivotDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: [
        FilterClause(
          field: pivotParentColumn,
          operator: FilterOperator.inValues,
          value: parentIds.toList(),
        ),
      ],
    );
    final pivotRows = await context.driver.execute(pivotPlan);
    final parentToTargets = <Object?, List<Object?>>{};
    final targetIds = <Object?>{};
    for (final row in pivotRows) {
      final parentId = row[pivotParentColumn];
      final targetId = row[pivotTargetColumn];
      if (parentId == null || targetId == null) {
        continue;
      }
      parentToTargets.putIfAbsent(parentId, () => <Object?>[]).add(targetId);
      targetIds.add(targetId);
    }

    if (targetIds.isEmpty) {
      for (final row in parents) {
        row.relations[relation.name] = const <dynamic>[];
      }
      return;
    }

    final targetKey = segment.childKey;

    final targetPlan = QueryPlan(
      definition: targetDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: [
        FilterClause(
          field: targetKey,
          operator: FilterOperator.inValues,
          value: targetIds.toList(),
        ),
      ],
      predicate: load.predicate,
    );
    final targetRows = await context.driver.execute(targetPlan);
    final lookup = <Object?, dynamic>{};
    for (final row in targetRows) {
      final model = targetDefinition.fromMap(row, registry: _codecRegistry);
      context.attachRuntimeMetadata(model);
      lookup[row[targetKey]] = model;
    }

    for (final row in parents) {
      final key = row.row[parentKey];
      final ids = parentToTargets[key] ?? const [];
      final models = ids
          .map((id) => lookup[id])
          .where((model) => model != null)
          .toList(growable: false);
      row.relations[relation.name] = List.unmodifiable(models);
    }
  }

  /// Loads a `morph-one` or `morph-many` relation.
  Future<void> _loadMorphMany<T extends OrmEntity>(
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    RelationLoad load, {
    required RelationSegment segment,
    required bool singleResult,
  }) async {
    final relation = load.relation;
    final parentKey = segment.parentKey;
    final targetDefinition = segment.targetDefinition;
    final foreignKey = segment.childKey;
    final morphColumn = segment.morphTypeColumn;
    final morphClass = segment.morphClass;
    if (morphColumn == null || morphClass == null) {
      throw StateError('Relation ${relation.name} requires morph metadata.');
    }

    final parentKeyValues = parents
        .map((row) => row.row[parentKey])
        .where((value) => value != null)
        .toSet();
    if (parentKeyValues.isEmpty) {
      for (final row in parents) {
        row.relations[relation.name] = singleResult ? null : const <dynamic>[];
      }
      return;
    }

    final childPlan = QueryPlan(
      definition: targetDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: [
        FilterClause(
          field: foreignKey,
          operator: FilterOperator.inValues,
          value: parentKeyValues.toList(),
        ),
        FilterClause(
          field: morphColumn,
          operator: FilterOperator.equals,
          value: morphClass,
        ),
      ],
      predicate: load.predicate,
    );
    final childRows = await context.driver.execute(childPlan);
    final grouped = <Object?, List<dynamic>>{};
    for (final childRow in childRows) {
      final model = targetDefinition.fromMap(
        childRow,
        registry: _codecRegistry,
      );
      context.attachRuntimeMetadata(model);
      final key = childRow[foreignKey];
      if (key == null) continue;
      grouped.putIfAbsent(key, () => <dynamic>[]).add(model);
    }

    for (final row in parents) {
      final key = row.row[parentKey];
      final models = grouped[key] ?? const <dynamic>[];
      if (singleResult) {
        row.relations[relation.name] = models.isEmpty ? null : models.first;
      } else {
        row.relations[relation.name] = List.unmodifiable(models);
      }
    }
  }

  RelationSegment _segmentForRelation<T extends OrmEntity>(
    ModelDefinition<T> parentDefinition,
    RelationLoad load,
    Map<String, RelationJoin> joinMap,
  ) {
    final join = joinMap[load.relation.name];
    if (join != null) {
      return join.leaf.segment;
    }
    return _fallbackSegment(parentDefinition, load.relation);
  }

  RelationSegment _fallbackSegment<T extends OrmEntity>(
    ModelDefinition<T> parent,
    RelationDefinition relation,
  ) {
    final target = _registry.expectByName(relation.targetModel);
    final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;
    if (parentKey == null) {
      throw StateError('Relation ${relation.name} requires a parent key.');
    }
    final parentDef = parent as ModelDefinition<OrmEntity>;
    switch (relation.kind) {
      case RelationKind.hasOne:
      case RelationKind.hasMany:
        final childKey = relation.foreignKey ?? '${parent.tableName}_id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parentDef,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          expectSingleResult: relation.kind == RelationKind.hasOne,
        );
      case RelationKind.belongsTo:
        final foreignKey = relation.foreignKey ?? '${relation.name}_id';
        final ownerKey =
            relation.localKey ?? target.primaryKeyField?.columnName;
        if (ownerKey == null) {
          throw StateError('Relation ${relation.name} requires a target key.');
        }
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parentDef,
          targetDefinition: target,
          parentKey: foreignKey,
          childKey: ownerKey,
          foreignKeyOnParent: true,
          expectSingleResult: true,
        );
      case RelationKind.manyToMany:
        final pivotTable =
            relation.through ?? '${parent.tableName}_${target.tableName}';
        final pivotParentKey =
            relation.pivotForeignKey ?? '${parent.tableName}_id';
        final pivotRelatedKey =
            relation.pivotRelatedKey ?? '${target.tableName}_id';
        final targetKey =
            relation.localKey ?? target.primaryKeyField?.columnName;
        if (targetKey == null) {
          throw StateError('Relation ${relation.name} requires a target key.');
        }
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parentDef,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: targetKey,
          pivotTable: pivotTable,
          pivotParentKey: pivotParentKey,
          pivotRelatedKey: pivotRelatedKey,
        );
      case RelationKind.morphOne:
      case RelationKind.morphMany:
        final childKey =
            relation.foreignKey ??
            (throw StateError(
              'Relation ${relation.name} requires a foreign key.',
            ));
        final morphColumn =
            relation.morphType ??
            (throw StateError(
              'Relation ${relation.name} requires a morph type column.',
            ));
        final morphClass =
            relation.morphClass ??
            (throw StateError(
              'Relation ${relation.name} requires a morph class.',
            ));
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parentDef,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          morphTypeColumn: morphColumn,
          morphClass: morphClass,
          expectSingleResult: relation.kind == RelationKind.morphOne,
        );
    }
  }

  ModelDefinition<AdHocRow> _pivotDefinition(
    String table,
    String parentColumn,
    String targetColumn,
  ) => ModelDefinition<AdHocRow>(
    modelName: '_Pivot_$table',
    tableName: table,
    fields: [
      FieldDefinition(
        name: parentColumn,
        columnName: parentColumn,
        dartType: 'Object',
        resolvedType: 'Object?',
        isPrimaryKey: false,
        isNullable: false,
      ),
      FieldDefinition(
        name: targetColumn,
        columnName: targetColumn,
        dartType: 'Object',
        resolvedType: 'Object?',
        isPrimaryKey: false,
        isNullable: false,
      ),
    ],
    relations: const [],
    codec: const _PivotCodec(),
  );
}

class _PivotCodec extends ModelCodec<AdHocRow> {
  const _PivotCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}
