import 'dart:async';

import '../style/chars.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../tui/bubbles/spinner.dart';
import 'console_context.dart';
import 'console_format.dart';
import 'console_presentation.dart';
import 'inline_animation.dart';
import 'operation_results.dart';

/// Shared implementation of interactive console operations.
///
/// Public facades such as `Console` and `Components` delegate here so activity
/// lifecycle, fallback behavior, and presentation have one source of truth.
final class ConsoleOperations {
  /// Creates operations backed by [host].
  ConsoleOperations(this.host);

  /// Console capabilities and output used by these operations.
  final ConsoleOperationHost host;

  /// Displays a dotted task line with an optional animated running state.
  Future<TaskResult> task(
    String description, {
    FutureOr<TaskResult> Function()? run,
    bool clearOnDone = false,
  }) async {
    final descriptionText = description.trimRight();
    final prefix = '  $descriptionText ';
    final terminal = host.promptTerminal;
    final animate =
        run != null &&
        supportsInteractiveConsole(host.interactive, () => terminal);
    final width = terminal.width;

    if (animate) {
      terminal.hideCursor();
    } else {
      host.write(prefix);
    }

    final watch = Stopwatch()..start();
    var result = TaskResult.success;
    Timer? timer;
    var spinnerTick = 0;
    try {
      if (animate) {
        const frames = ['|', '/', '-', '\\'];
        timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
          final frame = frames[spinnerTick % frames.length];
          spinnerTick++;
          final elapsed = _muted(' ${formatConsoleDuration(watch.elapsed)}');
          final used =
              Style.visibleLength(prefix) + Style.visibleLength(elapsed);
          final dotsLength = (width - used - 2).clamp(0, width);
          var dots = '.' * dotsLength;
          if (dotsLength > 0) {
            final index = spinnerTick % dotsLength;
            dots =
                '${dots.substring(0, index)}$frame${dots.substring(index + 1)}';
          }
          terminal.clearLine();
          terminal.write('$prefix${_muted(dots)}$elapsed');
        });
      }

      result = await (run?.call() ?? TaskResult.success);
      return result;
    } catch (_) {
      result = TaskResult.failure;
      rethrow;
    } finally {
      watch.stop();
      timer?.cancel();
      if (animate) terminal.clearLine();

      if (!clearOnDone) {
        final elapsed = run == null
            ? ''
            : ' ${formatConsoleDuration(watch.elapsed)}';
        final status = _taskStatus(result);
        final used =
            2 +
            Style.visibleLength(descriptionText) +
            1 +
            Style.visibleLength(elapsed) +
            1 +
            4;
        final dots = (width - used).clamp(0, width);
        final suffix =
            '${_muted('.' * dots)}${elapsed.isEmpty ? '' : _muted(elapsed)} $status';
        if (animate) {
          terminal
            ..write('$prefix$suffix')
            ..writeln();
        } else {
          host.writeln(suffix);
        }
      }
      if (animate) terminal.showCursor();
    }
  }

  /// Runs a sequential group of named operations.
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

    final interactive = supportsInteractiveConsole(
      host.interactive,
      () => host.promptTerminal,
    );
    final watch = Stopwatch()..start();
    if (title != null) host.writeln(_baseStyle().bold().render(title));

    final completed = <String>[];
    final failed = <(String, Object)>[];
    final skipped = <String>[];
    var hadError = false;

    for (var index = 0; index < tasks.length; index++) {
      final (description, operation) = tasks[index];
      if (hadError && !continueOnError) {
        skipped.add(description);
        host.writeln(
          '  ${_muted(PaginationDots.inactive)} $description ${_muted('(skipped)')}',
        );
        continue;
      }

      if (interactive) {
        try {
          await spin(
            description,
            run: operation,
            spinner: spinner,
            showResult: true,
          );
          completed.add(description);
        } catch (error) {
          failed.add((description, error));
          hadError = true;
          if (!continueOnError) {
            for (
              var remaining = index + 1;
              remaining < tasks.length;
              remaining++
            ) {
              skipped.add(tasks[remaining].$1);
            }
            break;
          }
        }
      } else {
        host.write('  $description... ');
        try {
          await operation();
          host.writeln(_styleFor('success').render('done'));
          completed.add(description);
        } catch (error) {
          host.writeln(_styleFor('error').render('failed'));
          failed.add((description, error));
          hadError = true;
          if (!continueOnError) {
            for (
              var remaining = index + 1;
              remaining < tasks.length;
              remaining++
            ) {
              skipped.add(tasks[remaining].$1);
            }
            break;
          }
        }
      }
    }

    watch.stop();
    if (title != null) {
      host.newLine();
      final summary = failed.isEmpty
          ? 'Completed ${completed.length} task(s) in ${formatConsoleDuration(watch.elapsed)}'
          : 'Completed ${completed.length}, failed ${failed.length}, skipped ${skipped.length} in ${formatConsoleDuration(watch.elapsed)}';
      host.writeln(
        _styleFor(failed.isEmpty ? 'success' : 'warning').render(summary),
      );
    }

    return TaskGroupResult(
      completed: completed,
      failed: failed,
      skipped: skipped,
      duration: watch.elapsed,
    );
  }

  /// Runs an operation while displaying a spinner or a plain fallback.
  Future<T> spin<T>(
    String message, {
    required FutureOr<T> Function() run,
    Spinner spinner = Spinners.miniDot,
    bool clearOnDone = false,
    bool showResult = true,
    String? doneMessage,
  }) async {
    if (!supportsInteractiveConsole(
      host.interactive,
      () => host.promptTerminal,
    )) {
      host.write('$message ');
      final watch = Stopwatch()..start();
      try {
        final result = await run();
        watch.stop();
        if (doneMessage != null && !clearOnDone) {
          host.writeln(doneMessage);
        } else if (showResult && !clearOnDone) {
          host.writeln(
            '${_styleFor('success').render('✓')}${_muted(' ${formatConsoleDuration(watch.elapsed)}')}',
          );
        } else if (!clearOnDone) {
          host.writeln();
        }
        return result;
      } catch (_) {
        watch.stop();
        if (showResult && !clearOnDone) {
          host.writeln(
            '${_styleFor('error').render('✗')}${_muted(' ${formatConsoleDuration(watch.elapsed)}')}',
          );
        } else if (!clearOnDone) {
          host.writeln();
        }
        rethrow;
      }
    }

    return InlineAnimation(terminal: host.promptTerminal).spin(
      message: message,
      task: run,
      spinner: spinner,
      clearOnDone: clearOnDone,
      doneMessage: doneMessage,
      successMessage: doneMessage == null && showResult && !clearOnDone
          ? (_, elapsed) =>
                '${_styleFor('success').render('✓')} $message ${_muted(formatConsoleDuration(elapsed))}'
          : null,
      failureMessage: showResult && !clearOnDone
          ? (_, elapsed) =>
                '${_styleFor('error').render('✗')} $message ${_muted(formatConsoleDuration(elapsed))}'
          : null,
    );
  }

  /// Runs an operation with an inline progress callback.
  Future<T> progress<T>(
    String message, {
    required FutureOr<T> Function(void Function(double) setProgress) run,
    bool clearOnDone = false,
    String? doneMessage,
  }) {
    return InlineAnimation(terminal: host.promptTerminal).progress(
      message: message,
      task: run,
      clearOnDone: clearOnDone,
      doneMessage: doneMessage,
    );
  }

  String _muted(String text) => _styleFor('muted').render(text);

  Style _baseStyle() => host.renderConfig.configureStyle(Style());

  String _taskStatus(TaskResult result) {
    final (role, fallback, label) = switch (result) {
      TaskResult.success => ('success', Colors.success, 'DONE'),
      TaskResult.skipped => ('warning', Colors.warning, 'SKIPPED'),
      TaskResult.failure => ('error', Colors.error, 'FAIL'),
    };
    final style =
        host.getStyle(role) ??
        (host.renderConfig.configureStyle(Style())
          ..bold()
          ..foreground(fallback));
    return style.render(label);
  }

  Style _styleFor(String role) {
    final themed = switch (role) {
      'success' => host.componentTheme.successStyle(host.renderConfig),
      'error' => host.componentTheme.errorStyle(host.renderConfig),
      _ => host.componentTheme.mutedStyle(host.renderConfig),
    };
    return resolveConsoleComponentStyle(themed, host.getStyle(role));
  }
}
