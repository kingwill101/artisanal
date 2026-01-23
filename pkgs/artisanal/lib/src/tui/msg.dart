import '../style/color.dart';
import '../uv/terminal_renderer.dart' show RenderMetrics;
import 'key.dart';

/// Base class for all messages in the TUI runtime.
///
/// Messages represent events that can trigger state updates in a [Model].
/// All message types should extend this class.
///
/// {@category TUI}
///
/// {@macro artisanal_tui_commands_and_messages}
///
/// ## Built-in Message Types
///
/// - [KeyMsg] - Keyboard input events
/// - [MouseMsg] - Mouse events (clicks, motion, wheel)
/// - [WindowSizeMsg] - Terminal resize events
/// - [TickMsg] - Timer tick events
/// - [QuitMsg] - Internal quit signal
/// - [BatchMsg] - Multiple messages bundled together
///
/// ## Custom Messages
///
/// Create custom message types by extending [Msg]:
///
/// ```dart
/// class DataLoadedMsg extends Msg {
///   final List<String> items;
///   DataLoadedMsg(this.items);
/// }
///
/// class ErrorMsg extends Msg {
///   final String message;
///   ErrorMsg(this.message);
/// }
/// ```
abstract class Msg {
  const Msg();
}

/// Message sent when a key is pressed.
///
/// Contains the parsed [Key] with information about:
/// - The type of key (character, special key, function key)
/// - Modifier keys held (Ctrl, Alt, Shift)
///
/// ## Example
///
/// ```dart
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     KeyMsg(key: Key(type: KeyType.up)) => (moveUp(), null),
///     KeyMsg(key: Key(type: KeyType.down)) => (moveDown(), null),
///     KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()), // 'q'
///     KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()), // Ctrl+C
///     _ => (this, null),
///   };
/// }
/// ```
class KeyMsg extends Msg {
  /// Creates a key message.
  const KeyMsg(this.key);

  /// The parsed key information.
  final Key key;

  @override
  String toString() => 'KeyMsg($key)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KeyMsg && key == other.key);

  @override
  int get hashCode => key.hashCode;
}

/// Message sent when the terminal window is resized.
///
/// Contains the new dimensions of the terminal in columns (width)
/// and rows (height).
///
/// ## Example
///
/// ```dart
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     WindowSizeMsg(:final width, :final height) =>
///       (copyWith(termWidth: width, termHeight: height), null),
///     _ => (this, null),
///   };
/// }
/// ```
class WindowSizeMsg extends Msg {
  /// Creates a window size message.
  const WindowSizeMsg(this.width, this.height);

  /// The terminal width in columns.
  final int width;

  /// The terminal height in rows.
  final int height;

  @override
  String toString() => 'WindowSizeMsg($width x $height)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WindowSizeMsg &&
          width == other.width &&
          height == other.height);

  @override
  int get hashCode => Object.hash(width, height);
}

/// Message sent when a timer tick occurs.
///
/// Created by [Cmd.tick] or [Cmd.every] commands.
/// Contains the time when the tick occurred and an optional
/// identifier for distinguishing between multiple timers.
///
/// ## Example
///
/// ```dart
/// @override
/// Cmd? init() => Cmd.tick(Duration(seconds: 1), (_) => TickMsg(DateTime.now()));
///
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     TickMsg(:final time) => (
///       copyWith(lastTick: time),
///       Cmd.tick(Duration(seconds: 1), (_) => TickMsg(DateTime.now())),
///     ),
///     _ => (this, null),
///   };
/// }
/// ```
class TickMsg extends Msg {
  /// Creates a tick message.
  const TickMsg(this.time, {this.id});

  /// The time when the tick occurred.
  final DateTime time;

  /// Optional identifier for the timer.
  final Object? id;

  @override
  String toString() => 'TickMsg($time${id != null ? ', id: $id' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TickMsg && time == other.time && id == other.id);

  @override
  int get hashCode => Object.hash(time, id);
}

/// Message sent automatically by the TUI runtime every frame.
///
/// When [ProgramOptions.frameTick] is enabled (default), the runtime
/// sends this message at the configured [ProgramOptions.fps] rate.
/// This drives animations and continuous updates without requiring
/// each application to set up its own tick loop.
///
/// The message contains:
/// - [time] - When the frame tick occurred
/// - [frameNumber] - Monotonically increasing frame counter
/// - [delta] - Time since the last frame (useful for smooth animations)
///
/// ## Example
///
/// ```dart
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     FrameTickMsg(:final time, :final delta) => (
///       copyWith(
///         animationProgress: animationProgress + delta.inMilliseconds / 1000.0,
///         lastFrameTime: time,
///       ),
///       null,
///     ),
///     _ => (this, null),
///   };
/// }
/// ```
///
/// ## Disabling Frame Ticks
///
/// For static UIs that don't need continuous updates, disable frame ticks:
///
/// ```dart
/// final program = Program(
///   MyModel(),
///   options: ProgramOptions(frameTick: false),
/// );
/// ```
class FrameTickMsg extends Msg {
  /// Creates a frame tick message.
  const FrameTickMsg({
    required this.time,
    required this.frameNumber,
    required this.delta,
  });

  /// The time when this frame tick occurred.
  final DateTime time;

  /// Monotonically increasing frame counter.
  final int frameNumber;

  /// Duration since the last frame tick.
  ///
  /// Useful for frame-rate-independent animations.
  final Duration delta;

  @override
  String toString() =>
      'FrameTickMsg(frame: $frameNumber, delta: ${delta.inMilliseconds}ms)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrameTickMsg &&
          time == other.time &&
          frameNumber == other.frameNumber &&
          delta == other.delta);

  @override
  int get hashCode => Object.hash(time, frameNumber, delta);
}

/// Internal message signaling that the program should quit.
///
/// This is typically not created directly. Instead, use [Cmd.quit()]
/// which triggers the quit sequence properly.
class QuitMsg extends Msg {
  /// Creates a quit message.
  const QuitMsg();

  @override
  String toString() => 'QuitMsg()';
}

/// Message containing multiple messages to be processed sequentially.
///
/// Used internally by the runtime for batching messages together.
class BatchMsg extends Msg {
  /// Creates a batch message.
  const BatchMsg(this.messages);

  /// The list of messages to process.
  final List<Msg> messages;

  @override
  String toString() => 'BatchMsg(${messages.length} messages)';
}

/// Raw Ultraviolet event message (only emitted when UV input decoding is enabled).
///
/// This enables feature parity for terminals that send non-key events like
/// OSC/CSI/DCS reports (device attributes, color reports, XTGETTCAP, etc.).
///
/// The payload is intentionally typed as [Object] to avoid hard-coupling the
/// core TUI message module to the UV event types.
final class UvEventMsg extends Msg {
  const UvEventMsg(this.event);

  final Object event;

  @override
  String toString() => 'UvEventMsg($event)';
}

/// Clipboard selection for OSC 52 operations.
enum ClipboardSelection { system, primary, unknown }

/// Clipboard content message.
///
/// Only emitted when UV input decoding is enabled and the terminal reports a
/// clipboard payload (OSC 52 response).
final class ClipboardMsg extends Msg {
  const ClipboardMsg({required this.selection, required this.content});

  final ClipboardSelection selection;
  final String content;

  @override
  String toString() =>
      'ClipboardMsg(selection: $selection, ${content.length} bytes)';
}

/// Terminal-reported color kinds.
enum TerminalColorKind { foreground, background, cursor }

/// Message containing the terminal's background color.
///
/// Only emitted when UV input decoding is enabled and the terminal reports a
/// background color (OSC 11).
final class BackgroundColorMsg extends Msg {
  const BackgroundColorMsg({required this.hex});

  /// The background color reported by the terminal (hex string).
  final String hex;

  /// Whether the background color is dark.
  bool get isDark {
    final rgb = _parseHexRgb(hex);
    if (rgb == null) return true;
    final (:r, :g, :b) = rgb;
    final rn = r / 255.0;
    final gn = g / 255.0;
    final bn = b / 255.0;
    final max = rn > gn ? (rn > bn ? rn : bn) : (gn > bn ? gn : bn);
    final min = rn < gn ? (rn < bn ? rn : bn) : (gn < bn ? gn : bn);
    final l = (max + min) / 2.0;
    return l < 0.5;
  }

  @override
  String toString() => 'BackgroundColorMsg($hex)';
}

/// Message containing the terminal's foreground color.
///
/// Only emitted when UV input decoding is enabled and the terminal reports a
/// foreground color (OSC 10).
final class ForegroundColorMsg extends Msg {
  const ForegroundColorMsg({required this.hex});

  /// The foreground color reported by the terminal (hex string).
  final String hex;

  @override
  String toString() => 'ForegroundColorMsg($hex)';
}

/// Message containing the terminal's cursor color.
///
/// Only emitted when UV input decoding is enabled and the terminal reports a
/// cursor color (OSC 12).
final class CursorColorMsg extends Msg {
  const CursorColorMsg({required this.hex});

  /// The cursor color reported by the terminal (hex string).
  final String hex;

  @override
  String toString() => 'CursorColorMsg($hex)';
}

/// Message sent when a terminal capability is reported.
class CapabilityMsg extends Msg {
  const CapabilityMsg(this.content);
  final String content;

  @override
  String toString() => 'CapabilityMsg($content)';
}

/// Message sent when the terminal version is reported.
class TerminalVersionMsg extends Msg {
  const TerminalVersionMsg(this.version);
  final String version;

  @override
  String toString() => 'TerminalVersionMsg($version)';
}

/// Message sent when keyboard enhancements are reported.
class KeyboardEnhancementsMsg extends Msg {
  const KeyboardEnhancementsMsg({this.reportEventTypes = false});
  final bool reportEventTypes;

  @override
  String toString() =>
      'KeyboardEnhancementsMsg(reportEventTypes: $reportEventTypes)';
}

/// Message sent when the terminal color profile is detected or changed.
class ColorProfileMsg extends Msg {
  const ColorProfileMsg(this.profile);
  final ColorProfile profile;

  @override
  String toString() => 'ColorProfileMsg($profile)';
}

({int r, int g, int b})? _parseHexRgb(String? hex) {
  if (hex == null) return null;
  final s = hex.trim();
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(s)) return null;
  final r = int.parse(s.substring(1, 3), radix: 16);
  final g = int.parse(s.substring(3, 5), radix: 16);
  final b = int.parse(s.substring(5, 7), radix: 16);
  return (r: r, g: g, b: b);
}

/// Mouse tracking modes.
enum MouseMode { none, cellMotion, allMotion }

/// Mouse button identifiers.
enum MouseButton {
  /// No button (for motion events).
  none,

  /// Left mouse button.
  left,

  /// Middle mouse button (wheel click).
  middle,

  /// Right mouse button.
  right,

  /// Scroll wheel up.
  wheelUp,

  /// Scroll wheel down.
  wheelDown,

  /// Scroll wheel left (horizontal scroll).
  wheelLeft,

  /// Scroll wheel right (horizontal scroll).
  wheelRight,

  /// Additional button 4 (back).
  button4,

  /// Additional button 5 (forward).
  button5,
}

/// Mouse event action types.
enum MouseAction {
  /// Mouse button pressed.
  press,

  /// Mouse button released.
  release,

  /// Mouse moved (with or without button held).
  motion,

  /// Scroll wheel moved.
  wheel,
}

/// Message sent for mouse events.
///
/// Contains information about:
/// - The action (press, release, motion, wheel)
/// - Which button was involved
/// - The position in the terminal (column, row)
/// - Modifier keys held during the event
///
/// ## Example
///
/// ```dart
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     MouseMsg(action: MouseAction.press, button: MouseButton.left, :final x, :final y) =>
///       (handleClick(x, y), null),
///     MouseMsg(action: MouseAction.wheel, button: MouseButton.wheelUp) =>
///       (scrollUp(), null),
///     MouseMsg(action: MouseAction.wheel, button: MouseButton.wheelDown) =>
///       (scrollDown(), null),
///     _ => (this, null),
///   };
/// }
/// ```
class MouseMsg extends Msg {
  /// Creates a mouse message.
  const MouseMsg({
    required this.action,
    required this.button,
    required this.x,
    required this.y,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
  });

  /// The type of mouse action.
  final MouseAction action;

  /// The mouse button involved.
  final MouseButton button;

  /// The column position (0-based).
  final int x;

  /// The row position (0-based).
  final int y;

  /// Whether Ctrl was held.
  final bool ctrl;

  /// Whether Alt was held.
  final bool alt;

  /// Whether Shift was held.
  final bool shift;

  /// Whether any modifier key is held.
  bool get hasModifier => ctrl || alt || shift;

  /// Creates a copy of this message with some fields replaced.
  MouseMsg copyWith({
    MouseAction? action,
    MouseButton? button,
    int? x,
    int? y,
    bool? ctrl,
    bool? alt,
    bool? shift,
  }) {
    return MouseMsg(
      action: action ?? this.action,
      button: button ?? this.button,
      x: x ?? this.x,
      y: y ?? this.y,
      ctrl: ctrl ?? this.ctrl,
      alt: alt ?? this.alt,
      shift: shift ?? this.shift,
    );
  }

  @override
  String toString() {
    final mods = [if (ctrl) 'Ctrl', if (alt) 'Alt', if (shift) 'Shift'];
    final modStr = mods.isNotEmpty ? '${mods.join('+')}+' : '';
    return 'MouseMsg($modStr$action $button at $x,$y)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MouseMsg &&
          action == other.action &&
          button == other.button &&
          x == other.x &&
          y == other.y &&
          ctrl == other.ctrl &&
          alt == other.alt &&
          shift == other.shift);

  @override
  int get hashCode => Object.hash(action, button, x, y, ctrl, alt, shift);
}

/// Message sent when focus is gained or lost.
///
/// Only available when focus reporting is enabled.
class FocusMsg extends Msg {
  /// Creates a focus message.
  const FocusMsg(this.focused);

  /// Whether the terminal gained focus (true) or lost focus (false).
  final bool focused;

  @override
  String toString() => 'FocusMsg(${focused ? 'gained' : 'lost'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FocusMsg && focused == other.focused);

  @override
  int get hashCode => focused.hashCode;
}

/// Message sent when bracketed paste content is received.
///
/// Only available when bracketed paste mode is enabled.
class PasteMsg extends Msg {
  /// Creates a paste message.
  const PasteMsg(this.content);

  /// The pasted text content.
  final String content;

  @override
  String toString() => 'PasteMsg(${content.length} chars)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PasteMsg && content == other.content);

  @override
  int get hashCode => content.hashCode;
}

/// Message sent when an interrupt signal (SIGINT/Ctrl+C) is received.
///
/// This is distinct from [QuitMsg] in that it represents an external
/// interrupt request rather than a programmatic quit command.
///
/// The model can handle this to:
/// - Prompt for confirmation before quitting
/// - Save state before exiting
/// - Cancel a long-running operation
/// - Ignore the interrupt entirely
///
/// ## Example
///
/// ```dart
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     InterruptMsg() when hasUnsavedChanges => (
///       copyWith(showConfirmDialog: true),
///       null,
///     ),
///     InterruptMsg() => (this, Cmd.quit()),
///     _ => (this, null),
///   };
/// }
/// ```
class InterruptMsg extends Msg {
  /// Creates an interrupt message.
  const InterruptMsg();

  @override
  String toString() => 'InterruptMsg()';
}

/// Message sent to force a repaint of the view.
///
/// This bypasses the skip-if-unchanged optimization and
/// forces a full re-render of the current view.
///
/// Useful when external factors have changed the terminal
/// state or when the view needs to be refreshed.
class RepaintMsg extends Msg {
  /// Creates a repaint message.
  const RepaintMsg();

  @override
  String toString() => 'RepaintMsg()';
}

/// Message sent periodically with renderer performance metrics.
///
/// When enabled via [ProgramOptions.metricsInterval], the Program sends
/// this message at the specified interval with current FPS, frame times,
/// and render durations.
///
/// ## Example
///
/// ```dart
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     RenderMetricsMsg(:final metrics) => (
///       copyWith(
///         fps: metrics.averageFps,
///         frameTime: metrics.averageFrameTime,
///       ),
///       null,
///     ),
///     _ => (this, null),
///   };
/// }
/// ```
class RenderMetricsMsg extends Msg {
  /// Creates a render metrics message.
  const RenderMetricsMsg(this.metrics);

  /// The current render performance metrics.
  final RenderMetrics metrics;

  @override
  String toString() =>
      'RenderMetricsMsg(fps: ${metrics.averageFps.toStringAsFixed(1)})';
}

/// Message wrapper for custom user-defined messages.
///
/// This allows wrapping any value as a message:
///
/// ```dart
/// // Define a custom message type
/// final msg = CustomMsg<String>('hello');
///
/// // Or use the factory
/// final msg = CustomMsg.of('hello');
/// ```
class CustomMsg<T> extends Msg {
  /// Creates a custom message wrapping a value.
  const CustomMsg(this.value);

  /// Factory constructor for type inference.
  static CustomMsg<T> of<T>(T value) => CustomMsg(value);

  /// The wrapped value.
  final T value;

  @override
  String toString() => 'CustomMsg<$T>($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomMsg<T> && value == other.value);

  @override
  int get hashCode => value.hashCode;
}
