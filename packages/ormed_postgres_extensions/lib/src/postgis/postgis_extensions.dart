import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

/// Extension keys for PostGIS handlers.
abstract class PostgisExtensionKeys {
  static const String within = 'postgis_within';
  static const String distance = 'postgis_distance';
  static const String geoJson = 'postgis_geojson';
}

/// Coordinate data for PostGIS point-based operations.
@immutable
class PostgisPoint {
  const PostgisPoint({
    required this.longitude,
    required this.latitude,
    this.srid = 4326,
  });

  final double longitude;
  final double latitude;
  final int srid;
}

/// Payload for within-radius predicates using ST_DWithin.
@immutable
class PostgisWithinPayload {
  const PostgisWithinPayload({
    required this.column,
    required this.point,
    required this.meters,
  });

  final String column;
  final PostgisPoint point;
  final double meters;
}

/// Payload for distance ordering using ST_Distance.
@immutable
class PostgisDistancePayload {
  const PostgisDistancePayload({required this.column, required this.point});

  final String column;
  final PostgisPoint point;
}

/// Payload for selecting GeoJSON output using ST_AsGeoJSON.
@immutable
class PostgisGeoJsonPayload {
  const PostgisGeoJsonPayload({required this.column});

  final String column;
}

/// Driver extension bundle that registers PostGIS handlers.
class PostgisExtensions extends DriverExtension {
  const PostgisExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: PostgisExtensionKeys.within,
      compile: _compileWithin,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.orderBy,
      key: PostgisExtensionKeys.distance,
      compile: _compileDistance,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.select,
      key: PostgisExtensionKeys.geoJson,
      compile: _compileGeoJson,
    ),
  ];
}

DriverExtensionFragment _compileWithin(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PostgisWithinPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PostgisWithinPayload for ${PostgisExtensionKeys.within}.',
    );
  }
  final column = _qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();
  final point = payload.point;

  final sql =
      'ST_DWithin(($column)::geography, '
      'ST_SetSRID(ST_MakePoint($placeholder, $placeholder), $placeholder)::geography, '
      '$placeholder)';

  return DriverExtensionFragment(
    sql: sql,
    bindings: [point.longitude, point.latitude, point.srid, payload.meters],
  );
}

DriverExtensionFragment _compileDistance(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PostgisDistancePayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PostgisDistancePayload for ${PostgisExtensionKeys.distance}.',
    );
  }
  final column = _qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();
  final point = payload.point;

  final sql =
      'ST_Distance(($column)::geography, '
      'ST_SetSRID(ST_MakePoint($placeholder, $placeholder), $placeholder)::geography)';

  return DriverExtensionFragment(
    sql: sql,
    bindings: [point.longitude, point.latitude, point.srid],
  );
}

DriverExtensionFragment _compileGeoJson(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PostgisGeoJsonPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PostgisGeoJsonPayload for ${PostgisExtensionKeys.geoJson}.',
    );
  }
  final column = _qualifiedColumn(context, payload.column);
  return DriverExtensionFragment(sql: 'ST_AsGeoJSON($column)');
}

String _qualifiedColumn(DriverExtensionContext context, String column) {
  if (column.contains('.')) {
    return column.split('.').map(context.grammar.wrapIdentifier).join('.');
  }
  return '${context.tableIdentifier}.${context.grammar.wrapIdentifier(column)}';
}

/// Convenience query helpers for PostGIS extensions.
extension PostgisQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> wherePostgisWithin(PostgisWithinPayload payload) =>
      whereExtension(PostgisExtensionKeys.within, payload);

  Query<T> orWherePostgisWithin(PostgisWithinPayload payload) =>
      orWhereExtension(PostgisExtensionKeys.within, payload);

  Query<T> orderByPostgisDistance(
    PostgisDistancePayload payload, {
    bool descending = false,
  }) => orderByExtension(
    PostgisExtensionKeys.distance,
    payload: payload,
    descending: descending,
  );

  Query<T> selectPostgisGeoJson(
    PostgisGeoJsonPayload payload, {
    String? alias,
  }) => selectExtension(
    PostgisExtensionKeys.geoJson,
    payload: payload,
    alias: alias,
  );
}
