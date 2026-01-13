import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

/// Test demonstrating nested transaction support (savepoints)
void main() {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'nested_transactions_test',
      driver: SqliteDriverAdapter.inMemory(),
      registry: buildOrmRegistry(),
    ),
  );

  setUpAll(() async {
    await dataSource.init();

    // Run migrations
    final migration = CreateUsersTable();
    final plan = migration.plan(MigrationDirection.up);
    final schemaDriver = dataSource.connection.driver as SchemaDriver;
    await schemaDriver.applySchemaPlan(plan);
  });

  tearDown(() async {
    // Clean up all data after each test
    await dataSource.connection.driver.executeRaw(
      'DELETE FROM active_users',
      [],
    );
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  test('nested transaction with savepoint rollback', () async {
    await dataSource.beginTransaction();

    // Insert user in outer transaction
    await dataSource.repo<ActiveUser>().insert(
      ActiveUser(name: 'User1', email: 'user1@example.com'),
    );

    // Begin nested transaction (creates savepoint)
    await dataSource.beginTransaction();

    // Insert user in nested transaction
    await dataSource.repo<ActiveUser>().insert(
      ActiveUser(name: 'User2', email: 'user2@example.com'),
    );

    // Both should exist
    var count = await dataSource.query<ActiveUser>().count();
    expect(count, 2);

    // Rollback nested transaction (rollback to savepoint)
    await dataSource.rollback();

    // Only outer transaction user should remain
    count = await dataSource.query<ActiveUser>().count();
    expect(count, 1);

    // Commit outer transaction
    await dataSource.commit();

    // User1 should still exist
    count = await dataSource.query<ActiveUser>().count();
    expect(count, 1);
  });

  test('nested transaction with savepoint commit', () async {
    await dataSource.beginTransaction();

    // Insert user in outer transaction
    await dataSource.repo<ActiveUser>().insert(
      ActiveUser(name: 'User3', email: 'user3@example.com'),
    );

    // Begin nested transaction (creates savepoint)
    await dataSource.beginTransaction();

    // Insert user in nested transaction
    await dataSource.repo<ActiveUser>().insert(
      ActiveUser(name: 'User4', email: 'user4@example.com'),
    );

    // Commit nested transaction (release savepoint)
    await dataSource.commit();

    // Both should exist
    var count = await dataSource.query<ActiveUser>().count();
    expect(count, 2);

    // Commit outer transaction
    await dataSource.commit();

    // Both should still exist
    count = await dataSource.query<ActiveUser>().count();
    expect(count, 2);
  });

  test('multiple nested levels', () async {
    await dataSource.beginTransaction(); // Level 1

    await dataSource.repo<ActiveUser>().insert(
      ActiveUser(name: 'Level1', email: 'level1@example.com'),
    );

    await dataSource.beginTransaction(); // Level 2

    await dataSource.repo<ActiveUser>().insert(
      ActiveUser(name: 'Level2', email: 'level2@example.com'),
    );

    await dataSource.beginTransaction(); // Level 3

    await dataSource.repo<ActiveUser>().insert(
      ActiveUser(name: 'Level3', email: 'level3@example.com'),
    );

    // All three should exist
    var count = await dataSource.query<ActiveUser>().count();
    expect(count, 3);

    // Rollback level 3
    await dataSource.rollback();

    count = await dataSource.query<ActiveUser>().count();
    expect(count, 2);

    // Commit level 2
    await dataSource.commit();

    count = await dataSource.query<ActiveUser>().count();
    expect(count, 2);

    // Commit level 1
    await dataSource.commit();

    count = await dataSource.query<ActiveUser>().count();
    expect(count, 2);
  });

  test('cannot commit without active transaction', () {
    expect(() async => await dataSource.commit(), throwsA(isA<StateError>()));
  });

  test('cannot rollback without active transaction', () {
    expect(() async => await dataSource.rollback(), throwsA(isA<StateError>()));
  });
}

class CreateUsersTable extends Migration {
  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('active_users', (table) {
      table.id();
      table.string('name').nullable();
      table.string('email');
      table.json('settings');
      table.timestamp('deleted_at').nullable();
      table.timestamps();
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('active_users');
  }
}
