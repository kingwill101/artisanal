import 'dart:math' as math;

import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color;
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/core/element.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/rendering/render_object.dart';
import 'package:artisanal_widgets/src/widgets/layout_widgets.dart';
import 'package:artisanal_widgets/src/widgets/scroll_widgets.dart'
    show ScrollController, WidgetScrollController, SingleChildScrollView;
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal/bubbles.dart'
    show
        DiffCommentAnchor,
        DiffCommentLineHighlight,
        DiffCommentSide,
        DiffFile,
        DiffStyles,
        DiffViewMode,
        GitDiffModel;

import 'package:artisanal_widgets/src/widgets/gestures/events.dart';
import 'package:artisanal_widgets/src/widgets/gestures/hit_testing.dart';
import 'package:artisanal_widgets/src/widgets/theme/theme.dart';

/// A comment block to render inline in a [GitDiffViewer] at a specific
/// [renderLine] position. The [child] widget is rendered as an additional row
/// between diff lines, and [height] tells the viewer how many terminal rows
/// it occupies so scroll metrics stay correct.
class DiffCommentBlock {
  /// Creates a diff comment block.
  const DiffCommentBlock({
    required this.renderLine,
    required this.child,
    required this.height,
    this.side,
  });

  /// The 0-based render line of the diff line above which this block is
  /// positioned.
  final int renderLine;

  /// The widget to render inline.
  final Widget child;

  /// How many terminal rows this block occupies.
  final int height;

  /// Which diff side this comment belongs to (addition/removal). Used to align
  /// the block under the correct column in side-by-side view.
  final DiffCommentSide? side;
}

/// A single-child render object widget that measures its child's real
/// post-layout height and reports it (once per layout) via [onHeight].
///
/// Unlike a build-time measurement, this probes the child in the real layout
/// pass, so asynchronous content (e.g. loaded images) contributes to the
/// measured height. The reported height is in terminal rows (rounded).
class _CardHeightProbe extends SingleChildRenderObjectWidget {
  _CardHeightProbe({
    required this.renderLine,
    required this.onHeight,
    required super.child,
  });

  /// The [DiffCommentBlock.renderLine] the measured child belongs to.
  final int renderLine;

  /// Called with the child's measured height in rows after each layout.
  final void Function(int renderLine, int height) onHeight;

  @override
  RenderObject createRenderObject() =>
      _RenderCardHeightProbe((height) => onHeight(renderLine, height));

  @override
  Object view() => child?.view() ?? '';
}

/// Render object for [_CardHeightProbe].
///
/// Lays the child out with unconstrained height and reports its rendered
/// height back to the parent so scroll metrics can be corrected.
class _RenderCardHeightProbe extends RenderBox {
  _RenderCardHeightProbe(this._onHeight);

  final void Function(int height) _onHeight;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    if (children.isEmpty) return;

    final child = children.first;
    final childConstraints = BoxConstraints(
      minWidth: constraints.hasBoundedWidth
          ? constraints.maxWidth
          : constraints.minWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0,
      maxHeight: double.infinity,
    );
    child.layout(childConstraints);

    size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : child.size.width,
        constraints.maxHeight,
      ),
    );

    _onHeight(child.size.height.toInt());
  }

  @override
  String paint() {
    if (children.isEmpty) return '';
    return children.first.paint();
  }
}

/// Controller for [GitDiffViewer].
///
/// Holds a [GitDiffModel] and delegates updates to it. Provides methods for
/// setting diff content and configuring the display.
class GitDiffController {
  /// Creates a controller with an optional initial model.
  GitDiffController({GitDiffModel? initial})
    : _model = initial ?? GitDiffModel(width: 80, height: 24);

  GitDiffModel _model;
  final Set<void Function()> _listeners = <void Function()>{};

  /// The current diff model state.
  GitDiffModel get model => _model;

  /// The parsed diff files.
  List<DiffFile> get files => _model.files;

  /// Total additions across all files.
  int get totalAdditions => _model.totalAdditions;

  /// Total deletions across all files.
  int get totalDeletions => _model.totalDeletions;

  /// Current scroll percentage.
  double get scrollPercent => _model.viewport.scrollPercent;

  /// Current vertical scroll offset.
  int get scrollOffset => _model.viewport.yOffset;

  /// Total rendered line count.
  int get totalLineCount => _model.viewport.totalLineCount;

  /// Commentable anchors in the currently rendered diff.
  List<DiffCommentAnchor> get commentAnchors => _model.commentAnchors;

  /// Comment line highlights in the current model.
  List<DiffCommentLineHighlight> get commentHighlights =>
      _model.commentHighlights;

  /// The full list of rendered diff lines (before viewport clipping).
  List<String> get renderedLines => _model.renderedLines;

  /// Returns the nearest comment anchor at or after [renderLine].
  DiffCommentAnchor? nearestCommentAnchor(int renderLine) {
    return _model.nearestCommentAnchor(renderLine);
  }

  /// Returns the comment anchor occupying [renderLine].
  DiffCommentAnchor? commentAnchorAt(int renderLine, {DiffCommentSide? side}) {
    return _model.commentAnchorAt(renderLine, side: side);
  }

  /// Returns the index of the comment anchor occupying [renderLine].
  int? commentAnchorIndexAt(int renderLine, {DiffCommentSide? side}) {
    return _model.commentAnchorIndexAt(renderLine, side: side);
  }

  /// Sets the raw unified diff text.
  void setDiff(String rawDiff) {
    _model = _model.setDiff(rawDiff);
    _notifyListeners();
  }

  /// Updates the viewport size.
  void setSize(int width, int height) {
    if (_model.width == width && _model.height == height) return;
    final widthChanged = _model.width != width;
    _model = _model.copyWith(
      width: width,
      height: height,
      viewport: _model.viewport.copyWith(width: width, height: height),
    );
    if (widthChanged) {
      // Re-render lines for new dimensions that affect diff composition.
      _model = _model.rerender();
    }
    _notifyListeners();
  }

  /// Sets the viewport scroll offset.
  void setScrollOffset(int offset) {
    final viewport = _model.viewport.setYOffset(offset);
    if (viewport.yOffset == _model.viewport.yOffset) return;
    _model = _model.copyWith(viewport: viewport);
    _notifyListeners();
  }

  /// Configures display options.
  ///
  /// When rendering-relevant options change (viewMode, showLineNumbers,
  /// wrapLines, zeroPadLineNumbers, styles), the diff lines are re-rendered
  /// automatically.
  void configure({
    bool? showLineNumbers,
    bool? wrapLines,
    bool? zeroPadLineNumbers,
    DiffViewMode? viewMode,
    DiffStyles? styles,
    List<DiffCommentLineHighlight>? commentHighlights,
  }) {
    if (TuiTrace.enabled) {
      TuiTrace.event(
        'git_diff.configure',
        tag: TraceTag.general,
        fields: <String, Object?>{
          'showLineNumbers': showLineNumbers,
          'wrapLines': wrapLines,
          'zeroPadLineNumbers': zeroPadLineNumbers,
          'viewMode': viewMode?.name,
          'stylesChanged': styles != null,
          'commentHighlights': commentHighlights?.length,
        },
      );
    }

    final needsRerender =
        (viewMode != null && viewMode != _model.viewMode) ||
        (showLineNumbers != null &&
            showLineNumbers != _model.showLineNumbers) ||
        (wrapLines != null && wrapLines != _model.wrapLines) ||
        (zeroPadLineNumbers != null &&
            zeroPadLineNumbers != _model.zeroPadLineNumbers) ||
        (styles != null && styles != _model.styles) ||
        (commentHighlights != null &&
            !_sameCommentHighlights(
              commentHighlights,
              _model.commentHighlights,
            ));

    if (!needsRerender) return;

    _model = _model.copyWith(
      showLineNumbers: showLineNumbers,
      wrapLines: wrapLines,
      zeroPadLineNumbers: zeroPadLineNumbers,
      viewMode: viewMode,
      styles: styles,
      commentHighlights: commentHighlights,
    );

    _model = _model.rerender();
    _notifyListeners();
  }

  /// Forwards a message to the underlying model.
  (GitDiffModel, Cmd?) update(Msg msg) {
    final prev = _model;
    final (next, cmd) = _model.update(msg);
    _model = next;
    if (!identical(prev, next)) {
      _notifyListeners();
    }
    return (next, cmd);
  }

  /// Adds a listener for state changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  bool _sameCommentHighlights(
    List<DiffCommentLineHighlight> left,
    List<DiffCommentLineHighlight> right,
  ) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      final l = left[index];
      final r = right[index];
      if (l.key != r.key || l.kind != r.kind) return false;
    }
    return true;
  }
}

/// A widget for viewing git diffs with syntax highlighting and scrolling.
///
/// Wraps [GitDiffModel] (a TUI bubble) in the widget system. Supports
/// unified diff format with colored additions/deletions, line numbers, and
/// keyboard/mouse scrolling.
///
/// ## Example
///
/// ```dart
/// class MyApp extends StatefulWidget {
///   @override
///   State createState() => _MyAppState();
/// }
///
/// class _MyAppState extends State<MyApp> {
///   final _controller = GitDiffController();
///
///   @override
///   void initState() {
///     super.initState();
///     _controller.setDiff(rawDiffString);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return GitDiffViewer(
///       diff: rawDiffString,
///       width: 80,
///       height: 24,
///       controller: _controller,
///     );
///   }
/// }
/// ```
class GitDiffViewer extends StatefulWidget {
  /// Creates a git diff viewer widget.
  GitDiffViewer({
    required this.diff,
    this.width,
    this.height,
    this.showLineNumbers = true,
    this.wrapLines = true,
    this.zeroPadLineNumbers = false,
    this.viewMode,
    this.styles,
    this.controller,
    this.scrollController,
    this.handleKeys = true,
    this.scrollable = true,
    this.fitContentHeight = false,
    this.commentHighlights = const <DiffCommentLineHighlight>[],
    this.commentBlocks = const [],
    this.onCommentAnchorSelected,
    super.key,
  });

  /// The raw unified diff text to display.
  final String diff;

  /// Width of the viewer in columns. Defaults to available width.
  final int? width;

  /// Height of the viewer in rows. Defaults to available height.
  final int? height;

  /// Whether to show line numbers in the gutter.
  final bool showLineNumbers;

  /// Whether to wrap long lines that exceed the viewport width.
  final bool wrapLines;

  /// Whether to zero-pad line numbers (e.g. `0001`) instead of space-padding
  /// (e.g. `   1`).
  final bool zeroPadLineNumbers;

  /// Display mode (unified, side-by-side, or pretty).
  ///
  /// When non-null, forces this mode on every rebuild — keyboard cycling
  /// (`v` key) will be overridden. When `null` (the default), the model's
  /// current view mode is preserved, allowing interactive cycling.
  final DiffViewMode? viewMode;

  /// Custom diff styling.
  final DiffStyles? styles;

  /// Optional controller for external access to the diff model.
  final GitDiffController? controller;

  /// Optional external scroll controller.
  ///
  /// When supplied, this controller owns the vertical scroll offset so parent
  /// layouts can drive the diff viewer without forcing full-content rendering.
  final ScrollController? scrollController;

  /// Inline comment blocks rendered as widgets between diff lines. When empty,
  /// the viewer renders the diff as a plain text proxy. When non-empty, the
  /// viewer composes a scrollable column of diff lines interleaved with these
  /// rich comment widgets.
  final List<DiffCommentBlock> commentBlocks;

  /// Whether to handle keyboard input for scrolling.
  final bool handleKeys;

  /// Whether this viewer should process scrolling input.
  ///
  /// When `false`, keyboard and mouse scroll messages are ignored so the
  /// parent scroll container handles scrolling instead.
  final bool scrollable;

  /// Whether to auto-size height to rendered content line count.
  ///
  /// Useful when embedding the viewer inside a parent scroll container and
  /// wanting no internal blank fill area.
  final bool fitContentHeight;

  /// Visual highlights for selected/ranged/threaded diff comment lines.
  final List<DiffCommentLineHighlight> commentHighlights;

  /// Called when a commentable diff line is selected with the mouse.
  final Cmd? Function(DiffCommentAnchor anchor)? onCommentAnchorSelected;

  @override
  State createState() => _GitDiffViewerState();
}

class _GitDiffViewerState extends State<GitDiffViewer> {
  late GitDiffController _controller;
  bool _controllerAttached = false;
  ScrollController? _scrollController;
  bool _scrollControllerAttached = false;
  String _lastDiff = '';
  Theme? _cachedTheme;
  bool? _cachedHasDarkBackground;
  DiffStyles? _cachedThemeStyles;

  /// Maps a composed content row (diff line or comment-card row) back to the
  /// underlying diff render-line index. Built during [build] when comment
  /// blocks are present so tap handling can resolve the clicked row to a
  /// commentable anchor.
  Map<int, int> _rowToRenderedLine = const {};

  /// Inverse of [_rowToRenderedLine]: maps a diff render-line to the composed
  /// content row where that diff line starts. Used to translate the external
  /// scroll controller (render-line space, owned by the parent/dashboard) into
  /// the inner SingleChildScrollView's content-row space.
  Map<int, int> _renderLineToContentRow = const {};

  /// Internal scroll controller owning the SingleChildScrollView's content-row
  /// space. Kept separate from [widget.scrollController] (render-line space) so
  /// the two coordinate systems never diverge by the comment-block heights.
  WidgetScrollController? _commentScrollController;

  /// Guards the two-way sync between the external and internal scroll
  /// controllers against feedback loops.
  bool _syncingScroll = false;

  bool get _hasCommentBlocks => widget.commentBlocks.isNotEmpty;

  int get _totalCommentBlockHeight => _measuredCommentHeightTotal > 0
      ? _measuredCommentHeightTotal
      : widget.commentBlocks.fold(0, (sum, b) => sum + b.height);

  /// Real total height (in content rows) of all comment cards, sourced from the
  /// actual layout via [_CardHeightProbe] (which reports each card's true
  /// rendered height, including async `Image` galleries). Until the first layout
  /// reports, this is 0 and [_totalCommentBlockHeight] falls back to the estimate
  /// sum — never worse than the pre-measurement behavior.
  int _measuredCommentHeightTotal = 0;

  /// True rendered heights (rows) of comment cards, reported by [_CardHeightProbe]
  /// after the real layout runs. Keyed by the card's anchor render-line. Using
  /// the real layout (instead of a build-time snapshot) is what keeps the
  /// row→render-line map aligned with what is actually on screen, even when cards
  /// contain async content (e.g. `NetworkImage` galleries) that is absent from a
  /// build-time measurement.
  Map<int, int> _realCardHeights = const {};

  /// Guards the deferred relayout triggered when a probe reports a new height, so
  /// we schedule at most one `setState` per change.
  bool _relayoutScheduled = false;

  /// Records a card's real rendered [height] (rows) for [renderLine] and, if it
  /// differs from what the map currently uses, schedules a single rebuild so the
  /// row→render-line map picks up the corrected height. Deferred via a microtask
  /// to avoid calling `setState` during the layout phase.
  void _reportCardHeight(int renderLine, int height) {
    if (_realCardHeights[renderLine] == height) return;
    _realCardHeights = {..._realCardHeights, renderLine: height};
    _scheduleRelayout();
  }

  void _scheduleRelayout() {
    if (_relayoutScheduled) return;
    _relayoutScheduled = true;
    Future.microtask(() {
      _relayoutScheduled = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _attachScrollController(widget.scrollController);
    _commentScrollController = WidgetScrollController();
    _commentScrollController!.addListener(_onCommentScrollChanged);
    _syncController();
  }

  @override
  Cmd? didUpdateWidget(covariant GitDiffViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _attachController(widget.controller);
    }
    if (widget.scrollController != oldWidget.scrollController) {
      _attachScrollController(widget.scrollController);
    }
    _syncController();
    if (_hasCommentBlocks) _syncCommentScrollFromExternal();
    _updateThemeStyles();
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateThemeStyles();
  }

  void _attachController(GitDiffController? controller) {
    if (_controllerAttached) {
      _controller.removeListener(_onChanged);
    }
    _controller = controller ?? GitDiffController();
    _controller.addListener(_onChanged);
    _controllerAttached = true;
  }

  void _attachScrollController(ScrollController? controller) {
    if (_scrollControllerAttached) {
      _scrollController?.removeListener(_onExternalScrollChanged);
    }
    _scrollController = controller;
    if (controller != null) {
      controller.addListener(_onExternalScrollChanged);
      _scrollControllerAttached = true;
    } else {
      _scrollControllerAttached = false;
    }
  }

  void _updateThemeStyles() {
    final theme = ThemeScope.of(context);
    final terminalHasDarkBackground = hasDarkBackground;
    final needsThemeStylesUpdate = widget.styles == null
        ? !identical(theme, _cachedTheme) ||
              _cachedHasDarkBackground != terminalHasDarkBackground
        : _cachedThemeStyles != widget.styles ||
              _cachedHasDarkBackground != terminalHasDarkBackground;

    if (!needsThemeStylesUpdate) return;

    _cachedTheme = theme;
    _cachedHasDarkBackground = terminalHasDarkBackground;
    _cachedThemeStyles =
        widget.styles ??
        DiffStyles.fromColors(
          success: theme.gitDiffTheme?.addedBackground ?? theme.success,
          error: theme.gitDiffTheme?.removedBackground ?? theme.error,
          muted: theme.gitDiffTheme?.contextForeground ?? theme.muted,
          surface: theme.surface,
          onSurface: theme.gitDiffTheme?.addedForeground ?? theme.onSurface,
          onBackground:
              theme.gitDiffTheme?.headerForeground ?? theme.onBackground,
          border: theme.border,
        ).withHasDarkBackground(terminalHasDarkBackground);

    final gdTheme = theme.gitDiffTheme;
    if (gdTheme != null) {
      Style bgStyle(Color color) {
        return Style()
          ..hasDarkBackground = terminalHasDarkBackground
          ..background(color);
      }

      final overrides = <String, Style>{};
      if (gdTheme.selectedCommentLineBackground != null) {
        overrides['selectedCommentLine'] = bgStyle(
          gdTheme.selectedCommentLineBackground!,
        );
      }
      if (gdTheme.selectedCommentGutterBackground != null) {
        overrides['selectedCommentGutter'] = bgStyle(
          gdTheme.selectedCommentGutterBackground!,
        );
      }
      if (gdTheme.commentRangeLineBackground != null) {
        overrides['commentRangeLine'] = bgStyle(
          gdTheme.commentRangeLineBackground!,
        );
      }
      if (gdTheme.commentRangeGutterBackground != null) {
        overrides['commentRangeGutter'] = bgStyle(
          gdTheme.commentRangeGutterBackground!,
        );
      }
      if (gdTheme.commentThreadLineBackground != null) {
        overrides['commentThreadLine'] = bgStyle(
          gdTheme.commentThreadLineBackground!,
        );
      }
      if (gdTheme.commentThreadGutterBackground != null) {
        overrides['commentThreadGutter'] = bgStyle(
          gdTheme.commentThreadGutterBackground!,
        );
      }
      if (overrides.isNotEmpty) {
        _cachedThemeStyles = _cachedThemeStyles!.copyWith(
          selectedCommentLine: overrides['selectedCommentLine'],
          selectedCommentGutter: overrides['selectedCommentGutter'],
          commentRangeLine: overrides['commentRangeLine'],
          commentRangeGutter: overrides['commentRangeGutter'],
          commentThreadLine: overrides['commentThreadLine'],
          commentThreadGutter: overrides['commentThreadGutter'],
        );
      }
    }
    _controller.configure(styles: _cachedThemeStyles);
  }

  @override
  void dispose() {
    if (_controllerAttached) {
      _controller.removeListener(_onChanged);
    }
    if (_scrollControllerAttached) {
      _scrollController?.removeListener(_onExternalScrollChanged);
    }
    _commentScrollController?.removeListener(_onCommentScrollChanged);
    super.dispose();
  }

  void _syncController() {
    _controller.configure(
      showLineNumbers: widget.showLineNumbers,
      wrapLines: widget.wrapLines,
      zeroPadLineNumbers: widget.zeroPadLineNumbers,
      viewMode: widget.viewMode, // null = don't override model's current mode
      styles: widget.styles,
      commentHighlights: widget.commentHighlights,
    );
    if (widget.width != null || widget.height != null) {
      _controller.setSize(
        widget.width ?? _controller.model.width,
        widget.height ?? _controller.model.height,
      );
    }
    if (widget.diff != _lastDiff) {
      _lastDiff = widget.diff;
      _controller.setDiff(widget.diff);
    }

    if (widget.fitContentHeight && widget.height == null) {
      final targetHeight = math.max(
        1,
        _controller.model.viewport.totalLineCount,
      );
      if (_controller.model.height != targetHeight) {
        _controller.setSize(
          widget.width ?? _controller.model.width,
          targetHeight,
        );
      }
    }

    _syncExternalScrollController();
  }

  void _onChanged() {
    _syncExternalScrollMetrics();
    if (_hasCommentBlocks) _syncCommentScrollFromExternal();
    setState(() {});
  }

  void _onExternalScrollChanged() {
    _syncExternalScrollController();
    if (_hasCommentBlocks) _syncCommentScrollFromExternal();
    setState(() {});
  }

  void _syncExternalScrollController() {
    final scroll = _scrollController;
    if (scroll == null) return;
    _syncExternalScrollMetrics();
    // When comment blocks are present the viewer composes its own scrollable
    // content (diff lines + widget cards) and the external scroll controller
    // drives that directly; the model's viewport is not used for display, so
    // we must not push the offset back into the model (it would just move an
    // unused viewport).
    if (_hasCommentBlocks) return;
    final offset = scroll.offset;
    if (TuiTrace.enabled && TuiTrace.isTagEnabled(TraceTag.scroll)) {
      TuiTrace.event(
        'git_diff.sync_scroll_to_model',
        tag: TraceTag.scroll,
        fields: <String, Object?>{'scrollOffset': offset},
      );
    }
    _controller.setScrollOffset(offset);
  }

  void _syncExternalScrollMetrics() {
    final external = _scrollController;
    if (external is! WidgetScrollController) return;
    // The external controller stays in render-line space (owned by the
    // parent/dashboard), so its extent is just the model's line count. This
    // keeps keyboard navigation / reveal math consistent with anchor
    // render-lines and lets it scroll past comment blocks.
    final totalLineCount = _controller.model.viewport.totalLineCount;
    external.updateMetrics(
      viewportExtent: _controller.model.height,
      contentExtent: totalLineCount,
    );
    // The internal controller owns the composed content (diff lines + comment
    // cards), so its extent includes the comment-block heights.
    final internal = _commentScrollController;
    if (internal != null) {
      internal.updateMetrics(
        viewportExtent: _controller.model.height,
        contentExtent: totalLineCount + _totalCommentBlockHeight,
      );
    }
  }

  /// Translates the external scroll controller (render-line space) into the
  /// internal SingleChildScrollView controller (content-row space).
  void _syncCommentScrollFromExternal() {
    final external = _scrollController;
    final internal = _commentScrollController;
    if (external == null || internal == null) return;
    final target = _contentRowForRenderLine(external.offset);
    if (_syncingScroll) return;
    _syncingScroll = true;
    try {
      if (internal.offset != target) internal.jumpTo(target);
    } finally {
      _syncingScroll = false;
    }
  }

  /// Translates wheel/scroll on the internal SingleChildScrollView back into
  /// the external controller's render-line space.
  void _onCommentScrollChanged() {
    final external = _scrollController;
    final internal = _commentScrollController;
    if (external == null || internal == null || !_hasCommentBlocks) return;
    final target = _renderLineForContentRow(internal.offset);
    if (_syncingScroll) return;
    _syncingScroll = true;
    try {
      if (external.offset != target) external.jumpTo(target);
    } finally {
      _syncingScroll = false;
    }
  }

  int _contentRowForRenderLine(int renderLine) {
    if (_renderLineToContentRow.isEmpty) return renderLine;
    final row = _renderLineToContentRow[renderLine];
    if (row != null) return row;
    final keys = _renderLineToContentRow.keys;
    if (renderLine < keys.reduce(math.min)) return 0;
    final maxKey = keys.reduce(math.max);
    return _renderLineToContentRow[maxKey]! + (renderLine - maxKey);
  }

  int _renderLineForContentRow(int contentRow) {
    final rl = _rowToRenderedLine[contentRow];
    if (rl != null) return rl;
    final keys = _rowToRenderedLine.keys;
    if (keys.isEmpty) return contentRow;
    if (contentRow < keys.reduce(math.min)) return 0;
    final maxKey = keys.reduce(math.max);
    if (contentRow > maxKey) {
      return _rowToRenderedLine[maxKey]! + (contentRow - maxKey);
    }
    return contentRow;
  }

  void _syncExternalOffsetFromModel() {
    final scroll = _scrollController;
    if (scroll == null) return;
    _syncExternalScrollMetrics();
    final offset = _controller.scrollOffset;
    if (TuiTrace.enabled && TuiTrace.isTagEnabled(TraceTag.scroll)) {
      TuiTrace.event(
        'git_diff.sync_offset_from_model',
        tag: TraceTag.scroll,
        fields: <String, Object?>{
          'modelScrollOffset': offset,
          'scrollOffsetBefore': scroll.offset,
          'jumpTo': scroll.offset != offset,
        },
      );
    }
    if (scroll.offset != offset) {
      scroll.jumpTo(offset);
    }
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (_hasCommentBlocks) {
      // When comment blocks are present the diff is rendered as a
      // SingleChildScrollView child. The framework forwards the message to
      // that child first, so it handles wheel/key scrolling on its own. We
      // only need taps to reach the GestureDetector wrapping it, which also
      // happens via child dispatch — so we stay out of the way here.
      return null;
    }
    if (!widget.scrollable &&
        (msg is KeyMsg || msg is MouseMsg || msg is HitTestMouseMsg)) {
      return null;
    }
    if (!widget.handleKeys && msg is KeyMsg) return null;

    if (msg is HitTestMouseMsg) {
      if (!_isWheelEvent(msg.event)) return null;
      return _updateController(
        msg.event.copyWith(x: msg.localX.toInt(), y: msg.localY.toInt()),
      );
    }

    return _updateController(msg);
  }

  Cmd? _updateController(Msg msg) {
    final prev = _controller.model;
    final (next, cmd) = _controller.update(msg);
    if (!identical(prev, next)) {
      _syncExternalOffsetFromModel();
      setState(() {});
    }
    return cmd;
  }

  bool _isWheelEvent(MouseMsg msg) {
    return msg.action == MouseAction.wheel ||
        msg.button == MouseButton.wheelUp ||
        msg.button == MouseButton.wheelDown ||
        msg.button == MouseButton.wheelLeft ||
        msg.button == MouseButton.wheelRight;
  }

  @override
  Widget build(BuildContext context) {
    if (TuiTrace.enabled) {
      TuiTrace.event(
        'git_diff.build',
        tag: TraceTag.general,
        fields: <String, Object?>{
          'hasCustomStyles': widget.styles != null,
          'hasController': widget.controller != null,
          'hasDarkBackground': hasDarkBackground,
          'width': widget.width,
          'height': widget.height,
        },
      );
    }

    // Derive styles from the theme when no custom styles are provided.
    // Cache the derived DiffStyles so we only re-render when the theme
    // actually changes, not on every frame.
    _updateThemeStyles();
    final model = _controller.model;
    if (TuiTrace.enabled) {
      TuiTrace.event(
        'git_diff.model_view',
        tag: TraceTag.general,
        fields: <String, Object?>{
          'files': model.files.length,
          'lineCount': model.viewport.totalLineCount,
          'viewMode': model.viewMode.name,
          'wrapLines': model.wrapLines,
        },
      );
    }

    final text = Text(model.view(), softWrap: false);
    if (!_hasCommentBlocks && widget.onCommentAnchorSelected == null) {
      return text;
    }

    if (_hasCommentBlocks) {
      // Compose a scrollable column of diff lines interleaved with rich
      // comment widgets. The SingleChildScrollView owns vertical scrolling via
      // its own internal controller (content-row space); the external scroll
      // controller (render-line space) is kept in sync via [_syncCommentScrollFromExternal].
      // The GestureDetector captures taps so we can resolve the clicked row to
      // a commentable anchor.
      final content = _buildContent();
      _syncCommentScrollFromExternal();
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        child: SingleChildScrollView(
          controller: _commentScrollController,
          child: content,
        ),
      );
    }

    // No comment blocks, but tap-to-select is enabled: wrap the plain text.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      child: text,
    );
  }

  /// Builds the composed content column: one [Text] per diff render-line, with
  /// comment cards inserted directly after the diff line they are anchored to.
  ///
  /// Also records [_rowToRenderedLine] so tap handling can map a clicked
  /// content row back to the underlying diff render-line.
  Widget _buildContent() {
    final model = _controller.model;
    final renderedLines = model.renderedLines;
    final children = <Widget>[];
    final rowToRendered = <int, int>{};
    final renderLineToContent = <int, int>{};

    final sorted = [...widget.commentBlocks]
      ..sort((a, b) => a.renderLine.compareTo(b.renderLine));
    var blockIdx = 0;
    var row = 0;
    var measuredTotal = 0;

    for (var i = 0; i < renderedLines.length; i++) {
      renderLineToContent[i] = row;
      children.add(Text(renderedLines[i], softWrap: false));
      rowToRendered[row] = i;
      row++;

      while (blockIdx < sorted.length && sorted[blockIdx].renderLine == i) {
        final block = sorted[blockIdx];
        // Use the most recently measured real height (from [_CardHeightProbe])
        // so async content such as loaded images is accounted for. Fall back to
        // the estimate before the first real measurement arrives.
        final cardRows = _realCardHeights[block.renderLine] ?? block.height;
        measuredTotal += cardRows;
        children.add(
          _CardHeightProbe(
            renderLine: block.renderLine,
            onHeight: _reportCardHeight,
            child: _positionedComment(block, model),
          ),
        );
        for (var h = 0; h < cardRows; h++) {
          rowToRendered[row] = i;
          row++;
        }
        blockIdx++;
      }
    }

    _measuredCommentHeightTotal = measuredTotal;

    _rowToRenderedLine = rowToRendered;
    _renderLineToContentRow = renderLineToContent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Wraps a comment [block]'s child so it aligns under the correct side in
  /// side-by-side view. In unified view the card spans the full width.
  Widget _positionedComment(DiffCommentBlock block, GitDiffModel model) {
    if (model.viewMode != DiffViewMode.sideBySide || block.side == null) {
      return block.child;
    }
    // In side-by-side each panel is half the content width. Pad the card to
    // sit under the panel matching its side.
    final half = (model.width / 2).ceil();
    if (block.side == DiffCommentSide.right) {
      return Padding(
        padding: EdgeInsets.only(left: half),
        child: block.child,
      );
    }
    return Padding(
      padding: EdgeInsets.only(right: half),
      child: block.child,
    );
  }

  Cmd? _handleTapDown(TapDownDetails details) {
    final localX = details.localPosition.dx.floor();
    // In block mode the content is a column of per-line Text widgets, so the
    // hit-test local Y is relative to the deepest Text (~0). Derive the
    // viewer-relative row from the global pointer position instead.
    final y = _hasCommentBlocks
        ? (details.globalPosition.dy - _viewerGlobalTopY()).floor()
        : details.localPosition.dy.floor();
    // Map the tapped content row back to a diff render-line. When comment
    // blocks are present, the content rows include the comment cards, so we
    // consult the row->render-line map built during layout. The scroll offset
    // is the inner controller's content-row offset in block mode.
    final offset = _hasCommentBlocks
        ? (_commentScrollController?.offset ?? 0)
        : _controller.scrollOffset;
    final contentRow = offset + y;
    final renderLine =
        _rowToRenderedLine[contentRow] ??
        (contentRow < _controller.model.renderedLines.length
            ? contentRow
            : _controller.model.renderedLines.length - 1);
    final side = _sideForLocalX(localX);
    // Only select a comment anchor when the tapped row maps exactly to one, so
    // tapping a diff line below a comment does not snap to (and jump to) the
    // comment card. Tapping a comment card row still resolves to its anchor
    // because the map yields that anchor's render-line.
    final anchor = _controller.model.commentAnchors
        .where(
          (a) => a.renderLine == renderLine && (side == null || a.side == side),
        )
        .firstOrNull;
    if (anchor == null) return null;
    return widget.onCommentAnchorSelected?.call(anchor);
  }

  /// Global Y (screen space) of the top of this viewer, used to convert a
  /// pointer's global position into a viewer-relative row when per-line Text
  /// widgets make the hit-test local Y unreliable.
  double _viewerGlobalTopY() {
    final el = elementOf(widget);
    if (el == null) return 0;
    RenderObject? current = el.renderObject;
    var top = 0.0;
    while (current != null) {
      top += current.offset.dy;
      current = current.parent;
    }
    return top;
  }

  DiffCommentSide? _sideForLocalX(int localX) {
    if (_controller.model.viewMode != DiffViewMode.sideBySide) return null;
    return localX < (_controller.model.width ~/ 2)
        ? DiffCommentSide.left
        : DiffCommentSide.right;
  }
}
