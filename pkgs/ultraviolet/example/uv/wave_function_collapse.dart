import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

typedef _Mask = int;

final class _Tile {
  const _Tile({
    required this.glyph,
    required this.style,
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final String glyph;
  final UvStyle style;
  final int top;
  final int right;
  final int bottom;
  final int left;
}

final class _WfcGrid {
  _WfcGrid(this.width, this.height, this._rng)
    : _cells = List<_Mask>.filled(width * height, _allMask, growable: false) {
    _buildCompatibilityLut();
  }

  static const List<_Tile> _tiles = [
    _Tile(
      glyph: '·',
      style: UvStyle(fg: UvColor.rgb(70, 78, 94), bg: UvColor.rgb(8, 10, 18)),
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    ),
    _Tile(
      glyph: '│',
      style: UvStyle(
        fg: UvColor.rgb(124, 198, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 1,
      right: 0,
      bottom: 1,
      left: 0,
    ),
    _Tile(
      glyph: '─',
      style: UvStyle(
        fg: UvColor.rgb(124, 198, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 0,
      right: 1,
      bottom: 0,
      left: 1,
    ),
    _Tile(
      glyph: '┌',
      style: UvStyle(
        fg: UvColor.rgb(124, 198, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 0,
      right: 1,
      bottom: 1,
      left: 0,
    ),
    _Tile(
      glyph: '┐',
      style: UvStyle(
        fg: UvColor.rgb(124, 198, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 0,
      right: 0,
      bottom: 1,
      left: 1,
    ),
    _Tile(
      glyph: '└',
      style: UvStyle(
        fg: UvColor.rgb(124, 198, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 1,
      right: 1,
      bottom: 0,
      left: 0,
    ),
    _Tile(
      glyph: '┘',
      style: UvStyle(
        fg: UvColor.rgb(124, 198, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 1,
      right: 0,
      bottom: 0,
      left: 1,
    ),
    _Tile(
      glyph: '┼',
      style: UvStyle(
        fg: UvColor.rgb(255, 208, 142),
        bg: UvColor.rgb(8, 10, 18),
        attrs: Attr.bold,
      ),
      top: 1,
      right: 1,
      bottom: 1,
      left: 1,
    ),
    _Tile(
      glyph: '╵',
      style: UvStyle(
        fg: UvColor.rgb(168, 226, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 1,
      right: 0,
      bottom: 0,
      left: 0,
    ),
    _Tile(
      glyph: '╶',
      style: UvStyle(
        fg: UvColor.rgb(168, 226, 255),
        bg: UvColor.rgb(8, 10, 18),
      ),
      top: 0,
      right: 1,
      bottom: 0,
      left: 0,
    ),
  ];

  static final _allMask = (1 << _tiles.length) - 1;

  static const _dirUp = 0;
  static const _dirRight = 1;
  static const _dirDown = 2;
  static const _dirLeft = 3;

  static late final List<List<int>> _compatByDirAndTile;
  static bool _lutReady = false;

  final math.Random _rng;

  int width;
  int height;
  List<_Mask> _cells;

  bool contradiction = false;
  int steps = 0;

  int get totalCells => width * height;

  int get collapsedCount {
    var count = 0;
    for (final mask in _cells) {
      if (_isSingle(mask)) count++;
    }
    return count;
  }

  int get unresolvedCount {
    var count = 0;
    for (final mask in _cells) {
      if (!_isSingle(mask)) count++;
    }
    return count;
  }

  double get progress => totalCells == 0 ? 1.0 : collapsedCount / totalCells;

  bool get solved => !contradiction && unresolvedCount == 0;

  void reset() {
    contradiction = false;
    steps = 0;
    for (var i = 0; i < _cells.length; i++) {
      _cells[i] = _allMask;
    }
  }

  void resize(int newWidth, int newHeight) {
    final nextW = math.max(1, newWidth);
    final nextH = math.max(1, newHeight);
    if (nextW == width && nextH == height) return;

    final next = List<_Mask>.filled(nextW * nextH, _allMask, growable: false);
    final copyW = math.min(width, nextW);
    final copyH = math.min(height, nextH);

    for (var y = 0; y < copyH; y++) {
      for (var x = 0; x < copyW; x++) {
        next[y * nextW + x] = _cells[y * width + x];
      }
    }

    width = nextW;
    height = nextH;
    _cells = next;
    contradiction = _cells.any((mask) => mask == 0);
  }

  _Mask maskAt(int x, int y) => _cells[y * width + x];

  bool step() {
    if (contradiction || solved) return false;

    var minEntropy = 1 << 30;
    final candidateIndices = <int>[];

    for (var i = 0; i < _cells.length; i++) {
      final mask = _cells[i];
      final entropy = _bitCount(mask);
      if (entropy <= 1) continue;
      if (entropy < minEntropy) {
        minEntropy = entropy;
        candidateIndices
          ..clear()
          ..add(i);
      } else if (entropy == minEntropy) {
        candidateIndices.add(i);
      }
    }

    if (candidateIndices.isEmpty) {
      return false;
    }

    final pick = candidateIndices[_rng.nextInt(candidateIndices.length)];
    final chosenTile = _randomTileFromMask(_cells[pick]);
    _cells[pick] = 1 << chosenTile;

    final queue = ListQueue<int>()..add(pick);
    final changed = _propagate(queue);
    steps++;
    return changed;
  }

  bool _propagate(ListQueue<int> queue) {
    var changed = false;

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final x = idx % width;
      final y = idx ~/ width;
      final sourceMask = _cells[idx];

      bool restrictNeighbor(int nx, int ny, int dir) {
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) return false;
        final nIdx = ny * width + nx;
        final neighborMask = _cells[nIdx];
        final allowed = _allowedNeighborMask(sourceMask, dir);
        final restricted = neighborMask & allowed;
        if (restricted == neighborMask) return false;

        _cells[nIdx] = restricted;
        changed = true;
        if (restricted == 0) {
          contradiction = true;
          return true;
        }

        queue.add(nIdx);
        return false;
      }

      if (restrictNeighbor(x, y - 1, _dirUp)) return changed;
      if (restrictNeighbor(x + 1, y, _dirRight)) return changed;
      if (restrictNeighbor(x, y + 1, _dirDown)) return changed;
      if (restrictNeighbor(x - 1, y, _dirLeft)) return changed;
    }

    return changed;
  }

  int _allowedNeighborMask(int sourceMask, int dir) {
    var allowed = 0;
    for (var tile = 0; tile < _tiles.length; tile++) {
      if ((sourceMask & (1 << tile)) == 0) continue;
      allowed |= _compatByDirAndTile[dir][tile];
    }
    return allowed;
  }

  int _randomTileFromMask(int mask) {
    final options = <int>[];
    for (var tile = 0; tile < _tiles.length; tile++) {
      if ((mask & (1 << tile)) != 0) options.add(tile);
    }
    return options[_rng.nextInt(options.length)];
  }

  static int _bitCount(int value) {
    var count = 0;
    var v = value;
    while (v != 0) {
      v &= v - 1;
      count++;
    }
    return count;
  }

  static bool _isSingle(int mask) => mask > 0 && (mask & (mask - 1)) == 0;

  static int _firstBitIndex(int mask) {
    var idx = 0;
    var v = mask;
    while (v > 1) {
      v >>= 1;
      idx++;
    }
    return idx;
  }

  static void _buildCompatibilityLut() {
    if (_lutReady) return;

    _compatByDirAndTile = List<List<int>>.generate(
      4,
      (_) => List<int>.filled(_tiles.length, 0),
      growable: false,
    );

    for (var i = 0; i < _tiles.length; i++) {
      final a = _tiles[i];
      for (var j = 0; j < _tiles.length; j++) {
        final b = _tiles[j];
        if (a.top == b.bottom) {
          _compatByDirAndTile[_dirUp][i] |= 1 << j;
        }
        if (a.right == b.left) {
          _compatByDirAndTile[_dirRight][i] |= 1 << j;
        }
        if (a.bottom == b.top) {
          _compatByDirAndTile[_dirDown][i] |= 1 << j;
        }
        if (a.left == b.right) {
          _compatByDirAndTile[_dirLeft][i] |= 1 << j;
        }
      }
    }

    _lutReady = true;
  }
}

void _writeLine(
  Screen screen,
  int x,
  int y,
  String text, {
  required UvStyle style,
  required int maxWidth,
}) {
  final limit = math.min(text.length, math.max(0, maxWidth));
  for (var i = 0; i < limit; i++) {
    screen.setCell(x + i, y, Cell(content: text[i], style: style));
  }
}

void main() async {
  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();
  terminal.setScrollOptim(false);
  terminal.setSynchronizedOutput(true);

  final rng = math.Random();

  var hardClear = true;
  var running = false;
  var showEntropy = true;
  var stepsPerTick = 1;

  final base = terminal.bounds();
  final grid = _WfcGrid(
    math.max(1, base.width),
    math.max(1, base.height - 3),
    rng,
  );

  final unknownStyle = const UvStyle(
    fg: UvColor.rgb(88, 101, 126),
    bg: UvColor.rgb(8, 10, 18),
  );
  final entropyStyle = const UvStyle(
    fg: UvColor.rgb(188, 204, 228),
    bg: UvColor.rgb(8, 10, 18),
  );
  final contradictionStyle = const UvStyle(
    fg: UvColor.rgb(255, 122, 122),
    bg: UvColor.rgb(8, 10, 18),
    attrs: Attr.bold,
  );
  final hudStyle = const UvStyle(
    fg: UvColor.rgb(216, 225, 236),
    bg: UvColor.rgb(18, 24, 34),
  );
  final helpStyle = const UvStyle(
    fg: UvColor.rgb(146, 165, 190),
    bg: UvColor.rgb(18, 24, 34),
  );

  void resizeGrid(int width, int height) {
    final newW = math.max(1, width);
    final newH = math.max(1, height - 3);
    grid.resize(newW, newH);
    hardClear = true;
  }

  String statusText() {
    final pct = (grid.progress * 100).toStringAsFixed(1);
    final state = grid.contradiction
        ? 'contradiction'
        : grid.solved
        ? 'solved'
        : running
        ? 'running'
        : 'paused';
    return 'Wave Function Collapse  ${grid.collapsedCount}/${grid.totalCells} ($pct%)  steps:${grid.steps}  state:$state  batch:$stepsPerTick';
  }

  void drawGrid() {
    final h = grid.height;
    final w = grid.width;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final mask = grid.maskAt(x, y);
        if (mask == 0) {
          terminal.setCell(x, y, Cell(content: '!', style: contradictionStyle));
          continue;
        }

        if ((mask & (mask - 1)) == 0) {
          final tileIdx = _WfcGrid._firstBitIndex(mask);
          final tile = _WfcGrid._tiles[tileIdx];
          terminal.setCell(x, y, Cell(content: tile.glyph, style: tile.style));
          continue;
        }

        final entropy = _WfcGrid._bitCount(mask);
        if (showEntropy) {
          final ch = entropy <= 9 ? '$entropy' : '*';
          terminal.setCell(x, y, Cell(content: ch, style: entropyStyle));
        } else {
          terminal.setCell(x, y, Cell(content: '·', style: unknownStyle));
        }
      }
    }
  }

  void render() {
    final bounds = terminal.bounds();
    final nextW = math.max(1, bounds.width);
    final nextH = math.max(1, bounds.height - 3);
    if (grid.width != nextW || grid.height != nextH) {
      resizeGrid(bounds.width, bounds.height);
    }

    terminal.clear();
    if (hardClear) {
      terminal.clearScreen();
      hardClear = false;
    }

    terminal.fill(Cell(content: ' ', style: unknownStyle));
    drawGrid();

    if (bounds.height >= 3) {
      terminal.fillArea(
        Cell(content: ' ', style: hudStyle),
        rect(0, bounds.height - 3, bounds.width, 1),
      );
      _writeLine(
        terminal,
        0,
        bounds.height - 3,
        statusText(),
        style: hudStyle,
        maxWidth: bounds.width,
      );
    }

    if (bounds.height >= 2) {
      final entropyText = showEntropy ? 'entropy:on' : 'entropy:off';
      final flags =
          'unresolved:${grid.unresolvedCount}  $entropyText  ${grid.contradiction ? "press r to reset" : ""}';
      terminal.fillArea(
        Cell(content: ' ', style: hudStyle),
        rect(0, bounds.height - 2, bounds.width, 1),
      );
      _writeLine(
        terminal,
        0,
        bounds.height - 2,
        flags,
        style: hudStyle,
        maxWidth: bounds.width,
      );
    }

    if (bounds.height >= 1) {
      const help =
          'space run/pause  n step  r reset  +/- batch  e toggle entropy  q/esc/ctrl+c quit';
      terminal.fillArea(
        Cell(content: ' ', style: helpStyle),
        rect(0, bounds.height - 1, bounds.width, 1),
      );
      _writeLine(
        terminal,
        0,
        bounds.height - 1,
        help,
        style: helpStyle,
        maxWidth: bounds.width,
      );
    }

    terminal.draw();
  }

  final ticker = Timer.periodic(const Duration(milliseconds: 42), (_) {
    if (running && !grid.contradiction && !grid.solved) {
      for (var i = 0; i < stepsPerTick; i++) {
        final changed = grid.step();
        if (!changed || grid.contradiction || grid.solved) break;
      }
    }
    render();
  });

  try {
    render();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        resizeGrid(event.width, event.height);
        render();
        continue;
      }

      if (event is! KeyEvent) continue;
      if (event.matchString('q', 'esc', 'ctrl+c')) break;

      final key = event.key().text;
      if (event.matchString(' ')) {
        running = !running;
      } else if (event.matchString('n')) {
        if (!grid.contradiction && !grid.solved) {
          grid.step();
        }
      } else if (event.matchString('r')) {
        grid.reset();
        running = false;
      } else if (key == '+' || key == '=') {
        stepsPerTick = math.min(48, stepsPerTick + 1);
      } else if (key == '-') {
        stepsPerTick = math.max(1, stepsPerTick - 1);
      } else if (event.matchString('e')) {
        showEntropy = !showEntropy;
      }

      render();
    }
  } finally {
    ticker.cancel();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
