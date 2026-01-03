import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Style hyperlink + underline variants', () {
    int expectUnderlinedColorSegment(
      String rendered,
      String char, {
      required String underlineStart,
      int startAt = 0,
    }) {
      final charIndex = rendered.indexOf(char, startAt);
      expect(charIndex, greaterThanOrEqualTo(0), reason: 'Missing "$char"');

      final u = rendered.lastIndexOf(underlineStart, charIndex);
      final c58 = rendered.lastIndexOf('\x1b[58', charIndex);
      expect(u, greaterThanOrEqualTo(0), reason: 'Missing underline start');
      expect(
        c58,
        greaterThan(u),
        reason: 'Underline color must be inside span',
      );

      final c59 = rendered.indexOf('\x1b[59m', charIndex);
      final uOff = rendered.indexOf('\x1b[24m', charIndex);
      expect(
        c59,
        greaterThan(charIndex),
        reason: 'Missing underline color reset',
      );
      expect(
        uOff,
        greaterThan(c59),
        reason: 'Underline must end after color reset',
      );

      return charIndex + 1;
    }

    test('hyperlink wraps rendered output with OSC 8 open/close', () {
      final style = Style().hyperlink('https://example.com');
      final rendered = style.render('Hello');

      expect(rendered, contains('\x1b]8;;https://example.com\x1b\\'));
      expect(rendered, contains('\x1b]8;;\x1b\\'));
      expect(Style.stripAnsi(rendered), equals('Hello'));
    });

    test('hyperlink is applied per rendered line', () {
      final style = Style().width(4).hyperlink('https://example.com');
      final rendered = style.render('AAA BBB');
      final lines = rendered.split('\n');

      expect(lines.length, greaterThanOrEqualTo(2));
      for (final line in lines) {
        expect(line, contains('\x1b]8;;https://example.com\x1b\\'));
        expect(line, contains('\x1b]8;;\x1b\\'));
      }
    });

    test('underlineStyle emits expected SGR sequences', () {
      final style = Style().underlineStyle(UnderlineStyle.dotted);
      final rendered = style.render('Hi');

      expect(rendered, contains('\x1b[4:4m'));
      expect(rendered, contains('\x1b[24m'));
      expect(Style.stripAnsi(rendered), equals('Hi'));
    });

    test('underline() defaults to a single underline', () {
      final style = Style().underline();
      final rendered = style.render('Hi');

      expect(rendered, contains('\x1b[4m'));
      expect(rendered, contains('\x1b[24m'));
    });

    test('underlineColor emits SGR 58/59 sequences', () {
      final style = Style().underline().underlineColor(
        const BasicColor('1'),
      ); // Red
      final rendered = style.render('Hi');

      // SGR 58:2:1m (TrueColor) or 58:5:1m (256) or 58:1m (Basic)
      // Our implementation uses sgrColor which handles the profile.
      // For BasicColor('1'), it should be 58:5:1m or similar depending on profile.
      expect(rendered, contains('\x1b[58'));
      expect(rendered, contains('\x1b[59m'));
      expect(
        rendered,
        contains('\x1b[58:'),
      ); // xterm-style underline color params

      // Ordering matters: underline color must be inside the underline span.
      // Rendering is applied per grapheme/rune, so check each character segment.
      var cursor = 0;
      cursor = expectUnderlinedColorSegment(
        rendered,
        'H',
        underlineStart: '\x1b[4m',
        startAt: cursor,
      );
      cursor = expectUnderlinedColorSegment(
        rendered,
        'i',
        underlineStart: '\x1b[4m',
        startAt: cursor,
      );
      expect(Style.stripAnsi(rendered), equals('Hi'));
    });

    test('curly underline color is applied within underline span', () {
      final style = Style()
          .bold()
          .underlineStyle(UnderlineStyle.curly)
          .underlineColor(const BasicColor('1'));
      final rendered = style.render('Hi');
      expect(rendered, contains('\x1b[4:3m'));
      expect(rendered, contains('\x1b[58'));
      expect(rendered, contains('\x1b[59m'));
      expect(rendered, contains('\x1b[24m'));

      var cursor = 0;
      cursor = expectUnderlinedColorSegment(
        rendered,
        'H',
        underlineStart: '\x1b[4:3m',
        startAt: cursor,
      );
      cursor = expectUnderlinedColorSegment(
        rendered,
        'i',
        underlineStart: '\x1b[4:3m',
        startAt: cursor,
      );
      expect(Style.stripAnsi(rendered), equals('Hi'));
    });
  });

  group('Style.styleRunes', () {
    test('styles rune indices with matched/unmatched styles', () {
      final matched = Style().bold();
      final unmatched = Style();

      final rendered = Style.styleRunes('abcd', [1, 2], matched, unmatched);
      expect(Style.stripAnsi(rendered), equals('abcd'));
      expect(rendered, contains('\x1b[1m'));
      expect(rendered, contains('bc'));
    });
  });
}
