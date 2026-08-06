/// Registers a [tui.ShortcutSurface] with the nearest [tui.KeymapHub] while mounted.
library;

import 'package:artisanal/tui.dart' as tui;

import '../core/framework.dart' show BuildContext, State, StatefulWidget;
import '../core/widget.dart' show Widget;
import 'keymap_hub_scope.dart';

/// Pushes a shortcut surface onto the hub for the lifetime of this widget.
///
/// ```dart
/// ShortcutSurfaceScope(
///   surfaceId: 'session',
///   bindings: [
///     tui.ShortcutBinding.chord(
///       id: 'sidebar_toggle',
///       leader: 'ctrl+x',
///       key: 'b',
///       description: 'toggle sidebar',
///     ),
///   ],
///   child: SessionShell(...),
/// )
/// ```
///
/// Requires an ancestor [KeymapHubScope] (or pass [hub] explicitly).
class ShortcutSurfaceScope extends StatefulWidget {
  ShortcutSurfaceScope({
    required this.surfaceId,
    required this.child,
    this.bindings = const [],
    this.exclusive = false,
    this.sequenceTimeout,
    this.hub,
    this.onMessage,
    this.meta = const {},
    super.key,
  });

  /// Surface id for hub push/pop (e.g. `session`, `confirm-dialog`).
  ///
  /// Named [surfaceId] (not `id`) to avoid clashing with [Widget.id].
  final String surfaceId;

  /// Bindings for this surface (singles + sequences).
  final List<tui.ShortcutBinding> bindings;

  /// Modal surfaces drop unclaimed keys (no fallthrough).
  final bool exclusive;

  /// Leader timeout; `null` waits forever.
  final Duration? sequenceTimeout;

  /// Explicit hub; defaults to [KeymapHubScope.maybeOf].
  final tui.KeymapHub? hub;

  /// Optional custom layer handler after bindings.
  final tui.KeymapLayerResult Function(tui.Msg msg)? onMessage;

  /// Optional metadata for discovery UIs.
  final Map<String, Object?> meta;

  final Widget child;

  @override
  State createState() => _ShortcutSurfaceScopeState();
}

class _ShortcutSurfaceScopeState extends State<ShortcutSurfaceScope> {
  tui.KeymapHub? _hub;
  String? _registeredId;

  @override
  tui.Cmd? handleInit() {
    _syncRegistration(forceReplace: true);
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRegistration(forceReplace: false);
  }

  @override
  tui.Cmd? didUpdateWidget(covariant ShortcutSurfaceScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bindingsChanged = !_listEquals(oldWidget.bindings, widget.bindings);
    final configChanged = oldWidget.surfaceId != widget.surfaceId ||
        oldWidget.exclusive != widget.exclusive ||
        oldWidget.sequenceTimeout != widget.sequenceTimeout ||
        !identical(oldWidget.hub, widget.hub) ||
        !identical(oldWidget.onMessage, widget.onMessage) ||
        bindingsChanged;
    if (configChanged) {
      _syncRegistration(forceReplace: true);
    }
    return null;
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  void _syncRegistration({required bool forceReplace}) {
    final hub = widget.hub ?? KeymapHubScope.maybeOf(context);
    if (hub == null) {
      _unregister();
      return;
    }

    final surface = _buildSurface();

    // Already registered with this hub/id: update in place only.
    // Never re-push — KeymapHub.push moves an existing id to the top, which
    // would steal focus from a newer route surface (e.g. home over session).
    if (identical(_hub, hub) && _registeredId == widget.surfaceId) {
      if (forceReplace) {
        hub.replace(surface);
      }
      return;
    }

    _unregister();
    _hub = hub;
    // First registration for this id: push to top (route became active).
    // If id already exists on hub (re-mount), replace in place then activate.
    if (hub.contains(widget.surfaceId)) {
      hub.replace(surface);
      hub.activate(widget.surfaceId);
    } else {
      hub.push(surface);
    }
    _registeredId = widget.surfaceId;
  }

  void _unregister() {
    final hub = _hub;
    final id = _registeredId;
    if (hub != null && id != null) {
      hub.pop(id);
    }
    _hub = null;
    _registeredId = null;
  }

  tui.ShortcutSurface _buildSurface() {
    return tui.ShortcutSurface(
      id: widget.surfaceId,
      exclusive: widget.exclusive,
      bindings: widget.bindings,
      sequenceTimeout: widget.sequenceTimeout,
      onMessage: widget.onMessage,
      meta: widget.meta,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
