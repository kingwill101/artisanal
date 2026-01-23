import 'package:artisanal/src/colorprofile/downsample.dart';
import 'package:artisanal/src/colorprofile/profile.dart';
import 'package:artisanal/src/terminal/ansi.dart' show Ansi;
import 'package:test/test.dart';

void main() {
  final cases =
      <
        ({
          String name,
          String input,
          String expectedTrueColor,
          String expectedAnsi256,
          String expectedAnsi,
          String expectedAscii,
        })
      >[
        (
          name: 'empty',
          input: '',
          expectedTrueColor: '',
          expectedAnsi256: '',
          expectedAnsi: '',
          expectedAscii: '',
        ),
        (
          name: 'no styles',
          input: 'hello world',
          expectedTrueColor: 'hello world',
          expectedAnsi256: 'hello world',
          expectedAnsi: 'hello world',
          expectedAscii: 'hello world',
        ),
        (
          name: 'simple style attributes',
          input: 'hello \x1b[1mworld\x1b[m',
          expectedTrueColor: 'hello \x1b[1mworld\x1b[m',
          expectedAnsi256: 'hello \x1b[1mworld\x1b[m',
          expectedAnsi: 'hello \x1b[1mworld\x1b[m',
          expectedAscii: 'hello \x1b[1mworld\x1b[m',
        ),
        (
          name: 'simple ansi color fg',
          input: 'hello \x1b[31mworld\x1b[m',
          expectedTrueColor: 'hello \x1b[31mworld\x1b[m',
          expectedAnsi256: 'hello \x1b[31mworld\x1b[m',
          expectedAnsi: 'hello \x1b[31mworld\x1b[m',
          expectedAscii: 'hello \x1b[mworld\x1b[m',
        ),
        (
          name: 'default fg color after ansi color',
          input: '\x1b[31mhello \x1b[39mworld\x1b[m',
          expectedTrueColor: '\x1b[31mhello \x1b[39mworld\x1b[m',
          expectedAnsi256: '\x1b[31mhello \x1b[39mworld\x1b[m',
          expectedAnsi: '\x1b[31mhello \x1b[39mworld\x1b[m',
          expectedAscii: '\x1b[mhello \x1b[mworld\x1b[m',
        ),
        (
          name: 'ansi color fg and bg',
          input: '\x1b[31;42mhello world\x1b[m',
          expectedTrueColor: '\x1b[31;42mhello world\x1b[m',
          expectedAnsi256: '\x1b[31;42mhello world\x1b[m',
          expectedAnsi: '\x1b[31;42mhello world\x1b[m',
          expectedAscii: '\x1b[mhello world\x1b[m',
        ),
        (
          name: 'bright ansi color fg and bg',
          input: '\x1b[91;102mhello world\x1b[m',
          expectedTrueColor: '\x1b[91;102mhello world\x1b[m',
          expectedAnsi256: '\x1b[91;102mhello world\x1b[m',
          expectedAnsi: '\x1b[91;102mhello world\x1b[m',
          expectedAscii: '\x1b[mhello world\x1b[m',
        ),
        (
          name: 'simple 256 color fg',
          input: 'hello \x1b[38;5;196mworld\x1b[m',
          expectedTrueColor: 'hello \x1b[38;5;196mworld\x1b[m',
          expectedAnsi256: 'hello \x1b[38;5;196mworld\x1b[m',
          expectedAnsi: 'hello \x1b[91mworld\x1b[m',
          expectedAscii: 'hello \x1b[mworld\x1b[m',
        ),
        (
          name: '256 color bg',
          input: '\x1b[48;5;196mhello world\x1b[m',
          expectedTrueColor: '\x1b[48;5;196mhello world\x1b[m',
          expectedAnsi256: '\x1b[48;5;196mhello world\x1b[m',
          expectedAnsi: '\x1b[101mhello world\x1b[m',
          expectedAscii: '\x1b[mhello world\x1b[m',
        ),
        (
          name: 'simple true color fg',
          input: 'hello \x1b[38;2;255;133;55mworld\x1b[m', // #ff8537
          expectedTrueColor: 'hello \x1b[38;2;255;133;55mworld\x1b[m',
          expectedAnsi256: 'hello \x1b[38;5;209mworld\x1b[m',
          expectedAnsi: 'hello \x1b[91mworld\x1b[m',
          expectedAscii: 'hello \x1b[mworld\x1b[m',
        ),
        (
          name: 'itu true color fg',
          input: 'hello \x1b[38:2::255:133:55mworld\x1b[m', // #ff8537
          expectedTrueColor: 'hello \x1b[38:2::255:133:55mworld\x1b[m',
          expectedAnsi256: 'hello \x1b[38;5;209mworld\x1b[m',
          expectedAnsi: 'hello \x1b[91mworld\x1b[m',
          expectedAscii: 'hello \x1b[mworld\x1b[m',
        ),
        (
          name: 'simple ansi 256 color bg (colon form)',
          input: 'hello \x1b[48:5:196mworld\x1b[m',
          expectedTrueColor: 'hello \x1b[48:5:196mworld\x1b[m',
          expectedAnsi256: 'hello \x1b[48;5;196mworld\x1b[m',
          expectedAnsi: 'hello \x1b[101mworld\x1b[m',
          expectedAscii: 'hello \x1b[mworld\x1b[m',
        ),
        (
          name: 'simple missing param',
          input: '\x1b[31mhello \x1b[;1mworld',
          expectedTrueColor: '\x1b[31mhello \x1b[;1mworld',
          expectedAnsi256: '\x1b[31mhello \x1b[;1mworld',
          expectedAnsi: '\x1b[31mhello \x1b[;1mworld',
          expectedAscii: '\x1b[mhello \x1b[;1mworld',
        ),
        (
          name: 'color with other attributes',
          input: '\x1b[1;38;5;204mhello \x1b[38;5;204mworld\x1b[m',
          expectedTrueColor: '\x1b[1;38;5;204mhello \x1b[38;5;204mworld\x1b[m',
          expectedAnsi256: '\x1b[1;38;5;204mhello \x1b[38;5;204mworld\x1b[m',
          expectedAnsi: '\x1b[1;91mhello \x1b[91mworld\x1b[m',
          expectedAscii: '\x1b[1mhello \x1b[mworld\x1b[m',
        ),
      ];

  group('writer parity (SGR downsampling)', () {
    for (final c in cases) {
      test(c.name, () {
        expect(downsampleSgr(c.input, Profile.trueColor), c.expectedTrueColor);
        expect(downsampleSgr(c.input, Profile.ansi256), c.expectedAnsi256);
        expect(downsampleSgr(c.input, Profile.ansi), c.expectedAnsi);
        expect(downsampleSgr(c.input, Profile.ascii), c.expectedAscii);

        // NoTTY behavior matches full ANSI strip.
        expect(downsampleSgr(c.input, Profile.noTty), Ansi.stripAnsi(c.input));
      });
    }
  });
}
