import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/terminal/terminal_base.dart';
import 'package:artisanal/src/tui/renderer.dart';
import 'package:test/test.dart';

/// A [StringTerminal] whose reported size can change between renders,
/// simulating a live console resize.
class _ResizableStringTerminal extends StringTerminal {
  int _width = 80;
  int _height = 24;

  @override
  int get width => _width;

  @override
  int get height => _height;

  void resize(int width, int height) {
    _width = width;
    _height = height;
  }
}

void main() {
  group('FullScreenTuiRenderer', () {
    FullScreenTuiRenderer buildRenderer(StringTerminal terminal) {
      return FullScreenTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(
          fps: 100000,
          altScreen: true,
          hideCursor: false,
        ),
      );
    }

    test('updates only changed lines after the first frame', () {
      final terminal = StringTerminal();
      final renderer = buildRenderer(terminal);

      renderer.render('alpha\nbeta');
      terminal.clear();

      renderer.render('alpha\nBETA');

      expect(terminal.output, contains(Ansi.cursorTo(2, 1)));
      expect(terminal.output, contains('BETA'));
      expect(terminal.output, isNot(contains(Ansi.cursorTo(1, 1))));
      expect(terminal.output, isNot(contains('alpha')));
    });

    test('re-renders lines whose inherited ANSI state changed', () {
      final terminal = StringTerminal();
      final renderer = buildRenderer(terminal);

      renderer.render('\x1b[31mTitle\nBody');
      terminal.clear();

      renderer.render('\x1b[34mTitle\nBody');

      expect(terminal.output, contains(Ansi.cursorTo(1, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(2, 1)));
      expect(terminal.output, contains('\x1b[34mBody'));
    });

    test('a text change left of a rail never touches the rail columns', () {
      // Row layout mimics a chat column, a separator, and a blank rail that
      // a sixel image is painted over: when only the chat text changes, the
      // separator and rail cells must not be rewritten (rewriting them would
      // destroy the graphics), and no line may be erased.
      const rail = '\x1b[38;2;1;2;3m          \x1b[39m';
      final terminal = StringTerminal();
      final renderer = buildRenderer(terminal);

      renderer.render('one   │$rail\ntwo   │$rail');
      terminal.clear();

      renderer.render('one!  │$rail\ntwo   │$rail');

      expect(terminal.output, contains(Ansi.cursorTo(1, 4)));
      expect(terminal.output, contains('!'));
      expect(terminal.output, isNot(contains('│')));
      expect(terminal.output, isNot(contains('38;2;1;2;3')));
      expect(terminal.output, isNot(contains(Ansi.clearLine)));
      expect(terminal.output, isNot(contains(Ansi.cursorTo(2, 1))));
    });

    test('a size change clears and repaints in full, never diffs', () {
      // A resize reflows the terminal's existing content, so diffing against
      // the previous frame would leave reflowed fragments inside every
      // skipped span. Even an unchanged view must repaint after a resize.
      final terminal = _ResizableStringTerminal();
      final renderer = buildRenderer(terminal);

      renderer.render('alpha\nbeta');
      terminal.clear();
      terminal.resize(100, 30);

      renderer.render('alpha\nbeta');

      expect(terminal.output, contains('alpha'));
      expect(terminal.output, contains('beta'));
    });

    test('a frame taller than the terminal is clipped and never becomes a '
        'diff baseline', () {
      // Mid-resize the app can briefly render a frame built for the old,
      // larger size. Writing its extra rows would scroll the screen and
      // corrupt every absolute row address; caching it as the diff baseline
      // would leave the corruption permanent. It must be drawn clipped, and
      // the first frame that fits must repaint in full.
      final terminal = StringTerminal(terminalHeight: 3);
      final renderer = buildRenderer(terminal);

      renderer.render('row0\nrow1\nrow2\nrow3\nrow4\nrow5');
      expect(terminal.output, contains('row2'));
      expect(terminal.output, isNot(contains('row3')));

      terminal.clear();
      renderer.render('row0\nrowX\nrow2');

      // A span diff would skip the unchanged rows; the invalid baseline must
      // force a full repaint instead.
      expect(terminal.output, contains('row0'));
      expect(terminal.output, contains('rowX'));
      expect(terminal.output, contains('row2'));
    });

    test('disables auto-wrap for the session and restores it on dispose', () {
      // With auto-wrap on, an over-wide row (transient mid-resize state)
      // wraps and scrolls the screen; clipped at the margin it is harmless.
      final terminal = StringTerminal();
      final renderer = buildRenderer(terminal);

      renderer.render('x');
      expect(terminal.output, contains('\x1b[?7l'));

      renderer.dispose();
      expect(terminal.output, contains('\x1b[?7h'));
    });

    test('wraps diff writes in synchronized-update guards', () {
      final terminal = StringTerminal();
      final renderer = buildRenderer(terminal);

      renderer.render('alpha\nbeta');
      terminal.clear();

      renderer.render('alpha\nBETA');

      final output = terminal.output;
      final begin = output.indexOf(Ansi.beginSynchronizedUpdate);
      final write = output.indexOf(Ansi.cursorTo(2, 1));
      final end = output.indexOf(Ansi.endSynchronizedUpdate);
      expect(begin, isNot(-1));
      expect(end, isNot(-1));
      expect(begin < write && write < end, isTrue);
    });

    test('clears lines removed by a shorter frame', () {
      final terminal = StringTerminal();
      final renderer = buildRenderer(terminal);

      renderer.render('one\ntwo\nthree');
      terminal.clear();

      renderer.render('one');

      expect(terminal.output, contains(Ansi.cursorTo(2, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(3, 1)));
      expect(
        RegExp(
          '${RegExp.escape(Ansi.cursorTo(2, 1))}${RegExp.escape(Ansi.clearLine)}',
        ).hasMatch(terminal.output),
        isTrue,
      );
      expect(
        RegExp(
          '${RegExp.escape(Ansi.cursorTo(3, 1))}${RegExp.escape(Ansi.clearLine)}',
        ).hasMatch(terminal.output),
        isTrue,
      );
    });
  });
}
