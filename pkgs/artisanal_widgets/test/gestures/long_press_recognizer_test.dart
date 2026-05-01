/// Unit tests for [LongPressGestureRecognizer].
///
/// Covers the long-press lifecycle: hold for duration fires callbacks,
/// release before duration does not, movement beyond slop cancels, and
/// proper Cmd accumulation.
library;

import 'package:artisanal/tui.dart'
    show Cmd, MouseMsg, MouseAction, MouseButton;
import 'package:artisanal_widgets/artisanal_widgets.dart' show Offset;
import 'package:artisanal_widgets/artisanal_widgets.dart'
    show
        LongPressGestureRecognizer,
        LongPressStartDetails,
        LongPressEndDetails,
        GestureRecognizerState,
        GestureTimerHandle;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MouseMsg _press(int x, int y) =>
    MouseMsg(action: MouseAction.press, button: MouseButton.left, x: x, y: y);

MouseMsg _release(int x, int y) =>
    MouseMsg(action: MouseAction.release, button: MouseButton.left, x: x, y: y);

MouseMsg _motion(int x, int y) =>
    MouseMsg(action: MouseAction.motion, button: MouseButton.none, x: x, y: y);

Offset _local(int x, int y) => Offset(x.toDouble(), y.toDouble());

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late LongPressGestureRecognizer recognizer;
  late _FakeGestureTimerFactory timers;

  setUp(() {
    timers = _FakeGestureTimerFactory();
    recognizer = LongPressGestureRecognizer(timerFactory: timers.call);
    recognizer.duration = const Duration(milliseconds: 100);
  });

  tearDown(() {
    recognizer.dispose();
  });

  // -------------------------------------------------------------------------
  // Basic long-press
  // -------------------------------------------------------------------------

  group('basic long-press', () {
    test('fires onLongPress after holding for duration', () {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(longPressed, isFalse, reason: 'should not fire immediately');
      timers.fireNext();
      expect(longPressed, isTrue);
    });

    test('fires onLongPressStart with position details', () {
      LongPressStartDetails? captured;
      recognizer.onLongPressStart = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(3, 7), _local(3, 7));
      timers.fireNext();

      expect(captured, isNotNull);
      expect(captured!.globalPosition, equals(const Offset(3, 7)));
      expect(captured!.localPosition, equals(const Offset(3, 7)));
    });

    test('fires onLongPressEnd on release after long-press', () {
      LongPressEndDetails? captured;
      recognizer.onLongPressEnd = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      timers.fireNext();

      recognizer.handlePointerUp(_release(6, 6), _local(6, 6));
      expect(captured, isNotNull);
      expect(captured!.globalPosition, equals(const Offset(6, 6)));
    });

    test(
      'callback sequence: onLongPressStart → onLongPress → ... → onLongPressEnd',
      () {
        final sequence = <String>[];
        recognizer
          ..onLongPressStart = (_) {
            sequence.add('start');
            return null;
          }
          ..onLongPress = () {
            sequence.add('longPress');
            return null;
          }
          ..onLongPressEnd = (_) {
            sequence.add('end');
            return null;
          };

        recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
        timers.fireNext();
        recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

        expect(sequence, equals(['start', 'longPress', 'end']));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Cancellation
  // -------------------------------------------------------------------------

  group('cancellation', () {
    test('release before timer fires does not trigger long-press', () {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      timers.fireAll();
      expect(longPressed, isFalse);
    });

    test('movement beyond slop cancels long-press', () {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Move far beyond kTouchSlop = 2.0 (uses squared distance comparison).
      // Move by (3, 0) → squared dist = 9.0, threshold is 2.0*2.0 = 4.0.
      recognizer.handlePointerMove(_motion(8, 5), _local(8, 5));

      timers.fireAll();
      expect(longPressed, isFalse);
    });

    test('small movement within slop does not cancel', () {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Move by (1, 0) → squared dist = 1.0, threshold is 4.0.
      recognizer.handlePointerMove(_motion(6, 5), _local(6, 5));

      timers.fireNext();
      expect(longPressed, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // State management
  // -------------------------------------------------------------------------

  group('state management', () {
    test('starts in ready state', () {
      expect(recognizer.state, equals(GestureRecognizerState.ready));
    });

    test('enters possible state on pointer-down', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(recognizer.state, equals(GestureRecognizerState.possible));
    });

    test('enters accepted state after timer fires', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      timers.fireNext();
      expect(recognizer.state, equals(GestureRecognizerState.accepted));
    });

    test('enters defunct state on pointer-up after long-press', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      timers.fireNext();
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('enters defunct state on rejection', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.rejectGesture();
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('reset clears timer and returns to ready', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.reset();
      expect(recognizer.state, equals(GestureRecognizerState.ready));
    });
  });

  // -------------------------------------------------------------------------
  // Cmd accumulation
  // -------------------------------------------------------------------------

  group('cmd accumulation', () {
    test('long-press callbacks accumulate Cmds', () {
      final cmd1 = Cmd.none();
      final cmd2 = Cmd.none();
      final cmd3 = Cmd.none();
      recognizer.onLongPressStart = (_) => cmd1;
      recognizer.onLongPress = () => cmd2;
      recognizer.onLongPressEnd = (_) => cmd3;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      timers.fireNext();
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      expect(recognizer.pendingCmds, contains(cmd1));
      expect(recognizer.pendingCmds, contains(cmd2));
      expect(recognizer.pendingCmds, contains(cmd3));
    });
  });

  // -------------------------------------------------------------------------
  // Configurable duration
  // -------------------------------------------------------------------------

  group('configurable duration', () {
    test('longer duration delays long-press', () {
      recognizer.duration = const Duration(milliseconds: 200);
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(longPressed, isFalse, reason: 'not enough time');
      timers.fireNext();
      expect(longPressed, isTrue, reason: 'enough time now');
    });
  });
}

final class _FakeGestureTimerFactory {
  final List<_FakeGestureTimerHandle> _timers = <_FakeGestureTimerHandle>[];

  GestureTimerHandle call(Duration delay, void Function() callback) {
    final timer = _FakeGestureTimerHandle(delay, callback);
    _timers.add(timer);
    return timer;
  }

  void fireNext() {
    final timer = _timers.firstWhere((timer) => !timer.isCanceled);
    timer.fire();
  }

  void fireAll() {
    for (final timer in _timers.where((timer) => !timer.isCanceled).toList()) {
      timer.fire();
    }
  }
}

final class _FakeGestureTimerHandle implements GestureTimerHandle {
  _FakeGestureTimerHandle(this.delay, this._callback);

  final Duration delay;
  final void Function() _callback;
  bool isCanceled = false;

  @override
  void cancel() {
    isCanceled = true;
  }

  void fire() {
    if (isCanceled) return;
    isCanceled = true;
    _callback();
  }
}
