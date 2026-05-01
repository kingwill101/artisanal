import 'package:artisanal/runtime.dart';
import 'package:artisanal/src/uv/buffer.dart' as uv_buffer;
import 'package:artisanal/src/uv/cell.dart';
import 'package:test/test.dart';

void main() {
  group('TerminalNativeFrame', () {
    test('captures styled and linked cells from a buffer', () {
      final buffer = uv_buffer.Buffer.create(4, 1);
      buffer.setCell(
        0,
        0,
        Cell(
          content: 'A',
          style: const UvStyle(
            fg: UvColor.basic16(1),
            bg: UvColor.rgb(1, 2, 3),
            attrs: Attr.bold,
          ),
          link: const Link(url: 'https://example.com'),
          width: 1,
        ),
      );

      final frame = TerminalNativeFrame.fromBuffer(buffer);
      final cell = frame.lines.single.cells.first;

      expect(frame.width, 4);
      expect(frame.height, 1);
      expect(cell.content, 'A');
      expect(cell.width, 1);
      expect(cell.style.fg?.kind, 'basic16');
      expect(cell.style.fg?.index, 1);
      expect(cell.style.bg?.kind, 'rgb');
      expect(cell.style.bg?.r, 1);
      expect(cell.style.attrs, Attr.bold);
      expect(cell.link.url, 'https://example.com');
      expect(cell.isZero, isFalse);
      expect(cell.packed, hasLength(4));
    });

    test('preserves zero-width placeholders for wide cells', () {
      final buffer = uv_buffer.Buffer.create(4, 1);
      buffer.setCell(0, 0, Cell(content: '🙂', width: 2));

      final frame = TerminalNativeFrame.fromBuffer(buffer);
      final cells = frame.lines.single.cells;

      expect(cells[0].content, '🙂');
      expect(cells[0].width, 2);
      expect(cells[1].isZero, isTrue);
      expect(frame.lines.single.plainText, '🙂  ');
    });

    test('captures dirty spans from UV buffers', () {
      final buffer = uv_buffer.Buffer.create(5, 1);
      buffer.setCell(1, 0, Cell(content: 'x', width: 1));
      buffer.setCell(2, 0, Cell(content: 'y', width: 1));

      final frame = TerminalNativeFrame.fromBuffer(buffer);
      final spans = frame.lines.single.dirtySpans;

      expect(spans, isNotEmpty);
      expect(spans.first.start, lessThanOrEqualTo(1));
      expect(spans.first.end, greaterThanOrEqualTo(3));
    });

    test('can produce a delta frame from dirty UV lines', () {
      final buffer = uv_buffer.Buffer.create(5, 2);
      buffer.setCell(2, 1, Cell(content: 'z', width: 1));

      final delta = TerminalNativeDeltaFrame.fromBuffer(buffer);

      expect(delta.isEmpty, isFalse);
      expect(delta.lines, hasLength(1));
      expect(delta.lines.single.index, 1);
      expect(delta.lines.single.plainText, contains('z'));
    });

    test('can compute changed cells between frames', () {
      final previous = TerminalNativeFrame.inspect('ab', width: 3, height: 1);
      final current = TerminalNativeFrame.inspect('ax', width: 3, height: 1);

      final delta = TerminalNativeCellDeltaFrame.between(previous, current);

      expect(delta.isEmpty, isFalse);
      expect(delta.lines, hasLength(1));
      expect(delta.lines.single.index, 0);
      expect(delta.lines.single.cells, hasLength(1));
      expect(delta.lines.single.cells.single.column, 1);
      expect(delta.lines.single.cells.single.previous?.content, 'b');
      expect(delta.lines.single.cells.single.current?.content, 'x');
    });

    test('can group changed cells into semantic spans', () {
      final previous = TerminalNativeFrame.inspect('ab  ', width: 4, height: 1);
      final current = TerminalNativeFrame.inspect(
        '\x1b[31mxy\x1b[0m  ',
        width: 4,
        height: 1,
      );

      final delta = TerminalNativeCellDeltaFrame.between(previous, current);
      final spans = delta.spanDeltas;

      expect(spans, hasLength(1));
      expect(spans.single.index, 0);
      expect(spans.single.spans, hasLength(1));
      expect(spans.single.spans.single.startColumn, 0);
      expect(spans.single.spans.single.endColumn, 2);
      expect(spans.single.spans.single.text, 'xy');
      expect(spans.single.spans.single.style.fg?.index, 1);
    });

    test('can inspect rendered content through a temporary screen buffer', () {
      final frame = TerminalNativeFrame.inspect(
        const View(content: '\x1b[31mred'),
        width: 4,
        height: 1,
      );

      expect(frame.lines.single.cells[0].content, 'r');
      expect(frame.lines.single.cells[0].style.fg?.kind, 'basic16');
      expect(frame.lines.single.cells[0].style.fg?.index, 1);
      expect(frame.plainText, 'red ');
    });
  });
}
