import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

void main() {
  group('TilingPaneManager', () {
    test('split creates expected sub-pane geometry', () {
      final manager =
          tui.TilingPaneManager(
            rootPaneId: 'left',
            paneMinWidth: 4,
            paneMinHeight: 2,
          ).splitPane(
            targetPaneId: 'left',
            splitId: 'main',
            splitPaneId: 'right',
            direction: tui.PaneSplitDirection.vertical,
            ratio: 0.6,
          );

      final layout = manager.layout(width: 40, height: 10);
      final leftPane = layout.panes['left'];
      final rightPane = layout.panes['right'];

      expect(leftPane, isNotNull);
      expect(rightPane, isNotNull);
      expect(layout.panes.length, 2);

      final left = leftPane!;
      final right = rightPane!;
      expect(left.x, 0);
      expect(left.y, 0);
      expect(left.height, 10);
      expect(right.y, 0);
      expect(right.height, 10);

      expect(left.width + right.width, 40);
      expect(left.width, 24);
      expect(right.width, 16);
      expect(right.x, left.x + left.width);
      expect(layout.splits['main'], isNotNull);
    });

    test('drag resize enforces min sizes', () {
      final minWidth = 8;
      final manager =
          tui.TilingPaneManager(
            rootPaneId: 'left',
            paneMinWidth: minWidth,
            paneMinHeight: 2,
          ).splitPane(
            targetPaneId: 'left',
            splitId: 'main',
            splitPaneId: 'right',
            direction: tui.PaneSplitDirection.vertical,
          );

      final oversized = manager.dragResizeSplit(
        splitId: 'main',
        delta: 1000,
        width: 40,
        height: 10,
      );
      final shrunk = manager.dragResizeSplit(
        splitId: 'main',
        delta: -1000,
        width: 40,
        height: 10,
      );

      final minLayout = manager.layout(width: 40, height: 10).panes;
      final wideLayout = oversized.layout(width: 40, height: 10).panes;
      final narrowLayout = shrunk.layout(width: 40, height: 10).panes;

      for (final pane in wideLayout.values) {
        expect(pane.width, greaterThanOrEqualTo(minWidth));
      }
      for (final pane in narrowLayout.values) {
        expect(pane.width, greaterThanOrEqualTo(minWidth));
      }

      final expectedLeft = 32;
      final expectedRight = 8;
      expect(wideLayout['left']!.width, expectedLeft);
      expect(wideLayout['right']!.width, expectedRight);

      expect(minLayout['left']!.width, 20);
      expect(minLayout['right']!.width, 20);
      expect(narrowLayout['left']!.width, expectedRight);
      expect(narrowLayout['right']!.width, expectedLeft);
    });

    test('snap targets are detected near split divider', () {
      final manager =
          tui.TilingPaneManager(
            rootPaneId: 'left',
            paneMinWidth: 2,
            paneMinHeight: 2,
            snapThreshold: 3,
          ).splitPane(
            targetPaneId: 'left',
            splitId: 'split',
            splitPaneId: 'right',
            direction: tui.PaneSplitDirection.vertical,
            ratio: 0.45,
          );

      final layout = manager.layout(width: 50, height: 10);
      final split = layout.splits['split']!;
      final snapOn = manager.snapTarget(
        x: split.boundaryX + 1,
        y: 3,
        width: 50,
        height: 10,
      );
      final snapFar = manager.snapTarget(x: 1, y: 3, width: 50, height: 10);

      expect(snapOn, isNotNull);
      expect(snapOn!.splitId, 'split');
      expect(snapOn.direction, tui.PaneSplitDirection.vertical);
      expect(snapOn.alignment, tui.PaneSnapAlignment.after);
      expect(snapFar, isNull);
    });

    test('keyboard navigation moves focus between adjacent panes', () {
      var manager =
          tui.TilingPaneManager(
                rootPaneId: 'top-left',
                paneMinWidth: 1,
                paneMinHeight: 1,
              )
              .splitPane(
                targetPaneId: 'top-left',
                splitId: 'vertical',
                splitPaneId: 'bottom-left',
                direction: tui.PaneSplitDirection.vertical,
                ratio: 0.5,
              )
              .splitPane(
                targetPaneId: 'bottom-left',
                splitId: 'bottom-split',
                splitPaneId: 'bottom-right',
                direction: tui.PaneSplitDirection.horizontal,
                ratio: 0.5,
              );

      manager = manager.copyWith(focusedPaneId: 'top-left');
      final right = manager.focusByDirection(
        direction: tui.PaneNavigationDirection.right,
        width: 40,
        height: 10,
      );
      expect(right.focusedPaneId, 'bottom-left');

      final down = right.focusByDirection(
        direction: tui.PaneNavigationDirection.down,
        width: 40,
        height: 10,
      );
      expect(down.focusedPaneId, 'bottom-right');
      expect(
        down
            .focusByDirection(
              direction: tui.PaneNavigationDirection.right,
              width: 40,
              height: 10,
            )
            .focusedPaneId,
        'bottom-right',
      );
    });

    test('validation reports duplicate ids and invalid ratios', () {
      final duplicatePanes = tui.TilingPaneManager.withRoot(
        root: tui.PaneSplit(
          splitId: 'split-1',
          direction: tui.PaneSplitDirection.vertical,
          first: const tui.PaneLeaf('same'),
          second: const tui.PaneLeaf('same'),
          ratio: 0.5,
        ),
        focusedPaneId: 'same',
        paneMinWidth: 1,
        paneMinHeight: 1,
      );

      final badRatio = tui.TilingPaneManager.withRoot(
        root: const tui.PaneSplit(
          splitId: 'split-1',
          direction: tui.PaneSplitDirection.horizontal,
          first: tui.PaneLeaf('left'),
          second: tui.PaneLeaf('right'),
          ratio: 1.5,
        ),
        focusedPaneId: 'left',
        paneMinWidth: 1,
        paneMinHeight: 1,
      );

      expect(
        duplicatePanes.validationErrors(),
        contains('pane ids must be unique'),
      );
      expect(
        badRatio.validationErrors(),
        contains('split ratios must be finite within (0, 1)'),
      );
    });
  });
}
