/// Unit tests for [TapGestureRecognizer].
///
/// Covers the full lifecycle: pointer-down fires onTapDown, pointer-up
/// fires onTapUp + onTap (within slop), pointer-move beyond slop fires
/// onTapCancel, and state management across multiple tap sequences.
library;

import 'package:artisanal/tui.dart'
    show Cmd, MouseMsg, MouseAction, MouseButton;
import 'package:artisanal_widgets/artisanal_widgets.dart' show Offset;
import 'package:artisanal_widgets/artisanal_widgets.dart'
    show
        TapGestureRecognizer,
        TapDownDetails,
        TapUpDetails,
        GestureRecognizerState;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MouseMsg _press(int x, int y, {MouseButton button = MouseButton.left}) =>
    MouseMsg(action: MouseAction.press, button: button, x: x, y: y);

MouseMsg _release(int x, int y, {MouseButton button = MouseButton.left}) =>
    MouseMsg(action: MouseAction.release, button: button, x: x, y: y);

MouseMsg _motion(int x, int y) =>
    MouseMsg(action: MouseAction.motion, button: MouseButton.none, x: x, y: y);

Offset _local(int x, int y) => Offset(x.toDouble(), y.toDouble());

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late TapGestureRecognizer recognizer;

  setUp(() {
    recognizer = TapGestureRecognizer();
  });

  tearDown(() {
    recognizer.dispose();
  });

  // -------------------------------------------------------------------------
  // Basic tap lifecycle
  // -------------------------------------------------------------------------

  group('basic tap lifecycle', () {
    test('onTap fires on press + release within slop', () {
      var tapped = false;
      recognizer.onTap = () {
        tapped = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(tapped, isFalse, reason: 'tap should not fire on down alone');

      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(tapped, isTrue);
    });

    test('onTapDown fires on pointer-down', () {
      TapDownDetails? captured;
      recognizer.onTapDown = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(3, 7), _local(3, 7));
      expect(captured, isNotNull);
      expect(captured!.globalPosition, equals(const Offset(3, 7)));
      expect(captured!.localPosition, equals(const Offset(3, 7)));
      expect(captured!.button, equals(MouseButton.left));
    });

    test('onTapUp fires on pointer-up within slop', () {
      TapUpDetails? captured;
      recognizer.onTapUp = (details) {
        captured = details;
        return null;
      };

      recognizer.handlePointerDown(_press(2, 2), _local(2, 2));
      recognizer.handlePointerUp(_release(2, 2), _local(2, 2));
      expect(captured, isNotNull);
      expect(captured!.globalPosition, equals(const Offset(2, 2)));
    });

    test('callback sequence: onTapDown → onTapUp → onTap', () {
      final sequence = <String>[];
      recognizer
        ..onTapDown = (_) {
          sequence.add('tapDown');
          return null;
        }
        ..onTapUp = (_) {
          sequence.add('tapUp');
          return null;
        }
        ..onTap = () {
          sequence.add('tap');
          return null;
        };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(sequence, equals(['tapDown', 'tapUp', 'tap']));
    });

    test('does not fire onTap on press alone', () {
      var tapCount = 0;
      recognizer.onTap = () {
        tapCount++;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(tapCount, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // Slop handling
  // -------------------------------------------------------------------------

  group('slop handling', () {
    test('small movement within slop still allows tap', () {
      var tapped = false;
      recognizer.onTap = () {
        tapped = true;
        return null;
      };

      // kTouchSlop = 2.0 (compared against squared distance).
      // Move by (1, 0) → squared distance = 1.0, which is <= 2.0.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(6, 5), _local(6, 5));
      recognizer.handlePointerUp(_release(6, 5), _local(6, 5));
      expect(tapped, isTrue);
    });

    test('movement beyond slop cancels tap', () {
      var tapped = false;
      var cancelled = false;
      recognizer
        ..onTap = () {
          tapped = true;
          return null;
        }
        ..onTapCancel = () {
          cancelled = true;
          return null;
        };

      // Move by (2, 0) → squared distance = 4.0, which is > 2.0.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(7, 5), _local(7, 5));
      expect(cancelled, isTrue);
      expect(tapped, isFalse);

      // Even if we release, onTap should not fire.
      recognizer.handlePointerUp(_release(7, 5), _local(7, 5));
      expect(tapped, isFalse);
    });

    test('diagonal movement within slop allows tap', () {
      var tapped = false;
      recognizer.onTap = () {
        tapped = true;
        return null;
      };

      // Move by (1, 1) → squared distance = 2.0, which is NOT > 2.0.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(6, 6), _local(6, 6));
      recognizer.handlePointerUp(_release(6, 6), _local(6, 6));
      expect(tapped, isTrue);
    });

    test('diagonal movement beyond slop cancels tap', () {
      var cancelled = false;
      recognizer.onTapCancel = () {
        cancelled = true;
        return null;
      };

      // Move by (1, 2) → squared distance = 5.0, which is > 2.0.
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(6, 7), _local(6, 7));
      expect(cancelled, isTrue);
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

    test('enters defunct state on pointer-up after tap', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('enters defunct state after rejection', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerMove(_motion(20, 20), _local(20, 20));
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('reset returns to ready state', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      recognizer.reset();
      expect(recognizer.state, equals(GestureRecognizerState.ready));
      expect(recognizer.initialPosition, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Cmd accumulation
  // -------------------------------------------------------------------------

  group('cmd accumulation', () {
    test('onTap callback Cmd is added to pendingCmds', () {
      final testCmd = Cmd.none();
      recognizer.onTap = () => testCmd;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(recognizer.pendingCmds, contains(testCmd));
    });

    test('null return from callback does not add to pendingCmds', () {
      recognizer.onTap = () => null;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      // pendingCmds should have nothing from onTapDown since it's null
      final countAfterDown = recognizer.pendingCmds.length;
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      // onTap returned null, so no new cmds
      expect(recognizer.pendingCmds.length, equals(countAfterDown));
    });

    test('multiple callbacks accumulate Cmds', () {
      final cmd1 = Cmd.none();
      final cmd2 = Cmd.none();
      final cmd3 = Cmd.none();
      recognizer.onTapDown = (_) => cmd1;
      recognizer.onTapUp = (_) => cmd2;
      recognizer.onTap = () => cmd3;

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(recognizer.pendingCmds, equals([cmd1, cmd2, cmd3]));
    });

    test('reset clears pendingCmds', () {
      recognizer.onTap = () => Cmd.none();
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(recognizer.pendingCmds, isNotEmpty);

      recognizer.reset();
      expect(recognizer.pendingCmds, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Modifier keys
  // -------------------------------------------------------------------------

  group('modifier keys', () {
    test('TapDownDetails captures ctrl modifier', () {
      TapDownDetails? captured;
      recognizer.onTapDown = (d) {
        captured = d;
        return null;
      };

      recognizer.handlePointerDown(
        MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 5,
          y: 5,
          ctrl: true,
        ),
        _local(5, 5),
      );
      expect(captured!.ctrl, isTrue);
      expect(captured!.hasModifier, isTrue);
    });

    test('TapDownDetails captures alt modifier', () {
      TapDownDetails? captured;
      recognizer.onTapDown = (d) {
        captured = d;
        return null;
      };

      recognizer.handlePointerDown(
        MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 5,
          y: 5,
          alt: true,
        ),
        _local(5, 5),
      );
      expect(captured!.alt, isTrue);
      expect(captured!.hasModifier, isTrue);
    });

    test('TapDownDetails captures shift modifier', () {
      TapDownDetails? captured;
      recognizer.onTapDown = (d) {
        captured = d;
        return null;
      };

      recognizer.handlePointerDown(
        MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 5,
          y: 5,
          shift: true,
        ),
        _local(5, 5),
      );
      expect(captured!.shift, isTrue);
      expect(captured!.hasModifier, isTrue);
    });

    test('TapDownDetails captures right button', () {
      TapDownDetails? captured;
      recognizer.onTapDown = (d) {
        captured = d;
        return null;
      };

      recognizer.handlePointerDown(
        _press(5, 5, button: MouseButton.right),
        _local(5, 5),
      );
      expect(captured!.button, equals(MouseButton.right));
    });
  });

  // -------------------------------------------------------------------------
  // acceptGesture / rejectGesture
  // -------------------------------------------------------------------------

  group('arena integration', () {
    test('acceptGesture sets state to accepted', () {
      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.acceptGesture();
      expect(recognizer.state, equals(GestureRecognizerState.accepted));
    });

    test('rejectGesture fires onTapCancel when in possible state', () {
      var cancelled = false;
      recognizer.onTapCancel = () {
        cancelled = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      expect(recognizer.state, equals(GestureRecognizerState.possible));
      recognizer.rejectGesture();
      expect(cancelled, isTrue);
      expect(recognizer.state, equals(GestureRecognizerState.defunct));
    });

    test('rejectGesture does not fire onTapCancel when not possible', () {
      var cancelled = false;
      recognizer.onTapCancel = () {
        cancelled = true;
        return null;
      };

      // Already defunct (never started).
      recognizer.state = GestureRecognizerState.defunct;
      recognizer.rejectGesture();
      expect(cancelled, isFalse);
    });

    test('tap fires after acceptance', () {
      var tapped = false;
      recognizer.onTap = () {
        tapped = true;
        return null;
      };

      recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
      recognizer.acceptGesture();
      expect(tapped, isFalse, reason: 'acceptance alone does not fire tap');

      recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
      expect(tapped, isTrue, reason: 'tap fires on up after acceptance');
    });
  });

  // -------------------------------------------------------------------------
  // Multiple tap sequences
  // -------------------------------------------------------------------------

  group('multiple sequences', () {
    test('can tap multiple times with reset between', () {
      var tapCount = 0;
      recognizer.onTap = () {
        tapCount++;
        return null;
      };

      for (var i = 0; i < 3; i++) {
        recognizer.handlePointerDown(_press(5, 5), _local(5, 5));
        recognizer.handlePointerUp(_release(5, 5), _local(5, 5));
        recognizer.reset();
      }
      expect(tapCount, equals(3));
    });
  });
}
