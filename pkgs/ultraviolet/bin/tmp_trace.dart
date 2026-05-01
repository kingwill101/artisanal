import 'dart:io' show Platform;
import 'package:ultraviolet/src/uv/uv.dart';

final class _Sink implements StringSink {
  final StringBuffer b = StringBuffer();
  String get value => b.toString();
  void reset() => b.clear();
  @override
  void write(Object? obj) => b.write(obj);
  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      b.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => b.writeCharCode(charCode);
  @override
  void writeln([Object? obj = '']) => b.writeln(obj);
}

String repr(String s) {
  return s.runes.map((r) {
    if (r == 13) return '\\r';
    if (r == 10) return '\\n';
    if (r >= 32 && r <= 126) return String.fromCharCode(r);
    return '\\x${r.toRadixString(16).padLeft(2, '0')}';
  }).join();
}

void main() {
  final sink = _Sink();
  final r = UvTerminalRenderer(
    sink,
    env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
  );
  r.setScrollOptim(!Platform.isWindows);
  r.setRelativeCursor(true);

  final scr = ScreenBuffer(10, 5);

  final c1 = newStyledString('ABC');
  c1.draw(scr, scr.bounds());
  r.render(scr.buffer);
  r.flush();
  print('A=${repr(sink.value)}');

  sink.b.clear();
  final c2 = newStyledString('XXX');
  c2.draw(scr, scr.bounds());
  r.render(scr.buffer);
  r.flush();
  print('B=${repr(sink.value)}');
}
