@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'dart:math' as math;

import 'package:artisanal/tui.dart'
    show
        Cmd,
        Msg,
        KeyMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        HitTestMouseMsg,
        ZoneInBoundsMsg,
        TraceTag,
        TuiTrace,
        globalZone;
import 'package:artisanal/bubbles.dart'
    show ViewportModel, ViewportKeyMap, ScrollbarChars, ViewportScrollPane;
import 'package:artisanal/style.dart' hide Padding;
import '../core/element.dart' show elementOf, Element, RenderObjectElement;
import '../core/framework.dart' show BuildContext, StatefulWidget, State;
import '../layout/geometry.dart'
    show BoxConstraints, Size, HitTestResult, Offset;
import '../rendering/render_object.dart';
import '../core/widget.dart';
import '../theme/theme.dart' show hasDarkBackground;
import '../theme/theme_scope.dart' show ThemeScope;
import '../layout/layout_widgets.dart' show EdgeInsets, Padding;
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/uv.dart' show Canvas, StyledString;

void _traceScroll(String message) {
  if (!TuiTrace.enabled) return;
  TuiTrace.log(message, tag: TraceTag.scroll);
}

/// Scroll controller interface for scrollable widgets.
abstract class ScrollController {
  /// Current scroll offset in rows.
  int get offset;

  /// Visible viewport extent in rows.
  int get viewportExtent;

  /// Total content extent in rows.
  int get contentExtent;

  /// Maximum scroll offset.
  int get maxOffset => math.max(0, contentExtent - viewportExtent);

  /// Scroll percentage in the range [0, 1].
  double get scrollPercent => maxOffset == 0 ? 0 : offset / maxOffset;

  /// Jumps to an absolute offset. Returns true if the offset changed.
  bool jumpTo(int offset);

  /// Scrolls by a delta. Returns true if the offset changed.
  bool scrollBy(int delta);

  /// Adds a listener that fires when the scroll offset changes.
  void addListener(void Function() listener);

  /// Removes a previously added listener.
  void removeListener(void Function() listener);
}

/// A simple [ScrollController] for use with [SingleChildScrollView],
/// [ScrollView], and [ListView].
///
/// Tracks viewport dimension, content extent, and scroll offset. The viewport
/// render object calls [updateMetrics] after layout; the widget state calls
/// [scrollBy] / [jumpTo] in response to user input.
class WidgetScrollController implements ScrollController {
  int _offset = 0;
  int _viewportExtent = 0;
  int _contentExtent = 0;
  final Set<void Function()> _listeners = <void Function()>{};

  // True while the user is actively dragging a linked scrollbar thumb.
  // Used by variable-height viewports to avoid anchor corrections that can
  // fight direct drag intent and feel like compensation jumps.
  bool _thumbDragActive = false;

  // Latest measured content extent while thumb drag is active.
  // Shrinks are deferred until drag ends to avoid mid-drag remapping/clamping.
  int? _deferredContentExtent;

  // ---- Selection state ----

  /// Start of selection in content coordinates (x, y) where Y includes
  /// scroll offset. Null when no selection is active.
  ({int x, int y})? _selectionStart;

  /// End of selection in content coordinates (x, y) where Y includes
  /// scroll offset. Null when no selection is active.
  ({int x, int y})? _selectionEnd;

  /// Whether a drag-selection is in progress.
  bool _selecting = false;

  /// Timestamp of the last click, for double-click detection.
  DateTime? _lastClickTime;

  /// Position of the last click, for double-click detection.
  ({int x, int y})? _lastClickPos;

  /// The selection start point, or null.
  ({int x, int y})? get selectionStart => _selectionStart;

  /// The selection end point, or null.
  ({int x, int y})? get selectionEnd => _selectionEnd;

  /// Whether a selection is currently active (start and end are set).
  bool get hasSelection => _selectionStart != null && _selectionEnd != null;

  /// Whether a drag-selection is in progress.
  bool get selecting => _selecting;

  /// Whether an attached scrollbar thumb drag is currently active.
  bool get thumbDragActive => _thumbDragActive;

  /// Marks whether an attached scrollbar thumb drag is active.
  void setThumbDragActive(bool active) {
    if (_thumbDragActive == active) return;
    _thumbDragActive = active;
    if (!active && _deferredContentExtent != null) {
      final target = _deferredContentExtent!;
      _deferredContentExtent = null;
      if (target != _contentExtent) {
        final beforeContent = _contentExtent;
        final beforeOffset = _offset;
        _contentExtent = target;
        final clamped = _clampOffset();
        _traceScroll(
          'widget_scroll.metrics.deferred '
          'content=$beforeContent->$_contentExtent '
          'offset=$beforeOffset->$_offset max=$maxOffset '
          'clamped=$clamped',
        );
      }
    }
  }

  /// Sets the selection start and end, and notifies listeners.
  void setSelection({
    required ({int x, int y}) start,
    required ({int x, int y}) end,
  }) {
    _selectionStart = start;
    _selectionEnd = end;
    _notifyListeners();
  }

  /// Clears the current selection and notifies listeners.
  void clearSelection() {
    if (_selectionStart == null && _selectionEnd == null) return;
    _selectionStart = null;
    _selectionEnd = null;
    _selecting = false;
    _notifyListeners();
  }

  /// Extracts the selected text from rendered content [lines].
  ///
  /// [lines] should be the full content lines (not just visible), in order.
  /// Selection coordinates are in content space.
  String getSelectedText(List<String> lines) {
    if (!hasSelection) return '';

    final s = _selectionStart!;
    final e = _selectionEnd!;

    final startY = math.min(s.y, e.y);
    final endY = math.max(s.y, e.y);

    if (startY < 0 || endY >= lines.length) return '';

    final sb = StringBuffer();
    for (var y = startY; y <= endY; y++) {
      final line = lines[y];
      final plain = Style.stripAnsi(line);

      int startX, endX;
      if (startY == endY) {
        startX = math.min(s.x, e.x);
        endX = math.max(s.x, e.x);
      } else if (y == startY) {
        startX = s.y < e.y ? s.x : e.x;
        endX = Style.visibleLength(plain);
      } else if (y == endY) {
        startX = 0;
        endX = s.y < e.y ? e.x : s.x;
      } else {
        startX = 0;
        endX = Style.visibleLength(plain);
      }

      final maxX = Style.visibleLength(plain);
      startX = startX.clamp(0, maxX);
      endX = endX.clamp(0, maxX);

      if (startX < endX) {
        sb.write(cutAnsiByCells(plain, startX, endX));
      }
      if (y < endY) {
        sb.write('\n');
      }
    }

    return sb.toString();
  }

  @override
  int get offset => _offset;

  @override
  int get viewportExtent => _viewportExtent;

  @override
  int get contentExtent => _contentExtent;

  @override
  int get maxOffset => math.max(0, _contentExtent - _viewportExtent);

  @override
  double get scrollPercent => maxOffset == 0 ? 0 : _offset / maxOffset;

  /// Updates metrics after layout. Returns true if offset was clamped.
  bool updateMetrics({
    required int viewportExtent,
    required int contentExtent,
  }) {
    final prevViewport = _viewportExtent;
    final prevContent = _contentExtent;
    final prevOffset = _offset;
    final nextViewport = math.max(0, viewportExtent);
    final incomingContent = math.max(0, contentExtent);

    _viewportExtent = nextViewport;
    if (_thumbDragActive) {
      _deferredContentExtent = incomingContent;
      // Keep content extent fixed while thumb drag is active so the
      // thumb-to-offset mapping remains stable and does not remap as
      // variable-height measurements fluctuate.
    } else {
      _deferredContentExtent = null;
      _contentExtent = incomingContent;
    }

    final clamped = _clampOffset();
    if (prevViewport != _viewportExtent ||
        prevContent != _contentExtent ||
        clamped) {
      _traceScroll(
        'widget_scroll.metrics '
        'view=$prevViewport->$_viewportExtent '
        'content=$prevContent->$_contentExtent '
        'incoming=$incomingContent drag=$_thumbDragActive '
        'offset=$prevOffset->$_offset '
        'max=$maxOffset clamped=$clamped',
      );
    }
    return clamped;
  }

  @override
  bool scrollBy(int delta) {
    if (delta == 0) return false;
    final before = _offset;
    final next = (_offset + delta).clamp(0, maxOffset);
    if (next == _offset) {
      _traceScroll(
        'widget_scroll.scrollBy noop '
        'delta=$delta offset=$before max=$maxOffset',
      );
      return false;
    }
    _offset = next;
    _notifyListeners();
    _traceScroll(
      'widget_scroll.scrollBy '
      'delta=$delta from=$before to=$_offset max=$maxOffset',
    );
    return true;
  }

  @override
  bool jumpTo(int offset) {
    final before = _offset;
    final next = offset.clamp(0, maxOffset);
    if (next == _offset) {
      _traceScroll(
        'widget_scroll.jumpTo noop '
        'target=$offset offset=$before max=$maxOffset',
      );
      return false;
    }
    _offset = next;
    _notifyListeners();
    _traceScroll(
      'widget_scroll.jumpTo '
      'target=$offset from=$before to=$_offset max=$maxOffset',
    );
    return true;
  }

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  bool _clampOffset() {
    final before = _offset;
    final next = _offset.clamp(0, maxOffset);
    if (next == _offset) return false;
    _offset = next;
    _notifyListeners();
    _traceScroll(
      'widget_scroll.clamp '
      'from=$before to=$_offset max=$maxOffset',
    );
    return true;
  }
}

/// Controller for [Viewport].
class ViewportController implements ScrollController {
  /// Creates a viewport controller.
  ViewportController({ViewportModel? initial})
    : _model = initial ?? ViewportModel(width: 80, height: 24);

  ViewportModel _model;
  ViewportScrollPane? _scrollPane;
  String _content = '';
  ScrollbarChars? _scrollbarChars;
  String? _scrollbarSeparator;
  final Set<void Function()> _listeners = <void Function()>{};

  /// Current immutable viewport model.
  ViewportModel get model => _model;

  @override
  double get scrollPercent => _model.scrollPercent;

  /// Vertical scroll offset in rows.
  int get yOffset => _model.yOffset;

  @override
  int get offset => _model.yOffset;

  @override
  int get viewportExtent => _model.height ?? _model.lines.length;

  @override
  int get contentExtent => _model.lines.length;

  @override
  int get maxOffset => math.max(0, contentExtent - viewportExtent);

  /// Replaces viewport content text.
  void setContent(String content) {
    if (content == _content) return;
    _content = content;
    _model = _model.setContent(content);
  }

  /// Applies viewport configuration values.
  void configure({
    int? width,
    int? height,
    int? gutter,
    bool? softWrap,
    bool? fillHeight,
    bool? showLineNumbers,
    bool? mouseWheelEnabled,
    int? mouseWheelDelta,
    int? horizontalStep,
    ViewportKeyMap? keyMap,
    Style? style,
  }) {
    _model = _model.copyWith(
      width: width,
      height: height,
      gutter: gutter,
      softWrap: softWrap,
      fillHeight: fillHeight,
      showLineNumbers: showLineNumbers,
      mouseWheelEnabled: mouseWheelEnabled,
      mouseWheelDelta: mouseWheelDelta,
      horizontalStep: horizontalStep,
      keyMap: keyMap,
      style: style,
    );
  }

  /// Updates viewport dimensions.
  void setSize(int width, int? height) {
    if (_model.width == width && _model.height == height) return;
    _model = _model.copyWith(width: width, height: height);
  }

  @override
  bool jumpTo(int offset) {
    final next = _model.setYOffset(offset);
    if (identical(next, _model)) return false;
    _model = next;
    _notifyListeners();
    return true;
  }

  @override
  bool scrollBy(int delta) {
    if (delta == 0) return false;
    final next = delta > 0 ? _model.scrollDown(delta) : _model.scrollUp(-delta);
    if (identical(next, _model)) return false;
    _model = next;
    _notifyListeners();
    return true;
  }

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  /// Forwards a message to the underlying [ViewportModel].
  (ViewportModel, Cmd?) update(Msg msg) {
    final Stopwatch? sw = TuiTrace.enabled ? Stopwatch() : null;
    sw?.start();
    final (vp, cmd) = _model.update(msg);
    _model = vp;
    if (sw != null) {
      sw.stop();
      TuiTrace.log(
        'viewport.controller.update ${msg.runtimeType} '
        'y=${_model.yOffset} ${sw.elapsedMicroseconds}us',
      );
    }
    return (vp, cmd);
  }

  /// Returns a reusable scroll-pane helper for scrollbar rendering/interaction.
  ViewportScrollPane scrollPane({
    required String separator,
    required ScrollbarChars chars,
  }) {
    if (_scrollPane == null ||
        _scrollbarSeparator != separator ||
        _scrollbarChars != chars) {
      _scrollPane = ViewportScrollPane(
        viewport: _model,
        separator: separator,
        chars: chars,
      );
      _scrollbarSeparator = separator;
      _scrollbarChars = chars;
    }
    _scrollPane!.viewport = _model;
    return _scrollPane!;
  }
}

/// A string-backed scrollable viewport powered by [ViewportModel].
///
/// Use this when content already exists as rendered text and you want line
/// wrapping, line numbers, key handling, and optional integrated scrollbar
/// behavior.
class Viewport extends StatefulWidget {
  /// Creates a viewport widget.
  Viewport({
    required this.content,
    this.width,
    this.height,
    this.gutter = 0,
    this.softWrap = false,
    this.fillHeight = false,
    this.showLineNumbers = false,
    this.mouseWheelEnabled = true,
    this.mouseWheelDelta = 3,
    this.horizontalStep = 6,
    this.keyMap,
    this.style,
    this.controller,
    this.showScrollbar = false,
    this.scrollbarSeparator = ' ',
    this.scrollbarChars = const ScrollbarChars(),
    this.enableSelection = false,
    this.handleKeys = true,
    this.zoneId,
    super.key,
  });

  /// Source content rendered by the viewport.
  final String content;

  /// Optional explicit viewport width in columns.
  final int? width;

  /// Optional explicit viewport height in rows.
  final int? height;

  /// Gutter width before content.
  final int gutter;

  /// Whether long lines should soft-wrap.
  final bool softWrap;

  /// Whether to pad output to the configured height.
  final bool fillHeight;

  /// Whether to show line numbers.
  final bool showLineNumbers;

  /// Whether mouse wheel messages should scroll content.
  final bool mouseWheelEnabled;

  /// Rows to scroll per wheel tick.
  final int mouseWheelDelta;

  /// Horizontal scroll amount for applicable keybindings.
  final int horizontalStep;

  /// Optional keybinding overrides.
  final ViewportKeyMap? keyMap;

  /// Optional style overrides.
  final Style? style;

  /// Optional external controller.
  final ViewportController? controller;

  /// Whether to render an integrated scrollbar.
  final bool showScrollbar;

  /// Separator inserted between content and scrollbar.
  final String scrollbarSeparator;

  /// Characters used for scrollbar rendering.
  final ScrollbarChars scrollbarChars;

  /// Whether text selection support is enabled.
  final bool enableSelection;

  /// Whether key messages are forwarded to the viewport model.
  final bool handleKeys;

  /// Optional mouse zone id override.
  final String? zoneId;

  @override
  State createState() => _ViewportState();
}

class _ViewportState extends State<Viewport> {
  late ViewportController _controller;
  bool _controllerAttached = false;

  String get _zoneId => widget.zoneId ?? 'viewport-${widget.id}';

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _syncController();
  }

  @override
  Cmd? didUpdateWidget(covariant Viewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _attachController(widget.controller);
    }
    _syncController();
    return null;
  }

  void _attachController(ViewportController? controller) {
    if (_controllerAttached) {
      _controller.removeListener(_markNeedsPaint);
    }
    _controller = controller ?? ViewportController();
    _controller.addListener(_markNeedsPaint);
    _controllerAttached = true;
  }

  @override
  void dispose() {
    if (_controllerAttached) {
      _controller.removeListener(_markNeedsPaint);
    }
    super.dispose();
  }

  void _syncController() {
    _controller.configure(
      width: widget.width,
      height: widget.height,
      gutter: widget.gutter,
      softWrap: widget.softWrap,
      fillHeight: widget.fillHeight,
      showLineNumbers: widget.showLineNumbers,
      mouseWheelEnabled: widget.mouseWheelEnabled,
      mouseWheelDelta: widget.mouseWheelDelta,
      horizontalStep: widget.horizontalStep,
      keyMap: widget.keyMap,
      style: widget.style,
    );
    _controller.setContent(widget.content);
  }

  void _markNeedsPaint() {
    final element = elementOf(widget);
    element?.markNeedsPaint();
  }

  @override
  Widget build(BuildContext context) {
    return _ViewportRender(
      controller: _controller,
      zoneId: _zoneId,
      width: widget.width,
      height: widget.height,
      showScrollbar: widget.showScrollbar,
      scrollbarSeparator: widget.scrollbarSeparator,
      scrollbarChars: widget.scrollbarChars,
    );
  }

  /// Handles a mouse event using local coordinates (from hit-testing or zone).
  Cmd? _handleLocalMouse(MouseMsg local) {
    if (widget.showScrollbar) {
      final pane = _controller.scrollPane(
        separator: widget.scrollbarSeparator,
        chars: widget.scrollbarChars,
      );
      pane.originX = 0;
      pane.originY = 0;
      if (!widget.enableSelection && !pane.consumesMouse(local)) {
        return null;
      }
      final prev = pane.viewport;
      final (newPane, cmd) = pane.update(local);
      _controller._model = newPane.viewport;
      _traceScroll(
        'viewport.mouse '
        'id=${widget.id} scrollbar=true action=${local.action} '
        'button=${local.button} local=(${local.x},${local.y}) '
        'offset=${prev.yOffset}->${newPane.viewport.yOffset} '
        'max=${_controller.maxOffset} cmd=${cmd != null}',
      );
      if (!identical(prev, newPane.viewport) || cmd != null) {
        _markNeedsPaint();
      }
      return cmd;
    }
    if (!widget.enableSelection && !_isWheelEvent(local)) {
      return null;
    }
    final prev = _controller.model;
    final (next, cmd) = _controller.update(local);
    _traceScroll(
      'viewport.mouse '
      'id=${widget.id} scrollbar=false action=${local.action} '
      'button=${local.button} local=(${local.x},${local.y}) '
      'offset=${prev.yOffset}->${next.yOffset} '
      'max=${_controller.maxOffset} cmd=${cmd != null}',
    );
    if (!identical(prev, next) || cmd != null) {
      _markNeedsPaint();
    }
    return cmd;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    // ---- New: render-tree hit-test dispatch ----
    if (msg is HitTestMouseMsg) {
      final local = msg.event.copyWith(
        x: msg.localX.toInt(),
        y: msg.localY.toInt(),
      );
      if (local.x >= 0 && local.y >= 0) {
        final cmd = _handleLocalMouse(local);
        if (_isWheelEvent(local)) return cmd ?? Cmd.none();
        return cmd;
      }
    }

    // ---- Legacy: zone-based dispatch ----
    if (msg is ZoneInBoundsMsg && msg.zone.id == _zoneId) {
      final pos = msg.zone.pos(msg.event);
      if (pos.x >= 0 && pos.y >= 0) {
        final local = msg.event.copyWith(x: pos.x, y: pos.y);
        final cmd = _handleLocalMouse(local);
        if (_isWheelEvent(local)) return cmd ?? Cmd.none();
        return cmd;
      }
    }

    if (msg is MouseMsg && widget.showScrollbar) {
      if (msg.action == MouseAction.release) {
        final pane = _controller.scrollPane(
          separator: widget.scrollbarSeparator,
          chars: widget.scrollbarChars,
        );
        pane.originX = 0;
        pane.originY = 0;
        pane.update(msg.copyWith(x: -1, y: -1));
      }
    }

    if (widget.handleKeys && msg is KeyMsg) {
      final prev = _controller.model;
      final (next, cmd) = _controller.update(msg);
      if (!identical(prev, next) || cmd != null) {
        _markNeedsPaint();
      }
      return cmd;
    }

    return null;
  }
}

/// A scrollable container for a single child widget.
///
/// Unlike [Viewport] which takes a pre-rendered [String], this widget keeps
/// its child in the element tree so that stateful widgets work correctly.
/// The child is laid out with unconstrained height, and only the visible
/// portion (determined by the scroll offset) is painted.
///
/// Provide a [ScrollController] to share scroll state with a [Scrollbar].
///
/// ```dart
/// Scrollbar(
///   controller: ctrl,
///   child: SingleChildScrollView(
///     controller: ctrl,
///     child: Column(children: [...]),
///   ),
/// )
/// ```
class SingleChildScrollView extends StatefulWidget {
  SingleChildScrollView({
    required this.child,
    this.padding,
    this.controller,
    this.handleKeys = true,
    this.mouseWheelDelta = 3,
    this.enableSelection = false,
    super.key,
  });

  /// The widget to render inside the scrollable viewport.
  final Widget child;

  /// Optional padding to apply around [child].
  final EdgeInsets? padding;

  /// Optional controller for programmatic scrolling.
  ///
  /// If omitted, an internal [WidgetScrollController] is created.
  final ScrollController? controller;

  /// Whether to handle keyboard scrolling (arrow keys/PageUp/PageDown).
  final bool handleKeys;

  /// Number of rows to scroll per mouse wheel tick.
  final int mouseWheelDelta;

  /// Whether in-app text selection is enabled.
  ///
  /// When true, click+drag inside the content area selects text.
  /// Double-click selects a word. Ctrl+C copies the selection to clipboard.
  final bool enableSelection;

  @override
  State createState() => _SingleChildScrollViewState();
}

class _SingleChildScrollViewState extends State<SingleChildScrollView> {
  WidgetScrollController? _ownController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownController ??= WidgetScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_markNeedsPaintScrollOnly);
  }

  @override
  Cmd? didUpdateWidget(covariant SingleChildScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(
        _markNeedsPaintScrollOnly,
      );
      if (widget.controller != null) {
        // External controller provided; discard our own.
        _ownController = null;
      }
      _effectiveController.addListener(_markNeedsPaintScrollOnly);
    }
    return null;
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_markNeedsPaintScrollOnly);
    super.dispose();
  }

  /// Schedules a repaint for scroll-offset changes only. Does NOT invalidate
  /// the viewport's child paint cache because the child content hasn't changed.
  void _markNeedsPaintScrollOnly() {
    final element = elementOf(widget);
    element?.markNeedsPaintScrollOnly();
  }

  void _markNeedsPaint() {
    final element = elementOf(widget);
    element?.markNeedsPaint();
  }

  bool _scrollBy(int delta) {
    final before = _effectiveController.offset;
    final changed = _effectiveController.scrollBy(delta);
    final after = _effectiveController.offset;
    if (changed) _markNeedsPaint();
    _traceScroll(
      'single_child_scroll.scrollBy '
      'id=${widget.id} delta=$delta from=$before to=$after '
      'max=${_effectiveController.maxOffset} changed=$changed',
    );
    return changed;
  }

  bool _handleKey(terminal_keys.Key key) {
    final viewportHeight = _effectiveController.viewportExtent;
    switch (key.type) {
      case terminal_keys.KeyType.up:
        return _scrollBy(-1);
      case terminal_keys.KeyType.down:
        return _scrollBy(1);
      case terminal_keys.KeyType.pageUp:
        if (viewportHeight <= 0) return false;
        return _scrollBy(-viewportHeight);
      case terminal_keys.KeyType.pageDown:
        if (viewportHeight <= 0) return false;
        return _scrollBy(viewportHeight);
      case terminal_keys.KeyType.home:
        if (_effectiveController.jumpTo(0)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      case terminal_keys.KeyType.end:
        if (_effectiveController.jumpTo(_effectiveController.maxOffset)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    // Render-tree hit-test dispatch (mouse wheel + selection).
    if (msg is HitTestMouseMsg) {
      final local = msg.event.copyWith(
        x: msg.localX.toInt(),
        y: msg.localY.toInt(),
      );
      if (_isWheelEvent(local)) {
        final delta = switch (local.button) {
          MouseButton.wheelUp => -widget.mouseWheelDelta,
          MouseButton.wheelDown => widget.mouseWheelDelta,
          _ => 0,
        };
        _traceScroll(
          'single_child_scroll.wheel '
          'id=${widget.id} local=(${local.x},${local.y}) '
          'button=${local.button} delta=$delta '
          'offset=${_effectiveController.offset} '
          'max=${_effectiveController.maxOffset}',
        );
        if (delta != 0) _scrollBy(delta);
        return Cmd.none();
      }
      // Handle selection via mouse press/drag/release.
      if (widget.enableSelection) {
        final cmd = _handleSelectionMouse(msg);
        if (cmd != null) return cmd;
      }
    }

    // Keyboard scrolling and copy.
    if (msg is KeyMsg) {
      if (widget.enableSelection) {
        final cmd = _handleSelectionKey(msg);
        if (cmd != null) return cmd;
      }
      if (widget.handleKeys) {
        _handleKey(msg.key);
      }
    }

    return null;
  }

  /// Handles mouse events for text selection.
  Cmd? _handleSelectionMouse(HitTestMouseMsg msg) {
    final ctrl = _effectiveController;
    if (ctrl is! WidgetScrollController) return null;

    final event = msg.event;
    // Content coordinates: Use screen-space event.x for X (localX from the
    // deepest hit may be relative to a child, not the viewport).
    // For Y we use event.y minus the viewport's global Y offset, then add
    // the scroll offset to convert to content space.
    // localY from HitTestMouseMsg is relative to the deepest-hit render
    // object (e.g., a Text widget), not the viewport, so it's always ~0.
    final ro = _findRenderViewport();
    final vpGlobalY = ro != null ? _roGlobalY(ro) : 0.0;
    final vpGlobalX = ro != null ? _roGlobalX(ro) : 0.0;
    final contentX = (event.x - vpGlobalX).toInt();
    final contentY = (event.y - vpGlobalY).toInt() + ctrl.offset;

    // Motion and release events may have button == none (terminal motion
    // packets don't always re-report the held button). Handle them based on
    // the _selecting flag rather than requiring button == left.
    if (event.action == MouseAction.motion && ctrl._selecting) {
      ctrl._selectionEnd = (x: contentX, y: contentY);
      _markNeedsPaint();
      return null;
    }
    if (event.action == MouseAction.release && ctrl._selecting) {
      ctrl._selecting = false;
      return null;
    }

    if (event.button == MouseButton.left && event.action == MouseAction.press) {
      final now = DateTime.now();
      final pos = (x: contentX, y: contentY);

      // Double-click detection.
      if (ctrl._lastClickTime != null &&
          now.difference(ctrl._lastClickTime!) <
              const Duration(milliseconds: 500) &&
          ctrl._lastClickPos == pos) {
        // Double-click: select word.
        final ro = _findRenderViewport();
        if (ro != null) {
          final lines = _getPaintedContentLines(ro);
          final (wordStart, wordEnd) = _findWordAt(lines, contentX, contentY);
          ctrl._selectionStart = (x: wordStart, y: contentY);
          ctrl._selectionEnd = (x: wordEnd, y: contentY);
          ctrl._selecting = false;
          ctrl._lastClickTime = now;
          ctrl._lastClickPos = pos;
          _markNeedsPaint();
        }
        return null;
      }

      // Start new selection.
      ctrl._selectionStart = pos;
      ctrl._selectionEnd = pos;
      ctrl._selecting = true;
      ctrl._lastClickTime = now;
      ctrl._lastClickPos = pos;
      _markNeedsPaint();
      return null;
    }

    return null;
  }

  /// Handles Ctrl+C for copying selection to clipboard.
  Cmd? _handleSelectionKey(KeyMsg msg) {
    final ctrl = _effectiveController;
    if (ctrl is! WidgetScrollController) return null;

    if (msg.key.char == 'c' && msg.key.ctrl) {
      if (ctrl.hasSelection) {
        final ro = _findRenderViewport();
        if (ro != null) {
          final lines = _getPaintedContentLines(ro);
          final text = ctrl.getSelectedText(lines);
          if (text.isNotEmpty) {
            return Cmd.setClipboard(text);
          }
        }
      }
    }
    return null;
  }

  /// Finds the [RenderSingleChildViewport] owned by this widget.
  RenderSingleChildViewport? _findRenderViewport() {
    final el = elementOf(widget);
    if (el == null) return null;
    RenderSingleChildViewport? result;
    void visit(Element e) {
      if (result != null) return;
      if (e is RenderObjectElement &&
          e.renderObject is RenderSingleChildViewport) {
        result = e.renderObject as RenderSingleChildViewport;
        return;
      }
      for (final child in e.children) {
        visit(child);
        if (result != null) return;
      }
    }

    visit(el);
    return result;
  }

  /// Extracts ALL content lines from the child's paint output (before
  /// viewport slicing).
  List<String> _getPaintedContentLines(RenderSingleChildViewport ro) {
    return ro.cachedContentLines;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    final pad = widget.padding;
    if (pad != null && !pad.isZero) {
      child = Padding(padding: pad, child: child);
    }
    return _SingleChildViewport(controller: _effectiveController, child: child);
  }
}

/// Internal render-object widget for [SingleChildScrollView].
///
/// Keeps the child in the element tree. The render object lays the child
/// out with unconstrained height, then clips its paint output to the
/// viewport window.
class _SingleChildViewport extends SingleChildRenderObjectWidget {
  _SingleChildViewport({required this.controller, required super.child});

  final ScrollController controller;

  @override
  RenderObject createRenderObject() {
    return RenderSingleChildViewport(controller: controller);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as RenderSingleChildViewport;
    ro.controller = controller;
    // The widget tree rebuilt — child content may have changed.
    ro.invalidateChildPaintCache();
  }

  @override
  Object view() => child?.view() ?? '';
}

/// Render object for [_SingleChildViewport].
///
/// Lays out the child with unconstrained height (so the child can be taller
/// than the viewport). On paint, it takes the child's rendered string,
/// skips [offset] lines, and returns only [viewportHeight] lines.
class RenderSingleChildViewport extends RenderBox {
  RenderSingleChildViewport({required ScrollController controller})
    : _controller = controller;

  ScrollController _controller;

  ScrollController get controller => _controller;
  set controller(ScrollController value) {
    if (_controller != value) {
      _controller = value;
    }
  }

  // --- Paint cache ---
  // Caches the child's paint output to avoid re-rendering it on every scroll
  // frame. Invalidated when the child's constraints or size change, or when
  // [invalidateChildPaintCache] is called (e.g., on widget rebuild).
  List<String>? _cachedChildPaintLines;
  BoxConstraints? _cachedChildConstraints;
  Size? _cachedChildSize;

  /// Marks the cached child paint output as stale so it will be recomputed
  /// on the next [paint] call.
  void invalidateChildPaintCache() {
    _cachedChildPaintLines = null;
  }

  @override
  void markDescendantNeedsPaint() {
    super.markDescendantNeedsPaint();
    invalidateChildPaintCache();
  }

  /// Returns the cached content lines (all lines before viewport slicing).
  /// If no cache exists, paints the child and caches the result.
  List<String> get cachedContentLines {
    if (_cachedChildPaintLines != null) return _cachedChildPaintLines!;
    if (children.isEmpty) return const [];
    final child = children.first;
    final content = child.paint();
    if (content.isEmpty) return const [];
    _cachedChildPaintLines = content.split('\n');
    return _cachedChildPaintLines!;
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    if (children.isEmpty) return;

    final child = children.first;
    // Let the child have unconstrained height so it can be as tall as it wants.
    // For the cross-axis (width), use tight constraints when bounded so the
    // child fills the full viewport width (matches Flutter's behavior).
    final childConstraints = BoxConstraints(
      minWidth: constraints.hasBoundedWidth
          ? constraints.maxWidth
          : constraints.minWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0,
      maxHeight: double.infinity,
    );
    child.layout(childConstraints);

    // Invalidate paint cache if child constraints or size changed.
    if (_cachedChildConstraints != childConstraints ||
        _cachedChildSize != child.size) {
      _cachedChildPaintLines = null;
      _cachedChildConstraints = childConstraints;
      _cachedChildSize = child.size;
    }

    // Our size is constrained to the parent.
    size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : child.size.width,
        constraints.maxHeight,
      ),
    );

    // Update controller metrics.
    final viewportHeight = size.height.round();
    final contentHeight = child.size.height.round();
    if (_controller is WidgetScrollController) {
      (_controller as WidgetScrollController).updateMetrics(
        viewportExtent: viewportHeight,
        contentExtent: contentHeight,
      );
    } else if (_controller is ListViewController) {
      final lvc = _controller as ListViewController;
      lvc.setViewportHeight(viewportHeight);
      lvc.setContentHeight(contentHeight);
    }
    // For ViewportController or other custom controllers, the caller is
    // responsible for updating metrics.
  }

  @override
  String paint() {
    if (children.isEmpty) return '';

    // Use cached content lines if available; otherwise paint the child and
    // cache the result.
    final lines = cachedContentLines;
    if (lines.isEmpty) return '';

    final viewportHeight = size.height.round();
    final scrollOffset = _controller.offset.clamp(0, _controller.maxOffset);

    // Skip `scrollOffset` lines, take `viewportHeight` lines.
    if (scrollOffset >= lines.length) return '';
    final endLine = math.min(lines.length, scrollOffset + viewportHeight);
    var visible = lines.sublist(scrollOffset, endLine);

    // Apply selection highlighting if controller has an active selection.
    if (_controller is WidgetScrollController) {
      final ctrl = _controller as WidgetScrollController;
      if (ctrl.hasSelection) {
        visible = _applySelectionHighlighting(visible, scrollOffset, ctrl);
      }
    }

    // If fewer lines than viewport, pad with empty lines to fill height.
    while (visible.length < viewportHeight) {
      visible.add('');
    }

    return visible.join('\n');
  }

  @override
  bool hitTest(
    HitTestResult result, {
    required double localX,
    required double localY,
  }) {
    if (localX < 0 ||
        localY < 0 ||
        localX >= size.width ||
        localY >= size.height) {
      return false;
    }

    // Adjust Y by scroll offset when testing children.
    for (var i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      final childX = localX - child.offset.dx;
      final childY = localY + _controller.offset - child.offset.dy;
      if (child.hitTest(result, localX: childX, localY: childY)) {
        break;
      }
    }

    return true;
  }
}

/// A scrollable container for a single child widget.
///
/// This is a convenience alias for [SingleChildScrollView]. The two
/// widgets are interchangeable; [ScrollView] is kept for backward
/// compatibility.
class ScrollView extends StatefulWidget {
  /// Creates a scroll view.
  ScrollView({
    required this.child,
    this.controller,
    this.handleKeys = true,
    this.mouseWheelDelta = 3,
    this.enableSelection = false,
    this.autoCopySelectionOnMouseUp = false,
    this.autoCopySelectionOnExit = false,
    this.clearSelectionAfterAutoCopy = true,
    super.key,
  });

  /// Child widget rendered inside the viewport.
  final Widget child;

  /// Optional external controller for reading/updating offset.
  final ScrollController? controller;

  /// Whether keyboard keys trigger scrolling.
  final bool handleKeys;

  /// Number of rows scrolled per mouse wheel tick.
  final int mouseWheelDelta;

  /// Whether in-app text selection is enabled.
  ///
  /// When true, click+drag inside the content area selects text.
  /// Double-click selects a word. Ctrl+C copies the selection to clipboard.
  final bool enableSelection;

  /// Whether to auto-copy selected text when mouse button is released.
  final bool autoCopySelectionOnMouseUp;

  /// Whether to auto-copy selected text immediately when drag leaves the
  /// scroll view's hit-test area.
  final bool autoCopySelectionOnExit;

  /// Whether to clear selection after auto-copy.
  final bool clearSelectionAfterAutoCopy;

  @override
  State createState() => _ScrollViewState();
}

class _ScrollViewState extends State<ScrollView> {
  WidgetScrollController? _ownController;
  MouseMsg? _lastSelectionHitMouse;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownController ??= WidgetScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_markNeedsPaintScrollOnly);
  }

  @override
  Cmd? didUpdateWidget(covariant ScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(
        _markNeedsPaintScrollOnly,
      );
      if (widget.controller != null) {
        _ownController = null;
      }
      _effectiveController.addListener(_markNeedsPaintScrollOnly);
    }
    return null;
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_markNeedsPaintScrollOnly);
    super.dispose();
  }

  /// Schedules a repaint for scroll-offset changes only. Does NOT invalidate
  /// the viewport's child paint cache because the child content hasn't changed.
  void _markNeedsPaintScrollOnly() {
    final element = elementOf(widget);
    element?.markNeedsPaintScrollOnly();
  }

  void _markNeedsPaint() {
    final element = elementOf(widget);
    element?.markNeedsPaint();
  }

  bool _scrollBy(int delta) {
    final before = _effectiveController.offset;
    final changed = _effectiveController.scrollBy(delta);
    final after = _effectiveController.offset;
    if (changed) _markNeedsPaint();
    _traceScroll(
      'scroll_view.scrollBy '
      'id=${widget.id} delta=$delta from=$before to=$after '
      'max=${_effectiveController.maxOffset} changed=$changed',
    );
    return changed;
  }

  bool _handleKey(terminal_keys.Key key) {
    final viewportHeight = _effectiveController.viewportExtent;
    switch (key.type) {
      case terminal_keys.KeyType.up:
        return _scrollBy(-1);
      case terminal_keys.KeyType.down:
        return _scrollBy(1);
      case terminal_keys.KeyType.pageUp:
        if (viewportHeight <= 0) return false;
        return _scrollBy(-viewportHeight);
      case terminal_keys.KeyType.pageDown:
        if (viewportHeight <= 0) return false;
        return _scrollBy(viewportHeight);
      case terminal_keys.KeyType.home:
        if (_effectiveController.jumpTo(0)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      case terminal_keys.KeyType.end:
        if (_effectiveController.jumpTo(_effectiveController.maxOffset)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) {
      if (widget.enableSelection) {
        _lastSelectionHitMouse = msg.event;
      }
      final local = msg.event.copyWith(
        x: msg.localX.toInt(),
        y: msg.localY.toInt(),
      );
      if (_isWheelEvent(local)) {
        final delta = switch (local.button) {
          MouseButton.wheelUp => -widget.mouseWheelDelta,
          MouseButton.wheelDown => widget.mouseWheelDelta,
          _ => 0,
        };
        _traceScroll(
          'scroll_view.wheel '
          'id=${widget.id} local=(${local.x},${local.y}) '
          'button=${local.button} delta=$delta '
          'offset=${_effectiveController.offset} '
          'max=${_effectiveController.maxOffset}',
        );
        if (delta != 0) _scrollBy(delta);
        return Cmd.none();
      }
      // Handle selection via mouse press/drag/release.
      if (widget.enableSelection) {
        final cmd = _handleSelectionMouse(msg);
        if (cmd != null) return cmd;
      }
    }
    if (msg is MouseMsg &&
        widget.enableSelection &&
        widget.autoCopySelectionOnExit) {
      final ctrl = _effectiveController;
      if (ctrl is WidgetScrollController && ctrl._selecting) {
        final sameAsHit =
            _lastSelectionHitMouse != null && msg == _lastSelectionHitMouse;
        if (!sameAsHit &&
            (msg.action == MouseAction.motion ||
                msg.action == MouseAction.release)) {
          ctrl._selecting = false;
          return _copyCurrentSelection(
            clearAfterCopy: widget.clearSelectionAfterAutoCopy,
          );
        }
      }
    }
    if (msg is KeyMsg) {
      if (widget.enableSelection) {
        final cmd = _handleSelectionKey(msg);
        if (cmd != null) return cmd;
      }
      if (widget.handleKeys) {
        _handleKey(msg.key);
      }
    }
    return null;
  }

  /// Handles mouse events for text selection.
  Cmd? _handleSelectionMouse(HitTestMouseMsg msg) {
    final ctrl = _effectiveController;
    if (ctrl is! WidgetScrollController) return null;

    final event = msg.event;
    // Use screen-space coordinates and subtract the viewport's global offset
    // to get viewport-local Y. localY from HitTestMouseMsg is relative to
    // the deepest-hit render object (e.g. a Text), not the viewport.
    final ro = _findRenderViewport();
    final vpGlobalY = ro != null ? _roGlobalY(ro) : 0.0;
    final vpGlobalX = ro != null ? _roGlobalX(ro) : 0.0;
    final contentX = (event.x - vpGlobalX).toInt();
    final contentY = (event.y - vpGlobalY).toInt() + ctrl.offset;

    // Motion and release events may have button == none (terminal motion
    // packets don't always re-report the held button). Handle them based on
    // the _selecting flag rather than requiring button == left.
    if (event.action == MouseAction.motion && ctrl._selecting) {
      ctrl._selectionEnd = (x: contentX, y: contentY);
      _markNeedsPaint();
      return null;
    }
    if (event.action == MouseAction.release && ctrl._selecting) {
      ctrl._selecting = false;
      if (widget.autoCopySelectionOnMouseUp) {
        return _copyCurrentSelection(
          clearAfterCopy: widget.clearSelectionAfterAutoCopy,
        );
      }
      return null;
    }

    if (event.button == MouseButton.left && event.action == MouseAction.press) {
      final now = DateTime.now();
      final pos = (x: contentX, y: contentY);

      // Double-click detection.
      if (ctrl._lastClickTime != null &&
          now.difference(ctrl._lastClickTime!) <
              const Duration(milliseconds: 500) &&
          ctrl._lastClickPos == pos) {
        final ro = _findRenderViewport();
        if (ro != null) {
          final lines = _getPaintedContentLines(ro);
          final (wordStart, wordEnd) = _findWordAt(lines, contentX, contentY);
          ctrl._selectionStart = (x: wordStart, y: contentY);
          ctrl._selectionEnd = (x: wordEnd, y: contentY);
          ctrl._selecting = false;
          ctrl._lastClickTime = now;
          ctrl._lastClickPos = pos;
          _markNeedsPaint();
        }
        return null;
      }

      ctrl._selectionStart = pos;
      ctrl._selectionEnd = pos;
      ctrl._selecting = true;
      ctrl._lastClickTime = now;
      ctrl._lastClickPos = pos;
      _markNeedsPaint();
      return null;
    }

    return null;
  }

  /// Handles Ctrl+C for copying selection to clipboard.
  Cmd? _handleSelectionKey(KeyMsg msg) {
    final ctrl = _effectiveController;
    if (ctrl is! WidgetScrollController) return null;

    if (msg.key.char == 'c' && msg.key.ctrl) {
      if (ctrl.hasSelection) {
        return _copyCurrentSelection(clearAfterCopy: false);
      }
    }
    return null;
  }

  Cmd? _copyCurrentSelection({required bool clearAfterCopy}) {
    final ctrl = _effectiveController;
    if (ctrl is! WidgetScrollController) return null;
    if (!ctrl.hasSelection) return null;

    final ro = _findRenderViewport();
    if (ro == null) {
      if (clearAfterCopy) {
        ctrl.clearSelection();
      }
      return null;
    }

    final lines = _getPaintedContentLines(ro);
    final text = ctrl.getSelectedText(lines);
    if (text.isEmpty) {
      if (clearAfterCopy) {
        ctrl.clearSelection();
      }
      return null;
    }

    if (clearAfterCopy) {
      ctrl.clearSelection();
    }
    return Cmd.setClipboard(text);
  }

  /// Finds the [RenderSingleChildViewport] owned by this widget.
  RenderSingleChildViewport? _findRenderViewport() {
    final el = elementOf(widget);
    if (el == null) return null;
    RenderSingleChildViewport? result;
    void visit(Element e) {
      if (result != null) return;
      if (e is RenderObjectElement &&
          e.renderObject is RenderSingleChildViewport) {
        result = e.renderObject as RenderSingleChildViewport;
        return;
      }
      for (final child in e.children) {
        visit(child);
        if (result != null) return;
      }
    }

    visit(el);
    return result;
  }

  /// Extracts ALL content lines from the child's paint output.
  List<String> _getPaintedContentLines(RenderSingleChildViewport ro) {
    return ro.cachedContentLines;
  }

  @override
  Widget build(BuildContext context) {
    return _SingleChildViewport(
      controller: _effectiveController,
      child: widget.child,
    );
  }
}

/// A scrollbar that decorates a scrollable child.
///
/// Provide a [controller] to read scroll metrics and enable dragging. By
/// default, the scrollbar reserves space to the right; set [overlay] to true
/// to draw it on top of the child.
///
/// For smooth gutters, use space characters with background styling and set
/// [trackUsesBackground] or [thumbUsesBackground] to true. Use [gutterWidth]
/// to reserve extra columns for the track, and [roundedCaps] to round the
/// thumb ends.
///
/// Hover styling requires mouse all-motion mode.
class Scrollbar extends StatefulWidget {
  Scrollbar({
    required this.child,
    required this.controller,
    this.trackStyle,
    this.thumbStyle,
    this.trackGradient,
    this.thumbGradient,
    this.trackUsesBackground = false,
    this.thumbUsesBackground = false,
    this.trackChar = '│',
    this.thumbChar = '█',
    this.thickness = 1,
    this.gutterWidth,
    this.roundedCaps = false,
    this.thumbCapTopChar,
    this.thumbCapBottomChar,
    this.enableHover = false,
    this.hoverTrackStyle,
    this.hoverThumbStyle,
    this.hoverTrackGradient,
    this.hoverThumbGradient,
    this.hoverTrackChar,
    this.hoverThumbChar,
    this.overlay = false,
    this.gap = 0,
    this.mouseWheelDelta = 3,
    this.enableDrag = true,
    this.zoneId,
    super.key,
  });

  /// The scrollable child to decorate.
  final Widget child;

  /// Scroll controller providing offset and extent information.
  final ScrollController controller;

  /// Optional style for the scrollbar track.
  final Style? trackStyle;

  /// Optional style for the scrollbar thumb.
  final Style? thumbStyle;

  /// Optional gradient for the scrollbar track.
  ///
  /// Use [ScrollbarGradient.background] for smooth gutter fills.
  final ScrollbarGradient? trackGradient;

  /// Optional gradient for the scrollbar thumb.
  ///
  /// Use [ScrollbarGradient.background] for smooth thumb fills.
  final ScrollbarGradient? thumbGradient;

  /// Whether the track style should apply to the background.
  ///
  /// This only affects how the scrollbar is composited when the track uses
  /// spaces (for example, a background-filled gutter).
  final bool trackUsesBackground;

  /// Whether the thumb style should apply to the background.
  ///
  /// This only affects how the scrollbar is composited when the thumb uses
  /// spaces (for example, a background-filled thumb).
  final bool thumbUsesBackground;

  /// Character used for the track.
  final String trackChar;

  /// Character used for the thumb.
  final String thumbChar;

  /// Width of the scrollbar in columns.
  final int thickness;

  /// Optional track width in columns (defaults to [thickness]).
  final int? gutterWidth;

  /// Whether to use rounded cap characters for the thumb.
  final bool roundedCaps;

  /// Optional top cap character for the thumb.
  final String? thumbCapTopChar;

  /// Optional bottom cap character for the thumb.
  final String? thumbCapBottomChar;

  /// Whether hover styling is enabled (requires all-motion mouse mode).
  final bool enableHover;

  /// Optional style for the track when hovered.
  final Style? hoverTrackStyle;

  /// Optional style for the thumb when hovered.
  final Style? hoverThumbStyle;

  /// Optional gradient for the track when hovered.
  final ScrollbarGradient? hoverTrackGradient;

  /// Optional gradient for the thumb when hovered.
  final ScrollbarGradient? hoverThumbGradient;

  /// Optional track character when hovered.
  final String? hoverTrackChar;

  /// Optional thumb character when hovered.
  final String? hoverThumbChar;

  /// Whether the scrollbar is drawn on top of the child.
  ///
  /// When false, the scrollbar reserves space to the right of the child.
  final bool overlay;

  /// Gap between the child and the scrollbar when [overlay] is false.
  final int gap;

  /// Number of rows to scroll per mouse wheel tick.
  final int mouseWheelDelta;

  /// Whether dragging the thumb updates scroll offset.
  final bool enableDrag;

  /// Optional zone id for mouse tracking.
  final String? zoneId;

  @override
  State createState() => _ScrollbarState();
}

final Set<String> _hoveredScrollbars = <String>{};

/// A vertical gradient for scrollbar tracks or thumbs.
class ScrollbarGradient {
  const ScrollbarGradient({
    required this.start,
    required this.end,
    this.useBackground = false,
  });

  /// Creates a gradient that applies to the foreground color.
  const ScrollbarGradient.foreground({required this.start, required this.end})
    : useBackground = false;

  /// Creates a gradient that applies to the background color.
  const ScrollbarGradient.background({required this.start, required this.end})
    : useBackground = true;

  /// Starting color of the gradient.
  final Color start;

  /// Ending color of the gradient.
  final Color end;

  /// Whether the gradient applies to the background color.
  final bool useBackground;
}

class _ScrollbarState extends State<Scrollbar> {
  bool _dragging = false;
  int _dragOffset = 0;
  int? _dragOriginY;
  bool _hovering = false;
  bool _hitTestedThisFrame = false;

  String get _zoneId => widget.zoneId ?? 'scrollbar-${widget.id}';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_markNeedsPaint);
  }

  @override
  Cmd? didUpdateWidget(covariant Scrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_markNeedsPaint);
      widget.controller.addListener(_markNeedsPaint);
    }
    return null;
  }

  @override
  void dispose() {
    _setThumbDragActive(false);
    widget.controller.removeListener(_markNeedsPaint);
    super.dispose();
  }

  void _captureMouse() {
    final element = elementOf(widget);
    element?.captureMouse();
  }

  void _releaseMouse() {
    final element = elementOf(widget);
    element?.releaseMouse();
  }

  void _setHovering(bool next) {
    if (_hovering == next) return;
    _hovering = next;
    if (next) {
      _hoveredScrollbars.add(_zoneId);
    } else {
      _hoveredScrollbars.remove(_zoneId);
    }
    _markNeedsPaint();
  }

  void _markNeedsPaint() {
    final element = elementOf(widget);
    element?.markNeedsPaint();
  }

  void _setThumbDragActive(bool active) {
    final c = widget.controller;
    if (c is WidgetScrollController) {
      c.setThumbDragActive(active);
    }
  }

  /// Returns the [RenderScrollbar] owned by this scrollbar widget, or null.
  RenderScrollbar? _findRenderScrollbar() {
    final el = elementOf(widget);
    if (el == null) return null;
    RenderScrollbar? result;
    void visit(Element e) {
      if (result != null) return;
      if (e is RenderObjectElement && e.renderObject is RenderScrollbar) {
        result = e.renderObject as RenderScrollbar;
        return;
      }
      for (final child in e.children) {
        visit(child);
        if (result != null) return;
      }
    }

    visit(el);
    return result;
  }

  /// Computes the global X offset of a render object by summing offsets
  /// up the parent chain.
  static double _globalX(RenderObject ro) {
    var x = 0.0;
    RenderObject? current = ro;
    while (current != null) {
      x += current.offset.dx;
      current = current.parent;
    }
    return x;
  }

  /// Computes the global Y offset of a render object by summing offsets
  /// up the parent chain.
  static double _globalY(RenderObject ro) {
    var y = 0.0;
    RenderObject? current = ro;
    while (current != null) {
      y += current.offset.dy;
      current = current.parent;
    }
    return y;
  }

  ({int left, int top, int width, int height})? _scrollbarGeometry() {
    final rsb = _findRenderScrollbar();
    if (rsb == null) return null;
    return (
      left: _globalX(rsb).round(),
      top: _globalY(rsb).round(),
      width: rsb.size.width.round(),
      height: rsb.size.height.round(),
    );
  }

  int _resolvedTrackWidth(int totalWidth) {
    if (totalWidth <= 0) return 0;
    final requested = math.max(
      widget.thickness,
      widget.gutterWidth ?? widget.thickness,
    );
    return requested.clamp(1, totalWidth);
  }

  ({int startX, int endX}) _globalTrackBounds({
    required int left,
    required int width,
  }) {
    final trackWidth = _resolvedTrackWidth(width);
    final endX = left + width;
    final startX = endX - trackWidth;
    return (startX: startX, endX: endX);
  }

  /// Returns true if hit-test local X falls within the scrollbar track area.
  bool _isOnScrollbarTrack(HitTestMouseMsg msg) {
    final geometry = _scrollbarGeometry();
    if (geometry == null) {
      // If we cannot resolve the render object, be permissive: this message
      // already passed render hit-testing and reached this Scrollbar state.
      return true;
    }

    final bounds = _globalTrackBounds(
      left: geometry.left,
      width: geometry.width,
    );
    return msg.event.x >= bounds.startX && msg.event.x < bounds.endX;
  }

  bool _isMouseOverScrollbarTrack(MouseMsg msg) {
    final geometry = _scrollbarGeometry();
    if (geometry == null) return false;

    final withinVertical =
        msg.y >= geometry.top && msg.y < geometry.top + geometry.height;
    if (!withinVertical) return false;

    final bounds = _globalTrackBounds(
      left: geometry.left,
      width: geometry.width,
    );
    return msg.x >= bounds.startX && msg.x < bounds.endX;
  }

  _ThumbMetrics _thumbMetrics() {
    final viewport = math.max(0, widget.controller.viewportExtent);
    final content = math.max(0, widget.controller.contentExtent);
    final maxOffset = widget.controller.maxOffset;
    if (viewport == 0 || content == 0) {
      return const _ThumbMetrics(
        viewport: 0,
        thumbExtent: 0,
        thumbTop: 0,
        maxThumbTop: 0,
      );
    }

    if (content <= viewport) {
      return _ThumbMetrics(
        viewport: viewport,
        thumbExtent: viewport,
        thumbTop: 0,
        maxThumbTop: 0,
      );
    }

    final thumbExtent = math.max(1, (viewport * viewport) ~/ content);
    final maxThumbTop = math.max(0, viewport - thumbExtent);
    final thumbTop = maxOffset == 0
        ? 0
        : ((widget.controller.offset / maxOffset) * maxThumbTop).round();
    return _ThumbMetrics(
      viewport: viewport,
      thumbExtent: thumbExtent,
      thumbTop: thumbTop,
      maxThumbTop: maxThumbTop,
    );
  }

  void _handlePress(int y) {
    final metrics = _thumbMetrics();
    if (metrics.thumbExtent <= 0) return;
    if (y >= metrics.thumbTop && y < metrics.thumbTop + metrics.thumbExtent) {
      _dragging = true;
      _setThumbDragActive(true);
      _dragOffset = y - metrics.thumbTop;
      _captureMouse();
      return;
    }

    _dragging = true;
    _setThumbDragActive(true);
    _dragOffset = metrics.thumbExtent ~/ 2;
    _captureMouse();
    final targetTop = (y - _dragOffset).clamp(0, metrics.maxThumbTop);
    _jumpToThumb(targetTop, metrics);
  }

  void _handleMotion(int y) {
    if (!_dragging) return;
    final metrics = _thumbMetrics();
    final targetTop = (y - _dragOffset).clamp(0, metrics.maxThumbTop);
    _jumpToThumb(targetTop, metrics);
  }

  void _jumpToThumb(int thumbTop, _ThumbMetrics metrics) {
    if (metrics.maxThumbTop <= 0) return;
    final maxOffset = widget.controller.maxOffset;
    final nextOffset = ((thumbTop / metrics.maxThumbTop) * maxOffset).round();
    final before = widget.controller.offset;
    if (widget.controller.jumpTo(nextOffset)) {
      _markNeedsPaint();
    }
    _traceScroll(
      'scrollbar.jump '
      'id=${widget.id} thumbTop=$thumbTop '
      'offset=$before->${widget.controller.offset} max=$maxOffset',
    );
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (!widget.enableDrag) return null;

    // ---- New: render-tree hit-test dispatch ----
    if (msg is HitTestMouseMsg) {
      if (!_isWheelEvent(msg.event)) {
        _hitTestedThisFrame = true;
      }
      // Always handle wheel events regardless of X position (scroll should
      // work anywhere within the scrollbar+content area).
      if (_isWheelEvent(msg.event)) {
        final cmd = _handleLocalScrollbarMouse(msg.event);
        return cmd ?? Cmd.none();
      }
      // For press/drag/release, only handle if the click is on the scrollbar
      // track area.  Without this guard, clicks on content would be
      // misinterpreted as scrollbar interactions because HitTestMouseMsg
      // localX/localY are relative to the deepest hit child, not this widget.
      if (!_isOnScrollbarTrack(msg)) return null;

      final geometry = _scrollbarGeometry();
      final localY = geometry == null
          ? msg.localY.round()
          : msg.event.y - geometry.top;
      final originY = geometry == null
          ? msg.event.y - msg.localY.round()
          : geometry.top;
      final local = msg.event.copyWith(x: msg.event.x, y: localY);

      // Pass the absolute scrollbar origin so subsequent raw MouseMsg motion
      // events (dispatched via mouse capture) can be converted back to local Y.
      return _handleLocalScrollbarMouse(local, zoneStartY: originY);
    }

    if (msg is MouseMsg && _dragging && _dragOriginY != null) {
      final localY = msg.y - _dragOriginY!;
      switch (msg.action) {
        case MouseAction.motion:
          _handleMotion(localY);
          return null;
        case MouseAction.release:
          if (msg.button == MouseButton.left ||
              msg.button == MouseButton.none) {
            _dragging = false;
            _setThumbDragActive(false);
            _dragOriginY = null;
            _releaseMouse();
            return null;
          }
          break;
        default:
          break;
      }
    }
    if (msg is MouseMsg &&
        msg.button == MouseButton.left &&
        msg.action == MouseAction.release) {
      _dragging = false;
      _setThumbDragActive(false);
      _dragOriginY = null;
      _releaseMouse();
    }
    // ---- Legacy: zone-based dispatch ----
    if (msg is ZoneInBoundsMsg && msg.zone.id == _zoneId) {
      final local = msg.event.copyWith(
        x: msg.zone.pos(msg.event).x,
        y: msg.zone.pos(msg.event).y,
      );
      return _handleLocalScrollbarMouse(local, zoneStartY: msg.zone.startY);
    }

    if (msg is MouseMsg && widget.enableHover) {
      if (msg.action == MouseAction.motion) {
        if (_hitTestedThisFrame) {
          _hitTestedThisFrame = false;
        } else if (!_isMouseOverScrollbarTrack(msg)) {
          _setHovering(false);
        }
      } else {
        _hitTestedThisFrame = false;
      }
    }
    return null;
  }

  /// Handles a mouse event using local coordinates (from hit-testing or zone).
  Cmd? _handleLocalScrollbarMouse(MouseMsg local, {int? zoneStartY}) {
    if (widget.enableHover && local.action == MouseAction.motion) {
      _setHovering(true);
    }
    if (_isWheelEvent(local)) {
      final delta = switch (local.button) {
        MouseButton.wheelUp => -widget.mouseWheelDelta,
        MouseButton.wheelDown => widget.mouseWheelDelta,
        _ => 0,
      };
      if (delta == 0) return null;
      final before = widget.controller.offset;
      if (widget.controller.scrollBy(delta)) {
        _markNeedsPaint();
      }
      _traceScroll(
        'scrollbar.wheel '
        'id=${widget.id} button=${local.button} delta=$delta '
        'offset=$before->${widget.controller.offset} '
        'max=${widget.controller.maxOffset}',
      );
      return null;
    }

    if (local.action == MouseAction.motion && _dragging) {
      _handleMotion(local.y);
      return null;
    }

    if (local.button == MouseButton.left) {
      switch (local.action) {
        case MouseAction.press:
          _dragOriginY ??= zoneStartY ?? 0;
          _handlePress(local.y);
          break;
        case MouseAction.release:
          _dragging = false;
          _setThumbDragActive(false);
          _dragOriginY = null;
          break;
        default:
          break;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return _ScrollbarRender(
      child: widget.child,
      controller: widget.controller,
      trackStyle: widget.trackStyle ?? Style().foreground(theme.border),
      thumbStyle: widget.thumbStyle ?? Style().foreground(theme.onSurface),
      trackGradient: widget.trackGradient,
      thumbGradient: widget.thumbGradient,
      trackUsesBackground: widget.trackUsesBackground,
      thumbUsesBackground: widget.thumbUsesBackground,
      trackChar: widget.trackChar,
      thumbChar: widget.thumbChar,
      thickness: widget.thickness,
      gutterWidth: widget.gutterWidth,
      roundedCaps: widget.roundedCaps,
      thumbCapTopChar: widget.thumbCapTopChar,
      thumbCapBottomChar: widget.thumbCapBottomChar,
      hovered: widget.enableHover && _hovering,
      hoverTrackStyle: widget.hoverTrackStyle,
      hoverThumbStyle: widget.hoverThumbStyle,
      hoverTrackGradient: widget.hoverTrackGradient,
      hoverThumbGradient: widget.hoverThumbGradient,
      hoverTrackChar: widget.hoverTrackChar,
      hoverThumbChar: widget.hoverThumbChar,
      overlay: widget.overlay,
      gap: widget.gap,
      zoneId: _zoneId,
    );
  }
}

class _ThumbMetrics {
  const _ThumbMetrics({
    required this.viewport,
    required this.thumbExtent,
    required this.thumbTop,
    required this.maxThumbTop,
  });

  final int viewport;
  final int thumbExtent;
  final int thumbTop;
  final int maxThumbTop;
}

class _ScrollbarRender extends SingleChildRenderObjectWidget {
  _ScrollbarRender({
    required super.child,
    required this.controller,
    required this.trackStyle,
    required this.thumbStyle,
    required this.trackGradient,
    required this.thumbGradient,
    required this.trackUsesBackground,
    required this.thumbUsesBackground,
    required this.trackChar,
    required this.thumbChar,
    required this.thickness,
    required this.gutterWidth,
    required this.roundedCaps,
    required this.thumbCapTopChar,
    required this.thumbCapBottomChar,
    required this.hovered,
    required this.hoverTrackStyle,
    required this.hoverThumbStyle,
    required this.hoverTrackGradient,
    required this.hoverThumbGradient,
    required this.hoverTrackChar,
    required this.hoverThumbChar,
    required this.overlay,
    required this.gap,
    required this.zoneId,
  });

  final ScrollController controller;
  final Style trackStyle;
  final Style thumbStyle;
  final ScrollbarGradient? trackGradient;
  final ScrollbarGradient? thumbGradient;
  final bool trackUsesBackground;
  final bool thumbUsesBackground;
  final String trackChar;
  final String thumbChar;
  final int thickness;
  final int? gutterWidth;
  final bool roundedCaps;
  final String? thumbCapTopChar;
  final String? thumbCapBottomChar;
  final bool hovered;
  final Style? hoverTrackStyle;
  final Style? hoverThumbStyle;
  final ScrollbarGradient? hoverTrackGradient;
  final ScrollbarGradient? hoverThumbGradient;
  final String? hoverTrackChar;
  final String? hoverThumbChar;
  final bool overlay;
  final int gap;
  final String zoneId;

  @override
  RenderObject createRenderObject() {
    return RenderScrollbar(
      controller: controller,
      trackStyle: trackStyle,
      thumbStyle: thumbStyle,
      trackGradient: trackGradient,
      thumbGradient: thumbGradient,
      trackUsesBackground: trackUsesBackground,
      thumbUsesBackground: thumbUsesBackground,
      trackChar: trackChar,
      thumbChar: thumbChar,
      thickness: thickness,
      gutterWidth: gutterWidth,
      roundedCaps: roundedCaps,
      thumbCapTopChar: thumbCapTopChar,
      thumbCapBottomChar: thumbCapBottomChar,
      hovered: hovered,
      hoverTrackStyle: hoverTrackStyle,
      hoverThumbStyle: hoverThumbStyle,
      hoverTrackGradient: hoverTrackGradient,
      hoverThumbGradient: hoverThumbGradient,
      hoverTrackChar: hoverTrackChar,
      hoverThumbChar: hoverThumbChar,
      overlay: overlay,
      gap: gap,
      zoneId: zoneId,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final scrollbar = renderObject as RenderScrollbar;
    scrollbar
      ..controller = controller
      ..trackStyle = trackStyle
      ..thumbStyle = thumbStyle
      ..trackGradient = trackGradient
      ..thumbGradient = thumbGradient
      ..trackUsesBackground = trackUsesBackground
      ..thumbUsesBackground = thumbUsesBackground
      ..trackChar = trackChar
      ..thumbChar = thumbChar
      ..thickness = thickness
      ..gutterWidth = gutterWidth
      ..roundedCaps = roundedCaps
      ..thumbCapTopChar = thumbCapTopChar
      ..thumbCapBottomChar = thumbCapBottomChar
      ..hovered = hovered
      ..hoverTrackStyle = hoverTrackStyle
      ..hoverThumbStyle = hoverThumbStyle
      ..hoverTrackGradient = hoverTrackGradient
      ..hoverThumbGradient = hoverThumbGradient
      ..hoverTrackChar = hoverTrackChar
      ..hoverThumbChar = hoverThumbChar
      ..overlay = overlay
      ..gap = gap
      ..zoneId = zoneId;
  }

  @override
  Object view() => child?.view() ?? '';
}

/// Render object that draws a vertical scrollbar next to or over child content.
class RenderScrollbar extends RenderBox {
  RenderScrollbar({
    required this.controller,
    required this.trackStyle,
    required this.thumbStyle,
    required this.trackGradient,
    required this.thumbGradient,
    required this.trackUsesBackground,
    required this.thumbUsesBackground,
    required this.trackChar,
    required this.thumbChar,
    required this.thickness,
    required this.gutterWidth,
    required this.roundedCaps,
    required this.thumbCapTopChar,
    required this.thumbCapBottomChar,
    required this.hovered,
    required this.hoverTrackStyle,
    required this.hoverThumbStyle,
    required this.hoverTrackGradient,
    required this.hoverThumbGradient,
    required this.hoverTrackChar,
    required this.hoverThumbChar,
    required this.overlay,
    required this.gap,
    required this.zoneId,
  });

  ScrollController controller;
  Style trackStyle;
  Style thumbStyle;
  ScrollbarGradient? trackGradient;
  ScrollbarGradient? thumbGradient;
  bool trackUsesBackground;
  bool thumbUsesBackground;
  String trackChar;
  String thumbChar;
  int thickness;
  int? gutterWidth;
  bool roundedCaps;
  String? thumbCapTopChar;
  String? thumbCapBottomChar;
  bool hovered;
  Style? hoverTrackStyle;
  Style? hoverThumbStyle;
  ScrollbarGradient? hoverTrackGradient;
  ScrollbarGradient? hoverThumbGradient;
  String? hoverTrackChar;
  String? hoverThumbChar;
  bool overlay;
  int gap;
  String zoneId;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    if (children.isNotEmpty) {
      final child = children.first;
      final trackWidth = math
          .max(thickness, gutterWidth ?? thickness)
          .toDouble();
      final reserved = overlay ? 0.0 : (math.max(0, gap) + trackWidth);
      var childConstraints = constraints;
      if (!overlay && constraints.hasBoundedWidth) {
        final maxWidth = math.max(0.0, constraints.maxWidth - reserved);
        final minWidth = math.min(constraints.minWidth, maxWidth);
        childConstraints = BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
          minHeight: constraints.minHeight,
          maxHeight: constraints.maxHeight,
        );
      }
      child.layout(childConstraints);
      size = constraints.constrain(
        Size(child.size.width + reserved, child.size.height),
      );
    }
  }

  @override
  String paint() {
    if (children.isEmpty) return '';
    final child = children.first;
    final content = child.paint();

    // Use the layout-allocated child size for positioning, not the painted
    // output dimensions.  The painted output's visible width can vary per
    // line (shorter text lines, ANSI escapes, etc.) which causes the
    // scrollbar to shift left/right.  The layout size is stable.
    final layoutW = child.size.width.toInt();
    final layoutH = child.size.height.toInt();
    // Fall back to painted dimensions only when layout reports zero.
    final paintedSize = Layout.getSize(content);
    final stableW = layoutW > 0 ? layoutW : paintedSize.width;
    final stableH = layoutH > 0 ? layoutH : paintedSize.height;
    if (stableW <= 0 || stableH <= 0) {
      return content;
    }

    var thumbWidth = math.max(1, thickness);
    final trackWidth = math.max(thumbWidth, gutterWidth ?? thumbWidth);
    final isHovered = hovered || _hoveredScrollbars.contains(zoneId);
    final effectiveTrackStyle = isHovered
        ? (hoverTrackStyle ?? trackStyle)
        : trackStyle;
    final effectiveThumbStyle = isHovered
        ? (hoverThumbStyle ?? thumbStyle)
        : thumbStyle;
    final effectiveTrackGradient = isHovered
        ? (hoverTrackGradient ?? trackGradient)
        : trackGradient;
    final effectiveThumbGradient = isHovered
        ? (hoverThumbGradient ?? thumbGradient)
        : thumbGradient;
    final effectiveTrackChar = isHovered
        ? (hoverTrackChar ?? trackChar)
        : trackChar;
    final effectiveThumbChar = isHovered
        ? (hoverThumbChar ?? thumbChar)
        : thumbChar;
    final expandThumbToTrack =
        thumbUsesBackground && effectiveThumbChar.trim().isEmpty;
    if (expandThumbToTrack && trackWidth > thumbWidth) {
      thumbWidth = trackWidth;
    }

    final allowCaps =
        roundedCaps && !thumbUsesBackground && effectiveThumbChar != ' ';
    final capTop = thumbCapTopChar ?? (allowCaps ? '▀' : null);
    final capBottom = thumbCapBottomChar ?? (allowCaps ? '▄' : null);
    final bar = _renderScrollbar(
      controller: controller,
      height: stableH,
      trackWidth: trackWidth,
      thumbWidth: thumbWidth,
      trackStyle: effectiveTrackStyle,
      thumbStyle: effectiveThumbStyle,
      trackGradient: effectiveTrackGradient,
      thumbGradient: effectiveThumbGradient,
      trackUsesBackground: trackUsesBackground,
      thumbUsesBackground: thumbUsesBackground,
      trackChar: effectiveTrackChar,
      thumbChar: effectiveThumbChar,
      thumbCapTopChar: capTop,
      thumbCapBottomChar: capBottom,
      zoneId: zoneId,
    );
    if (bar.isEmpty) return content;

    if (!overlay) {
      // Use a canvas to position the scrollbar at a stable offset based on
      // the layout-allocated width rather than the painted content width.
      final gapW = math.max(0, gap);
      final totalW = stableW + gapW + trackWidth;
      final canvas = Canvas(totalW, stableH);
      _drawStyledContent(canvas, content, 0, 0);
      final barX = stableW + gapW;
      _drawStyledContent(canvas, bar, barX, 0);
      return canvas.render();
    }

    final canvas = Canvas(stableW, stableH);
    _drawStyledContent(canvas, content, 0, 0);
    final barX = math.max(0, stableW - trackWidth);
    final barOverwritesSpaces =
        trackUsesBackground ||
        thumbUsesBackground ||
        (effectiveTrackGradient?.useBackground ?? false) ||
        (effectiveThumbGradient?.useBackground ?? false);
    _drawStyledContent(
      canvas,
      bar,
      barX,
      0,
      treatSpacesAsTransparent: !barOverwritesSpaces,
    );
    return canvas.render();
  }
}

String _renderScrollbar({
  required ScrollController controller,
  required int height,
  required int trackWidth,
  required int thumbWidth,
  required Style trackStyle,
  required Style thumbStyle,
  required ScrollbarGradient? trackGradient,
  required ScrollbarGradient? thumbGradient,
  required bool trackUsesBackground,
  required bool thumbUsesBackground,
  required String trackChar,
  required String thumbChar,
  required String? thumbCapTopChar,
  required String? thumbCapBottomChar,
  required String zoneId,
}) {
  if (height <= 0 || trackWidth <= 0 || thumbWidth <= 0) return '';
  final viewport = controller.viewportExtent;
  final content = controller.contentExtent;
  if (viewport <= 0 || content <= 0) return '';

  final effectiveViewport = math.min(height, viewport);

  // Auto-hide: nothing to scroll when content fits the viewport.
  if (content <= effectiveViewport) return '';

  final maxOffset = controller.maxOffset;
  final thumbExtent = math.max(
    1,
    (effectiveViewport * effectiveViewport) ~/ content,
  );
  final maxThumbTop = math.max(0, effectiveViewport - thumbExtent);
  final thumbTop = maxOffset == 0
      ? 0
      : ((controller.offset / maxOffset) * maxThumbTop).round();

  final trackUsesBg =
      trackUsesBackground || (trackGradient?.useBackground ?? false);
  final thumbUsesBg =
      thumbUsesBackground || (thumbGradient?.useBackground ?? false);
  final padLeft = ((trackWidth - thumbWidth) / 2).floor();
  final padRight = trackWidth - thumbWidth - padLeft;
  final lines = <String>[];
  for (var i = 0; i < effectiveViewport; i++) {
    final isThumb = i >= thumbTop && i < thumbTop + thumbExtent;
    if (!isThumb) {
      lines.add(
        _styleLine(
          trackStyle,
          trackChar,
          trackWidth,
          line: i,
          height: effectiveViewport,
          gradient: trackGradient,
          useBackground: trackUsesBg,
        ),
      );
      continue;
    }

    final capChar = _thumbCapChar(
      thumbChar,
      thumbCapTopChar,
      thumbCapBottomChar,
      i,
      thumbTop,
      thumbExtent,
    );
    final thumbLine = _styleLine(
      thumbStyle,
      capChar,
      thumbWidth,
      line: i,
      height: effectiveViewport,
      gradient: thumbGradient,
      useBackground: thumbUsesBg,
    );
    if (trackWidth == thumbWidth) {
      lines.add(thumbLine);
      continue;
    }

    final left = padLeft <= 0
        ? ''
        : _styleLine(
            trackStyle,
            trackChar,
            padLeft,
            line: i,
            height: effectiveViewport,
            gradient: trackGradient,
            useBackground: trackUsesBg,
          );
    final right = padRight <= 0
        ? ''
        : _styleLine(
            trackStyle,
            trackChar,
            padRight,
            line: i,
            height: effectiveViewport,
            gradient: trackGradient,
            useBackground: trackUsesBg,
          );
    lines.add('$left$thumbLine$right');
  }

  final contentStr = lines.join('\n');
  final manager = globalZone;
  return manager == null ? contentStr : manager.mark(zoneId, contentStr);
}

String _styleLine(
  Style style,
  String char,
  int width, {
  required int line,
  required int height,
  required ScrollbarGradient? gradient,
  required bool useBackground,
}) {
  final resolved = _resolveScrollbarStyle(
    base: style,
    line: line,
    height: height,
    gradient: gradient,
    useBackground: useBackground,
  );
  final text = _repeatChar(char, width);
  return resolved.render(text);
}

String _thumbCapChar(
  String fallback,
  String? top,
  String? bottom,
  int line,
  int thumbTop,
  int thumbExtent,
) {
  if (thumbExtent <= 0) return fallback;
  if (line == thumbTop) return top ?? fallback;
  if (line == thumbTop + thumbExtent - 1) return bottom ?? fallback;
  return fallback;
}

Style _resolveScrollbarStyle({
  required Style base,
  required int line,
  required int height,
  required ScrollbarGradient? gradient,
  required bool useBackground,
}) {
  final style = base.copy();
  style.hasDarkBackground = hasDarkBackground;

  if (gradient != null) {
    final color = _gradientColor(gradient, line, height);
    if (color != null) {
      if (gradient.useBackground || useBackground) {
        style.background(color);
      } else {
        style.foreground(color);
      }
    }
  }

  return style;
}

Color? _gradientColor(ScrollbarGradient gradient, int line, int height) {
  if (height <= 1) return _resolveGradientStop(gradient.start);
  final t = (line / (height - 1)).clamp(0, 1.0);
  final start = _resolveGradientStop(gradient.start);
  final end = _resolveGradientStop(gradient.end);
  final startRgb = _colorToRgb(start);
  final endRgb = _colorToRgb(end);
  if (startRgb == null || endRgb == null) return start;
  final r = (startRgb.$1 + (endRgb.$1 - startRgb.$1) * t).round();
  final g = (startRgb.$2 + (endRgb.$2 - startRgb.$2) * t).round();
  final b = (startRgb.$3 + (endRgb.$3 - startRgb.$3) * t).round();
  return BasicColor(_hexFromRgb(r, g, b));
}

Color _resolveGradientStop(Color color) {
  if (color is AdaptiveColor) {
    return hasDarkBackground ? color.dark : color.light;
  }
  return color;
}

(int, int, int)? _colorToRgb(Color color) {
  final hex = color.toHex();
  if (hex.isEmpty) return null;
  var value = hex.startsWith('#') ? hex.substring(1) : hex;
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (value.length != 6) return null;
  final r = int.tryParse(value.substring(0, 2), radix: 16);
  final g = int.tryParse(value.substring(2, 4), radix: 16);
  final b = int.tryParse(value.substring(4, 6), radix: 16);
  if (r == null || g == null || b == null) return null;
  return (r, g, b);
}

String _hexFromRgb(int r, int g, int b) {
  final rr = r.clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final gg = g.clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final bb = b.clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#$rr$gg$bb';
}

String _repeatChar(String char, int count) {
  if (count <= 0) return '';
  if (count == 1) return char;
  final buffer = StringBuffer();
  for (var i = 0; i < count; i++) {
    buffer.write(char);
  }
  return buffer.toString();
}

void _drawStyledContent(
  Canvas canvas,
  String content,
  int startX,
  int startY, {
  bool treatSpacesAsTransparent = false,
}) {
  final styled = StyledString(content);
  final styledBounds = styled.bounds();
  final tempCanvas = Canvas(styledBounds.width, styledBounds.height);
  styled.draw(tempCanvas, tempCanvas.bounds());

  for (var y = 0; y < styledBounds.height; y++) {
    for (var x = 0; x < styledBounds.width; x++) {
      final destX = startX + x;
      final destY = startY + y;

      if (destX < 0 || destY < 0) continue;
      if (destX >= canvas.width() || destY >= canvas.height()) continue;

      final srcCell = tempCanvas.cellAt(x, y);
      if (srcCell == null || srcCell.isZero) continue;
      if (treatSpacesAsTransparent && srcCell.isEmpty) continue;

      canvas.setCell(destX, destY, srcCell.clone());
    }
  }
}

/// A scrollable list of child widgets.
///
/// Children remain in the element tree (unlike the old implementation that
/// rendered children to strings). Stateful children are fully supported.
///
/// Provide a [ScrollController] to share scroll state with a [Scrollbar].
///
/// Flutter-like constructors are available:
/// - [ListView] for an explicit [children] list
/// - [ListView.builder] for index-based item generation
/// - [ListView.separated] for generated separators between items
typedef IndexedWidgetBuilder = Widget Function(BuildContext context, int index);

typedef IndexedSeparatorBuilder =
    Widget Function(BuildContext context, int index);

class ListView extends StatefulWidget {
  /// Creates a list view that keeps child widgets mounted.
  ListView({
    List<Widget> children = const <Widget>[],
    this.separator = '\n',
    this.controller,
    this.padding,
    this.handleKeys = true,
    this.mouseWheelDelta = 3,
    super.key,
  }) : _children = children,
       itemBuilder = null,
       separatorBuilder = null,
       itemCount = children.length;

  /// Creates a list view that lazily builds items by index.
  ListView.builder({
    required this.itemBuilder,
    required this.itemCount,
    this.separator = '\n',
    this.controller,
    this.padding,
    this.handleKeys = true,
    this.mouseWheelDelta = 3,
    super.key,
  }) : assert(itemCount >= 0),
       _children = null,
       separatorBuilder = null;

  /// Creates a list view with explicit separators between generated items.
  ListView.separated({
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.itemCount,
    this.separator = '\n',
    this.controller,
    this.padding,
    this.handleKeys = true,
    this.mouseWheelDelta = 3,
    super.key,
  }) : assert(itemCount >= 0),
       _children = null;

  final List<Widget>? _children;

  /// Item builder for [ListView.builder] and [ListView.separated].
  final IndexedWidgetBuilder? itemBuilder;

  /// Separator builder for [ListView.separated].
  final IndexedSeparatorBuilder? separatorBuilder;

  /// Number of items produced by [itemBuilder].
  final int itemCount;

  /// Child widgets rendered in order (explicit list constructor only).
  @override
  List<Widget> get children => _children ?? const <Widget>[];

  /// Text inserted between rendered children.
  final String separator;

  /// Optional external scroll controller.
  final ScrollController? controller;

  /// Optional padding around the scrollable content.
  final EdgeInsets? padding;

  /// Whether keyboard keys trigger scrolling.
  final bool handleKeys;

  /// Number of rows scrolled per mouse wheel tick.
  final int mouseWheelDelta;

  @override
  State createState() => _ListViewState();
}

class _ListViewState extends State<ListView> {
  WidgetScrollController? _ownController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownController ??= WidgetScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_markNeedsPaintScrollOnly);
  }

  @override
  Cmd? didUpdateWidget(covariant ListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(
        _markNeedsPaintScrollOnly,
      );
      if (widget.controller != null) {
        _ownController = null;
      }
      _effectiveController.addListener(_markNeedsPaintScrollOnly);
    }
    return null;
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_markNeedsPaintScrollOnly);
    super.dispose();
  }

  /// Schedules a repaint for scroll-offset changes only. Does NOT invalidate
  /// the viewport's child paint cache because the child content hasn't changed.
  void _markNeedsPaintScrollOnly() {
    final element = elementOf(widget);
    element?.markNeedsPaintScrollOnly();
  }

  void _markNeedsPaint() {
    final element = elementOf(widget);
    element?.markNeedsPaint();
  }

  bool _scrollBy(int delta) {
    final changed = _effectiveController.scrollBy(delta);
    if (changed) _markNeedsPaint();
    return changed;
  }

  bool _handleKey(terminal_keys.Key key) {
    final viewportHeight = _effectiveController.viewportExtent;
    switch (key.type) {
      case terminal_keys.KeyType.up:
        return _scrollBy(-1);
      case terminal_keys.KeyType.down:
        return _scrollBy(1);
      case terminal_keys.KeyType.pageUp:
        if (viewportHeight <= 0) return false;
        return _scrollBy(-viewportHeight);
      case terminal_keys.KeyType.pageDown:
        if (viewportHeight <= 0) return false;
        return _scrollBy(viewportHeight);
      case terminal_keys.KeyType.home:
        if (_effectiveController.jumpTo(0)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      case terminal_keys.KeyType.end:
        if (_effectiveController.jumpTo(_effectiveController.maxOffset)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) {
      final local = msg.event.copyWith(
        x: msg.localX.toInt(),
        y: msg.localY.toInt(),
      );
      if (_isWheelEvent(local)) {
        final delta = switch (local.button) {
          MouseButton.wheelUp => -widget.mouseWheelDelta,
          MouseButton.wheelDown => widget.mouseWheelDelta,
          _ => 0,
        };
        if (delta != 0) _scrollBy(delta);
        return Cmd.none();
      }
    }
    if (widget.handleKeys && msg is KeyMsg) {
      _handleKey(msg.key);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final builtChildren = _buildChildren(context);

    Widget body = _ListViewViewport(
      controller: _effectiveController,
      separator: widget.separator,
      children: builtChildren,
    );

    final padding = widget.padding;
    if (padding != null) {
      body = Padding(padding: padding, child: body);
    }

    return body;
  }

  List<Widget> _buildChildren(BuildContext context) {
    final staticChildren = widget._children;
    if (staticChildren != null) {
      return staticChildren;
    }

    final itemBuilder = widget.itemBuilder;
    if (itemBuilder == null || widget.itemCount <= 0) {
      return const <Widget>[];
    }

    final separatorBuilder = widget.separatorBuilder;
    if (separatorBuilder == null) {
      return List<Widget>.generate(
        widget.itemCount,
        (index) => itemBuilder(context, index),
      );
    }

    final result = <Widget>[];
    for (var i = 0; i < widget.itemCount; i++) {
      result.add(itemBuilder(context, i));
      if (i < widget.itemCount - 1) {
        result.add(separatorBuilder(context, i));
      }
    }
    return result;
  }
}

/// Internal multi-child render object widget for [ListView].
class _ListViewViewport extends MultiChildRenderObjectWidget {
  _ListViewViewport({
    required this.controller,
    required this.separator,
    required super.children,
  });

  final ScrollController controller;
  final String separator;

  @override
  RenderObject createRenderObject() {
    return RenderListViewScrollViewport(
      controller: controller,
      separator: separator,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final rv = renderObject as RenderListViewScrollViewport;
    rv
      ..controller = controller
      ..separator = separator;
    // The widget tree rebuilt — child content may have changed.
    rv.invalidateChildPaintCache();
  }

  @override
  Object view() {
    if (children.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < children.length; i++) {
      buffer.write(_renderWidget(children[i]));
      if (i < children.length - 1) buffer.write(separator);
    }
    return buffer.toString();
  }
}

/// Render object for [_ListViewViewport].
///
/// Lays out all children (so they stay in the element tree), paints them,
/// joins with [separator], and clips to the viewport window based on
/// scroll offset.
class RenderListViewScrollViewport extends RenderBox {
  RenderListViewScrollViewport({
    required this.controller,
    required this.separator,
  });

  ScrollController controller;

  String separator;

  // --- Paint cache ---
  List<String>? _cachedChildPaintLines;
  BoxConstraints? _cachedChildConstraints;
  double? _cachedTotalHeight;
  int? _cachedChildCount;

  /// Marks the cached child paint output as stale.
  void invalidateChildPaintCache() {
    _cachedChildPaintLines = null;
  }

  @override
  void markDescendantNeedsPaint() {
    super.markDescendantNeedsPaint();
    invalidateChildPaintCache();
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    // Layout all children with unconstrained height.
    final childConstraints = BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
    );
    var maxChildWidth = 0.0;
    var totalHeight = 0.0;
    var y = 0.0;
    final separatorBreaks = _separatorBreaks(separator);
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      child.layout(childConstraints);
      child.offset = Offset(0, y);

      maxChildWidth = math.max(maxChildWidth, child.size.width);
      totalHeight += child.size.height;
      y += child.size.height;

      if (i < children.length - 1) {
        totalHeight += separatorBreaks;
        y += separatorBreaks;
      }
    }

    // Invalidate paint cache if constraints, total height, or child count
    // changed.
    if (_cachedChildConstraints != childConstraints ||
        _cachedTotalHeight != totalHeight ||
        _cachedChildCount != children.length) {
      _cachedChildPaintLines = null;
      _cachedChildConstraints = childConstraints;
      _cachedTotalHeight = totalHeight;
      _cachedChildCount = children.length;
    }

    size = constraints.constrain(Size(maxChildWidth, constraints.maxHeight));

    final viewportHeight = size.height.round();
    final contentHeight = totalHeight.round();
    if (controller is WidgetScrollController) {
      (controller as WidgetScrollController).updateMetrics(
        viewportExtent: viewportHeight,
        contentExtent: contentHeight,
      );
    } else if (controller is ListViewController) {
      final lvc = controller as ListViewController;
      lvc.setViewportHeight(viewportHeight);
      lvc.setContentHeight(contentHeight);
    }
  }

  @override
  String paint() {
    if (children.isEmpty) return '';

    // Use cached content lines if available; otherwise paint all children
    // and cache the result.
    final lines = _cachedChildPaintLines ?? _paintAndCacheChildren();
    if (lines.isEmpty) return '';

    final viewportHeight = size.height.round();
    final scrollOffset = controller.offset.clamp(0, controller.maxOffset);

    if (scrollOffset >= lines.length) return '';
    final endLine = math.min(lines.length, scrollOffset + viewportHeight);
    final visible = lines.sublist(scrollOffset, endLine);

    while (visible.length < viewportHeight) {
      visible.add('');
    }

    return visible.join('\n');
  }

  @override
  bool hitTest(
    HitTestResult result, {
    required double localX,
    required double localY,
  }) {
    if (localX < 0 ||
        localY < 0 ||
        localX >= size.width ||
        localY >= size.height) {
      return false;
    }

    if (children.isEmpty) return true;

    final offset = controller.offset.clamp(0, controller.maxOffset).toDouble();
    final contentY = localY + offset;
    final separatorBreaks = _separatorBreaks(separator).toDouble();
    var top = 0.0;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final bottom = top + child.size.height;

      if (contentY >= top && contentY < bottom) {
        final childX = localX - child.offset.dx;
        final childY = contentY - child.offset.dy;
        child.hitTest(result, localX: childX, localY: childY);
        break;
      }

      top = bottom;
      if (i < children.length - 1) {
        top += separatorBreaks;
      }
    }

    // Capture the hit for wheel/key scrolling even when no child is hit.
    return true;
  }

  List<String> _paintAndCacheChildren() {
    final buffer = StringBuffer();
    for (var i = 0; i < children.length; i++) {
      buffer.write(children[i].paint());
      if (i < children.length - 1 && separator.isNotEmpty) {
        buffer.write(separator);
      }
    }
    final allContent = buffer.toString();
    _cachedChildPaintLines = allContent.split('\n');
    return _cachedChildPaintLines!;
  }
}

/// Controller for scroll position in [VirtualListView].
///
/// Tracks the viewport height, content height, and current offset in rows.
class ListViewController implements ScrollController {
  int _offset = 0;
  int _viewportHeight = 0;
  int _contentHeight = 0;
  final Set<void Function()> _listeners = <void Function()>{};

  @override
  int get offset => _offset;

  @override
  int get viewportExtent => _viewportHeight;

  @override
  int get contentExtent => _contentHeight;

  /// Current viewport height in rows.
  int get viewportHeight => _viewportHeight;

  /// Current content height in rows.
  int get contentHeight => _contentHeight;

  @override
  int get maxOffset => math.max(0, _contentHeight - _viewportHeight);

  @override
  double get scrollPercent => maxOffset == 0 ? 0 : _offset / maxOffset;

  /// Updates the viewport height and clamps offset if needed.
  bool setViewportHeight(int height) {
    if (height < 0) height = 0;
    if (_viewportHeight == height) return false;
    final beforeHeight = _viewportHeight;
    final beforeOffset = _offset;
    _viewportHeight = height;
    final clamped = _clampOffset();
    _traceScroll(
      'list_view.metrics.viewport '
      'view=$beforeHeight->$_viewportHeight '
      'offset=$beforeOffset->$_offset max=$maxOffset clamped=$clamped',
    );
    return clamped;
  }

  /// Updates the content height and clamps offset if needed.
  bool setContentHeight(int height) {
    if (height < 0) height = 0;
    if (_contentHeight == height) return false;
    final beforeHeight = _contentHeight;
    final beforeOffset = _offset;
    _contentHeight = height;
    final clamped = _clampOffset();
    _traceScroll(
      'list_view.metrics.content '
      'content=$beforeHeight->$_contentHeight '
      'offset=$beforeOffset->$_offset max=$maxOffset clamped=$clamped',
    );
    return clamped;
  }

  @override
  bool scrollBy(int delta) {
    if (delta == 0) return false;
    final before = _offset;
    final next = (_offset + delta).clamp(0, maxOffset);
    if (next == _offset) {
      _traceScroll(
        'list_view.scrollBy noop '
        'delta=$delta offset=$before max=$maxOffset',
      );
      return false;
    }
    _offset = next;
    _notifyListeners();
    _traceScroll(
      'list_view.scrollBy '
      'delta=$delta from=$before to=$_offset max=$maxOffset',
    );
    return true;
  }

  @override
  bool jumpTo(int offset) {
    final before = _offset;
    final next = offset.clamp(0, maxOffset);
    if (next == _offset) {
      _traceScroll(
        'list_view.jumpTo noop '
        'target=$offset offset=$before max=$maxOffset',
      );
      return false;
    }
    _offset = next;
    _notifyListeners();
    _traceScroll(
      'list_view.jumpTo '
      'target=$offset from=$before to=$_offset max=$maxOffset',
    );
    return true;
  }

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  bool _clampOffset() {
    final before = _offset;
    final next = _offset.clamp(0, maxOffset);
    if (next == _offset) return false;
    _offset = next;
    _notifyListeners();
    _traceScroll(
      'list_view.clamp '
      'from=$before to=$_offset max=$maxOffset',
    );
    return true;
  }
}

/// A render-object driven list view that only paints visible items.
///
/// This is optimized for long lists. By default it assumes fixed-height rows
/// using [itemExtent]. When [variableHeight] is true, each child is measured
/// on demand and the list uses [estimatedItemExtent] for items that have not
/// been measured yet.
class VirtualListView extends StatefulWidget {
  /// Creates a virtualized list view.
  VirtualListView({
    required this.children,
    this.width,
    this.height,
    this.itemExtent = 1,
    this.estimatedItemExtent,
    this.variableHeight = false,
    this.separator = '\n',
    this.handleKeys = true,
    this.mouseWheelEnabled = true,
    this.mouseWheelDelta = 3,
    this.enableSelection = false,
    this.autoCopySelectionOnMouseUp = false,
    this.autoCopySelectionOnExit = false,
    this.clearSelectionAfterAutoCopy = true,
    this.controller,
    this.zoneId,
    super.key,
  });

  /// Child widgets rendered by index.
  @override
  final List<Widget> children;

  /// Optional explicit width in columns.
  final int? width;

  /// Optional explicit height in rows.
  final int? height;

  /// Fixed item height used when [variableHeight] is false.
  final int itemExtent;

  /// Estimated height in rows for items when [variableHeight] is true.
  ///
  /// Defaults to [itemExtent] when null.
  final int? estimatedItemExtent;

  /// Whether to measure children dynamically instead of using [itemExtent].
  final bool variableHeight;

  /// Text inserted between items.
  final String separator;

  /// Whether keyboard keys trigger scrolling.
  final bool handleKeys;

  /// Whether mouse wheel messages trigger scrolling.
  final bool mouseWheelEnabled;

  /// Number of rows scrolled per mouse wheel tick.
  final int mouseWheelDelta;

  /// Whether in-app text selection is enabled.
  final bool enableSelection;

  /// Whether to auto-copy selected text when mouse button is released.
  final bool autoCopySelectionOnMouseUp;

  /// Whether to auto-copy selected text immediately when drag leaves bounds.
  final bool autoCopySelectionOnExit;

  /// Whether to clear selection after auto-copy.
  final bool clearSelectionAfterAutoCopy;

  /// Optional external scroll controller.
  final ScrollController? controller;

  /// Optional mouse zone id override.
  final String? zoneId;

  @override
  State createState() => _VirtualListViewState();
}

class _VirtualListViewState extends State<VirtualListView> {
  static const _wheelMinTickInterval = Duration(milliseconds: 6);

  late ScrollController _controller;
  bool _controllerAttached = false;
  MouseMsg? _lastSelectionHitMouse;
  double _wheelAccumulator = 0;
  DateTime? _lastWheelEventAt;
  int _lastWheelDirection = 0;

  String get _zoneId => widget.zoneId ?? 'listview-${widget.id}';

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
  }

  @override
  Cmd? didUpdateWidget(covariant VirtualListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _attachController(widget.controller);
    }
    return null;
  }

  void _attachController(ScrollController? controller) {
    if (_controllerAttached) {
      _controller.removeListener(_markNeedsPaint);
    }
    _controller = controller ?? ListViewController();
    _controller.addListener(_markNeedsPaint);
    _controllerAttached = true;
  }

  @override
  void dispose() {
    if (_controllerAttached) {
      _controller.removeListener(_markNeedsPaint);
    }
    super.dispose();
  }

  void _markNeedsPaint() {
    final element = elementOf(widget);
    element?.markNeedsPaint();
  }

  bool _scrollBy(int delta) {
    final before = _controller.offset;
    final changed = _controller.scrollBy(delta);
    final after = _controller.offset;
    if (changed) {
      _markNeedsPaint();
    }
    _traceScroll(
      'virtual_list.scrollBy '
      'id=${widget.id} delta=$delta from=$before to=$after '
      'max=${_controller.maxOffset} changed=$changed',
    );
    return changed;
  }

  Cmd? _applyWheelDelta(int delta) {
    if (delta == 0) return null;

    final direction = delta > 0 ? 1 : -1;
    final beforeAccumulator = _wheelAccumulator;
    final now = DateTime.now();
    final last = _lastWheelEventAt;
    final duplicatePulse =
        last != null &&
        now.difference(last) < _wheelMinTickInterval &&
        _lastWheelDirection == direction;
    _lastWheelEventAt = now;
    _lastWheelDirection = direction;

    if (beforeAccumulator != 0 && beforeAccumulator.sign != delta.sign) {
      _traceScroll(
        'virtual_list.wheel.flip '
        'id=${widget.id} accumulator=$beforeAccumulator delta=$delta '
        'offset=${_controller.offset} max=${_controller.maxOffset}',
      );
      _wheelAccumulator = 0;
    }

    _wheelAccumulator += delta;
    final step = _wheelAccumulator.truncate();
    _wheelAccumulator -= step;
    final changed = step != 0 && _scrollBy(step);

    _traceScroll(
      'virtual_list.wheel.apply '
      'id=${widget.id} delta=$delta step=$step '
      'accumulator=$beforeAccumulator->$_wheelAccumulator '
      'duplicate=$duplicatePulse changed=$changed '
      'offset=${_controller.offset} max=${_controller.maxOffset}',
    );
    return null;
  }

  bool _handleKey(terminal_keys.Key key) {
    final viewportHeight = _controller.viewportExtent > 0
        ? _controller.viewportExtent
        : null;
    switch (key.type) {
      case terminal_keys.KeyType.up:
        return _scrollBy(-1);
      case terminal_keys.KeyType.down:
        return _scrollBy(1);
      case terminal_keys.KeyType.pageUp:
        if (viewportHeight == null) return false;
        return _scrollBy(-viewportHeight);
      case terminal_keys.KeyType.pageDown:
        if (viewportHeight == null) return false;
        return _scrollBy(viewportHeight);
      case terminal_keys.KeyType.home:
        if (_controller.jumpTo(0)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      case terminal_keys.KeyType.end:
        if (_controller.jumpTo(_controller.maxOffset)) {
          _markNeedsPaint();
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _VirtualListViewport(
      controller: _controller,
      zoneId: _zoneId,
      width: widget.width,
      height: widget.height,
      itemExtent: widget.itemExtent,
      estimatedItemExtent: widget.estimatedItemExtent,
      variableHeight: widget.variableHeight,
      separator: widget.separator,
      children: widget.children,
    );
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    Cmd? cmd;

    // ---- New: render-tree hit-test dispatch ----
    if (msg is HitTestMouseMsg) {
      if (widget.enableSelection) {
        _lastSelectionHitMouse = msg.event;
      }
      if (widget.mouseWheelEnabled) {
        final local = msg.event.copyWith(
          x: msg.localX.toInt(),
          y: msg.localY.toInt(),
        );
        if (_isWheelEvent(local)) {
          final delta = local.button == MouseButton.wheelUp
              ? -widget.mouseWheelDelta
              : widget.mouseWheelDelta;
          _traceScroll(
            'virtual_list.wheel.hit '
            'id=${widget.id} local=(${local.x},${local.y}) '
            'button=${local.button} delta=$delta '
            'offset=${_controller.offset} max=${_controller.maxOffset}',
          );
          cmd = _applyWheelDelta(delta) ?? cmd;
          return cmd ?? Cmd.none();
        }
      }
      if (widget.enableSelection) {
        cmd = _handleSelectionMouse(msg) ?? cmd;
      }
    }

    // ---- Legacy: zone-based dispatch ----
    if (msg is ZoneInBoundsMsg && msg.zone.id == _zoneId) {
      if (widget.mouseWheelEnabled) {
        final local = msg.event.copyWith(
          x: msg.zone.pos(msg.event).x,
          y: msg.zone.pos(msg.event).y,
        );
        if (_isWheelEvent(local)) {
          final delta = local.button == MouseButton.wheelUp
              ? -widget.mouseWheelDelta
              : widget.mouseWheelDelta;
          _traceScroll(
            'virtual_list.wheel.zone '
            'id=${widget.id} local=(${local.x},${local.y}) '
            'button=${local.button} delta=$delta '
            'offset=${_controller.offset} max=${_controller.maxOffset}',
          );
          cmd = _applyWheelDelta(delta) ?? cmd;
          return cmd ?? Cmd.none();
        }
      }
    }

    if (msg is MouseMsg &&
        widget.enableSelection &&
        widget.autoCopySelectionOnExit) {
      final ctrl = _controller;
      if (ctrl is WidgetScrollController && ctrl._selecting) {
        final sameAsHit =
            _lastSelectionHitMouse != null && msg == _lastSelectionHitMouse;
        if (!sameAsHit &&
            (msg.action == MouseAction.motion ||
                msg.action == MouseAction.release)) {
          ctrl._selecting = false;
          return _copyCurrentSelection(
            clearAfterCopy: widget.clearSelectionAfterAutoCopy,
          );
        }
      }
    }

    if (msg is KeyMsg) {
      if (widget.enableSelection) {
        final selectionCmd = _handleSelectionKey(msg);
        if (selectionCmd != null) return selectionCmd;
      }
      if (widget.handleKeys && _handleKey(msg.key)) {
        return null;
      }
    }

    return cmd;
  }

  Cmd? _handleSelectionMouse(HitTestMouseMsg msg) {
    final ctrl = _controller;
    if (ctrl is! WidgetScrollController) return null;

    final event = msg.event;
    final ro = _findRenderViewport();
    final vpGlobalY = ro != null ? _roGlobalY(ro) : 0.0;
    final vpGlobalX = ro != null ? _roGlobalX(ro) : 0.0;
    final contentX = (event.x - vpGlobalX).toInt();
    final contentY = (event.y - vpGlobalY).toInt() + ctrl.offset;

    if (event.action == MouseAction.motion && ctrl._selecting) {
      ctrl._selectionEnd = (x: contentX, y: contentY);
      _markNeedsPaint();
      return null;
    }
    if (event.action == MouseAction.release && ctrl._selecting) {
      ctrl._selecting = false;
      if (widget.autoCopySelectionOnMouseUp) {
        return _copyCurrentSelection(
          clearAfterCopy: widget.clearSelectionAfterAutoCopy,
        );
      }
      return null;
    }

    if (event.button == MouseButton.left && event.action == MouseAction.press) {
      final now = DateTime.now();
      final pos = (x: contentX, y: contentY);

      if (ctrl._lastClickTime != null &&
          now.difference(ctrl._lastClickTime!) <
              const Duration(milliseconds: 500) &&
          ctrl._lastClickPos == pos) {
        final ro = _findRenderViewport();
        if (ro != null) {
          final lines = ro.allContentLinesForSelection();
          final (wordStart, wordEnd) = _findWordAt(lines, contentX, contentY);
          ctrl._selectionStart = (x: wordStart, y: contentY);
          ctrl._selectionEnd = (x: wordEnd, y: contentY);
          ctrl._selecting = false;
          ctrl._lastClickTime = now;
          ctrl._lastClickPos = pos;
          _markNeedsPaint();
        }
        return null;
      }

      ctrl._selectionStart = pos;
      ctrl._selectionEnd = pos;
      ctrl._selecting = true;
      ctrl._lastClickTime = now;
      ctrl._lastClickPos = pos;
      _markNeedsPaint();
      return null;
    }

    return null;
  }

  Cmd? _handleSelectionKey(KeyMsg msg) {
    final ctrl = _controller;
    if (ctrl is! WidgetScrollController) return null;
    if (msg.key.char == 'c' && msg.key.ctrl && ctrl.hasSelection) {
      return _copyCurrentSelection(clearAfterCopy: false);
    }
    return null;
  }

  Cmd? _copyCurrentSelection({required bool clearAfterCopy}) {
    final ctrl = _controller;
    if (ctrl is! WidgetScrollController) return null;
    if (!ctrl.hasSelection) return null;

    final ro = _findRenderViewport();
    if (ro == null) {
      if (clearAfterCopy) ctrl.clearSelection();
      return null;
    }

    final lines = ro.allContentLinesForSelection();
    final text = ctrl.getSelectedText(lines);
    if (text.isEmpty) {
      if (clearAfterCopy) ctrl.clearSelection();
      return null;
    }

    if (clearAfterCopy) {
      ctrl.clearSelection();
    }
    return Cmd.setClipboard(text);
  }

  RenderListViewport? _findRenderViewport() {
    final el = elementOf(widget);
    if (el == null) return null;
    RenderListViewport? result;
    void visit(Element e) {
      if (result != null) return;
      if (e is RenderObjectElement && e.renderObject is RenderListViewport) {
        result = e.renderObject as RenderListViewport;
        return;
      }
      for (final child in e.children) {
        visit(child);
        if (result != null) return;
      }
    }

    visit(el);
    return result;
  }
}

class _VirtualListViewport extends MultiChildRenderObjectWidget {
  _VirtualListViewport({
    required this.controller,
    required this.zoneId,
    required this.width,
    required this.height,
    required this.itemExtent,
    required this.estimatedItemExtent,
    required this.variableHeight,
    required this.separator,
    required super.children,
  });

  final ScrollController controller;
  final String zoneId;
  final int? width;
  final int? height;
  final int itemExtent;
  final int? estimatedItemExtent;
  final bool variableHeight;
  final String separator;

  @override
  RenderObject createRenderObject() {
    return RenderListViewport(
      controller: controller,
      zoneId: zoneId,
      width: width,
      height: height,
      itemExtent: itemExtent,
      estimatedItemExtent: estimatedItemExtent,
      variableHeight: variableHeight,
      separator: separator,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final viewport = renderObject as RenderListViewport;
    viewport
      ..controller = controller
      ..zoneId = zoneId
      ..width = width
      ..height = height
      ..itemExtent = itemExtent
      ..estimatedItemExtent = estimatedItemExtent
      ..variableHeight = variableHeight
      ..separator = separator;
  }

  @override
  Object view() {
    if (children.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < children.length; i++) {
      buffer.write(_renderWidget(children[i]));
      if (i < children.length - 1) buffer.write(separator);
    }
    return buffer.toString();
  }
}

/// Render object backing [VirtualListView].
///
/// It virtualizes painting to only include visible items and supports both
/// fixed-height and variable-height modes.
class RenderListViewport extends RenderBox {
  RenderListViewport({
    required this.controller,
    required this.zoneId,
    required this.width,
    required this.height,
    required this.itemExtent,
    required this.estimatedItemExtent,
    required this.variableHeight,
    required this.separator,
  });

  ScrollController controller;
  String zoneId;
  int? width;
  int? height;
  int itemExtent;
  int? estimatedItemExtent;
  bool variableHeight;
  String separator;

  final Map<int, int> _measuredHeights = <int, int>{};
  final Map<int, _ChildPaintSnapshot> _childPaintCache =
      <int, _ChildPaintSnapshot>{};
  List<int>? _cachedPrefix;
  int _cachedItemCount = -1;
  int _cachedSeparatorBreaks = -1;
  int _cachedEstimated = -1;
  int? _cachedContentHeight;
  int? _lastMaxWidth;
  bool _needsRepaint = false;
  int _lastPaintOffset = -1;
  int _lastPaintViewportHeight = -1;
  int _lastOffsetInItem = 0;
  final List<_VisibleItemHit> _lastVisibleHits = <_VisibleItemHit>[];
  String? _cachedVisibleContent;
  int _cachedVisibleOffset = -1;
  int _cachedVisibleViewportHeight = -1;
  int _cachedVisibleMaxWidth = -1;
  int _cachedVisibleItemCount = -1;
  int _cachedVisibleSeparatorBreaks = -1;
  bool _cachedVisibleVariableHeight = false;

  bool _setMetrics({required int viewportExtent, required int contentExtent}) {
    final c = controller;
    if (c is WidgetScrollController) {
      return c.updateMetrics(
        viewportExtent: viewportExtent,
        contentExtent: contentExtent,
      );
    }
    if (c is ListViewController) {
      final changedViewport = c.setViewportHeight(viewportExtent);
      final changedContent = c.setContentHeight(contentExtent);
      return changedViewport || changedContent;
    }
    return false;
  }

  bool _setContentExtent(int contentExtent) {
    final c = controller;
    if (c is WidgetScrollController) {
      return c.updateMetrics(
        viewportExtent: c.viewportExtent,
        contentExtent: contentExtent,
      );
    }
    if (c is ListViewController) {
      return c.setContentHeight(contentExtent);
    }
    return false;
  }

  void _invalidateVisiblePaintCache() {
    _cachedVisibleContent = null;
    _cachedVisibleOffset = -1;
    _cachedVisibleViewportHeight = -1;
    _cachedVisibleMaxWidth = -1;
    _cachedVisibleItemCount = -1;
    _cachedVisibleSeparatorBreaks = -1;
  }

  void _invalidateMeasurements() {
    _cachedPrefix = null;
    _cachedContentHeight = null;
  }

  void _clearMeasurements() {
    _invalidateMeasurements();
    _measuredHeights.clear();
    _childPaintCache.clear();
    _invalidateVisiblePaintCache();
  }

  @override
  void markDescendantNeedsPaint() {
    super.markDescendantNeedsPaint();
    _needsRepaint = true;
    _invalidateVisiblePaintCache();
  }

  void _resetRepaintFlag() {
    _needsRepaint = false;
  }

  void _resetVisibleHitCache() {
    _lastVisibleHits.clear();
    _lastPaintOffset = -1;
    _lastPaintViewportHeight = -1;
    _lastOffsetInItem = 0;
  }

  bool _canUseVisiblePaintCache({
    required int offset,
    required int viewportHeight,
    required int maxWidth,
    required int itemCount,
    required int separatorBreaks,
    required bool isVariableHeight,
  }) {
    if (_needsRepaint || _cachedVisibleContent == null) return false;
    return _cachedVisibleOffset == offset &&
        _cachedVisibleViewportHeight == viewportHeight &&
        _cachedVisibleMaxWidth == maxWidth &&
        _cachedVisibleItemCount == itemCount &&
        _cachedVisibleSeparatorBreaks == separatorBreaks &&
        _cachedVisibleVariableHeight == isVariableHeight;
  }

  void _storeVisiblePaintCache({
    required String visible,
    required int offset,
    required int viewportHeight,
    required int maxWidth,
    required int itemCount,
    required int separatorBreaks,
    required bool isVariableHeight,
  }) {
    _cachedVisibleContent = visible;
    _cachedVisibleOffset = offset;
    _cachedVisibleViewportHeight = viewportHeight;
    _cachedVisibleMaxWidth = maxWidth;
    _cachedVisibleItemCount = itemCount;
    _cachedVisibleSeparatorBreaks = separatorBreaks;
    _cachedVisibleVariableHeight = isVariableHeight;
  }

  void _syncCache(int itemCount, int separatorBreaks, int estimate) {
    if (_cachedItemCount != itemCount ||
        _cachedSeparatorBreaks != separatorBreaks ||
        _cachedEstimated != estimate) {
      _cachedItemCount = itemCount;
      _cachedSeparatorBreaks = separatorBreaks;
      _cachedEstimated = estimate;
      _cachedPrefix = null;
      _cachedContentHeight = null;
      _measuredHeights.removeWhere((index, _) => index >= itemCount);
      _childPaintCache.removeWhere((index, _) => index >= itemCount);
    }
  }

  ({String text, int measured}) _resolveChildPaint({
    required int index,
    required int maxWidth,
  }) {
    final child = children[index];
    final cached = _childPaintCache[index];
    if (cached != null && cached.maxWidth == maxWidth && !child.paintDirty) {
      return (text: cached.text, measured: cached.measured);
    }

    child.layout(
      BoxConstraints(
        minWidth: maxWidth.toDouble(),
        maxWidth: maxWidth.toDouble(),
      ),
    );
    final text = child.paint();
    final measured = math.max(1, child.size.height.round());
    _childPaintCache[index] = _ChildPaintSnapshot(
      text: text,
      measured: measured,
      maxWidth: maxWidth,
    );
    child.clearPaintDirty();
    return (text: text, measured: measured);
  }

  int _resolveAdaptiveEstimate(int baseEstimate) {
    if (_measuredHeights.isEmpty) return baseEstimate;
    var measuredTotal = 0;
    for (final height in _measuredHeights.values) {
      measuredTotal += height;
    }
    final measuredAvg = (measuredTotal / _measuredHeights.length).round();
    final blended = ((baseEstimate * 2) + (measuredAvg * 3)) ~/ 5;
    return math.max(1, blended);
  }

  int _estimateHeight(int index, int estimate) {
    final measured = _measuredHeights[index];
    return measured ?? estimate;
  }

  int _estimatedContentHeight(
    int itemCount,
    int separatorBreaks,
    int estimate,
  ) {
    if (itemCount == 0) return 0;
    final cached = _cachedContentHeight;
    if (cached != null) return cached;
    var total = 0;
    for (var i = 0; i < itemCount; i++) {
      total += _estimateHeight(i, estimate);
      if (i < itemCount - 1) total += separatorBreaks;
    }
    _cachedContentHeight = total;
    return total;
  }

  List<int> _prefixHeights(int itemCount, int separatorBreaks, int estimate) {
    final cached = _cachedPrefix;
    if (cached != null && cached.length == itemCount + 1) {
      return cached;
    }
    final prefix = List<int>.filled(itemCount + 1, 0);
    var total = 0;
    for (var i = 0; i < itemCount; i++) {
      prefix[i] = total;
      total += _estimateHeight(i, estimate);
      if (i < itemCount - 1) total += separatorBreaks;
    }
    prefix[itemCount] = total;
    _cachedPrefix = prefix;
    return prefix;
  }

  int _findStartIndex(List<int> prefix, int offset) {
    var low = 0;
    var high = prefix.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (prefix[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low.clamp(0, prefix.length - 1);
  }

  int _offsetForAnchor({
    required int itemCount,
    required int separatorBreaks,
    required int estimate,
    required int anchorIndex,
    required int anchorOffsetInItem,
  }) {
    if (itemCount <= 0) return 0;
    final idx = anchorIndex.clamp(0, itemCount - 1);
    final prefix = _prefixHeights(itemCount, separatorBreaks, estimate);
    final itemHeight = _estimateHeight(idx, estimate);
    final stride = itemHeight + (idx < itemCount - 1 ? separatorBreaks : 0);
    final clampedInItem = stride <= 0
        ? 0
        : anchorOffsetInItem.clamp(0, stride - 1);
    return prefix[idx] + clampedInItem;
  }

  @override
  bool hitTest(
    HitTestResult result, {
    required double localX,
    required double localY,
  }) {
    if (localX < 0 ||
        localY < 0 ||
        localX >= size.width ||
        localY >= size.height) {
      return false;
    }

    if (children.isEmpty) return false;

    final separatorBreaks = _separatorBreaks(separator);
    final offset = controller.offset.clamp(0, controller.maxOffset);
    final contentY = localY + offset;

    if (!variableHeight) {
      final stride = math.max(1, itemExtent).toInt() + separatorBreaks;
      final index = stride > 0 ? (contentY ~/ stride).toInt() : 0;
      if (index < 0 || index >= children.length) return false;
      final childTop = (index * stride).toInt();
      final childBottom = childTop + math.max(1, itemExtent).toInt();
      if (contentY < childTop || contentY >= childBottom) return false;
      final child = children[index];
      final childX = localX - child.offset.dx;
      final childY = contentY - childTop - child.offset.dy;
      return child.hitTest(result, localX: childX, localY: childY);
    }

    if (_lastPaintOffset == offset &&
        _lastPaintViewportHeight == size.height.round() &&
        _lastVisibleHits.isNotEmpty) {
      final bufferY = localY.toInt() + _lastOffsetInItem;
      for (final hit in _lastVisibleHits) {
        if (bufferY >= hit.bufferStart && bufferY < hit.bufferEnd) {
          final child = children[hit.index];
          final childX = localX - child.offset.dx;
          final childY = bufferY - hit.bufferStart - child.offset.dy;
          return child.hitTest(result, localX: childX, localY: childY);
        }
      }
    }

    // Variable-height hit testing favors correctness over speed.
    // Walk rows in order using measured heights where available.
    final estimate = math.max(1, estimatedItemExtent ?? itemExtent).toInt();
    _syncCache(children.length, separatorBreaks, estimate);
    var top = 0;
    for (var i = 0; i < children.length; i++) {
      final childHeight = _estimateHeight(i, estimate);
      final bottom = top + childHeight;
      if (contentY >= top && contentY < bottom) {
        final child = children[i];
        final childX = localX - child.offset.dx;
        final childY = contentY - top - child.offset.dy;
        return child.hitTest(result, localX: childX, localY: childY);
      }

      top = bottom;
      if (i < children.length - 1) {
        final sepBottom = top + separatorBreaks;
        if (contentY >= top && contentY < sepBottom) return false;
        top = sepBottom;
      }
    }
    return false;
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    final maxWidth =
        width ??
        (constraints.hasBoundedWidth ? constraints.maxWidth.round() : 0);
    final boundedHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight.round()
        : null;
    final viewportHeight = height ?? boundedHeight;
    final separatorBreaks = _separatorBreaks(separator);
    final itemCount = children.length;
    if (variableHeight) {
      if (_lastMaxWidth != maxWidth) {
        _lastMaxWidth = maxWidth;
        _clearMeasurements();
      }
      final baseEstimate = math
          .max(1, estimatedItemExtent ?? itemExtent)
          .toInt();
      final estimate = _resolveAdaptiveEstimate(baseEstimate);
      _syncCache(itemCount, separatorBreaks, estimate);
      final contentHeight = _estimatedContentHeight(
        itemCount,
        separatorBreaks,
        estimate,
      );
      final layoutHeight = viewportHeight ?? contentHeight;
      _setMetrics(
        viewportExtent: layoutHeight.toInt(),
        contentExtent: contentHeight.toInt(),
      );
      size = constraints.constrain(
        Size(maxWidth.toDouble(), layoutHeight.toDouble()),
      );
      return;
    }

    final itemHeight = math.max(1, itemExtent).toInt();
    final contentHeight = itemCount == 0
        ? 0
        : itemCount * itemHeight + (itemCount - 1) * separatorBreaks;
    final layoutHeight = viewportHeight ?? contentHeight;

    _setMetrics(
      viewportExtent: layoutHeight.toInt(),
      contentExtent: contentHeight.toInt(),
    );

    size = constraints.constrain(
      Size(maxWidth.toDouble(), layoutHeight.toDouble()),
    );
  }

  @override
  String paint() {
    final maxWidth = size.width.round();
    final viewportHeight = size.height.round();
    final separatorBreaks = _separatorBreaks(separator);
    final itemCount = children.length;
    final hasSelection =
        controller is WidgetScrollController &&
        (controller as WidgetScrollController).hasSelection;
    if (itemCount == 0 || viewportHeight <= 0) {
      _invalidateVisiblePaintCache();
      _resetVisibleHitCache();
      _resetRepaintFlag();
      final manager = globalZone;
      final empty = '';
      return manager == null ? empty : manager.mark(zoneId, empty);
    }

    final offset = controller.offset.clamp(0, controller.maxOffset);
    if (!hasSelection &&
        _canUseVisiblePaintCache(
          offset: offset,
          viewportHeight: viewportHeight,
          maxWidth: maxWidth,
          itemCount: itemCount,
          separatorBreaks: separatorBreaks,
          isVariableHeight: variableHeight,
        )) {
      final cached = _cachedVisibleContent!;
      _resetRepaintFlag();
      final manager = globalZone;
      return manager == null ? cached : manager.mark(zoneId, cached);
    }

    if (variableHeight) {
      final baseEstimate = math
          .max(1, estimatedItemExtent ?? itemExtent)
          .toInt();
      final estimate = _resolveAdaptiveEstimate(baseEstimate);
      _syncCache(itemCount, separatorBreaks, estimate);
      ({
        String visible,
        bool heightsChanged,
        int anchorIndex,
        int anchorOffsetInItem,
      })
      buildVisibleForOffset(int target) {
        _resetVisibleHitCache();
        final prefix = _prefixHeights(itemCount, separatorBreaks, estimate);
        var startIndex = _findStartIndex(prefix, target).clamp(0, itemCount);
        var offsetInItem = target - prefix[startIndex];
        if (startIndex >= itemCount) {
          startIndex = itemCount - 1;
          offsetInItem = 0;
        }
        final requiredLines = offsetInItem + viewportHeight;

        final buffer = StringBuffer();
        var lineCount = 0;
        var measuredHeightsChanged = false;
        _lastPaintOffset = target;
        _lastPaintViewportHeight = viewportHeight;
        _lastOffsetInItem = offsetInItem;

        for (
          var i = startIndex;
          i < itemCount && lineCount < requiredLines;
          i++
        ) {
          final itemStart = lineCount;
          final resolved = _resolveChildPaint(index: i, maxWidth: maxWidth);
          final text = resolved.text;
          final measured = resolved.measured;
          if (_measuredHeights[i] != measured) {
            _measuredHeights[i] = measured;
            measuredHeightsChanged = true;
            _invalidateMeasurements();
          }
          buffer.write(text);
          lineCount += measured;
          final itemEnd = lineCount;
          if (itemEnd > offsetInItem && itemStart < requiredLines) {
            _lastVisibleHits.add(
              _VisibleItemHit(
                index: i,
                bufferStart: itemStart,
                bufferEnd: itemEnd,
              ),
            );
          }
          if (i < itemCount - 1 && separator.isNotEmpty) {
            buffer.write(separator);
            lineCount += separatorBreaks;
          }
        }

        final content = buffer.toString();
        return (
          visible: _sliceLines(content, offsetInItem, viewportHeight),
          heightsChanged: measuredHeightsChanged,
          anchorIndex: startIndex,
          anchorOffsetInItem: offsetInItem,
        );
      }

      var workingOffset = offset;
      var rendered = buildVisibleForOffset(workingOffset);

      if (rendered.heightsChanged) {
        _traceScroll(
          'virtual_list.measurements_changed '
          'zone=$zoneId items=$itemCount estimate=$estimate '
          'offset=$workingOffset max=${controller.maxOffset}',
        );
        final contentHeight = _estimatedContentHeight(
          itemCount,
          separatorBreaks,
          estimate,
        );
        _setContentExtent(contentHeight);

        // Stabilize viewport anchor when measured heights change: keep the
        // same first visible item and intra-item line, and move absolute
        // offset to match the new prefix sum. This prevents apparent jumps
        // backward/forward while estimates converge during scrolling.
        final anchorOffset = _offsetForAnchor(
          itemCount: itemCount,
          separatorBreaks: separatorBreaks,
          estimate: estimate,
          anchorIndex: rendered.anchorIndex,
          anchorOffsetInItem: rendered.anchorOffsetInItem,
        ).clamp(0, controller.maxOffset);
        final currentOffset = controller.offset.clamp(0, controller.maxOffset);
        final suppressAnchorAdjust =
            controller is WidgetScrollController &&
            (controller as WidgetScrollController).thumbDragActive;
        if (anchorOffset != currentOffset && !suppressAnchorAdjust) {
          _traceScroll(
            'virtual_list.anchor_adjust '
            'zone=$zoneId from=$currentOffset to=$anchorOffset '
            'anchorIndex=${rendered.anchorIndex} '
            'anchorInItem=${rendered.anchorOffsetInItem} '
            'contentHeight=$contentHeight max=${controller.maxOffset}',
          );
          controller.jumpTo(anchorOffset);
        } else if (anchorOffset != currentOffset && suppressAnchorAdjust) {
          _traceScroll(
            'virtual_list.anchor_skip '
            'zone=$zoneId from=$currentOffset target=$anchorOffset '
            'anchorIndex=${rendered.anchorIndex} '
            'anchorInItem=${rendered.anchorOffsetInItem} '
            'contentHeight=$contentHeight max=${controller.maxOffset}',
          );
        }

        final nextOffset = controller.offset.clamp(0, controller.maxOffset);
        if (nextOffset != workingOffset) {
          _traceScroll(
            'virtual_list.offset_resolved '
            'zone=$zoneId $workingOffset->$nextOffset max=${controller.maxOffset}',
          );
          _resetRepaintFlag();
          workingOffset = nextOffset;
          rendered = buildVisibleForOffset(workingOffset);
        }
      }

      _storeVisiblePaintCache(
        visible: _applySelectionIfNeeded(rendered.visible, workingOffset),
        offset: workingOffset,
        viewportHeight: viewportHeight,
        maxWidth: maxWidth,
        itemCount: itemCount,
        separatorBreaks: separatorBreaks,
        isVariableHeight: true,
      );

      _resetRepaintFlag();
      final manager = globalZone;
      return manager == null
          ? _cachedVisibleContent!
          : manager.mark(zoneId, _cachedVisibleContent!);
    }

    _resetVisibleHitCache();

    final itemHeight = math.max(1, itemExtent).toInt();
    final stride = itemHeight + separatorBreaks;
    final startIndex = stride > 0 ? offset ~/ stride : 0;
    final offsetInStride = stride > 0 ? offset % stride : 0;
    final requiredLines = offsetInStride + viewportHeight;

    final buffer = StringBuffer();
    var lineCount = 0;
    for (var i = startIndex; i < itemCount && lineCount < requiredLines; i++) {
      final resolved = _resolveChildPaint(index: i, maxWidth: maxWidth);
      final text = resolved.text;
      buffer.write(text);
      lineCount += resolved.measured;
      if (i < itemCount - 1 && separator.isNotEmpty) {
        buffer.write(separator);
        lineCount += separatorBreaks;
      }
    }

    final visible = _applySelectionIfNeeded(
      _sliceLines(buffer.toString(), offsetInStride, viewportHeight),
      offset,
    );
    _storeVisiblePaintCache(
      visible: visible,
      offset: offset,
      viewportHeight: viewportHeight,
      maxWidth: maxWidth,
      itemCount: itemCount,
      separatorBreaks: separatorBreaks,
      isVariableHeight: false,
    );
    _resetRepaintFlag();
    final manager = globalZone;
    return manager == null ? visible : manager.mark(zoneId, visible);
  }

  List<String> allContentLinesForSelection() {
    if (children.isEmpty) return const <String>[];
    final maxWidth = size.width.round();
    final buffer = StringBuffer();
    for (var i = 0; i < children.length; i++) {
      final resolved = _resolveChildPaint(index: i, maxWidth: maxWidth);
      buffer.write(resolved.text);
      if (i < children.length - 1 && separator.isNotEmpty) {
        buffer.write(separator);
      }
    }
    return buffer.toString().split('\n');
  }

  String _applySelectionIfNeeded(String visible, int offset) {
    final c = controller;
    if (c is! WidgetScrollController || !c.hasSelection) return visible;
    final lines = visible.split('\n');
    final highlighted = _applySelectionHighlighting(lines, offset, c);
    return highlighted.join('\n');
  }
}

class _VisibleItemHit {
  const _VisibleItemHit({
    required this.index,
    required this.bufferStart,
    required this.bufferEnd,
  });

  final int index;
  final int bufferStart;
  final int bufferEnd;
}

class _ChildPaintSnapshot {
  const _ChildPaintSnapshot({
    required this.text,
    required this.measured,
    required this.maxWidth,
  });

  final String text;
  final int measured;
  final int maxWidth;
}

int _separatorBreaks(String separator) {
  if (separator.isEmpty) return 0;
  var count = 0;
  for (var i = 0; i < separator.length; i++) {
    if (separator.codeUnitAt(i) == 0x0A) count++;
  }
  return count;
}

String _sliceLines(String text, int startLine, int maxLines) {
  if (text.isEmpty || maxLines <= 0) return '';

  var start = 0;
  var line = 0;
  while (line < startLine && start < text.length) {
    final nl = text.indexOf('\n', start);
    if (nl == -1) return '';
    start = nl + 1;
    line++;
  }

  var end = start;
  var taken = 0;
  while (taken < maxLines && end < text.length) {
    final nl = text.indexOf('\n', end);
    if (nl == -1) {
      end = text.length;
      taken++;
      break;
    }
    end = nl + 1;
    taken++;
  }

  if (taken <= 0) return '';
  var out = text.substring(start, end);
  if (out.endsWith('\n')) {
    out = out.substring(0, out.length - 1);
  }
  return out;
}

bool _isWheelEvent(MouseMsg msg) {
  return switch (msg.button) {
    MouseButton.wheelUp ||
    MouseButton.wheelDown ||
    MouseButton.wheelLeft ||
    MouseButton.wheelRight => true,
    _ => msg.action == MouseAction.wheel,
  };
}

/// Finds the word boundaries at position (x, y) in [lines].
///
/// Computes the global X offset of a render object by summing offsets
/// up the parent chain.
double _roGlobalX(RenderObject ro) {
  double x = 0;
  RenderObject? current = ro;
  while (current != null) {
    x += current.offset.dx;
    current = current.parent;
  }
  return x;
}

/// Computes the global Y offset of a render object by summing offsets
/// up the parent chain.
double _roGlobalY(RenderObject ro) {
  double y = 0;
  RenderObject? current = ro;
  while (current != null) {
    y += current.offset.dy;
    current = current.parent;
  }
  return y;
}

/// Returns `(startX, endX)` for the word at the given position.
/// Mirrors `ViewportModel._findWordAt`.
(int, int) _findWordAt(List<String> lines, int x, int y) {
  if (y < 0 || y >= lines.length) return (x, x);
  final line = Style.stripAnsi(lines[y]);
  if (x < 0 || x >= line.length) return (x, x);

  if (_isWhitespaceChar(line[x])) {
    var start = x;
    while (start > 0 && _isWhitespaceChar(line[start - 1])) {
      start--;
    }
    var end = x;
    while (end < line.length && _isWhitespaceChar(line[end])) {
      end++;
    }
    return (start, end);
  } else {
    var start = x;
    while (start > 0 && !_isWhitespaceChar(line[start - 1])) {
      start--;
    }
    var end = x;
    while (end < line.length && !_isWhitespaceChar(line[end])) {
      end++;
    }
    return (start, end);
  }
}

bool _isWhitespaceChar(String char) {
  return char == ' ' || char == '\t' || char == '\n' || char == '\r';
}

/// Selection highlight style: white background, black foreground.
final Style _selectionStyle = Style()
    .background(const AnsiColor(7))
    .foreground(const AnsiColor(0));

/// Applies selection highlighting to [lines] based on the controller's
/// selection state. [offset] is the content-line index of the first visible
/// line (i.e. the scroll offset).
///
/// Selection coordinates in [ctrl] are in content space (Y includes scroll).
/// This mirrors `ViewportModel._applySelection`.
List<String> _applySelectionHighlighting(
  List<String> lines,
  int offset,
  WidgetScrollController ctrl,
) {
  if (!ctrl.hasSelection) return lines;

  final s = ctrl.selectionStart!;
  final e = ctrl.selectionEnd!;

  final startY = math.min(s.y, e.y);
  final endY = math.max(s.y, e.y);

  // If the selection is entirely outside the visible range, return as-is.
  if (endY < offset) return lines;
  if (startY >= offset + lines.length) return lines;

  final result = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final lineIdx = i + offset;
    var line = lines[i];

    if (lineIdx < startY || lineIdx > endY) {
      result.add(line);
      continue;
    }

    final maxX = Style.visibleLength(line);

    int startX;
    int endX;

    if (startY == endY) {
      startX = math.min(s.x, e.x);
      endX = math.max(s.x, e.x);
    } else if (lineIdx == startY) {
      startX = s.y < e.y ? s.x : e.x;
      endX = maxX;
    } else if (lineIdx == endY) {
      startX = 0;
      endX = s.y < e.y ? e.x : s.x;
    } else {
      startX = 0;
      endX = maxX;
    }

    startX = startX.clamp(0, maxX);
    endX = endX.clamp(0, maxX);
    if (startX >= endX) {
      result.add(line);
      continue;
    }

    line = styleRanges(line, [StyleRange(startX, endX, _selectionStyle)]);
    result.add(line);
  }

  return result;
}

class _ViewportRender extends LeafRenderObjectWidget {
  _ViewportRender({
    required this.controller,
    required this.zoneId,
    required this.width,
    required this.height,
    required this.showScrollbar,
    required this.scrollbarSeparator,
    required this.scrollbarChars,
  });

  final ViewportController controller;
  final String zoneId;
  final int? width;
  final int? height;
  final bool showScrollbar;
  final String scrollbarSeparator;
  final ScrollbarChars scrollbarChars;

  @override
  RenderObject createRenderObject() {
    return RenderViewport(
      controller: controller,
      zoneId: zoneId,
      width: width,
      height: height,
      showScrollbar: showScrollbar,
      scrollbarSeparator: scrollbarSeparator,
      scrollbarChars: scrollbarChars,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final viewport = renderObject as RenderViewport;
    viewport
      ..controller = controller
      ..zoneId = zoneId
      ..width = width
      ..height = height
      ..showScrollbar = showScrollbar
      ..scrollbarSeparator = scrollbarSeparator
      ..scrollbarChars = scrollbarChars;
  }

  @override
  Object view() {
    return _renderViewportString(
      controller: controller,
      zoneId: zoneId,
      showScrollbar: showScrollbar,
      scrollbarSeparator: scrollbarSeparator,
      scrollbarChars: scrollbarChars,
    );
  }
}

/// Render object backing [Viewport].
class RenderViewport extends RenderBox {
  RenderViewport({
    required this.controller,
    required this.zoneId,
    required this.width,
    required this.height,
    required this.showScrollbar,
    required this.scrollbarSeparator,
    required this.scrollbarChars,
  });

  ViewportController controller;
  String zoneId;
  int? width;
  int? height;
  bool showScrollbar;
  String scrollbarSeparator;
  ScrollbarChars scrollbarChars;

  bool _effectiveScrollbar = false;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    final maxWidth =
        width ??
        (constraints.hasBoundedWidth
            ? constraints.maxWidth.round()
            : controller.model.width);
    final boundedHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight.round()
        : null;
    final viewportHeight = height ?? boundedHeight;
    final layoutHeight =
        viewportHeight ??
        controller.model.height ??
        controller.model.lines.length;

    var contentWidth = math.max(0, maxWidth);
    var totalWidth = contentWidth;
    _effectiveScrollbar =
        showScrollbar && maxWidth > scrollbarSeparator.length + 1;
    if (_effectiveScrollbar) {
      contentWidth = math.max(1, maxWidth - scrollbarSeparator.length - 1);
      totalWidth = contentWidth + scrollbarSeparator.length + 1;
    }

    controller.setSize(contentWidth, viewportHeight);

    size = constraints.constrain(
      Size(totalWidth.toDouble(), layoutHeight.toDouble()),
    );
  }

  @override
  String paint() {
    return _renderViewportString(
      controller: controller,
      zoneId: zoneId,
      showScrollbar: _effectiveScrollbar,
      scrollbarSeparator: scrollbarSeparator,
      scrollbarChars: scrollbarChars,
    );
  }
}

String _renderViewportString({
  required ViewportController controller,
  required String zoneId,
  required bool showScrollbar,
  required String scrollbarSeparator,
  required ScrollbarChars scrollbarChars,
}) {
  final Stopwatch? sw = TuiTrace.enabled ? Stopwatch() : null;
  sw?.start();
  String content;
  if (showScrollbar) {
    final pane = controller.scrollPane(
      separator: scrollbarSeparator,
      chars: scrollbarChars,
    );
    pane.originX = 0;
    pane.originY = 0;
    content = pane.view();
  } else {
    content = controller.model.view();
  }

  final manager = globalZone;
  final result = manager == null ? content : manager.mark(zoneId, content);
  if (sw != null) {
    sw.stop();
    TuiTrace.log(
      'viewport.render zone=$zoneId scrollbar=$showScrollbar '
      'len=${result.length} ${sw.elapsedMicroseconds}us',
    );
  }
  return result;
}

String _renderWidget(Widget widget) {
  final element = elementOf(widget);
  if (element != null) return element.render();
  final view = widget.view();
  return view is String ? view : view.toString();
}
