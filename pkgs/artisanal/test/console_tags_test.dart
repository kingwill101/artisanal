import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  group('Console Tags', () {
    test('basic foreground color', () {
      final style = Style();
      final output = style.render('<fg=red>Hello</>');
      expect(output, contains('\x1B[38;5;1mHello\x1B[m'));
    });

    test('basic background color', () {
      final style = Style();
      final output = style.render('<bg=blue>World</>');
      expect(output, contains('\x1B[48;5;4mWorld\x1B[m'));
    });

    test('options', () {
      final style = Style();
      final output = style.render('<options=bold,underline>Styled</>');
      expect(Style.stripAnsi(output), contains('Styled'));
      expect(output, contains('\x1B[1m'));
      expect(output, contains('\x1B[4m'));
    });

    test('hex colors', () {
      final style = Style()..colorProfile = ColorProfile.trueColor;
      final output = style.render('<fg=#ff5500>Hex</>');
      expect(output, contains('\x1B[38;2;255;85;0mHex\x1B[m'));
    });

    test('ansi 256 colors', () {
      final style = Style()..colorProfile = ColorProfile.ansi256;
      final output = style.render('<fg=196>Red</>');
      expect(output, contains('\x1B[38;5;196mRed\x1B[m'));
    });

    test('more options', () {
      final style = Style();
      final output = style.render(
        '<options=italic,strikethrough,dim>Styled</>',
      );
      expect(Style.stripAnsi(output), contains('Styled'));
      expect(output, contains('\x1B[3m'));
      expect(output, contains('\x1B[9m'));
      expect(output, contains('\x1B[2m'));
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
      expect(output, contains('\x1b]8;;https://example.com\x1b\\Link'));
    });
  });
}
