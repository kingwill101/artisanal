/// Regression tests for Container hit-testing.
///
/// Verifies that [RenderContainer] sets its child's render-object offset
/// correctly so that hit-tests match the visual paint positions — including
/// when the Container has padding, margin, border, alignment, or
/// combinations thereof.
///
/// See: Session 8 fix — child offset computation in `RenderContainer.layout()`.
library;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/artisanal_widgets.dart' show BoxDecoration;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 1. Aligned Container in Column — tap fires on ALL rows/columns
  // ---------------------------------------------------------------------------

  group('Container with alignment in Column', () {
    test('tap fires on every row and column of the Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;

      await tester.pumpWidget(
        w.Column(
          gap: 1,
          children: [
            w.Text('Title'),
            // gap row at y=1
            // Container at rows 2..4 (height 3), cols 0..19 (width 20)
            w.GestureDetector(
              onTap: () {
                tapCount++;
                return null;
              },
              child: w.Container(
                width: 20,
                height: 3,
                alignment: w.Alignment.center,
                child: w.Text('Click!'),
              ),
            ),
          ],
        ),
      );

      // Tap on the title row — should NOT fire.
      tapCount = 0;
      tester.tapAt(5, 0);
      expect(tapCount, 0, reason: 'Tap on Title row should not fire');

      // Tap on the gap row — should NOT fire.
      tapCount = 0;
      tester.tapAt(5, 1);
      expect(tapCount, 0, reason: 'Tap on gap row should not fire');

      // Tap on every cell of the 20x3 Container area (rows 2-4).
      for (var y = 2; y <= 4; y++) {
        for (var x = 0; x < 20; x++) {
          tapCount = 0;
          tester.tapAt(x, y);
          expect(
            tapCount,
            1,
            reason: 'Tap at ($x, $y) inside Container should fire',
          );
        }
      }
    });

    test('hit-test includes Container on its background area', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;

      await tester.pumpWidget(
        w.Column(
          gap: 0,
          children: [
            w.Text('Title'),
            w.GestureDetector(
              onTap: () {
                tapCount++;
                return null;
              },
              child: w.Container(
                width: 20,
                height: 3,
                alignment: w.Alignment.center,
                child: w.Text('Click!'),
              ),
            ),
          ],
        ),
      );

      // Row 1 col 0: empty background area of the Container (text is
      // centered, so col 0 has no text). Hit-test should include the
      // Container render object.
      final hits = tester.hitTestAt(0, 1);
      final hitTypes = hits
          .map((h) => h.element.widget.runtimeType.toString())
          .toList();
      expect(
        hitTypes,
        contains('Container'),
        reason: 'Hit-test on Container background should include Container',
      );

      // Verify tap fires GestureDetector callback.
      tapCount = 0;
      tester.tapAt(0, 1);
      expect(
        tapCount,
        1,
        reason: 'Tap on Container background should fire GestureDetector',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Outer Container with padding wrapping inner GestureDetector Container
  // ---------------------------------------------------------------------------

  group('Container with padding wrapping GestureDetector', () {
    test('tap fires only within padded content area, not in padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;

      // Outer Container: padding=1 on all sides.
      // Inner GestureDetector > Container: width=20, height=3.
      // Visual layout:
      //   Row 0: padding (top)
      //   Rows 1-3: content (inner Container at cols 1-20)
      //   Row 4: padding (bottom)
      await tester.pumpWidget(
        w.Container(
          padding: const w.EdgeInsets.all(1),
          child: w.GestureDetector(
            onTap: () {
              tapCount++;
              return null;
            },
            child: w.Container(
              width: 20,
              height: 3,
              alignment: w.Alignment.center,
              child: w.Text('Click!'),
            ),
          ),
        ),
      );

      // Tap in outer padding (top row, row 0) — should NOT fire on
      // GestureDetector.
      tapCount = 0;
      tester.tapAt(5, 0);
      expect(tapCount, 0, reason: 'Tap in top padding should not fire');

      // Tap in outer padding (left col=0, within content rows) — should NOT
      // fire on GestureDetector (it's in the outer Container's padding area).
      tapCount = 0;
      tester.tapAt(0, 2);
      expect(tapCount, 0, reason: 'Tap in left padding should not fire');

      // Tap inside the inner Container content area — should fire.
      // Inner Container starts at col=1 (padLeft=1), row=1 (padTop=1).
      tapCount = 0;
      tester.tapAt(5, 1);
      expect(
        tapCount,
        1,
        reason: 'Tap at (5,1) inside inner Container should fire',
      );

      tapCount = 0;
      tester.tapAt(1, 1);
      expect(
        tapCount,
        1,
        reason: 'Tap at (1,1) top-left of inner Container should fire',
      );

      tapCount = 0;
      tester.tapAt(20, 3);
      expect(
        tapCount,
        1,
        reason: 'Tap at (20,3) bottom-right of inner Container should fire',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Container with padding + Column with multiple children
  // ---------------------------------------------------------------------------

  group('Container(padding) > Column > GestureDetector', () {
    test(
      'tap fires only on the GestureDetector child, offset by padding',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        var tapCount = 0;

        await tester.pumpWidget(
          w.Container(
            padding: const w.EdgeInsets.all(1),
            child: w.Column(
              gap: 0,
              children: [
                w.Text('Title'),
                w.GestureDetector(
                  onTap: () {
                    tapCount++;
                    return null;
                  },
                  child: w.Container(
                    width: 20,
                    height: 3,
                    alignment: w.Alignment.center,
                    child: w.Text('Click!'),
                  ),
                ),
              ],
            ),
          ),
        );

        // Layout with padding=1:
        //   Row 0: outer padding
        //   Row 1: "Title" (inside padding, padTop=1)
        //   Rows 2-4: GestureDetector > Container (20x3)
        //   Row 5: outer padding (bottom)

        // Tap on Title — should NOT fire GestureDetector.
        tapCount = 0;
        tester.tapAt(3, 1);
        expect(tapCount, 0, reason: 'Tap on Title should not fire');

        // Tap on inner Container first row — should fire.
        tapCount = 0;
        tester.tapAt(5, 2);
        expect(
          tapCount,
          1,
          reason: 'Tap at (5,2) inside inner Container should fire',
        );

        // Tap on inner Container last row — should fire.
        tapCount = 0;
        tester.tapAt(10, 4);
        expect(
          tapCount,
          1,
          reason: 'Tap at (10,4) inside inner Container should fire',
        );

        // Tap on outer padding top — should NOT fire.
        tapCount = 0;
        tester.tapAt(5, 0);
        expect(tapCount, 0, reason: 'Tap in outer padding row should not fire');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 4. Container with margin — GestureDetector inside covers content only
  // ---------------------------------------------------------------------------

  group('Container with margin', () {
    test(
      'GestureDetector inside Container: fires in content, not in margin',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        var tapCount = 0;

        // Place inside a Stack so the outer Container doesn't fill the
        // entire terminal (which would make the GestureDetector always hit).
        await tester.pumpWidget(
          w.Stack(
            width: 40,
            height: 20,
            children: [
              w.Positioned(
                left: 0,
                top: 0,
                child: w.Container(
                  margin: const w.EdgeInsets.all(2),
                  width: 10,
                  height: 3,
                  child: w.GestureDetector(
                    onTap: () {
                      tapCount++;
                      return null;
                    },
                    child: w.Text('Hi'),
                  ),
                ),
              ),
            ],
          ),
        );

        // The Container has margin=2 on all sides.
        // Container width=10 (inner) → total rendered width = 10 + 4 = 14.
        // Container height=3 (inner) → total rendered height = 3 + 4 = 7.
        // Content starts at (2, 2) within the Container.
        // The GestureDetector wraps the Text inside the Container, so it
        // only covers the content area.

        // Tap in margin area (0, 0) — should NOT fire.
        tapCount = 0;
        tester.tapAt(0, 0);
        expect(
          tapCount,
          0,
          reason: 'Tap in margin area should not fire GestureDetector',
        );

        // Tap inside the content area (col=2, row=2) — should fire.
        tapCount = 0;
        tester.tapAt(2, 2);
        expect(tapCount, 1, reason: 'Tap inside content area should fire');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 5. Container with border (decoration)
  // ---------------------------------------------------------------------------

  group('Container with border', () {
    test('tap fires on content area inside border', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;

      await tester.pumpWidget(
        w.Stack(
          width: 40,
          height: 20,
          children: [
            w.Positioned(
              left: 0,
              top: 0,
              child: w.Container(
                decoration: BoxDecoration(border: Border.normal),
                width: 10,
                height: 3,
                child: w.GestureDetector(
                  onTap: () {
                    tapCount++;
                    return null;
                  },
                  child: w.Text('Hi'),
                ),
              ),
            ),
          ],
        ),
      );

      // Container with border: width=10 includes border.
      // Border takes 1 char each side → content area starts at (1,1).
      // Container renders 10 wide, 3 tall.

      // Tap on the border area (0,0) — should NOT fire the inner
      // GestureDetector (border is outside the content area).
      tapCount = 0;
      tester.tapAt(0, 0);
      expect(
        tapCount,
        0,
        reason: 'Tap on border should not fire inner GestureDetector',
      );

      // Tap inside content area (1,1) — should fire.
      tapCount = 0;
      tester.tapAt(1, 1);
      expect(tapCount, 1, reason: 'Tap on content area should fire');
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Full integration: padding + margin + border + alignment
  // ---------------------------------------------------------------------------

  group('Container with padding + margin + border + alignment', () {
    test(
      'child GestureDetector fires only at aligned content position',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        var childTapCount = 0;

        // Outer Container with padding, border, margin — child is a
        // GestureDetector wrapping a Text, centered within.
        await tester.pumpWidget(
          w.Stack(
            width: 40,
            height: 20,
            children: [
              w.Positioned(
                left: 0,
                top: 0,
                child: w.Container(
                  margin: const w.EdgeInsets.all(1),
                  padding: const w.EdgeInsets.all(1),
                  decoration: BoxDecoration(border: Border.normal),
                  width: 20,
                  height: 5,
                  alignment: w.Alignment.center,
                  child: w.GestureDetector(
                    onTap: () {
                      childTapCount++;
                      return null;
                    },
                    child: w.Text('OK'),
                  ),
                ),
              ),
            ],
          ),
        );

        // Layout breakdown:
        //   margin=1 each side, border=1 each side, padding=1 each side
        //   Container inner width=20 → total rendered = 20 + 2(margin) = 22
        //   Content area starts at margin(1) + border(1) + padding(1) = 3
        //   Content width = 20 - 2*(border+padding) = 20 - 4 = 16
        //   Content height = 5 - 2*(border+padding) = 5 - 4 = 1
        //   "OK" (2 chars) centered in 16 wide: offset = (16-2)/2 = 7
        //   → text at col 3+7=10, row 3

        // Tap at the expected text position — should fire.
        childTapCount = 0;
        tester.tapAt(10, 3);
        expect(
          childTapCount,
          1,
          reason: 'Tap at centered text position should fire',
        );

        // Tap in the margin area — should NOT fire child GestureDetector.
        childTapCount = 0;
        tester.tapAt(0, 0);
        expect(
          childTapCount,
          0,
          reason: 'Tap on margin should not fire child GestureDetector',
        );

        // Tap in the border area — should NOT fire child GestureDetector.
        childTapCount = 0;
        tester.tapAt(1, 1);
        expect(
          childTapCount,
          0,
          reason: 'Tap on border should not fire child GestureDetector',
        );

        // Tap in the padding area — should NOT fire child GestureDetector.
        childTapCount = 0;
        tester.tapAt(2, 2);
        expect(
          childTapCount,
          0,
          reason: 'Tap in padding should not fire child GestureDetector',
        );

        // Tap well outside — should NOT fire.
        childTapCount = 0;
        tester.tapAt(30, 10);
        expect(
          childTapCount,
          0,
          reason: 'Tap outside Container should not fire',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 7. Column gap=0 with aligned Container — no false offset
  // ---------------------------------------------------------------------------

  group('Column gap=0 with Container', () {
    test('tap fires immediately after Title row with gap=0', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;

      await tester.pumpWidget(
        w.Column(
          gap: 0,
          children: [
            w.Text('Title'),
            w.GestureDetector(
              onTap: () {
                tapCount++;
                return null;
              },
              child: w.Container(
                width: 20,
                height: 3,
                alignment: w.Alignment.center,
                child: w.Text('Click!'),
              ),
            ),
          ],
        ),
      );

      // With gap=0:
      //   Row 0: Title
      //   Rows 1-3: Container (20x3)

      // Tap on Title — should NOT fire.
      tapCount = 0;
      tester.tapAt(2, 0);
      expect(tapCount, 0, reason: 'Tap on Title row should not fire');

      // Tap on first Container row — should fire.
      tapCount = 0;
      tester.tapAt(0, 1);
      expect(
        tapCount,
        1,
        reason: 'Tap at (0,1) first Container row should fire',
      );

      // Tap on Container background (not where text is) — should fire.
      tapCount = 0;
      tester.tapAt(19, 1);
      expect(
        tapCount,
        1,
        reason: 'Tap at far right of Container background should fire',
      );

      // Tap on last Container row — should fire.
      tapCount = 0;
      tester.tapAt(10, 3);
      expect(
        tapCount,
        1,
        reason: 'Tap at (10,3) last Container row should fire',
      );
    });
  });
}
