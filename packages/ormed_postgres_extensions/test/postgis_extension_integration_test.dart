import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres_extensions/ormed_postgres_extensions.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final postgisUrl = Platform.environment['POSTGIS_URL'];
  if (postgisUrl == null) {
    group('PostGIS extensions', () {
      test('requires POSTGIS_URL', () {}, skip: 'POSTGIS_URL not set');
    });
    return;
  }

  PostgresDriverAdapter.registerCodecs();

  final registry = ModelRegistry();
  registry.registerAll([_placeDefinition]);

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'ormed_postgres_extensions_postgis_base',
      driver: PostgresDriverAdapter.fromUrl(postgisUrl),
      entities: [_placeDefinition],
      registry: registry,
      driverExtensions: const [PostgisExtensions()],
      logging: true,
    ),
  );
  await dataSource.init();

  final config = setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: [
      MigrationDescriptor.fromMigration(
        id: MigrationId(DateTime.utc(2025, 1, 1, 0, 0, 1), 'postgis_places'),
        migration: const _CreatePostgisPlaces(),
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

  ormedGroup('PostGIS extensions', (scopedDataSource) {
    setUp(() async {
      await scopedDataSource.options.driver.executeRaw('''
INSERT INTO places (name, location)
VALUES
  ('origin', ST_SetSRID(ST_MakePoint(0, 0), 4326)),
  ('nearby', ST_SetSRID(ST_MakePoint(0.01, 0), 4326)),
  ('far', ST_SetSRID(ST_MakePoint(1, 0), 4326))
''');
    });

    test('within-radius filter, distance order, and geojson select', () async {
      final origin = const PostgisPoint(longitude: 0, latitude: 0);
      final withinPayload = PostgisWithinPayload(
        column: 'location',
        point: origin,
        meters: 2000,
      );
      final distancePayload = PostgisDistancePayload(
        column: 'location',
        point: origin,
      );
      final geoPayload = const PostgisGeoJsonPayload(column: 'location');

      final rows = await scopedDataSource
          .query<AdHocRow>()
          .select(['id', 'name'])
          .selectPostgisGeoJson(geoPayload, alias: 'location_geojson')
          .wherePostgisWithin(withinPayload)
          .orderByPostgisDistance(distancePayload)
          .rows();

      expect(rows, hasLength(2));
      expect(rows.first.row['name'], 'origin');
      expect(rows.last.row['name'], 'nearby');
      expect(rows.first.row['location_geojson'], isA<String>());
    });
  }, config: config);
}

final ModelDefinition<AdHocRow> _placeDefinition = ModelDefinition<AdHocRow>(
  modelName: 'Place',
  tableName: 'places',
  codec: _PlaceCodec(),
  fields: [
    FieldDefinition(
      name: 'id',
      columnName: 'id',
      dartType: 'int',
      resolvedType: 'int',
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      isIndexed: true,
      autoIncrement: true,
    ),
    FieldDefinition(
      name: 'name',
      columnName: 'name',
      dartType: 'String',
      resolvedType: 'String',
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      isIndexed: false,
      autoIncrement: false,
    ),
    FieldDefinition(
      name: 'location',
      columnName: 'location',
      dartType: 'Object?',
      resolvedType: 'Object?',
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      isIndexed: false,
      autoIncrement: false,
    ),
  ],
);

class _PlaceCodec extends ModelCodec<AdHocRow> {
  const _PlaceCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}

class _CreatePostgisPlaces extends Migration {
  const _CreatePostgisPlaces();

  @override
  void up(SchemaBuilder schema) {
    schema.raw('CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public');
    schema.raw('''
CREATE TABLE places (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  location geometry(Point, 4326) NOT NULL
)
''');
  }

  @override
  void down(SchemaBuilder schema) {
    schema.raw('DROP TABLE IF EXISTS places');
  }
}
