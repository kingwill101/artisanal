import 'dart:io' show Platform;

import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

final class _TestSink implements StringSink {
  final StringBuffer _b = StringBuffer();

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
  test('UvTerminalRenderer tolerates out-of-bounds cursor during updates', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);

    final b = Buffer.create(8, 5);
    b.setCell(0, 0, Cell(content: 'X', width: 1));
    r.render(b);
    r.flush();

    // Simulate a transient resize state where the cursor row is out of bounds.
    r.setPosition(0, b.height());

    // Force an update so rendering hits the code paths that consult the
    // current cursor position.
    b.setCell(1, 0, Cell(content: 'Y', width: 1));

    expect(() => r.render(b), returnsNormally);
  });

  test('UvTerminalRenderer tolerates shrinking buffer across frames', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    r.setFullscreen(true);

    final before = Buffer.create(12, 6);
    before.setCell(11, 5, Cell(content: 'Z', width: 1));
    r.render(before);
    r.flush();

    // Simulate cursor ending on the last cell, then shrink the buffer so both
    // x and y are out of bounds for the next frame.
    r.setPosition(before.width() - 1, before.height() - 1);

    final after = Buffer.create(5, 2);
    after.setCell(0, 0, Cell(content: 'A', width: 1));

    expect(() => r.render(after), returnsNormally);
    expect(() => r.flush(), returnsNormally);
  });

  test('UvTerminalRenderer tolerates far out-of-bounds cursor', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    r.setFullscreen(true);

    final b = Buffer.create(6, 3);
    b.setCell(0, 0, Cell(content: 'A', width: 1));
    r.render(b);
    r.flush();

    // Cursor can become garbage during rapid resizes; renderer must not crash.
    r.setPosition(b.width() + 50, b.height() + 50);
    b.setCell(1, 0, Cell(content: 'B', width: 1));

    expect(() => r.render(b), returnsNormally);
    expect(() => r.flush(), returnsNormally);
  });

  test('UvTerminalRenderer skips scroll optimization across resize', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    r.setFullscreen(true);
    r.setRelativeCursor(false);
    r.setScrollOptim(true);

    final before = Buffer.create(8, 5);
    before.setCell(0, 0, Cell(content: 'A', width: 1));
    r.render(before);
    r.flush();

    final after = Buffer.create(8, 6);
    after.setCell(0, 0, Cell(content: 'B', width: 1));

    // On non-Windows platforms, scroll optimization runs only in fullscreen
    // mode; it must not crash if the buffer size changes between frames.
    expect(() => r.render(after), returnsNormally);

    // Keep the test meaningful on Windows too (where scroll optimization is
    // disabled by default in the renderer).
    if (Platform.isWindows) {
      r.flush();
    }
  });
}
