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

      // Should not contain alt-screen enter sequence
      expect(terminal.output, isNot(contains(Ansi.altScreenEnter)));
    });

    test('saves cursor on initialization', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);
      renderer.initialize();

      // Should contain DEC cursor save (ESC 7)
      expect(terminal.output, contains(Ansi.cursorSaveDec));
    });

    test('renders content within the UI region', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 6);

      renderer.render('Hello from inline mode');

      // Should position cursor at the UI region start
      // For bottom-anchored with height=6 on 24-row terminal:
      // UI starts at row 24 - 6 + 1 = 19
      expect(terminal.output, contains(Ansi.cursorTo(19, 1)));
    });

    test('clears only UI region rows', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 3);

      terminal.clear();
      renderer.render('line1\nline2\nline3');

      // Should clear lines at rows 22, 23, 24 (bottom 3 rows)
      expect(terminal.output, contains(Ansi.cursorTo(22, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(23, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(24, 1)));
      // Each row should have clear-line
      expect(terminal.output, contains(Ansi.clearLine));
    });

    test('sets scroll region for bottom-anchored UI', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('content');

      // DECSTBM should be set to rows 1..20 (24-4=20)
      expect(terminal.output, contains('\x1b[1;20r'));
    });

    test('sets scroll region for top-anchored UI', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(
        terminal,
        inlineHeight: 4,
        uiAnchor: UiAnchor.top,
      );

      renderer.render('content');

      // DECSTBM should be set to rows 5..24 (UI is rows 1-4)
      expect(terminal.output, contains('\x1b[5;24r'));
    });

    test('resets scroll region after render', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('content');

      // DECSTBM reset should appear after the content
      expect(terminal.output, contains('\x1b[r'));
    });

    test('restores cursor after render', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);

      renderer.render('content');

      // DEC cursor restore should appear in output
      expect(terminal.output, contains(Ansi.cursorRestoreDec));
    });

    test('shows cursor after render when hideCursor is false', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, hideCursor: false);

      renderer.render('content');

      expect(terminal.output, contains(Ansi.cursorShow));
    });

    test('uses synchronized update markers', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);

      renderer.render('content');

      expect(terminal.output, contains(Ansi.beginSynchronizedUpdate));
      expect(terminal.output, contains(Ansi.endSynchronizedUpdate));
    });

    test('dispose restores cursor and does not exit alt-screen', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);
      renderer.initialize();
      renderer.render('content');

      terminal.clear();
      renderer.dispose();

      // Should restore cursor (cursor was saved on init)
      expect(terminal.output, contains(Ansi.cursorRestoreDec));
      // Should track showCursor operation (StringTerminal doesn't write
      // ANSI for showCursor — it records operations separately)
      expect(terminal.operations, contains('showCursor'));
      // Should NOT exit alt-screen (we never entered it)
      expect(terminal.output, isNot(contains(Ansi.altScreenExit)));
    });

    test('scroll region is reset at end of each render', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('content');

      // DECSTBM reset should appear after the content
      expect(terminal.output, contains('\x1b[r'));
      // DECSTBM set should also appear before content
      expect(terminal.output, contains('\x1b[1;20r'));
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
      // StringTerminal tracks enterAltScreen as an operation, not ANSI
      expect(terminal.operations, contains('enterAltScreen'));
    });

    test('still clears screen in fullscreen mode', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildFullScreenRenderer(terminal);
      renderer.initialize();
      // StringTerminal tracks clearScreen as an operation, not ANSI
      expect(terminal.operations, contains('clearScreen'));
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
