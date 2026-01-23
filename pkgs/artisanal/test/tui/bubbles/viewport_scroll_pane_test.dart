import 'package:artisanal/src/tui/bubbles/viewport.dart';
import 'package:artisanal/src/tui/bubbles/viewport_scroll_pane.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('ViewportScrollPane', () {
    test('renders a 1-col scrollbar when content overflows', () {
      final viewport = ViewportModel(
        width: 5,
        height: 3,
      ).setContent(List.generate(10, (i) => 'l$i').join('\n'));
      final pane = ViewportScrollPane(viewport: viewport);

      final out = pane.view();
      final lines = out.split('\n');
      expect(lines, hasLength(3));
      // content(5) + sep(1) + bar(1) = 7 columns, but ANSI may exist; check suffix.
      expect(lines[0].endsWith('│') || lines[0].endsWith('█'), isTrue);
    });

    test('dragging the scrollbar updates viewport yOffset', () {
      final viewport = ViewportModel(
        width: 5,
        height: 3,
      ).setContent(List.generate(10, (i) => 'l$i').join('\n'));
      final pane = ViewportScrollPane(viewport: viewport);

      // Prime internal hit-test geometry.
      pane.view();

      // Click on scrollbar column (x = viewport.width + separator.length).
      pane.update(
        const MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 6,
          y: 1,
        ),
      );

      // With height=3, y=1 should land around the middle: offset ~= 4.
      expect(pane.viewport.yOffset, 4);

      // Drag to bottom.
      pane.update(
        const MouseMsg(
          action: MouseAction.motion,
          button: MouseButton.left,
          x: 6,
          y: 2,
        ),
      );

      expect(pane.viewport.yOffset, 7);
    });
  });
}
