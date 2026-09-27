import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/selection.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  for (final (variable, height) in [
    (false, 1),
    (true, 1),
    (false, 3),
    (true, 3),
  ]) {
    for (final offset in [0, 15]) {
      for (final callbacks in [false, true]) {
        test(
          'virtual selection variable=$variable height=$height offset=$offset callbacks=$callbacks',
          () async {
            final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
            addTearDown(tester.dispose);
            final scroll = WidgetScrollController();
            final selection = SelectionController();
            final completed = <String>[];
            await tester.pumpWidget(
              SelectionArea(
                controller: selection,
                onSelectionEnd: callbacks ? completed.add : null,
                child: VirtualListView.builder(
                  controller: scroll,
                  variableHeight: variable,
                  itemExtent: height,
                  estimatedItemExtent: height,
                  itemCount: 50,
                  itemBuilder: (context, index) => SelectableText(
                    List.generate(
                      height,
                      (row) => 'Row ${index * height + row} alpha beta gamma',
                    ).join('\n'),
                  ),
                ),
              ),
            );
            scroll.jumpTo(offset);
            tester.pump();
            tester.mouseDown(0, 3);
            tester.sendMsg(
              tui.MouseMsg(
                action: tui.MouseAction.motion,
                button: tui.MouseButton.left,
                x: 12,
                y: 4,
              ),
            );
            final expected =
                'Row ${offset + 3} alpha beta gamma\n'
                '${'Row ${offset + 4} alpha beta gamma'.substring(0, 12)}';
            expect(selection.selecting, isTrue);
            expect(selection.getSelectedRegisteredText(), expected);
            expect(completed, isEmpty);
            tester.mouseUp(12, 4);
            expect(selection.selecting, isFalse);
            expect(selection.getSelectedRegisteredText(), expected);
            expect(completed, callbacks ? [expected] : isEmpty);
          },
        );
      }
    }
  }
}
