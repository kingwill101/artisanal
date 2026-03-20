import '../../uv.dart' as uv;
import 'remote_surface_drawable.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_state.dart';

/// Explicit host placement override for one remote plugin surface.
final class RemotePluginSurfacePlacement {
  const RemotePluginSurfacePlacement({
    required this.surfaceId,
    required this.x,
    required this.y,
    this.z = 0,
  });

  final String surfaceId;
  final int x;
  final int y;
  final int z;
}

/// Builds UV layers for the open surfaces in [store].
///
/// Root surfaces default to `(0, 0)` unless explicitly overridden in
/// [placements]. Child surfaces without explicit placements are positioned
/// relative to their parent surface and optional anchor rectangle.
List<uv.Layer> buildRemotePluginSurfaceLayers(
  RemotePluginSurfaceStore store, {
  Iterable<RemotePluginSurfacePlacement> placements = const [],
}) {
  final placementById = <String, RemotePluginSurfacePlacement>{
    for (final placement in placements) placement.surfaceId: placement,
  };
  final layersById = <String, uv.Layer>{};

  uv.Layer resolve(RemotePluginSurfaceState surface) {
    final cached = layersById[surface.surfaceId];
    if (cached != null) {
      return cached;
    }

    final explicitPlacement = placementById[surface.surfaceId];
    final parent = switch (surface.parentSurfaceId) {
      final parentId? => store[parentId],
      null => null,
    };

    final x = switch ((explicitPlacement, parent, surface.anchor)) {
      (final placement?, _, _) => placement.x,
      (null, final parent?, final anchor?) => resolve(parent).x + anchor.column,
      _ => 0,
    };
    final y = switch ((explicitPlacement, parent, surface.anchor)) {
      (final placement?, _, _) => placement.y,
      (null, final parent?, final anchor?) => resolve(parent).y + anchor.row,
      _ => 0,
    };
    final z = switch ((explicitPlacement, parent)) {
      (final placement?, _) => placement.z,
      (null, final parent?) => resolve(parent).z + _zOffsetFor(surface.kind),
      _ => _zOffsetFor(surface.kind),
    };

    final layer = uv
        .Layer(RemotePluginSurfaceDrawable(surface))
        .setId(surface.surfaceId)
        .setX(x)
        .setY(y)
        .setZ(z);
    layersById[surface.surfaceId] = layer;
    return layer;
  }

  for (final surface in store.surfaces) {
    resolve(surface);
  }

  return layersById.values.toList(growable: false);
}

int _zOffsetFor(RemotePluginSurfaceKind kind) {
  return switch (kind) {
    RemotePluginSurfaceKind.panel => 0,
    RemotePluginSurfaceKind.popup => 100,
    RemotePluginSurfaceKind.dialog => 200,
    RemotePluginSurfaceKind.overlay => 300,
  };
}
