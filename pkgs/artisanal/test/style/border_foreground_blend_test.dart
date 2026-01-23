import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Style.borderForegroundBlend', () {
    test('applies per-cell foreground gradient to border', () {
      final style = Style()
        ..colorProfile = ColorProfile.trueColor
        ..hasDarkBackground = true;

      final out = style
          .border(Border.ascii)
          .borderForegroundBlend([Colors.red, Colors.blue])
          .render('X');

      final top = out.split('\n').first;
      final matches = RegExp(
        r'\x1b\[38;2;[0-9]+;[0-9]+;[0-9]+m',
      ).allMatches(top).map((m) => m.group(0)!).toSet();

      expect(matches.length, greaterThan(1), reason: top);
    });

    test('offset rotates the gradient along the perimeter', () {
      final base = Style()
        ..colorProfile = ColorProfile.trueColor
        ..hasDarkBackground = true;

      final a = base
          .copy()
          .border(Border.ascii)
          .borderForegroundBlend([Colors.red, Colors.blue])
          .borderForegroundBlendOffset(0)
          .render('X')
          .split('\n')
          .first;

      final b = base
          .copy()
          .border(Border.ascii)
          .borderForegroundBlend([Colors.red, Colors.blue])
          .borderForegroundBlendOffset(1)
          .render('X')
          .split('\n')
          .first;

      expect(a, isNot(equals(b)));
    });

    test('with fewer than 2 colors, blending is disabled', () {
      final style = Style()
        ..colorProfile = ColorProfile.trueColor
        ..hasDarkBackground = true;

      final out = style
          .border(Border.ascii)
          .borderForegroundBlend([Colors.red])
          .render('X');

      expect(out.contains('\x1b[38;'), isFalse, reason: out);
    });
  });
}
