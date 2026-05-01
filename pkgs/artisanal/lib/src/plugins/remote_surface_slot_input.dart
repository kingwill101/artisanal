import 'remote_surface_input_router.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_slots.dart';

/// One hit within a slot-scoped remote plugin region.
final class RemotePluginSlotHit {
  const RemotePluginSlotHit({
    required this.entry,
    required this.column,
    required this.row,
    required this.hostColumn,
    required this.hostRow,
  });

  /// Resolved slot entry that was hit.
  final RemotePluginSlotEntry entry;

  /// Surface-local column inside [entry].
  final int column;

  /// Surface-local row inside [entry].
  final int row;

  /// Host-space column after applying the region origin.
  final int hostColumn;

  /// Host-space row after applying the region origin.
  final int hostRow;

  String get surfaceId => entry.surfaceId;
}

/// Slot-scoped input adapter over a [RemotePluginSurfaceInputRouter].
///
/// This lets hosts route input using slot-region-local coordinates instead of
/// rebuilding surface hit testing or global coordinate translation by hand.
final class RemotePluginSlotInputRouter {
  RemotePluginSlotInputRouter({
    required this.router,
    required Iterable<RemotePluginSlotEntry> entries,
    this.originX = 0,
    this.originY = 0,
  }) : entries = List<RemotePluginSlotEntry>.unmodifiable(entries);

  final RemotePluginSurfaceInputRouter router;
  final List<RemotePluginSlotEntry> entries;

  /// Host-space x-origin for the slot region.
  final int originX;

  /// Host-space y-origin for the slot region.
  final int originY;

  /// Surface currently considered focused by the underlying router.
  String? get focusedSurfaceId => router.focusedSurfaceId;

  /// Resolves the topmost slot entry at one slot-region-local coordinate.
  RemotePluginSlotHit? hitTest(int column, int row) {
    final hostColumn = originX + column;
    final hostRow = originY + row;

    RemotePluginSlotEntry? best;
    var bestOrder = -1;
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (!_contains(entry, hostColumn, hostRow)) {
        continue;
      }
      if (best == null ||
          entry.z > best.z ||
          (entry.z == best.z && index > bestOrder)) {
        best = entry;
        bestOrder = index;
      }
    }

    if (best == null) {
      return null;
    }

    return RemotePluginSlotHit(
      entry: best,
      column: hostColumn - best.x,
      row: hostRow - best.y,
      hostColumn: hostColumn,
      hostRow: hostRow,
    );
  }

  /// Focuses [entry], or clears focus when `null`.
  Future<void> focusEntry(RemotePluginSlotEntry? entry) {
    return router.focusSurface(entry?.surfaceId);
  }

  /// Focuses the topmost entry in the slot region, if any.
  Future<void> focusTopmost() async {
    if (entries.isEmpty) {
      return;
    }
    await focusEntry(entries.last);
  }

  /// Sends one mouse event using slot-region-local coordinates.
  Future<RemotePluginSlotHit?> sendMouse({
    required RemotePluginMouseAction action,
    required RemotePluginMouseButton button,
    required int column,
    required int row,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool meta = false,
    bool focusOnPress = true,
  }) async {
    final hit = hitTest(column, row);
    if (hit == null) {
      return null;
    }

    if (focusOnPress && action == RemotePluginMouseAction.press) {
      await router.focusSurface(hit.surfaceId);
    }

    await router.sendMouseToSurface(
      surfaceId: hit.surfaceId,
      action: action,
      button: button,
      column: hit.column,
      row: hit.row,
      ctrl: ctrl,
      alt: alt,
      shift: shift,
      meta: meta,
    );
    return hit;
  }

  /// Sends one key event to the router's currently focused surface.
  Future<void> sendKey({
    required String key,
    String? code,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool meta = false,
  }) {
    return router.sendKey(
      key: key,
      code: code,
      ctrl: ctrl,
      alt: alt,
      shift: shift,
      meta: meta,
    );
  }
}

bool _contains(RemotePluginSlotEntry entry, int hostColumn, int hostRow) {
  return hostColumn >= entry.x &&
      hostRow >= entry.y &&
      hostColumn < entry.x + entry.surface.width &&
      hostRow < entry.y + entry.surface.height;
}
