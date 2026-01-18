import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  late SqliteDriverAdapter adapter;
  late OrmConnection connection;
  late QueryContext context;

  const table = 'orm_cache_invalidation';
  const columns = [
    AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
    AdHocColumn(name: 'name', columnName: 'name'),
  ];

  setUpAll(() async {
    adapter = SqliteDriverAdapter.inMemory();
    connection = OrmConnection(
      config: ConnectionConfig(
        name: 'cache_invalidation_sqlite',
        options: const {
          'cacheInvalidationPolicy': 'flushOnWrite',
        },
      ),
      driver: adapter,
      registry: ModelRegistry(),
    );
    context = connection.context;

    await adapter.executeRaw('DROP TABLE IF EXISTS $table');
    await adapter.executeRaw(
      'CREATE TABLE $table (id INTEGER PRIMARY KEY, name TEXT)',
    );
    await adapter.executeRaw(
      'INSERT INTO $table (id, name) VALUES (?, ?)',
      [1, 'alpha'],
    );
  });

  tearDownAll(() async {
    await adapter.executeRaw('DROP TABLE IF EXISTS $table');
    await adapter.close();
  });

  test('flushOnWrite invalidates cached results after mutations', () async {
    context.flushQueryCache();

    await context
        .table(table, columns: columns)
        .remember(const Duration(minutes: 5))
        .get();
    expect(context.queryCacheStats.totalEntries, greaterThan(0));

    await context
        .table(table, columns: columns)
        .whereEquals('id', 1)
        .update({'name': 'beta'});

    expect(context.queryCacheStats.totalEntries, equals(0));
  });
}
