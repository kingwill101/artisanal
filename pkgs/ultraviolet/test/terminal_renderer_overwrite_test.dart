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
        env: const [
          'TERM=xterm-256color',
          'COLORTERM=truecolor',
          'TTY_FORCE=1',
        ],
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

  test(
    'UvTerminalRenderer clamps oversized RGB channels before writing SGR',
    () {
      final out = _TestSink();
      final renderer = UvTerminalRenderer(
        out,
        env: const [
          'TERM=xterm-256color',
          'COLORTERM=truecolor',
          'TTY_FORCE=1',
        ],
      );

      renderer.setFullscreen(true);
      renderer.setRelativeCursor(false);
      renderer.saveCursor();
      renderer.erase();

      final buffer = Buffer.create(1, 1);
      buffer.setCell(
        0,
        0,
        Cell(
          content: 'X',
          width: 1,
          style: const UvStyle(fg: UvRgb(57531, -1, 999999)),
        ),
      );

      renderer.render(buffer);
      renderer.flush();

      expect(out.value, contains('\x1b[38;2;255;0;255mX'));
    },
  );

  test('UvTerminalRenderer cached style transitions preserve output', () {
    final out = _TestSink();
    final renderer =
        UvTerminalRenderer(
            out,
            env: const [
              'TERM=xterm-256color',
              'COLORTERM=truecolor',
              'TTY_FORCE=1',
            ],
          )
          ..setFullscreen(true)
          ..setRelativeCursor(false)
          ..erase()
          ..resize(4, 1);
    final first = Buffer.create(4, 1, tracksDirty: false);
    final second = Buffer.create(4, 1, tracksDirty: false);
    for (var x = 0; x < 4; x++) {
      first.setCell(
        x,
        0,
        Cell.asciiStyled(
          0x41 + x,
          style: UvStyle(
            fg: UvColor.rgb(20 + x, 40 + x, 60 + x),
            bg: UvColor.rgb(80 + x, 100 + x, 120 + x),
            attrs: x.isEven ? Attr.bold : Attr.italic,
          ),
        ),
      );
      second.setCell(
        x,
        0,
        Cell.asciiStyled(
          0x57 + x,
          style: UvStyle(
            fg: UvColor.rgb(140 + x, 160 + x, 180 + x),
            bg: UvColor.rgb(200 + x, 220 + x, 240 + x),
            attrs: x.isEven ? Attr.italic : 0,
          ),
        ),
      );
    }

    renderer
      ..render(first)
      ..flush();
    out.reset();
    renderer
      ..render(second)
      ..flush();
    final uncachedOutput = out.value;

    out.reset();
    renderer
      ..render(first)
      ..flush();
    out.reset();
    renderer
      ..render(second)
      ..flush();

    expect(out.value, uncachedOutput);
    expect(out.value, contains('\x1b['));
    expect(out.value, contains('W'));
    expect(out.value, contains('Z'));
  });

  test('style caches distinguish decorations on the same color', () {
    const decorated = UvStyle(
      fg: UvColor.indexed256(99),
      underline: UnderlineStyle.single,
      attrs: Attr.bold,
    );
    const plain = UvStyle(fg: UvColor.indexed256(99), attrs: Attr.bold);

    final decoratedCell = Cell.asciiStyled(0x55, style: decorated);
    final plainCell = Cell.asciiStyled(0x50, style: plain);
    expect(decoratedCell, isNot(plainCell));
    expect(decoratedCell.styleId, isNot(plainCell.styleId));

    final out = _TestSink();
    final renderer = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor', 'TTY_FORCE=1'],
    )..setFullscreen(true);
    renderer.resetForResize(4, 2);

    final buffer = Buffer.create(4, 2)
      ..setCell(0, 0, decoratedCell)
      ..setCell(0, 1, plainCell);
    renderer.render(buffer);
    renderer.flush();

    expect(out.value, contains('\x1b[1;4;38;5;99mU'));
    expect(out.value, contains('\x1b[1;38;5;99mP'));
    expect(out.value, isNot(contains('\x1b[1;4;38;5;99mP')));
  });

  test('UvTerminalRenderer uses direct truecolor transitions', () {
    final out = _TestSink();
    final renderer =
        UvTerminalRenderer(
            out,
            env: const [
              'TERM=xterm-256color',
              'COLORTERM=truecolor',
              'TTY_FORCE=1',
            ],
          )
          ..setFullscreen(true)
          ..setRelativeCursor(false)
          ..resize(2, 1);
    final first = Buffer.create(2, 1, tracksDirty: false);
    final second = Buffer.create(2, 1, tracksDirty: false);
    first.setCell(
      0,
      0,
      Cell.asciiStyled(
        0x41,
        style: const UvStyle(
          fg: UvColor.rgb(10, 20, 30),
          bg: UvColor.rgb(40, 50, 60),
        ),
      ),
    );
    second.setCell(
      0,
      0,
      Cell.asciiStyled(
        0x42,
        style: const UvStyle(
          fg: UvColor.rgb(70, 80, 90),
          bg: UvColor.rgb(100, 110, 120),
        ),
      ),
    );

    renderer
      ..render(first)
      ..flush();
    out.reset();
    renderer
      ..render(second)
      ..flush();

    expect(out.value, contains('\x1b[38;2;70;80;90;48;2;100;110;120m'));
  });

  test('UvTerminalRenderer advances after Kitty no-cursor display cells', () {
    const kitty = '\x1b_Ga=T,f=100,i=7,c=3,r=1,C=1,q=2,m=0;AAAA\x1b\\';
    final out = _TestSink();
    final renderer = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );

    renderer.setFullscreen(true);
    renderer.setRelativeCursor(false);
    renderer.saveCursor();
    renderer.erase();
    renderer.resize(8, 1);

    final buffer = Buffer.create(8, 1);
    buffer.setCell(0, 0, Cell(content: kitty, width: 3));
    buffer.setCell(3, 0, Cell(content: 'X', width: 1));

    renderer.render(buffer);
    renderer.flush();

    final output = out.value;
    final markerIndex = output.indexOf('X');
    final kittyIndex = output.indexOf(kitty);

    expect(output, contains('${UvAnsi.cursorForward(3)}X'));
    expect(output, contains('$kitty${UvAnsi.cursorForward(3)}'));
    expect(markerIndex, isNonNegative);
    expect(kittyIndex, isNonNegative);
    expect(kittyIndex, greaterThan(markerIndex));
  });

  test('UvTerminalRenderer defers sixel payloads and restores cursor', () {
    const sixel = 'Pq#0;2;0;0;0!1~\\';
    final out = _TestSink();
    final renderer = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );

    renderer.setFullscreen(true);
    renderer.setRelativeCursor(false);
    renderer.saveCursor();
    renderer.erase();
    renderer.resize(8, 1);

    final buffer = Buffer.create(8, 1);
    buffer.setCell(0, 0, Cell(content: sixel, width: 1));
    buffer.setCell(1, 0, Cell(content: 'X', width: 1));

    renderer.render(buffer);
    renderer.flush();

    final output = out.value;
    final markerIndex = output.indexOf('X');
    final sixelIndex = output.indexOf(sixel);

    expect(output, contains('${UvAnsi.cursorForward(1)}X'));
    expect(
      output,
      contains(
        '${UvAnsi.cursorPosition(1, 1)}$sixel${UvAnsi.cursorPosition(3, 1)}',
      ),
    );
    expect(markerIndex, isNonNegative);
    expect(sixelIndex, isNonNegative);
    expect(sixelIndex, greaterThan(markerIndex));
    expect(output, isNot(contains('\x1b7')));
    expect(output, isNot(contains('\x1b8')));
  });

  test(
    'UvTerminalRenderer forces full clear when sixel is present or removed',
    () {
      const sixel = 'Pq#0;2;0;0;0!1~\\';
      final out = _TestSink();
      final renderer = UvTerminalRenderer(
        out,
        env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
      );

      renderer.setFullscreen(true);
      renderer.setRelativeCursor(false);
      renderer.saveCursor();
      renderer.erase();
      renderer.resize(8, 1);

      final withSixel = Buffer.create(8, 1);
      withSixel.setCell(0, 0, Cell(content: sixel, width: 1));
      withSixel.setCell(1, 0, Cell(content: 'X', width: 1));
      renderer.render(withSixel);
      renderer.flush();

      out.reset();
      renderer.setPosition(0, 0);

      final withoutSixel = Buffer.create(8, 1);
      withoutSixel.setCell(0, 0, Cell(content: 'A', width: 1));
      renderer.render(withoutSixel);
      renderer.flush();

      expect(out.value, contains(UvAnsi.eraseEntireScreen));
      expect(out.value, contains('A'));
    },
  );

  test('UvTerminalRenderer notices sixel removal in a reused buffer', () {
    const sixel = '\x1bPq#0;2;0;0;0!1~\x1b\\';
    final out = _TestSink();
    final renderer = UvTerminalRenderer(
      out,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
    );

    renderer
      ..setFullscreen(true)
      ..setRelativeCursor(false)
      ..erase()
      ..resize(8, 1);
    final buffer = Buffer.create(8, 1)
      ..setCell(0, 0, Cell(content: sixel, width: 1));
    renderer
      ..render(buffer)
      ..flush();

    out.reset();
    buffer.setCell(0, 0, Cell(content: 'A', width: 1));
    renderer
      ..render(buffer)
      ..flush();

    expect(out.value, contains(UvAnsi.eraseEntireScreen));
    expect(out.value, contains('A'));
  });

  test('UvTerminalRenderer wraps sixel payloads for tmux passthrough', () {
    const sixel = 'Pq#0;2;0;0;0!1~\\';
    final out = _TestSink();
    final renderer = UvTerminalRenderer(
      out,
      env: const [
        'TERM=tmux-256color',
        'TMUX=/tmp/tmux-1000/default,123,0',
        'COLORTERM=truecolor',
      ],
    );

    renderer.setFullscreen(true);
    renderer.setRelativeCursor(false);
    renderer.saveCursor();
    renderer.erase();
    renderer.resize(8, 1);

    final buffer = Buffer.create(8, 1);
    buffer.setCell(0, 0, Cell(content: sixel, width: 1));
    renderer.render(buffer);
    renderer.flush();

    expect(out.value, contains('\x1bPtmux;'));
    expect(out.value, contains('\x1b\x1bPq#0;2;0;0;0!1~\x1b\x1b\\'));
  });
}
