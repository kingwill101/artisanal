import 'remote_surface_host_connection.dart';
import 'remote_surface_layers.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_state.dart';
import '../tui/msg.dart' as tui;

typedef RemotePluginSurfaceMessageSender =
    Future<void> Function(RemotePluginMessage message);

/// Host-side router that maps global input into remote plugin surfaces.
///
/// This uses the same resolved placement logic as UV layer composition so host
/// mouse, key, focus, and blur events can be delivered to the correct plugin
/// surface without each host rebuilding hit testing by hand.
final class RemotePluginSurfaceInputRouter {
  RemotePluginSurfaceInputRouter({
    required this.surfaces,
    required Map<String, RemotePluginSurfaceMessageSender> sendersBySurfaceId,
    Iterable<RemotePluginSurfacePlacement> placements = const [],
  }) : _sendersBySurfaceId =
           Map<String, RemotePluginSurfaceMessageSender>.unmodifiable(
             sendersBySurfaceId,
           ),
       placements = List<RemotePluginSurfacePlacement>.of(placements);

  factory RemotePluginSurfaceInputRouter.forConnections({
    required RemotePluginSurfaceStore surfaces,
    required Map<String, RemotePluginHostConnection> connectionsBySurfaceId,
    Iterable<RemotePluginSurfacePlacement> placements = const [],
  }) {
    return RemotePluginSurfaceInputRouter(
      surfaces: surfaces,
      sendersBySurfaceId: <String, RemotePluginSurfaceMessageSender>{
        for (final entry in connectionsBySurfaceId.entries)
          entry.key: entry.value.send,
      },
      placements: placements,
    );
  }

  final RemotePluginSurfaceStore surfaces;
  final Map<String, RemotePluginSurfaceMessageSender> _sendersBySurfaceId;
  final List<RemotePluginSurfacePlacement> placements;

  String? _focusedSurfaceId;

  /// Surface currently considered focused by the router.
  String? get focusedSurfaceId => _focusedSurfaceId;

  /// Resolves the topmost remote plugin surface at one host coordinate.
  RemotePluginSurfaceHit? hitTest(int column, int row) {
    return hitTestRemotePluginSurface(
      surfaces,
      placements: placements,
      column: column,
      row: row,
    );
  }

  /// Focuses [surfaceId], blurring the previously focused surface first.
  Future<void> focusSurface(String? surfaceId) async {
    if (_focusedSurfaceId == surfaceId) {
      return;
    }

    final previousSurfaceId = _focusedSurfaceId;
    _focusedSurfaceId = surfaceId;

    if (previousSurfaceId case final previous?) {
      final sender = _sendersBySurfaceId[previous];
      if (sender != null) {
        await sender(RemotePluginBlurInput(surfaceId: previous));
      }
    }

    if (surfaceId case final next?) {
      final sender = _sendersBySurfaceId[next];
      if (sender != null) {
        await sender(RemotePluginFocusInput(surfaceId: next));
      }
    }
  }

  /// Sends one mouse event to the topmost hit surface, if any.
  ///
  /// When [focusOnPress] is true, press events also focus the hit surface.
  Future<RemotePluginSurfaceHit?> sendMouse({
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
      await focusSurface(hit.surface.surfaceId);
    }

    await sendMouseToSurface(
      surfaceId: hit.surface.surfaceId,
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

  /// Sends one TUI mouse event to the topmost hit surface, if supported.
  ///
  /// Unsupported host-side mouse buttons such as horizontal wheels or extra
  /// back/forward buttons are ignored because the remote plugin wire format
  /// does not currently encode them.
  Future<RemotePluginSurfaceHit?> sendTuiMouse(
    tui.MouseMsg event, {
    bool focusOnPress = true,
  }) async {
    final button = _mapMouseButton(event.button);
    if (button == null) {
      return null;
    }

    return sendMouse(
      action: _mapMouseAction(event.action),
      button: button,
      column: event.x,
      row: event.y,
      ctrl: event.ctrl,
      alt: event.alt,
      shift: event.shift,
      focusOnPress: focusOnPress,
    );
  }

  /// Sends one key event to the currently focused surface, if any.
  Future<void> sendKey({
    required String key,
    String? code,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool meta = false,
  }) async {
    final surfaceId = _focusedSurfaceId;
    if (surfaceId == null) {
      return;
    }

    final sender = _sendersBySurfaceId[surfaceId];
    if (sender == null) {
      return;
    }

    await sender(
      RemotePluginKeyInput(
        surfaceId: surfaceId,
        key: key,
        code: code,
        ctrl: ctrl,
        alt: alt,
        shift: shift,
        meta: meta,
      ),
    );
  }

  /// Sends one mouse event directly to [surfaceId] using surface-local
  /// coordinates.
  Future<void> sendMouseToSurface({
    required String surfaceId,
    required RemotePluginMouseAction action,
    required RemotePluginMouseButton button,
    required int column,
    required int row,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool meta = false,
  }) async {
    final sender = _sendersBySurfaceId[surfaceId];
    if (sender == null) {
      return;
    }

    await sender(
      RemotePluginMouseInput(
        surfaceId: surfaceId,
        action: action,
        button: button,
        column: column,
        row: row,
        ctrl: ctrl,
        alt: alt,
        shift: shift,
        meta: meta,
      ),
    );
  }
}

RemotePluginMouseAction _mapMouseAction(tui.MouseAction action) {
  return switch (action) {
    tui.MouseAction.press => RemotePluginMouseAction.press,
    tui.MouseAction.release => RemotePluginMouseAction.release,
    tui.MouseAction.motion => RemotePluginMouseAction.motion,
    tui.MouseAction.wheel => RemotePluginMouseAction.wheel,
  };
}

RemotePluginMouseButton? _mapMouseButton(tui.MouseButton button) {
  return switch (button) {
    tui.MouseButton.none => RemotePluginMouseButton.none,
    tui.MouseButton.left => RemotePluginMouseButton.left,
    tui.MouseButton.middle => RemotePluginMouseButton.middle,
    tui.MouseButton.right => RemotePluginMouseButton.right,
    tui.MouseButton.wheelUp => RemotePluginMouseButton.wheelUp,
    tui.MouseButton.wheelDown => RemotePluginMouseButton.wheelDown,
    tui.MouseButton.wheelLeft ||
    tui.MouseButton.wheelRight ||
    tui.MouseButton.button4 ||
    tui.MouseButton.button5 => null,
  };
}
