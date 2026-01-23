import '../cmd.dart';
import '../component.dart';
import '../msg.dart';

/// Message sent when the stopwatch ticks.
class StopwatchTickMsg extends Msg {
  const StopwatchTickMsg(this.time, this.tag, this.id);

  /// The time when the tick occurred.
  final DateTime time;

  /// The tag to identify which stopwatch instance this tick belongs to.
  final int tag;

  /// The stopwatch ID this tick belongs to.
  final int id;
}

/// Message sent to start or stop the stopwatch.
class StopwatchStartStopMsg extends Msg {
  const StopwatchStartStopMsg(this.running, this.tag, this.id);

  /// Whether the stopwatch is running.
  final bool running;

  /// The tag to identify which stopwatch instance this message belongs to.
  final int tag;

  /// The stopwatch ID this message belongs to.
  final int id;
}

/// Message sent to reset the stopwatch.
class StopwatchResetMsg extends Msg {
  const StopwatchResetMsg(this.tag, this.id);

  /// The tag to identify which stopwatch instance this reset belongs to.
  final int tag;

  /// The stopwatch ID this reset belongs to.
  final int id;
}

/// Global counter for generating unique stopwatch IDs.
int _lastStopwatchId = 0;

/// Generates a new unique stopwatch ID.
int _nextStopwatchId() {
  return _lastStopwatchId++;
}

/// A stopwatch model that counts up from zero.
///
/// The stopwatch counts elapsed time, ticking at [interval] intervals.
/// Unlike a timer, the stopwatch counts up and has no timeout.
///
/// Example:
/// ```dart
/// final stopwatch = StopwatchModel();
/// final (model, cmd) = stopwatch.init();
/// // Start the stopwatch
/// final (model2, cmd2) = model.startCmd();
/// ```
class StopwatchModel extends ViewComponent {
  /// Creates a new stopwatch model.
  ///
  /// [interval] is how often the stopwatch ticks (defaults to 100 milliseconds).
  StopwatchModel({this.interval = const Duration(milliseconds: 100)})
    : _elapsed = Duration.zero,
      _running = false,
      _id = _nextStopwatchId(),
      _tag = 0;

  /// Private constructor for copyWith.
  StopwatchModel._({
    required Duration elapsed,
    required this.interval,
    required bool running,
    required int id,
    required int tag,
  }) : _elapsed = elapsed,
       _running = running,
       _id = id,
       _tag = tag;

  /// The elapsed duration.
  final Duration _elapsed;

  /// How often the stopwatch ticks.
  final Duration interval;

  /// Whether the stopwatch is currently running.
  final bool _running;

  /// Unique ID for this stopwatch instance.
  final int _id;

  /// Tag to differentiate between stopwatch runs when filtering messages.
  final int _tag;

  /// Returns the elapsed duration.
  Duration get elapsed => _elapsed;

  /// Returns whether the stopwatch is currently running.
  bool get running => _running;

  /// Returns the tag for this stopwatch instance.
  int get tag => _tag;

  /// Returns the internal ID for this stopwatch.
  int get id => _id;

  /// Creates a copy of this model with the given fields replaced.
  StopwatchModel copyWith({
    Duration? elapsed,
    Duration? interval,
    bool? running,
    int? id,
    int? tag,
  }) {
    return StopwatchModel._(
      elapsed: elapsed ?? _elapsed,
      interval: interval ?? this.interval,
      running: running ?? _running,
      id: id ?? _id,
      tag: tag ?? _tag,
    );
  }

  /// Initializes the stopwatch.
  ///
  /// Returns null (stopwatch starts stopped).
  @override
  Cmd? init() {
    return null;
  }

  /// Updates the stopwatch based on incoming messages.
  @override
  (StopwatchModel, Cmd?) update(Msg msg) {
    switch (msg) {
      case StopwatchStartStopMsg():
        // Ignore messages for other stopwatch instances.
        if (msg.id != _id) {
          return (this, null);
        }
        return (copyWith(running: msg.running, tag: msg.tag), null);

      case StopwatchResetMsg():
        // Ignore messages for other stopwatch instances.
        if (msg.id != _id) {
          return (this, null);
        }
        return (copyWith(elapsed: Duration.zero, tag: msg.tag), null);

      case StopwatchTickMsg():
        // Ignore messages for other stopwatch instances.
        if (msg.id != _id || msg.tag != _tag) {
          return (this, null);
        }

        // If not running, ignore tick.
        if (!_running) {
          return (this, null);
        }

        // Update elapsed time.
        final newTag = _tag + 1;
        return (
          copyWith(elapsed: _elapsed + interval, tag: newTag),
          _tickWithTag(newTag),
        );

      default:
        return (this, null);
    }
  }

  /// Returns the view of the stopwatch.
  ///
  /// By default returns the elapsed time formatted as MM:SS.ss
  /// Override this method or use a custom formatter for different display.
  @override
  String view() {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    final centiseconds = (_elapsed.inMilliseconds ~/ 10) % 100;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${centiseconds.toString().padLeft(2, '0')}';
  }

  /// Creates a command to start the stopwatch.
  ///
  /// This will start emitting tick messages at the configured interval.
  Cmd start() {
    // Increment tag to ensure old ticks don't affect new stopwatch runs.
    final newTag = _tag + 1;
    return Cmd.batch([
      Cmd.message(StopwatchStartStopMsg(true, newTag, _id)),
      _tickWithTag(newTag),
    ]);
  }

  /// Creates a command to stop the stopwatch.
  Cmd stop() {
    return Cmd.message(StopwatchStartStopMsg(false, _tag, _id));
  }

  /// Creates a command to toggle the stopwatch on/off.
  Cmd toggle() {
    if (_running) {
      return stop();
    }
    return start();
  }

  /// Creates a command to reset the stopwatch.
  ///
  /// This does not stop the stopwatch if it's running.
  Cmd reset() {
    return Cmd.message(StopwatchResetMsg(_tag, _id));
  }

  /// Internal: creates a tick command with a specific tag.
  Cmd _tickWithTag(int tag) {
    return Cmd.tick(interval, (time) => StopwatchTickMsg(time, tag, _id));
  }
}
