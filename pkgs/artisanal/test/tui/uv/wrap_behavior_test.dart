import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';


void main() {
  group('wrapAnsiPreserving', () {
    test('wraps and preserves SGR pen state across inserted newlines', () {
      const red = '\x1b[31m';
      const reset = UvAnsi.resetStyle;

      final input = '${red}AB CD$reset';
      final expected = '${red}AB$reset\n${red}CD$reset';

      expect(wrapAnsiPreserving(input, 2), expected);
    });

    test(
      'wraps and preserves OSC 8 hyperlink state across inserted newlines',
      () {
        final open = UvAnsi.setHyperlink('https://example.com', '');
        final close = UvAnsi.resetHyperlink();

        final input = '${open}AB CD$close';
        final expected = '${open}AB$close\n${open}CD$close';

        expect(wrapAnsiPreserving(input, 2), expected);
      },
    );

    test(
      'preserves both OSC 8 and SGR with correct reset/reapply ordering',
      () {
        final open = UvAnsi.setHyperlink('https://example.com', '');
        final close = UvAnsi.resetHyperlink();
        const red = '\x1b[31m';
        const reset = UvAnsi.resetStyle;

        final input = '$open${red}AB CD$reset$close';
        final expected = '$open${red}AB$reset$close\n$open${red}CD$reset$close';

        expect(wrapAnsiPreserving(input, 2), expected);
      },
    );

    test('preserves 256-color foreground across line breaks', () {
      // 38;5;123 = indexed 256-color foreground (color 123)
      const fg256 = '\x1b[38;5;123m';
      const reset = UvAnsi.resetStyle;

      final input = '${fg256}AB CD$reset';
      final wrapped = wrapAnsiPreserving(input, 2);

      // Should contain the 256-color code after the line break
      expect(wrapped, contains('38;5;123'));
      // Should have structure: <color>AB<reset>\n<color>CD<reset>
      expect(wrapped, contains('\n'));
      // Count occurrences of the color code - should appear twice (before each segment)
      final matches = RegExp(r'38;5;123').allMatches(wrapped).length;
      expect(
        matches,
        2,
        reason: '256-color should be reapplied after line break',
      );
    });

    test('preserves 256-color background across line breaks', () {
      // 48;5;200 = indexed 256-color background (color 200)
      const bg256 = '\x1b[48;5;200m';
      const reset = UvAnsi.resetStyle;

      final input = '${bg256}AB CD$reset';
      final wrapped = wrapAnsiPreserving(input, 2);

      // Should contain the 256-color code after the line break
      expect(wrapped, contains('48;5;200'));
      final matches = RegExp(r'48;5;200').allMatches(wrapped).length;
      expect(
        matches,
        2,
        reason: '256-color bg should be reapplied after line break',
      );
    });

    test('preserves truecolor foreground across line breaks', () {
      // 38;2;255;128;0 = RGB truecolor foreground (orange)
      const fgRgb = '\x1b[38;2;255;128;0m';
      const reset = UvAnsi.resetStyle;

      final input = '${fgRgb}AB CD$reset';
      final wrapped = wrapAnsiPreserving(input, 2);

      // Should contain the truecolor code after the line break
      expect(wrapped, contains('38;2;255;128;0'));
      final matches = RegExp(r'38;2;255;128;0').allMatches(wrapped).length;
      expect(
        matches,
        2,
        reason: 'truecolor should be reapplied after line break',
      );
    });

    test('preserves truecolor background across line breaks', () {
      // 48;2;0;100;200 = RGB truecolor background (blue-ish)
      const bgRgb = '\x1b[48;2;0;100;200m';
      const reset = UvAnsi.resetStyle;

      final input = '${bgRgb}AB CD$reset';
      final wrapped = wrapAnsiPreserving(input, 2);

      // Should contain the truecolor code after the line break
      expect(wrapped, contains('48;2;0;100;200'));
      final matches = RegExp(r'48;2;0;100;200').allMatches(wrapped).length;
      expect(
        matches,
        2,
        reason: 'truecolor bg should be reapplied after line break',
      );
    });

    test('preserves combined 256-color and truecolor with attributes', () {
      // Bold + 256-color fg + truecolor bg
      const bold = '\x1b[1m';
      const fg256 = '\x1b[38;5;196m'; // bright red
      const bgRgb = '\x1b[48;2;30;30;30m'; // dark gray
      const reset = UvAnsi.resetStyle;

      final input = '$bold$fg256${bgRgb}AB CD$reset';
      final wrapped = wrapAnsiPreserving(input, 2);

      // All styles should be preserved after wrap
      expect(wrapped, contains('38;5;196'), reason: '256-color fg preserved');
      expect(
        wrapped,
        contains('48;2;30;30;30'),
        reason: 'truecolor bg preserved',
      );
      // Bold should appear in the reapplied style
      final boldMatches = RegExp(
        r'\x1b\[[^m]*1[^m]*m',
      ).allMatches(wrapped).length;
      expect(
        boldMatches,
        greaterThanOrEqualTo(2),
        reason: 'bold should be reapplied',
      );
    });

    test('handles existing newlines with extended colors', () {
      const fg256 = '\x1b[38;5;82m';
      const reset = UvAnsi.resetStyle;

      // Input has an existing newline
      final input = '${fg256}Line1\nLine2$reset';
      final wrapped = wrapAnsiPreserving(input, 80); // Wide enough not to wrap

      // Color should be reset before newline and reapplied after
      expect(
        wrapped,
        contains('\x1b[m\n'),
        reason: 'reset before existing newline',
      );
      // Should have color reapplied after newline
      final matches = RegExp(r'38;5;82').allMatches(wrapped).length;
      expect(matches, 2, reason: 'color reapplied after existing newline');
    });
  });
}
