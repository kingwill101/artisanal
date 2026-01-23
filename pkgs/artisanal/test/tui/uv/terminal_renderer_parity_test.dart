import 'package:artisanal/src/colorprofile/profile.dart' as cp;
import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/terminal_renderer_test.go`

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
  test('UvTerminalRenderer parity: simple renderer output', () {
    const w = 5;
    const h = 3;
    final out = _TestSink();
    final r = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );

    r.setFullscreen(true);
    r.setRelativeCursor(false);
    r.saveCursor();
    r.erase();
    r.resize(w, h);

    final buf = Buffer.create(w, h);
    final cell = Cell(content: 'X', width: 1);
    buf.setCell(0, 0, cell);
    buf.setCell(1, 1, cell);
    buf.setCell(2, 2, cell);

    r.render(buf);
    r.flush();

    expect(out.value, '\x1b[H\x1b[2JX\nX\nX');
  });

  test('UvTerminalRenderer parity: inline renderer output', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );

    r.setRelativeCursor(true);
    r.resize(80, 24);

    final buf = Buffer.create(80, 3);
    for (var i = 0; i < 'Hello, World!'.length; i++) {
      buf.setCell(i, 0, Cell(content: 'Hello, World!'[i], width: 1));
    }

    r.render(buf);
    r.flush();

    expect(out.value, '\rHello, World!\r\n\n');
  });

  test('UvTerminalRenderer parity: color profile setter', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    r.setColorProfile(cp.Profile.trueColor);

    final buf = Buffer.create(1, 1);
    buf.setCell(
      0,
      0,
      Cell(
        content: 'X',
        width: 1,
        style: const UvStyle(fg: UvRgb(255, 0, 0)),
      ),
    );
    r.render(buf);
    r.flush();

    expect(out.value, contains('X'));
  });

  test('UvTerminalRenderer parity: position and setPosition', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    expect(r.position(), (x: -1, y: -1));
    r.setPosition(5, 10);
    expect(r.position(), (x: 5, y: 10));
  });

  test('UvTerminalRenderer parity: moveTo', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    r.moveTo(5, 3);
    r.flush();
    expect(out.value, contains('\x1b['));
  });

  test('UvTerminalRenderer parity: writeString and write', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);

    expect(r.writeString('Hello, World!'), 13);
    r.flush();
    expect(out.value, contains('Hello, World!'));

    out.reset();
    expect(r.write('Hello, World!'.codeUnits), 13);
    r.flush();
    expect(out.value, contains('Hello, World!'));
  });

  test('UvTerminalRenderer parity: redraw', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);

    final buf = Buffer.create(3, 1);
    buf.setCell(0, 0, Cell(content: 'X', width: 1));
    r.render(buf);
    r.flush();
    final first = out.value;

    out.reset();
    r.redraw(buf);
    r.flush();
    final second = out.value;

    expect(first, contains('X'));
    expect(second, contains('X'));
  });

  test('UvTerminalRenderer parity: capabilities', () {
    final out = _TestSink();
    final xterm = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    expect(
      xterm.capabilities & UvTerminalRenderer.capCha,
      UvTerminalRenderer.capCha,
    );

    final linux = UvTerminalRenderer(out, env: const ['TERM=linux']);
    expect(
      linux.capabilities & UvTerminalRenderer.capVpa,
      UvTerminalRenderer.capVpa,
    );
    expect(
      linux.capabilities & UvTerminalRenderer.capHpa,
      UvTerminalRenderer.capHpa,
    );
    expect(linux.capabilities & UvTerminalRenderer.capRep, 0);

    final alacritty = UvTerminalRenderer(out, env: const ['TERM=alacritty']);
    expect(alacritty.capabilities & UvTerminalRenderer.capCht, 0);

    final screen = UvTerminalRenderer(out, env: const ['TERM=screen']);
    expect(screen.capabilities & UvTerminalRenderer.capRep, 0);

    final tmux = UvTerminalRenderer(out, env: const ['TERM=tmux']);
    expect(
      tmux.capabilities & UvTerminalRenderer.capVpa,
      UvTerminalRenderer.capVpa,
    );
  });

  test('UvTerminalRenderer parity: touched count', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    final buf = Buffer.create(5, 3);

    expect(r.touched(buf), 0);

    final cell = Cell(content: 'X', width: 1);
    buf.setCell(0, 0, cell);
    buf.setCell(0, 2, cell);
    expect(r.touched(buf), 2);

    r.render(buf);
    expect(r.touched(buf), 3);

    var actualTouched = 0;
    for (final ld in buf.touched) {
      if (ld != null && (ld.firstCell != -1 || ld.lastCell != -1)) {
        actualTouched++;
      }
    }
    expect(actualTouched, 0);
  });

  test('UvTerminalRenderer parity: switch buffer', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);

    final small = Buffer.create(5, 3);
    final cell = Cell(content: 'X', width: 1);
    small.setCell(0, 0, cell);

    r.render(small);
    r.flush();

    final large = Buffer.create(10, 6);
    large.setCell(0, 1, cell);

    r.render(large);
    r.flush();

    expect(out.value, '\x1b[HX\r\n\n\x1b[J\x1bMX\x1b[K\r\n\n\n\n');
  });

  test('UvTerminalRenderer parity: phantom cursor', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    r.setColorProfile(cp.Profile.trueColor);
    r.setFullscreen(true);
    r.setRelativeCursor(false);

    final buf = Buffer.create(5, 3);
    final cell = Cell(content: 'X', width: 1);
    for (var y = 0; y < buf.height(); y++) {
      buf.setCell(4, y, cell);
    }

    r.render(buf);
    r.flush();

    expect(out.value, '\x1b[1;5HX\r\n\x1b[5GX\r\n\x1b[5G\x1b[?7lX\x1b[?7h');
  });

  test('UvTerminalRenderer parity: updates (upstream frames)', () {
    final cases = <({String name, List<String> frames, List<String> expected})>[
      (
        name: 'simple style change',
        frames: ['A', '\x1b[1mA'],
        expected: ['\rA\r\n\n', '\x1b[2A\x1b[1mA\x1b[m'],
      ),
      (
        name: 'style and link change',
        frames: [
          'A',
          '\x1b[31m\x1b]8;;https://example.com\x1b\\A\x1b]8;;\x1b\\',
        ],
        expected: [
          '\rA\r\n\n',
          '\x1b[2A\x1b[31m\x1b]8;;https://example.com\x07A\x1b[m\x1b]8;;\x07',
        ],
      ),
      (
        name: 'the same true color style frames',
        frames: [
          ' \x1b[38;2;255;128;0mABC\n DEF',
          ' \x1b[38;2;255;128;0mABC\n DEF',
          ' \x1b[38;2;255;128;0mABC\n DEF',
        ],
        expected: [
          '\r \x1b[38;5;208mABC\x1b[m\r\n\x1b[38;5;208m DEF\x1b[m\r\n',
          '',
          '',
        ],
      ),
    ];

    for (final tc in cases) {
      final out = _TestSink();
      final r = UvTerminalRenderer(
        out,
        env: const ['TERM=xterm-256color', 'TTY_FORCE=1'],
      );
      r.setRelativeCursor(true);

      final scr = ScreenBuffer(5, 3);
      for (var i = 0; i < tc.frames.length; i++) {
        final frame = newStyledString(tc.frames[i]);
        frame.draw(scr, scr.bounds());
        r.render(scr.buffer);
        r.flush();
        expect(out.value, tc.expected[i], reason: '${tc.name} frame[$i]');
        out.reset();
      }
    }
  });

  test('UvTerminalRenderer parity: prepend one line', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);

    r.resize(10, 5);
    final scr = ScreenBuffer(10, 5);
    newStyledString('This-is-a .').draw(scr, scr.bounds());
    r.render(scr.buffer);
    r.flush();

    newStyledString('This-is-a .').draw(scr, scr.bounds());
    r.prependString(scr.buffer, 'Prepended-a-new-line');
    r.render(scr.buffer);
    r.flush();

    expect(
      out.value,
      '\x1b[HThis-is-a\r\n\n\n\n\n\n\x1b[H\x1b[2LPrepended-a-new-line\r\n',
    );
  });

  test('UvTerminalRenderer parity: enter/exit alt screen', () {
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    final buf = Buffer.create(3, 3);

    r.moveTo(1, 1);
    expect(r.position(), (x: 1, y: 1));

    r.enterAltScreen();
    r.render(buf);

    expect(r.isFullscreenEnabled, isTrue);
    expect(r.position(), (x: 0, y: 0));

    r.exitAltScreen();
    expect(r.isRelativeCursorEnabled, isTrue);
    expect(r.position(), (x: 1, y: 1));

    r.flush();
    expect(out.value, '\x1b[2;2H\x1b[?1049h\x1b[H\x1b[2J\x1b[?1049l');
  });

  test('UvTerminalRenderer parity: phantom cursor handling', () {
    // Upstream: `third_party/ultraviolet/terminal_renderer_test.go`
    // (TestRendererPhantomCursor)
    final out = _TestSink();
    final r = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );
    r.setColorProfile(cp.Profile.trueColor);

    r.setFullscreen(true);
    r.setRelativeCursor(false);
    r.resize(5, 3);

    final cellbuf = Buffer.create(5, 3);
    final cell = Cell(content: 'X', width: 1);
    for (var y = 0; y < cellbuf.height(); y++) {
      cellbuf.setCell(4, y, cell);
    }

    r.render(cellbuf);
    r.flush();

    expect(out.value, '\x1b[1;5HX\r\n\x1b[5GX\r\n\x1b[5G\x1b[?7lX\x1b[?7h');
  });

  test('UvTerminalRenderer parity: resize with clear does not crash', () {
    // Regression: during a resize, the cursor can be outside the current buffer
    // when a full clear redraw happens. Upstream Buffer.Line returns nil; our
    // Dart port must not throw.
    final out = _TestSink();
    final r = UvTerminalRenderer(out, env: const ['TERM=xterm-256color']);
    r.setFullscreen(true);
    r.setRelativeCursor(false);
    r.resize(10, 5);

    final buf1 = Buffer.create(10, 5);
    buf1.setCell(0, 0, Cell(content: 'X', width: 1));
    r.render(buf1);
    r.flush();

    // Simulate UltravioletTuiRenderer resize path: `erase()` then render a smaller buffer.
    r.erase();
    final buf2 = Buffer.create(6, 2);
    buf2.setCell(0, 0, Cell(content: 'Y', width: 1));

    expect(() => r.render(buf2), returnsNormally);
    r.flush();
    expect(out.value, contains('Y'));
  });
}
