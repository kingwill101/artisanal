/// Unit tests for [GestureArenaManager].
///
/// Covers arena creation, member addition, conflict resolution (first
/// acceptor wins, last-man-standing auto-wins), close/sweep behavior,
/// and disposal.
library;

import 'package:artisanal/tui.dart' show MouseMsg, MouseAction, MouseButton;
import 'package:artisanal_widgets/artisanal_widgets.dart' show Offset;
import 'package:artisanal_widgets/artisanal_widgets.dart'
    show
        GestureArenaManager,
        GestureRecognizer,
        GestureRecognizerState,
        GestureDisposition,
        TapGestureRecognizer,
        DragGestureRecognizer;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Test recognizer that records accept/reject calls
// ---------------------------------------------------------------------------

class _TestRecognizer extends GestureRecognizer {
  bool accepted = false;
  bool rejected = false;
  int acceptCount = 0;
  int rejectCount = 0;

  @override
  void handlePointerUp(MouseMsg event, Offset localPosition) {}

  @override
  void handlePointerMove(MouseMsg event, Offset localPosition) {}

  @override
  void acceptGesture() {
    state = GestureRecognizerState.accepted;
    accepted = true;
    acceptCount++;
  }

  @override
  void rejectGesture() {
    state = GestureRecognizerState.defunct;
    rejected = true;
    rejectCount++;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late GestureArenaManager manager;

  setUp(() {
    manager = GestureArenaManager();
  });

  tearDown(() {
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // Arena creation
  // -------------------------------------------------------------------------

  group('arena creation', () {
    test('createArena returns sequential keys', () {
      final key1 = manager.createArena();
      final key2 = manager.createArena();
      expect(key2, greaterThan(key1));
    });

    test('hasActiveArenas tracks active arenas', () {
      expect(manager.hasActiveArenas, isFalse);
      final key = manager.createArena();
      expect(manager.hasActiveArenas, isTrue);
      manager.close(key);
      expect(manager.hasActiveArenas, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Resolution: first acceptor wins
  // -------------------------------------------------------------------------

  group('first acceptor wins', () {
    test('accepting member wins, others are rejected', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r2 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r3 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key, r1);
      manager.add(key, r2);
      manager.add(key, r3);

      // r2 claims acceptance.
      manager.resolve(key, r2, GestureDisposition.accepted);

      expect(r2.accepted, isTrue);
      expect(r1.rejected, isTrue);
      expect(r3.rejected, isTrue);
    });

    test('arena is removed after acceptance', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;
      manager.add(key, r1);

      manager.resolve(key, r1, GestureDisposition.accepted);
      expect(manager.hasActiveArenas, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Resolution: member rejects itself
  // -------------------------------------------------------------------------

  group('self-rejection', () {
    test('last remaining member auto-wins', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r2 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key, r1);
      manager.add(key, r2);

      // r1 rejects itself — r2 is the last one, auto-wins.
      manager.resolve(key, r1, GestureDisposition.rejected);

      expect(r1.rejected, isTrue);
      expect(r2.accepted, isTrue);
      expect(manager.hasActiveArenas, isFalse);
    });

    test('two of three reject — third auto-wins', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r2 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r3 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key, r1);
      manager.add(key, r2);
      manager.add(key, r3);

      manager.resolve(key, r1, GestureDisposition.rejected);
      // r1 rejected, 2 remain — no auto-win yet.
      expect(r2.accepted, isFalse);
      expect(r3.accepted, isFalse);

      manager.resolve(key, r2, GestureDisposition.rejected);
      // Now r3 is the only one — auto-wins.
      expect(r3.accepted, isTrue);
    });

    test('all members reject — arena is cleaned up', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key, r1);
      manager.resolve(key, r1, GestureDisposition.rejected);

      expect(r1.rejected, isTrue);
      expect(manager.hasActiveArenas, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // close / sweep
  // -------------------------------------------------------------------------

  group('close / sweep', () {
    test('close picks first possible member as winner', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r2 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key, r1);
      manager.add(key, r2);

      manager.close(key);

      expect(r1.accepted, isTrue, reason: 'first possible wins');
      expect(r2.rejected, isTrue);
    });

    test('close picks accepted member over possible', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.accepted;
      final r2 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key, r1);
      manager.add(key, r2);

      manager.close(key);

      expect(r1.accepted, isTrue, reason: 'already accepted wins');
      expect(r2.rejected, isTrue);
    });

    test('close rejects all if none are possible', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.defunct;
      final r2 = _TestRecognizer()..state = GestureRecognizerState.ready;

      manager.add(key, r1);
      manager.add(key, r2);

      manager.close(key);

      expect(r1.rejected, isTrue);
      expect(r2.rejected, isTrue);
    });

    test('sweep is an alias for close', () {
      final key = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key, r1);
      manager.sweep(key);

      expect(r1.accepted, isTrue);
      expect(manager.hasActiveArenas, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Disposal
  // -------------------------------------------------------------------------

  group('disposal', () {
    test('dispose rejects all members in all arenas', () {
      final key1 = manager.createArena();
      final key2 = manager.createArena();
      final r1 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r2 = _TestRecognizer()..state = GestureRecognizerState.possible;
      final r3 = _TestRecognizer()..state = GestureRecognizerState.possible;

      manager.add(key1, r1);
      manager.add(key1, r2);
      manager.add(key2, r3);

      manager.dispose();

      expect(r1.rejected, isTrue);
      expect(r2.rejected, isTrue);
      expect(r3.rejected, isTrue);
      expect(manager.hasActiveArenas, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------------------------

  group('edge cases', () {
    test('resolve on nonexistent arena is a no-op', () {
      final r = _TestRecognizer();
      // Should not throw.
      manager.resolve(999, r, GestureDisposition.accepted);
      expect(r.accepted, isFalse);
    });

    test('close on nonexistent arena is a no-op', () {
      // Should not throw.
      manager.close(999);
    });

    test('add to nonexistent arena is a no-op', () {
      final r = _TestRecognizer();
      manager.add(999, r);
      // Should not throw and recognizer should not be modified.
    });

    test('recognizer without arena auto-accepts on resolve', () {
      final r = _TestRecognizer()..state = GestureRecognizerState.possible;
      // resolve() with no arena should auto-accept.
      r.resolve(GestureDisposition.accepted);
      expect(r.accepted, isTrue);
    });

    test('recognizer without arena auto-rejects on resolve', () {
      final r = _TestRecognizer()..state = GestureRecognizerState.possible;
      r.resolve(GestureDisposition.rejected);
      expect(r.rejected, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Integration with real recognizers
  // -------------------------------------------------------------------------

  group('real recognizer integration', () {
    test('tap vs drag: drag wins when pointer moves beyond slop', () {
      final key = manager.createArena();
      final tap = TapGestureRecognizer();
      final drag = DragGestureRecognizer();

      var tapFired = false;
      var tapCancelled = false;
      var dragStarted = false;

      tap.onTap = () {
        tapFired = true;
        return null;
      };
      tap.onTapCancel = () {
        tapCancelled = true;
        return null;
      };
      drag.onDragStart = (_) {
        dragStarted = true;
        return null;
      };

      manager.add(key, tap);
      manager.add(key, drag);

      final press = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 5,
        y: 5,
      );
      final local = const Offset(5, 5);

      tap.handlePointerDown(press, local);
      drag.handlePointerDown(press, local);

      // Move beyond drag slop but within tap slop range.
      // drag slop: squared > 1.0, tap slop: squared > 2.0.
      // Move by (1, 1) → squared = 2.0 — beyond drag slop (> 1.0)
      // but NOT beyond tap slop (not > 2.0).
      final move = MouseMsg(
        action: MouseAction.motion,
        button: MouseButton.none,
        x: 6,
        y: 6,
      );
      final moveLocal = const Offset(6, 6);

      tap.handlePointerMove(move, moveLocal);
      drag.handlePointerMove(move, moveLocal);

      // Drag should have started (resolved accepted in arena).
      // Since drag won the arena, tap should be rejected.
      expect(dragStarted, isTrue);
      expect(tapCancelled, isTrue);
      expect(tapFired, isFalse);
    });

    test('tap vs drag: tap wins when pointer released without move', () {
      final key = manager.createArena();
      final tap = TapGestureRecognizer();
      final drag = DragGestureRecognizer();

      var tapFired = false;
      var dragStarted = false;

      tap.onTap = () {
        tapFired = true;
        return null;
      };
      drag.onDragStart = (_) {
        dragStarted = true;
        return null;
      };

      manager.add(key, tap);
      manager.add(key, drag);

      final press = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 5,
        y: 5,
      );
      final local = const Offset(5, 5);

      tap.handlePointerDown(press, local);
      drag.handlePointerDown(press, local);

      // Release without moving — close the arena.
      final release = MouseMsg(
        action: MouseAction.release,
        button: MouseButton.left,
        x: 5,
        y: 5,
      );

      tap.handlePointerUp(release, local);
      drag.handlePointerUp(release, local);

      // Close the arena — tap should win (first possible).
      manager.close(key);

      // Tap was already handled in handlePointerUp (state became defunct).
      // The arena close would accept tap (if still possible) and reject drag.
      expect(tapFired, isTrue);
      expect(dragStarted, isFalse);
    });
  });
}
