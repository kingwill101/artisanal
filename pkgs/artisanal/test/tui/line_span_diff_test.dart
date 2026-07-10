import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/tui/line_span_diff.dart';
import 'package:artisanal/src/tui/terminal_render_inspector.dart';
import 'package:test/test.dart';

TerminalRenderLine _line(String raw, {String statePrefix = ''}) =>
    TerminalRenderLine(raw: raw, statePrefix: statePrefix);

void main() {
  group('lineSpanEdit', () {
    test('rewrites only the changed middle of equal-width lines', () {
      final edit = lineSpanEdit(_line('hello world'), _line('hello WORLD'))!;
      expect(edit.column, 6);
      expect(Ansi.stripAnsi(edit.text), 'WORLD');
    });

    test('keeps a byte-identical tail untouched', () {
      // A rail sits right of the text: the tail (separator + rail) must not
      // be part of the edit when only the text column changed.
      const rail = '│   rail   ';
      final edit = lineSpanEdit(
        _line('typing.  $rail'),
        _line('typing.. $rail'),
      )!;
      expect(edit.column, 7);
      expect(Ansi.stripAnsi(edit.text), '.');
      expect(edit.text, isNot(contains('│')));
      expect(edit.text, isNot(contains('rail')));
    });

    test('restores the ANSI state active at the span start', () {
      final edit = lineSpanEdit(
        _line('\x1b[31mred text here\x1b[0m'),
        _line('\x1b[31mred TEXT here\x1b[0m'),
      )!;
      expect(edit.column, 4);
      // The write must reset the pen, then re-enter the line's active style
      // before the changed word (reset + at least one state sequence).
      expect(
        RegExp(r'\x1b\[[0-9;:]*m').allMatches(edit.text).length,
        greaterThanOrEqualTo(2),
      );
      expect(Ansi.stripAnsi(edit.text), 'TEXT');
    });

    test('keeps the tail beyond a run whose style (not text) changed', () {
      // A selection highlight moving onto a row restyles a run of identical
      // text (dim -> bold), so the byte-identical suffix starts *inside* the
      // restyled run, where the pen states differ. The suffix must shrink to
      // the part after the run's reset — the separator and the tag-wrapped
      // blanks right of it (a parked sixel, in the app that hit this) must
      // stay outside the edit.
      const tail = ' \x1b[90m│\x1b[0m\x1b[38;2;1;2;3m     \x1b[39m';
      final edit = lineSpanEdit(
        _line('  \x1b[2m· Tea and rain\x1b[0m$tail'),
        _line('\x1b[33m▌ \x1b[0m\x1b[1m· Tea and rain\x1b[0m$tail'),
      )!;
      expect(edit.column, 0);
      expect(Ansi.stripAnsi(edit.text), '▌ · Tea and rain');
      expect(edit.text, isNot(contains('│')));
      expect(edit.text, isNot(contains('\x1b[38;2;1;2;3m')));
    });

    test('drops the tail when the pen state at its start changed', () {
      // Identical trailing bytes, but the middle switched the colour they
      // inherit — the tail must be rewritten too.
      final edit = lineSpanEdit(
        _line('\x1b[31mAAA tail'),
        _line('\x1b[34mAAA tail'),
      )!;
      expect(edit.column, 0);
      expect(Ansi.stripAnsi(edit.text), 'AAA tail');
    });

    test('blanks leftover columns when the line shrinks', () {
      final edit = lineSpanEdit(_line('a longer line'), _line('a line'))!;
      expect(edit.column, 3);
      expect(Ansi.stripAnsi(edit.text), 'ine${' ' * 7}');
      // Plain spaces, never erase-to-end-of-line: EL would destroy cells
      // beyond the old line's own extent.
      expect(edit.text, isNot(contains('K')));
    });

    test('does not trim a tail when widths differ', () {
      // Common suffix bytes sit at different columns — everything from the
      // first difference must be rewritten.
      final edit = lineSpanEdit(_line('ab tail'), _line('abXY tail'))!;
      expect(edit.column, 2);
      expect(Ansi.stripAnsi(edit.text), 'XY tail');
    });

    test('returns null for a zero-width-only difference', () {
      // A trailing zero-width tag changed; no visible cell did. A correct
      // span renderer has nothing to write.
      const blanks = '          ';
      expect(
        lineSpanEdit(
          _line('text │$blanks\x1b[38;2;1;2;3m\x1b[39m'),
          _line('text │$blanks'),
        ),
        isNull,
      );
    });

    test('rewrites wrapped cells when a wrapping zero-width tag changes', () {
      // The tag wraps the blanks: removing it must rewrite the blanks (this
      // is how an app erases graphics parked on those cells).
      const blanks = '          ';
      final edit = lineSpanEdit(
        _line('text │\x1b[38;2;1;2;3m$blanks\x1b[39m'),
        _line('text │$blanks'),
      )!;
      expect(edit.column, 6);
      expect(Ansi.stripAnsi(edit.text), blanks);
    });

    test('rewrites the whole row when the inherited state changed', () {
      final edit = lineSpanEdit(
        _line('Body', statePrefix: '\x1b[31m'),
        _line('Body', statePrefix: '\x1b[34m'),
      )!;
      expect(edit.column, 0);
      expect(edit.text, contains('\x1b[34mBody'));
    });

    test('handles wide characters at the span boundary', () {
      final edit = lineSpanEdit(_line('日本語 abc'), _line('日本語 abd'))!;
      // Three double-width graphemes + space + 'ab' = 9 columns before 'c'.
      expect(edit.column, 9);
      expect(Ansi.stripAnsi(edit.text), 'd');
    });
  });
}
