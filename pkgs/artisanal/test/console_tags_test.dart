import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  group('Console Tags', () {
    test('basic foreground color', () {
      final style = Style();
      final output = style.render('<fg=red>Hello</>');
      expect(output, contains('\x1B[31mHello\x1B[0m'));
    });

    test('basic background color', () {
      final style = Style();
      final output = style.render('<bg=blue>World</>');
      expect(output, contains('\x1B[44mWorld\x1B[0m'));
    });

    test('options', () {
      final style = Style();
      final output = style.render('<options=bold,underline>Styled</>');
      expect(output, contains('\x1B[1;4mStyled\x1B[0m'));
    });

    test('hex colors', () {
      final style = Style()..colorProfile = ColorProfile.trueColor;
      final output = style.render('<fg=#ff5500>Hex</>');
      expect(output, contains('\x1B[38;2;255;85;0mHex\x1B[0m'));
    });

    test('ansi 256 colors', () {
      final style = Style()..colorProfile = ColorProfile.ansi256;
      final output = style.render('<fg=196>Red</>');
      expect(output, contains('\x1B[38;5;196mRed\x1B[0m'));
    });

    test('more options', () {
      final style = Style();
      final output = style.render(
        '<options=italic,strikethrough,dim>Styled</>',
      );
      expect(output, contains('\x1B[3;9;2mStyled\x1B[0m'));
    });

    test('nested tags', () {
      final style = Style();
      final output = style.render(
        '<fg=green>Green <fg=red>Red</> Back to Green</>',
      );
      // The current implementation might not handle nesting perfectly if it just resets to \x1B[0m
      // Let's see what it does.
      print('Nested output: ${output.replaceAll('\x1B', 'ESC')}');
    });

    test('href', () {
      final style = Style();
      final output = style.render('<href=https://example.com>Link</>');
      expect(output, contains('\x1b]8;;https://example.com\x07Link\x1B[0m'));
    });
  });
}
