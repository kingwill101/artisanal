/// Tests for the GestureDetector widget.
///
/// Covers all gesture callbacks: onTapDown, onTapUp, onTap, onEnter, onExit,
/// onDragStart, onDragUpdate, onDragEnd, onWheel. Also tests enabled/disabled,
/// captureMouse behavior, and callback sequencing.
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // onTap
  // ---------------------------------------------------------------------------

  group('onTap', () {
    test('fires on full tap (press + release)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapCount++;
            return null;
          },
          child: w.Text('tap-target'),
        ),
      );

      tester.tapAt(0, 0);
      expect(tapCount, equals(1));
    });

    test('fires multiple times on repeated taps', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapCount++;
            return null;
          },
          child: w.Text('tap-target'),
        ),
      );

      tester.tapAt(0, 0);
      tester.tapAt(0, 0);
      tester.tapAt(0, 0);
      expect(tapCount, equals(3));
    });

    test('does not fire on press alone (no release)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapCount++;
            return null;
          },
          child: w.Text('tap-target'),
        ),
      );

      tester.mouseDown(0, 0);
      expect(tapCount, equals(0));
    });

    test('fires with no argument (GestureTapCallback)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapped = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapped = true;
            return null;
          },
          child: w.Text('tap-target'),
        ),
      );

      tester.tapAt(2, 0);
      expect(tapped, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // onTapDown / onTapUp
  // ---------------------------------------------------------------------------

  group('onTapDown / onTapUp', () {
    test('onTapDown fires on press', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var count = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTapDown: (_) {
            count++;
            return null;
          },
          child: w.Text('press-target'),
        ),
      );

      tester.mouseDown(0, 0);
      expect(count, equals(1));
    });

    test('onTapUp fires on release', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var count = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTapUp: (_) {
            count++;
            return null;
          },
          child: w.Text('release-target'),
        ),
      );

      tester.mouseDown(0, 0);
      expect(count, equals(0), reason: 'onTapUp should not fire on press');
      tester.mouseUp(0, 0);
      expect(count, equals(1));
    });

    test(
      'press fires onTapDown; drag fires after movement beyond slop',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final events = <String>[];
        await tester.pumpWidget(
          w.GestureDetector(
            onTapDown: (_) {
              events.add('tapDown');
              return null;
            },
            onDragStart: (_) {
              events.add('dragStart');
              return null;
            },
            child: w.Text('multi-callback'),
          ),
        );

        tester.mouseDown(0, 0);
        expect(events, contains('tapDown'));
        expect(
          events,
          isNot(contains('dragStart')),
          reason: 'dragStart requires movement beyond slop',
        );

        // Move beyond slop to trigger dragStart.
        tester.mouseMove(5, 0);
        expect(events, contains('dragStart'));
      },
    );

    test('release after tap fires onTapUp and onTap (no drag)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final events = <String>[];
      await tester.pumpWidget(
        w.GestureDetector(
          onTapUp: (_) {
            events.add('tapUp');
            return null;
          },
          onDragEnd: (_) {
            events.add('dragEnd');
            return null;
          },
          onTap: () {
            events.add('tap');
            return null;
          },
          child: w.Text('multi-release'),
        ),
      );

      tester.mouseDown(0, 0);
      events.clear(); // clear press events
      tester.mouseUp(0, 0);
      // No movement occurred, so drag was never started; dragEnd should NOT fire.
      expect(events, contains('tapUp'));
      expect(events, contains('tap'));
      expect(
        events,
        isNot(contains('dragEnd')),
        reason: 'dragEnd only fires if drag was started',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // onEnter / onExit (hover)
  // ---------------------------------------------------------------------------

  group('onEnter / onExit', () {
    test('onEnter fires on first motion within bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onEnter: (_) {
            enterCount++;
            return null;
          },
          child: w.Text('hover-target'),
        ),
      );

      tester.mouseMove(0, 0);
      expect(enterCount, equals(1));
    });

    test('onEnter fires only once for repeated motion in bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onEnter: (_) {
            enterCount++;
            return null;
          },
          child: w.Text('hover-target'),
        ),
      );

      tester.mouseMove(0, 0);
      tester.mouseMove(1, 0);
      tester.mouseMove(2, 0);
      expect(enterCount, equals(1), reason: 'onEnter fires once on first hit');
    });
  });

  // ---------------------------------------------------------------------------
  // Drag callbacks
  // ---------------------------------------------------------------------------

  group('drag callbacks', () {
    test('full drag sequence: start, update, end', () async {
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
          child: w.Text('drag-me'),
        ),
      );

      // Press: drag has not started yet (need movement beyond slop).
      tester.mouseDown(0, 0);
      expect(
        events,
        isEmpty,
        reason: 'drag requires movement beyond kDragSlop',
      );

      // Move beyond slop (kDragSlop = 1.0) → triggers start + first update.
      tester.mouseMove(3, 0);
      expect(events, contains('start'));
      expect(events, contains('update'));

      // Additional movement → more updates.
      events.clear();
      tester.mouseMove(5, 0);
      expect(events, equals(['update']));

      tester.mouseUp(5, 0);
      expect(events.last, equals('end'));
    });

    test('motion without prior press does not trigger drag', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var dragUpdateCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onDragUpdate: (_) {
            dragUpdateCount++;
            return null;
          },
          child: w.Text('no-drag'),
        ),
      );

      tester.mouseMove(0, 0);
      tester.mouseMove(3, 0);
      expect(
        dragUpdateCount,
        equals(0),
        reason: 'No drag without mouseDown first',
      );
    });

    test(
      'drag with captured mouse receives events outside original bounds',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        var updateCount = 0;
        await tester.pumpWidget(
          w.GestureDetector(
            captureMouse: true,
            onDragUpdate: (_) {
              updateCount++;
              return null;
            },
            child: w.Text('drag-me'),
          ),
        );

        tester.mouseDown(0, 0);
        // Move far outside the text bounds — captured mouse should still
        // deliver global MouseMsg events to this GestureDetector.
        tester.mouseMove(70, 20);
        expect(updateCount, greaterThanOrEqualTo(1));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // onWheel
  // ---------------------------------------------------------------------------

  group('onWheel', () {
    test('fires on wheel up', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var wheelCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onWheel: (_) {
            wheelCount++;
            return null;
          },
          child: w.Text('wheel-target'),
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
      expect(wheelCount, equals(1));
    });

    test('fires on wheel down', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var wheelCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onWheel: (_) {
            wheelCount++;
            return null;
          },
          child: w.Text('wheel-target'),
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
      expect(wheelCount, equals(1));
    });

    test('receives correct button in MouseMsg', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      tui.MouseMsg? receivedMsg;
      await tester.pumpWidget(
        w.GestureDetector(
          onWheel: (msg) {
            receivedMsg = msg;
            return null;
          },
          child: w.Text('wheel-target'),
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
      expect(receivedMsg, isNotNull);
      expect(receivedMsg!.button, equals(tui.MouseButton.wheelDown));
    });
  });

  // ---------------------------------------------------------------------------
  // enabled / disabled
  // ---------------------------------------------------------------------------

  group('enabled / disabled', () {
    test('enabled=false suppresses all callbacks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      var wheelCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          enabled: false,
          onTap: () {
            tapCount++;
            return null;
          },
          onWheel: (_) {
            wheelCount++;
            return null;
          },
          child: w.Text('disabled'),
        ),
      );

      tester.tapAt(0, 0);
      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelUp,
          x: 0,
          y: 0,
        ),
      );
      expect(tapCount, equals(0));
      expect(wheelCount, equals(0));
    });

    test('enabled=true (default) allows callbacks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            tapCount++;
            return null;
          },
          child: w.Text('enabled'),
        ),
      );

      tester.tapAt(0, 0);
      expect(tapCount, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // captureMouse
  // ---------------------------------------------------------------------------

  group('captureMouse', () {
    test('captureMouse=true (default) allows drag outside bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var updateCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          captureMouse: true,
          onDragUpdate: (_) {
            updateCount++;
            return null;
          },
          child: w.Text('capture'),
        ),
      );

      tester.mouseDown(0, 0);
      tester.mouseMove(50, 10);
      expect(updateCount, greaterThanOrEqualTo(1));
    });

    test('captureMouse=false still fires drag within bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var dragStarted = false;
      await tester.pumpWidget(
        w.GestureDetector(
          captureMouse: false,
          onDragStart: (_) {
            dragStarted = true;
            return null;
          },
          child: w.Text('no-capture'),
        ),
      );

      // Press alone doesn't start drag; need movement beyond slop.
      tester.mouseDown(0, 0);
      expect(dragStarted, isFalse);

      tester.mouseMove(3, 0);
      expect(dragStarted, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Stateful integration — state updates via gesture
  // ---------------------------------------------------------------------------

  group('stateful integration', () {
    test('tap increments counter in stateful parent', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ClickCounter());
      expect(tester.find.text('count: 0'), isTrue);

      tester.tapAt(0, 0);
      expect(tester.find.text('count: 1'), isTrue);

      tester.tapAt(0, 0);
      expect(tester.find.text('count: 2'), isTrue);
    });

    test('tap outside GestureDetector does not fire', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Container(
          width: 40,
          height: 10,
          child: w.GestureDetector(onTap: () => null, child: w.Text('small')),
        ),
      );

      // 'small' renders at top-left; tap far away.
      final hitsBefore = tester.hitTestAt(39, 9);
      // Verify that hitting far coordinates doesn't reach our GestureDetector.
      final hasGesture = hitsBefore.any(
        (e) => e.element.widget.runtimeType.toString() == 'GestureDetector',
      );
      expect(
        hasGesture,
        isFalse,
        reason: 'Hit-test at (39,9) should not hit the text area',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Nested GestureDetectors
  // ---------------------------------------------------------------------------

  group('nested GestureDetectors', () {
    test('inner GestureDetector receives tap (deepest first)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final events = <String>[];
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            events.add('outer');
            return null;
          },
          child: w.GestureDetector(
            onTap: () {
              events.add('inner');
              return null;
            },
            child: w.Text('nested'),
          ),
        ),
      );

      tester.tapAt(0, 0);
      // Hit-testing delivers to deepest first; both should fire since the
      // message propagates through the tree.
      expect(events, contains('inner'));
    });
  });

  // ---------------------------------------------------------------------------
  // Callback with non-null return
  // ---------------------------------------------------------------------------

  group('callback returning Cmd', () {
    test('onTap can return a Cmd without error', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var cmdExecuted = false;
      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () {
            return tui.Cmd(() async {
              cmdExecuted = true;
              return null;
            });
          },
          child: w.Text('cmd-tap'),
        ),
      );

      tester.tapAt(0, 0);
      // Give the async cmd time to execute.
      await Future<void>.delayed(Duration(milliseconds: 50));
      expect(cmdExecuted, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Child rendering
  // ---------------------------------------------------------------------------

  group('child rendering', () {
    test('renders child content unchanged', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.GestureDetector(onTap: () => null, child: w.Text('visible-text')),
      );

      expect(tester.find.text('visible-text'), isTrue);
    });

    test('wraps complex child tree', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.GestureDetector(
          onTap: () => null,
          child: w.Column(children: [w.Text('line-a'), w.Text('line-b')]),
        ),
      );

      expect(tester.find.text('line-a'), isTrue);
      expect(tester.find.text('line-b'), isTrue);
    });
  });
}

// =============================================================================
// Helper widgets
// =============================================================================

class _ClickCounter extends w.StatefulWidget {
  @override
  w.State createState() => _ClickCounterState();
}

class _ClickCounterState extends w.State<_ClickCounter> {
  int _count = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.GestureDetector(
      onTap: () {
        setState(() => _count++);
        return null;
      },
      child: w.Text('count: $_count'),
    );
  }
}
