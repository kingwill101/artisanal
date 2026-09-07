import 'dart:async';

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
