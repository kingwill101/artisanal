import '../cmd.dart';
import '../key.dart';
import '../component.dart';
import '../msg.dart';

DateTime _defaultPauseNowProvider() => DateTime.now();

/// A simple "press any key" pause model.
///
/// This is a small convenience bubble that mirrors the legacy "pause"
/// behavior (previously exposed as `PauseComponent`).
class PauseModel extends ViewComponent {
  PauseModel({this.message = 'Press any key to continue...'});

  final String message;

  @override
  Cmd? init() => null;

  @override
  (PauseModel, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      return (this, Cmd.quit());
    }
    return (this, null);
  }

  @override
  String view() => message;
}

/// A countdown model built on top of [TimerModel].
///
/// This is a convenience bubble for the legacy countdown behavior (previously
/// exposed as `CountdownComponent`).
class CountdownModel extends ViewComponent {
  static const Object _startTickId = 'countdown:start';
  static const Object _tickId = 'countdown:tick';

  CountdownModel({
    required this.duration,
    this.message = 'Continuing in',
    this.interval = const Duration(seconds: 1),
    DateTime Function()? nowProvider,
  }) : _remaining = duration,
       _nowProvider = nowProvider ?? _defaultPauseNowProvider;

  final Duration duration;
  final Duration interval;
  final String message;
  final DateTime Function() _nowProvider;
  Duration _remaining;

  @override
  Cmd? init() => _start();

  @override
  (CountdownModel, Cmd?) update(Msg msg) {
    if (msg is KeyMsg &&
        (msg.key.type == KeyType.escape ||
            (msg.key.ctrl &&
                msg.key.runes.isNotEmpty &&
                msg.key.runes.first == 0x63))) {
      return (this, Cmd.quit());
    }

    if (msg is TickMsg) {
      if (msg.id == _startTickId) {
        return (
          this,
          Cmd.tick(
            interval,
            (time) => TickMsg(time, id: _tickId),
            nowProvider: _nowProvider,
          ),
        );
      }

      if (msg.id == _tickId) {
        final newRemaining = _remaining - interval;
        if (newRemaining <= Duration.zero) {
          _remaining = Duration.zero;
          return (this, Cmd.quit());
        }
        _remaining = newRemaining;
        return (
          this,
          Cmd.tick(
            interval,
            (time) => TickMsg(time, id: _tickId),
            nowProvider: _nowProvider,
          ),
        );
      }
    }

    return (this, null);
  }

  /// Creates a command to start the countdown timer.
  ///
  /// This sends a start tick immediately so the first render shows full duration.
  Cmd _start() {
    return Cmd(() async => TickMsg(_nowProvider(), id: _startTickId));
  }

  @override
  String view() {
    final seconds = _remaining.inSeconds;
    return '$message ${seconds}s';
  }
}
