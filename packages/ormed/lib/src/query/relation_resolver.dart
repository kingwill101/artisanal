library;

import 'package:ormed/src/annotations.dart';
import 'package:ormed/src/model/model.dart';
import 'package:ormed/src/query/query.dart';

import '../contracts.dart';

/// Utility class for resolving and building relation metadata.
///
/// This class extracts shared logic for relation resolution used by both
/// the query builder and lazy loading on models.
///
/// Relation paths are cached to avoid redundant lookups when the same
/// relation is accessed multiple times.
class RelationResolver {
  /// Creates a new [RelationResolver] with caching enabled.
  ///
  /// The resolver will cache resolved relation paths to avoid redundant
  /// lookups when the same relation is accessed multiple times.
  RelationResolver(this.context) : _enableCaching = true;

  /// Creates a [RelationResolver] without caching.
  ///
  /// Useful for one-off lookups where caching overhead isn't worthwhile.
  const RelationResolver.uncached(this.context) : _enableCaching = false;

  final QueryContext context;

  /// Whether caching is enabled for this resolver.
  final bool _enableCaching;

  /// Storage for mutable caches per resolver instance.
  ///
  /// Keys are formatted as `{modelName}:{relationPath}` to ensure uniqueness.
  static final Expando<Map<String, RelationPath>> _resolverCaches =
      Expando<Map<String, RelationPath>>('_resolverCaches');

  /// Returns the cached path cache, lazily creating it if needed.
  Map<String, RelationPath> get _cache {
    if (!_enableCaching) return const {};
    return _resolverCaches[this] ??= <String, RelationPath>{};
  }

  /// Clears the relation path cache for this resolver.
  ///
  /// Useful when model definitions change at runtime (rare).
  void clearCache() {
    _resolverCaches[this]?.clear();
  }

  /// Returns cache statistics for debugging/profiling.
  ///
  /// Returns a map with 'size' indicating the number of cached paths.
  Map<String, int> get cacheStats => {'size': _cache.length};

  /// Resolves a dotted relation path (e.g., "posts.comments") into segments.
  ///
  /// Each segment contains the metadata needed to load that part of the relation.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final path = resolver.resolvePath(userDefinition, 'posts.comments');
  /// // Returns: RelationPath with segments for 'posts' and 'comments'
  /// ```
  ///
  /// Throws [ArgumentError] if any part of the relation path is invalid.
  RelationPath resolvePath(
    ModelDefinition<OrmEntity> startDefinition,
    String relation,
  ) {
    // Check cache first (only for cached resolvers)
    if (_enableCaching) {
      final cacheKey = '${startDefinition.modelName}:$relation';
      final cache = _cache;
      final cached = cache[cacheKey];
      if (cached != null) return cached;

      // Resolve and cache
      final path = _resolvePathUncached(startDefinition, relation);
      cache[cacheKey] = path;
      return path;
    }

    // Uncached resolver - resolve directly
    return _resolvePathUncached(startDefinition, relation);
  }

  /// Internal method that performs the actual path resolution without caching.
  RelationPath _resolvePathUncached(
    ModelDefinition<OrmEntity> startDefinition,
    String relation,
  ) {
    final names = relation.split('.');
    final segments = <RelationSegment>[];
    ModelDefinition<OrmEntity> current = startDefinition;

    for (var i = 0; i < names.length; i++) {
      final name = names[i];
      final relationDef = current.relations
          .cast<RelationDefinition?>()
          .firstWhere((r) => r?.name == name, orElse: () => null);

      if (relationDef == null) {
        throw ArgumentError.value(
          relation,
          'relation',
          'Unknown relation $name on ${current.modelName}.',
        );
      }

      final segment = segmentFor(current, relationDef);
      if (segment.relation.kind == RelationKind.morphTo &&
          i != names.length - 1) {
        throw ArgumentError.value(
          relation,
          'relation',
          'Relation path $relation cannot traverse morphTo segments.',
        );
      }
      segments.add(segment);
      current = segment.targetDefinition;
    }

    return RelationPath(segments: segments);
  }

  /// Builds a [RelationSegment] for a single relation.
  ///
  /// Contains all the metadata needed to load this relation, including
  /// foreign keys, pivot tables, morph columns, etc.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final segment = resolver.segmentFor(postDefinition, commentsRelation);
  /// // Returns: RelationSegment with childKey, parentKey, etc.
  /// ```
  RelationSegment segmentFor(
    ModelDefinition<OrmEntity> parent,
    RelationDefinition relation,
  ) {
    switch (relation.kind) {
      case RelationKind.morphTo:
        final foreignKey = relation.foreignKey ?? '${relation.name}_id';
        final morphColumn = relation.morphType ?? '${relation.name}_type';
        final targetKey = relation.localKey ?? 'id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: parent,
          parentKey: foreignKey,
          childKey: targetKey,
          foreignKeyOnParent: true,
          morphTypeColumn: morphColumn,
          expectSingleResult: true,
        );
      case RelationKind.hasOne:
      case RelationKind.hasMany:
        final target = context.registry.expectByName(relation.targetModel);
        final parentKey =
            relation.localKey ?? parent.primaryKeyField?.columnName;
        if (parentKey == null) {
          throw StateError('Relation ${relation.name} requires a parent key.');
        }
        final childKey = relation.foreignKey ?? '${parent.tableName}_id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          expectSingleResult: relation.kind == RelationKind.hasOne,
        );

      case RelationKind.hasOneThrough:
      case RelationKind.hasManyThrough:
        final target = context.registry.expectByName(relation.targetModel);
        final parentKey =
            relation.localKey ?? parent.primaryKeyField?.columnName;
        if (parentKey == null) {
          throw StateError('Relation ${relation.name} requires a parent key.');
        }
        final throughName =
            relation.throughModel ??
            (throw StateError(
              'Relation ${relation.name} requires a through model.',
            ));
        final throughDefinition = context.registry.expectByName(throughName);
        final throughParentKey =
            relation.throughForeignKey ?? '${parent.tableName}_id';
        final throughChildKey =
            relation.throughLocalKey ??
            throughDefinition.primaryKeyField?.columnName;
        if (throughChildKey == null) {
          throw StateError('Relation ${relation.name} requires a through key.');
        }
        final relatedForeignKey =
            relation.foreignKey ?? '${throughDefinition.tableName}_id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: relatedForeignKey,
          throughDefinition: throughDefinition,
          throughParentKey: throughParentKey,
          throughChildKey: throughChildKey,
          expectSingleResult: relation.kind == RelationKind.hasOneThrough,
        );

      case RelationKind.belongsTo:
        final target = context.registry.expectByName(relation.targetModel);
        final foreignKey = relation.foreignKey ?? '${relation.name}_id';
        final ownerKey =
            relation.localKey ?? target.primaryKeyField?.columnName;
        if (ownerKey == null) {
          throw StateError('Relation ${relation.name} requires a target key.');
        }
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: foreignKey,
          childKey: ownerKey,
          foreignKeyOnParent: true,
          expectSingleResult: true,
        );

      case RelationKind.manyToMany:
        final target = context.registry.expectByName(relation.targetModel);
        final parentKey =
            relation.localKey ?? parent.primaryKeyField?.columnName;
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
          parentDefinition: parent,
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
        final target = context.registry.expectByName(relation.targetModel);
        final parentKey =
            relation.localKey ?? parent.primaryKeyField?.columnName;
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
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          morphTypeColumn: morphColumn,
          morphClass: morphClass,
          expectSingleResult: relation.kind == RelationKind.morphOne,
        );

      case RelationKind.morphToMany:
      case RelationKind.morphedByMany:
        final target = context.registry.expectByName(relation.targetModel);
        final parentKey =
            relation.localKey ?? parent.primaryKeyField?.columnName;
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
          parentDefinition: parent,
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

  /// Converts a constraint callback to a [QueryPredicate].
  ///
  /// This allows constraint callbacks to be converted into predicates
  /// that can be applied to relation queries.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final predicate = resolver.predicateFor(
  ///   commentsRelation,
  ///   (q) => q.where('approved', true),
  /// );
  /// ```
  ///
  /// Returns `null` if no constraint is provided.
  QueryPredicate? predicateFor(
    RelationDefinition relation,
    PredicateCallback<OrmEntity>? constraint,
  ) {
    if (constraint == null) return null;
    if (relation.kind == RelationKind.morphTo) {
      throw StateError(
        'Relation ${relation.name} does not support constraint callbacks.',
      );
    }

    final target = context.registry.expectByName(relation.targetModel);
    final builder = PredicateBuilder<OrmEntity>(target);
    constraint(builder);
    return builder.build();
  }

  /// Converts a typed constraint callback to a [QueryPredicate].
  ///
  /// This variant accepts a typed [PredicateCallback] so generated helpers can
  /// expose type-safe relation constraints.
  QueryPredicate? predicateForTyped<T extends OrmEntity>(
    RelationDefinition relation,
    PredicateCallback<T>? constraint,
  ) {
    if (constraint == null) return null;
    if (relation.kind == RelationKind.morphTo) {
      throw StateError(
        'Relation ${relation.name} does not support constraint callbacks.',
      );
    }

    final target =
        context.registry.expectByName(relation.targetModel)
            as ModelDefinition<T>;
    final builder = PredicateBuilder<T>(target);
    constraint(builder);
    return builder.build();
  }

  /// Converts a constraint callback to a [QueryPredicate] using a relation path.
  ///
  /// This is useful for nested relation constraints where you need the
  /// final target definition from the path.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final path = resolver.resolvePath(userDef, 'posts.comments');
  /// final predicate = resolver.predicateForPath(
  ///   path,
  ///   (q) => q.where('approved', true),
  /// );
  /// ```
  ///
  /// Returns `null` if no constraint is provided.
  QueryPredicate? predicateForPath(
    RelationPath path,
    PredicateCallback<OrmEntity>? constraint,
  ) {
    if (constraint == null) return null;
    if (path.segments.any(
      (segment) => segment.relation.kind == RelationKind.morphTo,
    )) {
      throw StateError(
        'Relation paths containing morphTo do not support constraint callbacks.',
      );
    }

    final builder = PredicateBuilder<OrmEntity>(path.leaf.targetDefinition);
    constraint(builder);
    return builder.build();
  }

  /// Converts a typed constraint callback to a [QueryPredicate] using a path.
  QueryPredicate? predicateForPathTyped<T extends OrmEntity>(
    RelationPath path,
    PredicateCallback<T>? constraint,
  ) {
    if (constraint == null) return null;
    if (path.segments.any(
      (segment) => segment.relation.kind == RelationKind.morphTo,
    )) {
      throw StateError(
        'Relation paths containing morphTo do not support constraint callbacks.',
      );
    }

    final target = path.leaf.targetDefinition as ModelDefinition<T>;
    final builder = PredicateBuilder<T>(target);
    constraint(builder);
    return builder.build();
  }
}
