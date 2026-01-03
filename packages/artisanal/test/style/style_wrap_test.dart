import 'package:artisanal/src/style/style.dart';
import 'package:test/test.dart';

void main() {
  group('Style.wrapAnsi', () {
    test('preserves SGR state across wrapped lines when enabled', () {
      final style = Style().width(4).wrapAnsi(true);

      const blue = '\x1b[34m';
      const reset = '\x1b[0m';
      final input = '${blue}AAA BBB$reset';

      final rendered = style.render(input);
      final lines = rendered.split('\n');

      expect(lines.length, greaterThanOrEqualTo(2));
      expect(lines[0], contains(blue));
      expect(lines[1], contains(blue));
    });

    test('does not preserve SGR state across wrapped lines by default', () {
      final style = Style().width(4);

      const blue = '\x1b[34m';
      const reset = '\x1b[0m';
      final input = '${blue}AAA BBB$reset';

      final rendered = style.render(input);
      final lines = rendered.split('\n');

      expect(lines.length, greaterThanOrEqualTo(2));
      expect(lines[0], contains(blue));
      expect(lines[1], isNot(contains(blue)));
    });

    test(
      'preserves OSC8 hyperlink state across wrapped lines when enabled',
      () {
        final style = Style().width(4).wrapAnsi(true);

        const linkStart = '\x1b]8;;https://example.com\x07';
        const linkEnd = '\x1b]8;;\x07';
        final input = '${linkStart}AAA BBB$linkEnd';

        final rendered = style.render(input);
        final lines = rendered.split('\n');

        expect(lines.length, greaterThanOrEqualTo(2));
        expect(lines[0], contains(linkStart));
        expect(lines[1], contains(linkStart));
      },
    );

    test(
      'does not preserve OSC8 hyperlink state across wrapped lines by default',
      () {
        final style = Style().width(4);

        const linkStart = '\x1b]8;;https://example.com\x07';
        const linkEnd = '\x1b]8;;\x07';
        final input = '${linkStart}AAA BBB$linkEnd';

        final rendered = style.render(input);
        final lines = rendered.split('\n');

        expect(lines.length, greaterThanOrEqualTo(2));
        // Legacy wrapping is not OSC-aware: it won't re-open hyperlink state on
        // wrapped lines. The hyperlink opener remains in the first line only.
        expect(lines[0], contains(linkStart));
        expect(lines[1], isNot(contains(linkStart)));
      },
    );
  });
}
