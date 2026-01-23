import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal/src/style/color.dart' show Colors;
import 'package:test/test.dart';

void main() {
  group('Style.colorWhitespace', () {
    test('background does not apply to padding when disabled', () {
      final s = Style()
          .background(Colors.blue)
          .padding(0, 1, 0, 1)
          .colorWhitespace(false);

      final out = s.render('X');

      // Left padding is a literal space and should not be preceded by a BG code.
      expect(out.startsWith(' '), isTrue, reason: out);
      // The background code should still be applied to the content.
      expect(out.contains('\x1b[48;'), isTrue, reason: out);
    });

    test('background applies to padding when enabled (default)', () {
      final s = Style().background(Colors.blue).padding(0, 1, 0, 1);

      final out = s.render('X');

      // Whitespace should be styled, so the output begins with an escape.
      expect(out.startsWith('\x1b'), isTrue, reason: out);
      expect(out.contains('\x1b[48;'), isTrue, reason: out);
    });

    test('foreground never applies to padding unless inverse is enabled', () {
      final s = Style()
          .foreground(Colors.red)
          .padding(0, 1, 0, 1)
          .colorWhitespace(true);

      final out = s.render('X');

      // Foreground-only styles should not color padding whitespace.
      expect(out.startsWith(' '), isTrue, reason: out);
      expect(out.contains('\x1b[38;'), isTrue, reason: out);
    });

    test(
      'inverse enables whitespace styling even with colorWhitespace=false',
      () {
        final s = Style()
            .foreground(Colors.red)
            .inverse()
            .padding(0, 1, 0, 1)
            .colorWhitespace(false);

        final out = s.render('X');
        expect(out.startsWith('\x1b'), isTrue, reason: out);
      },
    );
  });
}
