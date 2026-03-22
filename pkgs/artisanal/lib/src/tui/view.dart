import '../style/color.dart';
import 'cmd.dart';
import 'degradation.dart';
import 'msg.dart';
import '../uv/uv.dart' hide MouseMode;

/// TerminalProgressBarState represents the state of the terminal taskbar progress.
enum TerminalProgressBarState {
  none,
  defaultState,
  error,
  indeterminate,
  warning,
}

/// TerminalProgressBar represents the terminal taskbar progress (OSC 9;4).
///
/// Support depends on the terminal (e.g., Windows Terminal, iTerm2).
class TerminalProgressBar {
  const TerminalProgressBar({required this.state, this.value = 0});

  /// The current state of the progress bar.
  final TerminalProgressBarState state;

  /// The current value of the progress bar (0-100).
  final int value;
}

/// View represents a terminal view that can contain metadata for terminal control.
///
/// This allows the [Model.view] method to return more than just a string,
/// enabling declarative control over terminal state like cursor position,
/// window title, and mouse tracking.
///
/// {@category TUI}
///
/// {@macro artisanal_tui_tea_overview}
class View {
  const View({
    required this.content,
    this.onMouse,
    this.cursor,
    this.backgroundColor,
    this.foregroundColor,
    this.windowTitle,
    this.progressBar,
    this.altScreen,
    this.reportFocus,
    this.bracketedPaste,
    this.mouseMode,
    this.keyboardEnhancements,
    this.degradation,
  });

  /// The screen content of the view.
  final String content;

  /// Optional mouse message handler that can be used to intercept mouse messages.
  final Cmd? Function(MouseMsg msg)? onMouse;

  /// Optional cursor position and style.
  final Cursor? cursor;

  /// Optional terminal background color.
  final Color? backgroundColor;

  /// Optional terminal foreground color.
  final Color? foregroundColor;

  /// Optional terminal window title.
  ///
  /// When omitted, the runtime falls back to [ProgramOptions.startupTitle] if
  /// one was configured for the program.
  final String? windowTitle;

  /// Optional terminal progress bar state.
  final TerminalProgressBar? progressBar;

  /// Optional override for alternate screen buffer mode.
  final bool? altScreen;

  /// Optional override for focus reporting.
  final bool? reportFocus;

  /// Optional override for bracketed paste mode.
  final bool? bracketedPaste;

  /// Optional override for mouse tracking mode.
  final MouseMode? mouseMode;

  /// Optional keyboard enhancement features to request from the terminal.
  final KeyboardEnhancements? keyboardEnhancements;

  /// Optional degraded content stages used by the runtime when render frames
  /// exceed the configured budget.
  final ViewDegradation? degradation;

  /// Returns this view resolved for the given degradation [level].
  View degraded(DegradationLevel level) {
    if (level == DegradationLevel.full || degradation == null) return this;
    return View(
      content: degradation!.resolve(content, level),
      onMouse: onMouse,
      cursor: cursor,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      windowTitle: windowTitle,
      progressBar: progressBar,
      altScreen: altScreen,
      reportFocus: reportFocus,
      bracketedPaste: bracketedPaste,
      mouseMode: mouseMode,
      keyboardEnhancements: keyboardEnhancements,
      degradation: degradation,
    );
  }

  @override
  String toString() => 'View(content: ${content.length} chars)';
}

/// KeyboardEnhancements describes the requested keyboard enhancement features.
class KeyboardEnhancements {
  const KeyboardEnhancements({this.reportEventTypes = false});

  /// Whether to request the terminal to report key repeat and release events.
  final bool reportEventTypes;
}
