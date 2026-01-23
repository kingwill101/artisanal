import 'package:artisanal/src/colorprofile/convert.dart' as cpconv;
import 'package:artisanal/src/colorprofile/profile.dart' as cp;
import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/cell_test.go`
// - `third_party/ultraviolet/cell.go` (`ConvertStyle`, `ConvertLink`, `StyleDiff`)

void main() {
  group('Cell parity', () {
    test('ConvertStyle', () {
      final s = UvStyle(
        fg: const UvRgb(0, 0, 0),
        bg: const UvRgb(255, 255, 255),
        underlineColor: const UvRgb(0, 0, 0),
      );

      final cases = <({String name, cp.Profile profile, UvStyle want})>[
        (name: 'True Color', profile: cp.Profile.trueColor, want: s),
        (
          name: '256 Color',
          profile: cp.Profile.ansi256,
          want: UvStyle(
            fg: UvColor.indexed256(cpconv.rgbToAnsi256(0, 0, 0)),
            bg: UvColor.indexed256(cpconv.rgbToAnsi256(255, 255, 255)),
            underlineColor: UvColor.indexed256(cpconv.rgbToAnsi256(0, 0, 0)),
          ),
        ),
        (
          name: '16 Color',
          profile: cp.Profile.ansi,
          want: UvStyle(
            fg: _basic16FromIdx16(cpconv.rgbToAnsi16(0, 0, 0)),
            bg: _basic16FromIdx16(cpconv.rgbToAnsi16(255, 255, 255)),
            underlineColor: _basic16FromIdx16(cpconv.rgbToAnsi16(0, 0, 0)),
          ),
        ),
        (name: 'Grayscale', profile: cp.Profile.ascii, want: const UvStyle()),
        (name: 'No Profile', profile: cp.Profile.noTty, want: const UvStyle()),
      ];

      for (final c in cases) {
        final got = convertStyle(s, c.profile);
        expect(got, c.want, reason: c.name);
      }
    });

    test('ConvertLink', () {
      const l = Link(url: 'https://example.com', params: 'id=1');
      expect(convertLink(l, cp.Profile.trueColor), l);
      expect(convertLink(l, cp.Profile.noTty), const Link());
    });

    test('StyleDiff (upstream cases)', () {
      const red = UvRgb(255, 0, 0);
      const blue = UvRgb(0, 0, 255);
      const green = UvRgb(0, 255, 0);
      const yellow = UvRgb(255, 255, 0);
      const cyan = UvRgb(0, 255, 255);
      const magenta = UvRgb(255, 0, 255);

      final cases = <({String name, UvStyle? from, UvStyle? to, String want})>[
        (name: 'both nil', from: null, to: null, want: ''),
        (
          name: 'from nil to zero',
          from: null,
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'from zero to zero',
          from: const UvStyle(),
          to: const UvStyle(),
          want: '',
        ),
        (
          name: 'from nil to styled',
          from: null,
          to: const UvStyle(fg: red, attrs: Attr.bold),
          want: '\x1b[1;38;2;255;0;0m',
        ),

        // Foreground color tests
        (
          name: 'foreground color change',
          from: const UvStyle(fg: red),
          to: const UvStyle(fg: blue),
          want: '\x1b[38;2;0;0;255m',
        ),
        (
          name: 'add foreground color',
          from: const UvStyle(),
          to: const UvStyle(fg: red),
          want: '\x1b[38;2;255;0;0m',
        ),
        (
          name: 'remove foreground color',
          from: const UvStyle(fg: red),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'foreground color same',
          from: const UvStyle(fg: red),
          to: const UvStyle(fg: red),
          want: '',
        ),

        // Background color tests
        (
          name: 'background color change',
          from: const UvStyle(bg: red),
          to: const UvStyle(bg: blue),
          want: '\x1b[48;2;0;0;255m',
        ),
        (
          name: 'add background color',
          from: const UvStyle(),
          to: const UvStyle(bg: blue),
          want: '\x1b[48;2;0;0;255m',
        ),
        (
          name: 'remove background color',
          from: const UvStyle(bg: blue),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'background color same',
          from: const UvStyle(bg: blue),
          to: const UvStyle(bg: blue),
          want: '',
        ),

        // Underline color tests
        (
          name: 'underline color change',
          from: const UvStyle(
            underlineColor: red,
            underline: UnderlineStyle.single,
          ),
          to: const UvStyle(
            underlineColor: blue,
            underline: UnderlineStyle.single,
          ),
          want: '\x1b[58:2::0:0:255m',
        ),
        (
          name: 'add underline color',
          from: const UvStyle(underline: UnderlineStyle.single),
          to: const UvStyle(
            underlineColor: green,
            underline: UnderlineStyle.single,
          ),
          want: '\x1b[58:2::0:255:0m',
        ),
        (
          name: 'remove underline color',
          from: const UvStyle(
            underlineColor: green,
            underline: UnderlineStyle.single,
          ),
          to: const UvStyle(underline: UnderlineStyle.single),
          want: '\x1b[59m',
        ),
        (
          name: 'underline color same',
          from: const UvStyle(
            underlineColor: green,
            underline: UnderlineStyle.single,
          ),
          to: const UvStyle(
            underlineColor: green,
            underline: UnderlineStyle.single,
          ),
          want: '',
        ),

        // Bold attribute tests
        (
          name: 'add bold',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.bold),
          want: '\x1b[1m',
        ),
        (
          name: 'remove bold',
          from: const UvStyle(attrs: Attr.bold),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep bold',
          from: const UvStyle(attrs: Attr.bold),
          to: const UvStyle(attrs: Attr.bold),
          want: '',
        ),

        // Faint attribute tests
        (
          name: 'add faint',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.faint),
          want: '\x1b[2m',
        ),
        (
          name: 'remove faint',
          from: const UvStyle(attrs: Attr.faint),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep faint',
          from: const UvStyle(attrs: Attr.faint),
          to: const UvStyle(attrs: Attr.faint),
          want: '',
        ),
        (
          name: 'bold to faint',
          from: const UvStyle(attrs: Attr.bold),
          to: const UvStyle(attrs: Attr.faint),
          want: '\x1b[22;2m',
        ),
        (
          name: 'faint to bold',
          from: const UvStyle(attrs: Attr.faint),
          to: const UvStyle(attrs: Attr.bold),
          want: '\x1b[22;1m',
        ),
        (
          name: 'bold and faint to bold',
          from: const UvStyle(attrs: Attr.bold | Attr.faint),
          to: const UvStyle(attrs: Attr.bold),
          want: '\x1b[22;1m',
        ),
        (
          name: 'bold to bold and faint',
          from: const UvStyle(attrs: Attr.bold),
          to: const UvStyle(attrs: Attr.bold | Attr.faint),
          want: '\x1b[2m',
        ),

        // Italic attribute tests
        (
          name: 'add italic',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.italic),
          want: '\x1b[3m',
        ),
        (
          name: 'remove italic',
          from: const UvStyle(attrs: Attr.italic),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep italic',
          from: const UvStyle(attrs: Attr.italic),
          to: const UvStyle(attrs: Attr.italic),
          want: '',
        ),

        // Bold and Italic combination tests
        (
          name: 'bold to bold and italic',
          from: const UvStyle(attrs: Attr.bold),
          to: const UvStyle(attrs: Attr.bold | Attr.italic),
          want: '\x1b[3m',
        ),
        (
          name: 'bold and italic to bold',
          from: const UvStyle(attrs: Attr.bold | Attr.italic),
          to: const UvStyle(attrs: Attr.bold),
          want: '\x1b[23m',
        ),

        // Bold, Faint, and Italic combination tests
        (
          name: 'bold and faint to italic',
          from: const UvStyle(attrs: Attr.bold | Attr.faint),
          to: const UvStyle(attrs: Attr.italic),
          want: '\x1b[22;3m',
        ),
        (
          name: 'italic to bold and faint',
          from: const UvStyle(attrs: Attr.italic),
          to: const UvStyle(attrs: Attr.bold | Attr.faint),
          want: '\x1b[23;1;2m',
        ),
        (
          name: 'bold, faint, and italic to bold',
          from: const UvStyle(attrs: Attr.bold | Attr.faint | Attr.italic),
          to: const UvStyle(attrs: Attr.bold),
          want: '\x1b[22;23;1m',
        ),
        (
          name: 'bold to bold, faint, and italic',
          from: const UvStyle(attrs: Attr.bold),
          to: const UvStyle(attrs: Attr.bold | Attr.faint | Attr.italic),
          want: '\x1b[2;3m',
        ),

        // Slow blink attribute tests
        (
          name: 'add slow blink',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.blink),
          want: '\x1b[5m',
        ),
        (
          name: 'remove slow blink',
          from: const UvStyle(attrs: Attr.blink),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep slow blink',
          from: const UvStyle(attrs: Attr.blink),
          to: const UvStyle(attrs: Attr.blink),
          want: '',
        ),

        // Rapid blink attribute tests
        (
          name: 'add rapid blink',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.rapidBlink),
          want: '\x1b[6m',
        ),
        (
          name: 'remove rapid blink',
          from: const UvStyle(attrs: Attr.rapidBlink),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep rapid blink',
          from: const UvStyle(attrs: Attr.rapidBlink),
          to: const UvStyle(attrs: Attr.rapidBlink),
          want: '',
        ),
        (
          name: 'change from slow to rapid blink',
          from: const UvStyle(attrs: Attr.blink),
          to: const UvStyle(attrs: Attr.rapidBlink),
          want: '\x1b[25;6m',
        ),
        (
          name: 'change from rapid to slow blink',
          from: const UvStyle(attrs: Attr.rapidBlink),
          to: const UvStyle(attrs: Attr.blink),
          want: '\x1b[25;5m',
        ),
        (
          name: 'slow and rapid blink to slow blink',
          from: const UvStyle(attrs: Attr.blink | Attr.rapidBlink),
          to: const UvStyle(attrs: Attr.blink),
          want: '\x1b[25;5m',
        ),

        // Reverse attribute tests
        (
          name: 'add reverse',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.reverse),
          want: '\x1b[7m',
        ),
        (
          name: 'remove reverse',
          from: const UvStyle(attrs: Attr.reverse),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep reverse',
          from: const UvStyle(attrs: Attr.reverse),
          to: const UvStyle(attrs: Attr.reverse),
          want: '',
        ),

        // Conceal attribute tests
        (
          name: 'add conceal',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.conceal),
          want: '\x1b[8m',
        ),
        (
          name: 'remove conceal',
          from: const UvStyle(attrs: Attr.conceal),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep conceal',
          from: const UvStyle(attrs: Attr.conceal),
          to: const UvStyle(attrs: Attr.conceal),
          want: '',
        ),

        // Strikethrough attribute tests
        (
          name: 'add strikethrough',
          from: const UvStyle(),
          to: const UvStyle(attrs: Attr.strikethrough),
          want: '\x1b[9m',
        ),
        (
          name: 'remove strikethrough',
          from: const UvStyle(attrs: Attr.strikethrough),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'keep strikethrough',
          from: const UvStyle(attrs: Attr.strikethrough),
          to: const UvStyle(attrs: Attr.strikethrough),
          want: '',
        ),

        // Underline style tests
        (
          name: 'add single underline',
          from: const UvStyle(),
          to: const UvStyle(underline: UnderlineStyle.single),
          want: '\x1b[4m',
        ),
        (
          name: 'add double underline',
          from: const UvStyle(),
          to: const UvStyle(underline: UnderlineStyle.double),
          want: '\x1b[4:2m',
        ),
        (
          name: 'add curly underline',
          from: const UvStyle(),
          to: const UvStyle(underline: UnderlineStyle.curly),
          want: '\x1b[4:3m',
        ),
        (
          name: 'add dotted underline',
          from: const UvStyle(),
          to: const UvStyle(underline: UnderlineStyle.dotted),
          want: '\x1b[4:4m',
        ),
        (
          name: 'add dashed underline',
          from: const UvStyle(),
          to: const UvStyle(underline: UnderlineStyle.dashed),
          want: '\x1b[4:5m',
        ),
        (
          name: 'change underline style single to double',
          from: const UvStyle(underline: UnderlineStyle.single),
          to: const UvStyle(underline: UnderlineStyle.double),
          want: '\x1b[4:2m',
        ),
        (
          name: 'change underline style double to curly',
          from: const UvStyle(underline: UnderlineStyle.double),
          to: const UvStyle(underline: UnderlineStyle.curly),
          want: '\x1b[4:3m',
        ),

        // Multiple attribute combinations
        (
          name: 'add multiple attributes',
          from: const UvStyle(),
          to: const UvStyle(
            attrs: Attr.bold | Attr.italic,
            underline: UnderlineStyle.single,
          ),
          want: '\x1b[1;3;4m',
        ),
        (
          name: 'remove multiple attributes',
          from: const UvStyle(attrs: Attr.bold | Attr.italic | Attr.reverse),
          to: const UvStyle(),
          want: '\x1b[m',
        ),
        (
          name: 'combine multiple attribute changes',
          from: const UvStyle(attrs: Attr.bold | Attr.italic),
          to: const UvStyle(attrs: Attr.bold | Attr.reverse),
          want: '\x1b[23;7m',
        ),
        (
          name: 'swap italic and strikethrough',
          from: const UvStyle(attrs: Attr.italic),
          to: const UvStyle(attrs: Attr.strikethrough),
          want: '\x1b[23;9m',
        ),
        (
          name: 'all attributes added',
          from: const UvStyle(),
          to: const UvStyle(
            attrs:
                Attr.bold |
                Attr.faint |
                Attr.italic |
                Attr.blink |
                Attr.rapidBlink |
                Attr.reverse |
                Attr.conceal |
                Attr.strikethrough,
          ),
          want: '\x1b[1;2;3;5;6;7;8;9m',
        ),
        (
          name: 'all attributes removed',
          from: const UvStyle(
            attrs:
                Attr.bold |
                Attr.faint |
                Attr.italic |
                Attr.blink |
                Attr.rapidBlink |
                Attr.reverse |
                Attr.conceal |
                Attr.strikethrough,
          ),
          to: const UvStyle(),
          want: '\x1b[m',
        ),

        // Complex style changes with colors and attributes
        (
          name: 'complex style change with all properties',
          from: const UvStyle(fg: red, bg: blue, attrs: Attr.bold),
          to: const UvStyle(
            fg: green,
            bg: yellow,
            underlineColor: cyan,
            attrs: Attr.italic,
            underline: UnderlineStyle.single,
          ),
          want: '\x1b[38;2;0;255;0;48;2;255;255;0;58:2::0:255:255;22;3;4m',
        ),
        (
          name: 'complex change keeping some properties',
          from: const UvStyle(
            fg: red,
            bg: blue,
            attrs: Attr.bold | Attr.italic,
            underline: UnderlineStyle.single,
          ),
          to: const UvStyle(
            fg: red,
            bg: green,
            attrs: Attr.bold | Attr.reverse,
            underline: UnderlineStyle.double,
          ),
          want: '\x1b[48;2;0;255;0;23;7;4:2m',
        ),

        // Edge cases
        (
          name: 'no changes with all properties',
          from: const UvStyle(
            fg: red,
            bg: blue,
            underlineColor: green,
            attrs: Attr.bold | Attr.italic,
            underline: UnderlineStyle.single,
          ),
          to: const UvStyle(
            fg: red,
            bg: blue,
            underlineColor: green,
            attrs: Attr.bold | Attr.italic,
            underline: UnderlineStyle.single,
          ),
          want: '',
        ),
        (
          name: 'only colors change',
          from: const UvStyle(fg: red, bg: blue, attrs: Attr.bold),
          to: const UvStyle(fg: green, bg: yellow, attrs: Attr.bold),
          want: '\x1b[38;2;0;255;0;48;2;255;255;0m',
        ),
        (
          name: 'only attributes change',
          from: const UvStyle(fg: red, attrs: Attr.bold),
          to: const UvStyle(fg: red, attrs: Attr.italic),
          want: '\x1b[22;3m',
        ),
        (
          name: 'add all colors',
          from: const UvStyle(),
          to: const UvStyle(
            fg: red,
            bg: blue,
            underlineColor: green,
            underline: UnderlineStyle.single,
          ),
          want: '\x1b[38;2;255;0;0;48;2;0;0;255;58:2::0:255:0;4m',
        ),
        (
          name: 'add all colors without underline',
          from: const UvStyle(),
          to: const UvStyle(fg: red, bg: blue, underlineColor: green),
          want: '\x1b[38;2;255;0;0;48;2;0;0;255;58:2::0:255:0m',
        ),
        (
          name: 'remove all colors with attributes',
          from: const UvStyle(fg: red, bg: blue, attrs: Attr.bold),
          to: const UvStyle(attrs: Attr.bold),
          want: '\x1b[39;49m',
        ),
        (
          name: 'change all colors',
          from: const UvStyle(fg: red, bg: blue, underlineColor: green),
          to: const UvStyle(fg: cyan, bg: magenta, underlineColor: yellow),
          want: '\x1b[38;2;0;255;255;48;2;255;0;255;58:2::255:255:0m',
        ),
      ];

      for (final c in cases) {
        final got = styleDiff(c.from, c.to);
        expect(got, c.want, reason: c.name);
      }
    });
  });
}

UvBasic16 _basic16FromIdx16(int idx16) {
  final i = idx16.clamp(0, 15);
  if (i < 8) return UvBasic16(i, bright: false);
  return UvBasic16(i - 8, bright: true);
}
