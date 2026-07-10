/// Regression tests for:
/// - [IgnorePointer] widget and [RenderIgnorePointer] render object
/// - [DebugOverlay] does not block mouse events (wrapped in IgnorePointer)
/// - Viewport paint caching does not break content updates
/// - Viewport paint caching does not break selection highlighting
/// - Viewport paint caching re-uses cache on scroll-only frames
library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

void main() {
  // -------------------------------------------------------
  // IgnorePointer widget tests
  // -------------------------------------------------------
  group('IgnorePointer', () {
    test('hit-test passes through IgnorePointer to sibling below', () async {
      var tapped = false;
      final tester = WidgetTester(screenWidth: 20, screenHeight: 3);
      try {
        await tester.pumpWidget(
          Container(
            width: 20,
            height: 3,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    tapped = true;
                    return null;
                  },
                  child: Text('Click me'),
                ),
                IgnorePointer(child: Text('Overlay')),
              ],
            ),
          ),
        );

        // Tap at (0, 0) — should pass through IgnorePointer to
        // GestureDetector below.
        tester.tapAt(0, 0);

        expect(tapped, isTrue, reason: 'tap should pass through IgnorePointer');
      } finally {
        await tester.dispose();
      }
    });

    test('ignoring: false allows hit-testing normally', () async {
      var tapped = false;
      var overlayTapped = false;
      final tester = WidgetTester(screenWidth: 20, screenHeight: 3);
      try {
        await tester.pumpWidget(
          Container(
            width: 20,
            height: 3,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    tapped = true;
                    return null;
                  },
                  child: Text('Click me'),
                ),
                IgnorePointer(
                  ignoring: false,
                  child: GestureDetector(
                    onTap: () {
                      overlayTapped = true;
                      return null;
                    },
                    child: Text('Overlay'),
                  ),
                ),
              ],
            ),
          ),
        );

        tester.tapAt(0, 0);

        // With ignoring: false, the overlay's GestureDetector should
        // receive the tap instead of the one below.
        expect(
          overlayTapped,
          isTrue,
          reason: 'overlay should intercept tap when ignoring=false',
        );
        expect(tapped, isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('IgnorePointer still renders child visually', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 3);
      try {
        await tester.pumpWidget(
          Container(
            width: 20,
            height: 3,
            child: IgnorePointer(child: Text('Visible')),
          ),
        );

        expect(
          tester.find.text('Visible'),
          isTrue,
          reason: 'child should be rendered even when ignoring',
        );
      } finally {
        await tester.dispose();
      }
    });
  });

  // -------------------------------------------------------
  // DebugOverlay mouse event tests
  // -------------------------------------------------------
  group('DebugOverlay does not block mouse events', () {
    test('GestureDetector receives tap through DebugOverlay', () async {
      var tapped = false;
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          DebugOverlay(
            child: Container(
              width: 40,
              height: 10,
              child: GestureDetector(
                onTap: () {
                  tapped = true;
                  return null;
                },
                child: Text('Tap target'),
              ),
            ),
          ),
        );

        // Tap inside the content area.
        tester.tapAt(0, 0);

        expect(
          tapped,
          isTrue,
          reason: 'DebugOverlay should not block mouse events from content',
        );
      } finally {
        await tester.dispose();
      }
    });
  });

  // -------------------------------------------------------
  // Viewport paint cache: content update tests
  // -------------------------------------------------------
  group('Viewport paint caching', () {
    test('child setState updates are reflected after scroll', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        // Create a counter widget inside a scroll view.
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _CounterWidget(),
                  ...List.generate(20, (i) => Text('Line $i')),
                ],
              ),
            ),
          ),
        );

        expect(tester.find.text('Count: 0'), isTrue);

        // Press '+' to increment the counter (triggers setState).
        tester.sendKey('+');

        expect(
          tester.find.text('Count: 1'),
          isTrue,
          reason: 'setState should invalidate cache and show updated content',
        );
      } finally {
        await tester.dispose();
      }
    });

    test(
      'selection highlighting invalidates cache on descendant paint',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
        final scrollCtrl = WidgetScrollController();
        final selCtrl = SelectionController();
        try {
          final lines = List.generate(
            30,
            (i) => SelectableText('Line $i', controller: selCtrl),
          );
          await tester.pumpWidget(
            Container(
              width: 40,
              height: 5,
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Column(children: lines),
              ),
            ),
          );

          // Scroll down.
          scrollCtrl.jumpTo(10);

          final beforeOutput = tester.view;

          // Select text at viewport row 1.
          tester.mouseDown(0, 1);
          tester.mouseMove(4, 1);
          tester.mouseUp(4, 1);

          final afterOutput = tester.view;

          // Output should change — ANSI highlighting applied.
          expect(
            afterOutput,
            isNot(equals(beforeOutput)),
            reason: 'selection highlighting should invalidate paint cache',
          );
          expect(
            afterOutput.contains('\x1b['),
            isTrue,
            reason: 'ANSI escape codes should be present for highlighting',
          );
        } finally {
          await tester.dispose();
        }
      },
    );

    test('scroll-only frames reuse cache (content unchanged)', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final scrollCtrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 5,
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Column(
                children: List.generate(30, (i) => Text('Line $i')),
              ),
            ),
          ),
        );

        // Initial render shows Line 0-4.
        expect(tester.find.text('Line 0'), isTrue);
        expect(tester.find.text('Line 4'), isTrue);

        // Scroll down by 5.
        scrollCtrl.jumpTo(5);
        // Trigger a render.
        tester.pump();

        // Now shows Line 5-9 — scroll-only change, cache should be reused
        // internally (but output still updates because slicing changes).
        expect(tester.find.text('Line 5'), isTrue);
        expect(tester.find.text('Line 9'), isTrue);
        // Line 0 should no longer be visible.
        expect(tester.find.text('Line 0'), isFalse);

        // Scroll again.
        scrollCtrl.jumpTo(10);
        tester.pump();

        expect(tester.find.text('Line 10'), isTrue);
        expect(tester.find.text('Line 14'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test(
      'markNeedsPaint from descendant invalidates ancestor viewport cache',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
        try {
          // A widget that changes content via setState.
          await tester.pumpWidget(
            Container(
              width: 40,
              height: 5,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _PaintToggleWidget(),
                    ...List.generate(20, (i) => Text('Filler $i')),
                  ],
                ),
              ),
            ),
          );

          expect(tester.find.text('STATE: OFF'), isTrue);

          // Press 't' to toggle paint state.
          tester.sendKey('t');

          expect(
            tester.find.text('STATE: ON'),
            isTrue,
            reason:
                'descendant content changes should invalidate viewport cache',
          );
        } finally {
          await tester.dispose();
        }
      },
    );
  });
}

// -------------------------------------------------------
// Helper widgets for tests
// -------------------------------------------------------

/// A stateful counter widget that increments on '+' key.
class _CounterWidget extends StatefulWidget {
  @override
  State createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int _count = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == '+') {
      setState(() => _count++);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Text('Count: $_count');
  }
}

/// A widget that toggles its text output on 't' key via setState.
class _PaintToggleWidget extends StatefulWidget {
  @override
  State createState() => _PaintToggleWidgetState();
}

class _PaintToggleWidgetState extends State<_PaintToggleWidget> {
  bool _on = false;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 't') {
      setState(() => _on = !_on);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Text('STATE: ${_on ? "ON" : "OFF"}');
  }
}
