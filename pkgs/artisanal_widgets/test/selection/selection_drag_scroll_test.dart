import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/selection.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  test(
    'stationary edge drag renders through the runtime without pumping',
    () async {
      final tester = WidgetTester(
        screenWidth: 40,
        screenHeight: 6,
        enableRenderer: true,
      );
      addTearDown(tester.dispose);
      final scroll = WidgetScrollController();
      final selection = SelectionController();
      await tester.pumpWidget(
        SizedBox(
          height: 6,
          child: SingleChildScrollView(
            controller: scroll,
            child: SelectableText(
              List.generate(
                80,
                (index) => 'Line $index selectable text',
              ).join('\n'),
              controller: selection,
            ),
          ),
        ),
      );
      tester.mouseDown(1, 1);
      tester.mouseMove(8, 5);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      tester.clearRendererOutput();
      final before = scroll.offset;
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(scroll.offset, greaterThan(before));
      expect(tester.rendererOutput, isNotEmpty);
      tester.mouseUp(8, 5);
      final stopped = scroll.offset;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(scroll.offset, stopped);
    },
  );

  for (final virtual in [false, true]) {
    for (final shared in [false, true]) {
      test(
        'drag scrolls without explicit binding (virtual=$virtual, shared=$shared)',
        () async {
          final tester = WidgetTester(screenWidth: 40, screenHeight: 6);
          addTearDown(tester.dispose);
          final scroll = WidgetScrollController();
          final selection = SelectionController();
          final lines = List.generate(
            80,
            (index) => 'Line $index selectable text',
          );
          final text = SelectableText(lines.join('\n'), controller: selection);
          final viewport = virtual
              ? VirtualListView(
                  controller: scroll,
                  variableHeight: true,
                  children: [text],
                )
              : SingleChildScrollView(controller: scroll, child: text);
          await tester.pumpWidget(
            SizedBox(
              height: 6,
              child: shared
                  ? SelectionArea(controller: selection, child: viewport)
                  : viewport,
            ),
          );
          tester.mouseDown(1, 1);
          tester.mouseMove(8, 2);
          final anchor = selection.selectionStart;
          tester.sendMsg(
            tui.MouseMsg(
              action: tui.MouseAction.wheel,
              button: tui.MouseButton.wheelDown,
              x: 8,
              y: 2,
            ),
          );
          tester.pump();
          expect(scroll.offset, greaterThan(0));
          expect(selection.selecting, isTrue);
          expect(selection.selectionStart, anchor);
          expect(selection.selectionEnd!.y, greaterThan(2));

          tester.mouseMove(8, 5);
          final beforeEdge = scroll.offset;
          await Future<void>.delayed(const Duration(milliseconds: 180));
          tester.pump();
          expect(scroll.offset, greaterThan(beforeEdge));
          final afterEdge = scroll.offset;
          await Future<void>.delayed(const Duration(milliseconds: 120));
          tester.pump();
          expect(scroll.offset, greaterThan(afterEdge));
          expect(selection.getSelectedText(lines), contains('Line 6'));

          tester.mouseMove(8, 0);
          final beforeUp = scroll.offset;
          await Future<void>.delayed(const Duration(milliseconds: 120));
          tester.pump();
          expect(scroll.offset, lessThan(beforeUp));
          tester.mouseUp(8, 0);
          final stopped = scroll.offset;
          await Future<void>.delayed(const Duration(milliseconds: 120));
          tester.pump();
          expect(scroll.offset, stopped);
          expect(selection.selecting, isFalse);
        },
      );
    }
  }
}
