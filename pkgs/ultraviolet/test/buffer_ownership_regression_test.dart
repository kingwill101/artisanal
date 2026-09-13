import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

void main() {
  test('resize and dispose release removed rows and are idempotent', () {
    final cell = Cell(
      content: 'x',
      link: const Link(url: 'https://example.test/resize'),
      width: 1,
    );
    final linkId = cell.linkId!;
    final buffer = Buffer.create(2, 2);
    buffer.setCellOwned(0, 1, cell);

    buffer.resize(2, 1);
    expect(debugLinkRefCount(linkId), 0);
    buffer.dispose();
    buffer.dispose();
    expect(debugLinkRefCount(linkId), 0);
  });

  test('borrowed cells remain valid independently of buffer disposal', () {
    final cell = Cell(
      content: 'x',
      link: const Link(url: 'https://example.test/borrowed'),
      width: 1,
    );
    final linkId = cell.linkId!;
    final buffer = Buffer.create(1, 1);
    buffer.setCell(0, 0, cell);

    cell.dispose();
    expect(debugLinkRefCount(linkId), 1);
    buffer.dispose();
    expect(debugLinkRefCount(linkId), 0);
  });

  test('owned equal cell is consumed without changing the stored cell', () {
    final buffer = Buffer.create(1, 1);
    final first = Cell(
      content: 'x',
      link: const Link(url: 'https://example.test/equal'),
      width: 1,
    );
    final linkId = first.linkId!;
    buffer.setCellOwned(0, 0, first);
    final equal = Cell(
      content: 'x',
      link: const Link(url: 'https://example.test/equal'),
      width: 1,
    );

    buffer.setCellOwned(0, 0, equal);
    expect(debugLinkRefCount(linkId), 1);
    buffer.dispose();
    expect(debugLinkRefCount(linkId), 0);
  });

  test('opacity replacement releases transient owned cells', () {
    final buffer = Buffer.create(1, 1);
    buffer.pushOpacity(0.5);
    final cell = Cell(
      content: 'x',
      style: const UvStyle(fg: UvRgb(255, 0, 0)),
      link: const Link(url: 'https://example.test/opacity'),
      width: 1,
    );
    final linkId = cell.linkId!;
    buffer.setCellOwned(0, 0, cell);

    expect(debugLinkRefCount(linkId), 1);
    buffer.clear();
    expect(debugLinkRefCount(linkId), 0);
    buffer.dispose();
  });

  test('wide overwrite snapshots metadata before disposing the origin', () {
    final line = Line.filled(4);
    final wide = Cell(
      content: '你',
      width: 2,
      link: const Link(url: 'https://example.test/wide'),
    );
    final linkId = wide.linkId!;
    line.setOwned(1, wide);
    line.set(1, Cell(content: 'a', width: 1));

    expect(line.at(1)!.content, 'a');
    expect(debugLinkRefCount(linkId), 1);
    line.dispose();
    expect(debugLinkRefCount(linkId), 0);
  });
}
