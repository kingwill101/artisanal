// Examples of query building with Ormed
// These can be referenced in documentation via code regions

// ignore_for_file: unused_local_variable

// #region basic-query
import 'package:ormed/ormed.dart';

import 'models/user.dart';
import 'models/user.orm.dart';
import 'models/post.dart';
import 'models/post.orm.dart';
import 'models/relations/has_many.dart';

Future<void> basicQueryExample(QueryContext context) async {
  // Find all users
  final users = await context.query<$User>().get();

  // Find by ID
  final user = await context.query<$User>().find(1);

  // Find with conditions
  final activeUsers = await context
      .query<$User>()
      .whereEquals('active', true)
      .get();
}
// #endregion basic-query

// #region intro-query
Future<void> introQueryExample(DataSource dataSource) async {
  // Query with fluent API
  final users = await dataSource
      .query<$User>()
      .whereEquals('active', true)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .get();

  // Repository operations
  final repo = dataSource.repo<$User>();
  final user = await repo.find(1);
  if (user != null) {
    user.setAttribute('name', 'John');
    await repo.update(user);
  }
}
// #endregion intro-query

// #region where-clauses
Future<void> whereClauseExamples(QueryContext context) async {
  // Equals
  await context.query<$User>().whereEquals('name', 'John').get();

  // Not equals
  await context.query<$User>().whereNotEquals('status', 'banned').get();

  // Comparison operators
  await context.query<$User>().whereGreaterThan('age', 18).get();
  await context.query<$User>().whereGreaterThanOrEqual('age', 21).get();
  await context.query<$User>().whereLessThan('age', 65).get();

  // In clause
  await context.query<$User>().whereIn('role', ['admin', 'moderator']).get();

  // Like clause
  await context.query<$User>().whereLike('name', '%john%').get();

  // Null checks
  await context.query<$User>().whereNull('deletedAt').get();
  await context.query<$User>().whereNotNull('emailVerifiedAt').get();

  // Between
  await context.query<$User>().whereBetween('age', 18, 65).get();
}
// #endregion where-clauses

// #region where-typed-predicate
Future<void> whereTypedPredicateExamples(QueryContext context) async {
  // Typed predicate fields via whereTyped
  await context
      .query<$User>()
      .whereTyped((q) => q.email.eq('alice@example.com'))
      .get();

  // Typed field access also works in untyped callbacks (dynamic), but without
  // static checking.
  await context.query<$User>().where((q) => q.name.isNotNull()).get();
}
// #endregion where-typed-predicate

// #region ordering-limiting
Future<void> orderingLimitingExamples(QueryContext context) async {
  // Order by single column (ascending by default)
  await context.query<$User>().orderBy('name').get();

  // Order descending
  await context.query<$User>().orderBy('createdAt', descending: true).get();

  // Multiple order by
  await context.query<$User>().orderBy('lastName').orderBy('firstName').get();

  // Limit and offset
  await context.query<$User>().limit(10).get();
  await context.query<$User>().limit(10).offset(20).get();

  // First record
  final firstUser = await context.query<$User>().orderBy('id').first();
}
// #endregion ordering-limiting

// #region group-limits
Future<void> groupLimitExamples(QueryContext context) async {
  final recentPerAuthor = await context
      .query<$Post>()
      .orderBy('publishedAt', descending: true)
      .limitPerGroup(2, 'authorId', offset: 1)
      .get();
}
// #endregion group-limits

// #region aggregates
Future<void> aggregateExamples(QueryContext context) async {
  // Count
  final userCount = await context.query<$User>().count();

  // Exists check
  final hasAdmins = await context
      .query<$User>()
      .whereEquals('role', 'admin')
      .exists();

  // Max/Min
  final maxAge = await context.query<$User>().max('age');
  final minAge = await context.query<$User>().min('age');

  // Sum/Avg
  final totalBalance = await context.query<$User>().sum('balance');
  final avgAge = await context.query<$User>().avg('age');
}
// #endregion aggregates

// #region relations
Future<void> relationExamples(QueryContext context) async {
  // Eager load a relation
  final posts = await context.query<$Post>().with_(['author']).get();

  // Load multiple relations
  final postsWithComments = await context.query<$Post>().with_([
    'author',
    'comments',
  ]).get();

  // Nested relation loading
  final postsDeep = await context.query<$Post>().with_([
    'author.profile',
    'comments.user',
  ]).get();

  // Join relation for filtering without loading
  final userPosts = await context
      .query<$User>()
      .joinRelation('posts')
      .whereEquals('posts.published', true)
      .get();
}
// #endregion relations

// #region typed-relation-helpers
Future<void> typedRelationHelpers(QueryContext context) async {
  final users = await context
      .query<$UserWithPosts>()
      .whereHasPosts((q) => q.title.like('%Dart%'))
      .withPosts((q) => q.title.like('%Dart%'))
      .get();
}
// #endregion typed-relation-helpers

// #region query-getting-started
Future<void> queryGettingStarted(DataSource dataSource) async {
  final users = await dataSource.query<$User>().get();
}
// #endregion query-getting-started

// #region query-getting-started-static
Future<void> queryGettingStartedStatic() async {
  // Assumes a default connection is configured (see DataSource docs).
  final users = await Users.query().get();
}
// #endregion query-getting-started-static

// #region query-get-all
Future<void> queryGetAll(DataSource dataSource) async {
  final users = await dataSource.query<$User>().get();
}
// #endregion query-get-all

// #region query-select
Future<void> querySelect(DataSource dataSource) async {
  final users = await dataSource.query<$User>().select([
    'id',
    'email',
    'name',
  ]).get();
}
// #endregion query-select

// #region query-first
Future<void> queryFirst(DataSource dataSource) async {
  // Returns null if not found
  final user = await dataSource.query<$User>().first();

  // Throws if not found
  final userOrFail = await dataSource.query<$User>().firstOrFail();
}
// #endregion query-first

// #region query-find
Future<void> queryFind(DataSource dataSource) async {
  final user = await dataSource.query<$User>().find(1);
  final userOrFail = await dataSource.query<$User>().findOrFail(1);
}
// #endregion query-find

// #region where-comparison
Future<void> whereComparison(DataSource dataSource) async {
  final users = await dataSource
      .query<$User>()
      .where('age', '>', 18)
      .where('age', '<=', 65)
      .get();
}
// #endregion where-comparison

// #region where-in
Future<void> whereIn(DataSource dataSource) async {
  final users = await dataSource.query<$User>().whereIn('role', [
    'admin',
    'moderator',
  ]).get();

  final bannedUsers = await dataSource.query<$User>().whereNotIn('status', [
    'banned',
    'suspended',
  ]).get();
}
// #endregion where-in

// #region where-null
Future<void> whereNull(DataSource dataSource) async {
  final users = await dataSource.query<$User>().whereNull('deleted_at').get();

  final verifiedUsers = await dataSource
      .query<$User>()
      .whereNotNull('verified_at')
      .get();
}
// #endregion where-null

// #region where-between
Future<void> whereBetween(DataSource dataSource) async {
  final users = await dataSource
      .query<$User>()
      .whereBetween('age', 18, 65)
      .get();
}
// #endregion where-between

// #region where-like
Future<void> whereLike(DataSource dataSource) async {
  final users = await dataSource
      .query<$User>()
      .whereLike('email', '%@example.com')
      .get();
}
// #endregion where-like

// #region where-or
Future<void> whereOr(DataSource dataSource) async {
  final users = await dataSource
      .query<$User>()
      .whereEquals('role', 'admin')
      .orWhere('role', '=', 'moderator')
      .get();
}
// #endregion where-or

// #region where-grouped
Future<void> whereGrouped(DataSource dataSource) async {
  final users = await dataSource
      .query<$User>()
      .where('active', '=', true)
      .whereGroup(
        (q) => q.where('role', '=', 'admin').orWhere('role', '=', 'moderator'),
      )
      .get();

  // SQL: WHERE active = 1 AND (role = 'admin' OR role = 'moderator')
}
// #endregion where-grouped

// #region distinct
Future<void> distinctExample(DataSource dataSource) async {
  final roles = await dataSource.query<$User>().distinct().select([
    'role',
  ]).get();
}
// #endregion distinct

// #region raw-expressions
Future<void> rawExpressions(DataSource dataSource) async {
  final users = await dataSource.query<$User>().whereRaw("LOWER(email) = ?", [
    'john@example.com',
  ]).get();

  final usersWithFullName = await dataSource
      .query<$User>()
      .selectRaw("*, CONCAT(first_name, ' ', last_name) AS full_name")
      .get();
}
// #endregion raw-expressions

// #region partial-projections
Future<void> partialProjections(DataSource dataSource) async {
  final partial = await dataSource.query<$User>().select([
    'id',
    'email',
  ]).firstPartial();

  print(partial?.id); // Available
  print(partial?.email); // Available
  // partial?.name is not available (not selected)
}
// #endregion partial-projections

// #region soft-delete-scopes
Future<void> softDeleteScopes(DataSource dataSource) async {
  // Default: excludes soft-deleted
  final posts = await dataSource.query<$Post>().get();

  // Include soft-deleted
  final allPosts = await dataSource.query<$Post>().withTrashed().get();

  // Only soft-deleted
  final trashedPosts = await dataSource.query<$Post>().onlyTrashed().get();
}
// #endregion soft-delete-scopes

// #region query-caching
Future<void> queryCaching(DataSource dataSource) async {
  // Cache for 5 minutes
  final users = await dataSource
      .query<$User>()
      .remember(Duration(minutes: 5))
      .get();

  // Cache forever (until manually cleared)
  final settings = await dataSource.query<$User>().rememberForever().get();

  // Disable caching for specific query
  final freshData = await dataSource.query<$User>().dontRemember().get();

  // Clear query cache
  await dataSource.flushQueryCache();
}

// #endregion query-caching
