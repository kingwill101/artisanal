import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

/// Test demonstrating ormedGroup usage
Future<void> main() async {
  // Register SQLite-specific codecs before using SQLite
  SqliteDriverAdapter.registerCodecs();

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test_orm_helpers',
      driver: SqliteDriverAdapter.inMemory(),
      registry: buildOrmRegistry(),
    ),
  );

  await dataSource.init();

  setUpOrmed(
    dataSource: dataSource,
    adapterFactory: (dbName) => SqliteDriverAdapter.file(dbName),
    migrations: [CreateUsersTable()],
  );
  await dataSource.init();

  ormedGroup('User CRUD operations with migrate', (ds) {
    test('can create and retrieve users', () async {
      final user = await ds.repo<ActiveUser>().insert(
        ActiveUser(name: 'Alice', email: 'alice@test.com'),
      );

      expect(user.id, isNotNull);
      expect(user.name, equals('Alice'));

      final count = await ds.query<ActiveUser>().count();
      expect(count, equals(1));
    });

    test('can update users', () async {
      final user = await ds.repo<ActiveUser>().insert(
        ActiveUser(name: 'Bob', email: 'bob@test.com'),
      );
      final userId = user.id!;

      // Update via updateMany
      final updated = ActiveUser(
        id: userId,
        name: 'Bob Updated',
        email: user.email,
      );
      await ds.repo<ActiveUser>().updateMany([updated]);

      final count = await ds
          .query<ActiveUser>()
          .whereEquals('name', 'Bob Updated')
          .count();
      expect(count, equals(1));
    });

    test('can delete users', () async {
      final user = await ds.repo<ActiveUser>().insert(
        ActiveUser(name: 'Charlie', email: 'charlie@test.com'),
      );
      final userId = user.id!;

      await ds.repo<ActiveUser>().deleteByKeys([
        {'id': userId},
      ]);

      final count = await ds
          .query<ActiveUser>()
          .whereEquals('id', userId)
          .count();
      expect(count, equals(0));
    });
  });

  ormedGroup('Database refresh strategies', (ds) {
    test('changes persist within test', () async {
      final user = await ds.repo<ActiveUser>().insert(
        ActiveUser(name: 'Temporary', email: 'temp@test.com'),
      );

      expect(user.id, isNotNull);

      final count = await ds.query<ActiveUser>().count();
      expect(count, equals(1));
    });

    test('database is clean in next test', () async {
      // With truncate strategy, previous test's data is cleared
      final count = await ds.query<ActiveUser>().count();
      expect(count, equals(0));
    });
  });
}

// Sample migration
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
