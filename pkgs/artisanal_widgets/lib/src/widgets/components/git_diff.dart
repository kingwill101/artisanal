import 'dart:math' as math;

import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color;
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout_widgets.dart';
import 'package:artisanal_widgets/src/widgets/scroll_widgets.dart'
    show WidgetScrollController;
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal/bubbles.dart'
    show
        DiffCommentAnchor,
        DiffCommentLineHighlight,
        DiffCommentLineHighlightKind,
        DiffCommentLineKey,
        DiffCommentKind,
        DiffCommentSide,
        DiffFile,
        DiffStyles,
        DiffViewMode,
        GitDiffModel;

import 'package:artisanal_widgets/src/widgets/gestures/events.dart';
import 'package:artisanal_widgets/src/widgets/gestures/hit_testing.dart';
import 'package:artisanal_widgets/src/widgets/theme/theme.dart';

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

  /// Optional external widget scroll controller.
  ///
  /// When supplied, this controller owns the vertical scroll offset so parent
  /// layouts can drive the diff viewer without forcing full-content rendering.
  final WidgetScrollController? scrollController;

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
  WidgetScrollController? _scrollController;
  bool _scrollControllerAttached = false;
  String _lastDiff = '';
  Theme? _cachedTheme;
  bool? _cachedHasDarkBackground;
  DiffStyles? _cachedThemeStyles;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _attachScrollController(widget.scrollController);
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

  void _attachScrollController(WidgetScrollController? controller) {
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
    setState(() {});
  }

  void _onExternalScrollChanged() {
    _syncExternalScrollController();
    setState(() {});
  }

  void _syncExternalScrollController() {
    final scroll = _scrollController;
    if (scroll == null) return;
    _syncExternalScrollMetrics();
    _controller.setScrollOffset(scroll.offset);
  }

  void _syncExternalScrollMetrics() {
    final scroll = _scrollController;
    if (scroll is! WidgetScrollController) return;
    scroll.updateMetrics(
      viewportExtent: _controller.model.height,
      contentExtent: _controller.totalLineCount,
    );
  }

  void _syncExternalOffsetFromModel() {
    final scroll = _scrollController;
    if (scroll == null) return;
    _syncExternalScrollMetrics();
    if (scroll.offset != _controller.scrollOffset) {
      scroll.jumpTo(_controller.scrollOffset);
    }
  }

  @override
  Cmd? handleUpdate(Msg msg) {
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
    if (widget.onCommentAnchorSelected == null) return text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      child: text,
    );
  }

  Cmd? _handleTapDown(TapDownDetails details) {
    final localY = details.localPosition.dy.floor();
    final localX = details.localPosition.dx.floor();
    final renderLine = _controller.scrollOffset + localY;
    final side = _sideForLocalX(localX);
    final anchor = _controller.commentAnchorAt(renderLine, side: side);
    if (anchor == null) return null;
    return widget.onCommentAnchorSelected?.call(anchor);
  }

  DiffCommentSide? _sideForLocalX(int localX) {
    if (_controller.model.viewMode != DiffViewMode.sideBySide) return null;
    return localX < (_controller.model.width ~/ 2)
        ? DiffCommentSide.left
        : DiffCommentSide.right;
  }
}
