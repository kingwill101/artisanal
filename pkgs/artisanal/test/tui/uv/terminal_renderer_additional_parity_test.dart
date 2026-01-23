import 'dart:io' show Platform;

import 'package:artisanal/src/colorprofile/profile.dart' as cp;
import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity (additional cases):
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

UvTerminalRenderer _newRenderer(_TestSink out, {List<String>? env}) {
  return UvTerminalRenderer(
    out,
    env:
        env ??
        const ['TERM=xterm-256color', 'TTY_FORCE=1', 'COLORTERM=truecolor'],
  );
}

void main() {
  group('UvTerminalRenderer parity (additional upstream cases)', () {
    test('TestRendererErase', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      final cellbuf = Buffer.create(3, 1);
      cellbuf.setCell(0, 0, Cell(content: 'X', width: 1));

      r.erase();
      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('X'));
    });

    test('TestRendererResize', () {
      final out = _TestSink();
      final r = _newRenderer(out);
      r.resize(80, 24);
      r.render(Buffer.create(80, 24));
      r.flush();
    });

    test('TestRendererPrependString', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.resize(10, 5);
      final cellbuf = Buffer.create(10, 5);

      r.prependString(cellbuf, 'Prepended line');
      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('Prepended line'));
    });

    test('TestRendererPrependLines', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.resize(10, 5);
      final cellbuf = Buffer.create(10, 5);

      final line = Line.filled(5);
      for (var i = 0; i < 'Hello'.length; i++) {
        line.set(i, Cell(content: 'Hello'[i], width: 1));
      }

      r.prependString(cellbuf, line.render());
      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('Hello'));
    });

    test('TestRendererTabStops', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.setTabStops(8);
      r.render(Buffer.create(20, 1));
      r.flush();

      r.setTabStops(-1);
      r.render(Buffer.create(20, 1));
      r.flush();
    });

    test('TestRendererBackspace', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.setBackspace(true);
      r.render(Buffer.create(10, 1));
      r.flush();

      r.setBackspace(false);
      r.render(Buffer.create(10, 1));
      r.flush();
    });

    test('TestRendererMapNewline', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.setMapNewline(true);
      r.render(Buffer.create(10, 2));
      r.flush();

      r.setMapNewline(false);
      r.render(Buffer.create(10, 2));
      r.flush();
    });

    test('TestRendererWideCharacters', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      final cellbuf = Buffer.create(10, 1);
      final wideChars = ['🌟', '中', '文', '字'];
      for (var i = 0; i < wideChars.length; i++) {
        cellbuf.setCell(i * 2, 0, Cell(content: wideChars[i], width: 2));
      }

      r.render(cellbuf);
      r.flush();

      for (final ch in wideChars) {
        expect(out.value, contains(ch));
      }
    });

    test('TestRendererZeroWidthCharacters', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      final cellbuf = Buffer.create(5, 1);
      cellbuf.setCell(0, 0, Cell(content: 'a\u0301', width: 1));
      cellbuf.setCell(1, 0, Cell(content: '\u200B', width: 0));

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('a\u0301'));
    });

    test('TestRendererStyledText', () {
      final out = _TestSink();
      final r = _newRenderer(out);
      r.setColorProfile(cp.Profile.trueColor);

      final cellbuf = Buffer.create(10, 1);
      final styles = <UvStyle>[
        const UvStyle(),
        const UvStyle(attrs: Attr.bold),
        const UvStyle(fg: UvRgb(255, 0, 0)),
        const UvStyle(bg: UvRgb(0, 255, 0)),
        const UvStyle(attrs: Attr.bold, fg: UvRgb(0, 0, 255)),
      ];

      for (var i = 0; i < styles.length; i++) {
        cellbuf.setCell(i, 0, Cell(content: 'X', width: 1, style: styles[i]));
      }

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('\x1b['));
    });

    test('TestRendererHyperlinks', () {
      final out = _TestSink();
      final r = _newRenderer(out);
      r.setColorProfile(cp.Profile.trueColor);

      final cellbuf = Buffer.create(10, 1);
      const link = Link(url: 'https://example.com');
      cellbuf.setCell(0, 0, Cell(content: 'l', width: 1, link: link));
      cellbuf.setCell(1, 0, Cell(content: 'i', width: 1, link: link));
      cellbuf.setCell(2, 0, Cell(content: 'n', width: 1, link: link));
      cellbuf.setCell(3, 0, Cell(content: 'k', width: 1, link: link));

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('link'));
      expect(
        out.value,
        contains(UvAnsi.setHyperlink('https://example.com', '')),
      );
    });

    test('TestRendererRelativeCursor', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.setRelativeCursor(true);

      final cellbuf = Buffer.create(10, 3);
      cellbuf.setCell(5, 1, Cell(content: 'X', width: 1));

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('X'));

      r.setRelativeCursor(false);
      out.reset();
      r.render(cellbuf);
      r.flush();
    });

    test('TestRendererLogger', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      final logs = <String>[];
      r.setLogger(logs.add);

      final cellbuf = Buffer.create(3, 1);
      cellbuf.setCell(0, 0, Cell(content: 'X', width: 1));

      r.render(cellbuf);
      r.flush();

      expect(logs, isNotEmpty);

      r.setLogger(null);
      logs.clear();
      r.render(cellbuf);
      r.flush();
      expect(logs, isEmpty);
    });

    test('TestRendererScrollOptimization', () {
      if (Platform.isWindows) return; // upstream also distinguishes behavior

      final out = _TestSink();
      final r = _newRenderer(out);

      r.setFullscreen(true);
      r.setScrollOptim(true);

      final first = Buffer.create(10, 5);
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 10; x++) {
          first.setCell(
            x,
            y,
            Cell(content: String.fromCharCode('A'.codeUnitAt(0) + y), width: 1),
          );
        }
      }

      r.render(first);
      r.flush();

      out.reset();

      final next = Buffer.create(10, 5);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 10; x++) {
          next.setCell(
            x,
            y,
            Cell(
              content: String.fromCharCode('A'.codeUnitAt(0) + y + 1),
              width: 1,
            ),
          );
        }
      }
      for (var x = 0; x < 10; x++) {
        next.setCell(x, 4, Cell(content: 'F', width: 1));
      }

      r.render(next);
      r.flush();

      expect(out.value, contains('F'));
    });

    test('TestRendererMultiplePrepends', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.resize(20, 10);
      final cellbuf = Buffer.create(20, 10);

      r.prependString(cellbuf, 'First line');
      r.prependString(cellbuf, 'Second line');

      final line1 = Line.filled(10);
      final line2 = Line.filled(10);
      final third = 'Third line';
      final fourth = 'Fourth lin';
      for (var i = 0; i < third.length && i < line1.length; i++) {
        line1.set(i, Cell(content: third[i], width: 1));
      }
      for (var i = 0; i < fourth.length && i < line2.length; i++) {
        line2.set(i, Cell(content: fourth[i], width: 1));
      }

      r.prependString(cellbuf, '${line1.render()}\n${line2.render()}');
      r.render(cellbuf);
      r.flush();

      for (final s in [
        'First line',
        'Second line',
        'Third line',
        'Fourth lin',
      ]) {
        expect(out.value, contains(s));
      }
    });

    test('TestRendererNewlineMapping', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      r.setMapNewline(true);
      r.setRelativeCursor(true);

      final cellbuf = Buffer.create(10, 3);
      for (var y = 0; y < 3; y++) {
        cellbuf.setCell(0, y, Cell(content: 'X', width: 1));
      }

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('X'));
    });

    test('TestRendererUnderlineStyles', () {
      final out = _TestSink();
      final r = _newRenderer(out);
      r.setColorProfile(cp.Profile.trueColor);

      final cellbuf = Buffer.create(10, 1);
      final styles = <UnderlineStyle>[
        UnderlineStyle.single,
        UnderlineStyle.double,
        UnderlineStyle.curly,
        UnderlineStyle.dotted,
        UnderlineStyle.dashed,
      ];

      for (var i = 0; i < styles.length && i < cellbuf.width(); i++) {
        cellbuf.setCell(
          i,
          0,
          Cell(
            content: 'U',
            width: 1,
            style: UvStyle(underline: styles[i]),
          ),
        );
      }

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('U'));
    });

    test('TestRendererTextAttributes', () {
      final out = _TestSink();
      final r = _newRenderer(out);
      r.setColorProfile(cp.Profile.trueColor);

      final cellbuf = Buffer.create(10, 1);
      final styles = <int>[
        Attr.italic,
        Attr.faint,
        Attr.blink,
        Attr.reverse,
        Attr.strikethrough,
      ];

      for (var i = 0; i < styles.length && i < cellbuf.width(); i++) {
        cellbuf.setCell(
          i,
          0,
          Cell(
            content: 'A',
            width: 1,
            style: UvStyle(attrs: styles[i]),
          ),
        );
      }

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('A'));
    });

    test('TestRendererColorDownsampling', () {
      final profiles = [
        cp.Profile.trueColor,
        cp.Profile.ansi256,
        cp.Profile.ansi,
        cp.Profile.ascii,
      ];

      for (final p in profiles) {
        final out = _TestSink();
        final r = _newRenderer(out);
        r.setColorProfile(p);

        final cellbuf = Buffer.create(3, 1);
        cellbuf.setCell(
          0,
          0,
          Cell(
            content: 'C',
            width: 1,
            style: const UvStyle(fg: UvRgb(123, 234, 45)),
          ),
        );

        r.render(cellbuf);
        r.flush();

        expect(out.value, contains('C'), reason: 'profile=$p');
      }
    });

    test('TestRendererLineClearingOptimizations', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      final cellbuf = Buffer.create(10, 3);
      final cell = Cell(content: 'X', width: 1);
      for (var x = 0; x < 10; x++) {
        cellbuf.setCell(x, 0, cell);
      }

      r.render(cellbuf);
      r.flush();

      out.reset();

      final newBuf = Buffer.create(10, 3);
      newBuf.setCell(0, 0, cell);

      r.render(newBuf);
      r.flush();

      // The renderer may keep the leading 'X' in place and only clear the
      // remainder of the line (line-clearing optimization).
      expect(out.value, contains(UvAnsi.eraseLineRight));
    });

    test('TestRendererRepeatCharacterOptimization', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      final cellbuf = Buffer.create(20, 1);
      final cell = Cell(content: 'A', width: 1);
      for (var x = 0; x < 15; x++) {
        cellbuf.setCell(x, 0, cell);
      }

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('A'));
    });

    test('TestRendererEraseCharacterOptimization', () {
      final out = _TestSink();
      final r = _newRenderer(out);

      final cellbuf = Buffer.create(20, 1);
      cellbuf.setCell(0, 0, Cell(content: 'A', width: 1));
      for (var x = 5; x < 15; x++) {
        cellbuf.setCell(x, 0, Cell(content: ' ', width: 1));
      }

      r.render(cellbuf);
      r.flush();

      expect(out.value, contains('A'));
    });
  });
}
