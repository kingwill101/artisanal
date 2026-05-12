import 'dart:async';
import 'dart:io' as io;

import '../terminal/ansi.dart' show Ansi;
import '../tui/bubbles/components/base.dart';
import '../tui/bubbles/components/progress_bar.dart' show ProgressBarComponent;
import '../tui/bubbles/components/table.dart';
import '../tui/bubbles/components/tree.dart' show TreeComponent, TreeEnumerator;
import '../tui/bubbles/spinner.dart' show Spinner, Spinners;
import '../renderer/renderer.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../style/tag_parser.dart';
import '../style/verbosity.dart';
import 'components.dart';
import 'inline_animation.dart';
import 'output_theme.dart';
import 'validators.dart';
import '../terminal/terminal_io_impl.dart' show StdioTerminal;
import '../tui/bubbles/password.dart' show PasswordModel;
import '../tui/bubbles/select.dart'
    show MultiSelectModel, SelectModel, SelectStyles, MultiSelectStyles;
import '../tui/bubbles/search.dart'
    show MultiSearchModel, SearchModel, SearchStyles;
import '../tui/bubbles/data_table.dart' show DataTableModel, DataTableStyles;
import '../tui/bubbles/table.dart' show Column;
import '../tui/bubbles/prompt.dart'
    show
        runMultiSelectPrompt,
        runPasswordPrompt,
        runSelectPrompt,
        runSearchPrompt,
        runMultiSearchPrompt,
        runDataTablePrompt,
        runNumberInputPrompt,
        runSuggestPrompt,
        promptProgramOptions;
import '../tui/bubbles/pause.dart' show CountdownModel;
import '../tui/bubbles/number_input.dart' show NumberInputModel;
import '../tui/bubbles/suggest.dart' show SuggestModel, SuggestStyles;
import '../tui/program.dart' show Program;

/// Callback for writing a complete line to output.
typedef WriteLine = void Function(String line);

/// Callback for writing raw text (without newline) to output.
typedef WriteRaw = void Function(String text);

/// Callback for reading a line of input.
typedef ReadLine = String? Function();

/// Callback for reading secret/password input without echo.
typedef SecretReader = String Function(String prompt, {String? fallback});

/// Result of a task operation.
enum TaskResult {
  /// Task completed successfully.
  success,

  /// Task failed.
  failure,

  /// Task was skipped.
  skipped,
}

/// Style presets for tree rendering.
enum TreeStyle {
  /// Standard tree characters (├── └──).
  normal,

  /// Rounded tree with curved elbow (├── ╰──).
  rounded,

  /// ASCII-only characters for maximum compatibility.
  ascii,

  /// Bullet-style list (• for all items).
  bullet,

  /// Arrow-style list (→ for all items).
  arrow,
}

/// Result of a task group operation.
class TaskGroupResult {
  /// Creates a task group result.
  const TaskGroupResult({
    required this.completed,
    required this.failed,
    required this.skipped,
    this.duration,
  });

  /// Names of successfully completed tasks.
  final List<String> completed;

  /// List of (name, error) pairs for failed tasks.
  final List<(String, Object)> failed;

  /// Names of tasks that were skipped (due to prior failures).
  final List<String> skipped;

  /// Total duration of the task group execution.
  final Duration? duration;

  /// Whether all tasks completed successfully.
  bool get success => failed.isEmpty && skipped.isEmpty;

  /// Total number of tasks.
  int get total => completed.length + failed.length + skipped.length;
}

/// Result of a steps workflow operation.
class StepsResult {
  /// Creates a steps result.
  const StepsResult({
    required this.completed,
    required this.failed,
    required this.skipped,
    this.duration,
  });

  /// Names of successfully completed steps.
  final List<String> completed;

  /// List of (name, error) pairs for failed steps.
  final List<(String, Object)> failed;

  /// Names of steps that were skipped (due to prior failures).
  final List<String> skipped;

  /// Total duration of the workflow execution.
  final Duration? duration;

  /// Whether all steps completed successfully.
  bool get success => failed.isEmpty && skipped.isEmpty;

  /// Total number of steps.
  int get total => completed.length + failed.length + skipped.length;
}

/// The main I/O helper for Artisanal-style console output.
///
/// [Console] provides a high-level API for building polished CLI tools. It
/// handles verbosity levels, ANSI styling, and interactive components.
///
/// {@category Core}
///
/// {@macro artisanal_io_overview}
/// {@macro artisanal_io_verbosity}
///
/// ## Features
///
/// - **Output**: [writeln], [write], [title], [section], [line], [info], [comment], [question], [warn], [success], [error], [alert].
/// - **Components**: [table], `progressBar`, [tree].
/// - **Prompts**: [ask], [confirm], [choice], [secret].
/// - **Tasks**: [task] for running operations with a status indicator.
///
/// ## Usage
///
/// ```dart
/// final console = Console();
/// console.title('My CLI Tool');
///
/// if (console.confirm('Do you want to continue?')) {
///   console.task('Processing...', () async {
///     await Future.delayed(Duration(seconds: 1));
///     return TaskResult.success;
///   });
/// }
/// ```
class Console {
  /// Creates a new I/O helper.
  ///
  /// The [outputTheme] parameter allows customizing the colors used for
  /// different message types (info, warning, error, etc.).
  Console({
    WriteLine? out,
    WriteLine? err,
    WriteRaw? outRaw,
    WriteRaw? errRaw,
    ReadLine? readLine,
    SecretReader? secretReader,
    io.Stdin? stdin,
    io.Stdout? stdout,
    this.interactive = true,
    this.verbosity = Verbosity.normal,
    int? terminalWidth,
    Renderer? renderer,
    OutputTheme? outputTheme,
  }) : _stdout = stdout ?? io.stdout,
       _stdin = stdin ?? io.stdin,
       _out = out ?? ((line) => (stdout ?? io.stdout).writeln(line)),
       _err = err ?? ((line) => io.stderr.writeln(line)),
       _outRaw = outRaw ?? ((text) => (stdout ?? io.stdout).write(text)),
       _errRaw = errRaw ?? ((text) => io.stderr.write(text)),
       _readLine = readLine ?? (stdin ?? io.stdin).readLineSync,
       _secretReader = secretReader,
       terminalWidth = terminalWidth ?? 120,
       _renderer = renderer ?? defaultRenderer,
       _outputTheme = outputTheme ?? const OutputTheme(),
       _tagParser = ConsoleTagParser(
         colorProfile: (renderer ?? defaultRenderer).colorProfile,
         hasDarkBackground: (renderer ?? defaultRenderer).hasDarkBackground,
       )..registerStyle('alert', Style().foreground(Colors.yellow)) {
    _applyOutputTheme();
  }

  /// The current output theme.
  OutputTheme get outputTheme => _outputTheme;

  set outputTheme(OutputTheme value) {
    _outputTheme = value;
    _applyOutputTheme();
  }

  OutputTheme _outputTheme;

  void _applyOutputTheme() {
    for (final entry in _outputTheme.toStyles().entries) {
      _tagParser.registerStyle(entry.key, entry.value);
    }
    // Update existing components to use the new theme
    if (_components != null) {
      _components = Components(io: this);
    }
  }

  /// The renderer for output.
  final Renderer _renderer;

  /// Console tag parser for inline styling.
  final ConsoleTagParser _tagParser;

  /// The ANSI style configuration.
  Style get style => Style()
    ..colorProfile = _renderer.colorProfile
    ..hasDarkBackground = _renderer.hasDarkBackground;

  /// Private getter for internal use (backwards compatibility).
  Style get _style => style;

  /// Registers a custom named style for console tags.
  void registerStyle(String name, Style style) {
    _tagParser.registerStyle(name, style);
  }

  /// Removes a registered custom style.
  void unregisterStyle(String name) {
    _tagParser.unregisterStyle(name);
  }

  /// Gets a registered style by name, or null if not found.
  Style? getStyle(String name) => _tagParser.getStyle(name);

  /// Returns all registered style names.
  Iterable<String> get styleNames => _tagParser.styleNames;

  /// Rendering configuration for bubble-style display components.
  RenderConfig get renderConfig =>
      RenderConfig.fromRenderer(_renderer, terminalWidth: terminalWidth);

  /// Whether interactive prompts are enabled.
  final bool interactive;

  /// The current verbosity level.
  final Verbosity verbosity;

  /// The terminal width for formatting.
  final int terminalWidth;

  StdioTerminal? _cachedPromptTerminal;

  final WriteLine _out;
  final WriteLine _err;
  final WriteRaw _outRaw;
  final WriteRaw _errRaw;
  final ReadLine? _readLine;
  final SecretReader? _secretReader;
  final io.Stdin? _stdin;
  final io.Stdout? _stdout;

  Components? _components;

  /// Whether output is suppressed (quiet mode).
  bool get quiet => verbosity == Verbosity.quiet;

  bool _shouldOutput(Verbosity? minVerbosity) {
    if (quiet) return false;
    if (minVerbosity == null) return true;
    return verbosity.index >= minVerbosity.index;
  }

  /// Access to higher-level console components (Laravel-style).
  ///
  /// ```dart
  /// io.components.task('Processing', run: () async => TaskResult.success);
  /// io.components.twoColumnDetail('Name', 'Value');
  /// io.components.bulletList(['Item 1', 'Item 2']);
  /// ```
  Components get components => _components ??= Components(io: this);

  /// Disposes of console resources, including any active terminal.
  void dispose() {
    _cachedPromptTerminal?.dispose();
    _cachedPromptTerminal = null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Basic Output
  // ─────────────────────────────────────────────────────────────────────────────

  /// Writes a line to stdout.
  void writeln([String line = '']) {
    if (quiet) return;
    _out(_tagParser.render(line));
  }

  /// Writes raw text to stdout (no newline).
  void write(String text) {
    if (quiet) return;
    _outRaw(_tagParser.render(text));
  }

  /// Writes raw text to stderr.
  void writeErr(String text) {
    _errRaw(_tagParser.render(text));
  }

  /// Writes a line to stderr.
  void writelnErr([String line = '']) {
    _err(_tagParser.render(line));
  }

  /// Outputs one or more blank lines.
  void newLine([int count = 1]) {
    for (var i = 0; i < count; i++) {
      writeln();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Formatted Output
  // ─────────────────────────────────────────────────────────────────────────────

  /// Displays an ASCII art logo.
  void logo(String ascii, {Style? style}) {
    final s = style ?? this.style.foreground(Colors.info).bold();
    for (final line in ascii.split('\n')) {
      writeln(s.render(line));
    }
  }

  /// Outputs a title with underline.
  void title(String message) {
    final trimmed = message.trimRight();
    writeln(_style.bold().render(trimmed));
    writeln(_style.bold().render('=' * Style.visibleLength(trimmed)));
    newLine();
  }

  /// Outputs a section header with underline.
  void section(String message) {
    final trimmed = message.trimRight();
    writeln(_style.bold().render(trimmed));
    writeln(_style.bold().render('-' * Style.visibleLength(trimmed)));
    newLine();
  }

  /// Outputs indented text.
  void text(Object message) {
    final lines = _normalizeLines(message);
    for (final line in lines) {
      writeln(' $line');
    }
  }

  /// Outputs a bulleted list.
  void listing(Iterable<Object> items) {
    for (final item in items) {
      writeln(' * $item');
    }
    newLine();
  }

  /// Clears the terminal screen and moves the cursor to the top-left.
  ///
  /// Writes the ANSI clear-screen and cursor-home sequences directly to
  /// stdout. Has no effect when output is quiet.
  ///
  /// Example:
  /// ```dart
  /// console.clearScreen();
  /// console.title('Fresh start');
  /// ```
  void clearScreen() {
    if (quiet) return;
    _outRaw(Ansi.clearScreen);
    _outRaw(Ansi.cursorHome);
  }

  /// Sets the terminal window title via an OSC escape sequence.
  ///
  /// Most modern terminal emulators honour this. Has no visible effect in
  /// environments that do not support OSC sequences.
  ///
  /// Example:
  /// ```dart
  /// console.setTerminalTitle('My CLI Tool — processing…');
  /// ```
  void setTerminalTitle(String title) {
    _outRaw(Ansi.setTitle(title));
  }

  /// Displays items in a multi-column grid layout.
  ///
  /// Arranges [items] into as many columns as fit within [maxWidth] (defaults
  /// to [terminalWidth]). Each column is sized to the longest item it contains,
  /// plus [columnGap] spaces of padding between columns.
  ///
  /// Items are filled **column-first** (down then across), matching the
  /// behaviour of `Laravel\Prompts\Grid`.
  ///
  /// Example:
  /// ```dart
  /// console.grid(['apple', 'banana', 'cherry', 'date', 'elderberry']);
  /// ```
  void grid(List<String> items, {int? maxWidth, int columnGap = 2}) {
    if (items.isEmpty) return;
    final width = maxWidth ?? terminalWidth;

    // Strip ANSI from items to measure visible width.
    int visibleWidth(String s) => Style.visibleLength(s);

    // Try to find the maximum number of columns that fit.
    // Start from 1 column and increase until it no longer fits.
    int bestCols = 1;
    for (var cols = 1; cols <= items.length; cols++) {
      final rows = (items.length / cols).ceil();
      // Build column widths for this layout.
      var totalWidth = 0;
      for (var col = 0; col < cols; col++) {
        var colMax = 0;
        for (var row = 0; row < rows; row++) {
          final idx = row * cols + col;
          if (idx < items.length) {
            final w = visibleWidth(items[idx]);
            if (w > colMax) colMax = w;
          }
        }
        totalWidth += colMax;
        if (col < cols - 1) totalWidth += columnGap;
      }
      if (totalWidth <= width) {
        bestCols = cols;
      } else {
        break;
      }
    }

    final cols = bestCols;
    final rows = (items.length / cols).ceil();

    // Compute column widths for the chosen layout.
    final colWidths = List<int>.filled(cols, 0);
    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < rows; row++) {
        final idx = row * cols + col;
        if (idx < items.length) {
          final w = visibleWidth(items[idx]);
          if (w > colWidths[col]) colWidths[col] = w;
        }
      }
    }

    // Render rows.
    for (var row = 0; row < rows; row++) {
      final buffer = StringBuffer();
      for (var col = 0; col < cols; col++) {
        final idx = row * cols + col;
        final item = idx < items.length ? items[idx] : '';
        buffer.write(item);
        // Pad to column width (except last column in row).
        if (col < cols - 1) {
          final pad = colWidths[col] - visibleWidth(item) + columnGap;
          if (pad > 0) buffer.write(' ' * pad);
        }
      }
      writeln(buffer.toString());
    }
  }

  /// Sends a desktop notification using the platform's native notification
  /// system.
  ///
  /// - **macOS**: uses `osascript`.
  /// - **Linux**: tries `notify-send`, then falls back to `kdialog`.
  /// - Other platforms: returns `false` immediately.
  ///
  /// Returns `true` if the notification was delivered successfully.
  ///
  /// Example:
  /// ```dart
  /// await console.notify('Build complete', body: 'All tests passed.');
  /// ```
  Future<bool> notify(
    String title, {
    String body = '',
    String subtitle = '',
    String sound = '',
    String icon = '',
  }) async {
    if (io.Platform.isMacOS) {
      return _notifyMacOS(title, body: body, subtitle: subtitle, sound: sound);
    }
    if (io.Platform.isLinux) {
      return _notifyLinux(title, body: body, icon: icon);
    }
    return false;
  }

  Future<bool> _notifyMacOS(
    String title, {
    String body = '',
    String subtitle = '',
    String sound = '',
  }) async {
    String esc(String s) =>
        '"${s.replaceAll(r'\', r'\\').replaceAll('"', '\\"')}"';

    final sb = StringBuffer('display notification ${esc(body)}');
    sb.write(' with title ${esc(title)}');
    if (subtitle.isNotEmpty) sb.write(' subtitle ${esc(subtitle)}');
    if (sound.isNotEmpty) sb.write(' sound name ${esc(sound)}');

    return _runProcess('osascript', ['-e', sb.toString()]);
  }

  Future<bool> _notifyLinux(
    String title, {
    String body = '',
    String icon = '',
  }) async {
    // Try notify-send first.
    final notifySend = await _findExecutable('notify-send');
    if (notifySend != null) {
      final args = <String>[];
      if (icon.isNotEmpty) {
        args.addAll(['--icon', icon]);
      }
      args.add(title);
      if (body.isNotEmpty) args.add(body);
      return _runProcess('notify-send', args);
    }

    // Fallback to kdialog.
    final kdialog = await _findExecutable('kdialog');
    if (kdialog != null) {
      final message = body.isNotEmpty ? '$title: $body' : title;
      return _runProcess('kdialog', [
        '--passivepopup',
        message,
        '5',
        '--title',
        title,
      ]);
    }

    return false;
  }

  /// Returns the full path of [executable] if it is on PATH, else null.
  Future<String?> _findExecutable(String executable) async {
    try {
      final result = await io.Process.run('which', [executable]);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}
    return null;
  }

  /// Runs [executable] with [args] and returns whether it exited successfully.
  Future<bool> _runProcess(String executable, List<String> args) async {
    try {
      final result = await io.Process.run(executable, args);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Message Blocks
  // ─────────────────────────────────────────────────────────────────────────────

  /// Outputs a plain line (Laravel-style).
  ///
  /// Supports console tags in the message content. If [style] is provided,
  /// it will be wrapped in a tag (e.g., style "info" -> `<info>message</info>`).
  void line(Object message, {String? style, Verbosity? verbosity}) {
    if (!_shouldOutput(verbosity)) return;
    final text = message.toString();
    if (style == null || style.isEmpty) {
      writeln(text);
      return;
    }
    writeln('<$style>$text</$style>');
  }

  /// Outputs an info message (Laravel-style).
  void info(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'info', verbosity: verbosity);

  /// Outputs a success message (Laravel-style extension).
  void success(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'success', verbosity: verbosity);

  /// Outputs a comment message (Laravel-style).
  void comment(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'comment', verbosity: verbosity);

  /// Outputs a question message (Laravel-style).
  void question(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'question', verbosity: verbosity);

  /// Outputs a warning message (Laravel-style).
  void warn(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'warning', verbosity: verbosity);

  /// Outputs an error message (Laravel-style).
  void error(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'error', verbosity: verbosity);

  /// Outputs a note message.
  void note(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'warning', verbosity: verbosity);

  /// Outputs a caution message.
  void caution(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'error', verbosity: verbosity);

  /// Outputs a verbose message (only if verbosity >= verbose).
  void verbose(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'muted', verbosity: verbosity ?? Verbosity.verbose);

  /// Outputs a debug message (only if verbosity >= debug).
  void debug(Object message, {Verbosity? verbosity}) =>
      line(message, style: 'muted', verbosity: verbosity ?? Verbosity.debug);

  /// Outputs an alert box.
  ///
  /// Uses Artisanal GUI components for rendering.
  void alert(Object message, {Verbosity? verbosity}) {
    if (!_shouldOutput(verbosity)) return;
    components.alert(message);
  }

  /// Outputs a two-column detail line.
  void twoColumnDetail(String first, [String? second]) {
    final left = first;
    final right = second ?? '';
    final maxLeft = (terminalWidth / 2).floor().clamp(16, 60);
    final leftLen = Style.visibleLength(left);
    final pad = maxLeft - leftLen;
    final gap = pad > 0 ? ' ' * pad : ' ';
    writeln('  $left$gap$right');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Tasks
  // ─────────────────────────────────────────────────────────────────────────────

  /// Displays a task with status indicator (DONE/FAIL/SKIPPED).
  ///
  /// Shows an animated progress indicator while the task runs, then displays
  /// the final status. By default, the final status line remains visible.
  ///
  /// Parameters:
  /// - [description]: Text describing the task
  /// - [run]: The async function to execute
  /// - [clearOnDone]: If true, remove the task line after completion
  ///
  /// Example:
  /// ```dart
  /// await console.task('Processing files', run: () async {
  ///   await processFiles();
  ///   return TaskResult.success;
  /// });
  ///
  /// // Task that disappears after completion
  /// await console.task('Loading...', run: () async {
  ///   await loadData();
  ///   return TaskResult.success;
  /// }, clearOnDone: true);
  /// ```
  Future<TaskResult> task(
    String description, {
    FutureOr<TaskResult> Function()? run,
    bool clearOnDone = false,
  }) async {
    final desc = description.trimRight();
    final prefix = '  $desc ';
    final terminal = promptTerminal;
    final supportsAnsi = (_stdout ?? io.stdout).hasTerminal;
    final animate = run != null && interactive && supportsAnsi;
    // Use actual terminal width, not the configured terminalWidth which may be wrong
    final actualWidth = terminal.width;

    if (!animate) {
      write(prefix);
    } else {
      terminal.hideCursor();
    }

    final watch = Stopwatch()..start();
    TaskResult result = TaskResult.success;
    Timer? spinnerTimer;
    var spinnerTick = 0;
    try {
      if (animate) {
        const frames = ['|', '/', '-', '\\'];
        spinnerTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
          final frame = frames[spinnerTick % frames.length];
          spinnerTick++;
          final runtime = _formatDuration(watch.elapsed);
          final runtimeStyled = _style.dim().render(' $runtime');
          final baseUsed =
              Style.visibleLength(prefix) + Style.visibleLength(runtimeStyled);
          final dotsLen = (actualWidth - baseUsed - 2).clamp(0, actualWidth);
          var dots = '.' * dotsLen;
          if (dotsLen > 0) {
            final idx = spinnerTick % dotsLen;
            dots = '${dots.substring(0, idx)}$frame${dots.substring(idx + 1)}';
          }
          terminal.clearLine();
          terminal.write('$prefix${_style.dim().render(dots)}$runtimeStyled');
        });
      }

      final value = await (run?.call() ?? TaskResult.success);
      result = value;
      return result;
    } catch (_) {
      result = TaskResult.failure;
      rethrow;
    } finally {
      watch.stop();
      spinnerTimer?.cancel();
      if (animate) {
        terminal.clearLine();
      }

      // If clearOnDone is set, just clear the line and restore cursor
      if (clearOnDone) {
        if (animate) {
          terminal.showCursor();
        }
      } else {
        final runtime = run == null ? '' : ' ${_formatDuration(watch.elapsed)}';
        final statusLabel = switch (result) {
          TaskResult.success =>
            (getStyle('success') ?? _style.bold().foreground(Colors.success))
                .render('DONE'),
          TaskResult.skipped =>
            (getStyle('warning') ?? _style.bold().foreground(Colors.warning))
                .render('SKIPPED'),
          TaskResult.failure =>
            (getStyle('error') ?? _style.bold().foreground(Colors.error))
                .render('FAIL'),
        };

        final used =
            2 +
            Style.visibleLength(desc) +
            1 +
            Style.visibleLength(runtime) +
            1 +
            4;
        final dots = (actualWidth - used).clamp(0, actualWidth);
        final line =
            '$prefix${_style.dim().render('.' * dots)}${runtime.isNotEmpty ? _style.dim().render(runtime) : ''} $statusLabel';
        if (animate) {
          terminal.write(line);
          terminal.writeln();
          terminal.showCursor();
        } else {
          write(_style.dim().render('.' * dots));
          if (runtime.isNotEmpty) {
            write(_style.dim().render(runtime));
          }
          writeln(' $statusLabel');
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Tables
  // ─────────────────────────────────────────────────────────────────────────────

  /// Outputs a formatted table.
  void table({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final renderConfig = RenderConfig.fromRenderer(
      _renderer,
      terminalWidth: terminalWidth,
    );
    final output = TableComponent(
      headers: headers,
      rows: rows,
      renderConfig: renderConfig,
    ).render();
    for (final line in output.split('\n')) {
      writeln(line);
    }
    newLine();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Progress
  // ─────────────────────────────────────────────────────────────────────────────

  /// Terminal instance used for inline prompts and animations.
  StdioTerminal get promptTerminal => _cachedPromptTerminal ??= StdioTerminal(
    stdout: _stdout ?? io.stdout,
    stdin: _stdin ?? io.stdin,
  );

  /// Iterates over items while showing a progress bar.
  ///
  /// Shows a progress bar that updates as items are yielded. By default,
  /// the final progress bar remains visible after iteration completes.
  ///
  /// Parameters:
  /// - [iterable]: Items to iterate over
  /// - [max]: Total count (if iterable doesn't have a known length)
  /// - [clearOnDone]: If true, remove the progress bar after completion
  ///
  /// Example:
  /// ```dart
  /// for (final item in console.progressIterate(items)) {
  ///   await process(item);
  /// }
  ///
  /// // Progress bar that disappears after completion
  /// for (final item in console.progressIterate(items, clearOnDone: true)) {
  ///   await process(item);
  /// }
  /// ```
  Iterable<T> progressIterate<T>(
    Iterable<T> iterable, {
    int? max,
    bool clearOnDone = false,
  }) sync* {
    final total = max ?? (iterable is List<T> ? iterable.length : 0);
    final terminal = promptTerminal;
    // Use actual terminal width for inline animations to prevent line wrapping
    final actualWidth = terminal.width;
    final renderConfig = RenderConfig.fromRenderer(
      _renderer,
      terminalWidth: actualWidth,
    );

    terminal.hideCursor();
    try {
      var current = 0;
      terminal.clearLine();
      terminal.write(
        ProgressBarComponent(
          current: current,
          total: total,
          renderConfig: renderConfig,
        ).render(),
      );

      for (final item in iterable) {
        yield item;
        current++;
        terminal.clearLine();
        terminal.write(
          ProgressBarComponent(
            current: current,
            total: total,
            renderConfig: renderConfig,
          ).render(),
        );
      }

      if (clearOnDone) {
        terminal.clearLine();
      } else {
        terminal.writeln();
        newLine();
      }
    } finally {
      terminal.showCursor();
    }
  }

  /// Runs an async task while displaying an animated spinner.
  ///
  /// This is a lightweight alternative to [task] that shows a spinner
  /// animation without the DONE/FAIL status line format.
  ///
  /// Parameters:
  /// - [message]: Text to display next to the spinner
  /// - [run]: The async function to execute
  /// - [spinner]: Spinner animation to use (default: miniDot)
  /// - [clearOnDone]: If true, remove the spinner line after completion
  /// - [doneMessage]: Optional message to show after completion
  ///
  /// Example:
  /// ```dart
  /// // Spinner with default behavior (stays visible)
  /// final data = await console.spin('Loading...', run: () => fetchData());
  ///
  /// // Spinner that disappears
  /// await console.spin('Processing...', run: () => process(), clearOnDone: true);
  ///
  /// // Spinner with custom done message
  /// await console.spin('Connecting...', run: () => connect(),
  ///     doneMessage: '✓ Connected');
  /// ```
  Future<T> spin<T>(
    String message, {
    required FutureOr<T> Function() run,
    Spinner spinner = Spinners.miniDot,
    bool clearOnDone = false,
    String? doneMessage,
  }) async {
    // Delegate to components.spin which has the full implementation
    return components.spin(
      message,
      run: run,
      spinner: spinner,
      clearOnDone: clearOnDone,
      showResult: doneMessage == null && !clearOnDone,
    );
  }

  /// Runs an async task with a progress callback.
  ///
  /// The task receives a callback to update progress (0.0 to 1.0).
  ///
  /// Parameters:
  /// - [message]: Text to display with the progress bar
  /// - [run]: Async function that receives a progress updater
  /// - [clearOnDone]: If true, clear the line after completion
  /// - [doneMessage]: Optional message to show after completion
  ///
  /// Example:
  /// ```dart
  /// await console.progress('Downloading', run: (setProgress) async {
  ///   for (var i = 0; i <= 100; i++) {
  ///     await Future.delayed(Duration(milliseconds: 50));
  ///     setProgress(i / 100);
  ///   }
  /// });
  /// ```
  Future<T> progress<T>(
    String message, {
    required FutureOr<T> Function(void Function(double) setProgress) run,
    bool clearOnDone = false,
    String? doneMessage,
  }) async {
    final animation = InlineAnimation(terminal: promptTerminal);
    return animation.progress(
      message: message,
      task: run,
      clearOnDone: clearOnDone,
      doneMessage: doneMessage,
    );
  }

  /// Runs a group of tasks with an overall progress indicator.
  ///
  /// Shows each task with a spinner/checkmark and an optional overall progress
  /// bar at the top. Useful for batch operations like migrations or deployments.
  ///
  /// Parameters:
  /// - [title]: Optional title for the task group
  /// - [tasks]: List of (description, task function) pairs
  /// - [showProgress]: If true, show an overall progress bar
  /// - [continueOnError]: If true, continue with remaining tasks after a failure
  /// - [spinner]: Spinner animation to use for each task
  ///
  /// Returns a [TaskGroupResult] with details about completed/failed tasks.
  ///
  /// Example:
  /// ```dart
  /// final result = await console.taskGroup(
  ///   title: 'Deploying application',
  ///   tasks: [
  ///     ('Building assets', () async { await build(); }),
  ///     ('Running tests', () async { await test(); }),
  ///     ('Deploying to server', () async { await deploy(); }),
  ///   ],
  /// );
  /// ```
  Future<TaskGroupResult> taskGroup({
    String? title,
    required List<(String description, FutureOr<void> Function() task)> tasks,
    bool showProgress = true,
    bool continueOnError = false,
    Spinner spinner = Spinners.miniDot,
  }) async {
    if (tasks.isEmpty) {
      return const TaskGroupResult(completed: [], failed: [], skipped: []);
    }

    final supportsAnsi = (_stdout ?? io.stdout).hasTerminal && interactive;
    final watch = Stopwatch()..start();

    if (title != null) {
      writeln(_style.bold().render(title));
    }

    final completed = <String>[];
    final failed = <(String, Object)>[];
    final skipped = <String>[];
    var hadError = false;

    for (var i = 0; i < tasks.length; i++) {
      final (description, taskFn) = tasks[i];

      if (hadError && !continueOnError) {
        skipped.add(description);
        writeln(
          '  ${_style.dim().render('○')} $description ${_style.dim().render('(skipped)')}',
        );
        continue;
      }

      if (supportsAnsi) {
        try {
          await components.spin(
            description,
            run: taskFn,
            spinner: spinner,
            showResult: true,
          );
          completed.add(description);
        } catch (e) {
          failed.add((description, e));
          hadError = true;
          if (!continueOnError) {
            // Mark remaining as skipped
            for (var j = i + 1; j < tasks.length; j++) {
              skipped.add(tasks[j].$1);
            }
            break;
          }
        }
      } else {
        // Non-interactive fallback
        write('  $description... ');
        try {
          await taskFn();
          writeln(_style.foreground(Colors.success).render('done'));
          completed.add(description);
        } catch (e) {
          writeln(_style.foreground(Colors.error).render('failed'));
          failed.add((description, e));
          hadError = true;
          if (!continueOnError) break;
        }
      }
    }

    watch.stop();

    // Summary
    if (title != null) {
      newLine();
      if (failed.isEmpty) {
        success(
          'Completed ${completed.length} task(s) in ${_formatDuration(watch.elapsed)}',
        );
      } else {
        warn(
          'Completed ${completed.length}, failed ${failed.length}, skipped ${skipped.length} in ${_formatDuration(watch.elapsed)}',
        );
      }
    }

    return TaskGroupResult(
      completed: completed,
      failed: failed,
      skipped: skipped,
      duration: watch.elapsed,
    );
  }

  /// Displays a multi-step workflow with sequential steps.
  ///
  /// Each step is numbered and shows its status (pending/running/done/failed).
  /// Unlike [taskGroup], steps are displayed in a vertical list format with
  /// clear step numbers, making it ideal for wizard-like workflows.
  ///
  /// Parameters:
  /// - [title]: Optional title for the workflow
  /// - [steps]: List of (step name, step function) pairs
  /// - [continueOnError]: If true, continue with remaining steps after a failure
  ///
  /// Example:
  /// ```dart
  /// await console.steps(
  ///   title: 'Project Setup',
  ///   steps: [
  ///     ('Create directory structure', () async => createDirs()),
  ///     ('Initialize git repository', () async => gitInit()),
  ///     ('Install dependencies', () async => installDeps()),
  ///     ('Run initial build', () async => build()),
  ///   ],
  /// );
  /// ```
  Future<StepsResult> steps({
    String? title,
    required List<(String name, FutureOr<void> Function() action)> steps,
    bool continueOnError = false,
  }) async {
    if (steps.isEmpty) {
      return const StepsResult(completed: [], failed: [], skipped: []);
    }

    final terminal = promptTerminal;
    final supportsAnsi = (_stdout ?? io.stdout).hasTerminal && interactive;
    final watch = Stopwatch()..start();
    final totalSteps = steps.length;
    final stepWidth = totalSteps.toString().length;

    if (title != null) {
      writeln(_style.bold().render(title));
      newLine();
    }

    final completed = <String>[];
    final failed = <(String, Object)>[];
    final skipped = <String>[];
    var hadError = false;

    for (var i = 0; i < steps.length; i++) {
      final (name, action) = steps[i];
      final stepNum = (i + 1).toString().padLeft(stepWidth);
      final prefix = '[$stepNum/$totalSteps]';

      if (hadError && !continueOnError) {
        skipped.add(name);
        writeln(
          '  ${_style.dim().render(prefix)} ${_style.dim().render(name)} ${_style.dim().render('○ skipped')}',
        );
        continue;
      }

      if (supportsAnsi) {
        terminal.hideCursor();
        final stepWatch = Stopwatch()..start();

        // Show running state
        var spinnerTick = 0;
        const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
        Timer? spinnerTimer;

        try {
          spinnerTimer = Timer.periodic(const Duration(milliseconds: 83), (_) {
            final frame = frames[spinnerTick % frames.length];
            spinnerTick++;
            terminal.clearLine();
            terminal.write(
              '  ${(getStyle('info') ?? _style.foreground(Colors.info)).render(prefix)} $name ${(getStyle('info') ?? _style.foreground(Colors.info)).render(frame)}',
            );
          });

          // Show initial state
          terminal.write(
            '  ${(getStyle('info') ?? _style.foreground(Colors.info)).render(prefix)} $name ${(getStyle('info') ?? _style.foreground(Colors.info)).render(frames[0])}',
          );

          await action();

          spinnerTimer.cancel();
          stepWatch.stop();
          terminal.clearLine();
          terminal.writeln(
            '  ${(getStyle('success') ?? _style.foreground(Colors.success)).render(prefix)} $name ${(getStyle('success') ?? _style.foreground(Colors.success)).render('✓')} ${_style.dim().render(_formatDuration(stepWatch.elapsed))}',
          );
          completed.add(name);
        } catch (e) {
          spinnerTimer?.cancel();
          stepWatch.stop();
          terminal.clearLine();
          terminal.writeln(
            '  ${(getStyle('error') ?? _style.foreground(Colors.error)).render(prefix)} $name ${(getStyle('error') ?? _style.foreground(Colors.error)).render('✗')} ${_style.dim().render(_formatDuration(stepWatch.elapsed))}',
          );
          failed.add((name, e));
          hadError = true;
          if (!continueOnError) {
            // Mark remaining as skipped
            for (var j = i + 1; j < steps.length; j++) {
              skipped.add(steps[j].$1);
              final skipNum = (j + 1).toString().padLeft(stepWidth);
              writeln(
                '  ${_style.dim().render('[$skipNum/$totalSteps]')} ${_style.dim().render(steps[j].$1)} ${_style.dim().render('○ skipped')}',
              );
            }
            break;
          }
        } finally {
          terminal.showCursor();
        }
      } else {
        // Non-interactive fallback
        write('  $prefix $name... ');
        try {
          await action();
          writeln(_style.foreground(Colors.success).render('done'));
          completed.add(name);
        } catch (e) {
          writeln(_style.foreground(Colors.error).render('failed'));
          failed.add((name, e));
          hadError = true;
          if (!continueOnError) break;
        }
      }
    }

    watch.stop();

    // Summary
    newLine();
    if (failed.isEmpty) {
      success(
        'All ${completed.length} step(s) completed in ${_formatDuration(watch.elapsed)}',
      );
    } else {
      error(
        'Steps: ${completed.length} completed, ${failed.length} failed, ${skipped.length} skipped',
      );
    }

    return StepsResult(
      completed: completed,
      failed: failed,
      skipped: skipped,
      duration: watch.elapsed,
    );
  }

  /// Displays a countdown timer.
  ///
  /// Shows a countdown from [seconds] to 0, then executes the optional [onComplete]
  /// callback. Useful for warning users before destructive operations.
  ///
  /// Uses the TUI [CountdownModel] bubble which handles rendering properly
  /// through the Program architecture, avoiding flicker.
  ///
  /// Parameters:
  /// - [message]: Message to display with the countdown
  /// - [seconds]: Number of seconds to count down
  /// - [onComplete]: Optional callback when countdown reaches zero
  ///
  /// Returns true when countdown completes.
  ///
  /// Example:
  /// ```dart
  /// await console.countdown(
  ///   'Deleting all data in',
  ///   seconds: 5,
  /// );
  /// await deleteAllData();
  /// }
  /// ```
  Future<bool> countdown(
    String message, {
    required int seconds,
    FutureOr<void> Function()? onComplete,
  }) async {
    final terminal = promptTerminal;
    final supportsAnsi = (_stdout ?? io.stdout).hasTerminal && interactive;

    if (!supportsAnsi) {
      // Non-interactive: just wait
      writeln('$message $seconds seconds...');
      await Future<void>.delayed(Duration(seconds: seconds));
      if (onComplete != null) await onComplete();
      return true;
    }

    // Use the TUI CountdownModel which handles rendering properly
    await Program(
      CountdownModel(
        duration: Duration(seconds: seconds),
        message: message,
      ),
      options: promptProgramOptions,
      terminal: terminal,
    ).run();

    if (onComplete != null) await onComplete();
    return true;
  }

  /// Displays a tree structure.
  ///
  /// Convenience method for rendering tree data. For more control,
  /// use `TreeComponent` or `Tree` directly.
  ///
  /// Parameters:
  /// - [data]: Nested map/list structure to display
  /// - [root]: Optional root label
  /// - [style]: Tree style preset (normal, rounded, ascii, etc.)
  ///
  /// Example:
  /// ```dart
  /// console.tree({
  ///   'src': {
  ///     'lib': ['main.dart', 'utils.dart'],
  ///     'test': ['main_test.dart'],
  ///   },
  ///   'pubspec.yaml': null,
  /// }, root: 'my_project');
  /// ```
  void tree(
    Map<String, dynamic> data, {
    String? root,
    TreeStyle style = TreeStyle.normal,
  }) {
    final enumerator = switch (style) {
      TreeStyle.normal => TreeEnumerator.normal,
      TreeStyle.rounded => TreeEnumerator.rounded,
      TreeStyle.ascii => TreeEnumerator.ascii,
      TreeStyle.bullet => TreeEnumerator.bullet,
      TreeStyle.arrow => TreeEnumerator.arrow,
    };

    final component = TreeComponent(
      data: data,
      showRoot: root != null,
      rootLabel: root ?? '.',
      enumerator: enumerator,
      renderConfig: renderConfig,
    );

    for (final line in component.render().split('\n')) {
      writeln(line);
    }
    newLine();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Prompts
  // ─────────────────────────────────────────────────────────────────────────────

  /// Prompts for a yes/no confirmation.
  bool confirm(String question, {bool defaultValue = true}) {
    if (!interactive) return defaultValue;

    final suffix = defaultValue ? '[Y/n]' : '[y/N]';
    write(
      '${(getStyle('question') ?? _style.bold().foreground(Colors.warning)).render(question)} $suffix ',
    );
    final input = (_readLine?.call() ?? '').trim().toLowerCase();
    if (input.isEmpty) return defaultValue;
    if (input == 'y' || input == 'yes') return true;
    if (input == 'n' || input == 'no') return false;
    return defaultValue;
  }

  /// Prompts for text input.
  String ask(
    String question, {
    String? defaultValue,
    String? Function(String value)? validator,
    int attempts = 3,
  }) {
    if (!interactive) {
      if (defaultValue != null) return defaultValue;
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    for (var i = 0; i < attempts; i++) {
      final suffix = defaultValue == null ? '' : ' [$defaultValue]';
      write(
        '${(getStyle('question') ?? _style.bold().foreground(Colors.warning)).render(question)}$suffix: ',
      );
      final raw = _readLine?.call();
      final value = (raw == null || raw.isEmpty) ? (defaultValue ?? '') : raw;
      final error = validator?.call(value);
      if (error == null) return value;
      writelnErr(
        _style.bold().foreground(Colors.error).render('Error: $error'),
      );
    }

    throw StateError('Too many invalid attempts.');
  }

  /// Prompts for secret/password input (no echo).
  Future<String> secret(String question, {String? fallback}) async {
    if (!interactive) {
      if (fallback != null) return fallback;
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    if (_secretReader != null) {
      return _secretReader(question, fallback: fallback);
    }

    final terminal = promptTerminal;
    final model = PasswordModel(prompt: question);
    final result = await runPasswordPrompt(model, terminal);
    if (result != null) return result;
    if (fallback != null) return fallback;
    throw StateError('Password prompt cancelled.');
  }

  /// Prompts for a choice from a list (basic numbered selection).
  Object choice(
    String question, {
    required List<String> choices,
    int? defaultIndex,
    bool multiSelect = false,
  }) {
    if (!interactive) {
      if (defaultIndex != null &&
          defaultIndex >= 0 &&
          defaultIndex < choices.length) {
        return multiSelect
            ? <String>[choices[defaultIndex]]
            : choices[defaultIndex];
      }
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    writeln(
      (getStyle('question') ?? _style.bold().foreground(Colors.warning)).render(
        question,
      ),
    );
    for (var i = 0; i < choices.length; i++) {
      writeln('  [$i] ${choices[i]}');
    }

    if (!multiSelect) {
      final prompt = defaultIndex == null
          ? 'Select an option'
          : 'Select an option [$defaultIndex]';
      final raw = ask(prompt, defaultValue: defaultIndex?.toString());
      final parsed = int.tryParse(raw);
      if (parsed == null || parsed < 0 || parsed >= choices.length) {
        throw StateError('Invalid selection: $raw');
      }
      return choices[parsed];
    }

    final prompt = defaultIndex == null
        ? 'Select options (comma separated)'
        : 'Select options (comma separated) [$defaultIndex]';
    final raw = ask(prompt, defaultValue: defaultIndex?.toString());
    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    final selected = <String>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed == null || parsed < 0 || parsed >= choices.length) {
        throw StateError('Invalid selection: $part');
      }
      selected.add(choices[parsed]);
    }
    return selected;
  }

  /// Prompts for a numeric value.
  ///
  /// When [interactive] is true, runs a TUI prompt where Up/Down arrow keys
  /// increment or decrement the value by [step], respecting [min] and [max].
  /// When non-interactive, falls back to a simple readline loop with validation.
  ///
  /// Returns the entered number, or [defaultValue] if accepted without typing.
  Future<num> number(
    String question, {
    num? defaultValue,
    num? min,
    num? max,
    num step = 1,
    int attempts = 3,
    String hint = '',
  }) async {
    if (!interactive) {
      // Non-interactive path: simple readline with validation.
      final validator = Validators.combine([
        Validators.required(),
        Validators.numeric(min: min, max: max),
      ]);
      final raw = ask(
        question,
        defaultValue: defaultValue?.toString(),
        validator: (val) {
          try {
            return validator(val);
          } catch (e) {
            return e.toString();
          }
        },
        attempts: attempts,
      );
      return num.parse(raw);
    }

    final terminal = promptTerminal;
    final model = NumberInputModel(
      prompt: question,
      defaultValue: defaultValue,
      min: min,
      max: max,
      step: step,
      hint: hint,
    );
    final result = await runNumberInputPrompt(model, terminal);
    if (result != null) return result;
    if (defaultValue != null) return defaultValue;
    throw StateError('Number prompt cancelled.');
  }

  /// Interactive single-select with arrow-key navigation.
  Future<T?> selectChoice<T>(
    String question, {
    required List<T> choices,
    int? defaultIndex,
    String Function(T)? display,
  }) async {
    if (!interactive) {
      if (defaultIndex != null &&
          defaultIndex >= 0 &&
          defaultIndex < choices.length) {
        return choices[defaultIndex];
      }
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    final terminal = promptTerminal;
    final model = SelectModel<T>(
      items: choices,
      title: question,
      initialIndex: defaultIndex ?? 0,
      display: display,
      styles: SelectStyles(
        title: getStyle('question') ?? Style().bold(),
        dimmed: getStyle('muted') ?? Style().foreground(AnsiColor(8)),
      ),
    );
    return await runSelectPrompt(model, terminal);
  }

  /// Interactive multi-select with arrow-key navigation.
  Future<List<T>> multiSelectChoice<T>(
    String question, {
    required List<T> choices,
    List<int> defaultSelected = const [],
    String Function(T)? display,
  }) async {
    if (!interactive) {
      return defaultSelected.map((i) => choices[i]).toList();
    }

    final terminal = promptTerminal;
    final validDefaults = defaultSelected
        .where((index) => index >= 0 && index < choices.length)
        .toSet();
    final model = MultiSelectModel<T>(
      items: choices,
      title: question,
      initialIndex: validDefaults.isNotEmpty ? validDefaults.first : 0,
      initialSelected: validDefaults,
      display: display,
      styles: MultiSelectStyles(
        title: getStyle('question') ?? Style().bold(),
        dimmed: getStyle('muted') ?? Style().foreground(AnsiColor(8)),
      ),
    );
    final result = await runMultiSelectPrompt(model, terminal);
    return result ?? [];
  }

  /// Displays a persistent menu and returns the selected choice.
  Future<T?> menu<T>(
    String title, {
    required List<T> choices,
    int? defaultIndex,
    String Function(T)? display,
  }) async {
    return selectChoice(
      title,
      choices: choices,
      defaultIndex: defaultIndex,
      display: display,
    );
  }

  /// Interactive search/filter prompt with fuzzy matching.
  ///
  /// Shows a search input that filters items in real-time as the user types.
  /// Returns the selected item, or null if cancelled.
  ///
  /// Parameters:
  /// - [question]: Title displayed above the search
  /// - [items]: List of items to search through
  /// - [display]: Optional function to convert items to display strings
  /// - [placeholder]: Placeholder text for the search input
  /// - [noResultsText]: Text shown when no items match
  ///
  /// Example:
  /// ```dart
  /// final file = await console.search(
  ///   'Select a file:',
  ///   items: ['main.dart', 'pubspec.yaml', 'README.md', 'lib/utils.dart'],
  /// );
  /// if (file != null) {
  ///   print('Selected: $file');
  /// }
  /// ```
  Future<T?> search<T>(
    String question, {
    required List<T> items,
    String Function(T)? display,
    String placeholder = 'Type to search...',
    String noResultsText = 'No matches found',
  }) async {
    if (!interactive) {
      if (items.isNotEmpty) return items.first;
      return null;
    }

    final terminal = promptTerminal;
    final model = SearchModel<T>(
      items: items,
      title: question,
      display: display,
      placeholder: placeholder,
      noResultsText: noResultsText,
      styles: SearchStyles(
        title: getStyle('question') ?? Style().bold(),
        dimmed: getStyle('muted') ?? Style().foreground(AnsiColor(8)),
      ),
    );
    return await runSearchPrompt(model, terminal);
  }

  /// Interactive multi-search/filter prompt with fuzzy matching.
  ///
  /// Shows a search input that filters items in real-time. Allows selecting
  /// multiple items using space. Returns the selected items.
  ///
  /// Parameters:
  /// - [question]: Title displayed above the search
  /// - [items]: List of items to search through
  /// - [display]: Optional function to convert items to display strings
  /// - [placeholder]: Placeholder text for the search input
  /// - [noResultsText]: Text shown when no items match
  /// - [hint]: Hint text shown below the title
  ///
  /// Example:
  /// ```dart
  /// final files = await console.multiSearch(
  ///   'Select files:',
  ///   items: ['main.dart', 'pubspec.yaml', 'README.md', 'lib/utils.dart'],
  /// );
  /// ```
  Future<List<T>> multiSearch<T>(
    String question, {
    required List<T> items,
    String Function(T)? display,
    String placeholder = 'Type to search...',
    String noResultsText = 'No matches found',
    String? hint,
  }) async {
    if (!interactive) {
      return [];
    }

    final terminal = promptTerminal;
    final model = MultiSearchModel<T>(
      items: items,
      title: question,
      display: display,
      placeholder: placeholder,
      noResultsText: noResultsText,
      hint: hint ?? '(Space to toggle, ^a to toggle all, Enter to confirm)',
      styles: SearchStyles(
        title: getStyle('question') ?? Style().bold(),
        dimmed: getStyle('muted') ?? Style().foreground(AnsiColor(8)),
      ),
    );
    final result = await runMultiSearchPrompt(model, terminal);
    return result ?? [];
  }

  /// Interactive data table with fuzzy filtering and row selection.
  ///
  /// Displays a searchable grid of items. Returns the selected item, or null if cancelled.
  ///
  /// Parameters:
  /// - [question]: Title displayed above the table
  /// - [columns]: List of table columns with titles and widths
  /// - [items]: List of source items
  /// - [rowBuilder]: Function to convert an item to a list of strings (cells)
  /// - [pageSize]: Number of rows to show per page
  ///
  /// Example:
  /// ```dart
  /// final user = await console.dataTable<User>(
  ///   'Select a user:',
  ///   columns: [
  ///     Column(title: 'ID', width: 5),
  ///     Column(title: 'Name', width: 20),
  ///   ],
  ///   items: users,
  ///   rowBuilder: (u) => [u.id, u.name],
  /// );
  /// ```
  Future<T?> dataTable<T>(
    String question, {
    required List<Column> columns,
    required List<T> items,
    required List<String> Function(T) rowBuilder,
    int pageSize = 10,
  }) async {
    if (!interactive) {
      return items.isNotEmpty ? items.first : null;
    }

    final terminal = promptTerminal;

    // Build header style: always keep bold + padding, optionally apply theme color.
    final headerBase = Style().bold().padding(0, 1);
    final infoColor = outputTheme.info;
    final headerStyle = infoColor != null
        ? (headerBase.copy()..foreground(infoColor))
        : headerBase;

    // Build selected-row style: always keep bold, apply theme color if available.
    final selectedBase = Style().bold();
    final alertColor = outputTheme.alert;
    final selectedStyle = alertColor != null
        ? (selectedBase.copy()..foreground(alertColor))
        : (selectedBase.copy()..foreground(AnsiColor(212)));

    final model = DataTableModel<T>(
      items: items,
      columns: columns,
      rowBuilder: rowBuilder,
      title: question,
      pageSize: pageSize,
      styles: DataTableStyles(
        title: getStyle('question') ?? Style().bold(),
        prompt: getStyle('info') ?? Style().foreground(AnsiColor(11)),
        tableHeader: headerStyle,
        tableSelected: selectedStyle,
        dimmed: getStyle('muted') ?? Style().foreground(AnsiColor(8)),
      ),
    );
    return await runDataTablePrompt<T>(model, terminal);
  }

  /// Interactive suggest/autocomplete prompt.
  ///
  /// Shows a text input with a scrollable dropdown of prefix-matched suggestions
  /// while the user types. The user may also type a value not in the list.
  ///
  /// - [options]: Static list of suggestion strings, **or** a callback
  ///   `(String input) => List<String>` for dynamic/async suggestions.
  /// - [scroll]: Maximum number of suggestion rows shown at once.
  ///
  /// Returns the accepted value (typed or selected), or null if cancelled.
  ///
  /// Example:
  /// ```dart
  /// final lang = await console.suggest(
  ///   'Pick a language:',
  ///   options: ['Dart', 'Python', 'Ruby', 'Rust'],
  /// );
  /// ```
  Future<String?> suggest(
    String question, {
    required List<String> options,
    String placeholder = '',
    String? defaultValue,
    int scroll = 5,
    String hint = '',
  }) async {
    if (!interactive) {
      return defaultValue;
    }

    final terminal = promptTerminal;
    final model = SuggestModel(
      prompt: question,
      options: options,
      placeholder: placeholder,
      defaultValue: defaultValue ?? '',
      scroll: scroll,
      hint: hint,
      styles: SuggestStyles(
        title: getStyle('question') ?? Style().bold(),
        highlighted: getStyle('info') ?? Style().foreground(AnsiColor(11)),
        dimmed: getStyle('muted') ?? Style().foreground(AnsiColor(8)),
      ),
    );
    return await runSuggestPrompt(model, terminal);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  List<String> _normalizeLines(Object message) {
    if (message is Iterable) {
      return message.map((e) => e.toString()).toList();
    }
    return message.toString().split('\n');
  }
}

String _formatDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms < 1000) return '${ms}ms';
  final seconds = ms / 1000;
  return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s';
}

/// Extension to allow [DisplayComponent]s to be written directly to a [Console].
extension DisplayComponentExtension on DisplayComponent {
  /// Renders the component and writes it to the console.
  void writelnTo(Console io) {
    final output = render();
    if (output.isEmpty) return;
    for (final line in output.split('\n')) {
      io.writeln(line);
    }
  }
}
