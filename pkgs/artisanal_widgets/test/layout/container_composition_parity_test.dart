import 'package:artisanal/style.dart' show Colors, Layout;
import 'package:artisanal/uv.dart';
import 'package:artisanal_widgets/src/widgets/layout/_layout_utils.dart';
import 'package:test/test.dart';

void main() {
  const width = 12;
  const height = 2;
  final cases = <String, String>{
    'plain': 'text',
    'blank': '    ',
    'tab': 'A\tB',
    'SGR': '\x1b[1;31mred\x1b[0m plain',
    'open SGR across rows': '\x1b[31mred',
    'foreground-only space': '\x1b[32m \x1b[0m',
    'bold-only space': '\x1b[1m \x1b[0m',
    'reverse space': '\x1b[7m \x1b[0m',
    'concealed text': '\x1b[8msecret\x1b[0m',
    'colon SGR': '\x1b[38:2::10:20:30mtext\x1b[0m',
    'underline space': '\x1b[4;58;2;1;2;3m \x1b[0m',
    'colored background': '\x1b[48;2;40;50;60mwide\x1b[0m',
    'OSC8 ST': '\x1b]8;id=x;https://example.test\x1b\\link\x1b]8;;\x1b\\',
    'OSC8 BEL': '\x1b]8;;https://example.test\x07link\x1b]8;;\x07',
    'CJK': '界中',
    'emoji': '😀',
    'combining fallback': 'e\u0301',
    'ZWJ fallback': '👩‍💻',
    'isolated format fallback': '\u200d',
    'rewrite fallback': 'ABCDE\r ',
    'C1 fallback': '\x9b31mred\x9b0m',
    'private CSI fallback': '\x1b[?25hX',
    'OSC title fallback': '\x1b]0;title\x07X',
    'graphics fallback': '\x1b_Ga=T,f=32,s=1,v=1;AAAAAA==\x1b\\',
    'malformed CSI fallback': '\x1b[31',
    'malformed UTF16 fallback': '\ud800',
    'clipped wide fallback': '${'x' * 11}界',
  };
  for (final entry in cases.entries) {
    for (final foreground in [false, true]) {
      test(
        '${entry.key}, foreground=$foreground matches two-grid composition',
        () {
          // The last row forces exact full-size geometry for eligible content;
          // the first row still exercises padding and transparent source cells.
          final source = '${entry.value}\n${' ' * width}';
          final actual = renderContainerContent(
            contentStr: source,
            width: width,
            height: height,
            background: Colors.blue,
            foreground: foreground ? Colors.white : null,
          );
          final expected = _reference(source, width, height, foreground);
          final actualCells = Canvas(width, height);
          final expectedCells = Canvas(width, height);
          addTearDown(actualCells.dispose);
          addTearDown(expectedCells.dispose);
          StyledString(actual).draw(actualCells, actualCells.bounds());
          StyledString(expected).draw(expectedCells, expectedCells.bounds());
          for (var y = 0; y < height; y++) {
            for (var x = 0; x < width; x++) {
              final a = actualCells.cellAt(x, y)!;
              final e = expectedCells.cellAt(x, y)!;
              expect(
                (a.content, a.width, a.style, a.link),
                (e.content, e.width, e.style, e.link),
                reason: 'cell ($x, $y)',
              );
            }
          }
        },
      );
    }
  }

  test('direct composition releases temporary hyperlink ownership', () {
    const link = Link(
      url: 'https://direct-composition.example',
      params: 'id=x',
    );
    final probe = Cell(link: link);
    addTearDown(probe.dispose);
    final id = probe.linkId!;
    final baseline = debugLinkRefCount(id);
    final result = renderContainerContent(
      contentStr:
          '\x1b]8;id=x;${link.url}\x1b\\A${' ' * 11}'
          '\x1b]8;;\x1b\\\n${' ' * width}',
      width: width,
      height: height,
      background: Colors.blue,
    );

    expect(result, contains(link.url));
    expect(debugLinkRefCount(id), baseline);
  });
}

String _reference(String content, int width, int height, bool foreground) {
  final canvas = Canvas(width, height);
  final style = UvStyle(
    bg: colorToUvColor(Colors.blue),
    fg: foreground ? colorToUvColor(Colors.white) : null,
  );
  final fill = Cell(content: ' ', style: style);
  try {
    canvas.fill(fill);
    // Keep using the established two-grid implementation as the reference,
    // independent of the optimized renderContainerContent entrypoint.
    drawStyledContent(
      canvas,
      content,
      0,
      0,
      style,
      contentWidth: Layout.getWidth(content),
      contentHeight: Layout.getHeight(content),
    );
    return padToWidth(canvas.render(), width, height);
  } finally {
    fill.dispose();
    canvas.dispose();
  }
}
