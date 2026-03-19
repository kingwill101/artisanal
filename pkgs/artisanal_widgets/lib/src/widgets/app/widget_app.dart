/// WidgetApp integrates widgets with the TUI program loop.
library;

import 'dart:collection';

import 'package:artisanal/tui.dart'
    show
        BackgroundColorMsg,
        Cmd,
        PrimaryDeviceAttributesMsg,
        DebugOverlayModel,
        EveryCmd,
        FrameTickModel,
        FrameTickMsg,
        HitTestMouseMsg,
        KeyMsg,
        Model,
        MouseAction,
        MouseButton,
        MouseMsg,
        Msg,
        ParallelCmd,
        RenderMetrics,
        RenderMetricsModel,
        RenderMetricsMsg,
        TerminalVersionMsg,
        StreamCmd,
        TuiTrace,
        View,
        WindowSizeMsg;
import 'package:artisanal/uv.dart'
    show
        PrimaryDeviceAttributesEvent,
        TerminalCapabilities,
        TerminalVersionEvent;
import 'package:artisanal/style.dart'
    show Color, AdaptiveColor, CompleteAdaptiveColor;
import 'package:artisanal/terminal.dart' show KeyType;
import '../core/element.dart'
    show BuildOwner, Element, ElementTree, HitTestElementEntry;
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../focus/focus.dart' show FocusScope;
import '../layout/geometry.dart' show BoxConstraints, Size;
import '../layout/layout_widgets.dart'
    show ImageAutoMode, withImageAutoConfiguration;
import '../core/key.dart';
import '../media/media_query.dart' show MediaQuery, MediaQueryData;
import '../core/widget.dart';
import '../components/components_widgets.dart'
    show DebugOverlay, DebugOverlayPosition, PerformanceOverlay;
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
    ImageAutoMode imageAutoMode = ImageAutoMode.environment,
    this.scanZones = false,
    this.useHitTesting = true,
    this.handleFrameTick = false,
    this.enableRenderMetrics = true,
    this.enableRenderMetricsInjection = true,
    this.debugOverlay = false,
    this.debugOverlayPosition = DebugOverlayPosition.topRight,
    bool debugRebuilds = false,
  }) : _mediaQueryData = MediaQueryData.zero,
       _imageAutoMode = imageAutoMode,
       _debugOverlayEnabled = debugOverlay,
       _metricsHolder = RenderMetricsHolder() {
    _tree = ElementTree(
      _MediaQueryHost(
        key: _mediaQueryKey,
        data: MediaQueryData.zero,
        metricsHolder: _metricsHolder,
        child: root,
      ),
      owner: BuildOwner(debugRebuilds: debugRebuilds),
    );

    _runtimeDebugOverlay = DebugOverlayModel.initial(
      enabled: debugOverlay,
      rendererLabel: 'UV',
    );
    _runtimeDebugOverlay = _positionRuntimeOverlay(_runtimeDebugOverlay);
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

  ImageAutoMode get imageAutoMode => _imageAutoMode;
  ImageAutoMode _imageAutoMode;

  set imageAutoMode(ImageAutoMode value) {
    if (_imageAutoMode == value) return;
    _imageAutoMode = value;
    _cachedView = null;
    _cachedViewObject = null;
    _dirty = true;
  }

  /// Legacy no-op compatibility flag.
  ///
  /// Zone scanning was removed from `artisanal_widgets`; rendering now relies
  /// exclusively on render-tree hit-testing.
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

  /// Whether to listen to [RenderMetricsInjector] updates.
  ///
  /// When `true` (the default), custom metrics can be injected globally from
  /// anywhere via [RenderMetricsInjector.instance].
  final bool enableRenderMetricsInjection;

  /// Whether the built-in debug overlay is initially enabled.
  ///
  /// When `true`, the root widget is wrapped in a [DebugOverlay] that shows
  /// FPS and frame timing data. Press **F12** at runtime to toggle.
  final bool debugOverlay;

  /// Where the debug overlay is positioned on screen.
  final DebugOverlayPosition debugOverlayPosition;

  late final ElementTree _tree;
  static const Key _mediaQueryKey = ValueKey<String>('_media_query_host');
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

  /// Runtime-composed debug overlay (split-dashboard style).
  late DebugOverlayModel _runtimeDebugOverlay;

  /// Whether overlay composition must be refreshed even if base tree is cached.
  bool _overlayDirty = false;

  /// Whether the debug overlay is currently visible.
  bool get debugOverlayEnabled => _debugOverlayEnabled;

  /// Mutable holder written to by WidgetApp, read by [RenderMetricsProvider].
  final RenderMetricsHolder _metricsHolder;
  final TerminalCapabilities _sessionImageCapabilities = TerminalCapabilities();

  /// Latest runtime-level render metrics received from [RenderMetricsMsg].
  RenderMetrics? _latestRenderMetrics;

  final Stopwatch _latencyClock = Stopwatch()..start();
  final ListQueue<int> _pendingKeyTimestampsUs = ListQueue<int>();
  final List<int> _keyRenderLatencyUs = <int>[];
  static const int _maxPendingKeySamples = 512;
  static const int _maxKeyRenderSamples = 240;

  @override
  bool get wantsFrameTicks => handleFrameTick || _debugOverlayEnabled;

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
    if (_imageAutoMode == ImageAutoMode.sessionCapabilities) {
      cmds.add(Cmd.requestPrimaryDeviceAttributesReport());
      cmds.add(Cmd.requestTerminalVersionReport());
    }

    if (enableRenderMetricsInjection) {
      cmds.add(
        Cmd.listen<RenderMetricsInjection>(
          RenderMetricsInjector.instance.stream,
          onData: (injection) => _RenderMetricsInjectionMsg(injection),
        ),
      );
    }

    final initCmd = _tree.collectHandleInit();
    if (initCmd != null) cmds.add(initCmd);
    return ParallelCmd(cmds);
  }

  Cmd? _coalesceCommands(List<Cmd> cmds) {
    if (cmds.isEmpty) return null;
    if (cmds.length == 1) return cmds.first;
    final hasRuntimeManaged = cmds.any(
      (cmd) => cmd is ParallelCmd || cmd is EveryCmd || cmd is StreamCmd,
    );
    return hasRuntimeManaged ? ParallelCmd(cmds) : Cmd.batch(cmds);
  }

  bool _updateSessionImageCapabilities(Msg msg) {
    return switch (msg) {
      PrimaryDeviceAttributesMsg(:final attrs) =>
        _sessionImageCapabilities.updateFromEvent(
          PrimaryDeviceAttributesEvent(attrs),
        ),
      TerminalVersionMsg(:final version) =>
        _sessionImageCapabilities.updateFromEvent(TerminalVersionEvent(version)),
      _ => false,
    };
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];

    if (TuiTrace.enabled) {
      TuiTrace.log('widget_app.update start ${msg.runtimeType}');
    }

    if (msg is KeyMsg) {
      _recordKeyTimestamp();
    }

    if (msg is FrameTickMsg) {
      if (_debugOverlayEnabled) {
        _overlayDirty = true;
      }
      if (!handleFrameTick) {
        return (this, null);
      }
    }

    // --- F12 toggles the built-in debug overlay ---
    if (msg is KeyMsg && msg.key.type == KeyType.f12) {
      _debugOverlayEnabled = !_debugOverlayEnabled;
      _runtimeDebugOverlay = _runtimeDebugOverlay.setEnabled(
        _debugOverlayEnabled,
      );
      _runtimeDebugOverlay = _positionRuntimeOverlay(_runtimeDebugOverlay);
      _overlayDirty = true;
      return (this, null);
    }

    if (msg is _RenderMetricsInjectionMsg) {
      _applyRenderMetricsInjection(msg.injection);
      return (this, null);
    }

    // Store runtime render metrics but avoid forcing full-tree rebuilds for
    // WidgetApp's built-in overlay. We compose that overlay outside the tree
    // from a cached base view (split-dashboard style).
    if (msg is RenderMetricsMsg) {
      _applyRenderMetricsInjection(
        RenderMetricsInjection(metrics: msg.metrics),
      );
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
          child: _currentRoot(),
        ),
      );
      _runtimeDebugOverlay = _runtimeDebugOverlay.copyWith(
        terminalWidth: msg.width,
        terminalHeight: msg.height,
      );
      _runtimeDebugOverlay = _positionRuntimeOverlay(_runtimeDebugOverlay);
      if (_debugOverlayEnabled) {
        _overlayDirty = true;
      }
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
        return (this, _coalesceCommands(cmds));
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

          // Broadcast raw mouse only when needed for out-of-hit housekeeping
          // (hover-exit and selection-finalize outside bounds). Avoid doing
          // this for wheel/press to prevent whole-tree traversals during
          // scroll bursts.
          final isWheelLike =
              msg.action == MouseAction.wheel ||
              msg.button == MouseButton.wheelUp ||
              msg.button == MouseButton.wheelDown ||
              msg.button == MouseButton.wheelLeft ||
              msg.button == MouseButton.wheelRight;
          // Press events are already delivered through hit-test bubbling.
          // Re-broadcasting press globally can let unrelated widgets react to
          // the same click (and potentially steal mouse capture), which breaks
          // controls like draggable scroll thumbs.
          final shouldBroadcastRawMouse =
              !isWheelLike && msg.action != MouseAction.press;
          if (shouldBroadcastRawMouse) {
            final broadcastCmd = _tree.dispatch(msg);
            if (broadcastCmd != null) cmds.add(broadcastCmd);
          }

          // Pick up any additional dirty flags from the broadcast.
          root = _currentRoot();
          _dirty = _dirty || _tree.hasDirty || _tree.hasPaintDirty;
          if (TuiTrace.enabled) {
            TuiTrace.log('widget_app.update end (hitTest) dirty=$_dirty');
          }
          return (this, _coalesceCommands(cmds));
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

    final imageCapabilitiesChanged =
        _imageAutoMode == ImageAutoMode.sessionCapabilities &&
        _updateSessionImageCapabilities(msg);

    root = _currentRoot();
    if (msg is BackgroundColorMsg) {
      // Adaptive theme state lives outside the element tree. When the terminal
      // reports a new background color, rebuild the root so widgets that read
      // ThemeScope/current theme in build() update immediately without waiting
      // for an unrelated resize or input event.
      _tree.root.markNeedsBuild();
      _dirty = true;
    } else if (msg is WindowSizeMsg) {
      _dirty = true;
    } else {
      _dirty =
          _dirty ||
          imageCapabilitiesChanged ||
          hadDirtyBeforeDispatch ||
          _tree.hasDirty ||
          _tree.hasPaintDirty;
    }

    if (TuiTrace.enabled) {
      TuiTrace.log('widget_app.update end dirty=$_dirty');
    }

    return (this, _coalesceCommands(cmds));
  }

  @override
  Object view() {
    final preRenderBackgroundColor = _resolveTerminalBackgroundColor(
      backgroundColorBuilder?.call() ?? backgroundColor,
    );
    final backgroundChanged =
        preRenderBackgroundColor != _cachedBackgroundColor;

    final canReuseCachedBase =
        !_dirty &&
        !_tree.hasDirty &&
        !_tree.hasPaintDirty &&
        _cachedView != null;

    if (!_dirty &&
        !_tree.hasDirty &&
        !backgroundChanged &&
        !_overlayDirty &&
        _cachedViewObject != null &&
        !_tree.hasPaintDirty) {
      if (TuiTrace.enabled) {
        TuiTrace.log('widget_view cache hit');
      }
      return _cachedViewObject!;
    }

    late String baseContent;
    if (canReuseCachedBase) {
      baseContent = _cachedView!;
    } else {
      final Stopwatch? sw = TuiTrace.enabled ? Stopwatch() : null;
      sw?.start();
      baseContent = withImageAutoConfiguration(
        mode: imageAutoMode,
        capabilities: _sessionImageCapabilities,
        callback: _tree.render,
      );
      sw?.stop();
      if (sw != null) {
        TuiTrace.log('widget_view render ${sw.elapsedMicroseconds}us');
      }

      _cachedView = baseContent;
      _dirty = false;
    }

    _recordAndPublishKeyRenderLatency();

    var composedContent = baseContent;
    if (_debugOverlayEnabled) {
      composedContent = _runtimeDebugOverlay.compose(baseContent);
    }

    final resolvedBackgroundColor = _resolveTerminalBackgroundColor(
      backgroundColorBuilder?.call() ?? backgroundColor,
    );
    _cachedBackgroundColor = resolvedBackgroundColor;
    _overlayDirty = false;

    if (resolvedBackgroundColor != null) {
      final viewObj = View(
        content: composedContent,
        backgroundColor: resolvedBackgroundColor,
      );
      _cachedViewObject = viewObj;
      return viewObj;
    }
    _cachedViewObject = composedContent;
    return composedContent;
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

  void _recordKeyTimestamp() {
    _pendingKeyTimestampsUs.addLast(_latencyClock.elapsedMicroseconds);
    while (_pendingKeyTimestampsUs.length > _maxPendingKeySamples) {
      _pendingKeyTimestampsUs.removeFirst();
    }
  }

  void _recordAndPublishKeyRenderLatency() {
    if (_pendingKeyTimestampsUs.isEmpty) return;

    final renderedAtUs = _latencyClock.elapsedMicroseconds;
    while (_pendingKeyTimestampsUs.isNotEmpty) {
      final startedAtUs = _pendingKeyTimestampsUs.removeFirst();
      final latencyUs = renderedAtUs - startedAtUs;
      if (latencyUs >= 0) {
        _keyRenderLatencyUs.add(latencyUs);
      }
    }

    if (_keyRenderLatencyUs.isEmpty) return;

    final overflow = _keyRenderLatencyUs.length - _maxKeyRenderSamples;
    if (overflow > 0) {
      _keyRenderLatencyUs.removeRange(0, overflow);
    }

    final p50Us = _percentileMicros(_keyRenderLatencyUs, 0.50);
    final p95Us = _percentileMicros(_keyRenderLatencyUs, 0.95);
    final changed = _metricsHolder.applyInjection(
      RenderMetricsInjection(
        upsertEntries: <String, String>{
          'Key->Render p50': '${(p50Us / 1000.0).toStringAsFixed(2)}ms',
          'Key->Render p95': '${(p95Us / 1000.0).toStringAsFixed(2)}ms',
          'Key->Render n': '${_keyRenderLatencyUs.length}',
        },
      ),
    );
    if (!changed) return;

    _runtimeDebugOverlay = _runtimeDebugOverlay.copyWith(
      customMetrics: _metricsHolder.customMetrics,
    );
    if (_debugOverlayEnabled) {
      _runtimeDebugOverlay = _positionRuntimeOverlay(_runtimeDebugOverlay);
    }
  }

  int _percentileMicros(List<int> samplesUs, double percentile) {
    if (samplesUs.isEmpty) return 0;

    final clamped = percentile < 0
        ? 0.0
        : percentile > 1
        ? 1.0
        : percentile;
    final sorted = List<int>.from(samplesUs)..sort();
    final index = ((sorted.length - 1) * clamped).round();
    return sorted[index];
  }

  void _applyRenderMetricsInjection(RenderMetricsInjection injection) {
    final changed = _metricsHolder.applyInjection(injection);
    if (!changed) return;

    _latestRenderMetrics = _metricsHolder.metrics;
    _runtimeDebugOverlay = _runtimeDebugOverlay.copyWith(
      metrics: _latestRenderMetrics,
      customMetrics: _metricsHolder.customMetrics,
    );
    if (_debugOverlayEnabled) {
      _runtimeDebugOverlay = _positionRuntimeOverlay(_runtimeDebugOverlay);
      _overlayDirty = true;
    }

    // Legacy/manual overlays rendered inside the widget tree still need
    // a tree update to repaint with the new holder value.
    final rootWidget = _currentRoot();
    if (rootWidget is DebugOverlay || rootWidget is PerformanceOverlay) {
      _tree.update(
        _MediaQueryHost(
          key: _mediaQueryKey,
          data: _mediaQueryData,
          metricsHolder: _metricsHolder,
          child: _currentRoot(),
        ),
      );
      _dirty = true;
    }
  }

  Widget _currentRoot() {
    final widget = _tree.root.widget;
    if (widget is _MediaQueryHost) {
      return widget.child;
    }
    return widget;
  }

  DebugOverlayModel _positionRuntimeOverlay(DebugOverlayModel overlay) {
    final width = _mediaQueryData.size.width.toInt();
    final height = _mediaQueryData.size.height.toInt();
    if (width <= 0 || height <= 0) return overlay;

    final panelWidth = overlay.panelWidth;
    final panelHeight = overlay.panelHeight;
    final maxX = (width - panelWidth).clamp(0, width);
    final maxY = (height - panelHeight).clamp(0, height);

    final (x, y) = switch (debugOverlayPosition) {
      DebugOverlayPosition.topLeft => (0, 0),
      DebugOverlayPosition.topRight => (maxX, 0),
      DebugOverlayPosition.bottomLeft => (0, maxY),
      DebugOverlayPosition.bottomRight => (maxX, maxY),
    };

    return overlay.copyWith(
      terminalWidth: width,
      terminalHeight: height,
      panelX: x,
      panelY: y,
      dragging: false,
    );
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

final class _RenderMetricsInjectionMsg extends Msg {
  const _RenderMetricsInjectionMsg(this.injection);

  final RenderMetricsInjection injection;
}
