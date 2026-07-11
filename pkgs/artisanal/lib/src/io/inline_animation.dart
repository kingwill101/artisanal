import 'dart:async';

import '../style/color.dart';
import '../style/style.dart';
import '../style/chars.dart';
import '../terminal/terminal.dart';
import '../tui/bubbles/spinner.dart';
import '../tui/bubbles/components/base.dart';

/// Result of an inline animation operation.
class InlineAnimationResult<T> {
  const InlineAnimationResult({
    required this.value,
    required this.duration,
    this.error,
  });

  /// The result value from the task.
  final T? value;

  /// How long the task took.
  final Duration duration;

  /// Error if the task failed.
  final Object? error;

  /// Whether the task succeeded.
  bool get success => error == null;
}

/// Lightweight inline animation runner.
///
/// Provides spinner and progress animations that run inline in the terminal
/// without the overhead of the full TUI Program. Animations can optionally
/// disappear after completion.
///
/// ## Features
///
/// - **Spinner animations**: Show a spinner while a task runs
/// - **Progress bars**: Show progress for iterative or async operations
/// - **Clear on done**: Optionally remove animation after completion
/// - **Custom done messages**: Replace animation with a completion message
///
/// ## Example
///
/// ```dart
/// final animation = InlineAnimation(terminal: terminal);
///
/// // Spinner that disappears after task completes
/// final result = await animation.spin(
///   message: 'Loading...',
///   task: () => fetchData(),
///   clearOnDone: true,
/// );
///
/// // Spinner with completion message
/// await animation.spin(
///   message: 'Processing...',
///   task: () => processFiles(),
///   doneMessage: '✓ Done',
/// );
///
/// // Progress bar
/// await animation.progress(
///   message: 'Downloading',
///   task: (setProgress) async {
///     for (var i = 0; i <= 100; i++) {
///       await Future.delayed(Duration(milliseconds: 50));
///       setProgress(i / 100);
///     }
///   },
/// );
/// ```
class InlineAnimation {
  /// Creates an inline animation runner.
  InlineAnimation({required this.terminal, this.renderConfig});

  /// The terminal to render to.
  final Terminal terminal;

  /// Optional render configuration for styling.
  final RenderConfig? renderConfig;

  /// Runs a spinner animation while executing a task.
  ///
  /// The spinner animates until the [task] completes. By default, the final
  /// frame remains visible. Set [clearOnDone] to true to remove the spinner
  /// after completion, or provide a [doneMessage] to replace it.
  ///
  /// Parameters:
  /// - [message]: Text to display next to the spinner
  /// - [task]: Async function to execute
  /// - [spinner]: Spinner animation to use (default: miniDot)
  /// - [clearOnDone]: If true, clear the line after completion
  /// - [doneMessage]: Optional message to show after completion
  /// - [errorMessage]: Optional message to show on error (uses doneMessage format)
  ///
  /// Returns the result of [task].
  ///
  /// Throws if [task] throws, after cleaning up the animation.
  Future<T> spin<T>({
    required String message,
    required FutureOr<T> Function() task,
    Spinner spinner = Spinners.miniDot,
    bool clearOnDone = false,
    String? doneMessage,
    String? errorMessage,
  }) async {
    final frames = spinner.frames;
    if (frames.isEmpty) {
      // No animation frames, just run the task
      return await task();
    }

    var frameIndex = 0;
    Timer? timer;
    final watch = Stopwatch()..start();

    // Hide cursor during animation
    terminal.hideCursor();

    try {
      // Start animation timer
      timer = Timer.periodic(spinner.fps, (_) {
        frameIndex = (frameIndex + 1) % frames.length;
        _renderSpinnerFrame(frames[frameIndex], message, watch.elapsed);
      });

      // Render initial frame
      _renderSpinnerFrame(frames[0], message, Duration.zero);

      // Execute task
      final result = await task();

      watch.stop();
      timer.cancel();

      // Handle completion
      if (clearOnDone && doneMessage == null) {
        terminal.clearLine();
      } else if (doneMessage != null) {
        terminal.clearLine();
        terminal.writeln(doneMessage);
      } else {
        // Leave final frame visible, add newline
        terminal.writeln();
      }

      return result;
    } catch (e) {
      watch.stop();
      timer?.cancel();

      // Handle error display
      if (clearOnDone && errorMessage == null && doneMessage == null) {
        terminal.clearLine();
      } else if (errorMessage != null) {
        terminal.clearLine();
        terminal.writeln(errorMessage);
      } else if (doneMessage != null) {
        // Use done message format for errors too if no specific error message
        terminal.clearLine();
        terminal.writeln(doneMessage);
      } else {
        terminal.writeln();
      }

      rethrow;
    } finally {
      terminal.showCursor();
    }
  }

  void _renderSpinnerFrame(String frame, String message, Duration elapsed) {
    final elapsedStr = _formatDuration(elapsed);
    // Move to start of line, write content, then clear any leftover chars.
    // This avoids the flash caused by clearLine() which clears before writing.
    terminal.cursorToColumn(1);
    terminal.write('$frame $message ${Style().dim().render(elapsedStr)}');
    terminal.clearLineToEnd();
  }

  /// Runs a progress bar animation while executing a task.
  ///
  /// The [task] receives a callback to update progress (0.0 to 1.0).
  ///
  /// Parameters:
  /// - [message]: Text to display with the progress bar
  /// - [task]: Async function that receives a progress updater
  /// - [clearOnDone]: If true, clear the line after completion
  /// - [doneMessage]: Optional message to show after completion
  /// - [width]: Width of the progress bar (default: auto-fit to terminal)
  ///
  /// Returns the result of [task].
  Future<T> progress<T>({
    required String message,
    required FutureOr<T> Function(void Function(double progress) setProgress)
    task,
    bool clearOnDone = false,
    String? doneMessage,
    int? width,
  }) async {
    // Calculate bar width to fit terminal
    // Format: "message [====] 100% 1.2s"
    // Reserve: message + space + brackets (2) + space + "100%" (4) + space + "999ms" (5) + buffer
    final termWidth = terminal.width;
    final reserved = message.length + 1 + 2 + 1 + 4 + 1 + 6;
    final barWidth = width ?? (termWidth - reserved).clamp(10, 40);

    var currentProgress = 0.0;
    final watch = Stopwatch()..start();

    terminal.hideCursor();

    void updateProgress(double progress) {
      currentProgress = progress.clamp(0.0, 1.0);
      _renderProgressFrame(message, currentProgress, watch.elapsed, barWidth);
    }

    try {
      // Render initial state
      _renderProgressFrame(message, 0.0, Duration.zero, barWidth);

      // Execute task with progress callback
      final result = await task(updateProgress);

      watch.stop();

      // Handle completion
      if (clearOnDone && doneMessage == null) {
        terminal.clearLine();
      } else if (doneMessage != null) {
        terminal.clearLine();
        terminal.writeln(doneMessage);
      } else {
        // Render final 100% state
        _renderProgressFrame(message, 1.0, watch.elapsed, barWidth);
        terminal.writeln();
      }

      return result;
    } catch (e) {
      watch.stop();

      if (clearOnDone && doneMessage == null) {
        terminal.clearLine();
      } else if (doneMessage != null) {
        terminal.clearLine();
        terminal.writeln(doneMessage);
      } else {
        terminal.writeln();
      }

      rethrow;
    } finally {
      terminal.showCursor();
    }
  }

  void _renderProgressFrame(
    String message,
    double progress,
    Duration elapsed,
    int width,
  ) {
    final percent = (progress * 100).round();
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '[${Style().bold().render('=' * filled)}${' ' * empty}]';
    final elapsedStr = _formatDuration(elapsed);

    // Move to start of line, write content, then clear any leftover chars.
    // This avoids the flash caused by clearLine() which clears before writing.
    terminal.cursorToColumn(1);
    terminal.write(
      '$message $bar $percent% ${Style().dim().render(elapsedStr)}',
    );
    terminal.clearLineToEnd();
  }

  /// Iterates over items while showing a progress bar.
  ///
  /// This is a synchronous generator that yields items from [items] while
  /// updating a progress bar.
  ///
  /// Parameters:
  /// - [items]: Items to iterate over
  /// - [message]: Optional message to display
  /// - [total]: Total count (if items doesn't have a length)
  /// - [clearOnDone]: If true, clear the progress bar after iteration
  /// - [doneMessage]: Optional message to show after completion
  /// - [width]: Width of the progress bar (default: auto-fit to terminal)
  ///
  /// Yields each item from [items].
  Iterable<T> progressIterate<T>(
    Iterable<T> items, {
    String? message,
    int? total,
    bool clearOnDone = false,
    String? doneMessage,
    int? width,
  }) sync* {
    final itemList = items is List<T> ? items : items.toList();
    final count = total ?? itemList.length;
    if (count == 0) return;

    // Calculate bar width to fit terminal
    final msg = message ?? '';
    final termWidth = terminal.width;
    final reserved = msg.length + 1 + 2 + 1 + 4 + 1 + 6;
    final barWidth = width ?? (termWidth - reserved).clamp(10, 40);

    final watch = Stopwatch()..start();
    var current = 0;

    terminal.hideCursor();

    try {
      for (final item in itemList) {
        final progress = count > 0 ? current / count : 0.0;
        _renderProgressFrame(msg, progress, watch.elapsed, barWidth);

        yield item;
        current++;
      }

      watch.stop();

      // Handle completion
      if (clearOnDone && doneMessage == null) {
        terminal.clearLine();
      } else if (doneMessage != null) {
        terminal.clearLine();
        terminal.writeln(doneMessage);
      } else {
        // Render final 100% state
        _renderProgressFrame(msg, 1.0, watch.elapsed, barWidth);
        terminal.writeln();
      }
    } finally {
      terminal.showCursor();
    }
  }

  /// Runs multiple tasks sequentially with a spinner for each.
  ///
  /// Each task is displayed with its message and a spinner. Results are
  /// collected and returned as a list.
  ///
  /// Parameters:
  /// - [tasks]: List of (message, task) pairs to execute
  /// - [spinner]: Spinner animation to use
  /// - [clearOnDone]: If true, clear each task's line after completion
  /// - [showCheckmarks]: If true, show ✓/✗ for each completed task
  ///
  /// Returns list of results from all tasks.
  Future<List<T>> spinAll<T>({
    required List<(String message, FutureOr<T> Function() task)> tasks,
    Spinner spinner = Spinners.miniDot,
    bool clearOnDone = false,
    bool showCheckmarks = true,
  }) async {
    final results = <T>[];

    for (final (message, task) in tasks) {
      try {
        final result = await spin(
          message: message,
          task: task,
          spinner: spinner,
          clearOnDone: clearOnDone,
          doneMessage: showCheckmarks && !clearOnDone
              ? '${Style().foreground(Colors.success).render(StatusChars.check)} $message'
              : null,
        );
        results.add(result);
      } catch (e) {
        if (showCheckmarks && !clearOnDone) {
          terminal.clearLine();
          terminal.writeln(
            '${Style().foreground(Colors.error).render(StatusChars.cross)} $message',
          );
        }
        rethrow;
      }
    }

    return results;
  }
}

String _formatDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms < 1000) return '${ms}ms';
  final seconds = ms / 1000;
  return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s';
}
