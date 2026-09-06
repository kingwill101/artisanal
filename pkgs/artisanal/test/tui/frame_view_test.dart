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

    test('applies insets without escaping a small area', () {
      expect(
        const FrameArea(
          4,
          6,
          10,
          8,
        ).inset(left: 2, top: 1, right: 3, bottom: 2),
        const FrameArea(6, 7, 5, 5),
      );
      expect(
        const FrameArea(4, 6, 2, 1).inset(left: 5, top: 5),
        const FrameArea(6, 7, 0, 0),
      );
    });

    test('centers requested dimensions and clamps them to the area', () {
      const area = FrameArea(10, 20, 11, 7);

      expect(area.centered(width: 5, height: 3), const FrameArea(13, 22, 5, 3));
      expect(area.centered(width: 50, height: 50), area);
    });

    test('rejects negative inset and centered dimensions', () {
      const area = FrameArea(0, 0, 10, 10);

      expect(() => area.inset(left: -1), throwsArgumentError);
      expect(() => area.centered(width: -1, height: 1), throwsArgumentError);
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

    test(
      'positions a Style border when content dimensions include its insets',
      () async {
        final terminal = StringTerminal(terminalWidth: 5, terminalHeight: 4);
        final renderer = UltravioletTuiRenderer(
          terminal: terminal,
          options: const TuiRendererOptions(altScreen: false),
        );
        final bordered = Style()
            .border(Border.rounded)
            .width(3)
            .height(4)
            .render('x\ny');

        renderer.render(
          FrameView(
            paint: (frame) {
              frame.write(bordered, target: const FrameArea(0, 0, 5, 4));
            },
          ),
        );
        await renderer.flush();

        expect(renderer.screenBuffer!.cellAt(0, 0)?.content, '╭');
        expect(renderer.screenBuffer!.cellAt(4, 0)?.content, '╮');
        expect(renderer.screenBuffer!.cellAt(0, 3)?.content, '╰');
        expect(renderer.screenBuffer!.cellAt(4, 3)?.content, '╯');
        renderer.dispose();
      },
    );

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
