# ormed_postgres_extensions

Postgres extension handlers for Ormed using the driver extension system.

## Usage

### PostGIS

```dart
final dataSource = DataSource(
  DataSourceOptions(
    driver: PostgresDriverAdapter.fromUrl(env['POSTGRES_URL']!),
    driverExtensions: const [PostgisExtensions()],
    entities: registry.allDefinitions,
  ),
);

final payload = PostgisWithinPayload(
  column: 'location',
  point: const PostgisPoint(longitude: -122.4194, latitude: 37.7749),
  meters: 1500,
);

final preview = dataSource.query<Place>()
  .wherePostgisWithin(payload)
  .orderByPostgisDistance(
    PostgisDistancePayload(
      column: 'location',
      point: payload.point,
    ),
  )
  .selectPostgisGeoJson(
    const PostgisGeoJsonPayload(column: 'location'),
    alias: 'location_geojson',
  )
  .toSql();
```

### pgvector

```dart
final dataSource = DataSource(
  DataSourceOptions(
    driver: PostgresDriverAdapter.fromUrl(env['POSTGRES_URL']!),
    driverExtensions: const [PgvectorExtensions()],
    entities: registry.allDefinitions,
  ),
);

final orderPayload = PgvectorDistancePayload(
  column: 'embedding',
  vector: const [0.1, 0.2, 0.3],
  metric: PgvectorDistanceMetric.l2,
);

final preview = dataSource.query<AdHocRow>()
  .orderByPgvectorDistance(orderPayload)
  .toSql();
```

### pg_trgm

```dart
final rows = dataSource.context
  .table('trgm_items')
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
```

### hstore

```dart
final rows = dataSource.context
  .table('hstore_items')
  .whereHstoreHasKey(
    const HstoreHasKeyPayload(column: 'attributes', key: 'color'),
  )
  .rows();
```

### ltree

```dart
final rows = dataSource.context
  .table('ltree_items')
  .whereLtreeContains(
    const LtreeContainsPayload(column: 'path', path: 'Top.Science'),
  )
  .rows();
```

### citext

```dart
final rows = dataSource.context
  .table('citext_items')
  .whereCitextEquals(
    const CitextEqualsPayload(column: 'email', value: 'test@example.com'),
  )
  .rows();
```

### uuid-ossp

```dart
final rows = dataSource.context
  .table('citext_items')
  .selectUuidOsspV4(alias: 'uuid_v4')
  .limit(1)
  .rows();
```

### pgcrypto

```dart
final rows = dataSource.context
  .table('citext_items')
  .selectPgcryptoDigest(
    const PgcryptoDigestPayload(value: 'hello', algorithm: 'sha256'),
    alias: 'digest',
  )
  .limit(1)
  .rows();
```

### PostGIS topology

```dart
final rows = dataSource.context
  .table('topology_items')
  .selectPostgisTopologyCreate(
    const PostgisTopologyCreatePayload(name: 'ormed_topology', srid: 4326),
    alias: 'topology_id',
  )
  .limit(1)
  .rows();
```

### PostGIS raster

```dart
final rows = dataSource.context
  .table('raster_items')
  .selectPostgisRasterWidth(
    const PostgisRasterDimensionPayload(column: 'rast'),
    alias: 'width',
  )
  .limit(1)
  .rows();
```

## Docker Compose

PostGIS:

```
./tool/docker/postgis/docker-compose.yml
```

Default connection string:

```
postgres://postgres:postgres@localhost:65432/ormed_postgis
```

Postgres (contrib extensions):

```
./tool/docker/postgres/docker-compose.yml
```

Default connection string:

```
postgres://postgres:postgres@localhost:65431/ormed_extensions
```

pgvector:

```
./tool/docker/pgvector/docker-compose.yml
```

Default connection string:

```
postgres://postgres:postgres@localhost:65433/ormed_pgvector
```

Export before running tests:

```
export POSTGIS_URL=postgres://postgres:postgres@localhost:65432/ormed_postgis
export POSTGRES_EXT_URL=postgres://postgres:postgres@localhost:65431/ormed_extensions
export PGVECTOR_URL=postgres://postgres:postgres@localhost:65433/ormed_pgvector
```
