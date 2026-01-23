import 'package:artisanal/src/uv/screen_ops.dart' as screen;
import 'package:artisanal/src/uv/uv.dart';

import 'package:artisanal/src/unicode/width.dart';
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/screen/screen.go`
// - `third_party/ultraviolet/screen/screen_test.go`

final class _MockScreen implements Screen {
  _MockScreen(int width, int height)
    : _buffer = Buffer.create(width, height),
      _method = WidthMethod.wcwidth;

  final Buffer _buffer;
  final WidthMethod _method;

  @override
  Rectangle bounds() => _buffer.bounds();

  @override
  Cell? cellAt(int x, int y) => _buffer.cellAt(x, y);

  @override
  void setCell(int x, int y, Cell? cell) => _buffer.setCell(x, y, cell);

  @override
  WidthMethod widthMethod() => _method;
}

final class _MockScreenWithClear extends _MockScreen
    implements ClearableScreen {
  _MockScreenWithClear(super.width, super.height);
  bool clearCalled = false;

  @override
  void clear() {
    clearCalled = true;
    _buffer.clear();
  }
}

final class _MockScreenWithClearArea extends _MockScreen
    implements ClearAreaScreen {
  _MockScreenWithClearArea(super.width, super.height);
  bool clearAreaCalled = false;
  Rectangle? lastArea;

  @override
  void clearArea(Rectangle area) {
    clearAreaCalled = true;
    lastArea = area;
    _buffer.clearArea(area);
  }
}

final class _MockScreenWithFill extends _MockScreen implements FillableScreen {
  _MockScreenWithFill(super.width, super.height);
  bool fillCalled = false;
  Cell? lastCell;

  @override
  void fill(Cell? cell) {
    fillCalled = true;
    lastCell = cell;
    _buffer.fill(cell);
  }
}

final class _MockScreenWithFillArea extends _MockScreen
    implements FillAreaScreen {
  _MockScreenWithFillArea(super.width, super.height);
  bool fillAreaCalled = false;
  Rectangle? lastArea;
  Cell? lastCell;

  @override
  void fillArea(Cell? cell, Rectangle area) {
    fillAreaCalled = true;
    lastArea = area;
    lastCell = cell;
    for (var y = area.minY; y < area.maxY; y++) {
      for (var x = area.minX; x < area.maxX; x++) {
        setCell(x, y, cell);
      }
    }
  }
}

final class _MockScreenWithClone extends _MockScreen
    implements CloneableScreen {
  _MockScreenWithClone(super.width, super.height);
  bool cloneCalled = false;

  @override
  Object clone() {
    cloneCalled = true;
    return _buffer.clone();
  }
}

final class _MockScreenWithCloneArea extends _MockScreen
    implements CloneAreaScreen {
  _MockScreenWithCloneArea(super.width, super.height);
  bool cloneAreaCalled = false;
  Rectangle? lastArea;

  @override
  Object? cloneArea(Rectangle area) {
    cloneAreaCalled = true;
    lastArea = area;
    return _buffer.cloneArea(area);
  }
}

// Minimal screen with no optional methods.
final class _MinimalScreen implements Screen {
  _MinimalScreen(this.width, this.height) {
    cells = List.generate(
      height,
      (_) => List.generate(width, (_) => Cell.emptyCell()),
    );
  }

  final int width;
  final int height;
  late final List<List<Cell>> cells;

  @override
  Rectangle bounds() => rect(0, 0, width, height);

  @override
  Cell? cellAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return null;
    return cells[y][x];
  }

  @override
  void setCell(int x, int y, Cell? cell) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    cells[y][x] = (cell ?? Cell.emptyCell()).clone();
  }

  @override
  WidthMethod widthMethod() => WidthMethod.wcwidth;
}

// Screen that can return nil for certain cells.
final class _NilCellMockScreen extends _MinimalScreen {
  _NilCellMockScreen(super.width, super.height);
  final Set<String> _nilPositions = {};

  void setNilAt(int x, int y) => _nilPositions.add('$x,$y');

  @override
  Cell? cellAt(int x, int y) {
    if (_nilPositions.contains('$x,$y')) return null;
    return super.cellAt(x, y);
  }
}

void main() {
  group('UV screen ops parity', () {
    test('Clear uses Clear() method when present', () {
      final scr = _MockScreenWithClear(10, 5);
      scr.setCell(0, 0, Cell(content: 'X', width: 1));

      screen.clear(scr);

      expect(scr.clearCalled, isTrue);
      expect(scr.cellAt(0, 0)!.content, ' ');
    });

    test('Clear fallback fills with empty cells', () {
      final scr = _MockScreen(10, 5);
      scr.setCell(0, 0, Cell(content: 'X', width: 1));

      screen.clear(scr);

      expect(scr.cellAt(0, 0)!.content, ' ');
    });

    test('ClearArea uses ClearArea() method when present', () {
      final scr = _MockScreenWithClearArea(10, 5);
      final testCell = Cell(content: 'X', width: 1);
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 10; x++) {
          scr.setCell(x, y, testCell);
        }
      }

      final area = rect(2, 1, 4, 2);
      screen.clearArea(scr, area);

      expect(scr.clearAreaCalled, isTrue);
      expect(scr.lastArea, area);
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 10; x++) {
          final c = scr.cellAt(x, y);
          final inside = x >= 2 && x < 6 && y >= 1 && y < 3;
          expect(c, isNotNull);
          if (inside) {
            expect(c!.content, ' ');
          } else {
            expect(c!.content, 'X');
          }
        }
      }
    });

    test('Fill uses Fill() method when present', () {
      final scr = _MockScreenWithFill(10, 5);
      final fillCell = Cell(content: 'F', width: 1);
      screen.fill(scr, fillCell);

      expect(scr.fillCalled, isTrue);
      expect(scr.lastCell, fillCell);
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 10; x++) {
          expect(scr.cellAt(x, y)!.content, 'F');
        }
      }
    });

    test('FillArea uses FillArea() method when present', () {
      final scr = _MockScreenWithFillArea(10, 5);
      final fillCell = Cell(content: 'A', width: 1);
      final area = rect(2, 1, 4, 2);

      screen.fillArea(scr, fillCell, area);

      expect(scr.fillAreaCalled, isTrue);
      expect(scr.lastArea, area);
      expect(scr.lastCell, fillCell);
      for (var y = 1; y < 3; y++) {
        for (var x = 2; x < 6; x++) {
          expect(scr.cellAt(x, y)!.content, 'A');
        }
      }
    });

    test('Clone uses Clone() method when present', () {
      final scr = _MockScreenWithClone(10, 5);
      scr.setCell(0, 0, Cell(content: 'A', width: 1));
      scr.setCell(5, 2, Cell(content: 'B', width: 1));
      scr.setCell(9, 4, Cell(content: 'C', width: 1));

      final cloned = screen.clone(scr);

      expect(scr.cloneCalled, isTrue);
      expect(cloned.width(), 10);
      expect(cloned.height(), 5);
      expect(cloned.cellAt(0, 0)!.content, 'A');
      expect(cloned.cellAt(5, 2)!.content, 'B');
      expect(cloned.cellAt(9, 4)!.content, 'C');
    });

    test('CloneArea uses CloneArea() method when present', () {
      final scr = _MockScreenWithCloneArea(10, 5);
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 10; x++) {
          scr.setCell(
            x,
            y,
            Cell(
              content: String.fromCharCode('A'.codeUnitAt(0) + y * 10 + x),
              width: 1,
            ),
          );
        }
      }

      final area = rect(2, 1, 4, 2);
      final cloned = screen.cloneArea(scr, area);

      expect(scr.cloneAreaCalled, isTrue);
      expect(scr.lastArea, area);
      expect(cloned, isNotNull);
      expect(cloned!.width(), 4);
      expect(cloned.height(), 2);

      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 4; x++) {
          final expected = String.fromCharCode(
            'A'.codeUnitAt(0) + (y + 1) * 10 + (x + 2),
          );
          expect(cloned.cellAt(x, y)!.content, expected);
        }
      }
    });

    test('ScreenBuffer integration', () {
      final scr = ScreenBuffer(10, 5);
      scr.setCell(0, 0, Cell(content: 'X', width: 1));
      screen.clear(scr);
      expect(scr.cellAt(0, 0)!.content, ' ');

      screen.fill(scr, Cell(content: 'F', width: 1));
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 10; x++) {
          expect(scr.cellAt(x, y)!.content, 'F');
        }
      }

      final area = rect(2, 1, 3, 2);
      screen.clearArea(scr, area);
      for (var y = 1; y < 3; y++) {
        for (var x = 2; x < 5; x++) {
          expect(scr.cellAt(x, y)!.content, ' ');
        }
      }

      final area2 = rect(1, 1, 2, 2);
      screen.fillArea(scr, Cell(content: 'A', width: 1), area2);
      for (var y = 1; y < 3; y++) {
        for (var x = 1; x < 3; x++) {
          expect(scr.cellAt(x, y)!.content, 'A');
        }
      }

      final cloned = screen.clone(scr);
      expect(cloned.width(), 10);
      expect(cloned.height(), 5);

      final clonedArea = screen.cloneArea(scr, rect(0, 0, 3, 3));
      expect(clonedArea, isNotNull);
      expect(clonedArea!.width(), 3);
      expect(clonedArea.height(), 3);
    });

    test('Edge cases: empty screen does not throw', () {
      final scr = _MockScreen(0, 0);
      expect(() => screen.clear(scr), returnsNormally);
      expect(
        () => screen.fill(scr, Cell(content: 'X', width: 1)),
        returnsNormally,
      );
      expect(() => screen.clearArea(scr, rect(0, 0, 1, 1)), returnsNormally);
      expect(
        () => screen.fillArea(
          scr,
          Cell(content: 'X', width: 1),
          rect(0, 0, 1, 1),
        ),
        returnsNormally,
      );
      expect(() => screen.clone(scr), returnsNormally);
      expect(() => screen.cloneArea(scr, rect(0, 0, 1, 1)), returnsNormally);
    });

    test('Edge cases: wide/styled/linked cells', () {
      final scr = ScreenBuffer(10, 5);
      final wide = Cell(content: '😀', width: 2);
      scr.setCell(0, 0, wide);

      final cloned = screen.clone(scr);
      final c0 = cloned.cellAt(0, 0)!;
      expect(c0.content, '😀');
      expect(c0.width, 2);

      screen.fillArea(scr, wide, rect(0, 1, 4, 1));
      for (var x = 0; x < 4; x += 2) {
        final c = scr.cellAt(x, 1)!;
        expect(c.content, '😀');
        expect(c.width, 2);
      }

      final styled = Cell(
        content: 'S',
        width: 1,
        style: const UvStyle(attrs: Attr.bold | Attr.italic),
      );
      scr.setCell(0, 2, styled);
      final cloned2 = screen.clone(scr);
      final cs = cloned2.cellAt(0, 2)!;
      expect(cs.content, 'S');
      expect(cs.style.attrs & Attr.bold, isNot(0));
      expect(cs.style.attrs & Attr.italic, isNot(0));

      final linked = Cell(
        content: 'L',
        width: 1,
        link: const Link(url: 'https://example.com', params: 'id=test'),
      );
      scr.setCell(0, 3, linked);
      final cloned3 = screen.clone(scr);
      final cl = cloned3.cellAt(0, 3)!;
      expect(cl.content, 'L');
      expect(cl.link.url, 'https://example.com');
    });

    test('Minimal screen fallbacks', () {
      final scr = _MinimalScreen(5, 3);
      final x = Cell(content: 'X', width: 1);
      scr.setCell(0, 0, x);
      scr.setCell(2, 1, x);
      scr.setCell(4, 2, x);

      screen.clear(scr);
      for (var y = 0; y < 3; y++) {
        for (var cx = 0; cx < 5; cx++) {
          expect(scr.cellAt(cx, y)!.content, ' ');
        }
      }

      final scr2 = _MinimalScreen(5, 3);
      for (var y = 0; y < 3; y++) {
        for (var cx = 0; cx < 5; cx++) {
          scr2.setCell(cx, y, x);
        }
      }
      final area = rect(1, 0, 3, 2);
      screen.clearArea(scr2, area);
      for (var y = 0; y < 3; y++) {
        for (var cx = 0; cx < 5; cx++) {
          final inside = cx >= 1 && cx < 4 && y >= 0 && y < 2;
          expect(scr2.cellAt(cx, y)!.content, inside ? ' ' : 'X');
        }
      }

      final scr3 = _MinimalScreen(5, 3);
      screen.fill(scr3, Cell(content: 'F', width: 1));
      for (var y = 0; y < 3; y++) {
        for (var cx = 0; cx < 5; cx++) {
          expect(scr3.cellAt(cx, y)!.content, 'F');
        }
      }

      final scr4 = _MinimalScreen(5, 3);
      screen.fillArea(scr4, Cell(content: 'A', width: 1), rect(1, 1, 2, 1));
      for (var y = 0; y < 3; y++) {
        for (var cx = 0; cx < 5; cx++) {
          final inside = cx >= 1 && cx < 3 && y == 1;
          expect(scr4.cellAt(cx, y)!.content, inside ? 'A' : ' ');
        }
      }
    });

    test('CloneArea with nil and zero cells', () {
      final scr = _MinimalScreen(5, 3);
      scr.setCell(1, 0, Cell(content: 'A', width: 1));
      scr.setCell(3, 1, Cell(content: 'B', width: 1));
      scr.setCell(2, 0, Cell()); // Zero cell

      final area = rect(0, 0, 5, 2);
      final cloned = screen.cloneArea(scr, area);

      expect(cloned, isNotNull);
      expect(cloned!.cellAt(1, 0)!.content, 'A');
      expect(cloned.cellAt(3, 1)!.content, 'B');
      expect(cloned.cellAt(0, 0)!.isEmpty, isTrue);
      expect(cloned.cellAt(2, 0)!.isEmpty, isTrue);
    });

    test('CloneArea with nil cells', () {
      final scr = _NilCellMockScreen(5, 3);
      scr.setCell(1, 0, Cell(content: 'A', width: 1));
      scr.setCell(3, 1, Cell(content: 'B', width: 1));
      scr.setNilAt(2, 1);

      final area = rect(0, 0, 5, 2);
      final cloned = screen.cloneArea(scr, area);

      expect(cloned, isNotNull);
      expect(cloned!.cellAt(1, 0)!.content, 'A');
      expect(cloned.cellAt(3, 1)!.content, 'B');
      expect(cloned.cellAt(2, 1)!.isEmpty, isTrue);
    });
  });
}
