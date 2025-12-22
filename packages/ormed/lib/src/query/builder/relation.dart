part of '../query_builder.dart';

/// Extension providing relation eager loading and aggregate methods.
extension RelationExtension<T extends OrmEntity> on Query<T> {
  /// Requests eager loading for the relation named [name].
  ///
  /// Eager loading fetches related models in the same query or a minimal number
  /// of subsequent queries, preventing N+1 query problems.
  ///
  /// [name] is the name of the relation as defined in the model.
  /// [constraint] is an optional callback to apply additional `WHERE` conditions
  /// to the eager-loaded relation.
  ///
  /// Example:
  /// ```dart
  /// // Eager load the 'posts' relation for each user
  /// final usersWithPosts = await context.query<User>()
  ///   .withRelation('posts')
  ///   .get();
  ///
  /// // Eager load 'posts' and filter them
  /// final usersWithPublishedPosts = await context.query<User>()
  ///   .withRelation('posts', (query) => query.where('isPublished', true))
  ///   .get();
  /// ```
  Query<T> withRelation(
    String name, [
    PredicateCallback<OrmEntity>? constraint,
  ]) {
    final path = _resolveRelationPath(name);
    return _copyWith(
      relations: _mergeRelationLoad(_relations, path, constraint),
    );
  }

  /// Requests eager loading for multiple relations.
  ///
  /// [names] is a list of relation names to eager load.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .with_(['posts', 'profile'])
  ///   .get();
  /// ```
  Query<T> with_(List<String> names) {
    var query = this;
    for (final name in names) {
      query = query.withRelation(name);
    }
    return query;
  }

  List<RelationLoad> _mergeRelationLoad(
    List<RelationLoad> existing,
    RelationPath path,
    PredicateCallback<OrmEntity>? constraint,
  ) {
    if (path.segments.isEmpty) return existing;

    final segment = path.segments.first;
    final remainingSegments = path.segments.skip(1).toList();

    final existingIndex = existing.indexWhere(
      (r) => r.relation.name == segment.name,
    );

    if (existingIndex >= 0) {
      final load = existing[existingIndex];
      final updatedNested = remainingSegments.isEmpty
          ? load.nested
          : _mergeRelationLoad(
              load.nested,
              RelationPath(segments: remainingSegments),
              constraint,
            );

      // If it's the leaf segment, apply the constraint
      final updatedPredicate = remainingSegments.isEmpty
          ? _buildRelationLoadPredicate(segment.relation, constraint)
          : load.predicate;

      final updated = RelationLoad(
        relation: load.relation,
        predicate: updatedPredicate,
        nested: updatedNested,
      );

      final result = List<RelationLoad>.from(existing);
      result[existingIndex] = updated;
      return result;
    } else {
      final nested = remainingSegments.isEmpty
          ? const <RelationLoad>[]
          : _mergeRelationLoad(
              const [],
              RelationPath(segments: remainingSegments),
              constraint,
            );

      final predicate = remainingSegments.isEmpty
          ? _buildRelationLoadPredicate(segment.relation, constraint)
          : null;

      final load = RelationLoad(
        relation: segment.relation,
        predicate: predicate,
        nested: nested,
      );

      return [...existing, load];
    }
  }

  /// Adds a `WITH COUNT` aggregate for a relation.
  ///
  /// This method counts the number of related models for each parent model
  /// and adds it as a new column to the result.
  ///
  /// [relation] is the name of the relation.
  /// [alias] is an optional alias for the count result (defaults to `relation_count`).
  /// [constraint] is an optional callback to apply conditions to the related models
  /// before counting.
  /// [distinct] whether to count distinct related models.
  ///
  /// Example:
  /// ```dart
  /// final usersWithPostCounts = await context.query<User>()
  ///   .withCount('posts', alias: 'totalPosts')
  ///   .get();
  ///
  /// // Count only published posts
  /// final usersWithPublishedPostCounts = await context.query<User>()
  ///   .withCount('posts', alias: 'publishedPosts', (query) => query.where('isPublished', true))
  ///   .get();
  /// ```
  Query<T> withCount(
    String relation, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
    bool distinct = false,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.count,
      alias,
      constraint,
      distinct: distinct,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Adds a `WITH EXISTS` aggregate for a relation.
  ///
  /// This method checks for the existence of related models for each parent model
  /// and adds a boolean flag as a new column to the result.
  ///
  /// [relation] is the name of the relation.
  /// [alias] is an optional alias for the existence flag (defaults to `relation_exists`).
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// final usersWithPostsFlag = await context.query<User>()
  ///   .withExists('posts', alias: 'hasPosts')
  ///   .get();
  /// ```
  Query<T> withExists(
    String relation, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.exists,
      alias,
      constraint,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Adds a `WITH SUM` aggregate for a relation.
  ///
  /// This method calculates the sum of a column in related models for each parent model.
  ///
  /// [relation] is the name of the relation.
  /// [column] is the column to sum.
  /// [alias] is an optional alias for the sum result (defaults to `relation_sum_column`).
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// final postsWithTotalLikes = await context.query<Post>()
  ///   .withSum('comments', 'likes', alias: 'totalCommentLikes')
  ///   .get();
  /// ```
  Query<T> withSum(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.sum,
      alias ?? '${relation}_sum_${column.replaceAll('.', '_')}',
      constraint,
      column: column,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Adds a `WITH AVG` aggregate for a relation.
  ///
  /// This method calculates the average of a column in related models for each parent model.
  ///
  /// [relation] is the name of the relation.
  /// [column] is the column to average.
  /// [alias] is an optional alias for the average result (defaults to `relation_avg_column`).
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// final postsWithAvgRating = await context.query<Post>()
  ///   .withAvg('comments', 'rating', alias: 'averageRating')
  ///   .get();
  /// ```
  Query<T> withAvg(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.avg,
      alias ?? '${relation}_avg_${column.replaceAll('.', '_')}',
      constraint,
      column: column,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Adds a `WITH MAX` aggregate for a relation.
  ///
  /// This method finds the maximum value of a column in related models for each parent model.
  ///
  /// [relation] is the name of the relation.
  /// [column] is the column to find the maximum value.
  /// [alias] is an optional alias for the max result (defaults to `relation_max_column`).
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// final postsWithLatestComment = await context.query<Post>()
  ///   .withMax('comments', 'created_at', alias: 'latestCommentDate')
  ///   .get();
  /// ```
  Query<T> withMax(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.max,
      alias ?? '${relation}_max_${column.replaceAll('.', '_')}',
      constraint,
      column: column,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Adds a `WITH MIN` aggregate for a relation.
  ///
  /// This method finds the minimum value of a column in related models for each parent model.
  ///
  /// [relation] is the name of the relation.
  /// [column] is the column to find the minimum value.
  /// [alias] is an optional alias for the min result (defaults to `relation_min_column`).
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// final postsWithEarliestComment = await context.query<Post>()
  ///   .withMin('comments', 'created_at', alias: 'earliestCommentDate')
  ///   .get();
  /// ```
  Query<T> withMin(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.min,
      alias ?? '${relation}_min_${column.replaceAll('.', '_')}',
      constraint,
      column: column,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Orders results based on a relation aggregate.
  ///
  /// This method allows you to sort parent models based on an aggregate value
  /// (e.g., count) of their related models.
  ///
  /// [relation] is the name of the relation.
  /// [descending] (defaults to `false`) to sort in reverse.
  /// [aggregate] is the type of aggregate to use for ordering (defaults to [RelationAggregateType.count]).
  /// [constraint] is an optional callback to apply conditions to the related models.
  /// [distinct] whether to count distinct related models for the aggregate.
  ///
  /// Example:
  /// ```dart
  /// // Order users by the number of their posts (most posts first)
  /// final usersByPostCount = await context.query<User>()
  ///   .orderByRelation('posts', descending: true)
  ///   .get();
  /// ```
  Query<T> orderByRelation(
    String relation, {
    bool descending = false,
    RelationAggregateType aggregate = RelationAggregateType.count,
    PredicateCallback<OrmEntity>? constraint,
    bool distinct = false,
  }) {
    if (aggregate != RelationAggregateType.count && distinct) {
      throw ArgumentError(
        'distinct relation ordering is only supported for count aggregates.',
      );
    }
    final path = _resolveRelationPath(relation);
    final where = _buildRelationPredicateConstraint(path, constraint);
    final order = RelationOrder(
      path: path,
      aggregateType: aggregate,
      descending: descending,
      where: where,
      distinct: distinct,
    );
    return _copyWith(relationOrders: [..._relationOrders, order]);
  }
}
