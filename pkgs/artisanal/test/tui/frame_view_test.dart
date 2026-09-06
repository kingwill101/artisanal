import 'package:artisanal/tui.dart';
import 'package:test/test.dart';
import 'package:ultraviolet/core.dart';

void main() {
  group('FrameView', () {
    test('paints directly into the Ultraviolet screen buffer', () async {
      final terminal = StringTerminal(terminalWidth: 8, terminalHeight: 3);
      final renderer = UltravioletTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: false),
      );

      Rectangle? paintedArea;
      renderer.render(
        FrameView(
          paint: (frame) {
            paintedArea = frame.area;
            frame.screen.setCell(1, 1, Cell(content: 'X'));
          },
        ),
      );
      await renderer.flush();

      expect(paintedArea, rect(0, 0, 8, 3));
      expect(renderer.screenBuffer!.cellAt(1, 1)?.content, 'X');
      renderer.dispose();
    });

    test('clears cells not repainted by the next frame', () async {
      final terminal = StringTerminal(terminalWidth: 4, terminalHeight: 2);
      final renderer = UltravioletTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: false),
      );

      renderer.render(
        FrameView(
          paint: (frame) {
            frame.screen.setCell(0, 0, Cell(content: 'A'));
          },
        ),
      );
      renderer.render(FrameView(paint: (_) {}));
      await renderer.flush();

      expect(renderer.screenBuffer!.cellAt(0, 0)?.content, ' ');
      renderer.dispose();
    });

    test('uses fallback content with non-structured renderers', () {
      final terminal = StringTerminal(terminalWidth: 8, terminalHeight: 3);
      final renderer = SimpleTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: false),
      );

      renderer.render(FrameView(content: 'fallback', paint: (_) {}));

      expect(terminal.output, contains('fallback'));
      renderer.dispose();
    });
  });
}
