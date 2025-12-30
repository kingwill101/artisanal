import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

import '../shared/extension_helpers.dart';

/// Extension keys for PostGIS raster handlers.
abstract class PostgisRasterExtensionKeys {
  static const String width = 'postgis_raster_width';
  static const String height = 'postgis_raster_height';
}

/// Payload for raster dimension queries.
@immutable
class PostgisRasterDimensionPayload {
  const PostgisRasterDimensionPayload({required this.column});

  final String column;
}

/// Driver extension bundle that registers PostGIS raster handlers.
class PostgisRasterExtensions extends DriverExtension {
  const PostgisRasterExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.select,
          key: PostgisRasterExtensionKeys.width,
          compile: _compileWidth,
        ),
        DriverExtensionHandler(
          kind: DriverExtensionKind.select,
          key: PostgisRasterExtensionKeys.height,
          compile: _compileHeight,
        ),
      ];
}

DriverExtensionFragment _compileWidth(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PostgisRasterDimensionPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PostgisRasterDimensionPayload for ${PostgisRasterExtensionKeys.width}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);

  return DriverExtensionFragment(sql: 'ST_Width($column)');
}

DriverExtensionFragment _compileHeight(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PostgisRasterDimensionPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PostgisRasterDimensionPayload for ${PostgisRasterExtensionKeys.height}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);

  return DriverExtensionFragment(sql: 'ST_Height($column)');
}

/// Convenience query helpers for PostGIS raster extensions.
extension PostgisRasterQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> selectPostgisRasterWidth(
    PostgisRasterDimensionPayload payload, {
    String? alias,
  }) =>
      selectExtension(
        PostgisRasterExtensionKeys.width,
        payload: payload,
        alias: alias,
      );

  Query<T> selectPostgisRasterHeight(
    PostgisRasterDimensionPayload payload, {
    String? alias,
  }) =>
      selectExtension(
        PostgisRasterExtensionKeys.height,
        payload: payload,
        alias: alias,
      );
}
