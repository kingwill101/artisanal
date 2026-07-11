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
import 'package:artisanal/style.dart';

DateTime _defaultBubbleNowProvider() => DateTime.now();

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
    frames: [
      BlockShades.full,
      BlockShades.dark,
      BlockShades.medium,
      BlockShades.light,
    ],
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
  static final meter = Spinner(
    frames: [
      BlockMedium.empty + BlockMedium.empty + BlockMedium.empty,
      BlockMedium.solid + BlockMedium.empty + BlockMedium.empty,
      BlockMedium.solid + BlockMedium.solid + BlockMedium.empty,
      BlockMedium.solid + BlockMedium.solid + BlockMedium.solid,
      BlockMedium.solid + BlockMedium.solid + BlockMedium.empty,
      BlockMedium.solid + BlockMedium.empty + BlockMedium.empty,
      BlockMedium.empty + BlockMedium.empty + BlockMedium.empty,
    ],
    fps: const Duration(milliseconds: 143),
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
    frames: [
      ArcSegments.leftHalf,
      ArcSegments.rightHalf,
      ArcSegments.lowerHalfCircle,
      ArcSegments.upperHalfCircle,
    ],
    fps: Duration(milliseconds: 120),
  );

  /// Arc spinner.
  static const arc = Spinner(
    frames: [
      ArcSegments.upperLeftArc,
      ArcSegments.upperHalf,
      ArcSegments.upperRightArc,
      ArcSegments.lowerRightArc,
      ArcSegments.lowerHalf,
      ArcSegments.lowerLeftArc,
    ],
    fps: Duration(milliseconds: 100),
  );

  /// Bounce spinner.
  static const bounce = Spinner(
    frames: ['⠁', '⠂', '⠄', '⠂'],
    fps: Duration(milliseconds: 120),
  );

  /// Arrow spinner.
  static const arrows = Spinner(
    frames: [
      Arrows.left,
      '↖',
      Arrows.up,
      '↗',
      Arrows.right,
      '↘',
      Arrows.down,
      '↙',
    ],
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
    frames: [
      BlockQuadrants.lowerLeft,
      BlockQuadrants.upperLeft,
      BlockQuadrants.upperRight,
      BlockQuadrants.lowerRight,
    ],
    fps: Duration(milliseconds: 120),
  );

  /// Box bounce 2 spinner (larger).
  static const boxBounce2 = Spinner(
    frames: [
      BlockShades.left,
      BlockShades.upper,
      BlockShades.right,
      BlockShades.lower,
    ],
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
  static final aesthetic = Spinner(
    frames: [
      _solidFrames(1),
      _solidFrames(2),
      _solidFrames(3),
      _solidFrames(4),
      _solidFrames(5),
      _solidFrames(6),
      _solidFrames(7),
      _emptyFrames(1),
      _emptyFrames(2),
      _emptyFrames(3),
      _emptyFrames(4),
      _emptyFrames(5),
      _emptyFrames(6),
      _emptyFrames(7),
    ],
    fps: const Duration(milliseconds: 80),
  );

  /// 7-char block frame: [count] solid + (7-[count]) empty.
  static String _solidFrames(int count) =>
      List.filled(count, BlockMedium.solid).join() +
      List.filled(7 - count, BlockMedium.empty).join();

  /// 7-char block frame: [count] empty + (7-[count]) solid.
  static String _emptyFrames(int count) =>
      List.filled(count, BlockMedium.empty).join() +
      List.filled(7 - count, BlockMedium.solid).join();

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
    frames: [SparseBlocks.smallEmpty, SparseBlocks.smallSolid],
    fps: Duration(milliseconds: 80),
  );

  /// Toggle 3 spinner.
  static const toggle3 = Spinner(
    frames: [SparseBlocks.empty, SparseBlocks.solid],
    fps: Duration(milliseconds: 120),
  );

  /// Toggle 4 spinner.
  static const toggle4 = Spinner(
    frames: [
      SparseBlocks.solid,
      SparseBlocks.empty,
      SparseBlocks.smallSolid,
      SparseBlocks.smallEmpty,
    ],
    fps: Duration(milliseconds: 100),
  );

  /// Noise spinner.
  static const noise = Spinner(
    frames: [BlockShades.dark, BlockShades.medium, BlockShades.light],
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
  static final sand = Spinner(
    frames: [
      '⠁',
      '⠂',
      '⠄',
      '⡀',
      '⡈',
      '⡐',
      '⡠',
      BrailleChars.topRow,
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
      BrailleChars.full,
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
    fps: const Duration(milliseconds: 80),
  );

  /// Creates a Knight Rider scanner animation.
  ///
  /// The scanner oscillates bidirectionally (left → right → left) with
  /// configurable hold frames at each end, producing a glowing sweep
  /// effect across the bar.
  ///
  /// Parameters:
  /// - [color] — The bright color for the scanner head (defaults to
  ///   [Colors.purple]).
  /// - [width] — Number of character positions (default 8).
  /// - [chars] — Character set for active/inactive positions
  ///   (default [ScannerChars.blocks]).
  /// - [holdStart] — Frames to hold at the start position (default 30).
  /// - [holdEnd] — Frames to hold at the end position (default 9).
  /// - [trailSteps] — Number of gradient steps in the trail (default 6).
  /// - [fps] — Frame interval duration (default 40ms, matching opencode).
  static Spinner scanner({
    Color? color,
    int width = 8,
    ScannerCharSet chars = ScannerChars.blocks,
    int holdStart = 30,
    int holdEnd = 9,
    int trailSteps = 6,
    Duration fps = const Duration(milliseconds: 40),
  }) {
    final c = color ?? Colors.purple;
    final trail = deriveTrail(c, steps: trailSteps);
    final inactive = deriveInactive(c);

    final frames = _generateScannerFrames(
      width: width,
      chars: chars,
      trail: trail,
      inactiveColor: inactive,
      holdStart: holdStart,
      holdEnd: holdEnd,
    );

    return Spinner(frames: frames, fps: fps);
  }
}

/// Derives a gradient of trail colors from a single bright color.
///
/// Each step is progressively dimmed (via [Color.dim]) to create the
/// falling trail effect behind the scanner head.
List<Color> deriveTrail(Color bright, {int steps = 6}) {
  final result = <Color>[bright];
  var current = bright;
  for (var i = 1; i < steps; i++) {
    current = current.dim;
    result.add(current);
  }
  return result;
}

/// Derives the inactive color for scanner background positions.
///
/// Produces a heavily dimmed version of [bright] so inactive dots
/// recede into the background.
Color deriveInactive(Color bright, {double factor = 0.2}) {
  var result = bright;
  for (var i = 0; i < 3; i++) {
    result = result.dim;
  }
  return result;
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
  SpinnerModel({
    Spinner spinner = Spinners.line,
    int frame = 0,
    DateTime Function()? nowProvider,
  }) : _spinner = spinner,
       _frame = frame,
       _nowProvider = nowProvider ?? _defaultBubbleNowProvider,
       _id = _nextSpinnerId(),
       _tag = 0;

  SpinnerModel._internal({
    required Spinner spinner,
    required int frame,
    required int id,
    required int tag,
    required DateTime Function() nowProvider,
  }) : _spinner = spinner,
       _frame = frame,
       _nowProvider = nowProvider,
       _id = id,
       _tag = tag;

  final Spinner _spinner;
  final int _frame;
  final DateTime Function() _nowProvider;
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
      nowProvider: _nowProvider,
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
      return SpinnerTickMsg(time: _nowProvider(), id: _id, tag: _tag);
    });
  }

  /// Creates a command that triggers the next tick after the FPS duration.
  Cmd _tickCmd() {
    final id = _id;
    final tag = _tag;
    final fps = _spinner.fps;

    return Cmd.tick(
      fps,
      (time) => SpinnerTickMsg(time: time, id: id, tag: tag),
      nowProvider: _nowProvider,
    );
  }

  @override
  String view() {
    if (_frame >= _spinner.frames.length) {
      return '(error)';
    }
    return _spinner.frames[_frame];
  }
}

// ---------------------------------------------------------------------------
// Scanner (Knight Rider) animation frame generation
// ---------------------------------------------------------------------------

class _ScannerState {
  const _ScannerState({
    required this.activePosition,
    required this.isMovingForward,
    required this.isHolding,
    required this.holdProgress,
  });

  final int activePosition;
  final bool isMovingForward;
  final bool isHolding;
  final int holdProgress;
}

_ScannerState _getScannerState(
  int frameIndex,
  int width,
  int holdStart,
  int holdEnd,
) {
  final forward = frameIndex;
  if (forward < width) {
    return _ScannerState(
      activePosition: forward,
      isMovingForward: true,
      isHolding: false,
      holdProgress: 0,
    );
  }
  final holdEndPhase = forward - width;
  if (holdEndPhase < holdEnd) {
    return _ScannerState(
      activePosition: width - 1,
      isMovingForward: true,
      isHolding: true,
      holdProgress: holdEndPhase,
    );
  }
  final backward = holdEndPhase - holdEnd;
  if (backward < width - 1) {
    return _ScannerState(
      activePosition: width - 2 - backward,
      isMovingForward: false,
      isHolding: false,
      holdProgress: 0,
    );
  }
  final holdStartPhase = backward - (width - 1);
  return _ScannerState(
    activePosition: 0,
    isMovingForward: false,
    isHolding: true,
    holdProgress: holdStartPhase,
  );
}

int _trailDistance(int charIndex, _ScannerState state) {
  final distance = state.isMovingForward
      ? state.activePosition - charIndex
      : charIndex - state.activePosition;
  if (distance < 0) return -1;
  if (state.isHolding) return distance + state.holdProgress;
  return distance;
}

List<String> _generateScannerFrames({
  required int width,
  required ScannerCharSet chars,
  required List<Color> trail,
  required Color inactiveColor,
  required int holdStart,
  required int holdEnd,
}) {
  final totalFrames = width + holdEnd + (width - 1) + holdStart;
  final activeChars = chars.active;
  final inactiveChar = chars.inactive;

  return List.generate(totalFrames, (frameIndex) {
    final state = _getScannerState(frameIndex, width, holdStart, holdEnd);
    final buf = StringBuffer();
    for (var charIndex = 0; charIndex < width; charIndex++) {
      final distance = _trailDistance(charIndex, state);
      String char;
      Color color;
      if (distance >= 0 && distance < trail.length) {
        final activeIndex = distance < activeChars.length ? distance : 0;
        char = activeChars[activeIndex];
        color = trail[distance];
      } else {
        char = inactiveChar;
        color = inactiveColor;
      }
      buf.write(Style().foreground(color).render(char));
    }
    return buf.toString();
  });
}
