/// Element tree for widgets.
@experimental
library;

import 'dart:collection';

import 'package:meta/meta.dart' show experimental;

import 'package:artisanal/tui.dart'
    show
        BackgroundColorMsg,
        Cmd,
        EveryCmd,
        DegradationLevel,
        HitTestMouseMsg,
        MouseMsg,
        MouseAction,
        ParallelCmd,
        Msg,
        RenderMetrics,
        StreamCmd,
        TraceTag,
        TuiTrace,
        View,
        KeyMsg;
import 'framework.dart';
import 'key.dart';
import '../layout/geometry.dart' show BoxConstraints, HitTestResult;
import '../rendering/render_object.dart';
import '../rendering/render_layout.dart'
    show RenderRow, RenderColumn, FlexParentData, RenderFlexFit;
import '../layout/layout_widgets.dart'
    show
        Flexible,
        Spacer,
        FlexFit,
        Positioned,
        StackParentData,
        RenderStack,
        TUIErrorWidget;
import '../theme/theme.dart' show updateThemeFromBackground;
import 'widget.dart';
import '../app/performance.dart';
import 'accessibility.dart';

const int _elementTreeRenderTraceThresholdUs = 5000;

final Expando<Element> _elementForWidget = Expando<Element>('widgetElement');

/// Returns the mounted [Element] associated with [widget], if any.
Element? elementOf(Widget widget) => _elementForWidget[widget];

void _bindElement(Widget widget, Element element) {
  _elementForWidget[widget] = element;
}

/// Creates an element for a widget.
Element createElement(Widget widget) {
  if (widget is StatefulWidget) {
    return StatefulElement(widget);
  }
  if (widget is StatelessWidget) {
    return StatelessElement(widget);
  }
  if (widget is InheritedWidget) {
    return InheritedElement(widget);
  }
  if (widget is RenderObjectWidget) {
    return RenderObjectElement(widget);
  }
  return WidgetElement(widget);
}

/// A mounted widget instance in the tree.
abstract class Element {
  Element(this.widget) {
    (context as _ElementBuildContext)._bind(this);
    _bindElement(widget, this);
  }

  Widget widget;
  Element? parent;
  final List<Element> _children = [];
  late final UnmodifiableListView<Element> _childrenView =
      UnmodifiableListView<Element>(_children);
  final BuildContext context = _ElementBuildContext();
  BuildOwner? _owner;
  bool _dirty = false;
  bool _isRebuilding = false;
  int _subtreeFocusCacheEpoch = -1;
  bool _subtreeFocusCacheValue = false;

  /// The child elements for this node, in paint order.
  List<Element> get children => _childrenView;

  /// Mounts this element under [parent] and performs its initial build.
  void mount(Element? parent) {
    this.parent = parent;
    _owner?.queueMountInitCmd(widget.handleInit());
    markNeedsBuild();
    rebuild();
  }

  /// Updates this element with a new widget configuration.
  void update(Widget newWidget) {
    widget = newWidget;
    _bindElement(widget, this);
  }

  /// Rebuilds this element if it is currently dirty.
  void rebuild() {
    if (!_dirty) return;
    _isRebuilding = true;
    try {
      _dirty = false;
      // Ensure the element is removed from the dirty set once rebuilt.
      // Without this, the dirty queue grows unbounded and render time
      // increases with each frame.
      _owner?.didRebuild(this);
      try {
        updateChildren(build());
      } catch (error, stackTrace) {
        final details = stackTrace.toString().split('\n').take(6).join('\n');
        updateChildren([
          TUIErrorWidget(
            message: 'Build failed in ${widget.runtimeType}: $error',
            details: details,
          ),
        ]);
      }
    } finally {
      _isRebuilding = false;
    }
  }

  /// Ensures the element is built before it is rendered.
  void ensureBuilt() {
    if (_dirty) rebuild();
  }

  /// Marks this element dirty so it participates in the next build scope.
  void markNeedsBuild() {
    _markDirty();
  }

  /// Whether the [BuildOwner] managing this element had dirty elements
  /// during the current frame's build phase.
  ///
  /// This is useful for render objects to determine if cached paint output
  /// might be stale because a descendant was rebuilt.
  bool get hadBuildThisFrame => _owner?.hadBuildThisFrame ?? false;

  /// Schedules a repaint and invalidates ancestor render caches.
  void markNeedsPaint() {
    _owner?.schedulePaint();
    _markRenderSubtreeNeedsPaint(invalidateDescendantCaches: true);
    _markRenderAncestorsNeedsPaint(invalidateDescendantCaches: true);
  }

  /// Schedules a repaint for scroll-only changes.
  ///
  /// Marks the relevant render subtree and ancestors as paint-dirty without
  /// forcing descendant cache invalidation.
  void markNeedsPaintScrollOnly() {
    _owner?.schedulePaint();
    _markRenderSubtreeNeedsPaint(invalidateDescendantCaches: false);
    _markRenderAncestorsNeedsPaint(invalidateDescendantCaches: false);
  }

  /// Captures mouse events for this element subtree.
  void captureMouse() {
    _owner?.captureMouse(this);
  }

  /// Releases mouse capture for this element subtree.
  void releaseMouse() {
    _owner?.releaseMouse(this);
  }

  RenderObjectElement? _renderObjectHost() {
    Element? current = this;
    while (current != null) {
      if (current is RenderObjectElement) return current;
      current = current.parent;
    }
    return null;
  }

  void _markRenderSubtreeNeedsPaint({
    required bool invalidateDescendantCaches,
  }) {
    void visit(Element element) {
      if (element is RenderObjectElement) {
        if (invalidateDescendantCaches) {
          element.renderObject.markDescendantNeedsPaint();
        } else {
          element.renderObject.markNeedsPaintOnly();
        }
        return;
      }
      for (final child in element._children) {
        visit(child);
      }
    }

    visit(this);
  }

  void _markRenderAncestorsNeedsPaint({
    required bool invalidateDescendantCaches,
  }) {
    Element? current = parent;
    while (current != null) {
      if (current is RenderObjectElement) {
        if (invalidateDescendantCaches) {
          current.renderObject.markDescendantNeedsPaint();
        } else {
          current.renderObject.markNeedsPaintOnly();
        }
      }
      current = current.parent;
    }
  }

  void _markDirty() {
    if (_dirty) return;
    _dirty = true;
    _owner?.scheduleBuildFor(this);
  }

  /// Current depth from the tree root.
  int get depth {
    var depth = 0;
    var current = parent;
    while (current != null) {
      depth++;
      current = current.parent;
    }
    return depth;
  }

  /// The render object hosted by this element, or `null`.
  RenderObject? get renderObject => null;

  bool _shouldRender(DegradationLevel degradationLevel) {
    final signal = widget.degradationSignal;
    if (!signal.focusBoost) {
      return widget.shouldRenderAt(
        degradationLevel,
        subtreeHasFocusedWidget: false,
      );
    }
    return widget.shouldRenderAt(
      degradationLevel,
      subtreeHasFocusedWidget: _subtreeHasFocusedWidget(),
    );
  }

  bool _subtreeHasFocusedWidget() {
    final owner = _owner;
    if (owner != null) {
      final epoch = owner.focusTraversalEpoch;
      if (_subtreeFocusCacheEpoch == epoch) {
        return _subtreeFocusCacheValue;
      }
    }

    final value = _computeSubtreeHasFocusedWidget();
    if (owner != null) {
      _subtreeFocusCacheEpoch = owner.focusTraversalEpoch;
      _subtreeFocusCacheValue = value;
    }
    return value;
  }

  bool _computeSubtreeHasFocusedWidget() {
    if (widget is FocusableWidget && (widget as FocusableWidget).focused) {
      return true;
    }
    for (final child in _children) {
      if (child._subtreeHasFocusedWidget()) {
        return true;
      }
    }
    return false;
  }

  /// Builds this element's child widget list.
  List<Widget> build() => widget.children;

  /// Reconcile old children with new widgets using Flutter's algorithm.
  ///
  /// Matching strategy:
  /// - Walk from the top matching by [Widget.canUpdate] (runtimeType + key).
  /// - Walk from the bottom matching the same way.
  /// - For the middle section, build a keyed map from old children that have
  ///   explicit keys. Unkeyed old children in the middle are unmounted.
  /// - Walk the middle of the new list, looking up matches by key.
  /// - Unmount any remaining unmatched keyed old children.
  void updateChildren(List<Widget> newWidgets) {
    if (_children.isEmpty && newWidgets.isEmpty) return;

    var structureChanged = false;

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = _children.length - 1;

    final newChildren = List<Element?>.filled(newWidgets.length, null);

    // Scan from the top: match while canUpdate holds.
    while (oldChildrenTop <= oldChildrenBottom &&
        newChildrenTop <= newChildrenBottom) {
      final oldChild = _children[oldChildrenTop];
      final newWidget = newWidgets[newChildrenTop];
      if (!Widget.canUpdate(oldChild.widget, newWidget)) break;
      oldChild.update(newWidget);
      newChildren[newChildrenTop] = oldChild;
      newChildrenTop++;
      oldChildrenTop++;
    }

    // Scan from the bottom: match while canUpdate holds.
    while (oldChildrenTop <= oldChildrenBottom &&
        newChildrenTop <= newChildrenBottom) {
      final oldChild = _children[oldChildrenBottom];
      final newWidget = newWidgets[newChildrenBottom];
      if (!Widget.canUpdate(oldChild.widget, newWidget)) break;
      // Don't update yet — just narrow the window. We update bottom matches
      // after the middle is resolved so indices are stable.
      oldChildrenBottom--;
      newChildrenBottom--;
    }

    // Build a keyed map of the remaining old children in the middle.
    final haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element>? oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, Element>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final oldChild = _children[oldChildrenTop];
        if (oldChild.widget.key != null) {
          oldKeyedChildren[oldChild.widget.key!] = oldChild;
        } else {
          // Unkeyed old children in the middle cannot be matched — unmount.
          oldChild.unmount();
          structureChanged = true;
        }
        oldChildrenTop++;
      }
    }

    // Walk the middle of the new list, matching by key.
    while (newChildrenTop <= newChildrenBottom) {
      Element? oldChild;
      final newWidget = newWidgets[newChildrenTop];
      if (newWidget.key != null && oldKeyedChildren != null) {
        oldChild = oldKeyedChildren[newWidget.key!];
        if (oldChild != null) {
          if (Widget.canUpdate(oldChild.widget, newWidget)) {
            oldKeyedChildren.remove(newWidget.key!);
          } else {
            oldChild = null;
          }
        }
      }

      if (oldChild != null) {
        oldChild.update(newWidget);
        newChildren[newChildrenTop] = oldChild;
      } else {
        final element = createElement(newWidget);
        element._attachOwner(_owner);
        element.mount(this);
        newChildren[newChildrenTop] = element;
        structureChanged = true;
      }
      newChildrenTop++;
    }

    // Now update the bottom matches (we deferred these earlier).
    assert(
      newWidgets.length - newChildrenTop == _children.length - oldChildrenTop,
    );
    newChildrenBottom = newWidgets.length - 1;
    oldChildrenBottom = _children.length - 1;
    while (newChildrenTop <= newChildrenBottom) {
      final oldChild = _children[oldChildrenTop];
      final newWidget = newWidgets[newChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));
      oldChild.update(newWidget);
      newChildren[newChildrenTop] = oldChild;
      newChildrenTop++;
      oldChildrenTop++;
    }

    // Unmount leftover keyed old children that were not reused.
    if (oldKeyedChildren != null && oldKeyedChildren.isNotEmpty) {
      for (final oldChild in oldKeyedChildren.values) {
        oldChild.unmount();
        structureChanged = true;
      }
    }

    _children
      ..clear()
      ..addAll(newChildren.cast<Element>());

    if (structureChanged) {
      final host = _renderObjectHost();
      if (host != null && !host._isRebuilding) {
        host._markDirty();
      }
    }
  }

  /// Renders this element subtree to a terminal string.
  String render({
    BoxConstraints? constraints,
    DegradationLevel degradationLevel = DegradationLevel.full,
  }) {
    if (!_shouldRender(degradationLevel)) {
      return '';
    }
    if (_dirty) {
      _owner?.buildScopeFor(_rootOfTree(this), this);
    }
    return _viewToString(widget.view());
  }

  /// Dispatches a message through interception, children, then self handlers.
  Cmd? dispatch(Msg msg) {
    rebuild();

    if (msg is BackgroundColorMsg) {
      updateThemeFromBackground(msg.hex);
    }

    // --- 1. Interception Phase (Top-down) ---
    // Widgets can override handleIntercept to catch messages before children.
    Cmd? interceptCmd;
    if (this is StatefulElement) {
      interceptCmd = (this as StatefulElement).state.handleIntercept(msg);
    } else {
      final (newWidget, cmd) = widget.handleIntercept(msg);
      if (!identical(newWidget, widget)) {
        update(newWidget);
      }
      interceptCmd = cmd;
    }
    if (interceptCmd != null) return interceptCmd;

    // --- 2. Children Phase ---
    final cmds = <Cmd>[];
    final children = msg is KeyMsg ? _children.reversed : _children;
    for (final child in children) {
      final cmd = child.dispatch(msg);
      if (cmd != null) {
        // Keyboard events use a "one-winner" policy with bubbling.
        // If a child handled it, we stop propagation.
        if (msg is KeyMsg) return cmd;
        cmds.add(cmd);
      }
    }

    // --- 3. Self Phase (Bottom-up) ---
    Cmd? selfCmd;
    if (this is StatefulElement) {
      selfCmd = (this as StatefulElement).state.handleUpdate(msg);
    } else {
      final (newWidget, cmd) = widget.handleUpdate(msg);
      if (!identical(newWidget, widget)) {
        update(newWidget);
      }
      selfCmd = cmd;
    }

    if (selfCmd != null) {
      if (msg is KeyMsg) return selfCmd;
      cmds.add(selfCmd);
    }

    return _coalesceCommands(cmds);
  }

  /// Unmounts this element and all descendants.
  void unmount() {
    // Avoid retaining unmounted elements in the dirty set.
    _owner?.unscheduleBuildFor(this);
    _owner?.releaseMouse(this);
    for (final child in _children) {
      child.unmount();
    }
    _children.clear();
    parent = null;
  }

  void _attachOwner(BuildOwner? owner) {
    _owner = owner;
    for (final child in _children) {
      child._attachOwner(owner);
    }
  }
}

/// Schedules and rebuilds dirty elements.
class BuildOwner {
  /// Creates a build owner.
  BuildOwner({this.debugRebuilds = false});

  /// Enables per-element rebuild logging to stdout.
  final bool debugRebuilds;
  final Set<Element> _dirty = <Element>{};
  bool _needsPaint = false;
  Element? _mouseCapture;
  bool _hadBuildThisFrame = false;
  int _focusTraversalEpoch = 0;

  // Init commands from elements mounted after initial app startup.
  bool _captureMountInitCmds = false;
  final List<Cmd> _pendingMountInitCmds = <Cmd>[];

  // --- Frame timing instrumentation ---
  final List<WidgetFrameTimingCallback> _frameTimingCallbacks = [];
  final List<WidgetFrameTiming> _recentTimings = [];
  static const int _maxRecentTimings = 120;
  int _widgetFrameCount = 0;

  // Accumulated phase durations for the current frame.
  Duration _currentBuildDuration = Duration.zero;
  Duration _currentLayoutDuration = Duration.zero;
  Duration _currentPaintDuration = Duration.zero;

  /// Whether there are dirty elements waiting to rebuild.
  bool get hasDirty => _dirty.isNotEmpty;

  /// Whether a repaint has been requested for the current frame.
  bool get hasPaintDirty => _needsPaint;

  /// Monotonic epoch used to memoize subtree focus scans during a frame.
  int get focusTraversalEpoch => _focusTraversalEpoch;

  /// Whether any elements were rebuilt during the current frame's build phase.
  ///
  /// Set to `true` at the start of [beginFrame] if there are dirty elements,
  /// then cleared in [endFrame]. Render objects can check this to decide
  /// whether cached paint output is still valid.
  bool get hadBuildThisFrame => _hadBuildThisFrame;

  /// The element currently holding mouse capture, if any.
  Element? get mouseCapture => _mouseCapture;

  /// Starts collecting init commands from newly mounted elements.
  void enableMountInitCmdCapture() {
    _captureMountInitCmds = true;
  }

  /// Queues an init command produced by a newly mounted element.
  void queueMountInitCmd(Cmd? cmd) {
    if (!_captureMountInitCmds || cmd == null) return;
    _pendingMountInitCmds.add(cmd);
  }

  /// Drains queued mount-init commands.
  Cmd? drainMountInitCmds() {
    if (_pendingMountInitCmds.isEmpty) return null;
    final drained = _pendingMountInitCmds.toList();
    _pendingMountInitCmds.clear();
    return _coalesceCommands(drained);
  }

  /// Drops queued mount-init commands without returning them.
  void clearPendingMountInitCmds() {
    _pendingMountInitCmds.clear();
  }

  /// Recent widget frame timings (up to [_maxRecentTimings]).
  List<WidgetFrameTiming> get recentTimings =>
      List.unmodifiable(_recentTimings);

  /// Total widget frames rendered so far.
  int get widgetFrameCount => _widgetFrameCount;

  /// Registers a callback invoked after each widget frame with timing data.
  void addFrameTimingCallback(WidgetFrameTimingCallback callback) {
    _frameTimingCallbacks.add(callback);
  }

  /// Removes a previously registered frame timing callback.
  void removeFrameTimingCallback(WidgetFrameTimingCallback callback) {
    _frameTimingCallbacks.remove(callback);
  }

  /// Records layout duration accumulated by a [RenderObjectElement] during
  /// the current frame.
  void recordLayout(Duration duration) {
    _currentLayoutDuration += duration;
  }

  /// Records paint duration accumulated by a [RenderObjectElement] during
  /// the current frame.
  void recordPaint(Duration duration) {
    _currentPaintDuration += duration;
  }

  /// Returns a [PerformanceMetricsSnapshot] combining the given runtime
  /// metrics with widget-level timing data.
  PerformanceMetricsSnapshot performanceSnapshot(RenderMetrics? renderMetrics) {
    return PerformanceMetricsSnapshot(
      renderMetrics: renderMetrics,
      widgetTimings: List.unmodifiable(_recentTimings),
      widgetFrameCount: _widgetFrameCount,
    );
  }

  /// Schedules [element] to rebuild in the next build scope.
  void scheduleBuildFor(Element element) {
    _dirty.add(element);
  }

  /// Removes [element] from the dirty queue if present.
  void unscheduleBuildFor(Element element) {
    _dirty.remove(element);
  }

  /// Marks the frame as needing a paint pass.
  void schedulePaint() {
    _needsPaint = true;
  }

  /// Routes subsequent mouse messages to [element].
  void captureMouse(Element element) {
    _mouseCapture = element;
  }

  /// Clears mouse capture when [element] currently owns it.
  void releaseMouse(Element element) {
    if (identical(_mouseCapture, element)) {
      _mouseCapture = null;
    }
  }

  /// Notifies the owner that [element] finished rebuilding.
  void didRebuild(Element element) {
    _dirty.remove(element);
    // Track that a rebuild occurred even outside beginFrame's buildScope
    // (e.g., during dispatch).  This ensures that paint caches (like the
    // scroll viewport's) are invalidated when a child widget was rebuilt
    // during message dispatch before the render pass begins.
    _hadBuildThisFrame = true;

    // Mark render-object ancestors as paint-dirty so viewport/list caches can
    // invalidate only along the changed subtree path instead of relying on a
    // frame-global "some build happened" signal.
    Element? current = element;
    while (current != null) {
      if (current is RenderObjectElement) {
        current.renderObject.markDescendantNeedsPaint();
      }
      current = current.parent;
    }

    // Ensure a paint pass is scheduled even when this rebuild happened during
    // message dispatch (outside the normal build phase).
    _needsPaint = true;
  }

  /// Starts a frame by resetting accumulators and running the build phase.
  void beginFrame(Element root) {
    // Reset per-frame phase accumulators.
    _currentBuildDuration = Duration.zero;
    _currentLayoutDuration = Duration.zero;
    _currentPaintDuration = Duration.zero;
    _focusTraversalEpoch++;
    // Preserve any `true` value set by didRebuild() during the dispatch
    // phase that precedes this render pass.  Without `||`, elements rebuilt
    // during dispatch (e.g., a HoverTracker setState) would be invisible to
    // viewport paint-cache invalidation because their dirty flags were
    // already cleared before beginFrame runs.
    _hadBuildThisFrame = _hadBuildThisFrame || _dirty.isNotEmpty;
    buildScope(root);
  }

  /// Ends a frame and publishes collected timing information.
  void endFrame({Duration? totalDuration, Duration? buildDuration}) {
    _needsPaint = false;
    _hadBuildThisFrame = false;

    _widgetFrameCount++;

    final timing = WidgetFrameTiming(
      frameNumber: _widgetFrameCount,
      buildDuration: buildDuration ?? _currentBuildDuration,
      layoutDuration: _currentLayoutDuration,
      paintDuration: _currentPaintDuration,
      totalDuration: totalDuration ?? Duration.zero,
      timestamp: DateTime.now(),
    );

    _recentTimings.add(timing);
    if (_recentTimings.length > _maxRecentTimings) {
      _recentTimings.removeAt(0);
    }

    for (final callback in _frameTimingCallbacks) {
      callback(timing);
    }
  }

  /// Rebuilds all dirty elements that are descendants of [root].
  void buildScope(Element root) {
    if (_dirty.isEmpty) return;

    var safety = 0;
    while (_dirty.isNotEmpty && safety < 1000) {
      safety++;
      final candidates = _dirty.where((e) => _isDescendantOf(e, root)).toList();
      if (candidates.isEmpty) break;

      candidates.sort((a, b) => a.depth.compareTo(b.depth));

      final toBuild = <Element>[];
      final dirtySet = _dirty.toSet();
      for (final element in candidates) {
        if (_hasDirtyAncestor(element, dirtySet)) continue;
        toBuild.add(element);
      }

      if (toBuild.isEmpty) break;

      for (final element in toBuild) {
        if (!_dirty.remove(element)) continue;
        _logBuild(element);
        element.rebuild();
      }
    }
  }

  /// Rebuilds [element] when it is dirty and under [root].
  void buildScopeFor(Element root, Element element) {
    if (!_dirty.remove(element)) return;
    if (!_isDescendantOf(element, root)) return;
    _logBuild(element);
    element.rebuild();
  }

  void _logBuild(Element element) {
    if (!debugRebuilds) return;
    final label = element.widget.runtimeType.toString();
    final key = element.widget.key;
    final keyLabel = key is ValueKey<Object?>
        ? key.value.toString()
        : key.toString();
    // ignore: avoid_print
    print('BuildOwner: rebuild $label($keyLabel)');
  }

  bool _hasDirtyAncestor(Element element, Set<Element> dirty) {
    var current = element.parent;
    while (current != null) {
      if (dirty.contains(current)) return true;
      current = current.parent;
    }
    return false;
  }

  bool _isDescendantOf(Element element, Element root) {
    if (identical(element, root)) return true;
    var current = element.parent;
    while (current != null) {
      if (identical(current, root)) return true;
      current = current.parent;
    }
    return false;
  }
}

/// Default element for widgets without render objects.
class WidgetElement extends Element {
  WidgetElement(super.widget);

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    markNeedsBuild();
  }
}

/// Element implementation for [StatelessWidget] nodes.
class StatelessElement extends Element {
  StatelessElement(super.widget);

  @override
  List<Widget> build() {
    final built = (widget as StatelessWidget).build(context);
    return [built];
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    markNeedsBuild();
  }

  @override
  String render({
    BoxConstraints? constraints,
    DegradationLevel degradationLevel = DegradationLevel.full,
  }) {
    if (_dirty) {
      _owner?.buildScopeFor(_rootOfTree(this), this);
    }
    if (!_shouldRender(degradationLevel)) {
      return '';
    }
    if (_children.isEmpty) return '';
    return _children.first.render(
      constraints: constraints,
      degradationLevel: degradationLevel,
    );
  }
}

/// Element implementation for [InheritedWidget] nodes.
class InheritedElement extends Element {
  InheritedElement(InheritedWidget super.widget);

  final Set<Element> _dependents = <Element>{};

  /// Registers [element] as dependent on this inherited widget.
  void registerDependent(Element element) {
    _dependents.add(element);
  }

  @override
  String render({
    BoxConstraints? constraints,
    DegradationLevel degradationLevel = DegradationLevel.full,
  }) {
    ensureBuilt();
    if (!_shouldRender(degradationLevel)) {
      return '';
    }
    if (_children.isEmpty) return '';
    return _children.first.render(
      constraints: constraints,
      degradationLevel: degradationLevel,
    );
  }

  @override
  void update(Widget newWidget) {
    final oldWidget = widget as InheritedWidget;
    super.update(newWidget);
    markNeedsBuild();

    if ((newWidget as InheritedWidget).updateShouldNotify(oldWidget)) {
      for (final dependent in _dependents) {
        dependent.markNeedsBuild();
      }
    }
  }
}

/// Element implementation for [StatefulWidget] nodes.
class StatefulElement extends Element implements StateSetter {
  StatefulElement(StatefulWidget widget)
    : state = widget.createState(),
      super(widget) {
    state.attach(this, context, widget);
  }

  @override
  void mount(Element? parent) {
    this.parent = parent;
    state.initState();
    _owner?.queueMountInitCmd(widget.handleInit());
    _owner?.queueMountInitCmd(state.handleInit());
    markNeedsBuild();
    rebuild();
  }

  final State state;

  /// Commands returned by [State.didUpdateWidget] that have not yet been
  /// drained by [dispatch].  This bridges the gap between the reconciliation
  /// phase (where `didUpdateWidget` runs but cannot feed Cmds into the TEA
  /// loop directly) and the dispatch phase (where Cmds are collected and
  /// returned to the runtime).
  final List<Cmd> _pendingUpdateCmds = [];

  @override
  void update(Widget newWidget) {
    final oldWidget = widget as StatefulWidget;
    super.update(newWidget);
    state.attach(this, context, newWidget as StatefulWidget);
    final cmd = state.didUpdateWidget(oldWidget);
    if (cmd != null) _pendingUpdateCmds.add(cmd);
    markNeedsBuild();
  }

  @override
  List<Widget> build() {
    final built = state.build(context);
    return [built];
  }

  @override
  String render({
    BoxConstraints? constraints,
    DegradationLevel degradationLevel = DegradationLevel.full,
  }) {
    if (_dirty) {
      _owner?.buildScopeFor(_rootOfTree(this), this);
    }
    if (!_shouldRender(degradationLevel)) {
      return '';
    }
    if (_children.isEmpty) return '';
    return _children.first.render(
      constraints: constraints,
      degradationLevel: degradationLevel,
    );
  }

  @override
  Cmd? dispatch(Msg msg) {
    // Drain any pending commands from didUpdateWidget before normal dispatch.
    final pending = _drainPendingCmds();
    final baseCmd = super.dispatch(msg);
    return _coalesceCommands([
      ?pending,
      ?baseCmd,
    ]);
  }

  /// Drains and returns any pending commands accumulated by [didUpdateWidget],
  /// or `null` if there are none.
  Cmd? _drainPendingCmds() {
    if (_pendingUpdateCmds.isEmpty) return null;
    final cmd = _pendingUpdateCmds.length == 1
        ? _pendingUpdateCmds.first
        : Cmd.batch(_pendingUpdateCmds.toList());
    _pendingUpdateCmds.clear();
    return cmd;
  }

  @override
  void unmount() {
    state.dispose();
    state.detach();
    super.unmount();
  }
}

/// Element for render object widgets.
class RenderObjectElement extends Element {
  RenderObjectElement(RenderObjectWidget super.widget)
    : _renderObject = widget.createRenderObject() {
    _renderObject.element = this;
  }

  final RenderObject _renderObject;

  @override
  RenderObject get renderObject => _renderObject;

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    (newWidget as RenderObjectWidget).updateRenderObject(renderObject);
    markNeedsBuild();
  }

  @override
  void rebuild() {
    super.rebuild();
    _buildDescendants(degradationLevel: DegradationLevel.full);
    _syncRenderChildren(degradationLevel: DegradationLevel.full);
  }

  @override
  String render({
    BoxConstraints? constraints,
    DegradationLevel degradationLevel = DegradationLevel.full,
  }) {
    if (!_shouldRender(degradationLevel)) {
      return '';
    }
    if (_dirty) {
      _owner?.buildScopeFor(_rootOfTree(this), this);
    }
    _buildDescendants(degradationLevel: degradationLevel);
    _syncRenderChildren(degradationLevel: degradationLevel);
    final roType = TuiTrace.enabled ? renderObject.runtimeType.toString() : '';
    final span = TuiTrace.begin(
      'ro.render',
      tag: TraceTag.render,
      extra: roType,
    );
    final layoutSw = Stopwatch()..start();
    renderObject.layout(constraints ?? BoxConstraints());
    layoutSw.stop();

    final paintSw = Stopwatch()..start();
    final result = renderObject.paint();
    paintSw.stop();

    // A frame consumed the latest paint output for this subtree.
    // Keep paint-dirty flags edge-triggered so unchanged branches can be
    // skipped by parent render objects on subsequent frames.
    renderObject.clearPaintDirtySubtree();

    // Report phase durations to BuildOwner for frame timing.
    _owner?.recordLayout(layoutSw.elapsed);
    _owner?.recordPaint(paintSw.elapsed);

    span.end(
      extra:
          'layout=${layoutSw.elapsedMicroseconds}us '
          'paint=${paintSw.elapsedMicroseconds}us '
          'size=${renderObject.size.width.toInt()}x${renderObject.size.height.toInt()}',
    );

    return result;
  }

  @override
  void unmount() {
    _detachFromParent();
    (widget as RenderObjectWidget).didUnmountRenderObject(renderObject);
    renderObject.dispose();
    super.unmount();
  }

  void _syncRenderChildren({required DegradationLevel degradationLevel}) {
    for (final child in List<RenderObject>.from(renderObject.children)) {
      renderObject.detach(child);
    }
    if (renderObject is RenderRow || renderObject is RenderColumn) {
      final flexChildren = <RenderObject>[];
      final flexData = <RenderObject, FlexParentData>{};

      for (final child in _children) {
        final info = _flexInfoFor(child.widget);
        for (final renderChild in _collectRenderChildren(
          child,
          degradationLevel: degradationLevel,
        )) {
          flexChildren.add(renderChild);
          if (info != null) {
            flexData[renderChild] = info;
          }
        }
      }

      for (final renderChild in flexChildren) {
        renderChild.parentData =
            flexData[renderChild] ??
            const FlexParentData(flex: 0, fit: RenderFlexFit.loose);
        renderObject.attach(renderChild);
      }
      return;
    }

    if (renderObject is RenderStack) {
      final stackChildren = <RenderObject>[];
      final stackData = <RenderObject, StackParentData>{};

      for (final child in _children) {
        final info = _stackInfoFor(child.widget);
        for (final renderChild in _collectRenderChildren(
          child,
          degradationLevel: degradationLevel,
        )) {
          stackChildren.add(renderChild);
          if (info != null) {
            stackData[renderChild] = info;
          }
        }
      }

      for (final renderChild in stackChildren) {
        renderChild.parentData = stackData[renderChild];
        renderObject.attach(renderChild);
      }
      return;
    }

    for (final child in _children) {
      for (final renderChild in _collectRenderChildren(
        child,
        degradationLevel: degradationLevel,
      )) {
        renderObject.attach(renderChild);
      }
    }
  }

  void _buildDescendants({required DegradationLevel degradationLevel}) {
    for (final child in _children) {
      _ensureSubtreeBuilt(child, degradationLevel: degradationLevel);
    }
  }

  void _ensureSubtreeBuilt(
    Element element, {
    required DegradationLevel degradationLevel,
  }) {
    if (!element._shouldRender(degradationLevel)) {
      return;
    }
    element.ensureBuilt();
    for (final child in element._children) {
      _ensureSubtreeBuilt(child, degradationLevel: degradationLevel);
    }
  }

  Iterable<RenderObject> _collectRenderChildren(
    Element element, {
    required DegradationLevel degradationLevel,
  }) sync* {
    if (!element._shouldRender(degradationLevel)) {
      return;
    }
    if (element is RenderObjectElement) {
      yield element.renderObject;
      return;
    }

    if (!const bool.fromEnvironment('dart.vm.product') &&
        element is WidgetElement &&
        !element.widget.debugRenderObjectPassthrough) {
      throw AssertionError(
        'Non-render widget `${element.widget.runtimeType}` was placed under '
        'render-object parent `${widget.runtimeType}`.\n'
        'Widgets that render visual output must extend StatelessWidget, '
        'StatefulWidget, or RenderObjectWidget so they are preserved during '
        'render-child flattening.\n'
        'If this widget is an intentional pass-through wrapper, override '
        '`debugRenderObjectPassthrough => true`.',
      );
    }

    for (final child in element._children) {
      yield* _collectRenderChildren(child, degradationLevel: degradationLevel);
    }
  }

  FlexParentData? _flexInfoFor(Widget widget) {
    if (widget is Flexible) {
      return FlexParentData(
        flex: widget.flex,
        fit: widget.fit == FlexFit.tight
            ? RenderFlexFit.tight
            : RenderFlexFit.loose,
      );
    }
    if (widget is Spacer && widget.flex != null) {
      return FlexParentData(flex: widget.flex!, fit: RenderFlexFit.tight);
    }
    return null;
  }

  StackParentData? _stackInfoFor(Widget widget) {
    if (widget is Positioned) {
      return StackParentData(
        left: widget.left,
        right: widget.right,
        top: widget.top,
        bottom: widget.bottom,
        width: widget.width,
        height: widget.height,
      );
    }
    return null;
  }

  void _detachFromParent() {
    var current = parent;
    while (current != null) {
      if (current is RenderObjectElement) {
        current.renderObject.detach(renderObject);
        break;
      }
      current = current.parent;
    }
  }
}

/// Owns an element tree and provides rendering.
class ElementTree {
  /// Creates and mounts an element tree for [rootWidget].
  ElementTree(this.rootWidget, {BuildOwner? owner})
    : _owner = owner ?? BuildOwner() {
    _root = createElement(rootWidget);
    _root._attachOwner(_owner);
    _root.mount(null);
    _owner.enableMountInitCmdCapture();
  }

  /// Root widget used to configure this tree.
  Widget rootWidget;
  late final Element _root;
  BoxConstraints? _rootConstraints;
  DegradationLevel _degradationLevel = DegradationLevel.full;
  final BuildOwner _owner;

  /// The mounted root element.
  Element get root => _root;

  /// The [BuildOwner] managing this tree's build lifecycle and frame timing.
  BuildOwner get owner => _owner;

  /// Whether the tree has pending build work.
  bool get hasDirty => _owner.hasDirty;

  /// Whether the tree has pending paint work.
  bool get hasPaintDirty => _owner.hasPaintDirty;

  /// The element currently capturing mouse input.
  Element? get mouseCapture => _owner.mouseCapture;

  /// Sets the render-time degradation level used by this tree.
  void setDegradationLevel(DegradationLevel level) {
    _degradationLevel = level;
  }

  /// Dispatches [msg] directly to [element].
  Cmd? dispatchTo(Element element, Msg msg) {
    final cmd = element.dispatch(msg);
    _flushDirtyBuilds();
    final mountInit = _owner.drainMountInitCmds();
    return _coalesceCommands([
      ?cmd,
      ?mountInit,
    ]);
  }

  /// Dispatches [msg] directly to the provided [StatefulElement]s.
  ///
  /// Unlike [dispatch], this does not traverse descendants. It is intended
  /// for targeted follow-up delivery such as hover-exit housekeeping for
  /// elements that were hit on the previous mouse-motion frame but are no
  /// longer under the pointer.
  Cmd? dispatchToStatefulElements(
    Iterable<StatefulElement> elements,
    Msg msg,
  ) {
    final cmds = <Cmd>[];
    final deferBuildFlush = msg is MouseMsg && msg.action == MouseAction.motion;
    for (final element in elements) {
      if (!element.state.mounted) continue;
      final cmd = element.state.handleUpdate(msg);
      if (cmd != null) cmds.add(cmd);
    }
    final mountInit = deferBuildFlush
        ? null
        : () {
            _flushDirtyBuilds();
            return _owner.drainMountInitCmds();
          }();
    return _coalesceCommands([
      ...cmds,
      ?mountInit,
    ]);
  }

  /// Dispatches [msg] by walking UP the element tree from [startElement] to
  /// the root, calling `handleUpdate` on each [StatefulElement]'s state.
  ///
  /// This mirrors Flutter's pointer-event bubbling: the deepest hit element's
  /// ancestors get to handle the event. For most hit-tested mouse events the
  /// first one that produces a [Cmd] wins, but motion events continue bubbling
  /// so nested hover handlers can all observe the same enter/update frame.
  ///
  /// When [visited] is provided, elements already in the set are skipped
  /// and newly visited elements are added.  This prevents a
  /// [GestureDetector] from processing the same event multiple times when
  /// several child render objects bubble up to the same ancestor.
  ///
  /// Use this for [HitTestMouseMsg] dispatch so that a [GestureDetector]
  /// (which is a [StatefulWidget] without its own render object) receives
  /// the event even though only its child's render object was hit.
  Cmd? dispatchBubbleUp(
    Element startElement,
    Msg msg, {
    Set<Element>? visited,
  }) {
    Element? current = startElement;
    final bubbleCmds = <Cmd>[];
    final continueOnMotion =
        msg is HitTestMouseMsg && msg.event.action == MouseAction.motion;
    final deferBuildFlush = continueOnMotion;
    while (current != null) {
      if (current is StatefulElement) {
        if (visited != null) {
          if (!visited.add(current)) {
            // Already dispatched to this element — skip.
            current = current.parent;
            continue;
          }
        }
        final cmd = current.state.handleUpdate(msg);
        if (cmd != null) {
          bubbleCmds.add(cmd);
          if (!continueOnMotion) {
            break;
          }
        }
      }
      current = current.parent;
    }
    final mountInit = deferBuildFlush
        ? null
        : () {
            _flushDirtyBuilds();
            return _owner.drainMountInitCmds();
          }();
    return _coalesceCommands([...bubbleCmds, ?mountInit]);
  }

  /// Overrides constraints used when rendering the root.
  void setRootConstraints(BoxConstraints? constraints) {
    _rootConstraints = constraints;
  }

  /// Updates the tree with a new root widget configuration.
  void update(Widget widget) {
    rootWidget = widget;
    _root.update(widget);
  }

  /// Dispatches [msg] to the root element.
  Cmd? dispatch(Msg msg) {
    final cmd = _root.dispatch(msg);
    _flushDirtyBuilds();
    final mountInit = _owner.drainMountInitCmds();
    return _coalesceCommands([
      ?cmd,
      ?mountInit,
    ]);
  }

  void _flushDirtyBuilds() {
    if (!_owner.hasDirty) return;
    _owner.buildScope(_root);
    if (_owner.hadBuildThisFrame) {
      _owner.schedulePaint();
    }
  }

  /// Collects initialization commands from widgets and state objects.
  Cmd? collectHandleInit() {
    final cmds = <Cmd>[];
    void visit(Element element) {
      final cmd = element.widget.handleInit();
      if (cmd != null) cmds.add(cmd);
      // Also collect init commands from State for StatefulElements.
      if (element is StatefulElement) {
        final stateCmd = element.state.handleInit();
        if (stateCmd != null) cmds.add(stateCmd);
      }
      for (final child in element._children) {
        visit(child);
      }
    }

    visit(_root);
    // Drop any mount-init queue collected during startup traversal to avoid
    // duplicate initialization when startup init commands are executed.
    _owner.clearPendingMountInitCmds();
    return cmds.isEmpty ? null : ParallelCmd(cmds);
  }

  /// Renders one widget frame and returns terminal output.
  String render() {
    final totalSw = Stopwatch()..start();
    final buildSw = Stopwatch()..start();
    _owner.beginFrame(_root);
    buildSw.stop();
    final output = _root.render(
      constraints: _rootConstraints,
      degradationLevel: _degradationLevel,
    );
    totalSw.stop();
    _owner.endFrame(
      totalDuration: totalSw.elapsed,
      buildDuration: buildSw.elapsed,
    );
    if (TuiTrace.enabled &&
        totalSw.elapsedMicroseconds >= _elementTreeRenderTraceThresholdUs) {
      TuiTrace.log(
        'element_tree.render root=${_root.widget.runtimeType} '
        '${totalSw.elapsedMicroseconds}us',
        tag: TraceTag.render,
      );
    }
    return output;
  }

  /// Hit-tests the render tree at the given terminal coordinates and returns
  /// a list of [HitTestElementEntry] objects, deepest first.
  ///
  /// Each entry contains the [Element] whose render object was hit and the
  /// local coordinates within that render object.
  ///
  /// Returns an empty list if nothing was hit (coordinates outside root).
  List<HitTestElementEntry> hitTestAt(double x, double y) {
    // Find the root render object.
    final rootRO = _findRootRenderObject(_root);
    if (rootRO == null) return const [];

    final result = HitTestResult();
    rootRO.hitTest(result, localX: x, localY: y);

    if (result.isEmpty) return const [];

    // Map render objects back to elements.
    final entries = <HitTestElementEntry>[];
    for (final hit in result.path) {
      final ro = hit.renderObject;
      if (ro is RenderObject && ro.element is Element) {
        entries.add(
          HitTestElementEntry(
            element: ro.element! as Element,
            localX: hit.localX,
            localY: hit.localY,
          ),
        );
      }
    }
    return entries;
  }

  /// Walks the element tree to find the root [RenderObject].
  static RenderObject? _findRootRenderObject(Element element) {
    if (element is RenderObjectElement) return element.renderObject;
    for (final child in element._children) {
      final ro = _findRootRenderObject(child);
      if (ro != null) return ro;
    }
    return null;
  }

  /// Unmounts the entire element tree.
  void unmount() => _root.unmount();

  /// Builds a deterministic accessibility tree from the current widget tree.
  ///
  /// Returns a best-effort snapshot used for diagnostics and parity testing.
  A11yTree buildA11yTree() {
    if (_owner.hasDirty) {
      _owner.buildScope(_root);
    }

    final nodes = <int, A11yNode>{};
    final widgetToNodeId = <Widget, int>{};

    int build(Element element, int? parentId, int childIndex, int depth) {
      final local = _a11yDescriptor(element.widget, childIndex);
      final id = _computeA11yId(
        parentId: parentId ?? -1,
        token: local,
        depth: depth,
      );

      final childIds = <int>[];
      for (var i = 0; i < element._children.length; i++) {
        final childId = build(element._children[i], id, i, depth + 1);
        childIds.add(childId);
      }

      final node = A11yNode(
        id: id,
        widget: element.widget,
        parentId: parentId,
        children: childIds,
        role: element.widget.accessibilityRole,
        label: element.widget.accessibilityLabel,
      );
      nodes[id] = node;
      widgetToNodeId[element.widget] = id;
      return id;
    }

    final rootId = build(_root, null, 0, 0);
    return A11yTree(
      rootId: rootId,
      nodes: Map<int, A11yNode>.unmodifiable(nodes),
      widgetToNodeId: Map<Widget, int>.unmodifiable(widgetToNodeId),
    );
  }
}

String _a11yDescriptor(Widget widget, int siblingIndex) {
  final key = widget.key;
  final keyPart = key == null ? 'idx:$siblingIndex' : 'key:$key';
  return '${widget.runtimeType}#$keyPart';
}

int _computeA11yId({
  required int parentId,
  required String token,
  required int depth,
}) {
  return fnv1a32('depth=$depth|parent=$parentId|$token');
}

/// Result of an element-level hit test — pairs an [Element] with the
/// local coordinates at which its render object was hit.
class HitTestElementEntry {
  const HitTestElementEntry({
    required this.element,
    required this.localX,
    required this.localY,
  });

  /// The hit element.
  final Element element;

  /// Local X coordinate relative to the hit render object.
  final double localX;

  /// Local Y coordinate relative to the hit render object.
  final double localY;
}

String _viewToString(Object v) {
  if (v is String) return v;
  if (v is View) return v.content;
  return v.toString();
}

Cmd? _coalesceCommands(List<Cmd> cmds) {
  if (cmds.isEmpty) return null;
  if (cmds.length == 1) return cmds.first;
  final hasRuntimeManaged = cmds.any(
    (cmd) => cmd is ParallelCmd || cmd is EveryCmd || cmd is StreamCmd,
  );
  return hasRuntimeManaged ? ParallelCmd(cmds) : Cmd.batch(cmds);
}

class _ElementBuildContext implements BuildContext {
  Element? _element;

  void _bind(Element element) {
    _element = element;
  }

  @override
  Widget get widget {
    final element = _element;
    if (element == null) {
      throw StateError('BuildContext is not bound to an element.');
    }
    return element.widget;
  }

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    var current = _element?.parent;
    while (current != null) {
      final widget = current.widget;
      if (widget is T) return widget;
      current = current.parent;
    }
    return null;
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>() {
    final element = _element;
    if (element == null) return null;

    var current = element.parent;
    while (current != null) {
      if (current.widget is T) {
        if (current is InheritedElement) {
          current.registerDependent(element);
        }
        return current.widget as T;
      }
      current = current.parent;
    }
    return null;
  }

  @override
  T? findAncestorStateOfType<T extends State>() {
    var current = _element?.parent;
    while (current != null) {
      if (current is StatefulElement && current.state is T) {
        return current.state as T;
      }
      current = current.parent;
    }
    return null;
  }
}

Element _rootOfTree(Element element) {
  var current = element;
  while (current.parent != null) {
    current = current.parent!;
  }
  return current;
}
