import 'package:artisanal/runtime.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  for (final surface in ['viewport', 'scrollbar', 'diff']) {
    for (final inherited in [false, true]) {
      for (final wrapped in [false, true]) {
        test('$surface shift wheel inherited=$inherited wrapped=$wrapped', () async {
          final tester = WidgetTester(screenWidth: 40, screenHeight: 6);
          addTearDown(tester.dispose);
          final viewport = w.ViewportController();
          final diff = w.GitDiffController();
          const policy = w.ScrollBehavior(wheelStep: 2);
          final lines = List.generate(
            40,
            (index) => '$index ${'long line ' * 12}',
          );
          final child = surface == 'diff'
              ? w.GitDiffViewer(
                  controller: diff,
                  diff:
                      'diff --git a/a b/a\n--- a/a\n+++ b/a\n@@ -0,0 +1,40 @@\n${lines.map((line) => '+$line').join('\n')}',
                  width: 40,
                  height: 6,
                  wrapLines: wrapped,
                  scrollBehavior: inherited ? null : policy,
                )
              : w.Viewport(
                  controller: viewport,
                  content: lines.join('\n'),
                  width: 40,
                  height: 6,
                  softWrap: wrapped,
                  showScrollbar: surface == 'scrollbar',
                  scrollBehavior: inherited ? null : policy,
                );
          await tester.pumpWidget(
            inherited
                ? w.ScrollBehaviorScope(behavior: policy, child: child)
                : child,
          );
          void wheel(tui.MouseButton button, {bool shift = true}) =>
              tester.sendMsg(
                tui.MouseMsg(
                  action: tui.MouseAction.wheel,
                  button: button,
                  shift: shift,
                  x: 2,
                  y: 2,
                ),
              );
          wheel(tui.MouseButton.wheelDown);
          final model = surface == 'diff'
              ? diff.model.viewport
              : viewport.model;
          expect(model.xOffset, wrapped ? 0 : greaterThan(0));
          expect(model.yOffset, wrapped ? 2 : 0);
          wheel(tui.MouseButton.wheelUp);
          expect(
            (surface == 'diff' ? diff.model.viewport : viewport.model).xOffset,
            0,
          );
          expect(
            (surface == 'diff' ? diff.model.viewport : viewport.model).yOffset,
            0,
          );
          wheel(tui.MouseButton.wheelDown, shift: false);
          expect(
            (surface == 'diff' ? diff.model.viewport : viewport.model).yOffset,
            2,
          );
        });
      }
    }
  }

  test('virtual lists retain distinct rapid same-direction pulses', () async {
    final tester = WidgetTester(screenWidth: 40, screenHeight: 6);
    addTearDown(tester.dispose);
    final controller = w.WidgetScrollController();
    var now = DateTime(2026);
    await tester.pumpWidget(
      w.VirtualListView(
        controller: controller,
        width: 40,
        height: 6,
        nowProvider: () => now,
        scrollBehavior: const w.ScrollBehavior(wheelStep: 1),
        children: List.generate(40, (index) => w.Text('Line $index')),
      ),
    );
    for (var pulse = 0; pulse < 3; pulse++) {
      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelDown,
          x: 2,
          y: 2,
        ),
      );
      now = now.add(const Duration(milliseconds: 1));
    }
    expect(controller.offset, 3);
    tester.sendMsg(
      tui.MouseMsg(
        action: tui.MouseAction.wheel,
        button: tui.MouseButton.wheelUp,
        x: 2,
        y: 2,
      ),
    );
    expect(controller.offset, 2);
  });
}
