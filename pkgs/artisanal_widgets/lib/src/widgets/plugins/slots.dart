library;

import 'package:artisanal/src/plugins/remote_surface_protocol.dart'
    show RemotePluginMouseAction, RemotePluginMouseButton;
import 'package:artisanal/src/plugins/remote_surface_drawable.dart'
    show RemotePluginSurfaceDrawable;
import 'package:artisanal/src/plugins/remote_surface_state.dart'
    show RemotePluginSurfaceState;
import 'package:artisanal/src/plugins/remote_surface_slots.dart'
    show RemotePluginSlotEntry;
import 'package:artisanal/src/plugins/remote_surface_slot_input.dart'
    show RemotePluginSlotHit, RemotePluginSlotInputRouter;
import 'package:artisanal/tui.dart'
    show Cmd, KeyMsg, KeyType, MouseAction, MouseButton, MouseMsg;
import 'package:artisanal/uv.dart' show Canvas;

import '../core/framework.dart';
import '../core/widget.dart';
import '../focus/focus.dart';
import '../gestures/events.dart' show TapDownDetails;
import '../layout/layout_widgets.dart';

/// Builds one widget contribution for a typed slot payload.
typedef SlotWidgetBuilder<TData> =
    Widget Function(BuildContext context, TData data);

/// One contribution declared by an in-process slot plugin.
final class SlotPluginContribution<TData> {
  const SlotPluginContribution({required this.builder, this.order = 0});

  final SlotWidgetBuilder<TData> builder;
  final int order;
}

/// Declarative registration for one in-process widget plugin.
final class SlotPlugin<TSlot extends Object, TData> {
  const SlotPlugin({required this.pluginId, required this.slots});

  final String pluginId;
  final Map<TSlot, SlotPluginContribution<TData>> slots;
}

/// Builds the composed widget tree for a resolved slot.
typedef SlotLayoutBuilder<TSlot extends Object, TData> =
    Widget Function(
      BuildContext context,
      List<ResolvedSlotContribution<TSlot, TData>> contributions,
      TData data,
    );

/// Builds a remote surface widget for one resolved slot entry.
typedef RemoteSlotEntryBuilder =
    Widget Function(BuildContext context, RemotePluginSlotEntry entry);

/// Builds the composed widget tree for one mixed local/remote slot region.
typedef SlotRegionLayoutBuilder<TSlot extends Object, TData> =
    Widget Function(
      BuildContext context,
      List<ResolvedSlotContribution<TSlot, TData>> localContributions,
      List<RemotePluginSlotEntry> remoteEntries,
      TData data,
    );

/// How [SlotBuilder] should compose multiple contributions by default.
enum SlotBuildMode {
  /// Render only the highest-priority contribution.
  first,

  /// Render all contributions in ascending order inside a [Column].
  column,
}

final class _SlotRegistration<TSlot extends Object, TData> {
  const _SlotRegistration({
    required this.pluginId,
    required this.slot,
    required this.order,
    required this.registrationOrder,
    required this.builder,
  });

  final String pluginId;
  final TSlot slot;
  final int order;
  final int registrationOrder;
  final SlotWidgetBuilder<TData> builder;
}

/// One resolved slot contribution in deterministic render order.
final class ResolvedSlotContribution<TSlot extends Object, TData> {
  const ResolvedSlotContribution._({
    required this.pluginId,
    required this.slot,
    required this.order,
    required this.registrationOrder,
    required SlotWidgetBuilder<TData> builder,
  }) : _builder = builder;

  /// Stable plugin identifier for this contribution.
  final String pluginId;

  /// Slot that this contribution targets.
  final TSlot slot;

  /// Explicit priority. Lower values render first.
  final int order;

  /// Tie-breaker for contributions with the same [order].
  final int registrationOrder;

  final SlotWidgetBuilder<TData> _builder;

  /// Builds the widget for this contribution.
  Widget build(BuildContext context, TData data) => _builder(context, data);
}

/// Mutable in-process registry of typed slot contributions.
///
/// Registrations are resolved in ascending `(order, registrationOrder,
/// pluginId)` order so output remains deterministic.
final class SlotRegistry<TSlot extends Object, TData> {
  final List<_SlotRegistration<TSlot, TData>> _registrations =
      <_SlotRegistration<TSlot, TData>>[];
  final Set<void Function()> _listeners = <void Function()>{};
  int _nextRegistrationOrder = 0;

  /// Adds a synchronous listener invoked when registrations change.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Returns whether the registry has any contributions for [slot].
  bool hasSlot(TSlot slot) {
    return _registrations.any((registration) => registration.slot == slot);
  }

  /// Registers one contribution and returns a disposer that unregisters it.
  ///
  /// A given `pluginId + slot` pair may only be registered once.
  void Function() register({
    required String pluginId,
    required TSlot slot,
    required SlotWidgetBuilder<TData> builder,
    int order = 0,
  }) {
    if (pluginId.isEmpty) {
      throw ArgumentError.value(pluginId, 'pluginId', 'Must not be empty.');
    }
    if (_registrations.any(
      (registration) =>
          registration.pluginId == pluginId && registration.slot == slot,
    )) {
      throw StateError(
        'Slot contribution "$pluginId" is already registered for slot '
        '"$slot".',
      );
    }

    _registrations.add(
      _SlotRegistration<TSlot, TData>(
        pluginId: pluginId,
        slot: slot,
        order: order,
        registrationOrder: _nextRegistrationOrder++,
        builder: builder,
      ),
    );
    _notifyListeners();

    var disposed = false;
    return () {
      if (disposed) return;
      disposed = true;
      unregister(pluginId: pluginId, slot: slot);
    };
  }

  /// Registers every slot contribution from [plugin].
  ///
  /// The registration is validated up front so partial registration cannot
  /// succeed.
  void Function() registerPlugin(SlotPlugin<TSlot, TData> plugin) {
    if (plugin.pluginId.isEmpty) {
      throw ArgumentError.value(
        plugin.pluginId,
        'plugin.pluginId',
        'Must not be empty.',
      );
    }
    if (plugin.slots.isEmpty) {
      throw ArgumentError.value(
        plugin.slots,
        'plugin.slots',
        'Must not be empty.',
      );
    }

    for (final entry in plugin.slots.entries) {
      if (_registrations.any(
        (registration) =>
            registration.pluginId == plugin.pluginId &&
            registration.slot == entry.key,
      )) {
        throw StateError(
          'Slot contribution "${plugin.pluginId}" is already registered for '
          'slot "${entry.key}".',
        );
      }
    }

    final registrations = plugin.slots.entries
        .map(
          (entry) => _SlotRegistration<TSlot, TData>(
            pluginId: plugin.pluginId,
            slot: entry.key,
            order: entry.value.order,
            registrationOrder: _nextRegistrationOrder++,
            builder: entry.value.builder,
          ),
        )
        .toList(growable: false);
    _registrations.addAll(registrations);
    _notifyListeners();

    var disposed = false;
    return () {
      if (disposed) return;
      disposed = true;
      unregisterPlugin(plugin.pluginId);
    };
  }

  /// Unregisters one contribution by `pluginId + slot`.
  bool unregister({required String pluginId, required TSlot slot}) {
    final index = _registrations.indexWhere(
      (registration) =>
          registration.pluginId == pluginId && registration.slot == slot,
    );
    if (index == -1) {
      return false;
    }
    _registrations.removeAt(index);
    _notifyListeners();
    return true;
  }

  /// Unregisters every contribution owned by [pluginId].
  bool unregisterPlugin(String pluginId) {
    final originalLength = _registrations.length;
    _registrations.removeWhere(
      (registration) => registration.pluginId == pluginId,
    );
    if (_registrations.length == originalLength) {
      return false;
    }
    _notifyListeners();
    return true;
  }

  /// Removes all contributions.
  void clear() {
    if (_registrations.isEmpty) return;
    _registrations.clear();
    _notifyListeners();
  }

  /// Resolves contributions for [slot] in deterministic order.
  List<ResolvedSlotContribution<TSlot, TData>> resolve(TSlot slot) {
    final matches =
        _registrations
            .where((registration) => registration.slot == slot)
            .toList()
          ..sort((left, right) {
            final orderCompare = left.order.compareTo(right.order);
            if (orderCompare != 0) return orderCompare;

            final registrationCompare = left.registrationOrder.compareTo(
              right.registrationOrder,
            );
            if (registrationCompare != 0) return registrationCompare;

            return left.pluginId.compareTo(right.pluginId);
          });

    return matches
        .map(
          (registration) => ResolvedSlotContribution<TSlot, TData>._(
            pluginId: registration.pluginId,
            slot: registration.slot,
            order: registration.order,
            registrationOrder: registration.registrationOrder,
            builder: registration.builder,
          ),
        )
        .toList(growable: false);
  }

  void _notifyListeners() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }
}

/// Exposes a [SlotRegistry] to descendant widgets and rebuilds them when the
/// registry contents change.
class SlotScope<TSlot extends Object, TData> extends StatefulWidget {
  SlotScope({required this.registry, required this.child, super.key});

  final SlotRegistry<TSlot, TData> registry;
  final Widget child;

  /// Returns the nearest matching registry, if any.
  static SlotRegistry<TSlot, TData>? maybeOf<TSlot extends Object, TData>(
    BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<
          _SlotRegistryProvider<TSlot, TData>
        >()
        ?.registry;
  }

  /// Returns the nearest matching registry.
  static SlotRegistry<TSlot, TData> of<TSlot extends Object, TData>(
    BuildContext context,
  ) {
    final registry = maybeOf<TSlot, TData>(context);
    assert(registry != null, 'No SlotScope<$TSlot, $TData> found in tree.');
    return registry!;
  }

  @override
  State createState() => _SlotScopeState<TSlot, TData>();
}

class _SlotScopeState<TSlot extends Object, TData>
    extends State<SlotScope<TSlot, TData>> {
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    widget.registry.addListener(_handleRegistryChanged);
  }

  @override
  Cmd? didUpdateWidget(covariant SlotScope<TSlot, TData> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.registry, widget.registry)) {
      oldWidget.registry.removeListener(_handleRegistryChanged);
      widget.registry.addListener(_handleRegistryChanged);
      _revision++;
    }
    return null;
  }

  @override
  void dispose() {
    widget.registry.removeListener(_handleRegistryChanged);
    super.dispose();
  }

  void _handleRegistryChanged() {
    if (!mounted) return;
    setState(() {
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SlotRegistryProvider<TSlot, TData>(
      registry: widget.registry,
      revision: _revision,
      child: widget.child,
    );
  }
}

class _SlotRegistryProvider<TSlot extends Object, TData>
    extends InheritedWidget {
  _SlotRegistryProvider({
    required this.registry,
    required this.revision,
    required super.child,
    super.key,
  });

  final SlotRegistry<TSlot, TData> registry;
  final int revision;

  @override
  bool updateShouldNotify(
    covariant _SlotRegistryProvider<TSlot, TData> oldWidget,
  ) {
    return !identical(registry, oldWidget.registry) ||
        revision != oldWidget.revision;
  }
}

/// Resolves and renders contributions for one slot.
class SlotBuilder<TSlot extends Object, TData> extends StatefulWidget {
  SlotBuilder({
    required this.slot,
    required this.data,
    this.registry,
    this.mode = SlotBuildMode.column,
    this.layoutBuilder,
    this.fallback,
    super.key,
  });

  final TSlot slot;
  final TData data;
  final SlotRegistry<TSlot, TData>? registry;
  final SlotBuildMode mode;
  final SlotLayoutBuilder<TSlot, TData>? layoutBuilder;
  final Widget? fallback;

  @override
  State createState() => _SlotBuilderState<TSlot, TData>();
}

class _SlotBuilderState<TSlot extends Object, TData>
    extends State<SlotBuilder<TSlot, TData>> {
  SlotRegistry<TSlot, TData>? _boundRegistry;

  @override
  void initState() {
    super.initState();
    _bindIfNeeded();
  }

  @override
  Cmd? didUpdateWidget(covariant SlotBuilder<TSlot, TData> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.registry, widget.registry)) {
      _rebind();
    }
    return null;
  }

  @override
  void dispose() {
    _boundRegistry?.removeListener(_handleRegistryChanged);
    _boundRegistry = null;
    super.dispose();
  }

  void _handleRegistryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _rebind() {
    _boundRegistry?.removeListener(_handleRegistryChanged);
    _boundRegistry = null;
    _bindIfNeeded();
  }

  void _bindIfNeeded() {
    final registry = widget.registry ?? SlotScope.of<TSlot, TData>(context);
    if (identical(_boundRegistry, registry)) return;
    _boundRegistry = registry;
    registry.addListener(_handleRegistryChanged);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedRegistry =
        widget.registry ?? SlotScope.of<TSlot, TData>(context);
    if (!identical(_boundRegistry, resolvedRegistry)) {
      _rebind();
    }
    final contributions = resolvedRegistry.resolve(widget.slot);

    if (widget.layoutBuilder != null) {
      return widget.layoutBuilder!(context, contributions, widget.data);
    }

    if (contributions.isEmpty) {
      return widget.fallback ?? SizedBox.shrink();
    }

    return switch (widget.mode) {
      SlotBuildMode.first => contributions.first.build(context, widget.data),
      SlotBuildMode.column => Column(
        children: [
          for (final contribution in contributions)
            contribution.build(context, widget.data),
        ],
      ),
    };
  }
}

/// Declaratively mounts a [SlotPlugin] into the nearest [SlotScope].
///
/// This is useful when a subtree wants to contribute one or more slot
/// renderers without wiring imperative registration code in the host app.
class SlotPluginMount<TSlot extends Object, TData> extends StatefulWidget {
  SlotPluginMount({required this.plugin, this.registry, this.child, super.key});

  final SlotPlugin<TSlot, TData> plugin;
  final SlotRegistry<TSlot, TData>? registry;
  final Widget? child;

  @override
  State createState() => _SlotPluginMountState<TSlot, TData>();
}

class _SlotPluginMountState<TSlot extends Object, TData>
    extends State<SlotPluginMount<TSlot, TData>> {
  SlotRegistry<TSlot, TData>? _boundRegistry;
  void Function()? _disposeRegistration;

  @override
  void initState() {
    super.initState();
    _bindIfNeeded();
  }

  @override
  Cmd? didUpdateWidget(covariant SlotPluginMount<TSlot, TData> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.plugin, widget.plugin) ||
        !identical(oldWidget.registry, widget.registry)) {
      _rebind();
    }
    return null;
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _rebind() {
    _unbind();
    _bindIfNeeded();
  }

  void _bindIfNeeded() {
    final registry = widget.registry ?? SlotScope.of<TSlot, TData>(context);
    if (identical(_boundRegistry, registry) && _disposeRegistration != null) {
      return;
    }
    _boundRegistry = registry;
    _disposeRegistration = registry.registerPlugin(widget.plugin);
  }

  void _unbind() {
    _disposeRegistration?.call();
    _disposeRegistration = null;
    _boundRegistry = null;
  }

  @override
  Widget build(BuildContext context) {
    final registry = widget.registry ?? SlotScope.of<TSlot, TData>(context);
    if (!identical(_boundRegistry, registry)) {
      _rebind();
    }
    return widget.child ?? SizedBox.shrink();
  }
}

/// Renders a remote plugin surface into a widget subtree.
///
/// This adapts the existing remote surface drawable to the widget layer by
/// drawing it into a canvas and reusing the ANSI text render path.
class RemotePluginSurfaceView extends StatelessWidget {
  RemotePluginSurfaceView({
    required this.surface,
    this.softWrap = false,
    super.key,
  });

  final RemotePluginSurfaceState surface;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    return Text(_renderRemotePluginSurface(surface), softWrap: softWrap);
  }
}

/// Resolves local slot plugins plus remote slot surfaces for one region.
///
/// Local contributions come from [SlotRegistry]. Remote entries are passed in as
/// resolved [RemotePluginSlotEntry] values, typically from
/// `resolveRemotePluginSlotEntries(...)`.
///
/// By default, local content is rendered first and remote surfaces are
/// positioned on top using their resolved `x/y` coordinates.
class SlotRegion<TSlot extends Object, TData> extends StatefulWidget {
  SlotRegion({
    required this.slot,
    required this.data,
    this.registry,
    this.mode = SlotBuildMode.column,
    this.layoutBuilder,
    this.fallback,
    this.remoteEntries = const <RemotePluginSlotEntry>[],
    this.remoteSlot,
    this.remoteEntryBuilder,
    super.key,
  });

  final TSlot slot;
  final TData data;
  final SlotRegistry<TSlot, TData>? registry;
  final SlotBuildMode mode;
  final SlotRegionLayoutBuilder<TSlot, TData>? layoutBuilder;
  final Widget? fallback;
  final Iterable<RemotePluginSlotEntry> remoteEntries;

  /// Slot name used to match remote entries.
  ///
  /// When omitted and [slot] is a [String], the same string value is used.
  /// For non-string local slot keys, provide this explicitly if the region
  /// should also include remote surfaces.
  final String? remoteSlot;
  final RemoteSlotEntryBuilder? remoteEntryBuilder;

  @override
  State createState() => _SlotRegionState<TSlot, TData>();
}

class _SlotRegionState<TSlot extends Object, TData>
    extends State<SlotRegion<TSlot, TData>> {
  SlotRegistry<TSlot, TData>? _boundRegistry;

  @override
  void initState() {
    super.initState();
    _bindIfNeeded();
  }

  @override
  Cmd? didUpdateWidget(covariant SlotRegion<TSlot, TData> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.registry, widget.registry)) {
      _rebind();
    }
    return null;
  }

  @override
  void dispose() {
    _boundRegistry?.removeListener(_handleRegistryChanged);
    _boundRegistry = null;
    super.dispose();
  }

  void _handleRegistryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _rebind() {
    _boundRegistry?.removeListener(_handleRegistryChanged);
    _boundRegistry = null;
    _bindIfNeeded();
  }

  void _bindIfNeeded() {
    final registry = widget.registry ?? SlotScope.of<TSlot, TData>(context);
    if (identical(_boundRegistry, registry)) return;
    _boundRegistry = registry;
    registry.addListener(_handleRegistryChanged);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedRegistry =
        widget.registry ?? SlotScope.of<TSlot, TData>(context);
    if (!identical(_boundRegistry, resolvedRegistry)) {
      _rebind();
    }

    final localContributions = resolvedRegistry.resolve(widget.slot);
    final resolvedRemoteSlot =
        widget.remoteSlot ??
        switch (widget.slot) {
          final String value => value,
          _ => null,
        };
    final remoteEntries = [
      if (resolvedRemoteSlot case final remoteSlot?)
        for (final entry in widget.remoteEntries)
          if (entry.slot == remoteSlot) entry,
    ];

    if (widget.layoutBuilder != null) {
      return widget.layoutBuilder!(
        context,
        localContributions,
        remoteEntries,
        widget.data,
      );
    }

    final localChild = _buildLocalSlotChild(
      context,
      localContributions,
      widget.data,
      mode: widget.mode,
      fallback: widget.fallback,
    );
    if (remoteEntries.isEmpty) {
      return localChild;
    }

    return _buildSlotRegionStack(
      context,
      localChild: localChild,
      remoteEntries: remoteEntries,
      remoteEntryBuilder: widget.remoteEntryBuilder,
    );
  }
}

Widget _buildLocalSlotChild<TSlot extends Object, TData>(
  BuildContext context,
  List<ResolvedSlotContribution<TSlot, TData>> contributions,
  TData data, {
  required SlotBuildMode mode,
  Widget? fallback,
}) {
  if (contributions.isEmpty) {
    return fallback ?? SizedBox.shrink();
  }

  return switch (mode) {
    SlotBuildMode.first => contributions.first.build(context, data),
    SlotBuildMode.column => Column(
      children: [
        for (final contribution in contributions)
          contribution.build(context, data),
      ],
    ),
  };
}

Widget _buildSlotRegionStack(
  BuildContext context, {
  required Widget localChild,
  required List<RemotePluginSlotEntry> remoteEntries,
  required RemoteSlotEntryBuilder? remoteEntryBuilder,
}) {
  var width = 0;
  var height = 0;
  for (final entry in remoteEntries) {
    final surface = entry.surface;
    final maxX = entry.x + surface.width;
    final maxY = entry.y + surface.height;
    if (maxX > width) {
      width = maxX;
    }
    if (maxY > height) {
      height = maxY;
    }
  }

  return Stack(
    children: [
      SizedBox(width: width, height: height),
      localChild,
      for (final entry in remoteEntries)
        Positioned(
          left: entry.x,
          top: entry.y,
          child:
              remoteEntryBuilder?.call(context, entry) ??
              RemotePluginSurfaceView(surface: entry.surface),
        ),
    ],
  );
}

String _renderRemotePluginSurface(RemotePluginSurfaceState surface) {
  final canvas = Canvas(surface.width, surface.height);
  final drawable = RemotePluginSurfaceDrawable(surface);
  drawable.draw(canvas, canvas.bounds());
  return canvas.render();
}

/// Interactive wrapper for [SlotRegion] that forwards remote input.
///
/// Mouse hit-testing is performed in slot-region-local coordinates using
/// [RemotePluginSlotInputRouter]. Keyboard events are forwarded to the
/// currently focused remote surface when this region has widget focus.
class InteractiveSlotRegion<TSlot extends Object, TData>
    extends StatefulWidget {
  InteractiveSlotRegion({
    required this.slot,
    required this.data,
    required this.remoteInputRouter,
    this.registry,
    this.mode = SlotBuildMode.column,
    this.layoutBuilder,
    this.fallback,
    this.remoteEntries = const <RemotePluginSlotEntry>[],
    this.remoteSlot,
    this.remoteEntryBuilder,
    this.focusController,
    this.enabled = true,
    super.key,
  });

  final TSlot slot;
  final TData data;
  final RemotePluginSlotInputRouter remoteInputRouter;
  final SlotRegistry<TSlot, TData>? registry;
  final SlotBuildMode mode;
  final SlotRegionLayoutBuilder<TSlot, TData>? layoutBuilder;
  final Widget? fallback;
  final Iterable<RemotePluginSlotEntry> remoteEntries;
  final String? remoteSlot;
  final RemoteSlotEntryBuilder? remoteEntryBuilder;
  final FocusController? focusController;
  final bool enabled;

  @override
  State createState() => _InteractiveSlotRegionState<TSlot, TData>();
}

class _InteractiveSlotRegionState<TSlot extends Object, TData>
    extends State<InteractiveSlotRegion<TSlot, TData>> {
  FocusController? _controller;
  FocusController? _localController;
  RemotePluginMouseButton? _activeDragButton;
  RemotePluginSlotEntry? _activeDragEntry;
  RemotePluginSlotHit? _pendingPressHit;
  bool _pendingPressCommitted = false;

  String get _focusId => widget.id;

  @override
  void initState() {
    super.initState();
    _resolveController();
  }

  @override
  Cmd? didUpdateWidget(
    covariant InteractiveSlotRegion<TSlot, TData> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusController != widget.focusController) {
      _controller?.unregister(_focusId);
      _resolveController();
    }
    return null;
  }

  @override
  void dispose() {
    _controller?.unregister(_focusId);
    super.dispose();
  }

  void _resolveController() {
    _controller =
        widget.focusController ??
        FocusScope.of(context) ??
        (_localController ??= FocusController());
    _controller?.register(_focusId);
  }

  Cmd? _handleRemoteKey(KeyMsg msg) {
    final controller = _controller;
    final focused =
        widget.enabled &&
        (controller?.isFocused(_focusId, searchPath: true) ?? false);
    if (!focused) {
      return null;
    }
    final focusedSurfaceId = widget.remoteInputRouter.focusedSurfaceId;
    if (focusedSurfaceId == null) {
      return null;
    }

    final translated = _translateRemoteKey(msg);
    if (translated == null) {
      return null;
    }

    return Cmd(() async {
      await widget.remoteInputRouter.sendKey(
        key: translated.key,
        code: translated.code,
        ctrl: translated.ctrl,
        alt: translated.alt,
        shift: translated.shift,
        meta: translated.meta,
      );
      return null;
    });
  }

  Cmd? _sendRemoteMouse({
    required RemotePluginMouseAction action,
    required RemotePluginMouseButton button,
    required int column,
    required int row,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool focusOnPress = true,
  }) {
    if (widget.remoteInputRouter.hitTest(column, row) == null &&
        action != RemotePluginMouseAction.motion &&
        action != RemotePluginMouseAction.release) {
      return null;
    }

    return Cmd(() async {
      await widget.remoteInputRouter.sendMouse(
        action: action,
        button: button,
        column: column,
        row: row,
        ctrl: ctrl,
        alt: alt,
        shift: shift,
        focusOnPress: focusOnPress,
      );
      return null;
    });
  }

  Cmd _sendRemoteMouseToHit({
    required RemotePluginSlotHit hit,
    required RemotePluginMouseAction action,
    required RemotePluginMouseButton button,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool focusOnPress = true,
  }) {
    return Cmd(() async {
      if (focusOnPress && action == RemotePluginMouseAction.press) {
        await widget.remoteInputRouter.focusEntry(hit.entry);
      }
      await widget.remoteInputRouter.router.sendMouseToSurface(
        surfaceId: hit.surfaceId,
        action: action,
        button: button,
        column: hit.column,
        row: hit.row,
        ctrl: ctrl,
        alt: alt,
        shift: shift,
      );
      return null;
    });
  }

  Cmd _sendRemoteMouseToEntry({
    required RemotePluginSlotEntry entry,
    required int regionColumn,
    required int regionRow,
    required RemotePluginMouseAction action,
    required RemotePluginMouseButton button,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
  }) {
    final hostColumn = widget.remoteInputRouter.originX + regionColumn;
    final hostRow = widget.remoteInputRouter.originY + regionRow;
    return Cmd(() async {
      await widget.remoteInputRouter.router.sendMouseToSurface(
        surfaceId: entry.surfaceId,
        action: action,
        button: button,
        column: hostColumn - entry.x,
        row: hostRow - entry.y,
        ctrl: ctrl,
        alt: alt,
        shift: shift,
      );
      return null;
    });
  }

  Cmd? _handleRemotePress(TapDownDetails details) {
    if (!widget.enabled) {
      return null;
    }

    if (_activeDragButton != null) {
      return null;
    }

    final button = _mapRemoteMouseButton(details.button);
    if (button == null) {
      return null;
    }

    final localX = details.localPosition.dx.toInt();
    final localY = details.localPosition.dy.toInt();
    final hit = widget.remoteInputRouter.hitTest(localX, localY);
    if (hit == null) {
      return null;
    }

    _activeDragButton = button;
    _activeDragEntry = hit.entry;
    _pendingPressHit = hit;
    _pendingPressCommitted = false;
    _controller?.requestFocus(_focusId);
    return Cmd(() async {
      await widget.remoteInputRouter.focusEntry(hit.entry);
      return null;
    });
  }

  @override
  Cmd? handleUpdate(msg) {
    if (msg is KeyMsg) {
      return _handleRemoteKey(msg);
    }
    if (!widget.enabled || msg is! MouseMsg) {
      return null;
    }

    final localX = msg.x - widget.remoteInputRouter.originX;
    final localY = msg.y - widget.remoteInputRouter.originY;
    final hit = widget.remoteInputRouter.hitTest(localX, localY);

    switch (msg.action) {
      case MouseAction.press:
        return null;
      case MouseAction.motion:
        final button = _activeDragButton ?? _mapRemoteMouseButton(msg.button);
        if (button == null || (hit == null && _activeDragButton == null)) {
          return null;
        }
        final activeDragEntry = _activeDragEntry;
        final pendingPressHit = _pendingPressHit;
        if (!_pendingPressCommitted && pendingPressHit != null) {
          _pendingPressCommitted = true;
          if (hit == null) {
            return Cmd.batch(<Cmd>[
              _sendRemoteMouseToHit(
                hit: pendingPressHit,
                action: RemotePluginMouseAction.press,
                button: button,
                ctrl: msg.ctrl,
                alt: msg.alt,
                shift: msg.shift,
                focusOnPress: false,
              ),
              if (activeDragEntry != null)
                _sendRemoteMouseToEntry(
                  entry: activeDragEntry,
                  regionColumn: localX,
                  regionRow: localY,
                  action: RemotePluginMouseAction.motion,
                  button: button,
                  ctrl: msg.ctrl,
                  alt: msg.alt,
                  shift: msg.shift,
                ),
            ]);
          }
          return Cmd.batch(<Cmd>[
            _sendRemoteMouseToHit(
              hit: pendingPressHit,
              action: RemotePluginMouseAction.press,
              button: button,
              ctrl: msg.ctrl,
              alt: msg.alt,
              shift: msg.shift,
              focusOnPress: false,
            ),
            if (activeDragEntry != null)
              _sendRemoteMouseToEntry(
                entry: activeDragEntry,
                regionColumn: localX,
                regionRow: localY,
                action: RemotePluginMouseAction.motion,
                button: button,
                ctrl: msg.ctrl,
                alt: msg.alt,
                shift: msg.shift,
              )
            else
              _sendRemoteMouseToHit(
                hit: hit,
                action: RemotePluginMouseAction.motion,
                button: button,
                ctrl: msg.ctrl,
                alt: msg.alt,
                shift: msg.shift,
                focusOnPress: false,
              ),
          ]);
        }
        if (activeDragEntry != null) {
          return _sendRemoteMouseToEntry(
            entry: activeDragEntry,
            regionColumn: localX,
            regionRow: localY,
            action: RemotePluginMouseAction.motion,
            button: button,
            ctrl: msg.ctrl,
            alt: msg.alt,
            shift: msg.shift,
          );
        }
        if (hit != null) {
          return _sendRemoteMouseToHit(
            hit: hit,
            action: RemotePluginMouseAction.motion,
            button: button,
            ctrl: msg.ctrl,
            alt: msg.alt,
            shift: msg.shift,
            focusOnPress: false,
          );
        }
        return _sendRemoteMouse(
          action: RemotePluginMouseAction.motion,
          button: button,
          column: localX,
          row: localY,
          ctrl: msg.ctrl,
          alt: msg.alt,
          shift: msg.shift,
          focusOnPress: false,
        );
      case MouseAction.release:
        final button = _activeDragButton ?? _mapRemoteMouseButton(msg.button);
        final pendingPressHit = _pendingPressHit;
        final activeDragEntry = _activeDragEntry;
        _activeDragButton = null;
        _activeDragEntry = null;
        _pendingPressHit = null;
        if (button == null) {
          return null;
        }
        if (!_pendingPressCommitted && pendingPressHit != null) {
          _pendingPressCommitted = false;
          return _sendRemoteMouseToHit(
            hit: pendingPressHit,
            action: RemotePluginMouseAction.press,
            button: button,
            ctrl: msg.ctrl,
            alt: msg.alt,
            shift: msg.shift,
            focusOnPress: false,
          );
        }
        _pendingPressCommitted = false;
        if (activeDragEntry != null) {
          return _sendRemoteMouseToEntry(
            entry: activeDragEntry,
            regionColumn: localX,
            regionRow: localY,
            action: RemotePluginMouseAction.release,
            button: button,
            ctrl: msg.ctrl,
            alt: msg.alt,
            shift: msg.shift,
          );
        }
        if (hit == null) {
          return null;
        }
        return _sendRemoteMouseToHit(
          hit: hit,
          action: RemotePluginMouseAction.release,
          button: button,
          ctrl: msg.ctrl,
          alt: msg.alt,
          shift: msg.shift,
          focusOnPress: false,
        );
      case MouseAction.wheel:
        final button = _mapRemoteMouseButton(msg.button);
        if (button == null || hit == null) {
          return null;
        }
        return _sendRemoteMouse(
          action: RemotePluginMouseAction.wheel,
          button: button,
          column: localX,
          row: localY,
          ctrl: msg.ctrl,
          alt: msg.alt,
          shift: msg.shift,
          focusOnPress: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    _resolveController();
    return GestureDetector(
      onTapDown: _handleRemotePress,
      captureMouse: false,
      child: SlotRegion<TSlot, TData>(
        slot: widget.slot,
        data: widget.data,
        registry: widget.registry,
        mode: widget.mode,
        layoutBuilder: widget.layoutBuilder,
        fallback: widget.fallback,
        remoteEntries: widget.remoteEntries,
        remoteSlot: widget.remoteSlot,
        remoteEntryBuilder: widget.remoteEntryBuilder,
      ),
    );
  }
}

RemotePluginMouseButton? _mapRemoteMouseButton(MouseButton button) {
  return switch (button) {
    MouseButton.none => RemotePluginMouseButton.none,
    MouseButton.left => RemotePluginMouseButton.left,
    MouseButton.middle => RemotePluginMouseButton.middle,
    MouseButton.right => RemotePluginMouseButton.right,
    MouseButton.wheelUp => RemotePluginMouseButton.wheelUp,
    MouseButton.wheelDown => RemotePluginMouseButton.wheelDown,
    MouseButton.wheelLeft ||
    MouseButton.wheelRight ||
    MouseButton.button4 ||
    MouseButton.button5 => null,
  };
}

({String key, String? code, bool ctrl, bool alt, bool shift, bool meta})?
_translateRemoteKey(KeyMsg msg) {
  final key = msg.key;
  final keyName = _remoteKeyNameFor(key);
  if (keyName == null || keyName.isEmpty) {
    return null;
  }

  return (
    key: keyName,
    code: _remoteKeyCodeFor(key),
    ctrl: key.ctrl,
    alt: key.alt,
    shift: key.shift,
    meta: key.meta,
  );
}

String? _remoteKeyCodeFor(dynamic key) {
  if (key.type == KeyType.runes && key.char != null && key.char!.length == 1) {
    final char = key.char!;
    final codeUnit = char.codeUnitAt(0);
    final isLower = codeUnit >= 0x61 && codeUnit <= 0x7a;
    final isUpper = codeUnit >= 0x41 && codeUnit <= 0x5a;
    if (isLower || isUpper) {
      return 'Key${char.toUpperCase()}';
    }
    if (codeUnit >= 0x30 && codeUnit <= 0x39) {
      return 'Digit$char';
    }
  }

  final extendedCode = _remoteExtendedKeyCode(key.type);
  if (extendedCode != null) {
    return extendedCode;
  }

  return _remoteKeyNameFor(key, spaceAsLiteral: false);
}

String? _remoteKeyNameFor(dynamic key, {bool spaceAsLiteral = true}) {
  if (key.type == KeyType.runes) {
    return key.char ?? String.fromCharCodes(key.runes);
  }

  final functionKeyName = _remoteFunctionKeyName(key.type);
  if (functionKeyName != null) {
    return functionKeyName;
  }

  final extendedKeyName = _remoteExtendedKeyName(key.type);
  if (extendedKeyName != null) {
    return extendedKeyName;
  }

  return switch (key.type) {
    KeyType.enter => 'Enter',
    KeyType.tab => 'Tab',
    KeyType.backspace => 'Backspace',
    KeyType.delete => 'Delete',
    KeyType.escape => 'Escape',
    KeyType.space => spaceAsLiteral ? ' ' : 'Space',
    KeyType.up => 'ArrowUp',
    KeyType.down => 'ArrowDown',
    KeyType.left => 'ArrowLeft',
    KeyType.right => 'ArrowRight',
    KeyType.home => 'Home',
    KeyType.end => 'End',
    KeyType.pageUp => 'PageUp',
    KeyType.pageDown => 'PageDown',
    KeyType.insert => 'Insert',
    _ => null,
  };
}

String? _remoteFunctionKeyName(KeyType type) {
  final name = type.name;
  if (name.length < 2 || !name.startsWith('f')) {
    return null;
  }

  final suffix = name.substring(1);
  final index = int.tryParse(suffix);
  if (index == null || index < 1 || index > 63) {
    return null;
  }
  return 'F$index';
}

String? _remoteExtendedKeyName(KeyType type) {
  return switch (type) {
    KeyType.capsLock => 'CapsLock',
    KeyType.scrollLock => 'ScrollLock',
    KeyType.numLock => 'NumLock',
    KeyType.printScreen => 'PrintScreen',
    KeyType.pause => 'Pause',
    KeyType.menu => 'ContextMenu',
    KeyType.mediaPlay => 'MediaPlay',
    KeyType.mediaPause => 'MediaPause',
    KeyType.mediaPlayPause => 'MediaPlayPause',
    KeyType.mediaReverse => 'MediaReverse',
    KeyType.mediaStop => 'MediaStop',
    KeyType.mediaFastForward => 'MediaFastForward',
    KeyType.mediaRewind => 'MediaRewind',
    KeyType.mediaNext => 'MediaTrackNext',
    KeyType.mediaPrev => 'MediaTrackPrevious',
    KeyType.mediaRecord => 'MediaRecord',
    KeyType.volumeDown => 'AudioVolumeDown',
    KeyType.volumeUp => 'AudioVolumeUp',
    KeyType.mute => 'AudioVolumeMute',
    KeyType.leftShift || KeyType.rightShift => 'Shift',
    KeyType.leftAlt ||
    KeyType.rightAlt ||
    KeyType.isoLevel3Shift ||
    KeyType.isoLevel5Shift => 'Alt',
    KeyType.leftCtrl || KeyType.rightCtrl => 'Control',
    KeyType.leftSuper ||
    KeyType.rightSuper ||
    KeyType.leftMeta ||
    KeyType.rightMeta => 'Meta',
    KeyType.leftHyper || KeyType.rightHyper => 'Hyper',
    _ => null,
  };
}

String? _remoteExtendedKeyCode(KeyType type) {
  return switch (type) {
    KeyType.capsLock => 'CapsLock',
    KeyType.scrollLock => 'ScrollLock',
    KeyType.numLock => 'NumLock',
    KeyType.printScreen => 'PrintScreen',
    KeyType.pause => 'Pause',
    KeyType.menu => 'ContextMenu',
    KeyType.mediaPlay => 'MediaPlay',
    KeyType.mediaPause => 'MediaPause',
    KeyType.mediaPlayPause => 'MediaPlayPause',
    KeyType.mediaReverse => 'MediaReverse',
    KeyType.mediaStop => 'MediaStop',
    KeyType.mediaFastForward => 'MediaFastForward',
    KeyType.mediaRewind => 'MediaRewind',
    KeyType.mediaNext => 'MediaTrackNext',
    KeyType.mediaPrev => 'MediaTrackPrevious',
    KeyType.mediaRecord => 'MediaRecord',
    KeyType.volumeDown => 'AudioVolumeDown',
    KeyType.volumeUp => 'AudioVolumeUp',
    KeyType.mute => 'AudioVolumeMute',
    KeyType.leftShift => 'ShiftLeft',
    KeyType.rightShift => 'ShiftRight',
    KeyType.leftAlt => 'AltLeft',
    KeyType.rightAlt => 'AltRight',
    KeyType.leftCtrl => 'ControlLeft',
    KeyType.rightCtrl => 'ControlRight',
    KeyType.leftSuper => 'SuperLeft',
    KeyType.rightSuper => 'SuperRight',
    KeyType.leftMeta => 'MetaLeft',
    KeyType.rightMeta => 'MetaRight',
    KeyType.leftHyper => 'HyperLeft',
    KeyType.rightHyper => 'HyperRight',
    KeyType.isoLevel3Shift => 'AltRight',
    KeyType.isoLevel5Shift => 'Fn',
    _ => null,
  };
}
