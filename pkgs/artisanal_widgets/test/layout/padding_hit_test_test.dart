import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Padding hit testing', () {
    test('offsets child hit area by padding in both axes', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 8);
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      await tester.pumpWidget(
        w.Container(
          width: 20,
          height: 6,
          child: w.Padding(
            padding: const w.EdgeInsets.only(
              left: 2,
              right: 2,
              top: 1,
              bottom: 1,
            ),
            child: w.GestureDetector(
              onTap: () {
                tapCount += 1;
                return null;
              },
              child: w.Container(width: 6, height: 2),
            ),
          ),
        ),
      );

      tapCount = 0;
      tester.tapAt(1, 2);
      expect(tapCount, 0, reason: 'Left padding should not hit child.');

      tapCount = 0;
      tester.tapAt(2, 1);
      expect(tapCount, 1, reason: 'Top-left content cell should hit child.');

      tapCount = 0;
      tester.tapAt(18, 2);
      expect(tapCount, 0, reason: 'Right padding should not hit child.');

      tapCount = 0;
      tester.tapAt(4, 0);
      expect(tapCount, 0, reason: 'Top padding should not hit child.');
    });

    test(
      'keeps scrollbar lane aligned when wrapped in horizontal padding',
      () async {
        final tester = WidgetTester(screenWidth: 32, screenHeight: 12);
        addTearDown(() => tester.dispose());

        final controller = w.WidgetScrollController();
        final rows = List<w.Widget>.generate(80, (i) => w.Text('row $i'));

        await tester.pumpWidget(
          w.Container(
            width: 30,
            height: 12,
            child: w.Padding(
              padding: const w.EdgeInsets.symmetric(horizontal: 2),
              child: w.Scrollbar(
                controller: controller,
                thickness: 1,
                gutterWidth: 3,
                gap: 1,
                child: w.VirtualListView(
                  controller: controller,
                  variableHeight: false,
                  estimatedItemExtent: 1,
                  children: rows,
                ),
              ),
            ),
          ),
        );

        expect(controller.maxOffset, greaterThan(0));

        final hitColumns = <int>[];
        for (var laneX = 22; laneX <= 29; laneX++) {
          controller.jumpTo(0);
          tester.pump();

          tester.mouseDown(laneX, 2);
          tester.mouseMove(laneX, 8);
          tester.mouseUp(laneX, 8);

          if (controller.offset > 0) {
            hitColumns.add(laneX);
          }
        }

        expect(
          hitColumns,
          equals([25, 26, 27]),
          reason: 'Expected padded scrollbar lane at x=25..27, got $hitColumns',
        );
      },
    );
  });
}
