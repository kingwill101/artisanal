import 'package:ultraviolet/src/uv/uv.dart';
import 'package:ultraviolet/src/unicode/width.dart';
import 'package:test/test.dart';

Cell _newWcCell(String s, UvStyle? style, Link? link) {
  final c = Cell.newCell(WidthMethod.wcwidth, s);
  if (style != null) c.style = style;
  if (link != null) c.link = link;
  return c;
}

Buffer _bufferFromLines(List<List<Cell>> lines) {
  return Buffer.fromCells(lines);
}

void main() {
  group('StyledString parity', () {
    test('TestStyledString (upstream cases)', () {
      final cases =
          <
            ({
              String name,
              String input,
              int expectedWidth,
              int expectedHeight,
              Buffer expected,
            })
          >[
            (
              name: 'single line',
              input: 'Hello, World!',
              expectedWidth: 13,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  _newWcCell('H', null, null),
                  _newWcCell('e', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('o', null, null),
                  _newWcCell(',', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell('W', null, null),
                  _newWcCell('o', null, null),
                  _newWcCell('r', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('d', null, null),
                  _newWcCell('!', null, null),
                ],
              ]),
            ),
            (
              name: 'multiple lines',
              input: 'Hello,\nWorld!',
              expectedWidth: 6,
              expectedHeight: 2,
              expected: _bufferFromLines([
                [
                  _newWcCell('H', null, null),
                  _newWcCell('e', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('o', null, null),
                  _newWcCell(',', null, null),
                ],
                [
                  _newWcCell('W', null, null),
                  _newWcCell('o', null, null),
                  _newWcCell('r', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('d', null, null),
                  _newWcCell('!', null, null),
                ],
              ]),
            ),
            (
              name: 'empty string',
              input: '',
              expectedWidth: 0,
              expectedHeight: 1,
              expected: _bufferFromLines([[]]),
            ),
            (
              name: 'multiple lines different width',
              input: 'Hello,\nWorld!\nThis is a test.',
              expectedWidth: 15,
              expectedHeight: 3,
              expected: _bufferFromLines([
                [
                  _newWcCell('H', null, null),
                  _newWcCell('e', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('o', null, null),
                  _newWcCell(',', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                ],
                [
                  _newWcCell('W', null, null),
                  _newWcCell('o', null, null),
                  _newWcCell('r', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('d', null, null),
                  _newWcCell('!', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell(' ', null, null),
                ],
                [
                  _newWcCell('T', null, null),
                  _newWcCell('h', null, null),
                  _newWcCell('i', null, null),
                  _newWcCell('s', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell('i', null, null),
                  _newWcCell('s', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell('a', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell('t', null, null),
                  _newWcCell('e', null, null),
                  _newWcCell('s', null, null),
                  _newWcCell('t', null, null),
                  _newWcCell('.', null, null),
                ],
              ]),
            ),
            (
              name: 'unicode characters',
              input: 'Hello, 世界!',
              expectedWidth: 12,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  _newWcCell('H', null, null),
                  _newWcCell('e', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('l', null, null),
                  _newWcCell('o', null, null),
                  _newWcCell(',', null, null),
                  _newWcCell(' ', null, null),
                  _newWcCell('世', null, null),
                  Cell(), // placeholder
                  _newWcCell('界', null, null),
                  Cell(), // placeholder
                  _newWcCell('!', null, null),
                ],
              ]),
            ),
            (
              name: 'styled hello world string',
              input: '\x1b[31;1;4mHello, \x1b[32;22;4mWorld!\x1b[0m',
              expectedWidth: 13,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  _newWcCell(
                    'H',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'l',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'l',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'o',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    ',',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    ' ',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'W',
                    UvStyle(
                      fg: const UvColor.basic16(2),
                      underline: UnderlineStyle.single,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'o',
                    UvStyle(
                      fg: const UvColor.basic16(2),
                      underline: UnderlineStyle.single,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'r',
                    UvStyle(
                      fg: const UvColor.basic16(2),
                      underline: UnderlineStyle.single,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'l',
                    UvStyle(
                      fg: const UvColor.basic16(2),
                      underline: UnderlineStyle.single,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'd',
                    UvStyle(
                      fg: const UvColor.basic16(2),
                      underline: UnderlineStyle.single,
                    ),
                    null,
                  ),
                  _newWcCell(
                    '!',
                    UvStyle(
                      fg: const UvColor.basic16(2),
                      underline: UnderlineStyle.single,
                    ),
                    null,
                  ),
                ],
              ]),
            ),
            (
              name: 'complex styling with multiple SGR sequences',
              input:
                  '\x1b[31;1;2;4mR\x1b[22;1med\x1b[0m \x1b[32;3mGreen\x1b[0m \x1b[34;9mBlue\x1b[0m \x1b[33;7mYellow\x1b[0m \x1b[35;5mPurple\x1b[0m',
              expectedWidth: 28,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  _newWcCell(
                    'R',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold | Attr.faint,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'd',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      underline: UnderlineStyle.single,
                      attrs: Attr.bold,
                    ),
                    null,
                  ),
                  _newWcCell(' ', null, null),
                  _newWcCell(
                    'G',
                    UvStyle(fg: const UvColor.basic16(2), attrs: Attr.italic),
                    null,
                  ),
                  _newWcCell(
                    'r',
                    UvStyle(fg: const UvColor.basic16(2), attrs: Attr.italic),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(fg: const UvColor.basic16(2), attrs: Attr.italic),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(fg: const UvColor.basic16(2), attrs: Attr.italic),
                    null,
                  ),
                  _newWcCell(
                    'n',
                    UvStyle(fg: const UvColor.basic16(2), attrs: Attr.italic),
                    null,
                  ),
                  _newWcCell(' ', null, null),
                  _newWcCell(
                    'B',
                    UvStyle(
                      fg: const UvColor.basic16(4),
                      attrs: Attr.strikethrough,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'l',
                    UvStyle(
                      fg: const UvColor.basic16(4),
                      attrs: Attr.strikethrough,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'u',
                    UvStyle(
                      fg: const UvColor.basic16(4),
                      attrs: Attr.strikethrough,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(
                      fg: const UvColor.basic16(4),
                      attrs: Attr.strikethrough,
                    ),
                    null,
                  ),
                  _newWcCell(' ', null, null),
                  _newWcCell(
                    'Y',
                    UvStyle(fg: const UvColor.basic16(3), attrs: Attr.reverse),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(fg: const UvColor.basic16(3), attrs: Attr.reverse),
                    null,
                  ),
                  _newWcCell(
                    'l',
                    UvStyle(fg: const UvColor.basic16(3), attrs: Attr.reverse),
                    null,
                  ),
                  _newWcCell(
                    'l',
                    UvStyle(fg: const UvColor.basic16(3), attrs: Attr.reverse),
                    null,
                  ),
                  _newWcCell(
                    'o',
                    UvStyle(fg: const UvColor.basic16(3), attrs: Attr.reverse),
                    null,
                  ),
                  _newWcCell(
                    'w',
                    UvStyle(fg: const UvColor.basic16(3), attrs: Attr.reverse),
                    null,
                  ),
                  _newWcCell(' ', null, null),
                  _newWcCell(
                    'P',
                    UvStyle(fg: const UvColor.basic16(5), attrs: Attr.blink),
                    null,
                  ),
                  _newWcCell(
                    'u',
                    UvStyle(fg: const UvColor.basic16(5), attrs: Attr.blink),
                    null,
                  ),
                  _newWcCell(
                    'r',
                    UvStyle(fg: const UvColor.basic16(5), attrs: Attr.blink),
                    null,
                  ),
                  _newWcCell(
                    'p',
                    UvStyle(fg: const UvColor.basic16(5), attrs: Attr.blink),
                    null,
                  ),
                  _newWcCell(
                    'l',
                    UvStyle(fg: const UvColor.basic16(5), attrs: Attr.blink),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(fg: const UvColor.basic16(5), attrs: Attr.blink),
                    null,
                  ),
                ],
              ]),
            ),
            (
              name: 'different underline styles',
              input:
                  '\x1b[4:1mSingle\x1b[0m \x1b[4:2mDouble\x1b[0m \x1b[4:3mCurly\x1b[0m \x1b[4:4mDotted\x1b[0m \x1b[4:5mDashed\x1b[0m',
              expectedWidth: 33,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  ...'Single'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(underline: UnderlineStyle.single),
                          null,
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'Double'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(underline: UnderlineStyle.double),
                          null,
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'Curly'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(underline: UnderlineStyle.curly),
                          null,
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'Dotted'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(underline: UnderlineStyle.dotted),
                          null,
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'Dashed'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(underline: UnderlineStyle.dashed),
                          null,
                        ),
                      ),
                ],
              ]),
            ),
            (
              name: 'truecolor and 256 color support',
              input:
                  '\x1b[38;2;255;0;0mRGB Red\x1b[0m \x1b[48;2;0;255;0mRGB Green BG\x1b[0m \x1b[38;5;33m256 Blue\x1b[0m',
              expectedWidth: 29,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  ...'RGB Red'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(fg: UvColor.rgb(255, 0, 0)),
                          null,
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'RGB Green BG'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(bg: UvColor.rgb(0, 255, 0)),
                          null,
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'256 Blue'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(fg: UvColor.indexed256(33)),
                          null,
                        ),
                      ),
                ],
              ]),
            ),
            (
              name: 'hyperlink support',
              input:
                  'Normal \x1b]8;;https://charm.sh\x1b\\Charm\x1b]8;;\x1b\\ Text \x1b]8;;https://github.com/charmbracelet\x1b\\GitHub\x1b]8;;\x1b\\',
              expectedWidth: 24,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  ...'Normal '
                      .split('')
                      .map((ch) => _newWcCell(ch, null, null)),
                  ...'Charm'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          null,
                          const Link(url: 'https://charm.sh'),
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'Text '.split('').map((ch) => _newWcCell(ch, null, null)),
                  ...'GitHub'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          null,
                          const Link(url: 'https://github.com/charmbracelet'),
                        ),
                      ),
                ],
              ]),
            ),
            (
              name: 'complex mixed styling with hyperlinks',
              input:
                  '\x1b[31;1;2;3mR\x1b[22;23;1med \x1b]8;;https://charm.sh\x1b\\\x1b[4mCharm\x1b]8;;\x1b\\\x1b[0m \x1b[38;5;33;48;2;0;100;0m\x1b]8;;https://github.com\x1b\\GitHub\x1b]8;;\x1b\\\x1b[0m',
              expectedWidth: 16,
              expectedHeight: 1,
              expected: _bufferFromLines([
                [
                  _newWcCell(
                    'R',
                    UvStyle(
                      fg: const UvColor.basic16(1),
                      attrs: Attr.bold | Attr.faint | Attr.italic,
                    ),
                    null,
                  ),
                  _newWcCell(
                    'e',
                    UvStyle(fg: const UvColor.basic16(1), attrs: Attr.bold),
                    null,
                  ),
                  _newWcCell(
                    'd',
                    UvStyle(fg: const UvColor.basic16(1), attrs: Attr.bold),
                    null,
                  ),
                  _newWcCell(
                    ' ',
                    UvStyle(fg: const UvColor.basic16(1), attrs: Attr.bold),
                    null,
                  ),
                  ...'Charm'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          UvStyle(
                            fg: const UvColor.basic16(1),
                            underline: UnderlineStyle.single,
                            attrs: Attr.bold,
                          ),
                          const Link(url: 'https://charm.sh'),
                        ),
                      ),
                  _newWcCell(' ', null, null),
                  ...'GitHub'
                      .split('')
                      .map(
                        (ch) => _newWcCell(
                          ch,
                          const UvStyle(
                            fg: UvColor.indexed256(33),
                            bg: UvColor.rgb(0, 100, 0),
                          ),
                          const Link(url: 'https://github.com'),
                        ),
                      ),
                ],
              ]),
            ),
          ];

      for (final tc in cases) {
        final ss = newStyledString(tc.input);
        final area = ss.bounds();
        final scr = ScreenBuffer(area.width, area.height);
        ss.draw(scr, area);

        expect(scr.width(), tc.expectedWidth, reason: tc.name);
        expect(scr.height(), tc.expectedHeight, reason: tc.name);

        for (var y = 0; y < scr.height(); y++) {
          for (var x = 0; x < scr.width(); x++) {
            final got = scr.cellAt(x, y);
            final expected = tc.expected.cellAt(x, y);
            expect(got, expected, reason: '${tc.name} cell($x,$y)');
          }
        }
      }
    });

    test('TestStyledStringEmptyLines (upstream)', () {
      final input = '\x1b[31;1;4mHello, \x1b[32;22;4mWorld!\x1b[0m';
      final ss = newStyledString(input);
      final scr = ScreenBuffer(5, 3);
      ss.draw(scr, scr.bounds());

      final expected = _bufferFromLines([
        [
          _newWcCell(
            'H',
            UvStyle(
              fg: const UvColor.basic16(1),
              underline: UnderlineStyle.single,
              attrs: Attr.bold,
            ),
            null,
          ),
          _newWcCell(
            'e',
            UvStyle(
              fg: const UvColor.basic16(1),
              underline: UnderlineStyle.single,
              attrs: Attr.bold,
            ),
            null,
          ),
          _newWcCell(
            'l',
            UvStyle(
              fg: const UvColor.basic16(1),
              underline: UnderlineStyle.single,
              attrs: Attr.bold,
            ),
            null,
          ),
          _newWcCell(
            'l',
            UvStyle(
              fg: const UvColor.basic16(1),
              underline: UnderlineStyle.single,
              attrs: Attr.bold,
            ),
            null,
          ),
          _newWcCell(
            'o',
            UvStyle(
              fg: const UvColor.basic16(1),
              underline: UnderlineStyle.single,
              attrs: Attr.bold,
            ),
            null,
          ),
        ],
        List<Cell>.generate(5, (_) => Cell.emptyCell()),
        List<Cell>.generate(5, (_) => Cell.emptyCell()),
      ]);

      for (var y = 0; y < scr.height(); y++) {
        for (var x = 0; x < scr.width(); x++) {
          expect(
            scr.cellAt(x, y),
            expected.cellAt(x, y),
            reason: 'cell($x,$y)',
          );
        }
      }
    });

    test('normalizes oversized truecolor SGR components to byte RGB', () {
      final scr = ScreenBuffer(3, 1);

      newStyledString(
        '\x1b[38:2::57531:4369:65535m'
        'F'
        '\x1b[48;2;65535;0;57531m'
        'B'
        '\x1b[58:2::4369:57531:65535m'
        'U',
      ).draw(scr, scr.bounds());

      expect(scr.cellAt(0, 0)?.style.fg, const UvRgb(224, 17, 255));
      expect(scr.cellAt(1, 0)?.style.bg, const UvRgb(255, 0, 224));
      expect(scr.cellAt(2, 0)?.style.underlineColor, const UvRgb(17, 224, 255));
    });

    test('draws mixed ASCII and complex graphemes in the same scan', () {
      final scr = ScreenBuffer(10, 1);

      newStyledString('A😀e\u0301Z').draw(scr, scr.bounds());

      expect(scr.cellAt(0, 0)?.content, 'A');
      expect(scr.cellAt(0, 0)?.width, 1);
      expect(scr.cellAt(1, 0)?.content, '😀');
      expect(scr.cellAt(1, 0)?.width, 2);
      expect(scr.cellAt(3, 0)?.content, 'e\u0301');
      expect(scr.cellAt(3, 0)?.width, 1);
      expect(scr.cellAt(4, 0)?.content, 'Z');
      expect(scr.cellAt(4, 0)?.width, 1);
    });

    test('preserves APC and DCS control strings as terminal payload cells', () {
      const kitty = '\x1b_Ga=T,f=100,i=1,c=2,r=1,C=1,q=2,m=0;AAAA\x1b\\';
      const sixel = '\x1bPq#0;2;0;0;0!1~\x1b\\';
      final scr = ScreenBuffer(8, 2);

      newStyledString('${kitty}X\n${sixel}Y').draw(scr, scr.bounds());

      expect(scr.cellAt(0, 0)?.content, kitty);
      expect(scr.cellAt(0, 0)?.width, 2);
      expect(scr.cellAt(1, 0)?.isZero, isTrue);
      expect(scr.cellAt(2, 0)?.content, 'X');
      expect(scr.cellAt(0, 1)?.content, sixel);
      expect(scr.cellAt(0, 1)?.width, 1);
      expect(scr.cellAt(1, 1)?.content, 'Y');
    });

    test('groups chunked Kitty APC sequences into one image cell', () {
      const kitty =
          '\x1b_Ga=T,f=100,i=7,c=4,r=2,C=1,q=2,m=1;AAAA\x1b\\'
          '\x1b_Gm=0;BBBB\x1b\\';
      final scr = ScreenBuffer(8, 2);

      newStyledString('${kitty}Z').draw(scr, scr.bounds());

      expect(scr.cellAt(0, 0)?.content, kitty);
      expect(scr.cellAt(0, 0)?.width, 4);
      expect(scr.cellAt(1, 0)?.isZero, isTrue);
      expect(scr.cellAt(2, 0)?.isZero, isTrue);
      expect(scr.cellAt(3, 0)?.isZero, isTrue);
      expect(scr.cellAt(4, 0)?.content, 'Z');
    });

    test('combines Kitty delete commands with the next display cell', () {
      const delete = '\x1b_Ga=d,d=I,i=9,q=2\x1b\\';
      const kitty = '\x1b_Ga=T,f=100,i=9,c=3,r=1,C=1,q=2,m=0;AAAA\x1b\\';
      final scr = ScreenBuffer(8, 1);

      newStyledString('$delete$kitty!').draw(scr, scr.bounds());

      expect(scr.cellAt(0, 0)?.content, '$delete$kitty');
      expect(scr.cellAt(0, 0)?.width, 3);
      expect(scr.cellAt(1, 0)?.isZero, isTrue);
      expect(scr.cellAt(2, 0)?.isZero, isTrue);
      expect(scr.cellAt(3, 0)?.content, '!');
    });

    test('bounds account for Kitty image cell width', () {
      const kitty = '\x1b_Ga=T,f=100,i=9,c=8,r=4,C=1,q=2,m=0;AAAA\x1b\\';

      expect(newStyledString(kitty).bounds(), rect(0, 0, 8, 1));
      expect(newStyledString('${kitty}X').bounds(), rect(0, 0, 9, 1));
    });
  });
}
