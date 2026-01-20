/// Animated spinner widget for loading/activity states.
///
/// Provides [SpinnerModel] for animated spinners and [Spinners] with
/// pre-defined animation presets.
///
/// ## Usage
///
/// ```dart
/// // Create a spinner with default animation
/// final spinner = SpinnerModel();
///
/// // Or use a specific animation
/// final spinner = SpinnerModel(spinner: Spinners.dot);
///
/// // Start animation in init()
/// @override
/// Cmd? init() => spinner.tick();
///
/// // Update handles animation timing
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   final (newSpinner, cmd) = spinner.update(msg);
///   return (MyModel(spinner: newSpinner), cmd);
/// }
///
/// // View renders current frame
/// @override
/// String view() => '${spinner.view()} Loading...';
/// ```
///
/// ## Available Spinners
///
/// - [Spinners.line] - Classic | / - \
/// - [Spinners.dot] - Braille dots ⣾⣽⣻⢿⡿⣟⣯⣷
/// - [Spinners.miniDot] - Small braille ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏
/// - [Spinners.pulse] - Block pulse █▓▒░
/// - [Spinners.globe] - Globe emoji 🌍🌎🌏
/// - [Spinners.moon] - Moon phases 🌑🌒🌓🌔🌕🌖🌗🌘
/// - And many more...
///
/// {@category TUI}
/// {@category Bubbles}
library;

import '../cmd.dart';
import '../component.dart';
import '../msg.dart';

/// A spinner animation definition.
///
/// Contains the frames to display and the speed at which to animate.
class Spinner {
  const Spinner({
    required this.frames,
    this.fps = const Duration(milliseconds: 100),
  });

  /// The frames of the spinner animation.
  final List<String> frames;

  /// Duration between frames.
  final Duration fps;
}

/// Pre-defined spinner animations.
class Spinners {
  Spinners._();

  /// Line spinner: | / - \
  static const line = Spinner(
    frames: ['|', '/', '-', '\\'],
    fps: Duration(milliseconds: 100),
  );

  /// Braille dot spinner.
  static const dot = Spinner(
    frames: ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'],
    fps: Duration(milliseconds: 100),
  );

  /// Mini dot spinner.
  static const miniDot = Spinner(
    frames: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
    fps: Duration(milliseconds: 83),
  );

  /// Jump spinner.
  static const jump = Spinner(
    frames: ['⢄', '⢂', '⢁', '⡁', '⡈', '⡐', '⡠'],
    fps: Duration(milliseconds: 100),
  );

  /// Pulse spinner.
  static const pulse = Spinner(
    frames: ['█', '▓', '▒', '░'],
    fps: Duration(milliseconds: 125),
  );

  /// Points spinner.
  static const points = Spinner(
    frames: ['∙∙∙', '●∙∙', '∙●∙', '∙∙●'],
    fps: Duration(milliseconds: 143),
  );

  /// Globe spinner.
  static const globe = Spinner(
    frames: ['🌍', '🌎', '🌏'],
    fps: Duration(milliseconds: 250),
  );

  /// Moon phases spinner.
  static const moon = Spinner(
    frames: ['🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘'],
    fps: Duration(milliseconds: 125),
  );

  /// Monkey spinner.
  static const monkey = Spinner(
    frames: ['🙈', '🙉', '🙊'],
    fps: Duration(milliseconds: 333),
  );

  /// Meter spinner.
  static const meter = Spinner(
    frames: ['▱▱▱', '▰▱▱', '▰▰▱', '▰▰▰', '▰▰▱', '▰▱▱', '▱▱▱'],
    fps: Duration(milliseconds: 143),
  );

  /// Hamburger spinner.
  static const hamburger = Spinner(
    frames: ['☱', '☲', '☴', '☲'],
    fps: Duration(milliseconds: 333),
  );

  /// Ellipsis spinner.
  static const ellipsis = Spinner(
    frames: ['', '.', '..', '...'],
    fps: Duration(milliseconds: 333),
  );

  /// Simple dots growing.
  static const growDots = Spinner(
    frames: ['.  ', '.. ', '...', ' ..', '  .', '   '],
    fps: Duration(milliseconds: 120),
  );

  /// Circle quarters.
  static const circle = Spinner(
    frames: ['◐', '◓', '◑', '◒'],
    fps: Duration(milliseconds: 120),
  );

  /// Arc spinner.
  static const arc = Spinner(
    frames: ['◜', '◠', '◝', '◞', '◡', '◟'],
    fps: Duration(milliseconds: 100),
  );

  /// Bounce spinner.
  static const bounce = Spinner(
    frames: ['⠁', '⠂', '⠄', '⠂'],
    fps: Duration(milliseconds: 120),
  );

  /// Arrow spinner.
  static const arrows = Spinner(
    frames: ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙'],
    fps: Duration(milliseconds: 100),
  );

  /// Clock faces spinner.
  static const clock = Spinner(
    frames: [
      '🕐',
      '🕑',
      '🕒',
      '🕓',
      '🕔',
      '🕕',
      '🕖',
      '🕗',
      '🕘',
      '🕙',
      '🕚',
      '🕛',
    ],
    fps: Duration(milliseconds: 100),
  );

  /// Box bounce spinner.
  static const boxBounce = Spinner(
    frames: ['▖', '▘', '▝', '▗'],
    fps: Duration(milliseconds: 120),
  );

  /// Box bounce 2 spinner (larger).
  static const boxBounce2 = Spinner(
    frames: ['▌', '▀', '▐', '▄'],
    fps: Duration(milliseconds: 100),
  );

  /// Triangle spinner.
  static const triangle = Spinner(
    frames: ['◢', '◣', '◤', '◥'],
    fps: Duration(milliseconds: 100),
  );

  /// Binary spinner.
  static const binary = Spinner(
    frames: ['010010', '001100', '100101', '111010', '001011', '110001'],
    fps: Duration(milliseconds: 100),
  );

  /// Aesthetic dots spinner.
  static const aesthetic = Spinner(
    frames: [
      '▰▱▱▱▱▱▱',
      '▰▰▱▱▱▱▱',
      '▰▰▰▱▱▱▱',
      '▰▰▰▰▱▱▱',
      '▰▰▰▰▰▱▱',
      '▰▰▰▰▰▰▱',
      '▰▰▰▰▰▰▰',
      '▱▰▰▰▰▰▰',
      '▱▱▰▰▰▰▰',
      '▱▱▱▰▰▰▰',
      '▱▱▱▱▰▰▰',
      '▱▱▱▱▱▰▰',
      '▱▱▱▱▱▱▰',
      '▱▱▱▱▱▱▱',
    ],
    fps: Duration(milliseconds: 80),
  );

  /// Flip spinner.
  static const flip = Spinner(
    frames: ['_', '_', '_', '-', '`', '`', '\'', '´', '-', '_', '_', '_'],
    fps: Duration(milliseconds: 70),
  );

  /// Weather spinner.
  static const weather = Spinner(
    frames: [
      '☀️',
      '☀️',
      '☀️',
      '🌤',
      '⛅️',
      '🌥',
      '☁️',
      '🌧',
      '🌨',
      '🌧',
      '🌥',
      '⛅️',
      '🌤',
      '☀️',
      '☀️',
    ],
    fps: Duration(milliseconds: 100),
  );

  /// Christmas spinner.
  static const christmas = Spinner(
    frames: ['🌲', '🎄'],
    fps: Duration(milliseconds: 400),
  );

  /// Grenade spinner.
  static const grenade = Spinner(
    frames: [
      '،  ',
      '′  ',
      ' ´ ',
      ' ‾ ',
      '  ⸌',
      '  ⸊',
      '  |',
      '  ⁎',
      '  ⁕',
      ' ෴ ',
      '  ⁂',
      '   ',
      '   ',
      '   ',
    ],
    fps: Duration(milliseconds: 80),
  );

  /// Point spinner.
  static const point = Spinner(
    frames: ['∙∙∙', '●∙∙', '∙●∙', '∙∙●', '∙∙∙'],
    fps: Duration(milliseconds: 125),
  );

  /// Layer spinner.
  static const layer = Spinner(
    frames: ['-', '=', '≡'],
    fps: Duration(milliseconds: 150),
  );

  /// Beta wave spinner.
  static const betaWave = Spinner(
    frames: [
      'ρββββββ',
      'βρβββββ',
      'ββρββββ',
      'βββρβββ',
      'ββββρββ',
      'βββββρβ',
      'ββββββρ',
    ],
    fps: Duration(milliseconds: 80),
  );

  /// Finger dance spinner.
  static const fingerDance = Spinner(
    frames: ['🤘', '🤟', '🖖', '✋', '🤚', '👆'],
    fps: Duration(milliseconds: 160),
  );

  /// Fist bump spinner.
  static const fistBump = Spinner(
    frames: [
      '🤜　　　　🤛',
      '🤜　　　🤛',
      '🤜　　🤛',
      '🤜　🤛',
      '👊🤛',
      '🤜👊',
      '🤜　🤛',
      '🤜　　🤛',
      '🤜　　　🤛',
      '🤜　　　　🤛',
    ],
    fps: Duration(milliseconds: 80),
  );

  /// Mind blown spinner.
  static const mindblown = Spinner(
    frames: [
      '😐',
      '😐',
      '😮',
      '😮',
      '😦',
      '😦',
      '😧',
      '😧',
      '🤯',
      '💥',
      '✨',
      '　',
      '　',
      '　',
    ],
    fps: Duration(milliseconds: 160),
  );

  /// Speaker spinner.
  static const speaker = Spinner(
    frames: ['🔈', '🔉', '🔊', '🔉'],
    fps: Duration(milliseconds: 160),
  );

  /// Orange pulse spinner.
  static const orangePulse = Spinner(
    frames: ['🔸', '🔶', '🟠', '🟠', '🔶'],
    fps: Duration(milliseconds: 100),
  );

  /// Blue pulse spinner.
  static const bluePulse = Spinner(
    frames: ['🔹', '🔷', '🔵', '🔵', '🔷'],
    fps: Duration(milliseconds: 100),
  );

  /// Toggle spinner.
  static const toggle = Spinner(
    frames: ['⊶', '⊷'],
    fps: Duration(milliseconds: 250),
  );

  /// Toggle 2 spinner.
  static const toggle2 = Spinner(
    frames: ['▫', '▪'],
    fps: Duration(milliseconds: 80),
  );

  /// Toggle 3 spinner.
  static const toggle3 = Spinner(
    frames: ['□', '■'],
    fps: Duration(milliseconds: 120),
  );

  /// Toggle 4 spinner.
  static const toggle4 = Spinner(
    frames: ['■', '□', '▪', '▫'],
    fps: Duration(milliseconds: 100),
  );

  /// Noise spinner.
  static const noise = Spinner(
    frames: ['▓', '▒', '░'],
    fps: Duration(milliseconds: 100),
  );

  /// Simple dots spinner (compact).
  static const simpleDots = Spinner(
    frames: ['.  ', '.. ', '...', '   '],
    fps: Duration(milliseconds: 400),
  );

  /// Simple dots scrolling.
  static const simpleDotsScrolling = Spinner(
    frames: ['.  ', '.. ', '...', ' ..', '  .', '   '],
    fps: Duration(milliseconds: 200),
  );

  /// Star spinner.
  static const star = Spinner(
    frames: ['✶', '✸', '✹', '✺', '✹', '✷'],
    fps: Duration(milliseconds: 70),
  );

  /// Star 2 spinner.
  static const star2 = Spinner(
    frames: ['+', 'x', '*'],
    fps: Duration(milliseconds: 80),
  );

  /// Sand spinner.
  static const sand = Spinner(
    frames: [
      '⠁',
      '⠂',
      '⠄',
      '⡀',
      '⡈',
      '⡐',
      '⡠',
      '⣀',
      '⣁',
      '⣂',
      '⣄',
      '⣌',
      '⣔',
      '⣤',
      '⣥',
      '⣦',
      '⣮',
      '⣶',
      '⣷',
      '⣿',
      '⡿',
      '⠿',
      '⢟',
      '⠟',
      '⡛',
      '⠛',
      '⠫',
      '⢋',
      '⠋',
      '⠍',
      '⡉',
      '⠉',
      '⠑',
      '⠡',
      '⢁',
    ],
    fps: Duration(milliseconds: 80),
  );
}

/// Global ID counter for spinner instances.
int _lastSpinnerId = 0;

int _nextSpinnerId() => ++_lastSpinnerId;

/// Message indicating a spinner should advance to the next frame.
class SpinnerTickMsg extends Msg {
  const SpinnerTickMsg({
    required this.time,
    required this.id,
    required this.tag,
  });

  /// The time at which the tick occurred.
  final DateTime time;

  /// The ID of the spinner this message belongs to.
  final int id;

  /// Tag to prevent duplicate tick messages.
  final int tag;
}

/// A spinner widget for showing loading/activity states.
///
/// The spinner animates through frames at a configurable rate. It follows
/// the Elm Architecture pattern and can be composed into larger components.
///
/// ## Example
///
/// ```dart
/// class LoadingModel implements Model {
///   final SpinnerModel spinner;
///   final String message;
///
///   LoadingModel({SpinnerModel? spinner, this.message = 'Loading...'})
///       : spinner = spinner ?? SpinnerModel();
///
///   @override
///   Cmd? init() => spinner.tick(); // Start the animation
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     final (newSpinner, cmd) = spinner.update(msg);
///     return (
///       LoadingModel(spinner: newSpinner, message: message),
///       cmd,
///     );
///   }
///
///   @override
///   String view() => '${spinner.view()} $message';
/// }
/// ```
class SpinnerModel extends ViewComponent {
  /// Creates a new spinner model.
  SpinnerModel({Spinner spinner = Spinners.line, int frame = 0})
    : _spinner = spinner,
      _frame = frame,
      _id = _nextSpinnerId(),
      _tag = 0;

  SpinnerModel._internal({
    required Spinner spinner,
    required int frame,
    required int id,
    required int tag,
  }) : _spinner = spinner,
       _frame = frame,
       _id = id,
       _tag = tag;

  final Spinner _spinner;
  final int _frame;
  final int _id;
  final int _tag;

  /// The spinner animation being used.
  Spinner get spinner => _spinner;

  /// The current frame index.
  int get frame => _frame;

  /// The spinner's unique ID.
  int get id => _id;

  /// Creates a copy with the given fields replaced.
  SpinnerModel copyWith({Spinner? spinner, int? frame, int? tag}) {
    return SpinnerModel._internal(
      spinner: spinner ?? _spinner,
      frame: frame ?? _frame,
      id: _id,
      tag: tag ?? _tag,
    );
  }

  @override
  Cmd? init() => null;

  @override
  (SpinnerModel, Cmd?) update(Msg msg) {
    if (msg is! SpinnerTickMsg) {
      return (this, null);
    }

    // Only accept tick messages for this spinner
    if (msg.id > 0 && msg.id != _id) {
      return (this, null);
    }

    // Prevent duplicate ticks
    if (msg.tag > 0 && msg.tag != _tag) {
      return (this, null);
    }

    // Advance to next frame
    final nextFrame = (_frame + 1) % _spinner.frames.length;
    final nextTag = _tag + 1;
    final newSpinner = copyWith(frame: nextFrame, tag: nextTag);

    return (newSpinner, newSpinner._tickCmd());
  }

  /// Creates a command to start the spinner animation.
  ///
  /// Call this from your init() method to begin animating.
  Cmd tick() {
    return Cmd(() async {
      return SpinnerTickMsg(time: DateTime.now(), id: _id, tag: _tag);
    });
  }

  /// Creates a command that triggers the next tick after the FPS duration.
  Cmd _tickCmd() {
    final id = _id;
    final tag = _tag;
    final fps = _spinner.fps;

    return Cmd.tick(fps, (time) {
      return SpinnerTickMsg(time: time, id: id, tag: tag);
    });
  }

  @override
  String view() {
    if (_frame >= _spinner.frames.length) {
      return '(error)';
    }
    return _spinner.frames[_frame];
  }
}
