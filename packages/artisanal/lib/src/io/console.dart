import 'dart:async';
import 'dart:io' as io;

import '../tui/bubbles/components/base.dart';
import '../tui/bubbles/components/progress_bar.dart' show ProgressBarComponent;
import '../tui/bubbles/components/table.dart';
import '../renderer/renderer.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../style/verbosity.dart';
import 'components.dart';
import '../tui/terminal.dart' show StdioTerminal;
import '../tui/bubbles/password.dart' show PasswordModel;
import '../tui/bubbles/select.dart' show MultiSelectModel, SelectModel;
import '../tui/bubbles/prompt.dart'
    show runMultiSelectPrompt, runPasswordPrompt, runSelectPrompt;

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
/// - **Output**: [writeln], [write], [title], [section], [info], [success], [error].
/// - **Components**: [table], [progressBar], [tree].
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
  }) : _stdout = stdout ?? io.stdout,
       _stdin = stdin ?? io.stdin,
       _out = out ?? ((line) => (stdout ?? io.stdout).writeln(line)),
       _err = err ?? ((line) => io.stderr.writeln(line)),
       _outRaw = outRaw ?? ((text) => (stdout ?? io.stdout).write(text)),
       _errRaw = errRaw ?? ((text) => io.stderr.write(text)),
       _readLine = readLine ?? (stdin ?? io.stdin).readLineSync,
       _secretReader = secretReader,
       terminalWidth = terminalWidth ?? 120,
       _renderer = renderer ?? defaultRenderer;

  /// The renderer for output.
  final Renderer _renderer;

  /// The ANSI style configuration.
  Style get style => Style()
    ..colorProfile = _renderer.colorProfile
    ..hasDarkBackground = _renderer.hasDarkBackground;

  /// Private getter for internal use (backwards compatibility).
  Style get _style => style;

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
    _out(line);
  }

  /// Writes raw text to stdout (no newline).
  void write(String text) {
    if (quiet) return;
    _outRaw(text);
  }

  /// Writes raw text to stderr.
  void writeErr(String text) {
    _errRaw(text);
  }

  /// Writes a line to stderr.
  void writelnErr([String line = '']) {
    _err(line);
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Message Blocks
  // ─────────────────────────────────────────────────────────────────────────────

  /// Outputs an info message.
  void info(Object message) =>
      _labeledBlock('INFO', message, _style.bold().foreground(Colors.info));

  /// Outputs a success message.
  void success(Object message) =>
      _labeledBlock('OK', message, _style.bold().foreground(Colors.success));

  /// Outputs a warning message.
  void warning(Object message) => _labeledBlock(
    'WARNING',
    message,
    _style.bold().foreground(Colors.warning),
  );

  /// Outputs an error message.
  void error(Object message) =>
      _labeledBlock('ERROR', message, _style.bold().foreground(Colors.error));

  /// Outputs a note message.
  void note(Object message) =>
      _labeledBlock('NOTE', message, _style.bold().foreground(Colors.warning));

  /// Outputs a caution message.
  void caution(Object message) =>
      _labeledBlock('CAUTION', message, _style.bold().foreground(Colors.error));

  /// Outputs a verbose message (only if verbosity >= verbose).
  void verbose(Object message) {
    if (verbosity.index >= Verbosity.verbose.index) {
      _labeledBlock('VERBOSE', message, _style.bold().foreground(Colors.muted));
    }
  }

  /// Outputs a debug message (only if verbosity >= debug).
  void debug(Object message) {
    if (verbosity.index >= Verbosity.debug.index) {
      _labeledBlock('DEBUG', message, _style.bold().foreground(Colors.muted));
    }
  }

  /// Outputs an alert box.
  void alert(Object message) {
    final warningStyle = _style.bold().foreground(Colors.warning);
    final lines = _normalizeLines(message);
    final contentWidth = lines
        .map((line) => Style.visibleLength(line))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final width = (contentWidth + 4).clamp(0, terminalWidth);

    final top = '+${'-' * (width - 2)}+';
    writeln(warningStyle.render(top));
    for (final line in lines) {
      final visible = Style.visibleLength(line);
      final fill = width - 4 - visible;
      writeln(
        warningStyle.render('| ') +
            line +
            (' ' * (fill > 0 ? fill : 0)) +
            warningStyle.render(' |'),
      );
    }
    writeln(warningStyle.render(top));
    newLine();
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
  Future<TaskResult> task(
    String description, {
    FutureOr<TaskResult> Function()? run,
  }) async {
    final desc = description.trimRight();
    final prefix = '  $desc ';
    final terminal = promptTerminal;
    final supportsAnsi = (_stdout ?? io.stdout).hasTerminal;
    final animate = run != null && interactive && supportsAnsi;

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
          final dotsLen = (terminalWidth - baseUsed - 2).clamp(
            0,
            terminalWidth,
          );
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
      final runtime = run == null ? '' : ' ${_formatDuration(watch.elapsed)}';
      final statusLabel = switch (result) {
        TaskResult.success =>
          _style.bold().foreground(Colors.success).render('DONE'),
        TaskResult.skipped =>
          _style.bold().foreground(Colors.warning).render('SKIPPED'),
        TaskResult.failure =>
          _style.bold().foreground(Colors.error).render('FAIL'),
      };

      final used =
          2 +
          Style.visibleLength(desc) +
          1 +
          Style.visibleLength(runtime) +
          1 +
          4;
      final dots = (terminalWidth - used).clamp(0, terminalWidth);
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

  /// Creates a new progress bar.
  Iterable<T> progressIterate<T>(Iterable<T> iterable, {int? max}) sync* {
    final total = max ?? (iterable is List<T> ? iterable.length : 0);
    final terminal = promptTerminal;
    final renderConfig = RenderConfig.fromRenderer(
      _renderer,
      terminalWidth: terminalWidth,
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

      terminal.writeln();
    } finally {
      terminal.showCursor();
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
      '${_style.bold().foreground(Colors.warning).render(question)} $suffix ',
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
        '${_style.bold().foreground(Colors.warning).render(question)}$suffix: ',
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

    writeln(_style.bold().foreground(Colors.warning).render(question));
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  List<String> _normalizeLines(Object message) {
    if (message is Iterable) {
      return message.map((e) => e.toString()).toList();
    }
    return message.toString().split('\n');
  }

  void _labeledBlock(String label, Object message, Style labelStyle) {
    final lines = _normalizeLines(message);
    for (final line in lines) {
      writeln('${labelStyle.render('[$label]')} $line');
    }
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
