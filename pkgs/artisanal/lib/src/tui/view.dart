import '../style/color.dart';
import 'cmd.dart';
import 'degradation.dart';
import 'msg.dart';
import 'package:ultraviolet/ultraviolet.dart' hide MouseMode;

/// A value that can paint itself directly into a terminal [Frame].
///
/// Implementations should be short-lived descriptions of the current model
/// state. Persistent application state belongs in the TEA [Model], not in the
/// renderable.
abstract interface class FrameRenderable {
  /// Paints this value into [area], clipped to the frame bounds.
  void render(Frame frame, Rectangle area);
}

/// The mutable cell target for one immediate-mode render pass.
///
/// A frame is created by the Ultraviolet renderer after the terminal viewport
/// has been sized and cleared. Use [screen] for low-level cell operations or
/// [render] to compose [FrameRenderable] values.
///
/// {@category TUI}
final class Frame {
  /// Creates a frame over [screen] restricted to [area].
  const Frame({required this.screen, required this.area});

  /// The cell surface receiving this frame.
  final Screen screen;

  /// The drawable viewport for this frame.
  final Rectangle area;

  /// Paints [renderable] into [area], clipped to this frame's viewport.
  void render(FrameRenderable renderable, Rectangle area) {
    final clipped = this.area.intersect(area);
    if (clipped.isEmpty) return;
    renderable.render(this, clipped);
  }
}

/// Signature used by [FrameView] to paint a structured terminal frame.
typedef FramePainter = void Function(Frame frame);

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

/// A [View] that paints cells directly instead of parsing an ANSI string.
///
/// [FrameView] is the immediate-mode rendering path for foundational TEA
/// applications. The runtime creates a cleared [Frame] at the current terminal
/// size and invokes [paint] once per rendered model state. Ultraviolet then
/// diffs the resulting cell buffer as usual.
///
/// [content] is an optional fallback used by renderers that do not support
/// structured frames. It is not parsed by [UltravioletTuiRenderer].
///
/// {@category TUI}
final class FrameView extends View {
  /// Creates a structured cell view.
  const FrameView({
    required this.paint,
    super.content = '',
    super.onMouse,
    super.cursor,
    super.backgroundColor,
    super.foregroundColor,
    super.windowTitle,
    super.progressBar,
    super.altScreen,
    super.reportFocus,
    super.bracketedPaste,
    super.mouseMode,
    super.keyboardEnhancements,
    super.degradation,
  });

  /// Paints the current model state into a frame.
  final FramePainter paint;

  @override
  FrameView degraded(DegradationLevel level) {
    if (level == DegradationLevel.full || degradation == null) return this;
    return FrameView(
      paint: paint,
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
  String toString() => 'FrameView(fallback: ${content.length} chars)';
}

/// KeyboardEnhancements describes the requested keyboard enhancement features.
class KeyboardEnhancements {
  const KeyboardEnhancements({this.reportEventTypes = false});

  /// Whether to request the terminal to report key repeat and release events.
  final bool reportEventTypes;
}
