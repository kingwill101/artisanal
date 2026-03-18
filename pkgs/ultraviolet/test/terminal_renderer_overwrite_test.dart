import 'package:ultraviolet/src/uv/uv.dart';
import 'package:test/test.dart';

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

void main() {
  test(
    'UvTerminalRenderer overwrites printable cells instead of moving cursor',
    () {
      final out = _TestSink();
      final renderer = UvTerminalRenderer(
        out,
        env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
      );

      renderer.setFullscreen(true);
      renderer.setRelativeCursor(false);
      renderer.saveCursor();
      renderer.erase();

      final first = Buffer.create(10, 1);
      for (var i = 0; i < 5; i++) {
        first.setCell(i, 0, Cell(content: 'ABCDE'[i], width: 1));
      }
      renderer.render(first);
      renderer.flush();

      out.reset();
      renderer.setPosition(0, 0);

      final second = Buffer.create(10, 1);
      second.setCell(0, 0, Cell(content: 'A', width: 1));
      second.setCell(1, 0, Cell(content: 'Z', width: 1));
      second.setCell(2, 0, Cell(content: 'C', width: 1));
      second.setCell(3, 0, Cell(content: 'D', width: 1));
      second.setCell(4, 0, Cell(content: 'E', width: 1));

      renderer.render(second);
      renderer.flush();

      expect(out.value, startsWith('AZ'));
      expect(out.value, isNot(contains('\x1b[2G')));
      expect(out.value, isNot(contains('\x1b[2C')));
    },
  );

  test('UvTerminalRenderer does not overwrite whitespace to move cursor', () {
    final out = _TestSink();
    final renderer = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );

    renderer.setFullscreen(true);
    renderer.setRelativeCursor(false);
    renderer.saveCursor();
    renderer.erase();

    final first = Buffer.create(6, 1);
    first.setCell(2, 0, Cell(content: 'A', width: 1));
    renderer.render(first);
    renderer.flush();

    out.reset();
    renderer.setPosition(0, 0);

    final second = Buffer.create(6, 1);
    second.setCell(2, 0, Cell(content: 'Z', width: 1));
    renderer.render(second);
    renderer.flush();

    expect(out.value, isNot(startsWith('  Z')));
    expect(
      out.value,
      anyOf(contains('\x1b[3G'), contains('\x1b[2C'), contains('\x1b[3`')),
    );
  });
}
