import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

final class _TestSink implements StringSink {
  final StringBuffer _buffer = StringBuffer();

  String get value => _buffer.toString();

  void reset() => _buffer.clear();

  @override
  void write(Object? obj) => _buffer.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _buffer.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) => _buffer.writeln(obj);
}

UvTerminalRenderer _renderer(_TestSink sink) {
  final renderer = UvTerminalRenderer(
    sink,
    env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
  );
  renderer.setFullscreen(true);
  renderer.setRelativeCursor(false);
  return renderer;
}

void _render(UvTerminalRenderer renderer, Buffer buffer) {
  renderer.render(buffer);
  renderer.flush();
}

void main() {
  group('cell diff options', () {
    test('alwaysUpdate emits an unchanged cell on every frame', () {
      final sink = _TestSink();
      final renderer = _renderer(sink);

      Buffer frame() {
        final buffer = Buffer.create(3, 1);
        buffer.setCell(
          1,
          0,
          Cell(content: 'A', diffOption: CellDiffOption.alwaysUpdate),
        );
        return buffer;
      }

      _render(renderer, frame());
      sink.reset();
      _render(renderer, frame());

      expect(sink.value, contains('A'));
    });

    test('skip leaves externally owned cells untouched', () {
      final sink = _TestSink();
      final renderer = _renderer(sink);

      final first = Buffer.create(3, 1);
      for (var x = 0; x < 3; x++) {
        first.setCell(x, 0, Cell(content: 'abc'[x]));
      }
      _render(renderer, first);
      sink.reset();

      final second = Buffer.create(3, 1);
      second.setCell(0, 0, Cell(content: 'x'));
      second.setCell(1, 0, Cell(content: 'y', diffOption: CellDiffOption.skip));
      second.setCell(2, 0, Cell(content: 'z'));
      _render(renderer, second);

      expect(sink.value, contains('x'));
      expect(sink.value, contains('z'));
      expect(sink.value, isNot(contains('y')));
    });

    test('forcedWidth advances across covered trailing cells', () {
      final sink = _TestSink();
      final renderer = _renderer(sink);

      final first = Buffer.create(4, 1);
      for (var x = 0; x < 4; x++) {
        first.setCell(x, 0, Cell(content: 'abcd'[x]));
      }
      _render(renderer, first);
      sink.reset();

      final second = Buffer.create(4, 1);
      second.setCell(
        0,
        0,
        Cell(content: 'x', diffOption: CellDiffOption.forcedWidth(2)),
      );
      second.setCell(1, 0, Cell(content: 'b'));
      second.setCell(2, 0, Cell(content: 'c'));
      second.setCell(3, 0, Cell(content: 'd'));
      _render(renderer, second);

      expect(sink.value, contains('x'));
      expect(sink.value, isNot(contains('b')));
    });
  });

  test('shrinking a styled wide glyph emits its uncovered trailing cell', () {
    final sink = _TestSink();
    final renderer = _renderer(sink);
    const blue = UvStyle(bg: UvRgb(0, 0, 255));

    final before = Buffer.fromCells([
      [Cell(content: '＋', width: 2, style: blue), Cell.emptyCell()],
    ]);
    before.touchLine(0, 0, 2);
    _render(renderer, before);
    sink.reset();

    final after = Buffer.fromCells([
      [Cell(content: 'a'), Cell.emptyCell()],
    ]);
    after.touchLine(0, 0, 2);
    _render(renderer, after);

    expect(sink.value, contains('a'));
    expect(
      sink.value,
      contains('${UvAnsi.resetModeAutoWrap} ${UvAnsi.setModeAutoWrap}'),
    );
  });

  test('wide glyph inside a trailing range is not overwritten', () {
    final sink = _TestSink();
    final renderer = _renderer(sink);
    const blue = UvStyle(bg: UvRgb(0, 0, 255));

    final before = Buffer.fromCells([
      [
        Cell(content: '你', width: 2, style: blue),
        Cell.emptyCell(),
        Cell(content: '好', width: 2, style: blue),
        Cell.emptyCell(),
      ],
    ]);
    before.touchLine(0, 0, 4);
    _render(renderer, before);
    sink.reset();

    final after = Buffer.fromCells([
      [
        Cell(content: 'a', style: blue),
        Cell(content: '好', width: 2, style: blue),
        Cell.zeroCell(),
        Cell.emptyCell(),
      ],
    ]);
    after.touchLine(0, 0, 4);
    _render(renderer, after);

    expect(sink.value, contains('a'));
    expect(sink.value, contains('好'));
    expect(sink.value, isNot(contains('${UvAnsi.cursorPosition(3, 1)} ')));
  });
}
