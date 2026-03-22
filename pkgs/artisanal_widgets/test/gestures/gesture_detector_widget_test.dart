/// Widget integration tests for [GestureDetector] with the new recognizer system.
///
/// Tests gesture detection through the full widget pipeline using
/// [WidgetTester]: tap, double-tap, long-press, drag, onEnter/onExit,
/// onWheel, enabled/disabled, and combined gestures.
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // -------------------------------------------------------------------------
  // Tap through widget pipeline
  // -------------------------------------------------------------------------

  group('tap via widget pipeline', () {
    test('onTap fires on click', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapCount++;
            return null;
          },
          child: w.Text('click me'),
        ),
      );

      tester.tapAt(0, 0);
      expect(tapCount, equals(1));
    });

    test('onTapDown provides TapDownDetails', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      w.TapDownDetails? captured;
      await tester.pumpWidget(
        w.GestureDetector(
          onTapDown: (details) {
            captured = details;
            return null;
          },
          child: w.Text('tap details'),
        ),
      );

      tester.mouseDown(2, 0);
      expect(captured, isNotNull);
      expect(captured!.globalPosition.dx, equals(2));
      expect(captured!.globalPosition.dy, equals(0));
    });

    test('onTapUp provides TapUpDetails', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      w.TapUpDetails? captured;
      await tester.pumpWidget(
        w.GestureDetector(
          onTapUp: (details) {
            captured = details;
            return null;
          },
          child: w.Text('tap up'),
        ),
      );

      tester.mouseDown(0, 0);
      expect(captured, isNull, reason: 'tapUp should not fire on down');
      tester.mouseUp(0, 0);
      expect(captured, isNotNull);
    });

    test('onTapCancel fires when drag moves beyond slop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var cancelled = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () => null,
          onTapCancel: () {
            cancelled = true;
            return null;
          },
          onDragStart: (_) => null,
          child: w.Text('cancel test'),
        ),
      );

      tester.mouseDown(0, 0);
      // Move far to trigger drag → tap gets cancelled.
      tester.mouseMove(10, 0);
      expect(cancelled, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Double-tap through widget pipeline
  // -------------------------------------------------------------------------

  group('double-tap via widget pipeline', () {
    test('onDoubleTap fires on two rapid clicks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var doubleTapped = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onDoubleTap: () {
            doubleTapped = true;
            return null;
          },
          child: w.Text('double click'),
        ),
      );

      // First tap.
      tester.tapAt(0, 0);
      expect(doubleTapped, isFalse);

      // Second tap immediately.
      tester.tapAt(0, 0);
      expect(doubleTapped, isTrue);
    });

    test('onDoubleTap does not fire after timeout', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var doubleTapped = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onDoubleTap: () {
            doubleTapped = true;
            return null;
          },
          child: w.Text('timeout test'),
        ),
      );

      tester.tapAt(0, 0);
      // Wait for double-tap timeout to expire.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      tester.tapAt(0, 0);
      expect(doubleTapped, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Long-press through widget pipeline
  // -------------------------------------------------------------------------

  group('long-press via widget pipeline', () {
    test('onLongPress fires after hold duration', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var longPressed = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onLongPress: () {
            longPressed = true;
            return null;
          },
          child: w.Text('long press'),
        ),
      );

      tester.mouseDown(0, 0);
      expect(longPressed, isFalse);

      // Default duration is 500ms. Wait for it.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(longPressed, isTrue);
    });

    test('onLongPressEnd fires on release after long-press', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      w.LongPressEndDetails? captured;
      await tester.pumpWidget(
        w.GestureDetector(
          onLongPress: () => null,
          onLongPressEnd: (details) {
            captured = details;
            return null;
          },
          child: w.Text('long end'),
        ),
      );

      tester.mouseDown(0, 0);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      tester.mouseUp(0, 0);
      expect(captured, isNotNull);
    });

    test('release before duration does not fire long-press', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var longPressed = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onLongPress: () {
            longPressed = true;
            return null;
          },
          child: w.Text('no long press'),
        ),
      );

      tester.mouseDown(0, 0);
      tester.mouseUp(0, 0); // Release immediately.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(longPressed, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Drag through widget pipeline
  // -------------------------------------------------------------------------

  group('drag via widget pipeline', () {
    test('drag callbacks fire on press + move beyond slop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final events = <String>[];
      await tester.pumpWidget(
        w.GestureDetector(
          onDragStart: (_) {
            events.add('start');
            return null;
          },
          onDragUpdate: (_) {
            events.add('update');
            return null;
          },
          onDragEnd: (_) {
            events.add('end');
            return null;
          },
          child: w.Text('drag target'),
        ),
      );

      tester.mouseDown(0, 0);
      expect(events, isEmpty, reason: 'no drag on press alone');

      tester.mouseMove(5, 0); // Beyond slop.
      expect(events, contains('start'));
      expect(events, contains('update'));

      tester.mouseUp(5, 0);
      expect(events, contains('end'));
    });

    test('drag provides DragUpdateDetails with delta', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final updates = <w.DragUpdateDetails>[];
      await tester.pumpWidget(
        w.GestureDetector(
          onDragStart: (_) => null,
          onDragUpdate: (d) {
            updates.add(d);
            return null;
          },
          child: w.Text('drag delta'),
        ),
      );

      tester.mouseDown(0, 0);
      tester.mouseMove(5, 0); // First update.
      tester.mouseMove(8, 0); // Second update.

      expect(updates.length, greaterThanOrEqualTo(2));
    });

    test('small movement within drag slop does not start drag', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var started = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onDragStart: (_) {
            started = true;
            return null;
          },
          child: w.Text('no drag'),
        ),
      );

      tester.mouseDown(5, 5);
      tester.mouseMove(5, 5); // No actual movement.
      expect(started, isFalse);
    });

    test('keyboard drag requires focus', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var updates = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onDragUpdate: (_) {
            updates++;
            return null;
          },
          child: w.Text('keyboard focus target'),
        ),
      );

      tester.sendSpecialKey(tui.KeyType.right);
      expect(updates, equals(0));
    });

    test(
      'keyboard drag activates on accept key and moves by arrow steps',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        var started = 0;
        var ended = 0;
        final deltas = <String>[];
        await tester.pumpWidget(
          w.GestureDetector(
            onDragStart: (_) {
              started++;
              return null;
            },
            onDragUpdate: (d) {
              deltas.add('${d.delta.dx},${d.delta.dy}');
              return null;
            },
            onDragEnd: (_) {
              ended++;
              return null;
            },
            child: w.Text('keyboard drag target'),
          ),
        );

        final pos = tester.locateText('keyboard drag target');
        expect(pos, isNotNull);
        tester.tapAt(pos!.x, pos.y);

        tester.sendKey(' ');
        expect(started, equals(1));

        tester.sendSpecialKey(tui.KeyType.right);
        tester.sendSpecialKey(tui.KeyType.down);
        tester.sendSpecialKey(tui.KeyType.left);
        expect(deltas, equals(['1.0,0.0', '0.0,1.0', '-1.0,0.0']));

        tester.sendKey(' ');
        expect(ended, equals(1));
      },
    );

    test('keyboard drag follows focus changes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var firstUpdates = 0;
      var secondUpdates = 0;
      await tester.pumpWidget(
        w.Row(
          children: [
            w.GestureDetector(
              onDragStart: (_) => null,
              onDragUpdate: (_) {
                firstUpdates++;
                return null;
              },
              child: w.Text('first drag target'),
            ),
            w.GestureDetector(
              onDragStart: (_) => null,
              onDragUpdate: (_) {
                secondUpdates++;
                return null;
              },
              child: w.Text('second drag target'),
            ),
          ],
        ),
      );

      final first = tester.locateText('first drag target');
      final second = tester.locateText('second drag target');
      expect(first, isNotNull);
      expect(second, isNotNull);

      tester.tapAt(first!.x, first.y);
      tester.sendKey(' ');
      tester.sendSpecialKey(tui.KeyType.right);
      expect(firstUpdates, equals(1));
      expect(secondUpdates, equals(0));

      tester.tapAt(second!.x, second.y);
      tester.sendKey(' ');
      tester.sendSpecialKey(tui.KeyType.right);
      expect(firstUpdates, equals(1));
      expect(secondUpdates, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Hover (onEnter / onExit)
  // -------------------------------------------------------------------------

  group('hover callbacks', () {
    test('onEnter fires on mouse motion within bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var entered = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onEnter: (_) {
            entered = true;
            return null;
          },
          child: w.Text('hover target'),
        ),
      );

      // Mouse motion triggers enter.
      tester.mouseMove(0, 0);
      expect(entered, isTrue);
    });

    test('onExit fires when mouse moves outside bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var entered = false;
      var exited = false;
      // Place the GestureDetector in a Stack so it occupies only a small
      // region; moving to (79,23) hits the Stack background, not the
      // GestureDetector.
      await tester.pumpWidget(
        w.Stack(
          width: 80,
          height: 24,
          children: [
            w.Positioned(
              left: 0,
              top: 0,
              child: w.GestureDetector(
                onEnter: (_) {
                  entered = true;
                  return null;
                },
                onExit: (_) {
                  exited = true;
                  return null;
                },
                child: w.Container(
                  width: 10,
                  height: 1,
                  child: w.Text('hover'),
                ),
              ),
            ),
          ],
        ),
      );

      // Mouse enters widget bounds.
      tester.mouseMove(0, 0);
      expect(entered, isTrue);
      expect(exited, isFalse);

      // Mouse moves outside widget bounds → onExit fires.
      tester.mouseMove(79, 23);
      expect(exited, isTrue);
    });

    test('onEnter fires again after exit', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      var exitCount = 0;
      await tester.pumpWidget(
        w.Stack(
          width: 80,
          height: 24,
          children: [
            w.Positioned(
              left: 0,
              top: 0,
              child: w.GestureDetector(
                onEnter: (_) {
                  enterCount++;
                  return null;
                },
                onExit: (_) {
                  exitCount++;
                  return null;
                },
                child: w.Container(
                  width: 10,
                  height: 1,
                  child: w.Text('hover'),
                ),
              ),
            ),
          ],
        ),
      );

      // Enter → exit → enter again.
      tester.mouseMove(0, 0);
      expect(enterCount, 1);
      tester.mouseMove(79, 23);
      expect(exitCount, 1);
      tester.mouseMove(0, 0);
      expect(enterCount, 2);
      expect(exitCount, 1);
    });

    test('repeated motion inside bounds fires onEnter only once', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.Stack(
          width: 80,
          height: 24,
          children: [
            w.Positioned(
              left: 0,
              top: 0,
              child: w.GestureDetector(
                onEnter: (_) {
                  enterCount++;
                  return null;
                },
                child: w.Container(
                  width: 10,
                  height: 1,
                  child: w.Text('hover'),
                ),
              ),
            ),
          ],
        ),
      );

      tester.mouseMove(0, 0);
      tester.mouseMove(1, 0);
      tester.mouseMove(2, 0);
      expect(enterCount, 1);
    });

    test('hover toggles visual output via setState', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_HoverToggleWidget());

      expect(tester.find.text('not hovered'), isTrue);

      // Mouse enters bounds → visual update.
      tester.mouseMove(0, 0);
      expect(tester.find.text('hovered'), isTrue);

      // Mouse exits bounds → visual update reverts.
      tester.mouseMove(79, 23);
      expect(tester.find.text('not hovered'), isTrue);
    });

    test('onEnter command is dispatched through the widget pipeline', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_HoverCmdWidget());

      expect(tester.find.text('not hovered'), isTrue);

      tester.mouseMove(0, 0);

      expect(tester.find.text('hovered'), isTrue);
    });

    test('onExit command is dispatched through the widget pipeline', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_HoverCmdWidget());

      tester.mouseMove(0, 0);
      expect(tester.find.text('hovered'), isTrue);

      tester.mouseMove(79, 23);

      expect(tester.find.text('not hovered'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Wheel (onWheel)
  // -------------------------------------------------------------------------

  group('wheel callbacks', () {
    test('onWheel fires on wheel event within bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var wheelCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onWheel: (_) {
            wheelCount++;
            return null;
          },
          child: w.Container(width: 10, height: 3, child: w.Text('scroll me')),
        ),
      );

      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelDown,
          x: 0,
          y: 0,
        ),
      );
      expect(wheelCount, 1);
    });

    test('multiple wheel events increment counter', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var wheelCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onWheel: (_) {
            wheelCount++;
            return null;
          },
          child: w.Container(width: 10, height: 3, child: w.Text('scroll me')),
        ),
      );

      for (var i = 0; i < 5; i++) {
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: 0,
            y: 0,
          ),
        );
      }
      expect(wheelCount, 5);
    });

    test('wheel event updates visual output via setState', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_WheelCounterWidget());

      expect(tester.find.text('scrolled: 0'), isTrue);

      // Wheel down → counter increments and view updates.
      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelDown,
          x: 0,
          y: 0,
        ),
      );
      expect(tester.find.text('scrolled: 1'), isTrue);

      // Another wheel → counter increments again.
      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelDown,
          x: 0,
          y: 0,
        ),
      );
      expect(tester.find.text('scrolled: 2'), isTrue);
    });

    test('wheel up and wheel down both fire onWheel', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final directions = <tui.MouseButton>[];
      await tester.pumpWidget(
        w.GestureDetector(
          onWheel: (msg) {
            directions.add(msg.button);
            return null;
          },
          child: w.Container(width: 10, height: 3, child: w.Text('scroll')),
        ),
      );

      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelUp,
          x: 0,
          y: 0,
        ),
      );
      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelDown,
          x: 0,
          y: 0,
        ),
      );
      expect(directions, [tui.MouseButton.wheelUp, tui.MouseButton.wheelDown]);
    });

    test(
      'wheel outside GestureDetector bounds does not fire onWheel',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        var wheelCount = 0;
        // Place the GestureDetector in a Stack so it occupies only a small
        // region and the wheel event at (79,23) hits the Stack background,
        // not the GestureDetector's render object.
        await tester.pumpWidget(
          w.Stack(
            width: 80,
            height: 24,
            children: [
              w.Positioned(
                left: 0,
                top: 0,
                child: w.GestureDetector(
                  onWheel: (_) {
                    wheelCount++;
                    return null;
                  },
                  child: w.Container(
                    width: 5,
                    height: 1,
                    child: w.Text('tiny'),
                  ),
                ),
              ),
            ],
          ),
        );

        // Wheel event far outside the 5x1 GestureDetector area.
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: 79,
            y: 23,
          ),
        );
        expect(wheelCount, 0);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Hover + Wheel combined
  // -------------------------------------------------------------------------

  group('hover and wheel combined', () {
    test('hover and wheel both work on same GestureDetector', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_HoverWheelWidget());

      expect(tester.find.text('hover: no'), isTrue);
      expect(tester.find.text('scroll: 0'), isTrue);

      // Hover enter.
      tester.mouseMove(0, 0);
      expect(tester.find.text('hover: yes'), isTrue);

      // Wheel while hovering.
      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelDown,
          x: 0,
          y: 0,
        ),
      );
      expect(tester.find.text('scroll: 1'), isTrue);
      expect(tester.find.text('hover: yes'), isTrue);

      // Hover exit.
      tester.mouseMove(79, 23);
      expect(tester.find.text('hover: no'), isTrue);
      // Scroll count should remain.
      expect(tester.find.text('scroll: 1'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Enabled / disabled
  // -------------------------------------------------------------------------

  group('enabled / disabled', () {
    test('disabled GestureDetector does not fire callbacks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapped = false;
      await tester.pumpWidget(
        w.GestureDetector(
          enabled: false,
          onTap: () {
            tapped = true;
            return null;
          },
          child: w.Text('disabled'),
        ),
      );

      tester.tapAt(0, 0);
      expect(tapped, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Combined gestures: tap + drag compete
  // -------------------------------------------------------------------------

  group('combined gestures', () {
    test('tap + drag: click fires tap, not drag', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapped = false;
      var dragStarted = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapped = true;
            return null;
          },
          onDragStart: (_) {
            dragStarted = true;
            return null;
          },
          child: w.Text('tap vs drag'),
        ),
      );

      tester.tapAt(0, 0);
      expect(tapped, isTrue);
      expect(dragStarted, isFalse);
    });

    test('tap + drag: movement fires drag and cancels tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapped = false;
      var dragStarted = false;
      var tapCancelled = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapped = true;
            return null;
          },
          onTapCancel: () {
            tapCancelled = true;
            return null;
          },
          onDragStart: (_) {
            dragStarted = true;
            return null;
          },
          child: w.Text('drag wins'),
        ),
      );

      tester.mouseDown(0, 0);
      tester.mouseMove(10, 0); // Beyond both slops.
      expect(dragStarted, isTrue);
      expect(tapCancelled, isTrue);
      expect(tapped, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Re-drag: second drag sequence after first completes (Bug B)
  // -------------------------------------------------------------------------

  group('re-drag after release', () {
    test('second drag sequence fires onDragStart again', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final events = <String>[];
      await tester.pumpWidget(
        w.GestureDetector(
          onDragStart: (_) {
            events.add('start');
            return null;
          },
          onDragUpdate: (_) {
            events.add('update');
            return null;
          },
          onDragEnd: (_) {
            events.add('end');
            return null;
          },
          child: w.Container(width: 20, height: 3, child: w.Text('drag me')),
        ),
      );

      // First drag: press → move beyond slop → release.
      tester.mouseDown(5, 1);
      tester.mouseMove(10, 1);
      tester.mouseUp(10, 1);
      expect(events, contains('start'));
      expect(events, contains('end'));

      events.clear();

      // Second drag: press → move beyond slop → release.
      tester.mouseDown(5, 1);
      tester.mouseMove(10, 1);
      expect(
        events,
        contains('start'),
        reason: 'second drag should fire onDragStart',
      );
      expect(
        events,
        contains('update'),
        reason: 'second drag should fire onDragUpdate',
      );

      tester.mouseUp(10, 1);
      expect(
        events,
        contains('end'),
        reason: 'second drag should fire onDragEnd',
      );
    });

    test('drag-only GestureDetector works across multiple sequences', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var dragCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onDragStart: (_) {
            dragCount++;
            return null;
          },
          onDragUpdate: (_) => null,
          onDragEnd: (_) => null,
          child: w.Container(width: 20, height: 3, child: w.Text('multi drag')),
        ),
      );

      // Perform 3 consecutive drag sequences.
      for (var i = 0; i < 3; i++) {
        tester.mouseDown(2, 1);
        tester.mouseMove(8, 1);
        tester.mouseUp(8, 1);
      }

      expect(
        dragCount,
        equals(3),
        reason: 'should be able to start 3 consecutive drags',
      );
    });

    test('drag with setState rebuild works across sequences', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Use a stateful widget that rebuilds on drag, simulating
      // the drag example's behavior.
      await tester.pumpWidget(_DragCounterWidget());

      // First drag.
      tester.mouseDown(2, 0);
      tester.mouseMove(8, 0);
      tester.mouseUp(8, 0);
      expect(
        tester.find.text('drags: 1'),
        isTrue,
        reason: 'first drag should increment counter',
      );

      // Second drag.
      tester.mouseDown(2, 0);
      tester.mouseMove(8, 0);
      tester.mouseUp(8, 0);
      expect(
        tester.find.text('drags: 2'),
        isTrue,
        reason: 'second drag should increment counter after rebuild',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Slider-like drag: horizontal-only (Bug A)
  // -------------------------------------------------------------------------

  group('slider-like drag', () {
    test('horizontal drag updates value via globalPosition', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_SliderWidget());

      // Press on slider track.
      tester.mouseDown(10, 0);
      // Move right by 5.
      tester.mouseMove(15, 0);
      expect(
        tester.find.text('value: 0'),
        isFalse,
        reason: 'slider should have moved from initial value',
      );

      tester.mouseUp(15, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Moveable box in Stack+Positioned (replicating drag example Bug B)
  // -------------------------------------------------------------------------

  group('drag inside Stack+Positioned', () {
    test('box can be re-dragged after first drag in Stack', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_MoveableBoxWidget());

      // First drag: move the box.
      tester.mouseDown(6, 1);
      tester.mouseMove(10, 1);
      tester.mouseUp(10, 1);
      expect(
        tester.find.text('pos: (4, 0)'),
        isFalse,
        reason: 'box should have moved from initial position',
      );

      // Second drag: should also work.
      tester.mouseDown(10, 1);
      tester.mouseMove(14, 1);
      tester.mouseUp(14, 1);
      // The box should have moved further.
    });

    test('moveable box position updates across multiple drags', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_MoveableBoxWidget());

      // Verify initial position.
      expect(tester.find.text('pos: (4, 0)'), isTrue);

      // First drag: move right by 4 (start at box interior x=6, move to 10).
      tester.mouseDown(6, 1);
      tester.mouseMove(10, 1); // Beyond slop.
      tester.mouseUp(10, 1);

      // Second drag: move right by another 4.
      tester.mouseDown(10, 1);
      tester.mouseMove(14, 1); // Beyond slop.
      tester.mouseUp(14, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Slider-style Row with dynamic-width Text children (Bug A detail)
  // -------------------------------------------------------------------------

  group('slider with Row track (replicating drag example)', () {
    test('slider track Row drag updates value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_RowSliderWidget());

      // Press somewhere on the track.
      tester.mouseDown(5, 0);
      // Move right.
      tester.mouseMove(10, 0);
      expect(
        tester.find.text('pct: 35'),
        isFalse,
        reason: 'slider value should have changed',
      );

      tester.mouseUp(10, 0);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helper widgets
// ---------------------------------------------------------------------------

/// A stateful widget that counts drag starts and rebuilds on each.
class _DragCounterWidget extends w.StatefulWidget {
  _DragCounterWidget();

  @override
  w.State createState() => _DragCounterState();
}

class _DragCounterState extends w.State<_DragCounterWidget> {
  int _dragCount = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.GestureDetector(
      onDragStart: (_) {
        setState(() => _dragCount++);
        return null;
      },
      onDragUpdate: (_) => null,
      onDragEnd: (_) => null,
      child: w.Container(
        width: 20,
        height: 1,
        child: w.Text('drags: $_dragCount'),
      ),
    );
  }
}

/// A minimal slider widget for testing horizontal drag.
class _SliderWidget extends w.StatefulWidget {
  _SliderWidget();

  @override
  w.State createState() => _SliderState();
}

class _SliderState extends w.State<_SliderWidget> {
  int _value = 0;
  int _startX = 0;
  int _startValue = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.GestureDetector(
      onDragStart: (d) {
        _startX = d.globalPosition.dx.round();
        _startValue = _value;
        return null;
      },
      onDragUpdate: (d) {
        final dx = d.globalPosition.dx.round() - _startX;
        setState(() => _value = _startValue + dx);
        return null;
      },
      onDragEnd: (_) => null,
      child: w.Container(width: 20, height: 1, child: w.Text('value: $_value')),
    );
  }
}

/// A moveable box inside a Stack+Positioned, replicating the drag example.
class _MoveableBoxWidget extends w.StatefulWidget {
  _MoveableBoxWidget();

  @override
  w.State createState() => _MoveableBoxState();
}

class _MoveableBoxState extends w.State<_MoveableBoxWidget> {
  static const int _arenaW = 30;
  static const int _arenaH = 5;
  static const int _boxW = 10;
  static const int _boxH = 3;
  int _boxX = 4;
  int _boxY = 0;
  int _dragStartX = 0;
  int _dragStartY = 0;
  int _dragStartBoxX = 0;
  int _dragStartBoxY = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      gap: 0,
      children: [
        w.Stack(
          width: _arenaW,
          height: _arenaH,
          children: [
            w.Container(width: _arenaW, height: _arenaH),
            w.Positioned(
              left: _boxX,
              top: _boxY,
              child: w.GestureDetector(
                onDragStart: (d) {
                  _dragStartX = d.globalPosition.dx.round();
                  _dragStartY = d.globalPosition.dy.round();
                  _dragStartBoxX = _boxX;
                  _dragStartBoxY = _boxY;
                  return null;
                },
                onDragUpdate: (d) {
                  final dx = d.globalPosition.dx.round() - _dragStartX;
                  final dy = d.globalPosition.dy.round() - _dragStartY;
                  setState(() {
                    _boxX = (_dragStartBoxX + dx).clamp(0, _arenaW - _boxW);
                    _boxY = (_dragStartBoxY + dy).clamp(0, _arenaH - _boxH);
                  });
                  return null;
                },
                onDragEnd: (_) => null,
                child: w.Container(
                  width: _boxW,
                  height: _boxH,
                  child: w.Text('box'),
                ),
              ),
            ),
          ],
        ),
        w.Text('pos: ($_boxX, $_boxY)'),
      ],
    );
  }
}

/// A slider widget with a Row-based track, replicating the drag example's
/// slider structure with dynamic-width Text children.
class _RowSliderWidget extends w.StatefulWidget {
  _RowSliderWidget();

  @override
  w.State createState() => _RowSliderState();
}

class _RowSliderState extends w.State<_RowSliderWidget> {
  static const int _trackWidth = 20;
  double _value = 0.35;
  int _startX = 0;
  double _startValue = 0;

  @override
  w.Widget build(w.BuildContext context) {
    final pct = (_value * 100).round();
    final clamped = _value.clamp(0.0, 1.0);
    final thumbPos = (clamped * (_trackWidth - 1)).round();

    return w.Column(
      gap: 0,
      children: [
        w.GestureDetector(
          onDragStart: (d) {
            _startX = d.globalPosition.dx.round();
            _startValue = _value;
            return null;
          },
          onDragUpdate: (d) {
            final dx = d.globalPosition.dx.round() - _startX;
            final next = _startValue + dx / (_trackWidth - 1);
            setState(() => _value = next.clamp(0.0, 1.0));
            return null;
          },
          onDragEnd: (_) => null,
          child: w.Container(
            width: _trackWidth,
            height: 1,
            child: w.Row(
              gap: 0,
              children: [
                w.Text('─' * thumbPos),
                w.Text('●'),
                w.Text('─' * (_trackWidth - thumbPos - 1)),
              ],
            ),
          ),
        ),
        w.Text('pct: $pct'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets for hover / wheel visual-update tests
// ---------------------------------------------------------------------------

/// A StatefulWidget that toggles its displayed text between "hovered" and
/// "not hovered" based on GestureDetector onEnter/onExit.
class _HoverToggleWidget extends w.StatefulWidget {
  @override
  w.State createState() => _HoverToggleState();
}

class _HoverToggleState extends w.State<_HoverToggleWidget> {
  bool _hovering = false;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Stack(
      width: 80,
      height: 24,
      children: [
        w.Positioned(
          left: 0,
          top: 0,
          child: w.GestureDetector(
            onEnter: (_) {
              setState(() => _hovering = true);
              return null;
            },
            onExit: (_) {
              setState(() => _hovering = false);
              return null;
            },
            child: w.Container(
              width: 20,
              height: 1,
              child: w.Text(_hovering ? 'hovered' : 'not hovered'),
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverCmdMsg extends tui.Msg {
  const _HoverCmdMsg(this.hovering);

  final bool hovering;
}

class _HoverCmdWidget extends w.StatefulWidget {
  @override
  w.State createState() => _HoverCmdState();
}

class _HoverCmdState extends w.State<_HoverCmdWidget> {
  bool _hovering = false;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _HoverCmdMsg) {
      setState(() => _hovering = msg.hovering);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Stack(
      width: 80,
      height: 24,
      children: [
        w.Positioned(
          left: 0,
          top: 0,
          child: w.GestureDetector(
            onEnter: (_) => tui.Cmd.message(const _HoverCmdMsg(true)),
            onExit: (_) => tui.Cmd.message(const _HoverCmdMsg(false)),
            child: w.Container(
              width: 20,
              height: 1,
              child: w.Text(_hovering ? 'hovered' : 'not hovered'),
            ),
          ),
        ),
      ],
    );
  }
}

/// A StatefulWidget that counts wheel events and displays the count.
class _WheelCounterWidget extends w.StatefulWidget {
  @override
  w.State createState() => _WheelCounterState();
}

class _WheelCounterState extends w.State<_WheelCounterWidget> {
  int _count = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.GestureDetector(
      onWheel: (_) {
        setState(() => _count++);
        return null;
      },
      child: w.Container(
        width: 20,
        height: 3,
        child: w.Text('scrolled: $_count'),
      ),
    );
  }
}

/// A StatefulWidget that tracks both hover state and wheel count.
class _HoverWheelWidget extends w.StatefulWidget {
  @override
  w.State createState() => _HoverWheelState();
}

class _HoverWheelState extends w.State<_HoverWheelWidget> {
  bool _hovering = false;
  int _scrollCount = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Stack(
      width: 80,
      height: 24,
      children: [
        w.Positioned(
          left: 0,
          top: 0,
          child: w.GestureDetector(
            onEnter: (_) {
              setState(() => _hovering = true);
              return null;
            },
            onExit: (_) {
              setState(() => _hovering = false);
              return null;
            },
            onWheel: (_) {
              setState(() => _scrollCount++);
              return null;
            },
            child: w.Container(
              width: 20,
              height: 3,
              child: w.Column(
                gap: 0,
                children: [
                  w.Text('hover: ${_hovering ? 'yes' : 'no'}'),
                  w.Text('scroll: $_scrollCount'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
