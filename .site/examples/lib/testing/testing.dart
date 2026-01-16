// Testing examples for documentation
// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';
import '../models/comment.dart';
import '../models/comment.orm.dart';
import '../orm_registry.g.dart';

// #region testing-basic-setup
Future<void> basicTestSetup() async {
  late DataSource dataSource;

  // setUp
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test_db',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // test
  final user = $User(id: 0, name: 'Test', email: 'test@example.com');
  await dataSource.repo<$User>().insert(user);

  final found = await dataSource
      .query<$User>()
      .whereEquals('email', 'test@example.com')
      .first();
  print('Found: ${found?.name}');

  // tearDown
  await dataSource.dispose();
}
// #endregion testing-basic-setup

// #region testing-in-memory
Future<void> inMemoryExecutorExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // The SQLite in-memory driver automatically:
  // - Generates auto-increment IDs
  // - Enforces foreign keys (when enabled by the driver)
  // - Starts from a fresh database per DataSource instance
  // - Supports basic query operations
}
// #endregion testing-in-memory

// #region testing-seeder
class UserSeeder extends Seeder {
  @override
  Future<void> run(DataSource dataSource) async {
    final users = [
      $User(id: 0, name: 'Admin', email: 'admin@example.com'),
      $User(id: 0, name: 'User', email: 'user@example.com'),
    ];

    for (final user in users) {
      await dataSource.repo<$User>().insert(user);
    }
  }
}

Future<void> seederExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  final seeder = UserSeeder();
  await seeder.run(dataSource);
}
// #endregion testing-seeder

// #region testing-real-db
Future<void> realDatabaseExample() async {
  late DataSource dataSource;
  late String testDbPath;

  // setUp
  testDbPath = 'test_${DateTime.now().millisecondsSinceEpoch}.db';

  dataSource = DataSource(
    DataSourceOptions(
      name: 'integration_test',
      driver: SqliteDriverAdapter.file(testDbPath),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // test...

  // tearDown
  await dataSource.dispose();
  final file = File(testDbPath);
  if (await file.exists()) {
    await file.delete();
  }
}
// #endregion testing-real-db

// #region testing-migration-harness
// For migration-driven test setups with FK-safe cleanup:
// Use setUpOrmed from package:ormed/testing.dart
//
// setUpOrmed(
//   dataSource: myDataSource,
//   migrationDescriptors: [
//     MigrationDescriptor.fromMigration(
//       id: MigrationId(DateTime.utc(2024, 1, 1), 'create_users'),
//       migration: CreateUsersTable(),
//     ),
//   ],
//   seeders: [UserSeeder.new],
//   strategy: DatabaseIsolationStrategy.migrateWithTransactions,
//   parallel: true,
// );
//
// ormedTest('creates a user', () async {
//   final user = $User(id: 0, name: 'Ada', email: 'ada@test.com');
//   await dataSource.repo<$User>().insert(user);
//   expect(user.id, isNotNull);
// });
// #endregion testing-migration-harness

// #region testing-static-helpers
Future<void> staticHelpersExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // First DataSource initialized becomes default, or:
  dataSource.setAsDefault();

  // Now static helpers work
  await Users.query().get();
}
// #endregion testing-static-helpers

// #region testing-relations
Future<void> testingRelationsExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: [
        UserOrmDefinition.definition,
        PostOrmDefinition.definition,
        CommentOrmDefinition.definition,
      ],
    ),
  );
  await dataSource.init();

  final user = $User(id: 0, name: 'Author', email: 'author@example.com');
  await dataSource.repo<$User>().insert(user);

  final post = $Post(id: 0, title: 'Test Post', authorId: user.id);
  await dataSource.repo<$Post>().insert(post);

  // Test eager loading
  final users = await dataSource.query<$User>().with_(['posts']).get();
  print('Posts count: ${users.first.posts?.length}');
}
// #endregion testing-relations

// #region testing-parallel
Future<void> parallelTestingExample() async {
  // Unique name per test suite
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  // Each test gets isolated database
}
// #endregion testing-parallel

// #region testing-best-practices-in-memory
// Use SQLite in-memory for unit tests - fast and isolated
void inMemoryBestPractice() {
  // driver: SqliteDriverAdapter.inMemory()
}
// #endregion testing-best-practices-in-memory

// #region testing-best-practices-real-db
// Use Real Databases for Integration Tests - More realistic
void realDbBestPractice() {
  // driver: SqliteDriverAdapter.file('test.db')
}
// #endregion testing-best-practices-real-db

// #region testing-keep-isolated
Future<void> keepTestsIsolated() async {
  late DataSource dataSource;

  // setUp - fresh database for each test
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // test 1 - This test's data won't affect test 2
  // ...

  // test 2 - Starts with clean database
  // ...
}
// #endregion testing-keep-isolated

// #region testing-factories
Future<void> useFactoriesForTestData(DataSource dataSource) async {
  for (var i = 0; i < 100; i++) {
    await Model.factory<User>()
        .seed(i)
        .withField('email', 'user_$i@test.com')
        .create(context: dataSource.context);
  }

  final count = await dataSource.query<$User>().count();
  // expect(count, equals(100));
}
// #endregion testing-factories

// #region testing-success-failure
Future<void> testBothSuccessAndFailure(DataSource dataSource) async {
  // test success case
  await dataSource.repo<$User>().insert(
    $User(id: 0, name: 'Test', email: 'test@example.com'),
  );

  // test failure case - throws on duplicate email
  // expect(
  //   () => dataSource.repo<$User>().insert(
  //     $User(id: 0, name: 'Test2', email: 'test@example.com'),
  //   ),
  //   throwsException,
  // );
}
// #endregion testing-success-failure

// #region testing-example-suite
Future<void> exampleTestSuite() async {
  late DataSource dataSource;

  // #region testing-example-suite-setup
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  // #endregion testing-example-suite-setup

  // #region testing-example-suite-tests

  // group('User model', () {
  //   test('can create user', () async {
  final user = $User(id: 0, name: 'Test', email: 'test@example.com');
  await dataSource.repo<$User>().insert(user);
  // expect(user.id, isNotNull);
  //   });

  //   test('can find user by id', () async {
  final found = await dataSource.query<$User>().find(user.id);
  // expect(found?.email, equals('test@example.com'));
  //   });

  //   test('can update user', () async {
  user.setAttribute('email', 'updated@example.com');
  await dataSource.repo<$User>().update(user);
  final updated = await dataSource.query<$User>().find(user.id);
  // expect(updated?.email, equals('updated@example.com'));
  //   });

  //   test('can delete user', () async {
  await dataSource.repo<$User>().delete(user);
  final deleted = await dataSource.query<$User>().find(user.id);
  // expect(deleted, isNull);
  //   });
  // });

  // #endregion testing-example-suite-tests

  // #region testing-example-suite-teardown
  await dataSource.dispose();
  // #endregion testing-example-suite-teardown
}

// #endregion testing-example-suite
// #region testing-mocking-strategies
// When to mock vs use real DB:
// - Use real DB (in-memory) for repository/query logic
// - Mock external services (email, payment, APIs)
// - Mock time-sensitive operations with fixed timestamps

Future<void> mockingStrategiesExample(DataSource dataSource) async {
  // ✅ Good: Use real DB for data operations
  final user = await Model.factory<User>().create(context: dataSource.context);

  // ✅ Good: Mock external services
  // final emailService = MockEmailService();
  // when(emailService.send(any)).thenAnswer((_) async => true);

  // Avoid mocking DataSource or Repository - use in-memory DB instead
}
// #endregion testing-mocking-strategies

// #region testing-factory-fixtures
// Create reusable fixture helpers with factories

Future<($User, List<$Post>)> createUserWithPosts(
  DataSource dataSource,
  int postCount,
) async {
  final user = $User(id: 0, name: 'Author', email: 'author@test.com');
  final insertedUser = await dataSource.repo<$User>().insert(user);

  final posts = <$Post>[];
  for (var i = 0; i < postCount; i++) {
    final post = $Post(id: 0, title: 'Post $i', authorId: insertedUser.id);
    final insertedPost = await dataSource.repo<$Post>().insert(post);
    posts.add(insertedPost);
  }

  return (insertedUser, posts);
}

Future<void> factoryFixturesExample(DataSource dataSource) async {
  final (user, posts) = await createUserWithPosts(dataSource, 5);
  // expect(posts.length, equals(5));
  // expect(posts.first.authorId, equals(user.id));
}
// #endregion testing-factory-fixtures

// #region testing-transaction-testing
// Test transaction rollback and concurrent access

Future<void> transactionTestingExample(DataSource dataSource) async {
  // Test rollback on error
  try {
    await dataSource.transaction((tx) async {
      final user = $User(id: 0, name: 'Test', email: 'test@example.com');
      await tx.repo<$User>().insert(user);

      // Simulate error
      throw Exception('Rollback test');
    });
  } catch (e) {
    // Transaction rolled back
  }

  // Verify rollback worked
  final count = await dataSource.query<$User>().count();
  // expect(count, equals(0));
}

Future<void> concurrentTransactionExample(DataSource dataSource) async {
  // Test concurrent inserts
  await Future.wait([
    dataSource.transaction((tx) async {
      await tx.repo<$User>().insert(
        $User(id: 0, name: 'User1', email: 'user1@test.com'),
      );
    }),
    dataSource.transaction((tx) async {
      await tx.repo<$User>().insert(
        $User(id: 0, name: 'User2', email: 'user2@test.com'),
      );
    }),
  ]);

  final count = await dataSource.query<$User>().count();
  // expect(count, equals(2));
}
// #endregion testing-transaction-testing

// #region testing-relationship-testing
// Test eager loading, lazy loading, and N+1 prevention

Future<void> eagerLoadingTest(DataSource dataSource) async {
  final (user, _) = await createUserWithPosts(dataSource, 3);

  // Eager load posts
  final users = await dataSource.query<$User>().with_(['posts']).get();

  // Access posts without additional query
  final posts = users.first.posts;
  // expect(posts?.length, equals(3));
}

Future<void> lazyLoadingTest(DataSource dataSource) async {
  final (user, _) = await createUserWithPosts(dataSource, 2);

  // Query without eager loading
  final foundUser = await dataSource.query<$User>().find(user.id);

  // Posts would need separate query (lazy loading)
  final posts = await dataSource
      .query<$Post>()
      .whereEquals('author_id', user.id)
      .get();
  // expect(posts.length, equals(2));
}

Future<void> n1PreventionTest(DataSource dataSource) async {
  // Create multiple users with posts
  for (var i = 0; i < 3; i++) {
    await createUserWithPosts(dataSource, 2);
  }

  // ❌ Bad: N+1 problem - 1 query for users + N queries for posts
  // final users = await dataSource.query<$User>().get();
  // for (final user in users) {
  //   final posts = await dataSource.query<$Post>()
  //     .whereEquals('author_id', user.id)
  //     .get();
  // }

  // ✅ Good: Single query with eager loading
  final users = await dataSource.query<$User>().with_(['posts']).get();
  // expect(users.length, equals(3));
  // expect(users.first.posts?.length, equals(2));
}
// #endregion testing-relationship-testing

// #region testing-validation-errors
// Test constraint violations and error handling

Future<void> uniqueConstraintTest(DataSource dataSource) async {
  final user1 = $User(id: 0, name: 'Test', email: 'unique@test.com');
  await dataSource.repo<$User>().insert(user1);

  // Attempt duplicate email (should throw)
  final user2 = $User(id: 0, name: 'Test2', email: 'unique@test.com');
  try {
    await dataSource.repo<$User>().insert(user2);
    // Should not reach here
  } catch (e) {
    // expect(e, isA<DatabaseException>());
  }
}

Future<void> foreignKeyConstraintTest(DataSource dataSource) async {
  // Attempt to insert post with invalid user_id
  final post = $Post(id: 0, title: 'Test', authorId: 9999);

  try {
    await dataSource.repo<$Post>().insert(post);
    // Should not reach here if FK constraints enabled
  } catch (e) {
    // expect(e, isA<DatabaseException>());
  }
}

Future<void> notNullConstraintTest(DataSource dataSource) async {
  // Attempt to insert null into required field
  try {
    await dataSource.repo<$User>().insert($User(id: 0, name: '', email: ''));
  } catch (e) {
    // Validation or constraint error
  }
}
// #endregion testing-validation-errors

// #region testing-performance
// Benchmark queries and detect N+1 issues

Future<void> benchmarkQueryTest(DataSource dataSource) async {
  // Seed large dataset
  for (var i = 0; i < 1000; i++) {
    await dataSource.repo<$User>().insert(
      $User(id: 0, name: 'User$i', email: 'user$i@test.com'),
    );
  }

  // Benchmark query performance
  final stopwatch = Stopwatch()..start();
  final users = await dataSource.query<$User>().limit(100).get();
  stopwatch.stop();

  // expect(stopwatch.elapsedMilliseconds, lessThan(100));
  // expect(users.length, equals(100));
}

Future<void> detectN1Test(DataSource dataSource) async {
  // Track query count
  var queryCount = 0;

  // Create test data
  for (var i = 0; i < 10; i++) {
    await createUserWithPosts(dataSource, 5);
  }

  // With eager loading: 1 query
  queryCount = 0;
  await dataSource.query<$User>().with_(['posts']).get();
  // expect(queryCount, equals(1)); // or small constant

  // Without eager loading: N+1 queries (1 + 10)
  queryCount = 0;
  final users = await dataSource.query<$User>().get();
  for (final user in users) {
    await dataSource.query<$Post>().whereEquals('author_id', user.id).get();
  }
  // expect(queryCount, equals(11)); // 1 + 10
}
// #endregion testing-performance

// #region testing-data-integrity
// Test foreign key cascades and integrity constraints

Future<void> cascadeDeleteTest(DataSource dataSource) async {
  final (user, posts) = await createUserWithPosts(dataSource, 3);

  // Delete user (should cascade to posts if configured)
  await dataSource.repo<$User>().delete(user);

  // Verify cascade worked
  final remainingPosts = await dataSource
      .query<$Post>()
      .whereEquals('author_id', user.id)
      .get();
  // expect(remainingPosts, isEmpty);
}

Future<void> referentialIntegrityTest(DataSource dataSource) async {
  final user = $User(id: 0, name: 'Author', email: 'author@test.com');
  await dataSource.repo<$User>().insert(user);

  final post = $Post(id: 0, title: 'Test', authorId: user.id);
  await dataSource.repo<$Post>().insert(post);

  // Attempt to delete user with existing posts (should fail if no cascade)
  try {
    await dataSource.repo<$User>().delete(user);
    // May throw if FK constraint prevents deletion
  } catch (e) {
    // expect(e, isA<DatabaseException>());
  }
}
// #endregion testing-data-integrity

// #region testing-cleanup-strategies
// Different cleanup approaches for test isolation

Future<void> transactionRollbackCleanup(DataSource dataSource) async {
  // Strategy 1: Transaction rollback (fastest)
  // Use DatabaseIsolationStrategy.migrateWithTransactions in setUpOrmed
  await dataSource.transaction((tx) async {
    // All test operations in transaction
    await tx.repo<$User>().insert(
      $User(id: 0, name: 'Test', email: 'test@example.com'),
    );
    // Auto-rolled back after test
  });
}

Future<void> truncateCleanup(DataSource dataSource) async {
  // Strategy 2: Truncate tables (moderate speed)
  // Use DatabaseIsolationStrategy.truncate in setUpOrmed
  // Runs after each test to clear all data

  // Manual truncate example:
  await dataSource.execute('DELETE FROM users');
  await dataSource.execute('DELETE FROM posts');
  await dataSource.execute('DELETE FROM comments');
}

Future<void> recreateCleanup() async {
  // Strategy 3: Recreate database (slowest, most thorough)
  // Use DatabaseIsolationStrategy.recreate in setUpOrmed
  // Drops and recreates entire schema for each test

  late DataSource dataSource;
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  // Complete isolation, but slower
  await dataSource.dispose();
}

// #endregion testing-cleanup-strategies
