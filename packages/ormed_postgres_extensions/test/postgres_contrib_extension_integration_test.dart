import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_postgres_extensions/ormed_postgres_extensions.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final contribUrl = Platform.environment['POSTGRES_EXT_URL'];
  if (contribUrl == null) {
    group('Postgres contrib extensions', () {
      test(
        'requires POSTGRES_EXT_URL',
        () {},
        skip: 'POSTGRES_EXT_URL not set',
      );
    });
    return;
  }

  PostgresDriverAdapter.registerCodecs();

  final registry = ModelRegistry();

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'ormed_postgres_extensions_contrib_base',
      driver: PostgresDriverAdapter.fromUrl(contribUrl),
      entities: const [],
      registry: registry,
      driverExtensions: const [
        PgTrgmExtensions(),
        HstoreExtensions(),
        LtreeExtensions(),
        CitextExtensions(),
        UuidOsspExtensions(),
        PgcryptoExtensions(),
      ],
      logging: true,
    ),
  );
  await dataSource.init();

  final config = setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: [
      MigrationDescriptor.fromMigration(
        id: MigrationId(
          DateTime.utc(2025, 1, 1, 0, 0, 3),
          'postgres_contrib_extensions',
        ),
        migration: const _CreateContribExtensions(),
      ),
    ],
    strategy: DatabaseIsolationStrategy.recreate,
    adapterFactory: (_) => PostgresDriverAdapter.custom(
      config: DatabaseConfig(driver: 'postgres', options: {'url': contribUrl}),
    ),
  );

  tearDownAll(() async {
    await dataSource.dispose();
  });

  ormedGroup('Postgres contrib extensions', (scopedDataSource) {
    setUp(() async {
      final driver = scopedDataSource.options.driver;
      await driver.executeRaw(
        "INSERT INTO trgm_items (name) VALUES ('hello'), ('hallo'), ('world')",
      );
      await driver.executeRaw(
        "INSERT INTO hstore_items (attributes) VALUES (hstore(ARRAY['color','size'], ARRAY['blue','large']))",
      );
      await driver.executeRaw(
        "INSERT INTO ltree_items (path) VALUES ('Top.Science.Astronomy'), ('Top.Science')",
      );
      await driver.executeRaw(
        "INSERT INTO citext_items (email) VALUES ('Test@Example.com')",
      );
    });

    test('pg_trgm similarity filter and order', () async {
      final rows = await scopedDataSource.context
          .table('trgm_items')
          .select(['name'])
          .wherePgTrgmSimilarity(
            const PgTrgmSimilarityPayload(
              column: 'name',
              value: 'hello',
              threshold: 0.2,
            ),
          )
          .orderByPgTrgmSimilarity(
            const PgTrgmOrderPayload(column: 'name', value: 'hello'),
          )
          .rows();

      expect(rows, isNotEmpty);
      expect(rows.any((row) => row.row['name'] == 'hello'), isTrue);
    });

    test('hstore key lookup and contains', () async {
      final hasKeyRows = await scopedDataSource.context
          .table('hstore_items')
          .whereHstoreHasKey(
            const HstoreHasKeyPayload(column: 'attributes', key: 'color'),
          )
          .rows();

      expect(hasKeyRows, hasLength(1));

      final containsRows = await scopedDataSource.context
          .table('hstore_items')
          .whereHstoreContains(
            const HstoreContainsPayload(
              column: 'attributes',
              entries: {'color': 'blue'},
            ),
          )
          .rows();

      expect(containsRows, hasLength(1));

      final getRows = await scopedDataSource.context
          .table('hstore_items')
          .selectHstoreGet(
            const HstoreGetPayload(column: 'attributes', key: 'size'),
            alias: 'size',
          )
          .rows();

      expect(getRows.first.row['size'], 'large');
    });

    test('ltree contains and matches', () async {
      final containsRows = await scopedDataSource.context
          .table('ltree_items')
          .whereLtreeContains(
            const LtreeContainsPayload(column: 'path', path: 'Top.Science'),
          )
          .rows();

      expect(containsRows, hasLength(2));

      final matchRows = await scopedDataSource.context
          .table('ltree_items')
          .whereLtreeMatches(
            const LtreeMatchesPayload(column: 'path', query: 'Top.*{1,2}'),
          )
          .rows();

      expect(matchRows, hasLength(2));
    });

    test('citext equals is case-insensitive', () async {
      final rows = await scopedDataSource.context
          .table('citext_items')
          .whereCitextEquals(
            const CitextEqualsPayload(
              column: 'email',
              value: 'test@example.com',
            ),
          )
          .rows();

      expect(rows, hasLength(1));
    });

    test('uuid-ossp generates uuids', () async {
      final rows = await scopedDataSource.context
          .table('citext_items')
          .selectUuidOsspV4(alias: 'uuid_v4')
          .limit(1)
          .rows();

      expect(rows.first.row['uuid_v4'], isNotNull);
    });

    test('pgcrypto digest and uuid', () async {
      final digestRows = await scopedDataSource.context
          .table('citext_items')
          .selectPgcryptoDigest(
            const PgcryptoDigestPayload(value: 'hello', algorithm: 'sha256'),
            alias: 'digest',
          )
          .limit(1)
          .rows();

      final digest = digestRows.first.row['digest'];
      expect(digest, isA<String>());
      expect((digest as String).length, 64);

      final uuidRows = await scopedDataSource.context
          .table('citext_items')
          .selectPgcryptoGenRandomUuid(alias: 'uuid_pgcrypto')
          .limit(1)
          .rows();

      expect(uuidRows.first.row['uuid_pgcrypto'], isNotNull);
    });
  }, config: config);
}

class _CreateContribExtensions extends Migration {
  const _CreateContribExtensions();

  @override
  void up(SchemaBuilder schema) {
    schema.raw('CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public');
    schema.raw('CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public');
    schema.raw('CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public');
    schema.raw('CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public');
    schema.raw('CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public');
    schema.raw('CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public');

    schema.raw('''
CREATE TABLE trgm_items (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
)
''');
    schema.raw('''
CREATE TABLE hstore_items (
  id SERIAL PRIMARY KEY,
  attributes hstore NOT NULL
)
''');
    schema.raw('''
CREATE TABLE ltree_items (
  id SERIAL PRIMARY KEY,
  path ltree NOT NULL
)
''');
    schema.raw('''
CREATE TABLE citext_items (
  id SERIAL PRIMARY KEY,
  email citext NOT NULL
)
''');
  }

  @override
  void down(SchemaBuilder schema) {
    schema.raw('DROP TABLE IF EXISTS citext_items');
    schema.raw('DROP TABLE IF EXISTS ltree_items');
    schema.raw('DROP TABLE IF EXISTS hstore_items');
    schema.raw('DROP TABLE IF EXISTS trgm_items');
  }
}
