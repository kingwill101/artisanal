import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

void main() {
  test('captures colon-form SGR underline and RGB parameters', () {
    final capture = TerminalCapture.fromAnsi(
      '\x1b[4:3m\x1b[38:2::10:20:30mA\x1b[0m',
      columns: 1,
      rows: 1,
    );
    final style = capture.toBuffer().cellAt(0, 0)!.style;
    expect(style.underline, uv.UnderlineStyle.curly);
    expect(style.fg, const uv.UvRgb(10, 20, 30));
  });

  test(
    'JSON round trip preserves styles, links, wide cells, and diff options',
    () {
      final source = uv.Buffer.fromCells([
        [
          uv.Cell(
            content: '界',
            width: 2,
            style: const uv.UvStyle(
              fg: uv.UvColor.indexed256(123),
              bg: uv.UvColor.basic16(2, bright: true),
              underlineColor: uv.UvColor.rgb(1, 2, 3),
              underline: uv.UnderlineStyle.curly,
              attrs: uv.Attr.bold | uv.Attr.italic,
            ),
            link: const uv.Link(url: 'https://example.test', params: 'id=x'),
            diffOption: uv.CellDiffOption.forcedWidth(2),
          ),
          uv.Cell(content: '', width: 0),
          uv.Cell(content: 'é', width: 1),
        ],
      ]);
      final capture = TerminalCapture.fromBuffer(source);
      final copy = TerminalCapture.fromJson(capture.toJson());
      expect(copy.toJson(), equals(capture.toJson()));

      source.cellAt(0, 0)!.content = 'x';
      final detached = capture.toBuffer();
      expect(detached.cellAt(0, 0)!.content, '界');
      detached.cellAt(0, 0)!.content = 'y';
      expect(capture.toBuffer().cellAt(0, 0)!.content, '界');
    },
  );

  test('ANSI capture supports SGR, OSC 8, tabs, and newlines', () {
    final capture = TerminalCapture.fromAnsi(
      '\x1b[38;5;123;4mA\x1b[0m\t'
      '\x1b]8;;https://example.test\x1b\\B\x1b]8;;\x1b\\\nC',
      columns: 12,
      rows: 2,
    );
    final buffer = capture.toBuffer();
    expect(buffer.cellAt(0, 0)!.content, 'A');
    expect(buffer.cellAt(0, 0)!.style.fg, const uv.UvColor.indexed256(123));
    expect(buffer.cellAt(0, 0)!.style.underline, uv.UnderlineStyle.single);
    expect(buffer.cellAt(5, 0)!.content, 'B');
    expect(buffer.cellAt(5, 0)!.link.url, 'https://example.test');
    expect(buffer.cellAt(0, 1)!.content, 'C');
  });

  test('ANSI cursor and graphics controls are rejected', () {
    expect(
      () => TerminalCapture.fromAnsi('\x1b[2J', columns: 2, rows: 1),
      throwsFormatException,
    );
    expect(
      () => TerminalCapture.fromAnsi('\x1b_Gf=100\x1b\\', columns: 2, rows: 1),
      throwsFormatException,
    );
  });

  test('malformed JSON is rejected before accepting invalid grids', () {
    expect(
      () => TerminalCapture.fromJson({
        'version': 1,
        'columns': 2,
        'rows': 1,
        'cells': [[]],
      }),
      throwsFormatException,
    );
    expect(
      () => TerminalCapture.fromJson({
        'version': 99,
        'columns': 0,
        'rows': 0,
        'cells': [],
      }),
      throwsFormatException,
    );
  });

  test('dimensions and cell widths use one bounded positive domain', () {
    expect(
      () => TerminalCapture.fromAnsi('', columns: 0, rows: 1),
      throwsFormatException,
    );
    expect(
      () => TerminalCapture.fromJson({
        'version': 1,
        'columns': 1,
        'rows': 0,
        'cells': [],
      }),
      throwsFormatException,
    );
    final source = uv.Buffer.fromCells([
      [uv.Cell(content: 'x', width: 6)],
    ]);
    expect(() => TerminalCapture.fromBuffer(source), throwsFormatException);
    expect(
      () => TerminalCapture.fromJson({
        'version': 1,
        'columns': 1,
        'rows': 1,
        'cells': [
          [
            {
              'content': '',
              'width': 0,
              'style': {
                'fg': null,
                'bg': null,
                'underlineColor': null,
                'underline': 'none',
                'attrs': 0,
              },
              'link': {'url': '', 'params': ''},
              'diff': {'kind': 'forcedWidth', 'width': 0},
            },
          ],
        ],
      }),
      throwsFormatException,
    );
  });

  test('ANSI rejects controls and unsafe OSC 8 payloads', () {
    for (final input in <String>['a\x07', 'a\b', 'a\r', '\x1b[2J']) {
      expect(
        () => TerminalCapture.fromAnsi(input, columns: 2, rows: 1),
        throwsFormatException,
      );
    }
    expect(
      () => TerminalCapture.fromAnsi(
        '\x1b]8;;https://example.test\nunsafe\x07',
        columns: 2,
        rows: 1,
      ),
      throwsFormatException,
    );
    expect(
      () => TerminalCapture.fromAnsi('a\r\nb', columns: 2, rows: 2),
      returnsNormally,
    );
  });

  test(
    'captures BEL and ST terminated hyperlinks without accepting raw BEL',
    () {
      for (final end in ['\x07', '\x1b\\']) {
        final capture = TerminalCapture.fromAnsi(
          '\x1b]8;id=link;https://example.test${end}A\x1b]8;;${end}B',
          columns: 2,
          rows: 1,
        );
        final buffer = capture.toBuffer();
        expect(buffer.cellAt(0, 0)!.content, 'A');
        expect(buffer.cellAt(0, 0)!.link.url, 'https://example.test');
        expect(buffer.cellAt(0, 0)!.link.params, 'id=link');
        expect(buffer.cellAt(1, 0)!.content, 'B');
        expect(buffer.cellAt(1, 0)!.link.isZero, isTrue);
      }
    },
  );

  test('JSON rejects unknown attributes and control-bearing links', () {
    final cell = <String, Object?>{
      'content': '',
      'width': 0,
      'style': {
        'fg': null,
        'bg': null,
        'underlineColor': null,
        'underline': 'none',
        'attrs': 1 << 20,
      },
      'link': {'url': '', 'params': ''},
      'diff': {'kind': 'normal'},
    };
    expect(
      () => TerminalCapture.fromJson({
        'version': 1,
        'columns': 1,
        'rows': 1,
        'cells': [
          [cell],
        ],
      }),
      throwsFormatException,
    );
    cell['style'] = {
      'fg': null,
      'bg': null,
      'underlineColor': null,
      'underline': 'none',
      'attrs': 0,
    };
    cell['link'] = {'url': 'https://safe.test', 'params': '\x1b'};
    expect(
      () => TerminalCapture.fromJson({
        'version': 1,
        'columns': 1,
        'rows': 1,
        'cells': [
          [cell],
        ],
      }),
      throwsFormatException,
    );
  });
}
