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
        GestureRecognizerState;
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

  setUp(() {
    recognizer = LongPressGestureRecognizer();
    // Use a short but not too short duration for tests to avoid races.
    recognizer.duration = const Duration(milliseconds: 100);
  });

  tearDown(() {
    recognizer.dispose();
  });

  // -------------------------------------------------------------------------
  // Basic long-press
  // -------------------------------------------------------------------------

  group('basic long-press', () {
    test('fires onLongPress after holding for duration', () async {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(longPressed, isFalse, reason: 'should not fire immediately');

      // Wait for timer to fire (duration=100ms, wait 200ms for safety).
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(longPressed, isTrue);
    });

    test('fires onLongPressStart with position details', () async {
      LongPressStartDetails? captured;
      recognizer.onLongPressStart = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(3, 7), _local(3, 7));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(captured, isNotNull);
      expect(captured!.globalPosition, equals(const Offset(3, 7)));
      expect(captured!.localPosition, equals(const Offset(3, 7)));
    });

    test('fires onLongPressEnd on release after long-press', () async {
      LongPressEndDetails? captured;
      recognizer.onLongPressEnd = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      recognizer.handlePointerUp(_release(6, 6), _local(6, 6));
      expect(captured, isNotNull);
      expect(captured!.globalPosition, equals(const Offset(6, 6)));
    });

    test(
      'callback sequence: onLongPressStart → onLongPress → ... → onLongPressEnd',
      () async {
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
        await Future<void>.delayed(const Duration(milliseconds: 200));
        recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

        expect(sequence, equals(['start', 'longPress', 'end']));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Cancellation
  // -------------------------------------------------------------------------

  group('cancellation', () {
    test('release before timer fires does not trigger long-press', () async {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Release immediately — before 100ms timer.
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      // Wait to make sure timer would have fired.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(longPressed, isFalse);
    });

    test('movement beyond slop cancels long-press', () async {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Move far beyond kTouchSlop = 2.0 (uses squared distance comparison).
      // Move by (3, 0) → squared dist = 9.0, threshold is 2.0*2.0 = 4.0.
      recognizer.handlePointerMove(_motion(8, 5), _local(8, 5));

      // Wait to see if timer fires.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(longPressed, isFalse);
    });

    test('small movement within slop does not cancel', () async {
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Move by (1, 0) → squared dist = 1.0, threshold is 4.0.
      recognizer.handlePointerMove(_motion(6, 5), _local(6, 5));

      await Future<void>.delayed(const Duration(milliseconds: 200));
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

    test('enters accepted state after timer fires', () async {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(recognizer.state, equals(GestureRecognizerState.accepted));
    });

    test('enters defunct state on pointer-up after long-press', () async {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      await Future<void>.delayed(const Duration(milliseconds: 200));
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
    test('long-press callbacks accumulate Cmds', () async {
      final cmd1 = Cmd.none();
      final cmd2 = Cmd.none();
      final cmd3 = Cmd.none();
      recognizer.onLongPressStart = (_) => cmd1;
      recognizer.onLongPress = () => cmd2;
      recognizer.onLongPressEnd = (_) => cmd3;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      await Future<void>.delayed(const Duration(milliseconds: 200));
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
    test('longer duration delays long-press', () async {
      recognizer.duration = const Duration(milliseconds: 200);
      var longPressed = false;
      recognizer.onLongPress = () {
        longPressed = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(longPressed, isFalse, reason: 'not enough time');

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(longPressed, isTrue, reason: 'enough time now');
    });
  });
}
