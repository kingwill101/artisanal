import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  test('fromCells factories support resizing and idempotent disposal', () {
    final source = Cell(
      content: 'A',
      link: const Link(url: 'https://factory-ownership.test'),
    );
    addTearDown(source.dispose);
    final id = source.linkId!;

    final line = Line.fromCells([source]);
    expect(debugLinkRefCount(id), 2);
    line.dispose();
    line.dispose();
    expect(debugLinkRefCount(id), 1);
    expect(source.content, 'A');

    final buffer = Buffer.fromCells([
      [source],
    ]);
    expect(debugLinkRefCount(id), 2);
    buffer.resize(2, 2);
    expect(debugLinkRefCount(id), 2);
    expect(buffer.cellAt(0, 0)!.content, 'A');
    buffer.resize(0, 0);
    expect(debugLinkRefCount(id), 1);
    buffer.dispose();
    buffer.dispose();
    expect(source.content, 'A');
  });
}
