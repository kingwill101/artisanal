import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

final class _TestSink implements StringSink {
  final StringBuffer _b = StringBuffer();

  String get value => _b.toString();

  void reset() => _b.clear();

  @override
  void write(Object? obj) => _b.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _b.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _b.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) => _b.writeln(obj);
}

void main() {
  test(
    'UvTerminalRenderer default does not emit synchronized update markers',
    () {
      final out = _TestSink();
      final r = UvTerminalRenderer(
        out,
        env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
      );
      final buf = Buffer.create(4, 1);
      buf.setCell(0, 0, Cell(content: 'X'));

      r.render(buf);
      r.flush();

      expect(out.value, isNot(contains(UvAnsi.beginSynchronizedUpdate)));
      expect(out.value, isNot(contains(UvAnsi.endSynchronizedUpdate)));
    },
  );

  test(
    'UvTerminalRenderer wraps rendered frames when synchronized output is enabled',
    () {
      final out = _TestSink();
      final r = UvTerminalRenderer(
        out,
        env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
      );
      r.setSynchronizedOutput(true);
      final buf = Buffer.create(4, 1);
      buf.setCell(0, 0, Cell(content: 'X'));

      r.render(buf);
      r.flush();

      final s = out.value;
      final begin = s.indexOf(UvAnsi.beginSynchronizedUpdate);
      final end = s.indexOf(UvAnsi.endSynchronizedUpdate);
      expect(begin, isNonNegative);
      expect(end, greaterThan(begin));
    },
  );

  test(
    'UvTerminalRenderer emits nothing for skipped frames even with synchronized output enabled',
    () {
      final out = _TestSink();
      final r = UvTerminalRenderer(
        out,
        env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
      );
      r.setSynchronizedOutput(true);
      final buf = Buffer.create(4, 1);
      buf.setCell(0, 0, Cell(content: 'X'));

      r.render(buf);
      r.flush();
      out.reset();

      // Rendering the same untouched buffer should be skipped.
      r.render(buf);
      r.flush();

      expect(out.value, isEmpty);
    },
  );
}
