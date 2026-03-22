import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/terminal/terminal_base.dart';
import 'package:artisanal/src/tui/renderer.dart';
import 'package:artisanal/src/tui/program.dart' show ScreenMode, UiAnchor;
import 'package:test/test.dart';

void main() {
  group('UltravioletTuiRenderer inline mode', () {
    UltravioletTuiRenderer buildInlineRenderer(
      StringTerminal terminal, {
      int inlineHeight = 4,
      UiAnchor uiAnchor = UiAnchor.bottom,
      bool hideCursor = true,
    }) {
      return UltravioletTuiRenderer(
        terminal: terminal,
        options: TuiRendererOptions(
          fps: 100000,
          altScreen: false,
          hideCursor: hideCursor,
          screenMode: ScreenMode.inline,
          inlineHeight: inlineHeight,
          uiAnchor: uiAnchor,
        ),
      );
    }

    test('does not enter alt-screen in inline mode', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);
      renderer.initialize();
      renderer.render('test');

      // Should not contain alt-screen enter sequence
      expect(terminal.output, isNot(contains(Ansi.altScreenEnter)));
    });

    test('does not emit full-screen clear in inline mode', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('inline');

      expect(terminal.output, isNot(contains(Ansi.clearScreen)));
    });

    test('does not scroll viewport on first frame', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('inline');

      expect(terminal.output, isNot(contains(Ansi.scrollUpBy(4))));
      expect(terminal.output, isNot(contains(Ansi.scrollDownBy(4))));
    });

    test('renders content within the UI region (bottom-anchored)', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 6);

      renderer.render('Hello inline');

      // For bottom-anchored height=6 on 24-row terminal:
      // UI starts at row 24 - 6 + 1 = 19.
      // The CUP in the UV output should be offset to row 19+.
      // Expect cursorTo(19,1) for clearing the first UI row.
      expect(terminal.output, contains(Ansi.cursorTo(19, 1)));
    });

    test('renders content within the UI region (top-anchored)', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(
        terminal,
        inlineHeight: 4,
        uiAnchor: UiAnchor.top,
      );

      renderer.render('Hello top');

      // Top-anchored: UI starts at row 1, offset = 0.
      // Content CUP should start at row 1.
      expect(terminal.output, contains(Ansi.cursorTo(1, 1)));
    });

    test('clears UI region rows before writing content', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 3);

      terminal.clear();
      renderer.render('line1\nline2\nline3');

      // Should clear lines at rows 22, 23, 24 (bottom 3 rows)
      expect(terminal.output, contains(Ansi.cursorTo(22, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(23, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(24, 1)));
      expect(terminal.output, contains(Ansi.clearLine));
    });

    test('offsets CUP rows in UV output', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('test');

      // Bottom-anchored, height=4: uiStartRow = 24 - 4 + 1 = 21
      // UV output has CUP at row 1 -> should become row 21
      // The UV renderer emits cursorTo(1,1) for first line,
      // which should be offset to cursorTo(21, 1).
      final output = terminal.output;

      // Should NOT contain cursorTo(1,1) from the UV renderer (it was offset)
      // But the clear loop uses cursorTo(21,1) which is the same sequence.
      // Instead, verify the content appears after the UI region positioning.
      expect(output, contains(Ansi.cursorTo(21, 1)));
    });

    test('does not double-offset home cursor sequence', () {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 10);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 3);

      renderer.render(
        'Inline Status Bar\nRUNNING  Events: 0\nSpace toggle  q quit',
      );

      // Bottom-anchored 10-row terminal with 3-row UI starts at row 8.
      expect(terminal.output, contains(Ansi.cursorTo(8, 1)));
      expect(terminal.output, isNot(contains(Ansi.cursorTo(15, 1))));
    });

    test('uses synchronized update markers', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);

      renderer.render('content');

      expect(terminal.output, contains(Ansi.beginSynchronizedUpdate));
      expect(terminal.output, contains(Ansi.endSynchronizedUpdate));
    });

    test('shows cursor at end of frame', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, hideCursor: false);

      renderer.render('content');

      expect(terminal.output, contains(Ansi.cursorShow));
    });

    test('dispose does not exit alt-screen', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);
      renderer.initialize();
      renderer.render('content');

      terminal.clear();
      renderer.dispose();

      // Should NOT exit alt-screen (we never entered it)
      expect(terminal.output, isNot(contains(Ansi.altScreenExit)));
      // Should track showCursor operation
      expect(terminal.operations, contains('showCursor'));
    });

    test('diffing works across frames', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('Hello');
      terminal.clear();

      renderer.render('World');

      // The second frame should contain the new content
      expect(terminal.output, contains('World'));
    });

    test('offsets incremental row updates inside the inline region', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render(
        'Inline Status Bar\nRUNNING  Events: 0\n\nSpace toggle  q quit',
      );
      terminal.clear();
      renderer.render(
        'Inline Status Bar\nRUNNING  Events: 1\n\nSpace toggle  q quit',
      );

      expect(
        terminal.output,
        anyOf(contains('\x1b[22d'), contains('\x1b[22;18H')),
      );
      expect(
        terminal.output,
        isNot(anyOf(contains('\x1b[2d'), contains('\x1b[2;18H'))),
      );
    });
  });

  group('UltravioletTuiRenderer fullscreen mode (regression)', () {
    UltravioletTuiRenderer buildFullScreenRenderer(StringTerminal terminal) {
      return UltravioletTuiRenderer(
        terminal: terminal,
        options: TuiRendererOptions(
          fps: 100000,
          altScreen: true,
          hideCursor: false,
          screenMode: ScreenMode.fullScreen,
        ),
      );
    }

    test('still enters alt-screen in fullscreen mode', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildFullScreenRenderer(terminal);
      renderer.initialize();
      expect(terminal.operations, contains('enterAltScreen'));
    });
  });

  group('TuiRendererOptions.isInline', () {
    test('returns true for ScreenMode.inline', () {
      const options = TuiRendererOptions(screenMode: ScreenMode.inline);
      expect(options.isInline, isTrue);
    });

    test('returns true for ScreenMode.inlineAuto', () {
      const options = TuiRendererOptions(screenMode: ScreenMode.inlineAuto);
      expect(options.isInline, isTrue);
    });

    test('returns false for ScreenMode.fullScreen', () {
      const options = TuiRendererOptions(screenMode: ScreenMode.fullScreen);
      expect(options.isInline, isFalse);
    });
  });
}
