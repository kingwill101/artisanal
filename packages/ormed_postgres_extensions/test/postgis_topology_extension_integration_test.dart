import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_postgres_extensions/ormed_postgres_extensions.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final postgisUrl = Platform.environment['POSTGIS_URL'];
  if (postgisUrl == null) {
    group('PostGIS topology extensions', () {
      test('requires POSTGIS_URL', () {}, skip: 'POSTGIS_URL not set');
    });
    return;
  }

  PostgresDriverAdapter.registerCodecs();

  final registry = ModelRegistry();

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'ormed_postgres_extensions_postgis_topology_base',
      driver: PostgresDriverAdapter.fromUrl(postgisUrl),
      entities: const [],
      registry: registry,
      driverExtensions: const [PostgisTopologyExtensions()],
      logging: true,
    ),
  );
  await dataSource.init();

  final config = setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: [
      MigrationDescriptor.fromMigration(
        id: MigrationId(
          DateTime.utc(2025, 1, 1, 0, 0, 4),
          'postgis_topology_extension',
        ),
        migration: const _CreateTopologyExtension(),
      ),
    ],
    strategy: DatabaseIsolationStrategy.recreate,
    adapterFactory: (_) => PostgresDriverAdapter.custom(
      config: DatabaseConfig(driver: 'postgres', options: {'url': postgisUrl}),
    ),
  );

  tearDownAll(() async {
    await dataSource.dispose();
  });

  ormedGroup('PostGIS topology extensions', (scopedDataSource) {
    setUp(() async {
      final driver = scopedDataSource.options.driver;
      await driver.executeRaw('INSERT INTO topology_items DEFAULT VALUES');
    });

    test('creates and drops topology', () async {
      final schemaName = scopedDataSource.options.defaultSchema ?? 'public';
      final topologyName = 'ormed_topology_${schemaName.replaceAll('-', '_')}';
      final driver = scopedDataSource.options.driver;

      await _dropTopology(driver, topologyName);

      final rows = await scopedDataSource.context
          .table('topology_items')
          .selectPostgisTopologyCreate(
            PostgisTopologyCreatePayload(name: topologyName, srid: 4326),
            alias: 'topology_id',
          )
          .limit(1)
          .rows();

      expect(rows.first.row['topology_id'], isNotNull);

      await _dropTopology(driver, topologyName);
    });
  }, config: config);
}

Future<void> _dropTopology(DriverAdapter driver, String name) async {
  final escapedName = name.replaceAll("'", "''");
  await driver.executeRaw('''
DO \$\$
BEGIN
  PERFORM topology.DropTopology('$escapedName');
EXCEPTION WHEN OTHERS THEN
  NULL;
END \$\$;
''');
}

class _CreateTopologyExtension extends Migration {
  const _CreateTopologyExtension();

  @override
  void up(SchemaBuilder schema) {
    schema.raw('CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public');
    schema.raw(
      'CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA public',
    );
    schema.raw('''
CREATE TABLE topology_items (
  id SERIAL PRIMARY KEY
)
''');
  }

  @override
  void down(SchemaBuilder schema) {
    schema.raw('DROP TABLE IF EXISTS topology_items');
  }
}
