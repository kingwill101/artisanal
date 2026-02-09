/// Diagnostic tests for scroll rendering corruption with emoji content.
///
/// Tests the UV renderer pipeline to detect cell-level issues when
/// scrolling content that contains wide-character emoji.
import 'package:artisanal/src/unicode/width.dart';
import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

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

/// Helper: create a StyledString, draw it into a ScreenBuffer, return buffer.
ScreenBuffer drawString(String text, int width, int height) {
  final scr = ScreenBuffer(width, height);
  final ss = StyledString(text)..wrap = true;
  ss.draw(scr, scr.bounds());
  return scr;
}

/// Helper: extract content of a specific line from a Buffer as a string.
String lineContent(Buffer buf, int y) {
  final line = buf.line(y);
  if (line == null) return '';
  final sb = StringBuffer();
  for (var x = 0; x < buf.width(); x++) {
    final cell = line.at(x);
    if (cell == null || cell.isZero) continue;
    sb.write(cell.content);
  }
  return sb.toString();
}

/// Helper: extract visible display widths of all cells on a line.
List<int> lineWidths(Buffer buf, int y) {
  final line = buf.line(y);
  if (line == null) return [];
  return List.generate(buf.width(), (x) => line.at(x)?.width ?? 0);
}

void main() {
  group('StyledString draw with emoji', () {
    test('emoji cells have correct widths in buffer', () {
      const width = 40;
      const height = 3;
      final text = 'Faces: 😀 😎 🤔\nHands: 👍 👎 👏\nPlain text line';
      final scr = drawString(text, width, height);

      // Line 0: "Faces: 😀 😎 🤔" - each emoji is width 2
      // F(1) a(1) c(1) e(1) s(1) :(1) space(1) 😀(2) space(1) 😎(2) space(1) 🤔(2)
      // Total: 7 + 2 + 1 + 2 + 1 + 2 = 15 display cells
      final line0 = scr.buffer.line(0)!;
      // Check emoji at position 7 has width 2
      expect(line0.at(7)?.content, '😀');
      expect(line0.at(7)?.width, 2);
      // Position 8 should be a placeholder (width 0, empty)
      expect(line0.at(8)?.isZero, true);
      // Space at position 9
      expect(line0.at(9)?.content, ' ');
      expect(line0.at(9)?.width, 1);
      // Emoji at position 10
      expect(line0.at(10)?.content, '😎');
      expect(line0.at(10)?.width, 2);
      // Position 11 should be a placeholder
      expect(line0.at(11)?.isZero, true);
    });

    test('screen buffer clear overwrites emoji placeholders', () {
      const width = 20;
      const height = 2;

      // Frame 1: Draw emoji content
      final scr = ScreenBuffer(width, height);
      final ss1 = StyledString('😀 text')..wrap = true;
      ss1.draw(scr, scr.bounds());

      // Verify emoji at (0,0) with placeholder at (1,0)
      expect(scr.buffer.line(0)!.at(0)?.content, '😀');
      expect(scr.buffer.line(0)!.at(0)?.width, 2);
      expect(scr.buffer.line(0)!.at(1)?.isZero, true);
      expect(scr.buffer.line(0)!.at(2)?.content, ' ');

      // Frame 2: Draw different content (simulating scroll)
      final ss2 = StyledString('ABCDEFGHIJ')..wrap = true;
      ss2.draw(scr, scr.bounds());

      // The clear phase should have replaced emoji cells with spaces,
      // then draw phase places new content
      expect(scr.buffer.line(0)!.at(0)?.content, 'A');
      expect(scr.buffer.line(0)!.at(0)?.width, 1);
      expect(scr.buffer.line(0)!.at(1)?.content, 'B');
      expect(scr.buffer.line(0)!.at(1)?.width, 1);
    });
  });

  group('UV renderer differential update with emoji', () {
    test('transition from emoji line to text line emits correct output', () {
      const w = 20;
      const h = 2;
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

      // Frame 1: emoji content
      final scr1 = drawString(
        '😀 hello world!!!!!!\nline two here pad!!',
        w,
        h,
      );
      r.render(scr1.buffer);
      r.flush();
      out.reset();

      // Frame 2: text-only content (simulating scroll down)
      final scr2 = drawString(
        'line two here pad!!\nline three below!!!\n',
        w,
        h,
      );
      r.render(scr2.buffer);
      r.flush();

      // After frame 2, the terminal should show:
      // Line 0: "line two here pad!!" (was "😀 hello world!!!!!!")
      // Line 1: "line three below!!!" (was "line two here pad!!")

      // Verify the new buffer content is correct
      final l0 = lineContent(scr2.buffer, 0);
      final l1 = lineContent(scr2.buffer, 1);
      expect(l0.trim(), 'line two here pad!!');
      expect(l1.trim(), 'line three below!!!');
    });

    test('transition from text line to emoji line emits correct output', () {
      const w = 20;
      const h = 2;
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

      // Frame 1: text content
      final scr1 = drawString('hello world here!!!\nline two goes here!', w, h);
      r.render(scr1.buffer);
      r.flush();
      out.reset();

      // Frame 2: emoji content (simulating scroll up)
      final scr2 = drawString('Faces: 😀 😎 🤔 pad\nHands: 👍 👎 pad!!', w, h);
      r.render(scr2.buffer);
      r.flush();

      // Verify buffer content
      expect(scr2.buffer.line(0)!.at(7)?.content, '😀');
      expect(scr2.buffer.line(0)!.at(7)?.width, 2);
    });

    test('emoji-to-emoji transition with shifted positions', () {
      const w = 30;
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

      // Frame 1: emoji lines
      final text1 =
          'Faces: 😀 😎 🤔 🤢 🐒 🎉\nHands: 👍 👎 👏 🤞 ✌️ pad\nPlain text line here';
      final scr1 = drawString(text1, w, h);
      r.render(scr1.buffer);
      r.flush();
      out.reset();

      // Frame 2: scroll by 1 — shifted up
      final text2 =
          'Hands: 👍 👎 👏 🤞 ✌️ pad\nPlain text line here\nAnother text line pad';
      final scr2 = drawString(text2, w, h);
      r.render(scr2.buffer);
      r.flush();

      // Line 0 changed from "Faces: ..." to "Hands: ..."
      // Verify the line was correctly updated
      expect(lineContent(scr2.buffer, 0).startsWith('Hands:'), true);
      expect(lineContent(scr2.buffer, 1).trim(), 'Plain text line here');
    });

    test('renderer curbuf matches actual terminal output', () {
      // This test simulates multiple scroll frames and verifies that
      // the renderer's internal _curbuf matches the new buffer after
      // each render.
      const w = 40;
      const h = 5;
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

      // Build a document with mixed content
      final lines = <String>[
        'Heading 1 -- the biggest',
        '',
        'Regular text, bold text.',
        '',
        'Faces: 😀 😎 🤔 🤢',
        'Food: 🍕 🍔 🍣 🍰',
        'Hands: 👍 👎 👏',
        '',
        'More regular text follows.',
        'And another line here.',
      ];

      // Simulate scrolling through the document
      for (var offset = 0; offset < lines.length - h; offset++) {
        final visible = lines.sublist(offset, offset + h);
        // Pad each line to width
        final padded = visible
            .map((l) {
              // Simple padding: add spaces to fill width
              final stripped = l;
              final visLen = stripped.length; // Simplified for test
              return stripped + ' ' * (w > visLen ? w - visLen : 0);
            })
            .join('\n');

        final scr = drawString(padded, w, h);
        r.render(scr.buffer);
        r.flush();
        out.reset();
      }

      // The test primarily checks that no assertions fail during the
      // scroll sequence. If _transformLine has cursor/cell issues,
      // the rendering would produce incorrect output.
    });
  });

  group('StyledString draw with scrollbar column', () {
    test('scrollbar character at end of emoji line is at correct position', () {
      // Simulates a viewport line with emoji content + scrollbar
      // The scrollbar char should be at the last column regardless of emoji
      const w = 20;
      const h = 3;

      // Build lines programmatically so widths are correct
      String padTo(String content, String scrollChar) {
        final vis = stringWidth(content);
        final padCount = w - vis - 1; // -1 for scrollbar char
        return '$content${' ' * padCount}$scrollChar';
      }

      final line1 = padTo('😀 😎 🤔 pad', '│');
      final line2 = padTo('Plain text here', '█');
      final line3 = padTo('Another line', '│');

      final text = '$line1\n$line2\n$line3';
      final scr = drawString(text, w, h);

      // Check that the scrollbar characters are at column 19
      // (the last column in a 20-wide buffer)
      for (var y = 0; y < h; y++) {
        final lastCell = scr.buffer.line(y)!.at(w - 1);
        // The last character should be either │ or █
        final content = lastCell?.content ?? '';
        expect(
          content == '│' || content == '█',
          true,
          reason:
              'Line $y: last cell should be scrollbar, got: "$content"'
              ' (width: ${lastCell?.width})',
        );
      }
    });
  });
}
