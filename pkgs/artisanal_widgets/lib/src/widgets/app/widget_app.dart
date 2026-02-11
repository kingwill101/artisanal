/// WidgetApp integrates widgets with the TUI program loop.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'package:artisanal/tui.dart'
    show
        BackgroundColorMsg,
        Cmd,
        FrameTickModel,
        FrameTickMsg,
        HitTestMouseMsg,
        KeyMsg,
        Model,
        MouseMsg,
        Msg,
        RenderMetrics,
        RenderMetricsModel,
        RenderMetricsMsg,
        TuiTrace,
        View,
        WindowSizeMsg;
import 'package:artisanal/style.dart'
    show Color, AdaptiveColor, CompleteAdaptiveColor;
import 'package:artisanal/terminal.dart' show KeyType;
import '../core/element.dart'
    show BuildOwner, Element, ElementTree, HitTestElementEntry;
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../focus/focus.dart' show FocusScope;
import '../layout/geometry.dart' show BoxConstraints, Size;
import '../core/key.dart';
import '../media/media_query.dart' show MediaQuery, MediaQueryData;
import '../core/widget.dart';
import '../components/components_widgets.dart'
    show DebugOverlay, DebugOverlayPosition;
import '../theme/theme.dart' show hasDarkBackground;
import 'performance.dart';
import 'render_metrics_provider.dart';

/// Runs a widget tree using an element hierarchy.
///
/// ## Built-in Debug Overlay
///
/// Set [debugOverlay] to `true` to enable a built-in [DebugOverlay] that
/// shows FPS, frame counts, and timing data. The overlay can be toggled at
/// runtime by pressing **F12**. The [debugOverlayPosition] parameter
/// controls where the overlay appears (defaults to [DebugOverlayPosition.topRight]).
///
/// The F12 toggle works even when [debugOverlay] starts as `false` — pressing
/// F12 will enable it on the fly.
class WidgetApp implements Model, FrameTickModel, RenderMetricsModel {
  WidgetApp(
    this.root, {
    this.backgroundColor,
    this.backgroundColorBuilder,
    this.scanZones = false,
    this.useHitTesting = true,
    this.handleFrameTick = false,
    this.enableRenderMetrics = true,
    this.debugOverlay = false,
    this.debugOverlayPosition = DebugOverlayPosition.topRight,
    bool debugRebuilds = false,
  }) : _mediaQueryData = MediaQueryData.zero,
       _debugOverlayEnabled = debugOverlay,
       _metricsHolder = RenderMetricsHolder() {
    _tree = ElementTree(
      _MediaQueryHost(
        key: _mediaQueryKey,
        data: MediaQueryData.zero,
        metricsHolder: _metricsHolder,
        child: debugOverlay
            ? DebugOverlay(
                key: _debugOverlayKey,
                position: debugOverlayPosition,
                child: root,
              )
            : root,
      ),
      owner: BuildOwner(debugRebuilds: debugRebuilds),
    );
  }

  Widget root;

  /// Optional terminal background color.
  ///
  /// When set, [view] returns a [View] object with this color as the
  /// terminal-level background (OSC 11). This fills the entire terminal
  /// window — including any cells that the widget tree does not explicitly
  /// paint — eliminating edge gaps around the UI.
  final Color? backgroundColor;

  /// Optional callback to resolve terminal background color at render time.
  ///
  /// This is useful when the app theme can change dynamically (for example
  /// via an in-app theme picker). If provided, this value takes precedence
  /// over [backgroundColor] and is applied to the returned [View] each frame.
  final Color? Function()? backgroundColorBuilder;

  /// Whether to scan rendered output for zone markers. Only relevant when
  /// zones are used outside of widget hit-testing (legacy/non-widget models).
  final bool scanZones;

  /// When `true` (the default), mouse events are dispatched via render-tree
  /// hit-testing instead of zone scanning. Set to `false` to fall back to
  /// zone-based dispatch.
  final bool useHitTesting;

  final bool handleFrameTick;

  /// Whether to opt into the TUI runtime's [RenderMetricsMsg] stream.
  /// When `true` (the default), the runtime starts a periodic timer that
  /// sends real renderer metrics (FPS, frame times, render durations).
  final bool enableRenderMetrics;

  /// Whether the built-in debug overlay is initially enabled.
  ///
  /// When `true`, the root widget is wrapped in a [DebugOverlay] that shows
  /// FPS and frame timing data. Press **F12** at runtime to toggle.
  final bool debugOverlay;

  /// Where the debug overlay is positioned on screen.
  final DebugOverlayPosition debugOverlayPosition;

  late final ElementTree _tree;
  static const Key _mediaQueryKey = ValueKey<String>('_media_query_host');
  static const Key _debugOverlayKey = ValueKey<String>('_debug_overlay');
  MediaQueryData _mediaQueryData;
  String? _cachedView;

  /// The last object returned by [view()] — either a [String] or a [View].
  /// Cached so that [Program._render()] can use `identical()` to skip the
  /// renderer pipeline when nothing changed.
  Object? _cachedViewObject;
  Color? _cachedBackgroundColor;
  bool _dirty = true;

  /// Current state of the debug overlay (mutable, toggled by F12).
  bool _debugOverlayEnabled;

  /// Whether the debug overlay is currently visible.
  bool get debugOverlayEnabled => _debugOverlayEnabled;

  /// Mutable holder written to by WidgetApp, read by [RenderMetricsProvider].
  final RenderMetricsHolder _metricsHolder;

  /// Latest runtime-level render metrics received from [RenderMetricsMsg].
  RenderMetrics? _latestRenderMetrics;

  @override
  bool get wantsFrameTicks => handleFrameTick;

  @override
  bool get wantsRenderMetrics => enableRenderMetrics;

  /// The most recent [RenderMetrics] from the TUI runtime, or `null` if
  /// none has been received yet.
  RenderMetrics? get latestRenderMetrics => _latestRenderMetrics;

  /// Returns a combined snapshot of runtime and widget-level performance data.
  PerformanceMetricsSnapshot get performanceSnapshot {
    return _tree.owner.performanceSnapshot(_latestRenderMetrics);
  }

  /// Registers a callback that fires after each widget frame with timing data.
  void addFrameTimingCallback(WidgetFrameTimingCallback callback) {
    _tree.owner.addFrameTimingCallback(callback);
  }

  /// Removes a previously registered frame timing callback.
  void removeFrameTimingCallback(WidgetFrameTimingCallback callback) {
    _tree.owner.removeFrameTimingCallback(callback);
  }

  @override
  Cmd? init() {
    final cmds = <Cmd>[Cmd.requestBackgroundColorReport()];
    final initCmd = _tree.collectHandleInit();
    if (initCmd != null) cmds.add(initCmd);
    return Cmd.batch(cmds);
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];

    if (TuiTrace.enabled) {
      TuiTrace.log('widget_app.update start ${msg.runtimeType}');
    }

    if (msg is FrameTickMsg && !handleFrameTick) {
      return (this, null);
    }

    // --- F12 toggles the built-in debug overlay ---
    if (msg is KeyMsg && msg.key.type == KeyType.f12) {
      _debugOverlayEnabled = !_debugOverlayEnabled;
      _tree.update(
        _MediaQueryHost(
          key: _mediaQueryKey,
          data: _mediaQueryData,
          metricsHolder: _metricsHolder,
          child: _effectiveRoot(),
        ),
      );
      _dirty = true;
      return (this, null);
    }

    // Store runtime render metrics but do NOT dispatch to the element tree.
    // This mirrors the pattern in split_dashboard_demo where
    // `case RenderMetricsMsg(): return (this, null);` short-circuits.
    // Dispatching metrics through the tree would trigger rebuilds (and mark
    // _dirty) on every metrics tick, causing pointless full-tree re-renders
    // that tank FPS from ~93 to ~24.
    //
    // When the debug overlay is visible we mark dirty so it picks up the
    // latest metrics on the next repaint (metrics interval is typically
    // 250ms–1s so this is 1–4 extra repaints/sec — acceptable).
    if (msg is RenderMetricsMsg) {
      _latestRenderMetrics = msg.metrics;
      // Update the mutable holder so RenderMetricsProvider descendants
      // (e.g. DebugOverlay) see the latest data on their next build.
      _metricsHolder.metrics = msg.metrics;
      if (_debugOverlayEnabled) {
        _dirty = true;
      }
      return (this, null);
    }

    if (msg is WindowSizeMsg) {
      _tree.setRootConstraints(
        BoxConstraints.tight(Size(msg.width.toDouble(), msg.height.toDouble())),
      );
      _mediaQueryData = MediaQueryData(
        size: Size(msg.width.toDouble(), msg.height.toDouble()),
      );
      _tree.update(
        _MediaQueryHost(
          key: _mediaQueryKey,
          data: _mediaQueryData,
          metricsHolder: _metricsHolder,
          child: _effectiveRoot(),
        ),
      );
      _dirty = true;
    }

    if (msg is MouseMsg) {
      // --- Mouse capture: active drag/press owner gets the event first ---
      final capture = _tree.mouseCapture;
      if (capture != null) {
        final Stopwatch? dispatchSw = TuiTrace.enabled ? Stopwatch() : null;
        dispatchSw?.start();
        final cmd = _tree.dispatchTo(capture, msg);
        dispatchSw?.stop();
        if (TuiTrace.captureDispatchEnabled) {
          TuiTrace.log(
            'widget_app.capture_dispatch ${capture.widget.runtimeType} '
            'dt=${dispatchSw?.elapsedMicroseconds ?? -1}us',
          );
        }
        if (cmd != null) cmds.add(cmd);

        root = _currentRoot();
        _dirty = _dirty || _tree.hasDirty || _tree.hasPaintDirty;
        if (TuiTrace.enabled) {
          TuiTrace.log('widget_app.update end (capture) dirty=$_dirty');
        }
        return (this, cmds.isEmpty ? null : Cmd.batch(cmds));
      }

      // --- Render-tree hit-testing (default for widget apps) ---
      if (useHitTesting) {
        final Stopwatch? hitSw = TuiTrace.enabled ? Stopwatch() : null;
        hitSw?.start();
        final hits = _tree.hitTestAt(msg.x.toDouble(), msg.y.toDouble());
        hitSw?.stop();
        if (TuiTrace.enabled) {
          TuiTrace.log(
            'widget_app.hitTest count=${hits.length} '
            'mouse=(${msg.x},${msg.y}) '
            'dt=${hitSw?.elapsedMicroseconds ?? -1}us',
          );
        }
        if (hits.isNotEmpty) {
          // Dispatch a HitTestMouseMsg starting from the deepest hit element,
          // bubbling UP to ancestors.  This ensures StatefulWidgets like
          // GestureDetector (which have no render object of their own)
          // receive the event when their child's render object is hit.
          //
          // Track which StatefulElements have already been visited so that
          // when multiple hit entries (child render objects) bubble up to
          // the same GestureDetector, it only processes the event once.
          final visited = <Element>{};
          for (final hit in hits) {
            final hitMsg = HitTestMouseMsg(
              event: msg,
              localX: hit.localX,
              localY: hit.localY,
            );
            final cmd = _tree.dispatchBubbleUp(
              hit.element,
              hitMsg,
              visited: visited,
            );
            if (cmd != null) {
              cmds.add(cmd);
              break;
            }
          }
          // Capture dirty state BEFORE broadcasting the raw MouseMsg.
          // The hit-test dispatch above may have triggered setState() calls
          // (e.g., onWheel, onEnter) that marked elements dirty.  If we
          // broadcast the raw MouseMsg first, _tree.dispatch() rebuilds
          // those dirty elements, clearing hasDirty/hasPaintDirty before we
          // can propagate it to `_dirty`.
          root = _currentRoot();
          _dirty = _dirty || _tree.hasDirty || _tree.hasPaintDirty;

          // Broadcast the raw MouseMsg so that GestureDetectors NOT in the
          // hit list can detect hover exit (they see a MouseMsg motion event
          // without a preceding HitTestMouseMsg and call _setHovering(false)).
          final broadcastCmd = _tree.dispatch(msg);
          if (broadcastCmd != null) cmds.add(broadcastCmd);

          // Pick up any additional dirty flags from the broadcast.
          root = _currentRoot();
          _dirty = _dirty || _tree.hasDirty || _tree.hasPaintDirty;
          if (TuiTrace.enabled) {
            TuiTrace.log('widget_app.update end (hitTest) dirty=$_dirty');
          }
          return (this, cmds.isEmpty ? null : Cmd.batch(cmds));
        }
      }
    }

    // Capture dirty state before dispatch — external setState() calls
    // (e.g., from OverlayEntry.markNeedsBuild) mark elements dirty between
    // frames.  dispatch() rebuilds them, clearing hasDirty, so we must
    // record the flag beforehand to ensure view() invalidates the cache.
    final hadDirtyBeforeDispatch = _tree.hasDirty || _tree.hasPaintDirty;

    final Stopwatch? dispatchSw = TuiTrace.enabled ? Stopwatch() : null;
    dispatchSw?.start();
    final cmd = _tree.dispatch(msg);
    dispatchSw?.stop();
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'widget_app.dispatch ${msg.runtimeType} '
        'dt=${dispatchSw?.elapsedMicroseconds ?? -1}us',
      );
    }
    if (cmd != null) cmds.add(cmd);

    root = _currentRoot();
    if (msg is WindowSizeMsg || msg is BackgroundColorMsg) {
      _dirty = true;
    } else {
      _dirty =
          _dirty ||
          hadDirtyBeforeDispatch ||
          _tree.hasDirty ||
          _tree.hasPaintDirty;
    }

    if (TuiTrace.enabled) {
      TuiTrace.log('widget_app.update end dirty=$_dirty');
    }

    return (this, cmds.isEmpty ? null : Cmd.batch(cmds));
  }

  @override
  Object view() {
    final preRenderBackgroundColor = _resolveTerminalBackgroundColor(
      backgroundColorBuilder?.call() ?? backgroundColor,
    );
    final backgroundChanged =
        preRenderBackgroundColor != _cachedBackgroundColor;

    if (!_dirty &&
        !backgroundChanged &&
        _cachedViewObject != null &&
        !_tree.hasPaintDirty) {
      if (TuiTrace.enabled) {
        TuiTrace.log('widget_view cache hit');
      }
      return _cachedViewObject!;
    }
    final Stopwatch? sw = TuiTrace.enabled ? Stopwatch() : null;
    sw?.start();
    final content = _tree.render();
    sw?.stop();
    if (sw != null) {
      TuiTrace.log('widget_view render ${sw.elapsedMicroseconds}us');
    }
    _cachedView = content;
    _dirty = false;
    final resolvedBackgroundColor = _resolveTerminalBackgroundColor(
      backgroundColorBuilder?.call() ?? backgroundColor,
    );
    _cachedBackgroundColor = resolvedBackgroundColor;
    if (resolvedBackgroundColor != null) {
      final viewObj = View(
        content: _cachedView!,
        backgroundColor: resolvedBackgroundColor,
      );
      _cachedViewObject = viewObj;
      return viewObj;
    }
    _cachedViewObject = _cachedView;
    return _cachedView!;
  }

  Color? _resolveTerminalBackgroundColor(Color? color) {
    if (color == null) return null;
    if (color is AdaptiveColor) {
      return hasDarkBackground ? color.dark : color.light;
    }
    if (color is CompleteAdaptiveColor) {
      return hasDarkBackground ? color.dark : color.light;
    }
    return color;
  }

  /// Performs a hit-test at the given terminal coordinates against the
  /// render tree.  Returns the list of hit elements, deepest first.
  ///
  /// This is primarily used by [WidgetTester] for testing.
  List<HitTestElementEntry> hitTestAt(double x, double y) {
    return _tree.hitTestAt(x, y);
  }

  /// Returns all mounted elements in depth-first order.
  ///
  /// Intended for test/debug tooling.
  List<Element> debugElements() {
    final out = <Element>[];
    void visit(Element e) {
      out.add(e);
      for (final child in e.children) {
        visit(child);
      }
    }

    visit(_tree.root);
    return out;
  }

  /// Returns mounted elements that satisfy [predicate].
  ///
  /// Intended for test/debug tooling.
  List<Element> debugElementsWhere(bool Function(Element element) predicate) {
    return debugElements().where(predicate).toList(growable: false);
  }

  Widget _currentRoot() {
    final widget = _tree.root.widget;
    if (widget is _MediaQueryHost) {
      final child = widget.child;
      // Only unwrap DebugOverlay instances managed by WidgetApp (identified by key).
      // User-provided DebugOverlay (without _debugOverlayKey) passes through untouched.
      if (child is DebugOverlay && child.key == _debugOverlayKey) {
        return child.child;
      }
      return child;
    }
    return widget;
  }

  /// Returns the user root widget, optionally wrapped in [DebugOverlay]
  /// based on the current toggle state.
  Widget _effectiveRoot() {
    final userRoot = _currentRoot();
    if (_debugOverlayEnabled) {
      return DebugOverlay(
        key: _debugOverlayKey,
        position: debugOverlayPosition,
        child: userRoot,
      );
    }
    return userRoot;
  }
}

class _MediaQueryHost extends StatelessWidget {
  _MediaQueryHost({
    super.key,
    required this.data,
    required this.metricsHolder,
    required this.child,
  });

  final MediaQueryData data;
  final RenderMetricsHolder metricsHolder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: data,
      child: RenderMetricsProvider(
        holder: metricsHolder,
        child: FocusScope(child: child),
      ),
    );
  }
}
