import 'dart:async';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

final class LifeGrid {
  LifeGrid(this.width, this.height, {math.Random? random})
    : _rng = random ?? math.Random(),
      _cells = List<bool>.filled(width * height, false, growable: false),
      _next = List<bool>.filled(width * height, false, growable: false);

  int width;
  int height;
  final math.Random _rng;
  List<bool> _cells;
  List<bool> _next;

  int _index(int x, int y) => y * width + x;

  bool aliveAt(int x, int y) => _cells[_index(x, y)];

  void clear() {
    _cells.fillRange(0, _cells.length, false);
    _next.fillRange(0, _next.length, false);
  }

  void randomize({double density = 0.22}) {
    final clamped = density.clamp(0.0, 1.0);
    for (var i = 0; i < _cells.length; i++) {
      _cells[i] = _rng.nextDouble() < clamped;
    }
  }

  void resize(int newWidth, int newHeight) {
    final nextCells = List<bool>.filled(
      newWidth * newHeight,
      false,
      growable: false,
    );
    final preservedWidth = math.min(width, newWidth);
    final preservedHeight = math.min(height, newHeight);

    for (var y = 0; y < preservedHeight; y++) {
      for (var x = 0; x < preservedWidth; x++) {
        nextCells[y * newWidth + x] = _cells[_index(x, y)];
      }
    }

    width = newWidth;
    height = newHeight;
    _cells = nextCells;
    _next = List<bool>.filled(newWidth * newHeight, false, growable: false);
  }

  void step() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var neighbors = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
            if (_cells[_index(nx, ny)]) neighbors++;
          }
        }

        final idx = _index(x, y);
        final alive = _cells[idx];
        _next[idx] = neighbors == 3 || (alive && neighbors == 2);
      }
    }

    final tmp = _cells;
    _cells = _next;
    _next = tmp;
  }
}

void _writeLine(
  Screen screen,
  int x,
  int y,
  String text, {
  UvStyle style = const UvStyle(),
  int? maxWidth,
}) {
  final limit = maxWidth == null
      ? text.length
      : math.min(text.length, maxWidth);
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

  var tick = const Duration(milliseconds: 95);
  var running = true;
  var generation = 0;
  var hardClear = true;

  final seedDensity = 0.22;
  final base = terminal.bounds();
  final initialHeight = math.max(1, base.height - 2);
  final life = LifeGrid(math.max(1, base.width), initialHeight);
  life.randomize(density: seedDensity);

  void resizeModel(int width, int height) {
    final simW = math.max(1, width);
    final simH = math.max(1, height - 2);
    life.resize(simW, simH);
  }

  void render() {
    final bounds = terminal.bounds();
    final simW = math.max(1, bounds.width);
    final simH = math.max(1, bounds.height - 2);
    if (life.width != simW || life.height != simH) {
      life.resize(simW, simH);
    }

    terminal.clear();
    if (hardClear) {
      terminal.clearScreen();
      hardClear = false;
    }

    final deadStyle = const UvStyle(bg: UvColor.rgb(8, 12, 22));
    final aliveStyle = const UvStyle(
      fg: UvColor.rgb(42, 240, 167),
      bg: UvColor.rgb(8, 12, 22),
      attrs: Attr.bold,
    );

    terminal.fill(Cell(content: ' ', style: deadStyle));
    for (var y = 0; y < simH; y++) {
      for (var x = 0; x < simW; x++) {
        if (!life.aliveAt(x, y)) continue;
        terminal.setCell(x, y, Cell(content: '█', style: aliveStyle));
      }
    }

    final statusStyle = const UvStyle(
      fg: UvColor.rgb(220, 226, 236),
      bg: UvColor.rgb(20, 24, 34),
    );
    final helpStyle = const UvStyle(
      fg: UvColor.rgb(150, 165, 186),
      bg: UvColor.rgb(20, 24, 34),
    );
    final speedMs = tick.inMilliseconds;
    final status =
        'Conway Life  gen:$generation  ${running ? "running" : "paused"}  step:${speedMs}ms';
    final help =
        'space pause/resume  n step  r randomize  c clear  +/- speed  q quit';

    if (bounds.height >= 2) {
      terminal.fillArea(
        Cell(content: ' ', style: statusStyle),
        rect(0, bounds.height - 2, bounds.width, 1),
      );
      _writeLine(
        terminal,
        0,
        bounds.height - 2,
        status,
        style: statusStyle,
        maxWidth: bounds.width,
      );
    }
    if (bounds.height >= 1) {
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

  Timer? timer;
  timer = Timer.periodic(tick, (_) {
    if (running) {
      life.step();
      generation++;
    }
    render();
  });

  try {
    render();
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        resizeModel(event.width, event.height);
        hardClear = true;
        render();
        continue;
      }

      if (event is! KeyEvent) continue;
      if (event.matchString('q', 'ctrl+c', 'esc')) break;

      final key = event.key().text;
      if (event.matchString(' ')) {
        running = !running;
      } else if (event.matchString('n')) {
        life.step();
        generation++;
      } else if (event.matchString('r')) {
        life.randomize(density: seedDensity);
        generation = 0;
      } else if (event.matchString('c')) {
        life.clear();
        generation = 0;
      } else if (key == '+' || key == '=') {
        final next = math.max(25, tick.inMilliseconds - 10);
        tick = Duration(milliseconds: next);
        timer?.cancel();
        timer = Timer.periodic(tick, (_) {
          if (running) {
            life.step();
            generation++;
          }
          render();
        });
      } else if (key == '-') {
        final next = math.min(450, tick.inMilliseconds + 10);
        tick = Duration(milliseconds: next);
        timer?.cancel();
        timer = Timer.periodic(tick, (_) {
          if (running) {
            life.step();
            generation++;
          }
          render();
        });
      }

      render();
    }
  } finally {
    timer?.cancel();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
