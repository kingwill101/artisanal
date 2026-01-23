import '../cmd.dart';
import '../component.dart';
import '../msg.dart';

/// Message sent when the timer ticks.
class TimerTickMsg extends Msg {
  const TimerTickMsg(this.time, this.tag, this.timeout);

  /// The time when the tick occurred.
  final DateTime time;

  /// The tag to identify which timer instance this tick belongs to.
  final int tag;

  /// Whether this tick represents a timeout event.
  final bool timeout;
}

/// Message sent to start or stop the timer.
class TimerStartStopMsg extends Msg {
  const TimerStartStopMsg(this.running, this.tag);

  /// Whether the timer is running.
  final bool running;

  /// The tag to identify which timer instance this message belongs to.
  final int tag;
}

/// Internal message sent when timer times out.
class TimerTimeoutMsg extends Msg {
  const TimerTimeoutMsg(this.tag);

  /// The tag to identify which timer instance this timeout belongs to.
  final int tag;
}

/// Global counter for generating unique timer IDs.
int _lastTimerId = 0;

/// Generates a new unique timer ID.
int _nextTimerId() {
  return _lastTimerId++;
}

/// A countdown timer model.
///
/// The timer counts down from [timeout] duration, ticking at [interval]
/// intervals. When the timer reaches zero, it sends a [TimerTickMsg] with
/// `timeout: true`.
///
/// Example:
/// ```dart
/// final timer = TimerModel(timeout: Duration(seconds: 30));
/// final (model, cmd) = timer.init();
/// // Start the timer
/// final (model2, cmd2) = model.update(TimerStartStopMsg(true, model.tag));
/// ```
class TimerModel extends ViewComponent {
  /// Creates a new timer model.
  ///
  /// [timeout] is the duration to count down from.
  /// [interval] is how often the timer ticks (defaults to 1 second).
  TimerModel({
    required this.timeout,
    this.interval = const Duration(seconds: 1),
  }) : _running = false,
       _id = _nextTimerId(),
       _tag = 0;

  /// Private constructor for copyWith.
  TimerModel._({
    required this.timeout,
    required this.interval,
    required bool running,
    required int id,
    required int tag,
  }) : _running = running,
       _id = id,
       _tag = tag;

  /// The duration to count down from.
  final Duration timeout;

  /// How often the timer ticks.
  final Duration interval;

  /// Whether the timer is currently running.
  final bool _running;

  /// Unique ID for this timer instance.
  final int _id;

  /// Tag to differentiate between timer instances when filtering messages.
  final int _tag;

  /// Returns whether the timer is currently running.
  bool get running => _running;

  /// Returns the tag for this timer instance.
  int get tag => _tag;

  /// Returns the internal ID for this timer.
  int get id => _id;

  /// Returns whether the timer has timed out (timeout <= 0).
  bool get timedOut => timeout <= Duration.zero;

  /// Creates a copy of this model with the given fields replaced.
  TimerModel copyWith({
    Duration? timeout,
    Duration? interval,
    bool? running,
    int? id,
    int? tag,
  }) {
    return TimerModel._(
      timeout: timeout ?? this.timeout,
      interval: interval ?? this.interval,
      running: running ?? _running,
      id: id ?? _id,
      tag: tag ?? _tag,
    );
  }

  /// Initializes the timer.
  ///
  /// Returns null (timer starts stopped).
  @override
  Cmd? init() {
    return null;
  }

  /// Updates the timer based on incoming messages.
  @override
  (TimerModel, Cmd?) update(Msg msg) {
    switch (msg) {
      case TimerStartStopMsg():
        // Ignore messages for other timer instances.
        if (msg.tag != _tag) {
          return (this, null);
        }
        return (copyWith(running: msg.running), null);

      case TimerTickMsg():
        // Ignore messages for other timer instances.
        if (msg.tag != _tag) {
          return (this, null);
        }

        // If not running, ignore tick.
        if (!_running) {
          return (this, null);
        }

        // Check for timeout.
        if (msg.timeout) {
          return (copyWith(timeout: Duration.zero, running: false), null);
        }

        // Update timeout, ensuring it doesn't go negative.
        final newTimeout = timeout - interval;
        if (newTimeout <= Duration.zero) {
          return (
            copyWith(timeout: Duration.zero, running: false),
            _timedOut(),
          );
        }

        return (copyWith(timeout: newTimeout), _tick());

      default:
        return (this, null);
    }
  }

  /// Returns the view of the timer.
  ///
  /// By default returns the timeout formatted as MM:SS.
  /// Override this method or use a custom formatter for different display.
  @override
  String view() {
    final minutes = timeout.inMinutes;
    final seconds = timeout.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a command to start the timer.
  ///
  /// This will start emitting tick messages at the configured interval.
  Cmd start() {
    // Increment tag to ensure old ticks don't affect new timer runs.
    final newTag = _tag + 1;
    return Cmd.batch([
      Cmd.message(TimerStartStopMsg(true, newTag)),
      _tickWithTag(newTag),
    ]);
  }

  /// Creates a command to stop the timer.
  Cmd stop() {
    return Cmd.message(TimerStartStopMsg(false, _tag));
  }

  /// Creates a command to toggle the timer on/off.
  Cmd toggle() {
    if (_running) {
      return stop();
    }
    return start();
  }

  /// Internal: creates a tick command with the current tag.
  Cmd _tick() {
    return _tickWithTag(_tag);
  }

  /// Internal: creates a tick command with a specific tag.
  Cmd _tickWithTag(int tag) {
    return Cmd.tick(interval, (time) => TimerTickMsg(time, tag, false));
  }

  /// Internal: creates a timeout command.
  Cmd _timedOut() {
    return Cmd.message(TimerTickMsg(DateTime.now(), _tag, true));
  }
}
