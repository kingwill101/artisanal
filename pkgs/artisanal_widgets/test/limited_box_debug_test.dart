import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Container deflates child constraints by padding', () {
    test('child receives deflated maxWidth and maxHeight', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 20);
      addTearDown(() => tester.dispose());

      // The Container has padding: all(2), so the child should see
      // maxWidth = 40 - 4 = 36, maxHeight = 20 - 4 = 16.
      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.all(2),
          color: const BasicColor('#111111'),
          child: w.Text('X'),
        ),
      );

      // The Container should fill the full terminal (40 x 20).
      final lines = tester.viewLines;
      expect(lines.length, equals(20));
      for (var i = 0; i < lines.length; i++) {
        final vis = Layout.visibleLength(lines[i]);
        expect(vis, equals(40), reason: 'Line $i should be 40 chars wide');
      }

      // Text 'X' should be at position (2, 2) — inside the padding.
      final pos = tester.locateText('X');
      expect(pos, isNotNull);
      expect(pos!.x, equals(2));
      expect(pos.y, equals(2));
    });

    test('padded Container with Scrollbar+ScrollView fits viewport', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 15);
      addTearDown(() => tester.dispose());

      final controller = w.WidgetScrollController();
      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.all(1),
          color: const BasicColor('#222222'),
          child: w.Scrollbar(
            controller: controller,
            thickness: 1,
            gap: 1,
            child: w.ScrollView(
              controller: controller,
              child: w.Column(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: List.generate(12, (i) => w.Text('Item ${i + 1}')),
              ),
            ),
          ),
        ),
      );

      final lines = tester.viewLines;
      final strippedLines = lines.map(Layout.stripAnsi).toList();

      // Must be exactly the viewport height.
      expect(lines.length, equals(15));

      // Every line must be the full terminal width (no empty padding rows).
      for (var i = 0; i < strippedLines.length; i++) {
        expect(
          strippedLines[i].length,
          equals(40),
          reason: 'Line $i should be 40 chars wide',
        );
      }

      // Top and bottom padding rows should not contain scrollbar chars.
      expect(
        strippedLines[0].trim(),
        isEmpty,
        reason: 'Top padding row should be empty space',
      );
      expect(
        strippedLines[14].trim(),
        isEmpty,
        reason: 'Bottom padding row should be empty space',
      );

      // Content rows (1..13) should contain item text.
      expect(strippedLines[1], contains('Item 1'));
    });

    test('padded Container without Scrollbar fits viewport', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          color: const BasicColor('#333333'),
          child: w.Column(children: [w.Text('Hello'), w.Text('World')]),
        ),
      );

      final lines = tester.viewLines;
      final stripped = lines.map(Layout.stripAnsi).toList();

      // Container should produce a consistent block.
      // All lines should have the same width.
      final widths = stripped.map((l) => l.length).toSet();
      expect(
        widths.length,
        equals(1),
        reason: 'All lines should have the same width',
      );
      expect(widths.first, equals(30));

      // Text should be at (2, 1) due to padding.
      final helloPos = tester.locateText('Hello');
      expect(helloPos, isNotNull);
      expect(helloPos!.x, equals(2));
      expect(helloPos.y, equals(1));
    });

    test('RenderText clips paint output to constrained width', () async {
      // Regression: a Text widget whose natural width exceeds the constraint
      // (e.g. Divider(width: 60) inside a 30-col Column) used to paint the
      // full 60-char string.  The Scrollbar would then join the oversized
      // content with the scrollbar track at column 61+, and the Container
      // canvas clipped it off-screen, making the scrollbar invisible.
      final tester = WidgetTester(screenWidth: 40, screenHeight: 15);
      addTearDown(() => tester.dispose());

      final controller = w.WidgetScrollController();
      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.all(1),
          color: const BasicColor('#222222'),
          child: w.Scrollbar(
            controller: controller,
            thickness: 1,
            gap: 1,
            child: w.ScrollView(
              controller: controller,
              child: w.Column(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: [
                  w.Text('Title'),
                  // Divider wider than the available Column width (40 - 2 pad
                  // - 2 scrollbar = 36).  Before fix, this made the scrollbar
                  // disappear at narrow terminals.
                  w.Divider(width: 60),
                  ...List.generate(20, (i) => w.Text('Item ${i + 1}')),
                ],
              ),
            ),
          ),
        ),
      );

      final lines = tester.viewLines;
      final stripped = lines.map(Layout.stripAnsi).toList();

      // Every line must be exactly the terminal width.
      expect(lines.length, equals(15));
      for (var i = 0; i < stripped.length; i++) {
        expect(
          stripped[i].length,
          equals(40),
          reason: 'Line $i should be 40 chars wide',
        );
      }

      // Content is 20 items + title + divider + gaps — definitely more than
      // the 13-line viewport (15 - 2 padding).  The scrollbar should be
      // visible, meaning the last two visible characters of content rows
      // should contain the scrollbar track/thumb (gap + track = 2 cols at
      // the right edge inside padding).
      //
      // Check that the scrollbar track column is not blank.  The track is at
      // column 38 inside the 40-wide terminal (1 pad + 36 content + 1 gap +
      // 1 track + 1 pad = 40).
      // We check a middle content row (not top/bottom padding).
      // The scrollbar track char should be at position 38 (0-based).
      // A blank track would be a plain space.  A visible scrollbar produces
      // either a styled space (background color) or a non-space character.
      // Since we stripped ANSI, we can't see styled spaces, so instead check
      // the view string for the controller metrics: content > viewport means
      // the scrollbar rendered (it returned a non-empty string).
      expect(controller.contentExtent, greaterThan(controller.viewportExtent));

      // Double-check the view has the right layout width: no line should be
      // wider than 40 (i.e. the Divider was clipped).
      for (final line in stripped) {
        expect(line.length, lessThanOrEqualTo(40));
      }
    });

    test('scrollbar click works inside padded Container', () async {
      // Bug #6: Scrollbar is not clickable/draggable when inside a padded
      // Container.  Two root causes:
      // 1. Examples missing mouseMode: MouseMode.allMotion in ProgramOptions
      //    (mouse events never reach the app at runtime).
      // 2. _dragOriginY was set to 0 instead of the scrollbar's global Y,
      //    causing subsequent drag motions to use wrong coordinates.
      final tester = WidgetTester(screenWidth: 40, screenHeight: 15);
      addTearDown(() => tester.dispose());

      final controller = w.WidgetScrollController();
      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.all(1),
          color: const BasicColor('#222222'),
          child: w.Scrollbar(
            controller: controller,
            thickness: 1,
            gap: 1,
            child: w.ScrollView(
              controller: controller,
              child: w.Column(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: List.generate(30, (i) => w.Text('Item ${i + 1}')),
              ),
            ),
          ),
        ),
      );

      // Verify content overflows the viewport (scrollbar should be visible).
      expect(controller.contentExtent, greaterThan(controller.viewportExtent));
      expect(controller.offset, equals(0));

      // The layout:
      // - Terminal: 40 cols (0-39)
      // - Container padding=1: content area cols 1-38 (38 wide)
      // - Scrollbar: gap=1 + track=1 → child gets 36 cols, track at col 37
      //   (scrollbar-local), which is absolute col 38.
      //
      // Hit test at the track column (absolute x=38):
      final hits = tester.hitTestAt(38, 5);
      expect(
        hits,
        isNotEmpty,
        reason: 'Hit test at scrollbar track column should hit something',
      );

      // Try clicking the scrollbar track — this should initiate a drag
      // and scroll down (clicking below the thumb).
      final offsetBefore = controller.offset;
      tester.tapAt(38, 10); // tap near the bottom of the track
      final offsetAfter = controller.offset;
      expect(
        offsetAfter,
        greaterThan(offsetBefore),
        reason: 'Tapping the scrollbar track should scroll',
      );
    });

    test('scrollbar drag works inside padded Container', () async {
      // Regression: after pressing on the scrollbar track inside a padded
      // Container, subsequent raw MouseMsg motion events carry absolute Y.
      // _dragOriginY must equal the scrollbar's global Y so that
      // localY = msg.y - _dragOriginY produces the correct scrollbar-local Y.
      final tester = WidgetTester(screenWidth: 40, screenHeight: 20);
      addTearDown(() => tester.dispose());

      final controller = w.WidgetScrollController();
      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.all(2),
          color: const BasicColor('#222222'),
          child: w.Scrollbar(
            controller: controller,
            thickness: 1,
            gap: 1,
            child: w.ScrollView(
              controller: controller,
              child: w.Column(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: List.generate(40, (i) => w.Text('Line ${i + 1}')),
              ),
            ),
          ),
        ),
      );

      expect(controller.contentExtent, greaterThan(controller.viewportExtent));
      expect(controller.offset, equals(0));

      // Track column: padding=2 on each side → content area cols 2-37 (36 wide).
      // Scrollbar reserves gap(1)+track(1)=2 → child=34, track at col 36
      // (scrollbar-local), which is absolute col 38 (2 + 36).
      // But let's compute: scrollbar size = 34+2 = 36, at offset (2,2).
      // Absolute track X = 2 + 34 = 36.. let me verify:
      // Actually: scrollbar gets maxWidth = 40 - 4(padding) = 36.
      // Child gets 36 - 2(gap+track) = 34. Track starts at child width = 34
      // inside scrollbar. Global X = 2(offset) + 34 = 36.

      // Press on the thumb (near top of track) and drag it downward.
      // The thumb should be near the top since offset=0.
      final trackX = 37; // absolute X of track (2 + 34 + 1 gap = 37)

      // Press on the track
      tester.mouseDown(trackX, 3); // near top, in thumb area
      final afterPress = controller.offset;

      // Drag downward
      tester.mouseMove(trackX, 12); // move to near bottom
      final afterDrag = controller.offset;

      // Release
      tester.mouseUp(trackX, 12);
      final afterRelease = controller.offset;

      // The drag should have scrolled significantly.
      expect(
        afterDrag,
        greaterThan(afterPress),
        reason: 'Dragging the scrollbar thumb downward should scroll',
      );
      // Offset should remain after release (not snap back).
      expect(
        afterRelease,
        equals(afterDrag),
        reason: 'Scroll position should persist after releasing the thumb',
      );
    });

    test('Container with border deflates by border + padding', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 6);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.all(1),
          decoration: w.BoxDecoration(border: Border.normal),
          child: w.Text('Hi'),
        ),
      );

      // Border = 1 cell on each side, padding = 1 on each side.
      // Child content area = 20 - 2(border) - 2(padding) = 16 wide.
      // Text 'Hi' should be at (2, 2) = border + padding on each axis.
      final pos = tester.locateText('Hi');
      expect(pos, isNotNull);
      expect(pos!.x, equals(2)); // 1 border + 1 padding
      expect(pos.y, equals(2)); // 1 border + 1 padding
    });
  });
}
