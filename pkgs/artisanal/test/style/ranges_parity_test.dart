import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('styleRanges (lipgloss v2 parity)', () {
    test('empty ranges returns input unchanged', () {
      expect(styleRanges('hello world', const []), equals('hello world'));
    });

    test('single range in middle styles substring', () {
      final input = 'hello world';
      final out = styleRanges(input, [StyleRange(6, 11, Style().bold())]);

      expect(Style.stripAnsi(out), equals(input));
      expect(out, contains('world'));
      expect(out, contains('\x1b[1m'));
    });

    test('multiple ranges preserve gaps', () {
      final input = 'hello world';
      final out = styleRanges(input, [
        StyleRange(0, 5, Style().bold()),
        StyleRange(6, 11, Style().italic()),
      ]);

      expect(Style.stripAnsi(out), equals(input));
      expect(out, contains('\x1b[1m'));
      expect(out, contains('\x1b[3m'));
    });

    test(
      'overlapping with existing ANSI preserves original outside the range',
      () {
        final input = 'hello \x1b[32mworld\x1b[m';
        final out = styleRanges(input, [StyleRange(0, 5, Style().bold())]);

        expect(Style.stripAnsi(out), equals('hello world'));
        expect(out, contains('\x1b[32mworld'));
      },
    );

    test('wide characters are indexed by cells', () {
      final input = 'Hello 你好 世界';
      final out = styleRanges(input, [
        StyleRange(0, 5, Style().bold()), // Hello
        StyleRange(7, 10, Style().italic()), // 你好
        StyleRange(11, 50, Style().bold()), // 世界 (end overflow is ok)
      ]);

      expect(Style.stripAnsi(out), equals(input));
      expect(out, contains('你好'));
      expect(out, contains('世界'));
    });

    test(
      'reapplies original pen state after styled segment resets (ansi + emoji case)',
      () {
        // Ported from lipgloss v2 ranges_test.go "ansi and emoji" case.
        const input = '\x1b[90m\ue615\x1b[39m \x1b[3mDownloads';

        final out = styleRanges(
          input,
          [StyleRange(2, 5, Style().foreground(const AnsiColor(2)))], // "Dow"
        );

        expect(Style.stripAnsi(out), equals('\ue615 Downloads'));

        // The output should still contain the original italic sequence after the
        // highlighted segment, otherwise the renderer will drop italic for the
        // remainder.
        expect(out, contains('\x1b[3m'));
        // The dim glyph should remain dimmed.
        expect(out, contains('\x1b[90m'));
      },
    );
  });
}
