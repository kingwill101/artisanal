/// Tap and double-tap gesture recognizers.
///
/// [TapGestureRecognizer] handles single taps (press + release within slop).
/// [DoubleTapGestureRecognizer] handles two taps in quick succession.
library;

import 'dart:async' show Timer;

import 'package:artisanal/tui.dart' show MouseMsg;

import '../layout/geometry.dart' show Offset;
import 'events.dart';
import 'recognizer.dart';

// ---------------------------------------------------------------------------
// TapGestureRecognizer
// ---------------------------------------------------------------------------

/// Recognizes single-tap gestures.
///
/// A tap is defined as a pointer-down followed by a pointer-up within
/// [kTouchSlop] cells of movement. If the pointer moves beyond the slop
/// before release, the tap is cancelled.
class TapGestureRecognizer extends GestureRecognizer {
  /// Callback fired when the pointer goes down.
  GestureTapDownCallback? onTapDown;

  /// Callback fired when the pointer goes up (within slop).
  GestureTapUpCallback? onTapUp;

  /// Callback fired after a successful tap (down + up within slop).
  GestureTapCallback? onTap;

  /// Callback fired when the tap is cancelled (pointer moved beyond slop).
  GestureTapCancelCallback? onTapCancel;

  /// Maximum distance in cells the pointer can move before the tap
  /// is cancelled.
  static const double kTouchSlop = 2.0;

  Offset? _downGlobal;
  Offset? _downLocal;

  @override
  void handlePointerDown(MouseMsg event, Offset localPosition) {
    super.handlePointerDown(event, localPosition);
    _downGlobal = Offset(event.x.toDouble(), event.y.toDouble());
    _downLocal = localPosition;

    addCmd(
      onTapDown?.call(
        TapDownDetails(
          globalPosition: _downGlobal!,
          localPosition: _downLocal!,
          button: event.button,
          ctrl: event.ctrl,
          alt: event.alt,
          shift: event.shift,
        ),
      ),
    );
  }

  @override
  void handlePointerMove(MouseMsg event, Offset localPosition) {
    if (state != GestureRecognizerState.possible) return;

    final delta = localPosition - initialPosition!;
    final distance = _magnitude(delta);
    if (distance > kTouchSlop) {
      // Moved too far — this is not a tap.
      addCmd(onTapCancel?.call());
      resolve(GestureDisposition.rejected);
    }
  }

  @override
  void handlePointerUp(MouseMsg event, Offset localPosition) {
    if (state == GestureRecognizerState.possible ||
        state == GestureRecognizerState.accepted) {
      final globalPos = Offset(event.x.toDouble(), event.y.toDouble());

      addCmd(
        onTapUp?.call(
          TapUpDetails(globalPosition: globalPos, localPosition: localPosition),
        ),
      );
      addCmd(onTap?.call());

      state = GestureRecognizerState.defunct;
    }
  }

  @override
  void acceptGesture() {
    state = GestureRecognizerState.accepted;
  }

  @override
  void rejectGesture() {
    if (state == GestureRecognizerState.possible) {
      addCmd(onTapCancel?.call());
    }
    state = GestureRecognizerState.defunct;
  }

  @override
  void reset() {
    super.reset();
    _downGlobal = null;
    _downLocal = null;
  }
}

// ---------------------------------------------------------------------------
// DoubleTapGestureRecognizer
// ---------------------------------------------------------------------------

/// Recognizes double-tap gestures.
///
/// A double-tap is two taps within [doubleTapTimeout] and [kDoubleTapSlop]
/// cells of each other.
class DoubleTapGestureRecognizer extends GestureRecognizer {
  /// Callback fired when a double-tap is detected.
  GestureDoubleTapCallback? onDoubleTap;

  /// Maximum time between the two taps.
  static const Duration doubleTapTimeout = Duration(milliseconds: 300);

  /// Maximum distance in cells between the two tap locations.
  static const double kDoubleTapSlop = 2.0;

  Offset? _firstTapPosition;
  Timer? _doubleTapTimer;
  bool _waitingForSecondTap = false;

  @override
  void handlePointerDown(MouseMsg event, Offset localPosition) {
    super.handlePointerDown(event, localPosition);

    if (_waitingForSecondTap) {
      // Check if this is within slop of the first tap.
      final delta = localPosition - _firstTapPosition!;
      if (_magnitude(delta) <= kDoubleTapSlop) {
        // This could be the second tap of a double-tap.
        // We'll confirm on pointer-up.
      } else {
        // Too far from first tap — reset and treat as new first tap.
        _resetDoubleTap();
        _firstTapPosition = localPosition;
      }
    } else {
      _firstTapPosition = localPosition;
    }
  }

  @override
  void handlePointerUp(MouseMsg event, Offset localPosition) {
    if (state != GestureRecognizerState.possible) return;

    if (_waitingForSecondTap) {
      // Second tap completed — fire double-tap.
      _doubleTapTimer?.cancel();
      _doubleTapTimer = null;
      _waitingForSecondTap = false;
      addCmd(onDoubleTap?.call());
      state = GestureRecognizerState.defunct;
    } else {
      // First tap completed — start waiting for second.
      _waitingForSecondTap = true;
      _doubleTapTimer = Timer(doubleTapTimeout, () {
        // Timeout — no double-tap.
        _resetDoubleTap();
      });
    }
  }

  @override
  void handlePointerMove(MouseMsg event, Offset localPosition) {
    // Movement during either tap is OK as long as it's within slop.
    // Large movements would be caught by the tap recognizer, not here.
  }

  @override
  void acceptGesture() {
    state = GestureRecognizerState.accepted;
  }

  @override
  void rejectGesture() {
    _resetDoubleTap();
    state = GestureRecognizerState.defunct;
  }

  void _resetDoubleTap() {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    _waitingForSecondTap = false;
    _firstTapPosition = null;
  }

  @override
  void reset() {
    _resetDoubleTap();
    super.reset();
  }

  @override
  void dispose() {
    _resetDoubleTap();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

/// Euclidean magnitude of an offset (used for slop checks).
double _magnitude(Offset delta) {
  return (delta.dx * delta.dx + delta.dy * delta.dy);
}
