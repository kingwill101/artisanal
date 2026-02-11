/// Unit tests for [DoubleTapGestureRecognizer].
///
/// Covers double-tap detection: two taps within timeout and slop fire
/// onDoubleTap; single tap with timeout expiry does not; taps too far
/// apart spatially reset the sequence.
library;

import 'package:artisanal/tui.dart'
    show Cmd, MouseMsg, MouseAction, MouseButton;
import 'package:artisanal_widgets/artisanal_widgets.dart' show Offset;
import 'package:artisanal_widgets/artisanal_widgets.dart'
    show DoubleTapGestureRecognizer, GestureRecognizerState;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MouseMsg _press(int x, int y) =>
    MouseMsg(action: MouseAction.press, button: MouseButton.left, x: x, y: y);

MouseMsg _release(int x, int y) =>
    MouseMsg(action: MouseAction.release, button: MouseButton.left, x: x, y: y);

Offset _local(int x, int y) => Offset(x.toDouble(), y.toDouble());

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late DoubleTapGestureRecognizer recognizer;

  setUp(() {
    recognizer = DoubleTapGestureRecognizer();
  });

  tearDown(() {
    recognizer.dispose();
  });

  // -------------------------------------------------------------------------
  // Basic double-tap
  // -------------------------------------------------------------------------

  group('basic double-tap', () {
    test('fires onDoubleTap on two taps within timeout and slop', () {
      var doubleTapped = false;
      recognizer.onDoubleTap = () {
        doubleTapped = true;
        return null;
      };

      // First tap.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(doubleTapped, isFalse, reason: 'first tap alone');

      // Second tap immediately.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(doubleTapped, isTrue);
    });

    test('does not fire on single tap', () {
      var doubleTapped = false;
      recognizer.onDoubleTap = () {
        doubleTapped = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(doubleTapped, isFalse);
    });

    test('second tap within slop (1 cell) fires', () {
      var doubleTapped = false;
      recognizer.onDoubleTap = () {
        doubleTapped = true;
        return null;
      };

      // First tap at (5, 5).
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      // Second tap at (6, 5) — distance = 1.0, within kDoubleTapSlop of 2.0.
      recognizer.handlePointerDown(_press(6, 5), _local(6, 5));
      recognizer.handlePointerUp(_release(6, 5), _local(6, 5));
      expect(doubleTapped, isTrue);
    });

    test('second tap beyond slop resets to new first tap', () {
      var doubleTapCount = 0;
      recognizer.onDoubleTap = () {
        doubleTapCount++;
        return null;
      };

      // First tap at (5, 5).
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      // Second tap at (10, 5) — distance = 5.0, beyond slop.
      // _magnitude returns squared distance = 25.0, kDoubleTapSlop = 2.0
      // 25.0 > 2.0, so it resets.
      recognizer.handlePointerDown(_press(10, 5), _local(10, 5));
      recognizer.handlePointerUp(_release(10, 5), _local(10, 5));
      expect(doubleTapCount, equals(0), reason: 'too far apart');

      // Now another tap at the same position should complete a double-tap.
      recognizer.handlePointerDown(_press(10, 5), _local(10, 5));
      recognizer.handlePointerUp(_release(10, 5), _local(10, 5));
      expect(doubleTapCount, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Timeout behavior
  // -------------------------------------------------------------------------

  group('timeout', () {
    test('timeout expires between taps resets sequence', () async {
      var doubleTapped = false;
      recognizer.onDoubleTap = () {
        doubleTapped = true;
        return null;
      };

      // First tap.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      // Wait longer than doubleTapTimeout (300ms).
      await Future<void>.delayed(const Duration(milliseconds: 350));

      // Second tap — should NOT count as double-tap.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(doubleTapped, isFalse, reason: 'timeout expired');
    });

    test('taps within timeout window fire double-tap', () async {
      var doubleTapped = false;
      recognizer.onDoubleTap = () {
        doubleTapped = true;
        return null;
      };

      // First tap.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      // Wait shorter than timeout.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Second tap — should fire.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(doubleTapped, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // State management
  // -------------------------------------------------------------------------

  group('state management', () {
    test('enters defunct after double-tap', () {
      recognizer.onDoubleTap = () => null;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('reset clears timer and state', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      recognizer.reset();
      expect(recognizer.state, equals(GestureRecognizerState.ready));
    });

    test('dispose cancels timer', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      // Should not throw.
      recognizer.dispose();
      expect(recognizer.state, equals(GestureRecognizerState.ready));
    });
  });

  // -------------------------------------------------------------------------
  // Arena integration
  // -------------------------------------------------------------------------

  group('arena integration', () {
    test('rejectGesture resets double-tap state', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));

      recognizer.rejectGesture();
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('acceptGesture sets accepted state', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.acceptGesture();
      expect(recognizer.state, equals(GestureRecognizerState.accepted));
    });
  });

  // -------------------------------------------------------------------------
  // Cmd accumulation
  // -------------------------------------------------------------------------

  group('cmd accumulation', () {
    test('onDoubleTap Cmd is added to pendingCmds', () {
      final testCmd = Cmd.none();
      recognizer.onDoubleTap = () => testCmd;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(recognizer.pendingCmds, contains(testCmd));
    });
  });
}
