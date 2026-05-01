import 'remote_surface_layers.dart';
import 'remote_surface_state.dart';

/// Resolved remote plugin surface grouped into a host slot.
final class RemotePluginSlotEntry {
  const RemotePluginSlotEntry({
    required this.slot,
    required this.surface,
    required this.x,
    required this.y,
    required this.z,
    this.pluginId,
  });

  /// Host slot name for this surface.
  final String slot;

  /// Optional plugin id when the host can map surfaces back to plugins.
  final String? pluginId;

  /// Resolved surface placement and state.
  final RemotePluginSurfaceState surface;

  /// Resolved host x-position.
  final int x;

  /// Resolved host y-position.
  final int y;

  /// Resolved host z-order.
  final int z;

  /// Surface id convenience accessor.
  String get surfaceId => surface.surfaceId;

  /// Surface title convenience accessor.
  String? get title => surface.title;
}

/// Resolves remote plugin surfaces into slot-grouped host entries.
///
/// Surfaces without a slot are ignored by default because the slot registry
/// model is explicitly named. Pass [defaultSlot] to coerce unslotted surfaces
/// into one host slot.
List<RemotePluginSlotEntry> resolveRemotePluginSlotEntries(
  RemotePluginSurfaceStore store, {
  Iterable<RemotePluginSurfacePlacement> placements = const [],
  Map<String, String> pluginIdBySurfaceId = const {},
  String? defaultSlot,
}) {
  final resolved = resolveRemotePluginSurfacePlacements(
    store,
    placements: placements,
  );
  final entries = <RemotePluginSlotEntry>[];

  for (final placement in resolved) {
    final slot = placement.surface.slot ?? defaultSlot;
    if (slot == null || slot.isEmpty) {
      continue;
    }
    entries.add(
      RemotePluginSlotEntry(
        slot: slot,
        pluginId: pluginIdBySurfaceId[placement.surfaceId],
        surface: placement.surface,
        x: placement.x,
        y: placement.y,
        z: placement.z,
      ),
    );
  }

  entries.sort((left, right) {
    final slotCompare = left.slot.compareTo(right.slot);
    if (slotCompare != 0) return slotCompare;

    final zCompare = left.z.compareTo(right.z);
    if (zCompare != 0) return zCompare;

    final pluginCompare = (left.pluginId ?? '').compareTo(right.pluginId ?? '');
    if (pluginCompare != 0) return pluginCompare;

    return left.surfaceId.compareTo(right.surfaceId);
  });

  return entries;
}

/// Groups resolved remote plugin slot entries by slot name.
Map<String, List<RemotePluginSlotEntry>> groupRemotePluginSlotEntries(
  RemotePluginSurfaceStore store, {
  Iterable<RemotePluginSurfacePlacement> placements = const [],
  Map<String, String> pluginIdBySurfaceId = const {},
  String? defaultSlot,
}) {
  final grouped = <String, List<RemotePluginSlotEntry>>{};
  for (final entry in resolveRemotePluginSlotEntries(
    store,
    placements: placements,
    pluginIdBySurfaceId: pluginIdBySurfaceId,
    defaultSlot: defaultSlot,
  )) {
    (grouped[entry.slot] ??= <RemotePluginSlotEntry>[]).add(entry);
  }
  return grouped;
}
