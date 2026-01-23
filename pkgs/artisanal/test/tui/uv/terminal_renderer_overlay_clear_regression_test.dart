import 'package:artisanal/src/uv/buffer.dart' as uv_buffer;
import 'package:artisanal/src/uv/cell.dart';
import 'package:artisanal/src/uv/terminal_renderer.dart';
import 'package:test/test.dart';

final class _TakeSink implements StringSink {
  final StringBuffer _buf = StringBuffer();

  String take() {
    final s = _buf.toString();
    _buf.clear();
    return s;
  }

  @override
  void write(Object? obj) => _buf.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _buf.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _buf.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) => _buf.writeln(obj);
}

final class _TermGrid {
  _TermGrid(this.width, this.height)
    : _rows = List<List<String>>.generate(
        height,
        (_) => List<String>.filled(width, ' ', growable: false),
        growable: false,
      );

  final int width;
  final int height;
  final List<List<String>> _rows;

  int _x = 0;
  int _y = 0;

  void apply(String s) {
    var i = 0;
    while (i < s.length) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x1b /* ESC */ ) {
        i = _consumeEscape(s, i);
        continue;
      }
      if (ch == 0x0d /* CR */ ) {
        _x = 0;
        i++;
        continue;
      }
      if (ch == 0x0a /* LF */ ) {
        _y = (_y + 1).clamp(0, height - 1);
        i++;
        continue;
      }

      _putChar(String.fromCharCode(ch));
      i++;
    }
  }

  int _consumeEscape(String s, int i) {
    if (i + 1 >= s.length) return s.length;
    final next = s.codeUnitAt(i + 1);

    // CSI: ESC [
    if (next == 0x5b) {
      final end = _findCsiEnd(s, i + 2);
      if (end == -1) return s.length;
      final cmd = s.codeUnitAt(end);
      final paramsRaw = s.substring(i + 2, end);
      final params = _parseParams(paramsRaw);
      _applyCsi(cmd, params);
      return end + 1;
    }

    // OSC: ESC ] ... (BEL or ST)
    if (next == 0x5d) {
      // BEL-terminated.
      final bel = s.indexOf('\x07', i + 2);
      final st = s.indexOf('\x1b\\', i + 2);
      if (bel != -1 && (st == -1 || bel < st)) return bel + 1;
      if (st != -1) return st + 2;
      return s.length;
    }

    // Two-byte escapes we can ignore.
    return i + 2;
  }

  int _findCsiEnd(String s, int start) {
    for (var j = start; j < s.length; j++) {
      final c = s.codeUnitAt(j);
      // Final byte is in @..~.
      if (c >= 0x40 && c <= 0x7e) return j;
    }
    return -1;
  }

  List<int> _parseParams(String raw) {
    if (raw.isEmpty) return const [];
    // Ignore private prefixes like ?.
    final cleaned = raw.replaceAll(RegExp(r'[^0-9;]'), '');
    if (cleaned.isEmpty) return const [];
    return cleaned.split(';').map((p) => int.tryParse(p) ?? 0).toList();
  }

  void _applyCsi(int cmd, List<int> params) {
    // CUP (H/f): ESC [ <row> ; <col> H
    if (cmd == 0x48 /* H */ || cmd == 0x66 /* f */ ) {
      final row = (params.isEmpty ? 1 : params[0]).clamp(1, height);
      final col = (params.length < 2 ? 1 : params[1]).clamp(1, width);
      _y = row - 1;
      _x = col - 1;
      return;
    }

    // CHA (G): ESC [ <col> G
    if (cmd == 0x47 /* G */ ) {
      final col = (params.isEmpty ? 1 : params[0]).clamp(1, width);
      _x = col - 1;
      return;
    }

    // VPA (d): ESC [ <row> d
    if (cmd == 0x64 /* d */ ) {
      final row = (params.isEmpty ? 1 : params[0]).clamp(1, height);
      _y = row - 1;
      return;
    }

    // CUU/CUD/CUF/CUB: A/B/C/D
    final n = (params.isEmpty ? 1 : params[0]).clamp(1, 1000000);
    switch (cmd) {
      case 0x41: // A
        _y = (_y - n).clamp(0, height - 1);
        return;
      case 0x42: // B
        _y = (_y + n).clamp(0, height - 1);
        return;
      case 0x43: // C
        _x = (_x + n).clamp(0, width - 1);
        return;
      case 0x44: // D
        _x = (_x - n).clamp(0, width - 1);
        return;
      case 0x4b: // K (EL)
        _eraseLineRight();
        return;
      case 0x4a: // J (ED)
        _eraseScreenBelow();
        return;
      default:
        // Ignore other CSI sequences (SGR etc).
        return;
    }
  }

  void _eraseLineRight() {
    for (var x = _x; x < width; x++) {
      _rows[_y][x] = ' ';
    }
  }

  void _eraseScreenBelow() {
    _eraseLineRight();
    for (var y = _y + 1; y < height; y++) {
      for (var x = 0; x < width; x++) {
        _rows[y][x] = ' ';
      }
    }
  }

  void _putChar(String ch) {
    if (_x < 0 || _y < 0 || _x >= width || _y >= height) return;
    _rows[_y][_x] = ch;
    _x++;
    if (_x >= width) {
      _x = 0;
      _y = (_y + 1).clamp(0, height - 1);
    }
  }

  String dump() => _rows.map((r) => r.join()).join('\n');
}

void _drawAsciiBox(uv_buffer.Buffer b, int x, int y, int w, int h) {
  if (w < 2 || h < 2) return;
  final x2 = x + w - 1;
  final y2 = y + h - 1;

  b.setCell(x, y, Cell(content: '+', width: 1));
  b.setCell(x2, y, Cell(content: '+', width: 1));
  b.setCell(x, y2, Cell(content: '+', width: 1));
  b.setCell(x2, y2, Cell(content: '+', width: 1));

  for (var xx = x + 1; xx < x2; xx++) {
    b.setCell(xx, y, Cell(content: '-', width: 1));
    b.setCell(xx, y2, Cell(content: '-', width: 1));
  }
  for (var yy = y + 1; yy < y2; yy++) {
    b.setCell(x, yy, Cell(content: '|', width: 1));
    b.setCell(x2, yy, Cell(content: '|', width: 1));
  }
}

void _writeAsciiText(uv_buffer.Buffer b, int x, int y, String text) {
  for (var i = 0; i < text.length; i++) {
    b.setCell(x + i, y, Cell(content: text[i], width: 1));
  }
}

void main() {
  test('UvTerminalRenderer clears removed overlay content (no artifacts)', () {
    const w = 64;
    const h = 18;

    final sink = _TakeSink();
    final r =
        UvTerminalRenderer(
            sink,
            env: const ['TERM=xterm-256color', 'TTY_FORCE=1'],
            isTty: true,
          )
          ..setFullscreen(true)
          ..setRelativeCursor(false)
          ..setMapNewline(true)
          ..setScrollOptim(false)
          ..erase();

    final grid = _TermGrid(w, h);

    uv_buffer.Buffer base() {
      final b = uv_buffer.Buffer.create(w, h)..touched = const [];
      _writeAsciiText(b, 0, 0, 'HEADER');
      _writeAsciiText(b, 0, h - 1, 'STATUS LINE');
      for (var yy = 6; yy < 12; yy++) {
        _writeAsciiText(b, 0, yy, 'left');
      }
      return b;
    }

    final base1 = base();
    r.render(base1);
    r.flush();
    grid.apply(sink.take());

    final withOverlay = base();
    _drawAsciiBox(withOverlay, 18, 6, 28, 6);
    r.render(withOverlay);
    r.flush();
    grid.apply(sink.take());

    final base2 = base();
    r.render(base2);
    r.flush();
    grid.apply(sink.take());

    expect(grid.dump().contains('+--------------------------+'), isFalse);
    expect(grid.dump().contains('STATUS LINE'), isTrue);
  });
}
