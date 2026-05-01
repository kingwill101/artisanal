/// Timer abstractions for deterministic gesture tests.
library;

import 'dart:async' show Timer;

/// Cancelable handle returned by a gesture timer factory.
abstract interface class GestureTimerHandle {
  /// Cancels the pending timer callback.
  void cancel();
}

/// Factory used by gesture recognizers to schedule time-based transitions.
typedef GestureTimerFactory =
    GestureTimerHandle Function(Duration delay, void Function() callback);

/// Default timer factory backed by `dart:async` [Timer].
GestureTimerHandle defaultGestureTimerFactory(
  Duration delay,
  void Function() callback,
) {
  return _DartGestureTimerHandle(Timer(delay, callback));
}

final class _DartGestureTimerHandle implements GestureTimerHandle {
  _DartGestureTimerHandle(this._timer);

  final Timer _timer;

  @override
  void cancel() {
    _timer.cancel();
  }
}
