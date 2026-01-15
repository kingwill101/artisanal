import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed/testing.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  final ModelRegistry registry = bootstrapOrm();

  registerOrmFactories();
  SqliteDriverAdapter.registerCodecs();

  final primaryDataSource = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: SqliteDriverAdapter.inMemory(),
      registry: registry,
    ),
  );

  final analyticsDataSource = DataSource(
    DataSourceOptions(
      name: 'analytics',
      driver: SqliteDriverAdapter.inMemory(),
      registry: registry,
    ),
  );

  final primaryConfig = setUpOrmed(
    dataSource: primaryDataSource,
    migrations: const [_CreateActiveUsersTable()],
    adapterFactory: (_) => SqliteDriverAdapter.inMemory(),
  );

  final analyticsConfig = setUpOrmed(
    dataSource: analyticsDataSource,
    migrations: const [_CreateActiveUsersTable()],
    adapterFactory: (_) => SqliteDriverAdapter.inMemory(),
  );

  ormedGroup('primary connection isolation', (ds) {
    ormedTest('primary writes stay on primary connection', (db) async {
      await db.repo<ActiveUser>().insert(
        const ActiveUser(email: 'primary@example.com', name: 'Primary'),
      );

      final primaryUsers = await db.query<ActiveUser>().get();
      expect(primaryUsers, hasLength(1));

      final analyticsConn = ConnectionManager.instance.connection('analytics');
      final analyticsRows = await analyticsConn.query<ActiveUser>().get();
      expect(analyticsRows, isEmpty);
    });
  }, config: primaryConfig);

  ormedGroup('analytics connection isolation', (ds) {
    ormedTest('analytics writes stay on analytics connection', (db) async {
      await db.repo<ActiveUser>().insert(
        const ActiveUser(email: 'analytics@example.com', name: 'Analytics'),
      );

      final analyticsUsers = await db.query<ActiveUser>().get();
      expect(analyticsUsers, hasLength(1));

      final primaryConn = ConnectionManager.instance.connection('primary');
      final primaryRows = await primaryConn.query<ActiveUser>().get();
      expect(primaryRows, isEmpty);
    });

    ormedTest('connection manager routes by name without conflicts', (db) async {
      final analyticsConn = ConnectionManager.instance.connection('analytics');
      final primaryConn = ConnectionManager.instance.connection('primary');

      expect(analyticsConn.name, 'analytics');
      expect(primaryConn.name, 'primary');

      await analyticsConn.repository<ActiveUser>().insert(
        const ActiveUser(
          email: 'analytics-second@example.com',
          name: 'Analytics v2',
        ),
      );

      expect(await analyticsConn.query<ActiveUser>().count(), 1);
      expect(await primaryConn.query<ActiveUser>().get(), isEmpty);
    });
  }, config: analyticsConfig);

  test('connection manager usage without ormedGroup stays isolated', () async {
    final primaryConn = ConnectionManager.instance.connection('primary');
    final analyticsConn = ConnectionManager.instance.connection('analytics');

    await primaryConn.driver.executeRaw('DELETE FROM active_users');
    await analyticsConn.driver.executeRaw('DELETE FROM active_users');

    await primaryConn.repository<ActiveUser>().insert(
      const ActiveUser(
        email: 'manual-primary@example.com',
        name: 'Manual Primary',
      ),
    );
    await analyticsConn.repository<ActiveUser>().insert(
      const ActiveUser(
        email: 'manual-analytics@example.com',
        name: 'Manual Analytics',
      ),
    );

    final primaryResults = await primaryConn.query<ActiveUser>().get();
    final analyticsResults = await analyticsConn.query<ActiveUser>().get();

    expect(primaryResults, hasLength(1));
    expect(analyticsResults, hasLength(1));
    expect(primaryResults.first.email, 'manual-primary@example.com');
    expect(analyticsResults.first.email, 'manual-analytics@example.com');
  });
}

class _CreateActiveUsersTable extends Migration {
  const _CreateActiveUsersTable();

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('active_users', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('email').unique();
      table.string('name').nullable();
      table.json('settings');
      table.timestamp('deleted_at').nullable();
      table.timestamp('created_at').nullable();
      table.timestamp('updated_at').nullable();
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('active_users', ifExists: true);
  }
}
