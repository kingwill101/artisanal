import 'dart:async';
import 'dart:io' as io;

import 'remote_surface_generic_service.dart';
import 'remote_surface_host_connection.dart';
import 'remote_surface_input_router.dart';
import 'remote_surface_slot_input.dart';
import 'remote_surface_manifest.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_state.dart';
import 'remote_surface_slots.dart';

/// Bundled multi-plugin host workspace built from manifest-backed plugins.
final class RemotePluginWorkspace {
  RemotePluginWorkspace._({
    required this.manifests,
    required this.surfaces,
    required this.connections,
    required this.router,
    required this.pluginIdBySurfaceId,
  }) : _manifestsById = <String, RemotePluginManifest>{
         for (final manifest in manifests) manifest.id: manifest,
       };

  /// Loads all manifests from [directoryPath], launches their plugin
  /// processes, waits for the declared surfaces to open, and returns a shared
  /// workspace over those plugin connections.
  static Future<RemotePluginWorkspace> startManifestDirectory(
    String directoryPath, {
    required String executable,
    required RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
    RemotePluginManifestValidator manifestValidator =
        const RemotePluginManifestValidator(),
    RemotePluginSurfaceStore? surfaces,
    Duration timeout = const Duration(seconds: 5),
    Duration readyTimeout = const Duration(seconds: 5),
  }) async {
    final manifests = await loadRemotePluginManifests(
      directoryPath,
      validator: manifestValidator,
    );
    return startManifests(
      manifests,
      executable: executable,
      hostHello: hostHello,
      genericServices: genericServices,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      mode: mode,
      validator: validator,
      surfaces: surfaces,
      timeout: timeout,
      readyTimeout: readyTimeout,
    );
  }

  /// Launches all [manifests] into one shared host-side surface store and
  /// input router.
  static Future<RemotePluginWorkspace> startManifests(
    List<RemotePluginManifest> manifests, {
    required String executable,
    required RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
    RemotePluginSurfaceStore? surfaces,
    Duration timeout = const Duration(seconds: 5),
    Duration readyTimeout = const Duration(seconds: 5),
  }) async {
    final sharedSurfaces = surfaces ?? RemotePluginSurfaceStore();
    final connections = <String, RemotePluginHostConnection>{};
    try {
      for (final manifest in manifests) {
        final connection = await RemotePluginHostConnection.startManifest(
          manifest,
          executable: executable,
          hostHello: hostHello,
          genericServices: genericServices,
          workingDirectory: workingDirectory,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          mode: mode,
          validator: validator,
          surfaces: sharedSurfaces,
          timeout: timeout,
        );
        connections[manifest.id] = connection;
      }

      await _waitForSurfaceIds(
        sharedSurfaces,
        manifests.expand((manifest) => manifest.surfaceIds),
        timeout: readyTimeout,
      );

      final connectionsBySurfaceId = <String, RemotePluginHostConnection>{
        for (final manifest in manifests)
          for (final surfaceId in manifest.surfaceIds)
            surfaceId: connections[manifest.id]!,
      };
      final pluginIdBySurfaceId = <String, String>{
        for (final manifest in manifests)
          for (final surfaceId in manifest.surfaceIds) surfaceId: manifest.id,
      };

      return RemotePluginWorkspace._(
        manifests: manifests,
        surfaces: sharedSurfaces,
        connections: connections,
        router: RemotePluginSurfaceInputRouter.forConnections(
          surfaces: sharedSurfaces,
          connectionsBySurfaceId: connectionsBySurfaceId,
          placements: manifests.map(
            (manifest) => manifest.placement.toSurfacePlacement(),
          ),
        ),
        pluginIdBySurfaceId: pluginIdBySurfaceId,
      );
    } catch (_) {
      for (final connection in connections.values) {
        await connection.dispose(kill: true);
      }
      rethrow;
    }
  }

  final List<RemotePluginManifest> manifests;
  final RemotePluginSurfaceStore surfaces;
  final Map<String, RemotePluginHostConnection> connections;
  final RemotePluginSurfaceInputRouter router;
  final Map<String, String> pluginIdBySurfaceId;
  final Map<String, RemotePluginManifest> _manifestsById;

  RemotePluginManifest? manifestForPlugin(String pluginId) {
    return _manifestsById[pluginId];
  }

  String? pluginIdForSurface(String surfaceId) {
    return pluginIdBySurfaceId[surfaceId];
  }

  /// Resolves current slot entries for [slot].
  List<RemotePluginSlotEntry> slotEntriesFor(
    String slot, {
    String? defaultSlot,
  }) {
    return resolveRemotePluginSlotEntries(
      surfaces,
      placements: manifests.map(
        (manifest) => manifest.placement.toSurfacePlacement(),
      ),
      pluginIdBySurfaceId: pluginIdBySurfaceId,
      defaultSlot: defaultSlot,
    ).where((entry) => entry.slot == slot).toList(growable: false);
  }

  /// Builds a slot-scoped input router for [slot].
  RemotePluginSlotInputRouter slotInputRouterFor(
    String slot, {
    int originX = 0,
    int originY = 0,
    String? defaultSlot,
  }) {
    return RemotePluginSlotInputRouter(
      router: router,
      entries: slotEntriesFor(slot, defaultSlot: defaultSlot),
      originX: originX,
      originY: originY,
    );
  }

  Future<void> focusPlugin(String? pluginId) async {
    if (pluginId == null) {
      return;
    }
    final manifest = manifestForPlugin(pluginId);
    if (manifest == null) {
      return;
    }
    await router.focusSurface(manifest.primarySurfaceId);
  }

  Future<void> dispose({bool kill = false}) async {
    for (final connection in connections.values) {
      await connection.dispose(kill: kill);
    }
  }
}

Future<void> _waitForSurfaceIds(
  RemotePluginSurfaceStore surfaces,
  Iterable<String> surfaceIds, {
  required Duration timeout,
}) async {
  final stopwatch = Stopwatch()..start();
  final expected = surfaceIds.toSet();
  while (stopwatch.elapsed < timeout) {
    final open = expected.every((surfaceId) => surfaces[surfaceId] != null);
    if (open) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }

  throw TimeoutException(
    'Timed out waiting for plugin surfaces: ${expected.join(', ')}',
    timeout,
  );
}
