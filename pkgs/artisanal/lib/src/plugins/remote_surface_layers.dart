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

/// Resolved host placement for one open remote plugin surface.
final class RemotePluginResolvedSurfacePlacement {
  const RemotePluginResolvedSurfacePlacement({
    required this.surface,
    required this.x,
    required this.y,
    required this.z,
  });

  final RemotePluginSurfaceState surface;
  final int x;
  final int y;
  final int z;

  String get surfaceId => surface.surfaceId;
  int get width => surface.width;
  int get height => surface.height;

  bool contains(int column, int row) {
    return column >= x && row >= y && column < x + width && row < y + height;
  }
}

/// One host hit mapped into a remote plugin surface.
final class RemotePluginSurfaceHit {
  const RemotePluginSurfaceHit({
    required this.surface,
    required this.column,
    required this.row,
  });

  final RemotePluginResolvedSurfacePlacement surface;
  final int column;
  final int row;
}

/// Resolves host placements for every open remote plugin surface in [store].
///
/// Root surfaces default to `(0, 0)` unless explicitly overridden in
/// [placements]. Child surfaces without explicit placements are positioned
/// relative to their parent surface and optional anchor rectangle.
List<RemotePluginResolvedSurfacePlacement> resolveRemotePluginSurfacePlacements(
  RemotePluginSurfaceStore store, {
  Iterable<RemotePluginSurfacePlacement> placements = const [],
}) {
  final placementById = <String, RemotePluginSurfacePlacement>{
    for (final placement in placements) placement.surfaceId: placement,
  };
  final resolvedById = <String, RemotePluginResolvedSurfacePlacement>{};

  RemotePluginResolvedSurfacePlacement resolve(
    RemotePluginSurfaceState surface,
  ) {
    final cached = resolvedById[surface.surfaceId];
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

    final resolved = RemotePluginResolvedSurfacePlacement(
      surface: surface,
      x: x,
      y: y,
      z: z,
    );
    resolvedById[surface.surfaceId] = resolved;
    return resolved;
  }

  for (final surface in store.surfaces) {
    resolve(surface);
  }

  return resolvedById.values.toList(growable: false);
}

/// Maps a host coordinate into the topmost remote plugin surface at that cell.
RemotePluginSurfaceHit? hitTestRemotePluginSurface(
  RemotePluginSurfaceStore store, {
  Iterable<RemotePluginSurfacePlacement> placements = const [],
  required int column,
  required int row,
}) {
  final resolved = resolveRemotePluginSurfacePlacements(
    store,
    placements: placements,
  );

  RemotePluginResolvedSurfacePlacement? best;
  var bestOrder = -1;
  for (var index = 0; index < resolved.length; index++) {
    final candidate = resolved[index];
    if (!candidate.contains(column, row)) {
      continue;
    }
    if (best == null ||
        candidate.z > best.z ||
        (candidate.z == best.z && index > bestOrder)) {
      best = candidate;
      bestOrder = index;
    }
  }

  if (best == null) {
    return null;
  }

  return RemotePluginSurfaceHit(
    surface: best,
    column: column - best.x,
    row: row - best.y,
  );
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
  final resolved = resolveRemotePluginSurfacePlacements(
    store,
    placements: placements,
  );
  return resolved
      .map(
        (surface) => uv.Layer(RemotePluginSurfaceDrawable(surface.surface))
            .setId(surface.surfaceId)
            .setX(surface.x)
            .setY(surface.y)
            .setZ(surface.z),
      )
      .toList(growable: false);
}

int _zOffsetFor(RemotePluginSurfaceKind kind) {
  return switch (kind) {
    RemotePluginSurfaceKind.panel => 0,
    RemotePluginSurfaceKind.popup => 100,
    RemotePluginSurfaceKind.dialog => 200,
    RemotePluginSurfaceKind.overlay => 300,
  };
}
