import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_postgres_extensions/ormed_postgres_extensions.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final pgvectorUrl = Platform.environment['PGVECTOR_URL'];
  if (pgvectorUrl == null) {
    group(
      'pgvector extensions',
      () {
        test('requires PGVECTOR_URL', () {}, skip: 'PGVECTOR_URL not set');
      },
    );
    return;
  }

  PostgresDriverAdapter.registerCodecs();

  final registry = ModelRegistry();
  registry.registerAll([_itemDefinition]);

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'ormed_postgres_extensions_pgvector_base',
      driver: PostgresDriverAdapter.fromUrl(pgvectorUrl),
      entities: [_itemDefinition],
      registry: registry,
      driverExtensions: const [PgvectorExtensions()],
      logging: true,
    ),
  );
  await dataSource.init();

  final config = setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: [
      MigrationDescriptor.fromMigration(
        id: MigrationId(DateTime.utc(2025, 1, 1, 0, 0, 2), 'pgvector_items'),
        migration: const _CreatePgvectorItems(),
      ),
    ],
    strategy: DatabaseIsolationStrategy.recreate,
    adapterFactory: (_) => PostgresDriverAdapter.custom(
      config: DatabaseConfig(driver: 'postgres', options: {'url': pgvectorUrl}),
    ),
  );

  tearDownAll(() async {
    await dataSource.dispose();
  });

  ormedGroup(
    'pgvector extensions',
    (scopedDataSource) {
      setUp(() async {
        await scopedDataSource.options.driver.executeRaw(
          '''
INSERT INTO items (name, embedding)
VALUES
  ('origin', '[0,0,0]'),
  ('nearby', '[0.1,0.1,0.1]'),
  ('far', '[2,2,2]')
''',
        );
      });

      test('orders and filters by vector distance', () async {
        final origin = const [0.0, 0.0, 0.0];
        final withinPayload = PgvectorWithinPayload(
          column: 'embedding',
          vector: origin,
          maxDistance: 0.5,
          metric: PgvectorDistanceMetric.l2,
        );
        final distancePayload = PgvectorDistancePayload(
          column: 'embedding',
          vector: origin,
          metric: PgvectorDistanceMetric.l2,
        );

        final rows = await scopedDataSource
            .query<AdHocRow>()
            .select(['id', 'name'])
            .wherePgvectorWithin(withinPayload)
            .orderByPgvectorDistance(distancePayload)
            .rows();

        expect(rows, hasLength(2));
        expect(rows.first.row['name'], 'origin');
        expect(rows.last.row['name'], 'nearby');
      });
    },
    config: config,
  );
}

final ModelDefinition<AdHocRow> _itemDefinition = ModelDefinition<AdHocRow>(
  modelName: 'Item',
  tableName: 'items',
  codec: _ItemCodec(),
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
      name: 'embedding',
      columnName: 'embedding',
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

class _ItemCodec extends ModelCodec<AdHocRow> {
  const _ItemCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}

class _CreatePgvectorItems extends Migration {
  const _CreatePgvectorItems();

  @override
  void up(SchemaBuilder schema) {
    schema.raw('CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public');
    schema.raw('''
CREATE TABLE items (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  embedding vector(3) NOT NULL
)
''');
  }

  @override
  void down(SchemaBuilder schema) {
    schema.raw('DROP TABLE IF EXISTS items');
  }
}
