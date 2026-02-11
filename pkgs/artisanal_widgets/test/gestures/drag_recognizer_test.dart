/// Unit tests for [DragGestureRecognizer].
///
/// Covers drag lifecycle: pointer-down + move beyond slop fires onDragStart
/// and onDragUpdate, release fires onDragEnd. Movement within slop does not
/// start drag. Tests delta calculations and Cmd accumulation.
library;

import 'package:artisanal/tui.dart'
    show Cmd, MouseMsg, MouseAction, MouseButton;
import 'package:artisanal_widgets/artisanal_widgets.dart' show Offset;
import 'package:artisanal_widgets/artisanal_widgets.dart'
    show
        DragGestureRecognizer,
        DragStartDetails,
        DragUpdateDetails,
        DragEndDetails,
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
  late DragGestureRecognizer recognizer;

  setUp(() {
    recognizer = DragGestureRecognizer();
  });

  tearDown(() {
    recognizer.dispose();
  });

  // -------------------------------------------------------------------------
  // Basic drag lifecycle
  // -------------------------------------------------------------------------

  group('basic drag lifecycle', () {
    test('fires onDragStart when movement exceeds slop', () {
      DragStartDetails? captured;
      recognizer.onDragStart = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(captured, isNull, reason: 'no drag on down alone');

      // Move by (2, 0) → squared distance = 4.0, kDragSlop*kDragSlop = 1.0.
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      expect(captured, isNotNull);
      expect(captured!.localPosition, equals(const Offset(5, 5)));
      expect(captured!.button, equals(MouseButton.left));
    });

    test('fires onDragUpdate with delta on subsequent moves', () {
      final updates = <DragUpdateDetails>[];
      recognizer.onDragStart = (_) => null;
      recognizer.onDragUpdate = (details) {
        updates.add(details);
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // First move beyond slop — triggers start + first update.
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      expect(updates.length, equals(1));
      // First update delta is from initial position to current.
      expect(updates[0].delta, equals(const Offset(2, 0)));

      // Second move.
      recognizer.handlePointerMove(_motion(9, 5), _local(9, 5));
      expect(updates.length, equals(2));
      // Delta is from last position (7,5) to current (9,5).
      expect(updates[1].delta, equals(const Offset(2, 0)));
    });

    test('fires onDragEnd on release after drag started', () {
      DragEndDetails? captured;
      recognizer.onDragStart = (_) => null;
      recognizer.onDragEnd = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      recognizer.handlePointerUp(_release(7, 5), _local(7, 5));
      expect(captured, isNotNull);
      expect(captured!.globalPosition, equals(const Offset(7, 5)));
    });

    test('full drag sequence: start → update → update → end', () {
      final sequence = <String>[];
      recognizer
        ..onDragStart = (_) {
          sequence.add('start');
          return null;
        }
        ..onDragUpdate = (_) {
          sequence.add('update');
          return null;
        }
        ..onDragEnd = (_) {
          sequence.add('end');
          return null;
        };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(
        _motion(7, 5),
        _local(7, 5),
      ); // start + update
      recognizer.handlePointerMove(_motion(9, 5), _local(9, 5)); // update
      recognizer.handlePointerUp(_release(9, 5), _local(9, 5)); // end
      expect(sequence, equals(['start', 'update', 'update', 'end']));
    });
  });

  // -------------------------------------------------------------------------
  // Slop handling
  // -------------------------------------------------------------------------

  group('slop handling', () {
    test('movement within slop does not start drag', () {
      var started = false;
      recognizer.onDragStart = (_) {
        started = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Move by (1, 0) → squared distance = 1.0, not > 1.0.
      recognizer.handlePointerMove(_motion(6, 5), _local(6, 5));
      expect(started, isFalse);
    });

    test('movement exactly at slop boundary does not start drag', () {
      var started = false;
      recognizer.onDragStart = (_) {
        started = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Move by (0, 1) → squared distance = 1.0, not > 1.0.
      recognizer.handlePointerMove(_motion(5, 6), _local(5, 6));
      expect(started, isFalse);
    });

    test('movement just beyond slop starts drag', () {
      var started = false;
      recognizer.onDragStart = (_) {
        started = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Move by (1, 1) → squared distance = 2.0, which is > 1.0.
      recognizer.handlePointerMove(_motion(6, 6), _local(6, 6));
      expect(started, isTrue);
    });

    test('no onDragEnd if drag never started', () {
      var endFired = false;
      recognizer.onDragEnd = (_) {
        endFired = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // Release without moving — no drag started.
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(endFired, isFalse);
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

    test('enters accepted state when drag starts', () {
      recognizer.onDragStart = (_) => null;
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      expect(recognizer.state, equals(GestureRecognizerState.accepted));
    });

    test('enters defunct state on release', () {
      recognizer.onDragStart = (_) => null;
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      recognizer.handlePointerUp(_release(7, 5), _local(7, 5));
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('reset returns to ready', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      recognizer.reset();
      expect(recognizer.state, equals(GestureRecognizerState.ready));
    });
  });

  // -------------------------------------------------------------------------
  // No prior pointer-down guard
  // -------------------------------------------------------------------------

  group('no prior pointer-down', () {
    test('handlePointerMove without prior down does not crash', () {
      // This tests the null guard added as a bug fix.
      recognizer.handlePointerMove(_motion(5, 5), _local(5, 5));
      // Should not throw.
    });
  });

  // -------------------------------------------------------------------------
  // Cmd accumulation
  // -------------------------------------------------------------------------

  group('cmd accumulation', () {
    test('drag callbacks accumulate Cmds', () {
      final cmd1 = Cmd.none();
      final cmd2 = Cmd.none();
      final cmd3 = Cmd.none();
      recognizer.onDragStart = (_) => cmd1;
      recognizer.onDragUpdate = (_) => cmd2;
      recognizer.onDragEnd = (_) => cmd3;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      recognizer.handlePointerUp(_release(7, 5), _local(7, 5));

      expect(recognizer.pendingCmds, contains(cmd1));
      expect(recognizer.pendingCmds, contains(cmd2));
      expect(recognizer.pendingCmds, contains(cmd3));
    });
  });

  // -------------------------------------------------------------------------
  // Arena integration
  // -------------------------------------------------------------------------

  group('arena integration', () {
    test('rejectGesture resets drag state', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
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
  // Delta calculations
  // -------------------------------------------------------------------------

  group('delta calculations', () {
    test('vertical drag has correct deltas', () {
      final updates = <DragUpdateDetails>[];
      recognizer.onDragStart = (_) => null;
      recognizer.onDragUpdate = (d) {
        updates.add(d);
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(
        _motion(5, 8),
        _local(5, 8),
      ); // start + update
      expect(updates.length, equals(1));
      expect(updates[0].delta.dx, equals(0));
      expect(updates[0].delta.dy, equals(3));

      recognizer.handlePointerMove(_motion(5, 10), _local(5, 10));
      expect(updates.length, equals(2));
      expect(updates[1].delta.dx, equals(0));
      expect(updates[1].delta.dy, equals(2));
    });

    test('diagonal drag has correct deltas', () {
      final updates = <DragUpdateDetails>[];
      recognizer.onDragStart = (_) => null;
      recognizer.onDragUpdate = (d) {
        updates.add(d);
        return null;
      };

      recognizer.handlePointerDown(_press(0, 0), _local(0, 0));
      recognizer.handlePointerMove(_motion(3, 4), _local(3, 4));
      expect(updates.length, equals(1));
      expect(updates[0].delta, equals(const Offset(3, 4)));
      expect(updates[0].globalPosition, equals(const Offset(3, 4)));
    });
  });
}
