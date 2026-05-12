// ignore_for_file: always_use_package_imports
import 'remote_surface_host_connection.dart';
import 'remote_surface_input_router.dart';
import 'remote_surface_layers.dart';
import 'remote_surface_state.dart';

/// Extends [RemotePluginSurfaceInputRouter] with a factory that requires
/// [RemotePluginHostConnection], which depends on `dart:io`.
extension RemotePluginSurfaceInputRouterConnectionExtension
    on RemotePluginSurfaceInputRouter {
  /// Creates a router wired to a set of live [RemotePluginHostConnection]s.
  static RemotePluginSurfaceInputRouter forConnections({
    required RemotePluginSurfaceStore surfaces,
    required Map<String, RemotePluginHostConnection> connectionsBySurfaceId,
    Iterable<RemotePluginSurfacePlacement> placements = const [],
  }) {
    return RemotePluginSurfaceInputRouter(
      surfaces: surfaces,
      sendersBySurfaceId: {
        for (final entry in connectionsBySurfaceId.entries)
          entry.key: entry.value.send,
      },
      placements: placements,
    );
  }
}
