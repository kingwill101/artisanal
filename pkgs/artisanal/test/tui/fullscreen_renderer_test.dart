import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/terminal/terminal_base.dart';
import 'package:artisanal/src/tui/renderer.dart';
import 'package:test/test.dart';

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
