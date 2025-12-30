import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

/// Extension keys for PostGIS topology handlers.
abstract class PostgisTopologyExtensionKeys {
  static const String create = 'postgis_topology_create';
  static const String drop = 'postgis_topology_drop';
}

/// Payload for creating a topology.
@immutable
class PostgisTopologyCreatePayload {
  const PostgisTopologyCreatePayload({required this.name, required this.srid});

  final String name;
  final int srid;
}

/// Payload for dropping a topology.
@immutable
class PostgisTopologyDropPayload {
  const PostgisTopologyDropPayload({required this.name});

  final String name;
}

/// Driver extension bundle that registers PostGIS topology handlers.
class PostgisTopologyExtensions extends DriverExtension {
  const PostgisTopologyExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
    DriverExtensionHandler(
      kind: DriverExtensionKind.select,
      key: PostgisTopologyExtensionKeys.create,
      compile: _compileCreate,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.select,
      key: PostgisTopologyExtensionKeys.drop,
      compile: _compileDrop,
    ),
  ];
}

DriverExtensionFragment _compileCreate(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PostgisTopologyCreatePayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PostgisTopologyCreatePayload for ${PostgisTopologyExtensionKeys.create}.',
    );
  }

  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: 'topology.CreateTopology($placeholder, $placeholder)',
    bindings: [payload.name, payload.srid],
  );
}

DriverExtensionFragment _compileDrop(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PostgisTopologyDropPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PostgisTopologyDropPayload for ${PostgisTopologyExtensionKeys.drop}.',
    );
  }

  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: 'topology.DropTopology($placeholder)',
    bindings: [payload.name],
  );
}

/// Convenience query helpers for PostGIS topology extensions.
extension PostgisTopologyQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> selectPostgisTopologyCreate(
    PostgisTopologyCreatePayload payload, {
    String? alias,
  }) => selectExtension(
    PostgisTopologyExtensionKeys.create,
    payload: payload,
    alias: alias,
  );

  Query<T> selectPostgisTopologyDrop(
    PostgisTopologyDropPayload payload, {
    String? alias,
  }) => selectExtension(
    PostgisTopologyExtensionKeys.drop,
    payload: payload,
    alias: alias,
  );
}
