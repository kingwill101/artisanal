import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('FrameArea', () {
    test('intersects overlapping and disjoint regions', () {
      const area = FrameArea(2, 2, 5, 4);

      expect(
        area.intersect(const FrameArea(4, 1, 5, 3)),
        const FrameArea(4, 2, 3, 2),
      );
      expect(area.intersect(const FrameArea(20, 20, 1, 1)).isEmpty, isTrue);
    });
  });

  group('FrameView', () {
    test('paints directly into the Ultraviolet screen buffer', () async {
      final terminal = StringTerminal(terminalWidth: 8, terminalHeight: 3);
      final renderer = UltravioletTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: false),
      );

      FrameArea? paintedArea;
      renderer.render(
        FrameView(
          paint: (frame) {
            paintedArea = frame.area;
            frame.write(
              Style().foreground(Colors.green).render('X'),
              target: const FrameArea(1, 1, 1, 1),
            );
          },
        ),
      );
      await renderer.flush();

      expect(paintedArea, const FrameArea(0, 0, 8, 3));
      expect(renderer.screenBuffer!.cellAt(1, 1)?.content, 'X');
      expect(renderer.screenBuffer!.cellAt(1, 1)?.style.isZero, isFalse);
      renderer.dispose();
    });

    test('clips positioned content to its target area', () async {
      final terminal = StringTerminal(terminalWidth: 5, terminalHeight: 2);
      final renderer = UltravioletTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: false),
      );

      renderer.render(
        FrameView(
          paint: (frame) {
            frame.write('abcdef', target: const FrameArea(2, 0, 2, 1));
          },
        ),
      );
      await renderer.flush();

      expect(renderer.screenBuffer!.cellAt(2, 0)?.content, 'a');
      expect(renderer.screenBuffer!.cellAt(3, 0)?.content, 'b');
      expect(renderer.screenBuffer!.cellAt(4, 0)?.content, isNot('c'));
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
            frame.write('A', target: const FrameArea(0, 0, 1, 1));
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
