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
        case RelationKind.hasOneThrough:
        case RelationKind.hasManyThrough:
          await _loadThrough(parentDefinition, parents, load, segment);
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
        case RelationKind.morphTo:
          await _loadMorphTo(parentDefinition, parents, load, segment);
          break;
        case RelationKind.belongsTo:
          await _loadBelongsTo(parentDefinition, parents, load, segment);
          break;
        case RelationKind.manyToMany:
        case RelationKind.morphToMany:
        case RelationKind.morphedByMany:
          await _loadManyToMany(parentDefinition, parents, load, segment);
          break;
      }
      // Sync relations to model cache
      _syncRelationsToModels(parents, load.relation.name);

      // Load nested relations
      if (load.relation.kind == RelationKind.morphTo) {
        continue;
      }
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

  Future<void> _loadThrough<T extends OrmEntity>(
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
    final throughDefinition = segment.throughDefinition;
    final throughParentKey = segment.throughParentKey;
    final throughChildKey = segment.throughChildKey;

    if (throughDefinition == null ||
        throughParentKey == null ||
        throughChildKey == null) {
      throw StateError(
        'Relation ${relation.name} requires through relation metadata.',
      );
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

    final throughPlan = QueryPlan(
      definition: throughDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: [
        FilterClause(
          field: throughParentKey,
          operator: FilterOperator.inValues,
          value: parentKeyValues.toList(),
        ),
      ],
      selects: [throughParentKey, throughChildKey],
      disableAutoHydration: true,
    );

    final throughRows = await context.driver.execute(throughPlan);
    final parentToThroughKeys = <Object?, List<Object?>>{};
    final throughKeyToParents = <Object?, List<Object?>>{};

    for (final row in throughRows) {
      final parentId = row[throughParentKey];
      final throughKey = row[throughChildKey];
      if (parentId == null || throughKey == null) continue;
      parentToThroughKeys
          .putIfAbsent(parentId, () => <Object?>[])
          .add(throughKey);
      throughKeyToParents
          .putIfAbsent(throughKey, () => <Object?>[])
          .add(parentId);
    }

    if (throughKeyToParents.isEmpty) {
      for (final row in parents) {
        row.relations[relation.name] = singleResult ? null : const <dynamic>[];
      }
      return;
    }

    final targetPlan = QueryPlan(
      definition: targetDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: [
        FilterClause(
          field: foreignKey,
          operator: FilterOperator.inValues,
          value: throughKeyToParents.keys.toList(),
        ),
      ],
      predicate: load.predicate,
    );
    final targetRows = await context.driver.execute(targetPlan);
    final grouped = <Object?, List<dynamic>>{};

    for (final row in targetRows) {
      final model = targetDefinition.fromMap(row, registry: _codecRegistry);
      context.attachRuntimeMetadata(model);
      final throughKey = row[foreignKey];
      final parentIds = throughKeyToParents[throughKey];
      if (parentIds == null) continue;
      for (final parentId in parentIds) {
        grouped.putIfAbsent(parentId, () => <dynamic>[]).add(model);
      }
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
    final pivotModelDefinition = _resolvePivotModelDefinition(relation);
    final pivotColumns = _normalizePivotColumns(
      [
        ...segment.pivotColumns,
        ..._pivotModelColumns(pivotModelDefinition),
        ..._pivotTimestampColumns(segment.pivotTimestamps),
      ],
      pivotParentColumn,
      pivotTargetColumn,
    );
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
      pivotColumns: _pivotExtraColumns(
        pivotColumns,
        segment.morphOnPivot ? segment.morphTypeColumn : null,
      ),
    );
    final pivotFilters = <FilterClause>[
      FilterClause(
        field: pivotParentColumn,
        operator: FilterOperator.inValues,
        value: parentIds.toList(),
      ),
    ];
    if (segment.usesMorph && segment.morphOnPivot) {
      pivotFilters.add(
        FilterClause(
          field: segment.morphTypeColumn!,
          operator: FilterOperator.equals,
          value: segment.morphClass,
        ),
      );
    }
    final pivotPlan = QueryPlan(
      definition: pivotDefinition,
      driverName: _driverName,
      tablePrefix: _tablePrefix,
      filters: pivotFilters,
    );
    final pivotRows = await context.driver.execute(pivotPlan);
    final parentToTargets = <Object?, List<Object?>>{};
    final pivotDataByParent = <Object?, Map<Object?, Map<String, Object?>>>{};
    final targetIds = <Object?>{};
    for (final row in pivotRows) {
      final parentId = row[pivotParentColumn];
      final targetId = row[pivotTargetColumn];
      if (parentId == null || targetId == null) {
        continue;
      }
      parentToTargets.putIfAbsent(parentId, () => <Object?>[]).add(targetId);
      targetIds.add(targetId);
      final pivotData = _pivotDataFromRow(
        row,
        pivotParentColumn,
        pivotTargetColumn,
        pivotColumns,
        includeKeysOnly: pivotModelDefinition != null,
      );
      if (pivotData != null) {
        pivotDataByParent
            .putIfAbsent(parentId, () => <Object?, Map<String, Object?>>{})
            .putIfAbsent(targetId, () => pivotData);
      }
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
    final usePivotData =
        pivotColumns.isNotEmpty || pivotModelDefinition != null;
    if (usePivotData) {
      final rowLookup = <Object?, Map<String, Object?>>{};
      for (final row in targetRows) {
        rowLookup[row[targetKey]] = row;
      }
      for (final row in parents) {
        final key = row.row[parentKey];
        final ids = parentToTargets[key] ?? const [];
        final pivotDataForParent = pivotDataByParent[key];
        final models = <dynamic>[];
        for (final id in ids) {
          final targetRow = rowLookup[id];
          if (targetRow == null) {
            continue;
          }
          final model =
              targetDefinition.fromMap(targetRow, registry: _codecRegistry);
          context.attachRuntimeMetadata(model);
          final pivotData = pivotDataForParent?[id];
          if (pivotData != null && model is ModelRelations) {
            final pivotValue = pivotModelDefinition == null
                ? Map<String, Object?>.from(pivotData)
                : _buildPivotModel(pivotModelDefinition, pivotData);
            (model as ModelRelations).setRelation(
              'pivot',
              pivotValue,
            );
          }
          models.add(model);
        }
        row.relations[relation.name] = List.unmodifiable(models);
      }
      return;
    }

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

  /// Loads a `morph-to` relation.
  Future<void> _loadMorphTo<T extends OrmEntity>(
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    RelationLoad load,
    RelationSegment segment,
  ) async {
    final relation = load.relation;
    final foreignKey = segment.parentKey;
    final morphColumn = segment.morphTypeColumn;
    if (morphColumn == null) {
      throw StateError('Relation ${relation.name} requires a morph type column.');
    }
    if (load.predicate != null) {
      throw StateError(
        'Relation ${relation.name} does not support constraint callbacks.',
      );
    }

    final refs = List<_MorphReference?>.filled(parents.length, null);
    final groupedIds = <String, Set<Object?>>{};

    for (var i = 0; i < parents.length; i++) {
      final row = parents[i].row;
      final rawType = row[morphColumn];
      final rawId = row[foreignKey];
      if (rawType == null || rawId == null) {
        parents[i].relations[relation.name] = null;
        continue;
      }
      final typeName = rawType is String ? rawType : rawType.toString();
      if (typeName.isEmpty) {
        parents[i].relations[relation.name] = null;
        continue;
      }
      refs[i] = _MorphReference(typeName, rawId);
      groupedIds.putIfAbsent(typeName, () => <Object?>{}).add(rawId);
    }

    if (groupedIds.isEmpty) {
      return;
    }

    final lookupByType = <String, Map<Object?, OrmEntity>>{};
    final nestedGroups = <ModelDefinition<OrmEntity>, List<QueryRow<OrmEntity>>>{};

    for (final entry in groupedIds.entries) {
      final typeName = entry.key;
      final ids = entry.value;
      if (ids.isEmpty) continue;

      final definition = _registry.resolveMorphDefinition(typeName);
      final targetKey =
          relation.localKey ?? definition.primaryKeyField?.columnName;
      if (targetKey == null) {
        throw StateError('Relation ${relation.name} requires a target key.');
      }

      final targetPlan = QueryPlan(
        definition: definition,
        driverName: _driverName,
        tablePrefix: _tablePrefix,
        filters: [
          FilterClause(
            field: targetKey,
            operator: FilterOperator.inValues,
            value: ids.toList(),
          ),
        ],
      );
      final targetRows = await context.driver.execute(targetPlan);
      final lookup = <Object?, OrmEntity>{};
      for (final row in targetRows) {
        final model = definition.fromMap(row, registry: _codecRegistry);
        context.attachRuntimeMetadata(model);
        lookup[row[targetKey]] = model;
        if (load.nested.isNotEmpty) {
          nestedGroups
              .putIfAbsent(definition, () => <QueryRow<OrmEntity>>[])
              .add(
                QueryRow<OrmEntity>(
                  model: model,
                  row: definition.toMap(model, registry: _codecRegistry),
                ),
              );
        }
      }
      lookupByType[typeName] = lookup;
    }

    for (var i = 0; i < parents.length; i++) {
      final ref = refs[i];
      if (ref == null) {
        continue;
      }
      final lookup = lookupByType[ref.typeName];
      parents[i].relations[relation.name] = lookup?[ref.id];
    }

    if (load.nested.isNotEmpty) {
      for (final entry in nestedGroups.entries) {
        await attach(entry.key, entry.value, load.nested);
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
    final parentDef = parent as ModelDefinition<OrmEntity>;
    switch (relation.kind) {
      case RelationKind.morphTo:
        final foreignKey = relation.foreignKey ?? '${relation.name}_id';
        final morphColumn = relation.morphType ?? '${relation.name}_type';
        final targetKey = relation.localKey ?? 'id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parentDef,
          targetDefinition: parentDef,
          parentKey: foreignKey,
          childKey: targetKey,
          foreignKeyOnParent: true,
          morphTypeColumn: morphColumn,
          expectSingleResult: true,
        );
      case RelationKind.hasOne:
      case RelationKind.hasMany:
        final target = _registry.expectByName(relation.targetModel);
        final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;
        if (parentKey == null) {
          throw StateError('Relation ${relation.name} requires a parent key.');
        }
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
      case RelationKind.hasOneThrough:
      case RelationKind.hasManyThrough:
        final target = _registry.expectByName(relation.targetModel);
        final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;
        if (parentKey == null) {
          throw StateError('Relation ${relation.name} requires a parent key.');
        }
        final throughName =
            relation.throughModel ??
            (throw StateError(
              'Relation ${relation.name} requires a through model.',
            ));
        final throughDefinition = _registry.expectByName(throughName);
        final throughParentKey =
            relation.throughForeignKey ?? '${parent.tableName}_id';
        final throughChildKey =
            relation.throughLocalKey ??
            throughDefinition.primaryKeyField?.columnName;
        if (throughChildKey == null) {
          throw StateError(
            'Relation ${relation.name} requires a through key.',
          );
        }
        final relatedForeignKey =
            relation.foreignKey ?? '${throughDefinition.tableName}_id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parentDef,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: relatedForeignKey,
          throughDefinition: throughDefinition,
          throughParentKey: throughParentKey,
          throughChildKey: throughChildKey,
          expectSingleResult: relation.kind == RelationKind.hasOneThrough,
        );
      case RelationKind.belongsTo:
        final target = _registry.expectByName(relation.targetModel);
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
        final target = _registry.expectByName(relation.targetModel);
        final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;
        if (parentKey == null) {
          throw StateError('Relation ${relation.name} requires a parent key.');
        }
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
          pivotColumns: relation.pivotColumns,
          pivotTimestamps: relation.pivotTimestamps,
        );
      case RelationKind.morphOne:
      case RelationKind.morphMany:
        final target = _registry.expectByName(relation.targetModel);
        final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;
        if (parentKey == null) {
          throw StateError('Relation ${relation.name} requires a parent key.');
        }
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
      case RelationKind.morphToMany:
      case RelationKind.morphedByMany:
        final target = _registry.expectByName(relation.targetModel);
        final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;
        if (parentKey == null) {
          throw StateError('Relation ${relation.name} requires a parent key.');
        }
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
          childKey: targetKey,
          pivotTable: pivotTable,
          pivotParentKey: pivotParentKey,
          pivotRelatedKey: pivotRelatedKey,
          pivotColumns: relation.pivotColumns,
          pivotTimestamps: relation.pivotTimestamps,
          morphTypeColumn: morphColumn,
          morphClass: morphClass,
          morphOnPivot: true,
        );
    }
  }

  ModelDefinition<AdHocRow> _pivotDefinition(
    String table,
    String parentColumn,
    String targetColumn, {
    List<String> pivotColumns = const [],
  }) => ModelDefinition<AdHocRow>(
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
      ...pivotColumns.map(
        (column) => FieldDefinition(
          name: column,
          columnName: column,
          dartType: 'Object',
          resolvedType: 'Object?',
          isPrimaryKey: false,
          isNullable: true,
        ),
      ),
    ],
    relations: const [],
    codec: const _PivotCodec(),
  );

  List<String> _normalizePivotColumns(
    List<String> columns,
    String? parentColumn,
    String? targetColumn,
  ) {
    if (columns.isEmpty) return const [];
    final normalized = <String>{};
    for (final column in columns) {
      final trimmed = column.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed == parentColumn || trimmed == targetColumn) {
        continue;
      }
      normalized.add(trimmed);
    }
    return normalized.toList(growable: false);
  }

  List<String> _pivotExtraColumns(
    List<String> pivotColumns,
    String? morphTypeColumn,
  ) {
    if (pivotColumns.isEmpty && morphTypeColumn == null) {
      return const [];
    }
    final columns = <String>{...pivotColumns};
    if (morphTypeColumn != null && morphTypeColumn.trim().isNotEmpty) {
      columns.add(morphTypeColumn);
    }
    return columns.toList(growable: false);
  }

  ModelDefinition<OrmEntity>? _resolvePivotModelDefinition(
    RelationDefinition relation,
  ) {
    final pivotModel = relation.pivotModel;
    if (pivotModel == null || pivotModel.isEmpty) {
      return null;
    }
    return _registry.expectByName(pivotModel);
  }

  List<String> _pivotModelColumns(ModelDefinition<OrmEntity>? pivotDefinition) {
    if (pivotDefinition == null) return const [];
    return pivotDefinition.fields
        .map((field) => field.columnName)
        .toList(growable: false);
  }

  List<String> _pivotTimestampColumns(bool enabled) {
    if (!enabled) return const [];
    return const [
      Timestamps.defaultCreatedAtColumn,
      Timestamps.defaultUpdatedAtColumn,
    ];
  }

  Map<String, Object?>? _pivotDataFromRow(
    Map<String, Object?> row,
    String parentColumn,
    String targetColumn,
    List<String> pivotColumns, {
    bool includeKeysOnly = false,
  }) {
    if (pivotColumns.isEmpty && !includeKeysOnly) return null;
    final data = <String, Object?>{
      parentColumn: row[parentColumn],
      targetColumn: row[targetColumn],
    };
    for (final column in pivotColumns) {
      data[column] = row[column];
    }
    return data;
  }

  Object _buildPivotModel(
    ModelDefinition<OrmEntity> pivotDefinition,
    Map<String, Object?> pivotData,
  ) {
    final model = pivotDefinition.fromMap(
      pivotData,
      registry: _codecRegistry,
    );
    if (model is Model) {
      context.attachRuntimeMetadata(model);
    }
    return model;
  }
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

class _MorphReference {
  const _MorphReference(this.typeName, this.id);

  final String typeName;
  final Object? id;
}
