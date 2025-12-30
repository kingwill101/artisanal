import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_postgres_extensions/ormed_postgres_extensions.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final postgisUrl = Platform.environment['POSTGIS_URL'];
  if (postgisUrl == null) {
    group(
      'PostGIS raster extensions',
      () {
        test('requires POSTGIS_URL', () {}, skip: 'POSTGIS_URL not set');
      },
    );
    return;
  }

  PostgresDriverAdapter.registerCodecs();

  final registry = ModelRegistry();

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'ormed_postgres_extensions_postgis_raster_base',
      driver: PostgresDriverAdapter.fromUrl(postgisUrl),
      entities: const [],
      registry: registry,
      driverExtensions: const [PostgisRasterExtensions()],
      logging: true,
    ),
  );
  await dataSource.init();

  final config = setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: [
      MigrationDescriptor.fromMigration(
        id: MigrationId(
          DateTime.utc(2025, 1, 1, 0, 0, 5),
          'postgis_raster_extension',
        ),
        migration: const _CreateRasterExtension(),
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

  ormedGroup(
    'PostGIS raster extensions',
    (scopedDataSource) {
      setUp(() async {
        final driver = scopedDataSource.options.driver;
        await driver.executeRaw('''
INSERT INTO raster_items (rast)
VALUES (
  ST_AddBand(
    ST_MakeEmptyRaster(1, 1, 0, 0, 1, -1, 0, 0, 4326),
    '8BUI'::text,
    0,
    0
  )
)
''');
      });

      test('reads raster dimensions', () async {
        final rows = await scopedDataSource.context
            .table('raster_items')
            .selectPostgisRasterWidth(
              const PostgisRasterDimensionPayload(column: 'rast'),
              alias: 'width',
            )
            .selectPostgisRasterHeight(
              const PostgisRasterDimensionPayload(column: 'rast'),
              alias: 'height',
            )
            .limit(1)
            .rows();

        expect(rows.first.row['width'], anyOf(1, 1.0));
        expect(rows.first.row['height'], anyOf(1, 1.0));
      });
    },
    config: config,
  );
}

class _CreateRasterExtension extends Migration {
  const _CreateRasterExtension();

  @override
  void up(SchemaBuilder schema) {
    schema.raw('CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public');
    schema.raw('CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public');
    schema.raw('''
CREATE TABLE raster_items (
  id SERIAL PRIMARY KEY,
  rast raster NOT NULL
)
''');
  }

  @override
  void down(SchemaBuilder schema) {
    schema.raw('DROP TABLE IF EXISTS raster_items');
  }
}
