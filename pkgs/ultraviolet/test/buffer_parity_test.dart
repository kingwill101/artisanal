import 'package:ultraviolet/src/uv/uv.dart';

import 'package:ultraviolet/src/unicode/width.dart';
import 'package:ultraviolet/src/unicode/grapheme.dart' as uni;
import 'package:test/test.dart';
import 'dart:typed_data';

void main() {
  group('Buffer parity (subset)', () {
    test('TestBufferUniseg (ASCII subset)', () {
      final cases = <({String name, String input, String expected})>[
        (name: 'empty buffer', input: '', expected: ''),
        (
          name: 'single line',
          input: 'Hello, World!',
          expected: 'Hello, World!',
        ),
        (
          name: 'multiple lines',
          input: 'Hello, World!\nThis is a test.\nGoodbye!',
          expected: 'Hello, World!\nThis is a test.\nGoodbye!',
        ),
      ];

      for (final tc in cases) {
        final lines = tc.input.split('\n');
        final w = _stringWidth(tc.input);
        final h = lines.length;
        final buf = Buffer.create(w, h);

        for (var y = 0; y < lines.length; y++) {
          var x = 0;
          final line = lines[y];
          for (final g in uni.graphemes(line)) {
            final cell = Cell.newCell(WidthMethod.wcwidth, g);
            buf.setCell(x, y, cell);
            x += cell.width;
          }
        }

        expect(buf.toString(), tc.expected, reason: tc.name);
      }
    });

    test('Line.set (wide-cell overwrite semantics)', () {
      final l = Line.filled(10);

      // set simple cell
      l.set(5, Cell(content: 'a', width: 1));
      expect(l.at(5)!.content, 'a');

      // out-of-bounds should no-op
      l.set(-1, Cell(content: 'b', width: 1));
      l.set(10, Cell(content: 'b', width: 1));

      // overwrite wide cell at origin
      l.set(2, Cell(content: '你', width: 2));
      l.set(2, Cell(content: 'c', width: 1));
      expect(l.at(2)!.content, 'c');

      // overwrite middle of wide cell should clear wide origin
      l.set(2, Cell(content: '你', width: 2));
      l.set(3, Cell(content: 'd', width: 1));
      expect(l.at(3)!.content, 'd');
      expect(l.at(2)!.content, ' ');

      // wide cell at end should be replaced with spaces (doesn’t fit)
      l.set(9, Cell(content: '你', width: 2));
      expect(l.at(9)!.content, ' ');
    });

    test('Line.toString (trims trailing spaces; skips placeholders)', () {
      // empty line
      expect(Line.filled(5).toString(), '');

      // simple text
      final hello = Line.fromCells([
        Cell(content: 'H', width: 1),
        Cell(content: 'e', width: 1),
        Cell(content: 'l', width: 1),
        Cell(content: 'l', width: 1),
        Cell(content: 'o', width: 1),
      ]);
      expect(hello.toString(), 'Hello');

      // wide characters include explicit placeholder cells
      final wide = Line.fromCells([
        Cell(content: '你', width: 2),
        Cell(), // placeholder
        Cell(content: '好', width: 2),
        Cell(), // placeholder
        Cell(content: '!', width: 1),
        Cell(content: ' ', width: 1),
      ]);
      expect(wide.toString(), '你好!');

      // trailing spaces trimmed
      final hi = Line.filled(10);
      hi.cells[0] = Cell(content: 'H', width: 1);
      hi.cells[1] = Cell(content: 'i', width: 1);
      expect(hi.toString(), 'Hi');
    });

    test('Line.render (styles and resets)', () {
      final l = Line.filled(5);
      l.set(
        0,
        Cell(
          content: 'H',
          width: 1,
          style: const UvStyle(fg: UvColor.basic16(1)),
        ),
      );
      l.set(1, Cell(content: 'i', width: 1));

      // Expect red "H", then a reset before "i".
      expect(l.render(), '\x1b[31mH\x1b[mi');
    });

    test('Buffer.render (hyperlink open/close)', () {
      final b = Buffer.create(5, 1);
      const link = Link(url: 'http://example.com');
      b.setCell(0, 0, Cell(content: 'L', width: 1, link: link));
      b.setCell(1, 0, Cell(content: 'i', width: 1, link: link));
      b.setCell(2, 0, Cell(content: 'n', width: 1, link: link));
      b.setCell(3, 0, Cell(content: 'k', width: 1, link: link));

      final out = b.render();
      expect(out, contains('Link'));
      expect(out, contains(UvAnsi.setHyperlink('http://example.com', '')));
      expect(out, endsWith(UvAnsi.resetHyperlink()));
    });

    test('Scissor stack clips writes with nested push/pop', () {
      final b = Buffer.create(8, 2);

      b.pushScissor(rect(1, 0, 6, 2)); // 1..7
      b.setCell(0, 0, Cell(content: 'A', width: 1));
      b.setCell(2, 0, Cell(content: 'B', width: 1));
      expect(b.cellAt(0, 0)!.content, ' ');
      expect(b.cellAt(2, 0)!.content, 'B');

      b.pushScissor(rect(3, 0, 2, 2)); // 3..5
      b.setCell(2, 0, Cell(content: 'C', width: 1));
      b.setCell(4, 0, Cell(content: 'D', width: 1));
      expect(b.cellAt(2, 0)!.content, 'B');
      expect(b.cellAt(4, 0)!.content, 'D');

      b.popScissor();
      b.setCell(2, 0, Cell(content: 'E', width: 1));
      b.setCell(4, 0, Cell(content: 'F', width: 1));
      expect(b.cellAt(2, 0)!.content, 'E');
      expect(b.cellAt(4, 0)!.content, 'F');

      b.popScissor();
      b.setCell(0, 0, Cell(content: 'Z', width: 1));
      expect(b.cellAt(0, 0)!.content, 'Z');
    });

    test('Opacity stack applies multiplicative alpha to RGB channels', () {
      final b = Buffer.create(6, 1);
      b.pushOpacity(0.5);
      b.setCell(
        0,
        0,
        Cell(
          content: 'A',
          width: 1,
          style: const UvStyle(
            fg: UvRgb(10, 20, 30, a: 255),
            bg: UvRgb(40, 50, 60, a: 200),
          ),
        ),
      );
      final fgHalf = b.cellAt(0, 0)!.style.fg!;
      final bgHalf = b.cellAt(0, 0)!.style.bg!;
      expect((fgHalf as UvRgb).a, 128);
      expect((bgHalf as UvRgb).a, 100);

      b.pushOpacity(0.25);
      b.setCell(
        1,
        0,
        Cell(
          content: 'B',
          width: 1,
          style: const UvStyle(fg: UvRgb(10, 20, 30, a: 255)),
        ),
      );
      final fgNested = b.cellAt(1, 0)!.style.fg! as UvRgb;
      expect(fgNested.a, 32);

      b.popOpacity();
      b.setCell(
        2,
        0,
        Cell(
          content: 'C',
          width: 1,
          style: const UvStyle(fg: UvRgb(100, 110, 120, a: 255)),
        ),
      );
      final fgRestored = b.cellAt(2, 0)!.style.fg! as UvRgb;
      expect(fgRestored.a, 128);

      b.popOpacity();
      b.setCell(
        3,
        0,
        Cell(
          content: 'D',
          width: 1,
          style: const UvStyle(fg: UvRgb(1, 2, 3, a: 10)),
        ),
      );
      final fgFinal = b.cellAt(3, 0)!.style.fg! as UvRgb;
      expect(fgFinal.a, 10);
    });

    test(
      'Buffer basics (width/height, cellAt bounds, setCell, resize, fillArea)',
      () {
        final empty = Buffer.create(0, 0);
        expect(empty.width(), 0);
        expect(empty.height(), 0);

        final b = Buffer.create(10, 5);
        expect(b.width(), 10);
        expect(b.height(), 5);

        b.setCell(2, 1, Cell(content: 'X', width: 1));
        expect(b.cellAt(2, 1)!.content, 'X');

        expect(b.cellAt(-1, 0), isNull);
        expect(b.cellAt(0, -1), isNull);
        expect(b.cellAt(10, 0), isNull);
        expect(b.cellAt(0, 5), isNull);

        // nil cell clears
        b.setCell(2, 1, null);
        expect(b.cellAt(2, 1)!.content, ' ');

        // resize smaller then larger
        b.setCell(2, 1, Cell(content: 'Y', width: 1));
        b.resize(5, 3);
        expect(b.width(), 5);
        expect(b.height(), 3);
        expect(b.cellAt(2, 1)!.content, 'Y');

        b.resize(15, 10);
        expect(b.width(), 15);
        expect(b.height(), 10);
        expect(b.cellAt(2, 1)!.content, 'Y');

        // fill area
        b.fillArea(Cell(content: 'Z', width: 1), rect(2, 1, 3, 2));
        for (var y = 1; y < 3; y++) {
          for (var x = 2; x < 5; x++) {
            expect(b.cellAt(x, y)!.content, 'Z');
          }
        }
      },
    );

    test('Buffer.setCell no-ops when the target cell already matches', () {
      final b = Buffer.create(3, 1);
      final cell = Cell(content: 'X', width: 1);

      b.setCell(1, 0, cell);
      b.clearDirtyTracking();

      final before = b.cellAt(1, 0)!;
      b.setCell(1, 0, cell);

      expect(identical(b.cellAt(1, 0), before), isTrue);
      expect(b.touched[0], LineData.clean);
      expect(b.dirtyBitSpans(0), isEmpty);
    });

    test('Line.renderHash changes for style-only updates', () {
      final line = Line.filled(2);
      final initial = line.renderHash();

      line.setOwned(
        0,
        Cell(
          content: ' ',
          width: 1,
          style: const UvStyle(fg: UvRgb(255, 0, 0)),
        ),
      );

      final updated = line.renderHash();
      expect(updated, isNot(initial));

      line.setOwned(
        0,
        Cell(
          content: ' ',
          width: 1,
          style: const UvStyle(fg: UvRgb(255, 0, 0)),
        ),
      );

      expect(line.renderHash(), equals(updated));
    });

    test('clear, clone, cloneArea, draw', () {
      final b = Buffer.create(10, 5);
      b.setCell(2, 1, Cell(content: 'X', width: 1));

      // clear
      b.clear();
      for (var y = 0; y < b.height(); y++) {
        for (var x = 0; x < b.width(); x++) {
          expect(b.cellAt(x, y)!.content, ' ');
        }
      }

      // clone independence
      b.setCell(2, 1, Cell(content: 'X', width: 1));
      final clone = b.clone();
      expect(clone.cellAt(2, 1)!.content, 'X');
      clone.setCell(2, 1, Cell(content: 'Y', width: 1));
      expect(b.cellAt(2, 1)!.content, 'X');

      // cloneArea
      b.setCell(3, 2, Cell(content: 'Z', width: 1));
      final areaClone = b.cloneArea(rect(2, 1, 2, 2))!;
      expect(areaClone.width(), 2);
      expect(areaClone.height(), 2);
      expect(areaClone.cellAt(0, 0)!.content, 'X');
      expect(areaClone.cellAt(1, 1)!.content, 'Z');

      // draw
      final src = Buffer.create(3, 3);
      src.setCell(1, 1, Cell(content: 'S', width: 1));
      final dst = ScreenBuffer(10, 5);
      dst.setCell(2, 2, Cell(content: 'D', width: 1));
      src.draw(dst, rect(1, 1, 4, 4));
      expect(dst.cellAt(2, 2)!.content, 'S');
      expect(dst.cellAt(0, 0)!.content, ' ');
    });

    test('cloneArea preserves wide characters', () {
      // Test that wide characters (CJK, emoji) survive cloneArea
      final b = Buffer.create(10, 3);

      // Place wide characters at various positions
      b.setCell(0, 0, Cell(content: '你', width: 2)); // x=0,1
      b.setCell(2, 0, Cell(content: '好', width: 2)); // x=2,3
      b.setCell(4, 0, Cell(content: '!', width: 1)); // x=4

      // Verify original buffer structure
      expect(b.cellAt(0, 0)!.content, '你');
      expect(b.cellAt(0, 0)!.width, 2);
      expect(b.cellAt(1, 0)!.isZero, isTrue, reason: 'placeholder for 你');
      expect(b.cellAt(2, 0)!.content, '好');
      expect(b.cellAt(2, 0)!.width, 2);
      expect(b.cellAt(3, 0)!.isZero, isTrue, reason: 'placeholder for 好');
      expect(b.cellAt(4, 0)!.content, '!');

      // Clone full area - wide chars should be preserved
      final fullClone = b.cloneArea(rect(0, 0, 5, 1))!;
      expect(fullClone.width(), 5);
      expect(fullClone.cellAt(0, 0)!.content, '你');
      expect(fullClone.cellAt(0, 0)!.width, 2);
      expect(
        fullClone.cellAt(1, 0)!.isZero,
        isTrue,
        reason: 'placeholder preserved',
      );
      expect(fullClone.cellAt(2, 0)!.content, '好');
      expect(fullClone.cellAt(4, 0)!.content, '!');

      // Clone starting at wide char origin - should work
      final originClone = b.cloneArea(rect(2, 0, 3, 1))!;
      expect(originClone.cellAt(0, 0)!.content, '好');
      expect(originClone.cellAt(0, 0)!.width, 2);
      expect(originClone.cellAt(1, 0)!.isZero, isTrue);
      expect(originClone.cellAt(2, 0)!.content, '!');

      // Clone starting at placeholder (middle of wide char) - should clear to space
      // since we can't preserve a partial wide character
      final placeholderClone = b.cloneArea(rect(1, 0, 4, 1))!;
      // Position 0 in clone corresponds to position 1 in original (placeholder)
      // This should either be a space (cleared) or the placeholder handling should
      // recognize it can't be rendered standalone
      expect(
        placeholderClone.cellAt(0, 0)!.content,
        ' ',
        reason: 'partial wide char at boundary becomes space',
      );
      // Position 1 in clone = position 2 in original = '好'
      expect(placeholderClone.cellAt(1, 0)!.content, '好');
      expect(placeholderClone.cellAt(1, 0)!.width, 2);
    });

    test('cloneArea handles wide characters at boundaries', () {
      final b = Buffer.create(6, 1);
      b.setCell(0, 0, Cell(content: 'A', width: 1));
      b.setCell(1, 0, Cell(content: '中', width: 2)); // x=1,2
      b.setCell(3, 0, Cell(content: 'B', width: 1));

      // Clone that ends in middle of wide char - the wide char can't fit
      // because its placeholder (position 2) is outside the clone area
      final endClone = b.cloneArea(rect(0, 0, 2, 1))!;
      expect(endClone.cellAt(0, 0)!.content, 'A');
      // Wide char at position 1 needs positions 1,2 but clone only has width 2 (positions 0,1)
      // So when setCell tries to place it at position 1 with width 2, it overflows and becomes space
      expect(
        endClone.cellAt(1, 0)!.content,
        ' ',
        reason: 'wide char at boundary that would overflow becomes space',
      );

      // Clone that properly includes the wide char
      final goodClone = b.cloneArea(rect(0, 0, 3, 1))!;
      expect(goodClone.cellAt(0, 0)!.content, 'A');
      expect(goodClone.cellAt(1, 0)!.content, '中');
      expect(goodClone.cellAt(1, 0)!.width, 2);
      expect(
        goodClone.cellAt(2, 0)!.isZero,
        isTrue,
        reason: 'placeholder preserved',
      );

      // Clone starting at a placeholder (x=2 is placeholder for '中')
      final startAtPlaceholder = b.cloneArea(rect(2, 0, 2, 1))!;
      // Position 0 in clone = position 2 in original = placeholder for '中'
      // Placeholders are skipped in cloneArea (c.isZero continue), so nothing is copied
      // and the cell remains the default space from Buffer.create
      expect(
        startAtPlaceholder.cellAt(0, 0)!.content,
        ' ',
        reason: 'placeholder at start of clone area becomes space',
      );
      expect(startAtPlaceholder.cellAt(1, 0)!.content, 'B');
    });

    test('cloned wide characters render correctly', () {
      // Verify that cloned buffers with wide characters produce correct string output
      final b = Buffer.create(8, 1);
      b.setCell(0, 0, Cell(content: '你', width: 2));
      b.setCell(2, 0, Cell(content: '好', width: 2));
      b.setCell(4, 0, Cell(content: '!', width: 1));

      // Verify original renders correctly
      expect(b.toString(), '你好!');

      // Clone and verify render
      final cloned = b.clone();
      expect(cloned.toString(), '你好!');

      // Clone area and verify render
      final partial = b.cloneArea(rect(2, 0, 3, 1))!;
      expect(partial.toString(), '好!');
    });

    test('insertLine / deleteLine', () {
      final b = Buffer.create(5, 3);
      b.setCell(0, 0, Cell(content: 'A', width: 1));
      b.setCell(0, 1, Cell(content: 'B', width: 1));
      b.setCell(0, 2, Cell(content: 'C', width: 1));

      b.insertLine(1, 1, null);
      expect(b.cellAt(0, 2)!.content, 'B');
      expect(b.cellAt(0, 1)!.content, ' ');

      b.deleteLine(1, 1, null);
      expect(b.cellAt(0, 1)!.content, 'B');
      expect(b.cellAt(0, 2)!.content, ' ');
    });

    test('insertLineArea / deleteLineArea', () {
      final b = Buffer.create(5, 5);
      b.setCell(0, 1, Cell(content: 'A', width: 1));
      b.setCell(0, 2, Cell(content: 'B', width: 1));

      b.insertLineArea(2, 1, null, rect(0, 1, 5, 4));
      expect(b.cellAt(0, 3)!.content, 'B');

      b.setCell(0, 3, Cell(content: 'C', width: 1));
      b.deleteLineArea(2, 1, null, rect(0, 1, 5, 4));
      expect(b.cellAt(0, 2)!.content, 'C');
    });

    test('insertCell / deleteCell', () {
      final b = Buffer.create(5, 2);
      final l = b.line(0)!.cells;
      l[0] = Cell(content: 'A', width: 1);
      l[1] = Cell(content: 'B', width: 1);
      l[2] = Cell(content: 'C', width: 1);

      b.insertCell(1, 0, 1, null);
      expect(b.cellAt(2, 0)!.content, 'B');

      b.deleteCell(1, 0, 1, null);
      expect(b.cellAt(1, 0)!.content, 'B');
    });

    test('insertCellArea / deleteCellArea', () {
      final insert = Buffer.create(5, 3);
      final il = insert.line(1)!.cells;
      il[1] = Cell(content: 'A', width: 1);
      il[2] = Cell(content: 'B', width: 1);

      insert.insertCellArea(1, 1, 1, null, rect(1, 1, 4, 2));
      expect(insert.cellAt(2, 1)!.content, 'A');

      final del = Buffer.create(5, 3);
      final dl = del.line(1)!.cells;
      dl[1] = Cell(content: 'A', width: 1);
      dl[2] = Cell(content: 'B', width: 1);
      dl[3] = Cell(content: 'C', width: 1);

      del.deleteCellArea(2, 1, 1, null, rect(1, 1, 4, 2));
      expect(del.cellAt(2, 1)!.content, 'C');
    });

    test('render contains content', () {
      final b = Buffer.create(5, 2);
      b.setCell(0, 0, Cell(content: 'H', width: 1));
      b.setCell(1, 0, Cell(content: 'i', width: 1));
      b.setCell(0, 1, Cell(content: '!', width: 1));
      expect(b.render(), contains('Hi'));
    });

    test('touchLine updates touched metadata', () {
      final b = Buffer.create(10, 3);
      expect(b.touched[1], isNull);
      expect(b.dirtyRows[1], isFalse);

      b.touchLine(2, 1, 3);
      expect(b.touched[1], isNotNull);
      expect(b.touched[1]!.firstCell, 2);
      expect(b.touched[1]!.lastCell, 5);
      expect(b.touched[1]!.spans, [DirtySpan(start: 2, end: 5)]);
      expect(b.dirtyRows[1], isTrue);

      // merge range
      b.touchLine(1, 1, 10);
      expect(b.touched[1]!.firstCell, 1);
      expect(b.touched[1]!.lastCell, 11);
      expect(b.touched[1]!.spans, [DirtySpan(start: 1, end: 11)]);

      // out-of-bounds should not throw
      b.touchLine(0, -1, 1);
      b.touchLine(0, 3, 1);
    });

    test('touchLine keeps multiple disjoint spans until overflow', () {
      final b = Buffer.create(40, 2);

      b.touchLine(1, 0, 1);
      b.touchLine(5, 0, 1);
      b.touchLine(9, 0, 1);
      b.touchLine(13, 0, 1);

      expect(b.touched[0]!.spans, [
        DirtySpan(start: 1, end: 2),
        DirtySpan(start: 5, end: 6),
        DirtySpan(start: 9, end: 10),
        DirtySpan(start: 13, end: 14),
      ]);
      expect(b.touched[0]!.overflowed, isFalse);

      b.touchLine(17, 0, 1);

      expect(b.touched[0]!.overflowed, isTrue);
      expect(b.touched[0]!.spans, [DirtySpan(start: 1, end: 18)]);
    });

    test('clearDirtyLine and clearDirtyTracking reset row metadata', () {
      final b = Buffer.create(10, 3);
      b.touchLine(2, 1, 3);
      b.touchLine(1, 2, 1);

      b.clearDirtyLine(1);
      expect(b.dirtyRows[1], isFalse);
      expect(b.touched[1], LineData.clean);
      expect(b.dirtyRows[2], isTrue);

      b.clearDirtyTracking();
      expect(b.dirtyRows, everyElement(isFalse));
      expect(b.touched, everyElement(LineData.clean));
    });

    test(
      'dirty tracking can be disabled for offscreen composition buffers',
      () {
        final b = Buffer.create(5, 2, tracksDirty: false);
        b.setCell(1, 0, Cell(content: 'A', width: 1));
        b.touchLine(0, 1, 3);

        expect(b.render(), contains('A'));
        expect(b.touched, isEmpty);
        expect(b.dirtyRows, isEmpty);
        expect(b.dirtyBitSpans(0), isEmpty);

        b.clearDirtyTracking();
        expect(b.touched, isEmpty);
        expect(b.dirtyRows, isEmpty);
      },
    );

    test('dirty bitsets track individual dirty cells and spans', () {
      final b = Buffer.create(40, 2);
      b.touchLine(2, 0, 2);
      b.touchLine(7, 0, 1);

      expect(b.isCellDirty(1, 0), isFalse);
      expect(b.isCellDirty(2, 0), isTrue);
      expect(b.isCellDirty(3, 0), isTrue);
      expect(b.isCellDirty(4, 0), isFalse);
      expect(b.isCellDirty(7, 0), isTrue);
      final trackedSpans = b.touched[0]!.spans;
      expect(identical(b.dirtyBitSpans(0), trackedSpans), isTrue);
      expect(trackedSpans, [
        DirtySpan(start: 2, end: 4),
        DirtySpan(start: 7, end: 8),
      ]);

      b.clearDirtyLine(0);
      expect(b.isCellDirty(2, 0), isFalse);
      expect(b.dirtyBitSpans(0), isEmpty);
    });

    test('clearDirtyTracking reuses its tracking storage', () {
      final b = Buffer.create(40, 2);
      final touched = b.touched;
      final dirtyRows = b.dirtyRows;
      final dirtyBits = b.dirtyBits;
      final firstRowBits = dirtyBits.first;

      b.touchLine(2, 0, 4);
      b.clearDirtyTracking();

      expect(identical(b.touched, touched), isTrue);
      expect(identical(b.dirtyRows, dirtyRows), isTrue);
      expect(identical(b.dirtyBits, dirtyBits), isTrue);
      expect(identical(b.dirtyBits.first, firstRowBits), isTrue);
      expect(b.touched, everyElement(LineData.clean));
      expect(b.dirtyRows, everyElement(isFalse));
      expect(b.dirtyBitSpans(0), isEmpty);
    });

    test(
      'clear resets styled and pooled cells while preserving line hashes',
      () {
        final b = Buffer.create(2, 1);
        final source = Cell(
          content: '\u007A\u0307',
          width: 1,
          style: const UvStyle(fg: UvRgb(20, 30, 40)),
          link: const Link(url: 'https://clear.example'),
        );
        b.setCell(0, 0, source);
        source.dispose();

        final line = b.line(0)!;
        final before = line.renderHash();
        final pooledId = line.at(0)!.pooledContentId!;
        expect(debugGraphemeRefCount(pooledId), 1);

        b.clear();

        final cleared = b.cellAt(0, 0)!;
        expect(cleared.isEmpty, isTrue);
        expect(cleared.style, const UvStyle());
        expect(cleared.link, const Link());
        expect(line.renderHash(), isNot(before));
        expect(line.renderHash(), equals(Line.filled(2).renderHash()));
        expect(debugGraphemeRefCount(pooledId), 0);
      },
    );

    test('line overwrite releases pooled graphemes', () {
      final line = Line.filled(4);
      final source = Cell(content: '\u007A\u0307', width: 1);
      line.set(0, source);
      final pooledId = line.at(0)!.pooledContentId!;
      expect(debugGraphemeRefCount(pooledId), 2);

      line.set(0, Cell(content: 'A', width: 1));
      source.dispose();

      expect(debugGraphemeRefCount(pooledId), 0);
      expect(line.at(0)!.content, 'A');
    });

    test('DirtyDensityMap reports summed dirty counts for rectangles', () {
      final b = Buffer.create(40, 12);
      b.touchLine(2, 1, 2);
      b.touchLine(15, 1, 1);
      b.touchLine(18, 7, 3);

      final density = DirtyDensityMap.fromBuffer(b);

      expect(density.count(rect(0, 0, 40, 12)), 6);
      expect(density.count(rect(0, 0, 10, 4)), 2);
      expect(density.count(rect(14, 0, 4, 4)), 1);
      expect(density.count(rect(16, 6, 8, 3)), 3);
      expect(density.hasAny(rect(0, 8, 10, 2)), isFalse);
    });

    test('DirtyDensityMap can reuse caller-provided scratch storage', () {
      final b = Buffer.create(8, 4);
      b.touchLine(1, 1, 2);
      final scratch = Int32List((b.width() + 1) * (b.height() + 1));
      scratch.fillRange(0, scratch.length, 123);

      final density = DirtyDensityMap.fromBuffer(b, scratch: scratch);

      expect(density.count(rect(0, 0, 8, 4)), 2);
      expect(scratch[0], 0);
      expect(scratch[scratch.length - 1], isNot(123));
    });

    test('ScreenBuffer defaults to wcwidth method', () {
      final sb = ScreenBuffer(10, 5);
      expect(sb.widthMethod().stringWidth('a'), 1);
      // A basic double-width CJK rune should report width 2 under wcwidth.
      expect(sb.widthMethod().stringWidth('你'), 2);
    });
  });
}

int _stringWidth(String s) {
  var width = 0;
  for (final line in s.split('\n')) {
    final w = WidthMethod.wcwidth.stringWidth(line);
    if (w > width) width = w;
  }
  return width;
}
