part of 'components_widgets.dart';

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

  /// Sets the raw unified diff text.
  void setDiff(String rawDiff) {
    _model = _model.setDiff(rawDiff);
    _notifyListeners();
  }

  /// Updates the viewport size.
  void setSize(int width, int height) {
    if (_model.width == width && _model.height == height) return;
    _model = _model.copyWith(
      width: width,
      height: height,
      viewport: _model.viewport.copyWith(width: width, height: height),
    );
    // Re-render lines for the new dimensions (e.g. side-by-side panel widths).
    _model = _model.rerender();
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
  }) {
    final needsRerender =
        (viewMode != null && viewMode != _model.viewMode) ||
        (showLineNumbers != null &&
            showLineNumbers != _model.showLineNumbers) ||
        (wrapLines != null && wrapLines != _model.wrapLines) ||
        (zeroPadLineNumbers != null &&
            zeroPadLineNumbers != _model.zeroPadLineNumbers) ||
        (styles != null && styles != _model.styles);

    if (!needsRerender) return;

    _model = _model.copyWith(
      showLineNumbers: showLineNumbers,
      wrapLines: wrapLines,
      zeroPadLineNumbers: zeroPadLineNumbers,
      viewMode: viewMode,
      styles: styles,
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
    this.handleKeys = true,
    this.scrollable = true,
    this.fitContentHeight = false,
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

  @override
  State createState() => _GitDiffViewerState();
}

class _GitDiffViewerState extends State<GitDiffViewer> {
  late GitDiffController _controller;
  bool _controllerAttached = false;
  String _lastDiff = '';
  Theme? _cachedTheme;
  DiffStyles? _cachedThemeStyles;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _syncController();
  }

  @override
  Cmd? didUpdateWidget(covariant GitDiffViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _attachController(widget.controller);
    }
    _syncController();
    return null;
  }

  void _attachController(GitDiffController? controller) {
    if (_controllerAttached) {
      _controller.removeListener(_onChanged);
    }
    _controller = controller ?? GitDiffController();
    _controller.addListener(_onChanged);
    _controllerAttached = true;
  }

  @override
  void dispose() {
    if (_controllerAttached) {
      _controller.removeListener(_onChanged);
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
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (!widget.scrollable && (msg is KeyMsg || msg is MouseMsg)) {
      return null;
    }
    if (!widget.handleKeys && msg is KeyMsg) return null;

    final prev = _controller.model;
    final (next, cmd) = _controller.update(msg);
    if (!identical(prev, next)) {
      setState(() {});
    }
    return cmd;
  }

  @override
  Widget build(BuildContext context) {
    // Derive styles from the theme when no custom styles are provided.
    // Cache the derived DiffStyles so we only re-render when the theme
    // actually changes, not on every frame.
    if (widget.styles == null) {
      final theme = ThemeScope.of(context);
      if (!identical(theme, _cachedTheme)) {
        _cachedTheme = theme;
        _cachedThemeStyles = DiffStyles.fromColors(
          success: theme.success,
          error: theme.error,
          muted: theme.muted,
          surface: theme.surface,
          onSurface: theme.onSurface,
          onBackground: theme.onBackground,
          border: theme.border,
        );
        _controller.configure(styles: _cachedThemeStyles);
      }
    } else {
      // Custom styles provided via widget prop — clear cache so theme
      // styles are re-derived if custom styles are later removed.
      _cachedTheme = null;
      _cachedThemeStyles = null;
    }
    return Text(_controller.model.view(), softWrap: false);
  }
}
