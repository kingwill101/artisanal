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

// #region pagination-basic
Future<void> paginationWithTotals(DataSource dataSource) async {
  final usersPage = await dataSource
      .query<$User>()
      .paginate(perPage: 10, page: 2);

  print('Total users: ${usersPage.total}');
  print('Page ${usersPage.currentPage} of ${usersPage.lastPage}');

  for (final row in usersPage.items) {
    print('User ${row.model.id}: ${row.model.email}');
  }
}
// #endregion pagination-basic

// #region pagination-simple
Future<void> paginationWithoutCount(DataSource dataSource) async {
  final page = await dataSource
      .query<$User>()
      .simplePaginate(perPage: 20, page: 1);

  print('Loaded ${page.items.length} users');
  print('Has more pages: ${page.hasMorePages}');
}
// #endregion pagination-simple

// #region pagination-cursor
Future<void> cursorPagination(DataSource dataSource) async {
  final firstPage = await dataSource
      .query<$User>()
      .cursorPaginate(perPage: 5, column: 'id');

  final nextPage = await dataSource
      .query<$User>()
      .cursorPaginate(
        perPage: 5,
        column: 'id',
        cursor: firstPage.nextCursor,
      );

  print('Has more: ${nextPage.hasMore}');
  print('Next cursor: ${nextPage.nextCursor}');
}
// #endregion pagination-cursor

// #region pagination-chunking
Future<void> paginationChunking(DataSource dataSource) async {
  await dataSource.query<$User>().chunk(100, (rows) async {
    for (final row in rows) {
      print('Chunk user: ${row.model.id}');
    }
    return true; // continue
  });

  await dataSource.query<$User>().chunkById(50, (rows) async {
    for (final row in rows) {
      print('Chunk by id user: ${row.model.id}');
    }
    return true;
  }, column: 'id');

  await dataSource.query<$User>().eachById(25, (row) async {
    if (row.model.id == 42) {
      return false; // stop early
    }
    return true;
  }, column: 'id');
}
// #endregion pagination-chunking

// #region pagination-streaming
Future<void> paginationStreaming(DataSource dataSource) async {
  await for (final row in dataSource
      .query<$User>()
      .streamRows(eagerLoadBatchSize: 200)) {
    print('Row email: ${row.model.email}');
  }

  await for (final user in dataSource.query<$User>().streamModels()) {
    print('User model: ${user.email}');
  }
}
// #endregion pagination-streaming

// #region joins
Future<void> joinsExamples(DataSource dataSource) async {
  // Inner join
  final usersWithPosts = await dataSource
      .query<$User>()
      .join('posts', 'users.id', '=', 'posts.author_id')
      .get();

  // Left join - includes users without posts
  final allUsersWithOptionalPosts = await dataSource
      .query<$User>()
      .leftJoin('posts', 'users.id', '=', 'posts.author_id')
      .get();

  // Right join
  final allPostsWithOptionalUsers = await dataSource
      .query<$Post>()
      .rightJoin('users', 'posts.author_id', '=', 'users.id')
      .get();

  // Cross join - Cartesian product
  final productColors = await dataSource
      .query<$User>()
      .crossJoin('colors')
      .get();

  // Join with callback for complex conditions
  final activeUserPosts = await dataSource.query<$User>().join('posts', (join) {
    join.on('users.id', '=', 'posts.author_id')
        .where('posts.status', '=', 'published');
  }).get();

  // Join through relationships
  final usersWithPublishedPosts = await dataSource
      .query<$User>()
      .joinRelation('posts')
      .whereEquals('posts.published', true)
      .get();
}
// #endregion joins

// #region subqueries
Future<void> subqueryExamples(DataSource dataSource) async {
  // WHERE IN subquery - users with published posts
  final activeAuthors = await dataSource.query<$User>().whereInSubquery(
    'id',
    dataSource.query<$Post>().select(['author_id']).whereEquals('published', true),
  ).get();

  // WHERE NOT IN subquery - users without posts
  final usersWithoutPosts = await dataSource.query<$User>().whereNotInSubquery(
    'id',
    dataSource.query<$Post>().select(['author_id']),
  ).get();

  // WHERE EXISTS - users with at least one comment
  final usersWithComments = await dataSource.query<$User>().whereExists(
    dataSource.query<$Comment>().whereColumn('comments.user_id', 'users.id'),
  ).get();

  // WHERE NOT EXISTS - users with no comments
  final usersWithoutComments = await dataSource.query<$User>().whereNotExists(
    dataSource.query<$Comment>().whereColumn('comments.user_id', 'users.id'),
  ).get();
}
// #endregion subqueries

// #region unions
Future<void> unionExamples(DataSource dataSource) async {
  // UNION - combine results, removing duplicates
  final activeOrAdminUsers = await dataSource
      .query<$User>()
      .whereEquals('active', true)
      .union(dataSource.query<$User>().whereEquals('role', 'admin'))
      .get();

  // UNION ALL - combine results, keeping duplicates
  final allUsersIncludingDupes = await dataSource
      .query<$User>()
      .whereEquals('active', true)
      .unionAll(dataSource.query<$User>().whereEquals('role', 'admin'))
      .get();

  // INSERT USING - bulk insert from another query
  final archivedCount = await dataSource.query<$User>().insertUsing(
    ['name', 'email', 'archived_at'],
    dataSource
        .query<$User>()
        .whereEquals('active', false)
        .select(['name', 'email'])
        .selectRaw('NOW()'),
  );
}
// #endregion unions

// #region locking
Future<void> lockingExamples(DataSource dataSource) async {
  await dataSource.transaction(() async {
    // Lock for update - prevents other transactions from modifying
    final user = await dataSource
        .query<$User>()
        .whereEquals('id', 1)
        .lockForUpdate()
        .first();

    // Update the locked row
    if (user != null) {
      await dataSource
          .query<$User>()
          .whereEquals('id', 1)
          .update({'balance': user.row['balance'] + 100});
    }
  });

  await dataSource.transaction(() async {
    // Shared lock - allows reads but prevents modifications
    final user = await dataSource
        .query<$User>()
        .whereEquals('id', 1)
        .sharedLock()
        .first();

    // Can read but other transactions can't modify
    print('User balance: ${user?.row['balance']}');
  });
}
// #endregion locking

// #region scopes
Future<void> scopesExamples(DataSource dataSource) async {
  // Apply a local scope (must be registered first)
  final activeUsers = await dataSource.query<$User>().scope('active').get();

  // Apply a query macro (global, works on any model)
  final recentPosts = await dataSource
      .query<$Post>()
      .macro('recent', [7]) // last 7 days
      .get();

  // Ignore global scopes
  final allPosts = await dataSource
      .query<$Post>()
      .withoutGlobalScopes() // includes soft-deleted
      .get();

  // Ignore specific global scope
  final postsIncludingDeleted = await dataSource
      .query<$Post>()
      .withoutGlobalScope('softDeletes')
      .get();
}
// #endregion scopes

// #region grouping
Future<void> groupingExamples(DataSource dataSource) async {
  // Group by single column
  final usersByCity = await dataSource
      .query<$User>()
      .select(['city'])
      .countAggregate(alias: 'total')
      .groupBy(['city'])
      .get();

  // Group by multiple columns
  final usersByStateAndCity = await dataSource
      .query<$User>()
      .select(['state', 'city'])
      .countAggregate(alias: 'total')
      .groupBy(['state', 'city'])
      .get();

  // HAVING clause - filter grouped results
  final popularCities = await dataSource
      .query<$User>()
      .select(['city'])
      .countAggregate(alias: 'user_count')
      .groupBy(['city'])
      .having('user_count', PredicateOperator.greaterThan, 100)
      .get();

  // HAVING with raw SQL
  final citiesWithHighTotalAge = await dataSource
      .query<$User>()
      .select(['city'])
      .groupBy(['city'])
      .havingRaw('SUM(age) > ?', [500])
      .get();
}
// #endregion grouping

// #region crud
Future<void> crudExamples(DataSource dataSource) async {
  // Create a single record
  final user = await dataSource.query<$User>().create({
    'name': 'John Doe',
    'email': 'john@example.com',
  });

  // Create multiple records
  final users = await dataSource.query<$User>().createMany([
    {'name': 'Alice', 'email': 'alice@example.com'},
    {'name': 'Bob', 'email': 'bob@example.com'},
  ]);

  // Update records
  final updatedCount = await dataSource
      .query<$User>()
      .whereEquals('active', false)
      .update({'status': 'inactive'});

  // Delete records
  final deletedCount = await dataSource
      .query<$User>()
      .whereEquals('banned', true)
      .delete();

  // Increment/decrement
  await dataSource
      .query<$User>()
      .whereEquals('id', 1)
      .increment('login_count', 1);

  await dataSource
      .query<$User>()
      .whereEquals('id', 1)
      .decrement('credits', 10);

  // Upsert - insert or update if exists
  await dataSource.query<$User>().upsert(
    [
      {'email': 'john@example.com', 'name': 'John Updated'},
    ],
    uniqueBy: ['email'],
    update: ['name'],
  );
}
// #endregion crud
