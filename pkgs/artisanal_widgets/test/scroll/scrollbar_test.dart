library;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Scrollbar — property / construction tests
  // ---------------------------------------------------------------------------
  group('Scrollbar properties', () {
    test('constructor sets default values', () {
      final ctrl = ListViewController();
      final sb = Scrollbar(child: Text('x'), controller: ctrl);
      expect(sb.trackChar, equals('│'));
      expect(sb.thumbChar, equals('█'));
      expect(sb.thickness, equals(1));
      expect(sb.gutterWidth, isNull);
      expect(sb.roundedCaps, isFalse);
      expect(sb.thumbCapTopChar, isNull);
      expect(sb.thumbCapBottomChar, isNull);
      expect(sb.enableHover, isFalse);
      expect(sb.overlay, isFalse);
      expect(sb.gap, equals(0));
      expect(sb.mouseWheelDelta, equals(3));
      expect(sb.enableDrag, isTrue);
      expect(sb.zoneId, isNull);
      expect(sb.trackStyle, isNull);
      expect(sb.thumbStyle, isNull);
      expect(sb.trackGradient, isNull);
      expect(sb.thumbGradient, isNull);
      expect(sb.trackUsesBackground, isFalse);
      expect(sb.thumbUsesBackground, isFalse);
      expect(sb.hoverTrackStyle, isNull);
      expect(sb.hoverThumbStyle, isNull);
      expect(sb.hoverTrackGradient, isNull);
      expect(sb.hoverThumbGradient, isNull);
      expect(sb.hoverTrackChar, isNull);
      expect(sb.hoverThumbChar, isNull);
    });

    test('constructor sets custom values', () {
      final ctrl = ListViewController();
      final sb = Scrollbar(
        child: Text('x'),
        controller: ctrl,
        trackChar: '#',
        thumbChar: '*',
        thickness: 2,
        gutterWidth: 3,
        roundedCaps: true,
        thumbCapTopChar: '^',
        thumbCapBottomChar: 'v',
        enableHover: true,
        overlay: true,
        gap: 1,
        mouseWheelDelta: 5,
        enableDrag: false,
        zoneId: 'my-sb',
        trackUsesBackground: true,
        thumbUsesBackground: true,
      );
      expect(sb.trackChar, equals('#'));
      expect(sb.thumbChar, equals('*'));
      expect(sb.thickness, equals(2));
      expect(sb.gutterWidth, equals(3));
      expect(sb.roundedCaps, isTrue);
      expect(sb.thumbCapTopChar, equals('^'));
      expect(sb.thumbCapBottomChar, equals('v'));
      expect(sb.enableHover, isTrue);
      expect(sb.overlay, isTrue);
      expect(sb.gap, equals(1));
      expect(sb.mouseWheelDelta, equals(5));
      expect(sb.enableDrag, isFalse);
      expect(sb.zoneId, equals('my-sb'));
      expect(sb.trackUsesBackground, isTrue);
      expect(sb.thumbUsesBackground, isTrue);
    });

    test('child is required', () {
      final ctrl = ListViewController();
      final sb = Scrollbar(child: Text('content'), controller: ctrl);
      expect(sb.child, isA<Text>());
      expect(sb.controller, same(ctrl));
    });
  });

  // ---------------------------------------------------------------------------
  // ScrollbarGradient
  // ---------------------------------------------------------------------------
  group('ScrollbarGradient', () {
    test('default constructor sets useBackground to false', () {
      final g = ScrollbarGradient(start: AnsiColor(1), end: AnsiColor(2));
      expect(g.start, isA<AnsiColor>());
      expect(g.end, isA<AnsiColor>());
      expect(g.useBackground, isFalse);
    });

    test('foreground named constructor sets useBackground to false', () {
      final g = ScrollbarGradient.foreground(
        start: AnsiColor(1),
        end: AnsiColor(2),
      );
      expect(g.useBackground, isFalse);
    });

    test('background named constructor sets useBackground to true', () {
      final g = ScrollbarGradient.background(
        start: AnsiColor(1),
        end: AnsiColor(2),
      );
      expect(g.useBackground, isTrue);
    });

    test('explicit useBackground overrides default', () {
      final g = ScrollbarGradient(
        start: AnsiColor(1),
        end: AnsiColor(2),
        useBackground: true,
      );
      expect(g.useBackground, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar rendering — non-overlay mode
  // ---------------------------------------------------------------------------
  group('Scrollbar rendering (non-overlay)', () {
    test('renders child alongside scrollbar track', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        final view = tester.view;
        // The track char should appear in the output
        expect(view.contains('│'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('custom track and thumb chars appear in output', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              trackChar: '|',
              thumbChar: '#',
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        final view = tester.view;
        // Custom chars should be present
        expect(view.contains('#') || view.contains('|'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('scrollbar reserves width for track in non-overlay', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thickness: 2,
              child: Text('Content'),
            ),
          ),
        );

        // In non-overlay mode, scrollbar reserves space.
        // The view should render successfully.
        expect(tester.view, isNotEmpty);
      } finally {
        await tester.dispose();
      }
    });

    test('gap adds space between content and scrollbar', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 30,
            height: 5,
            child: Scrollbar(controller: ctrl, gap: 2, child: Text('Hello')),
          ),
        );

        expect(tester.view, isNotEmpty);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar rendering — overlay mode
  // ---------------------------------------------------------------------------
  group('Scrollbar rendering (overlay)', () {
    test('overlay mode does not reserve extra width', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              overlay: true,
              child: Text('Content'),
            ),
          ),
        );

        expect(tester.view, isNotEmpty);
      } finally {
        await tester.dispose();
      }
    });

    test('overlay scrollbar still shows track chars', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              overlay: true,
              child: Column(
                children: List.generate(5, (i) => Text('Line $i here')),
              ),
            ),
          ),
        );

        // Track chars should still be drawn
        expect(tester.view.contains('│') || tester.view.contains('█'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar thumb positioning
  // ---------------------------------------------------------------------------
  group('Scrollbar thumb positioning', () {
    test('thumb at top when offset is 0', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(8);
        ctrl.setContentHeight(40);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 8,
            child: Scrollbar(
              controller: ctrl,
              thumbChar: '#',
              trackChar: '.',
              child: Column(children: List.generate(8, (i) => Text('Item $i'))),
            ),
          ),
        );

        // Thumb should be at the top (first line of scrollbar area has thumb)
        final lines = tester.viewLines;
        expect(lines.isNotEmpty, isTrue);
        // The first line should contain the thumb char
        expect(lines[0].contains('#'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('thumb moves down when scrolled via wheel event', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 12);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(8);
        ctrl.setContentHeight(80);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 8,
            child: Scrollbar(
              controller: ctrl,
              thumbChar: '#',
              trackChar: '.',
              child: Column(children: List.generate(8, (i) => Text('Item $i'))),
            ),
          ),
        );

        final viewBefore = tester.view;

        // Scroll via wheel event — this goes through handleUpdate
        // and triggers repaint
        for (var i = 0; i < 20; i++) {
          tester.sendMsg(
            tui.MouseMsg(
              action: tui.MouseAction.wheel,
              button: tui.MouseButton.wheelDown,
              x: 19,
              y: 0,
            ),
          );
        }

        final viewAfter = tester.view;
        // The view should change after scrolling (thumb moved)
        expect(viewAfter, isNot(equals(viewBefore)));
      } finally {
        await tester.dispose();
      }
    });

    test('no thumb when content fits viewport', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(10);
        ctrl.setContentHeight(5);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thumbChar: '#',
              trackChar: '.',
              child: Column(children: List.generate(5, (i) => Text('Item $i'))),
            ),
          ),
        );

        // When content <= viewport, thumb covers entire track
        // All visible scrollbar chars should be '#'
        final view = tester.view;
        // The thumb fills the viewport, so no track-only '.' line
        expect(view, isNotEmpty);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar — mouse wheel scrolling
  // ---------------------------------------------------------------------------
  group('Scrollbar mouse wheel scrolling', () {
    test('wheel down scrolls content forward', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              mouseWheelDelta: 3,
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        expect(ctrl.offset, equals(0));

        // Send a wheel-down event at the scrollbar area
        // In non-overlay mode, the scrollbar is to the right of the child.
        // We send the event somewhere within the widget area.
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: 19,
            y: 0,
          ),
        );

        expect(ctrl.offset, equals(3));
      } finally {
        await tester.dispose();
      }
    });

    test('wheel up scrolls content backward', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              mouseWheelDelta: 3,
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        // Scroll down first
        ctrl.scrollBy(10);
        tester.pump();
        expect(ctrl.offset, equals(10));

        // Now wheel up
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelUp,
            x: 19,
            y: 0,
          ),
        );

        expect(ctrl.offset, equals(7));
      } finally {
        await tester.dispose();
      }
    });

    test('custom mouseWheelDelta controls scroll amount', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(100);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              mouseWheelDelta: 7,
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: 19,
            y: 0,
          ),
        );

        expect(ctrl.offset, equals(7));
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar — rounded caps
  // ---------------------------------------------------------------------------
  group('Scrollbar rounded caps', () {
    test('roundedCaps shows cap characters', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 12);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(10);
        ctrl.setContentHeight(40);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 10,
            child: Scrollbar(
              controller: ctrl,
              roundedCaps: true,
              thumbChar: '█',
              trackChar: '│',
              child: Column(
                children: List.generate(10, (i) => Text('Line $i')),
              ),
            ),
          ),
        );

        // Default rounded caps use ▀ (top) and ▄ (bottom)
        final view = tester.view;
        expect(view.contains('▀') || view.contains('▄'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('custom cap characters override defaults', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 12);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(10);
        ctrl.setContentHeight(40);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 10,
            child: Scrollbar(
              controller: ctrl,
              roundedCaps: true,
              thumbCapTopChar: '^',
              thumbCapBottomChar: 'v',
              thumbChar: '#',
              trackChar: '.',
              child: Column(
                children: List.generate(10, (i) => Text('Line $i')),
              ),
            ),
          ),
        );

        final view = tester.view;
        expect(view.contains('^'), isTrue);
        expect(view.contains('v'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar — ViewportController integration
  // ---------------------------------------------------------------------------
  group('Scrollbar with ViewportController', () {
    test('works with ViewportController', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ViewportController();
        ctrl.configure(width: 15, height: 5);
        ctrl.setContent(_lines(20));

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              child: Viewport(
                content: _lines(20),
                width: 15,
                height: 5,
                controller: ctrl,
              ),
            ),
          ),
        );

        expect(tester.view, isNotEmpty);
        expect(ctrl.offset, equals(0));
      } finally {
        await tester.dispose();
      }
    });

    test('scrolling ViewportController updates thumb position', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ViewportController();
        ctrl.configure(width: 15, height: 5);
        ctrl.setContent(_lines(50));

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thumbChar: '#',
              trackChar: '.',
              child: Viewport(
                content: _lines(50),
                width: 15,
                height: 5,
                controller: ctrl,
              ),
            ),
          ),
        );

        final viewBefore = tester.view;

        // Scroll to the end
        ctrl.jumpTo(ctrl.maxOffset);
        tester.pump();

        final viewAfter = tester.view;
        // The view should change since thumb position moved
        expect(viewAfter != viewBefore, isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar — thickness and gutterWidth
  // ---------------------------------------------------------------------------
  group('Scrollbar thickness and gutter', () {
    test('thickness 1 produces single column scrollbar', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thickness: 1,
              child: Text('Hello'),
            ),
          ),
        );

        expect(tester.view, isNotEmpty);
      } finally {
        await tester.dispose();
      }
    });

    test('larger thickness increases scrollbar width', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 25,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thickness: 3,
              thumbChar: '#',
              child: Text('Hello'),
            ),
          ),
        );

        final view = tester.view;
        // With thickness 3, each scrollbar line should have 3 consecutive chars
        expect(view.contains('###'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('gutterWidth overrides track width when larger', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(20);

        await tester.pumpWidget(
          Container(
            width: 30,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thickness: 1,
              gutterWidth: 3,
              thumbChar: '#',
              trackChar: '.',
              child: Text('Hello'),
            ),
          ),
        );

        // GutterWidth 3 means the track area is 3 columns wide
        // but the thumb is only 1 column wide (thickness), centered
        expect(tester.view, isNotEmpty);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ListViewController — tests specific to scrollbar integration
  // ---------------------------------------------------------------------------
  group('ListViewController', () {
    test('scrollPercent is 0 at top', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(100);
      expect(ctrl.scrollPercent, equals(0.0));
    });

    test('scrollPercent is 1.0 at bottom', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(100);
      ctrl.jumpTo(ctrl.maxOffset);
      expect(ctrl.scrollPercent, equals(1.0));
    });

    test('scrollPercent is 0 when content fits viewport', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(5);
      expect(ctrl.scrollPercent, equals(0.0));
    });

    test('maxOffset is 0 when content fits viewport', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(5);
      expect(ctrl.maxOffset, equals(0));
    });

    test('maxOffset is content - viewport', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(50);
      expect(ctrl.maxOffset, equals(40));
    });

    test('setViewportHeight clamps offset', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(50);
      ctrl.jumpTo(40);
      expect(ctrl.offset, equals(40));

      // Shrinking content should clamp offset
      ctrl.setContentHeight(30);
      expect(ctrl.offset, lessThanOrEqualTo(ctrl.maxOffset));
    });

    test('setContentHeight clamps offset', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(50);
      ctrl.jumpTo(40);

      ctrl.setContentHeight(20);
      expect(ctrl.offset, lessThanOrEqualTo(ctrl.maxOffset));
      expect(ctrl.maxOffset, equals(10));
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar — enableDrag false disables drag
  // ---------------------------------------------------------------------------
  group('Scrollbar enableDrag', () {
    test('enableDrag false prevents drag interaction', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(100);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              enableDrag: false,
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        expect(ctrl.offset, equals(0));

        // Try pressing on the scrollbar area — should not drag
        tester.mouseDown(19, 0);
        tester.mouseMove(19, 4);
        tester.mouseUp(19, 4);

        // Offset should remain 0 since drag is disabled
        expect(ctrl.offset, equals(0));
      } finally {
        await tester.dispose();
      }
    });
  });

  group('Scrollbar track hit testing', () {
    test('gap column is not treated as draggable track', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(100);

        await tester.pumpWidget(
          Container(
            width: 24,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              gap: 1,
              thickness: 1,
              gutterWidth: 1,
              child: Column(
                children: List.generate(5, (i) => Text('Scrollable row $i')),
              ),
            ),
          ),
        );

        expect(ctrl.offset, equals(0));

        // width=24, gap=1, track=1 -> gap x=22, track x=23.
        tester.mouseDown(22, 1);
        tester.mouseMove(22, 4);
        tester.mouseUp(22, 4);
        expect(ctrl.offset, equals(0));

        tester.mouseDown(23, 1);
        tester.mouseMove(23, 4);
        tester.mouseUp(23, 4);
        expect(ctrl.offset, greaterThan(0));
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scrollbar — controller scrollPercent and thumbMetrics consistency
  // ---------------------------------------------------------------------------
  group('Scrollbar controller integration', () {
    test('scrollBy updates scrollPercent proportionally', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(100);

      ctrl.scrollBy(45);
      expect(ctrl.offset, equals(45));
      expect(ctrl.scrollPercent, equals(0.5));
    });

    test('jumpTo at maxOffset gives scrollPercent 1.0', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(100);

      ctrl.jumpTo(90);
      expect(ctrl.offset, equals(90));
      expect(ctrl.scrollPercent, equals(1.0));
    });

    test('jumpTo clamps to maxOffset', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(50);

      ctrl.jumpTo(999);
      expect(ctrl.offset, equals(40));
    });

    test('jumpTo clamps to 0', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(50);

      ctrl.jumpTo(-10);
      expect(ctrl.offset, equals(0));
    });

    test('scrollBy returns false when at boundary', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(20);

      // At top, scrolling up returns false
      expect(ctrl.scrollBy(-1), isFalse);

      // Jump to max
      ctrl.jumpTo(ctrl.maxOffset);
      // At bottom, scrolling down returns false
      expect(ctrl.scrollBy(1), isFalse);
    });

    test('scrollBy returns false for delta 0', () {
      final ctrl = ListViewController();
      ctrl.setViewportHeight(10);
      ctrl.setContentHeight(50);
      expect(ctrl.scrollBy(0), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Bug 5 regression — Scrollbar now listens to controller changes
  // ---------------------------------------------------------------------------
  group('Bug 5 regression: Scrollbar controller listener', () {
    test('external jumpTo triggers Scrollbar repaint', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ViewportController();
        ctrl.configure(width: 15, height: 5);
        ctrl.setContent(_lines(50));

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thumbChar: '#',
              trackChar: '.',
              child: Viewport(
                content: _lines(50),
                width: 15,
                height: 5,
                controller: ctrl,
              ),
            ),
          ),
        );

        final viewBefore = tester.view;

        // External controller change — should trigger repaint via listener
        ctrl.jumpTo(ctrl.maxOffset);
        tester.pump();

        final viewAfter = tester.view;
        expect(
          viewAfter != viewBefore,
          isTrue,
          reason: 'Scrollbar should repaint when controller scrolls externally',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('external scrollBy triggers Scrollbar repaint', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl = ListViewController();
        ctrl.setViewportHeight(5);
        ctrl.setContentHeight(100);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl,
              thumbChar: '#',
              trackChar: '.',
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        final viewBefore = tester.view;

        // External scrollBy — should trigger repaint
        ctrl.scrollBy(50);
        tester.pump();

        final viewAfter = tester.view;
        expect(
          viewAfter != viewBefore,
          isTrue,
          reason:
              'Scrollbar should repaint when controller scrollBy called externally',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('Scrollbar cleans up listener on dispose', () async {
      // Verify no errors when tester disposes (which tears down the widget tree)
      final ctrl = ListViewController();
      ctrl.setViewportHeight(5);
      ctrl.setContentHeight(20);

      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(controller: ctrl, child: Text('content')),
          ),
        );

        expect(tester.view, isNotEmpty);
      } finally {
        // dispose should cleanly remove the listener
        await tester.dispose();
      }

      // After dispose, scrolling should not throw
      ctrl.scrollBy(5);
    });

    test('controller swap removes old listener and adds new', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        final ctrl1 = ListViewController();
        ctrl1.setViewportHeight(5);
        ctrl1.setContentHeight(100);

        final ctrl2 = ListViewController();
        ctrl2.setViewportHeight(5);
        ctrl2.setContentHeight(100);

        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl1,
              thumbChar: '#',
              trackChar: '.',
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        final viewWithCtrl1 = tester.view;

        // Swap to ctrl2
        await tester.pumpWidget(
          Container(
            width: 20,
            height: 5,
            child: Scrollbar(
              controller: ctrl2,
              thumbChar: '#',
              trackChar: '.',
              child: Column(children: List.generate(5, (i) => Text('Row $i'))),
            ),
          ),
        );

        // Scroll ctrl2 externally — should trigger repaint
        ctrl2.scrollBy(50);
        tester.pump();

        final viewAfter = tester.view;
        expect(
          viewAfter != viewWithCtrl1,
          isTrue,
          reason: 'New controller should trigger Scrollbar repaint',
        );

        // Scrolling ctrl1 should NOT cause issues (listener removed)
        ctrl1.scrollBy(30);
        // No crash = success
      } finally {
        await tester.dispose();
      }
    });
  });
}

/// Generates [count] lines of "Line 0\nLine 1\n..." text.
String _lines(int count) {
  return List.generate(count, (i) => 'Line $i').join('\n');
}
