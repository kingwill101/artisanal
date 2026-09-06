import '../style/color.dart';
import 'cmd.dart';
import 'degradation.dart';
import 'msg.dart';
import 'package:ultraviolet/ultraviolet.dart' hide MouseMode;

/// A rectangular region in a structured terminal [Frame].
///
/// Coordinates are zero-based and relative to the frame's viewport.
final class FrameArea {
  /// Creates an area from its origin and dimensions.
  const FrameArea(this.x, this.y, this.width, this.height);

  /// Horizontal origin.
  final int x;

  /// Vertical origin.
  final int y;

  /// Width in terminal cells.
  final int width;

  /// Height in terminal cells.
  final int height;

  /// The first column outside this area.
  int get right => x + width;

  /// The first row outside this area.
  int get bottom => y + height;

  /// Whether this area has no drawable cells.
  bool get isEmpty => width <= 0 || height <= 0;

  /// Returns the overlap between this area and [other].
  FrameArea intersect(FrameArea other) {
    final left = x > other.x ? x : other.x;
    final top = y > other.y ? y : other.y;
    final clippedRight = right < other.right ? right : other.right;
    final clippedBottom = bottom < other.bottom ? bottom : other.bottom;
    final clippedWidth = clippedRight - left;
    final clippedHeight = clippedBottom - top;
    return FrameArea(
      left,
      top,
      clippedWidth > 0 ? clippedWidth : 0,
      clippedHeight > 0 ? clippedHeight : 0,
    );
  }

  /// Returns this area with the given edge insets removed.
  ///
  /// Insets that consume more than the available size produce an empty area
  /// anchored within this area's bottom-right edge.
  FrameArea inset({int left = 0, int top = 0, int right = 0, int bottom = 0}) {
    if (left < 0 || top < 0 || right < 0 || bottom < 0) {
      throw ArgumentError('FrameArea insets must not be negative');
    }
    final insetX = left.clamp(0, width);
    final insetY = top.clamp(0, height);
    final insetWidth = width - left - right;
    final insetHeight = height - top - bottom;
    return FrameArea(
      x + insetX,
      y + insetY,
      insetWidth > 0 ? insetWidth : 0,
      insetHeight > 0 ? insetHeight : 0,
    );
  }

  /// Returns an area of at most [width] by [height], centered within this area.
  FrameArea centered({required int width, required int height}) {
    if (width < 0 || height < 0) {
      throw ArgumentError('Centered dimensions must not be negative');
    }
    final centeredWidth = width.clamp(0, this.width);
    final centeredHeight = height.clamp(0, this.height);
    return FrameArea(
      x + (this.width - centeredWidth) ~/ 2,
      y + (this.height - centeredHeight) ~/ 2,
      centeredWidth,
      centeredHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FrameArea &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'FrameArea($x, $y, $width, $height)';
}

/// A value that can paint itself directly into a terminal [Frame].
///
/// Implementations should be short-lived descriptions of the current model
/// state. Persistent application state belongs in the TEA [Model], not in the
/// renderable.
abstract interface class FrameRenderable {
  /// Paints this value into [area], clipped to the frame bounds.
  void render(Frame frame, FrameArea area);
}

/// Positioned string composition for one immediate-mode render pass.
///
/// A frame is created after the terminal viewport has been sized and cleared.
/// Content passed to [write] may include ANSI styling produced by Artisanal's
/// `Style.render`. The renderer owns conversion to terminal cells.
///
/// {@category TUI}
abstract interface class Frame {
  /// The drawable viewport for this frame.
  FrameArea get area;

  /// Writes plain or ANSI-styled [content] into a positioned region.
  ///
  /// The region is clipped to [area]. When [target] is omitted, content is
  /// written into the complete frame.
  void write(String content, {FrameArea? target, bool wrap = true});

  /// Paints [renderable] into [target], clipped to this frame's viewport.
  void render(FrameRenderable renderable, FrameArea target);
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

/// A [View] that composes styled strings into positioned terminal regions.
///
/// [FrameView] is the immediate-mode rendering path for foundational TEA
/// applications. The runtime creates a cleared [Frame] at the current viewport
/// size and invokes [paint] once per rendered model state.
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
