import 'dart:async';

import '../style/style.dart';
import '../tui/bubbles/spinner.dart';
import 'console_context.dart';
import 'console_format.dart';
import 'console_presentation.dart';
import 'inline_animation.dart';

/// Shared implementation of interactive console operations.
///
/// Public facades such as `Console` and `Components` delegate here so activity
/// lifecycle, fallback behavior, and presentation have one source of truth.
final class ConsoleOperations {
  /// Creates operations backed by [host].
  ConsoleOperations(this.host);

  /// Console capabilities and output used by these operations.
  final ConsoleOperationHost host;

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

  Style _styleFor(String role) {
    final themed = switch (role) {
      'success' => host.componentTheme.successStyle(host.renderConfig),
      'error' => host.componentTheme.errorStyle(host.renderConfig),
      _ => host.componentTheme.mutedStyle(host.renderConfig),
    };
    return resolveConsoleComponentStyle(themed, host.getStyle(role));
  }
}
