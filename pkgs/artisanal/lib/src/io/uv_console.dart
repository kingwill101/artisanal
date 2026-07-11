import 'dart:async';

import '../style/chars.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../tui/bubbles/spinner.dart';
import '../tui/cmd.dart';
import '../tui/key.dart';
import '../tui/msg.dart';
import '../tui/model.dart';
import '../tui/program.dart';
import '../tui/view.dart' show View;
import 'console.dart';
import 'output_theme.dart';

/// Result of a UV console animation.
class UVAnimationResult<T> {
  const UVAnimationResult({
    required this.value,
    required this.duration,
    this.error,
  });

  final T? value;
  final Duration duration;
  final Object? error;

  bool get success => error == null;
}

/// UV-powered inline console for professional CLI output.
///
/// This class provides spinner and progress animations using the UV
/// (Ultraviolet) renderer in inline mode, which:
/// - Preserves scrollback above the UI
/// - Uses buffer diffing for efficient updates
/// - Supports professional-grade styling
///
/// ## Usage
///
/// ```dart
/// // Spinner
/// await UVConsole.spin('Loading...', task: () => fetchData());
///
/// // Progress bar
/// await UVConsole.progress('Downloading', (setProgress) async {
///   for (var i = 0; i <= 100; i++) {
///     await Future.delayed(Duration(milliseconds: 50));
///     setProgress(i / 100);
///   }
/// });
/// ```
class UVConsole {
  UVConsole._();

  /// Default console instance used if none is provided.
  static final _defaultIo = Console();

  static ProgramOptions _optionsWithAnchor(UiAnchor anchor) {
    return ProgramOptions(
      screenMode: ScreenMode.inline,
      inlineHeight: 3,
      uiAnchor: anchor,
      fps: 20,
      hideCursor: true,
      startupProbes: false,
    );
  }

  /// Shows a spinner while running a task.
  ///
  /// [message] - Text to display next to the spinner
  /// [task] - The async task to run
  /// [spinner] - Spinner style (default: miniDot)
  /// [anchor] - UI anchor position (default: bottom)
  /// [io] - Optional console instance to use for theme and output
  static Future<T> spin<T>(
    String message, {
    required FutureOr<T> Function() task,
    Spinner spinner = Spinners.miniDot,
    UiAnchor anchor = UiAnchor.bottom,
    Console? io,
  }) async {
    final console = io ?? _defaultIo;
    final watch = Stopwatch()..start();
    final completer = Completer<T>();

    final model = _SpinModel(
      message: message,
      spinner: spinner,
      theme: console.outputTheme,
      onComplete: (result) {
        watch.stop();
        completer.complete(result);
      },
      onError: (error) {
        watch.stop();
        completer.completeError(error);
      },
    );

    try {
      await runProgram(model, options: _optionsWithAnchor(anchor));
    } catch (e) {
      // Handled via model callbacks
    }

    return completer.future;
  }

  /// Shows a progress bar while running a task.
  ///
  /// [message] - Text to display with the progress bar
  /// [task] - The async task, receives a setProgress callback
  /// [anchor] - UI anchor position (default: bottom)
  /// [io] - Optional console instance to use for theme and output
  static Future<T> progress<T>(
    String message, {
    required FutureOr<T> Function(void Function(double) setProgress) task,
    UiAnchor anchor = UiAnchor.bottom,
    Console? io,
  }) async {
    final console = io ?? _defaultIo;
    final watch = Stopwatch()..start();
    final completer = Completer<T>();
    final progressController = _ProgressController();

    final model = _ProgressModel(
      message: message,
      progressController: progressController,
      theme: console.outputTheme,
      onComplete: (result) {
        watch.stop();
        completer.complete(result);
      },
      onError: (error) {
        watch.stop();
        completer.completeError(error);
      },
    );

    try {
      final result = await task(progressController.setProgress);
      model.onComplete(result);
    } catch (e) {
      model.onError(e);
    }

    return completer.future;
  }

  /// Runs multiple tasks with spinners.
  static Future<List<T>> spinAll<T>(
    List<(String, FutureOr<T> Function())> tasks, {
    Spinner spinner = Spinners.miniDot,
    bool showCheckmarks = true,
    UiAnchor anchor = UiAnchor.bottom,
    Console? io,
  }) async {
    final console = io ?? _defaultIo;
    final results = <T>[];

    for (final (message, task) in tasks) {
      try {
        final result = await spin(
          message,
          task: task,
          spinner: spinner,
          anchor: anchor,
          io: console,
        );
        results.add(result);
        if (showCheckmarks) {
          final check =
              (console.getStyle('success') ??
                      Style().foreground(Colors.success))
                  .render(StatusChars.check);
          print('$check $message');
        }
      } catch (e) {
        if (showCheckmarks) {
          final cross =
              (console.getStyle('error') ?? Style().foreground(Colors.error))
                  .render(StatusChars.cross);
          print('$cross $message');
        }
        rethrow;
      }
    }

    return results;
  }
}

class _ProgressController {
  final _controller = StreamController<double>.broadcast();

  void setProgress(double value) {
    _controller.add(value.clamp(0.0, 1.0));
  }

  Stream<double> get stream => _controller.stream;
}

class _SpinModel implements Model {
  _SpinModel({
    required this.message,
    required this.spinner,
    required this.onComplete,
    required this.onError,
    required this.theme,
    this.frameIndex = 0,
  });

  final String message;
  final Spinner spinner;
  final void Function(dynamic) onComplete;
  final void Function(Object) onError;
  final OutputTheme theme;
  int frameIndex;

  @override
  Cmd? init() =>
      Cmd.tick(const Duration(milliseconds: 100), (_) => _SpinTick());

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      _SpinTick() => (
        _SpinModel(
          message: message,
          spinner: spinner,
          theme: theme,
          onComplete: onComplete,
          onError: onError,
          frameIndex: (frameIndex + 1) % spinner.frames.length,
        ),
        Cmd.tick(const Duration(milliseconds: 100), (_) => _SpinTick()),
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  View view() {
    final frame = spinner.frames.isNotEmpty
        ? spinner.frames[frameIndex.clamp(0, spinner.frames.length - 1)]
        : Circles.filled;
    final frameStyled = (theme.info != null)
        ? Style().foreground(theme.info!).render(frame)
        : frame;
    final mutedStyle = theme.muted != null
        ? Style().foreground(theme.muted!)
        : Style().dim();
    return View(
      content:
          '$frameStyled $message\n\n${mutedStyle.render('Press q or Esc to quit')}',
    );
  }
}

class _SpinTick extends Msg {
  const _SpinTick();
}

class _ProgressModel implements Model {
  _ProgressModel({
    required this.message,
    required this.progressController,
    required this.onComplete,
    required this.onError,
    required this.theme,
  });

  final String message;
  final _ProgressController progressController;
  final void Function(dynamic) onComplete;
  final void Function(Object) onError;
  final OutputTheme theme;
  final double progress = 0.0;

  @override
  Cmd? init() {
    progressController.stream.listen((_) {});
    return every(const Duration(milliseconds: 100), (_) => _ProgressTick());
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      _ProgressTick() => (this, null),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  View view() {
    final percent = (progress * 100).round();
    const barWidth = 20;
    final filled = (progress * barWidth).round();
    final empty = barWidth - filled;
    final barStyle = theme.info != null
        ? Style().foreground(theme.info!)
        : Style();
    final bar = '[${barStyle.bold().render('=' * filled)}${' ' * empty}]';
    final mutedStyle = theme.muted != null
        ? Style().foreground(theme.muted!)
        : Style().dim();
    return View(
      content:
          '$message $bar $percent%\n\n${mutedStyle.render('Press q or Esc to quit')}',
    );
  }
}

class _ProgressTick extends Msg {
  const _ProgressTick();
}
