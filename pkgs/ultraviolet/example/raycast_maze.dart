import 'dart:async';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

const _mapRows = <String>[
  '########################',
  '#..........#...........#',
  '#..####....#....####...#',
  '#..#..#....#....#..#...#',
  '#..#..#.........#..#...#',
  '#..####..#####..####...#',
  '#......................#',
  '#..####..#....#..####..#',
  '#..#.....#....#.....#..#',
  '#..#.....#....#.....#..#',
  '#..#.....######.....#..#',
  '#......................#',
  '#..####..######..####..#',
  '#..#..#..........#..#..#',
  '#..#..#..######..#..#..#',
  '#..####..#....#..####..#',
  '#........#....#........#',
  '#..####..#....#..####..#',
  '#..#.....#....#.....#..#',
  '#..#.....######.....#..#',
  '#......................#',
  '#..######......######..#',
  '#......................#',
  '########################',
];

const _fov = math.pi / 3.0; // 60 deg
const _maxDepth = 22.0;

final _sceneBgStyle = const UvStyle(
  fg: UvColor.rgb(42, 54, 78),
  bg: UvColor.rgb(8, 10, 18),
);
final _skyStyle = const UvStyle(
  fg: UvColor.rgb(120, 150, 220),
  bg: UvColor.rgb(8, 10, 18),
);
final _wallNearStyle = const UvStyle(
  fg: UvColor.rgb(242, 246, 255),
  bg: UvColor.rgb(8, 10, 18),
  attrs: Attr.bold,
);
final _wallMidStyle = const UvStyle(
  fg: UvColor.rgb(185, 196, 220),
  bg: UvColor.rgb(8, 10, 18),
);
final _wallFarStyle = const UvStyle(
  fg: UvColor.rgb(130, 142, 166),
  bg: UvColor.rgb(8, 10, 18),
);
final _floorNearStyle = const UvStyle(
  fg: UvColor.rgb(82, 102, 138),
  bg: UvColor.rgb(8, 10, 18),
);
final _floorFarStyle = const UvStyle(
  fg: UvColor.rgb(62, 76, 104),
  bg: UvColor.rgb(8, 10, 18),
);
final _hudStyle = const UvStyle(
  fg: UvColor.rgb(214, 223, 234),
  bg: UvColor.rgb(18, 24, 36),
);
final _helpStyle = const UvStyle(
  fg: UvColor.rgb(151, 166, 186),
  bg: UvColor.rgb(18, 24, 36),
);
final _miniWallStyle = const UvStyle(
  fg: UvColor.rgb(120, 132, 154),
  bg: UvColor.rgb(10, 13, 20),
);
final _miniFloorStyle = const UvStyle(
  fg: UvColor.rgb(48, 60, 80),
  bg: UvColor.rgb(10, 13, 20),
);
final _miniPlayerStyle = const UvStyle(
  fg: UvColor.rgb(255, 190, 110),
  bg: UvColor.rgb(10, 13, 20),
  attrs: Attr.bold,
);

bool _isWall(double x, double y) {
  final xi = x.floor();
  final yi = y.floor();
  if (yi < 0 || yi >= _mapRows.length) return true;
  if (xi < 0 || xi >= _mapRows[yi].length) return true;
  return _mapRows[yi][xi] == '#';
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

({String glyph, UvStyle style}) _wallShade(
  double distanceRatio,
  bool boundary,
) {
  if (boundary) return (glyph: '|', style: _wallFarStyle);
  if (distanceRatio < 0.18) return (glyph: '@', style: _wallNearStyle);
  if (distanceRatio < 0.34) return (glyph: '#', style: _wallNearStyle);
  if (distanceRatio < 0.52) return (glyph: 'x', style: _wallMidStyle);
  if (distanceRatio < 0.75) return (glyph: '+', style: _wallFarStyle);
  return (glyph: '.', style: _wallFarStyle);
}

({String glyph, UvStyle style}) _floorShade(double ratioFromHorizon) {
  if (ratioFromHorizon < 0.2) return (glyph: '.', style: _floorFarStyle);
  if (ratioFromHorizon < 0.5) return (glyph: '-', style: _floorFarStyle);
  if (ratioFromHorizon < 0.78) return (glyph: '=', style: _floorNearStyle);
  return (glyph: '#', style: _floorNearStyle);
}

void main() async {
  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();
  terminal.setScrollOptim(false);
  terminal.setSynchronizedOutput(true);

  var playerX = 10.5;
  var playerY = 6.5;
  var playerA = 0.0;

  var hardClear = true;
  var showMiniMap = false;
  var paused = false;
  var fpsEstimate = 0.0;
  var frameCount = 0;

  var moveSpeed = 3.8; // cells/sec
  var rotateSpeed = 2.4; // rad/sec

  int playWidth = math.max(20, terminal.bounds().width);
  int playHeight = math.max(6, terminal.bounds().height - 2);

  final clock = Stopwatch()..start();
  var lastElapsed = clock.elapsed;

  void clampPlayerToMap() {
    final maxX = _mapRows.first.length - 1.001;
    final maxY = _mapRows.length - 1.001;
    playerX = playerX.clamp(1.001, maxX);
    playerY = playerY.clamp(1.001, maxY);
  }

  void moveBy(double amount) {
    final nx = playerX + math.cos(playerA) * amount;
    final ny = playerY + math.sin(playerA) * amount;
    if (!_isWall(nx, playerY)) playerX = nx;
    if (!_isWall(playerX, ny)) playerY = ny;
    clampPlayerToMap();
  }

  void strafeBy(double amount) {
    final nx = playerX + math.cos(playerA + math.pi / 2) * amount;
    final ny = playerY + math.sin(playerA + math.pi / 2) * amount;
    if (!_isWall(nx, playerY)) playerX = nx;
    if (!_isWall(playerX, ny)) playerY = ny;
    clampPlayerToMap();
  }

  void turnBy(double amount) {
    playerA += amount;
    while (playerA < 0) {
      playerA += math.pi * 2;
    }
    while (playerA >= math.pi * 2) {
      playerA -= math.pi * 2;
    }
  }

  void handleResize(int width, int height) {
    terminal.resize(width, height);
    playWidth = math.max(20, width);
    playHeight = math.max(6, height - 2);
    hardClear = true;
  }

  void drawMiniMap() {
    if (!showMiniMap) return;
    const ox = 1;
    const oy = 1;
    final mapW = _mapRows.first.length;
    final mapH = _mapRows.length;
    if (ox + mapW + 1 >= playWidth || oy + mapH + 1 >= playHeight) return;

    for (var y = 0; y < mapH; y++) {
      final row = _mapRows[y];
      for (var x = 0; x < mapW; x++) {
        final c = row[x];
        terminal.setCell(
          ox + x,
          oy + y,
          Cell(
            content: c == '#' ? '█' : '·',
            style: c == '#' ? _miniWallStyle : _miniFloorStyle,
          ),
        );
      }
    }

    final px = ox + playerX.floor();
    final py = oy + playerY.floor();
    terminal.setCell(px, py, Cell(content: '@', style: _miniPlayerStyle));
    final fx = ox + (playerX + math.cos(playerA) * 1.2).floor();
    final fy = oy + (playerY + math.sin(playerA) * 1.2).floor();
    terminal.setCell(fx, fy, Cell(content: '•', style: _miniPlayerStyle));
  }

  void render() {
    if (hardClear) {
      terminal.clear();
      terminal.clearScreen();
      hardClear = false;
    } else {
      terminal.clear();
    }

    if (playWidth <= 0 || playHeight <= 0) {
      terminal.draw();
      return;
    }

    terminal.fillArea(
      Cell(content: '.', style: _sceneBgStyle),
      rect(0, 0, playWidth, playHeight),
    );

    final skyFlicker =
        0.92 + math.sin(clock.elapsedMilliseconds / 430.0) * 0.08;

    for (var x = 0; x < playWidth; x++) {
      final rayAngle = (playerA - _fov / 2) + (x / playWidth) * _fov;
      final eyeX = math.cos(rayAngle);
      final eyeY = math.sin(rayAngle);

      var distance = 0.0;
      var hitWall = false;
      var boundary = false;

      while (!hitWall && distance < _maxDepth) {
        distance += 0.035;
        final tx = (playerX + eyeX * distance).floor();
        final ty = (playerY + eyeY * distance).floor();

        if (ty < 0 ||
            ty >= _mapRows.length ||
            tx < 0 ||
            tx >= _mapRows[ty].length) {
          hitWall = true;
          distance = _maxDepth;
        } else if (_mapRows[ty][tx] == '#') {
          hitWall = true;

          final corners = <({double d, double dot})>[];
          for (var cx = 0; cx <= 1; cx++) {
            for (var cy = 0; cy <= 1; cy++) {
              final vx = tx + cx - playerX;
              final vy = ty + cy - playerY;
              final d = math.sqrt(vx * vx + vy * vy);
              if (d <= 0.0001) continue;
              final dot = (eyeX * vx / d) + (eyeY * vy / d);
              corners.add((d: d, dot: dot));
            }
          }
          corners.sort((a, b) => a.d.compareTo(b.d));
          if (corners.isNotEmpty) {
            final edge0 = math.acos(corners[0].dot.clamp(-1.0, 1.0));
            final edge1 = corners.length > 1
                ? math.acos(corners[1].dot.clamp(-1.0, 1.0))
                : edge0;
            boundary = edge0 < 0.025 || edge1 < 0.025;
          }
        }
      }

      final corrected = (distance * math.cos(rayAngle - playerA)).clamp(
        0.0001,
        _maxDepth,
      );
      final wallHeight = (playHeight / corrected).toInt();
      final ceiling = (playHeight / 2 - wallHeight / 2).toInt();
      final floor = playHeight - ceiling;
      final wall = _wallShade(corrected / _maxDepth, boundary);

      for (var y = 0; y < playHeight; y++) {
        if (y < ceiling) {
          final t = y / math.max(1, playHeight);
          final skyChar = (t * skyFlicker) < 0.25
              ? '.'
              : (t < 0.42 ? '^' : '*');
          terminal.setCell(x, y, Cell(content: skyChar, style: _skyStyle));
        } else if (y > floor) {
          final ratio = (y - playHeight / 2) / (playHeight / 2);
          final f = _floorShade(ratio.clamp(0.0, 1.0));
          terminal.setCell(x, y, Cell(content: f.glyph, style: f.style));
        } else {
          terminal.setCell(x, y, Cell(content: wall.glyph, style: wall.style));
        }
      }
    }

    drawMiniMap();

    final hud1 =
        'RAYCAST MAZE  fps:${fpsEstimate.toStringAsFixed(1)}  pos:${playerX.toStringAsFixed(2)},${playerY.toStringAsFixed(2)}  a:${playerA.toStringAsFixed(2)}';
    final hud2 =
        'w/s move  a/d rotate  j/l strafe  m map  p pause  r reset  q quit';

    if (terminal.bounds().height >= 2) {
      terminal.fillArea(
        Cell(content: ' ', style: _hudStyle),
        rect(0, terminal.bounds().height - 2, terminal.bounds().width, 1),
      );
      _writeLine(
        terminal,
        0,
        terminal.bounds().height - 2,
        hud1,
        style: _hudStyle,
        maxWidth: terminal.bounds().width,
      );
    }
    if (terminal.bounds().height >= 1) {
      terminal.fillArea(
        Cell(content: ' ', style: _helpStyle),
        rect(0, terminal.bounds().height - 1, terminal.bounds().width, 1),
      );
      _writeLine(
        terminal,
        0,
        terminal.bounds().height - 1,
        hud2,
        style: _helpStyle,
        maxWidth: terminal.bounds().width,
      );
    }

    terminal.draw();
  }

  final timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
    final now = clock.elapsed;
    final dt = (now - lastElapsed).inMicroseconds / 1000000.0;
    lastElapsed = now;
    if (dt > 0) {
      fpsEstimate = fpsEstimate == 0
          ? (1.0 / dt)
          : (fpsEstimate * 0.9 + (1.0 / dt) * 0.1);
    }
    frameCount++;

    if (!paused) {
      // Subtle idle sway to show motion even when standing still.
      if (frameCount % 120 == 0) {
        playerA += 0.0001;
      }
    }
    render();
  });

  try {
    render();
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        handleResize(event.width, event.height);
        render();
        continue;
      }
      if (event is! KeyEvent) continue;

      if (event.matchString('q', 'esc', 'ctrl+c')) {
        break;
      } else if (event.matchString('w', 'up')) {
        moveBy(moveSpeed * 0.09);
      } else if (event.matchString('s', 'down')) {
        moveBy(-moveSpeed * 0.09);
      } else if (event.matchString('a', 'left')) {
        turnBy(-rotateSpeed * 0.09);
      } else if (event.matchString('d', 'right')) {
        turnBy(rotateSpeed * 0.09);
      } else if (event.matchString('j')) {
        strafeBy(-moveSpeed * 0.08);
      } else if (event.matchString('l')) {
        strafeBy(moveSpeed * 0.08);
      } else if (event.matchString('m')) {
        showMiniMap = !showMiniMap;
      } else if (event.matchString('p', ' ')) {
        paused = !paused;
      } else if (event.matchString('r')) {
        playerX = 10.5;
        playerY = 6.5;
        playerA = 0.0;
        hardClear = true;
      }
      render();
    }
  } finally {
    timer.cancel();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
