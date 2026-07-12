import 'package:ultraviolet/src/colorprofile/convert.dart' as cpconv;
import 'package:ultraviolet/src/colorprofile/profile.dart' as cp;
import 'package:ultraviolet/src/uv/uv.dart';

import 'package:test/test.dart';

void main() {
  group('Cell parity', () {
    test('equivalent styles and links compare equally across cells', () {
      final cellA = Cell(
        content: 'A',
        width: 1,
        style: UvStyle(
          fg: const UvRgb(1, 2, 3),
          bg: const UvRgb(4, 5, 6),
          attrs: Attr.bold,
        ),
        link: Link(url: 'https://example.com', params: 'id=1'),
      );
      final cellB = Cell(
        content: 'B',
        width: 1,
        style: UvStyle(
          fg: const UvRgb(1, 2, 3),
          bg: const UvRgb(4, 5, 6),
          attrs: Attr.bold,
        ),
        link: Link(url: 'https://example.com', params: 'id=1'),
      );

      expect(cellA.style, cellB.style);
      expect(cellA.link, cellB.link);
      expect(cellA, isNot(cellB));
    });

    test('preserves equality semantics for simple and complex graphemes', () {
      final asciiA = Cell(content: 'A', width: 1);
      final asciiB = Cell(content: 'A', width: 1);
      final asciiC = Cell(content: 'A', width: 2);
      final emojiA = Cell(content: '👩‍💻', width: 2);
      final emojiB = Cell(content: '👩‍💻', width: 2);
      final emojiC = Cell(content: '👩‍💻', width: 1);

      expect(asciiA, asciiB);
      expect(asciiA.hashCode, asciiB.hashCode);
      expect(asciiA, isNot(asciiC));

      expect(emojiA, emojiB);
      expect(emojiA.hashCode, emojiB.hashCode);
      expect(emojiA, isNot(emojiC));
    });

    test('pools complex graphemes and tracks refcounts across clones', () {
      final emoji = Cell(content: '\u0061\u0308', width: 1);
      final clone = emoji.clone();
      final pooledId = emoji.pooledContentId!;

      expect(emoji.pooledContentId, isNotNull);
      expect(clone.pooledContentId, emoji.pooledContentId);
      expect(debugGraphemeRefCount(pooledId), 2);

      clone.dispose();
      expect(debugGraphemeRefCount(pooledId), 1);

      emoji.dispose();
      expect(debugGraphemeRefCount(pooledId), 0);
    });

    test('mutating complex content releases the previous pooled grapheme', () {
      final cell = Cell(content: '\u0071\u0323', width: 1);
      final oldId = cell.pooledContentId!;

      cell.content = '\u0078\u0302';
      final newId = cell.pooledContentId!;

      expect(cell.pooledContentId, isNot(oldId));
      expect(debugGraphemeRefCount(oldId), 0);
      expect(debugGraphemeRefCount(newId), 1);

      cell.empty();
      expect(debugGraphemeRefCount(newId), 0);
    });

    test('reuses freed grapheme slots with a new generation', () {
      final first = Cell(content: '\u006F\u0302', width: 1);
      final firstId = first.pooledContentId!;
      final firstSlot = debugGraphemeSlot(firstId);
      final firstGeneration = debugGraphemeGeneration(firstId);

      first.dispose();

      final second = Cell(content: '\u0075\u0304', width: 1);
      final secondId = second.pooledContentId!;

      expect(debugGraphemeSlot(secondId), firstSlot);
      expect(debugGraphemeGeneration(secondId), greaterThan(firstGeneration));
      expect(debugGraphemeRefCount(firstId), 0);
      expect(second.content, '\u0075\u0304');
    });

    test('encodes grapheme width in pooled ids', () {
      final wide = Cell(content: '👩‍💻', width: 2);
      final combining = Cell(content: '\u0065\u0301', width: 1);
      final terminalPayload = Cell(content: '\x1b_Gpayload\x1b\\', width: 80);

      expect(debugGraphemeWidth(wide.pooledContentId!), 2);
      expect(debugGraphemeWidth(combining.pooledContentId!), 1);
      expect(debugGraphemeWidth(terminalPayload.pooledContentId!), 80);
      expect(terminalPayload.content, '\x1b_Gpayload\x1b\\');

      wide.dispose();
      combining.dispose();
      terminalPayload.dispose();
    });

    test('pools links by URL and params with refcount tracking', () {
      final first = Cell(
        content: 'L',
        width: 1,
        link: const Link(
          url: 'https://example-parity-link-registry-a.test',
          params: 'id=1',
        ),
      );
      final second = Cell(
        content: 'i',
        width: 1,
        link: const Link(
          url: 'https://example-parity-link-registry-a.test',
          params: 'id=1',
        ),
      );

      final firstId = first.linkId;
      final secondId = second.linkId;

      expect(firstId, isNotNull);
      expect(firstId, secondId);
      expect(debugLinkRefCount(firstId!), 2);

      first.dispose();
      expect(debugLinkRefCount(firstId), 1);

      second.dispose();
      expect(debugLinkRefCount(firstId), 0);
    });

    test('link registry reuses freed slots with generation increments', () {
      final first = Cell(
        content: 'A',
        link: const Link(url: 'https://free.example'),
      );
      final firstId = first.linkId!;
      final firstSlot = debugLinkSlot(firstId);
      final firstGeneration = debugLinkGeneration(firstId);
      first.dispose();

      final second = Cell(
        content: 'B',
        link: const Link(url: 'https://example-parity-link-registry-b.test'),
      );
      final secondId = second.linkId!;

      expect(debugLinkSlot(secondId), firstSlot);
      expect(debugLinkGeneration(secondId), greaterThan(firstGeneration));
      expect(
        second.link,
        const Link(url: 'https://example-parity-link-registry-b.test'),
      );
      second.dispose();
    });

    test('link links with control characters are rejected', () {
      expect(
        () => Cell(link: const Link(url: 'https://bad.example\nx')),
        throwsArgumentError,
      );
      expect(
        () => Cell(
          link: const Link(url: 'https://bad.example', params: '\x00x'),
        ),
        throwsArgumentError,
      );
    });

    test('Packed cell tuple reflects equality semantics', () {
      final base = Cell(
        content: 'A',
        width: 1,
        style: const UvStyle(fg: UvRgb(1, 2, 3)),
        link: const Link(url: 'https://example.com'),
      );
      final same = Cell(
        content: 'A',
        width: 1,
        style: const UvStyle(fg: UvRgb(1, 2, 3)),
        link: const Link(url: 'https://example.com'),
      );
      expect(base.packed, equals(same.packed));

      final widthShift = Cell(content: 'A', width: 2);
      expect(base.packed, isNot(widthShift.packed));
      final baseWidthReset = Cell(
        content: base.content,
        width: base.width,
        style: base.style,
        link: base.link,
      );
      expect(baseWidthReset.packed, equals(base.packed));

      final contentShift = Cell(content: 'B', width: 1);
      expect(base.packed, isNot(contentShift.packed));

      final contentKindShift = Cell(content: '👩‍💻', width: 2);
      expect(base.packed, isNot(contentKindShift.packed));
      final continuation = Line.filled(3);
      continuation.set(0, Cell(content: '👩‍💻', width: 2));
      final placeholder = continuation.at(1)!;
      expect(placeholder.width, 0);
      expect(contentKindShift.width, 2);
      expect(contentKindShift.packed, isNot(placeholder.packed));

      final sameLinkDifferentInstance = Cell(
        content: 'A',
        width: 1,
        style: const UvStyle(fg: UvRgb(1, 2, 3)),
        link: const Link(url: 'https://example.com'),
      );
      expect(base.packed, sameLinkDifferentInstance.packed);

      final styleShift = Cell(
        content: 'A',
        width: 1,
        style: const UvStyle(fg: UvRgb(9, 8, 7)),
        link: const Link(url: 'https://example.com'),
      );
      expect(base.packed, isNot(styleShift.packed));
    });

    test('empty keeps style and link while rewriting content to space', () {
      final cell = Cell(
        content: 'X',
        width: 1,
        style: const UvStyle(fg: UvRgb(255, 0, 0)),
        link: const Link(url: 'https://example.com'),
      );

      cell.empty();

      expect(cell.content, ' ');
      expect(cell.width, 1);
      expect(cell.style, const UvStyle(fg: UvRgb(255, 0, 0)));
      expect(cell.link, const Link(url: 'https://example.com'));
    });

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

    test('styleTransitionSgr picks the cheaper transition', () {
      final from = const UvStyle(
        fg: UvRgb(255, 0, 0),
        bg: UvRgb(0, 0, 255),
        attrs: Attr.bold | Attr.faint,
      );
      final to = const UvStyle(attrs: Attr.italic);

      final delta = styleDiff(from, to);
      final chosen = styleTransitionSgr(from, to);
      final resetThenApply = '${UvAnsi.resetStyle}${styleToSgr(to)}';

      expect(chosen.length, lessThanOrEqualTo(delta.length));
      expect(chosen.length, lessThanOrEqualTo(resetThenApply.length));
    });

    test('styleTransitionSgr handles bold/faint collateral damage cheaply', () {
      const from = UvStyle(attrs: Attr.bold | Attr.faint);
      const to = UvStyle(attrs: Attr.bold);

      final chosen = styleTransitionSgr(from, to);

      expect(
        chosen,
        anyOf('\x1b[22;1m', '${UvAnsi.resetStyle}${styleToSgr(to)}'),
      );
    });
  });
}

UvBasic16 _basic16FromIdx16(int idx16) {
  final i = idx16.clamp(0, 15);
  if (i < 8) return UvBasic16(i, bright: false);
  return UvBasic16(i - 8, bright: true);
}
