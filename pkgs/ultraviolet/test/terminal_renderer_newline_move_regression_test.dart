import 'package:ultraviolet/src/uv/uv.dart';
import 'package:test/test.dart';

// Regression for the Windows column-desync bug (upstream issue #8): the
// renderer used to move the cursor down a row with a lone LF while planning
// the rest of the move from the old column. Cooked consoles (Windows among
// them) expand LF to CR+LF, so the real cursor landed at column 0 and the
// next cell painted at the left edge. Every emitted LF must now arrive as an
// explicit CR+LF pair, which behaves identically whether or not the terminal
// expands LF.

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
  test('downward moves never rely on a lone LF keeping the column', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );
    r.setScrollOptim(false);
    r.setFullscreen(true);
    r.saveCursor();
    r.erase();

    final scr = ScreenBuffer(100, 6);

    // Frame A: a single cell mid-screen leaves the cursor just right of it.
    newStyledString('A').draw(scr, rect(50, 2, 1, 1));
    r.render(scr.buffer);
    r.flush();
    final frameA = out.value;

    // Frame B: the next dirty cell sits one row below, at exactly the column
    // the previous frame ended on. This is the shape where a lone LF used to
    // win the move-sequence price contest (one byte beats every absolute
    // candidate), desyncing the column on cooked terminals.
    newStyledString('B').draw(scr, rect(51, 3, 1, 1));
    out.reset();
    r.render(scr.buffer);
    r.flush();
    final frameB = out.value;

    expect(frameB, contains('B'), reason: 'frame B must still draw its cell');

    for (final (name, frame) in [('frame A', frameA), ('frame B', frameB)]) {
      for (var i = 0; i < frame.length; i++) {
        if (frame.codeUnitAt(i) != 0x0A) continue;
        final prevIsCr = i > 0 && frame.codeUnitAt(i - 1) == 0x0D;
        expect(
          prevIsCr,
          isTrue,
          reason:
              '$name emits a lone LF at offset $i; a downward move may not '
              'assume LF preserves the cursor column',
        );
      }
    }
  });
}
