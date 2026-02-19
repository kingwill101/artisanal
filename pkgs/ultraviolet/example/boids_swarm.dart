import 'dart:async';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

final class Boid {
  Boid({required this.x, required this.y, required this.vx, required this.vy});

  double x;
  double y;
  double vx;
  double vy;
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

double _length(double x, double y) => math.sqrt(x * x + y * y);

void _limitVector(List<double> v, double maxValue) {
  final m = _length(v[0], v[1]);
  if (m <= maxValue || m <= 0.000001) return;
  final scale = maxValue / m;
  v[0] *= scale;
  v[1] *= scale;
}

String _boidGlyph(double vx, double vy) {
  if (vx.abs() > vy.abs() * 1.8) return vx >= 0 ? '>' : '<';
  if (vy.abs() > vx.abs() * 1.8) return vy >= 0 ? 'v' : '^';
  if (vx >= 0 && vy >= 0) return '\\';
  if (vx >= 0 && vy < 0) return '/';
  if (vx < 0 && vy >= 0) return '/';
  return '\\';
}

Boid _spawnBoid(math.Random rng, double worldWidth, double worldHeight) {
  final angle = rng.nextDouble() * math.pi * 2;
  final speed = 8 + rng.nextDouble() * 10;
  return Boid(
    x: rng.nextDouble() * math.max(1.0, worldWidth),
    y: rng.nextDouble() * math.max(1.0, worldHeight),
    vx: math.cos(angle) * speed,
    vy: math.sin(angle) * speed,
  );
}

void main() async {
  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();
  terminal.setScrollOptim(false);
  terminal.setSynchronizedOutput(true);

  final rng = math.Random();

  var worldWidth = math.max(1, terminal.bounds().width).toDouble();
  var worldHeight = math.max(1, terminal.bounds().height - 2).toDouble();

  var separationWeight = 1.45;
  var alignmentWeight = 0.82;
  var cohesionWeight = 0.68;
  var paused = false;
  var hardClear = true;

  var forceEnabled = false;
  var useMouseForce = false;
  var repelMode = false;
  var forceX = worldWidth / 2;
  var forceY = worldHeight / 2;

  final boids = <Boid>[];

  int recommendedBoidCount(double width, double height) {
    final estimate = (width * height / 26).round();
    return estimate.clamp(30, 150);
  }

  void resizeWorld(int width, int height) {
    worldWidth = math.max(1, width).toDouble();
    worldHeight = math.max(1, height - 2).toDouble();
    final maxX = worldWidth - 1;
    final maxY = worldHeight - 1;
    for (final boid in boids) {
      boid.x = boid.x.clamp(0.0, maxX);
      boid.y = boid.y.clamp(0.0, maxY);
    }
    forceX = forceX.clamp(0.0, maxX);
    forceY = forceY.clamp(0.0, maxY);
  }

  void repopulate([int? count]) {
    boids.clear();
    final total = count ?? recommendedBoidCount(worldWidth, worldHeight);
    for (var i = 0; i < total; i++) {
      boids.add(_spawnBoid(rng, worldWidth, worldHeight));
    }
  }

  repopulate();

  UvStyle styleForSpeed(double speed) {
    if (speed < 8) {
      return const UvStyle(
        fg: UvColor.rgb(150, 180, 205),
        bg: UvColor.rgb(8, 12, 24),
      );
    }
    if (speed < 13) {
      return const UvStyle(
        fg: UvColor.rgb(140, 226, 214),
        bg: UvColor.rgb(8, 12, 24),
      );
    }
    return const UvStyle(
      fg: UvColor.rgb(255, 242, 176),
      bg: UvColor.rgb(8, 12, 24),
      attrs: Attr.bold,
    );
  }

  void stepFlock(double dt) {
    if (boids.isEmpty) return;

    const neighborRadius = 9.0;
    const separationRadius = 2.4;
    const minSpeed = 4.5;
    const maxSpeed = 18.0;
    const maxForce = 30.0;
    const attractStrength = 62.0;
    final neighborRadius2 = neighborRadius * neighborRadius;
    final separationRadius2 = separationRadius * separationRadius;
    final ax = List<double>.filled(boids.length, 0.0);
    final ay = List<double>.filled(boids.length, 0.0);

    for (var i = 0; i < boids.length; i++) {
      final boid = boids[i];
      var sepX = 0.0;
      var sepY = 0.0;
      var alignX = 0.0;
      var alignY = 0.0;
      var cohX = 0.0;
      var cohY = 0.0;
      var neighborCount = 0;

      for (var j = 0; j < boids.length; j++) {
        if (i == j) continue;
        final other = boids[j];
        final dx = other.x - boid.x;
        final dy = other.y - boid.y;
        final d2 = dx * dx + dy * dy;
        if (d2 > neighborRadius2 || d2 <= 0.000001) continue;

        neighborCount++;
        alignX += other.vx;
        alignY += other.vy;
        cohX += other.x;
        cohY += other.y;

        if (d2 < separationRadius2) {
          final inv = 1.0 / d2;
          sepX -= dx * inv;
          sepY -= dy * inv;
        }
      }

      var forceXAcc = 0.0;
      var forceYAcc = 0.0;
      if (neighborCount > 0) {
        alignX = (alignX / neighborCount) - boid.vx;
        alignY = (alignY / neighborCount) - boid.vy;
        cohX = (cohX / neighborCount) - boid.x;
        cohY = (cohY / neighborCount) - boid.y;

        forceXAcc += sepX * separationWeight;
        forceYAcc += sepY * separationWeight;
        forceXAcc += alignX * alignmentWeight;
        forceYAcc += alignY * alignmentWeight;
        forceXAcc += cohX * cohesionWeight;
        forceYAcc += cohY * cohesionWeight;
      }

      if (forceEnabled) {
        final dx = forceX - boid.x;
        final dy = forceY - boid.y;
        final d = _length(dx, dy);
        if (d > 0.0001) {
          final polarity = repelMode ? -1.0 : 1.0;
          final strength = attractStrength * polarity;
          forceXAcc += (dx / d) * strength;
          forceYAcc += (dy / d) * strength;
        }
      }

      final force = [forceXAcc, forceYAcc];
      _limitVector(force, maxForce);
      ax[i] = force[0];
      ay[i] = force[1];

      // Keeps manual force cursor inside world for key-driven interaction.
      forceX = forceX.clamp(0.0, math.max(0.0, worldWidth - 1));
      forceY = forceY.clamp(0.0, math.max(0.0, worldHeight - 1));

      if (!useMouseForce && forceEnabled && i == 0) {
        forceX = forceX.clamp(0.0, worldWidth - 1);
        forceY = forceY.clamp(0.0, worldHeight - 1);
      }
    }

    final maxX = math.max(0.0, worldWidth - 1);
    final maxY = math.max(0.0, worldHeight - 1);

    for (var i = 0; i < boids.length; i++) {
      final boid = boids[i];
      boid.vx += ax[i] * dt;
      boid.vy += ay[i] * dt;

      final speed = _length(boid.vx, boid.vy);
      if (speed > maxSpeed) {
        final s = maxSpeed / speed;
        boid.vx *= s;
        boid.vy *= s;
      } else if (speed < minSpeed) {
        final baseX = boid.vx.abs() < 0.001
            ? (rng.nextDouble() * 2 - 1)
            : boid.vx;
        final baseY = boid.vy.abs() < 0.001
            ? (rng.nextDouble() * 2 - 1)
            : boid.vy;
        final m = _length(baseX, baseY).clamp(0.001, double.infinity);
        boid.vx = (baseX / m) * minSpeed;
        boid.vy = (baseY / m) * minSpeed;
      }

      boid.x += boid.vx * dt;
      boid.y += boid.vy * dt;

      if (boid.x < 0) {
        boid.x = 0;
        boid.vx = boid.vx.abs();
      } else if (boid.x > maxX) {
        boid.x = maxX;
        boid.vx = -boid.vx.abs();
      }
      if (boid.y < 0) {
        boid.y = 0;
        boid.vy = boid.vy.abs();
      } else if (boid.y > maxY) {
        boid.y = maxY;
        boid.vy = -boid.vy.abs();
      }
    }
  }

  void render() {
    final bounds = terminal.bounds();
    final playWidth = math.max(1, bounds.width);
    final playHeight = math.max(1, bounds.height - 2);
    if (playWidth.toDouble() != worldWidth ||
        playHeight.toDouble() != worldHeight) {
      resizeWorld(playWidth, bounds.height);
    }

    terminal.clear();
    if (hardClear) {
      terminal.clearScreen();
      hardClear = false;
    }

    final fieldStyle = const UvStyle(
      fg: UvColor.rgb(64, 84, 120),
      bg: UvColor.rgb(8, 12, 24),
    );
    terminal.fillArea(
      Cell(content: '.', style: fieldStyle),
      rect(0, 0, playWidth, playHeight),
    );

    for (final boid in boids) {
      final px = boid.x.round().clamp(0, playWidth - 1);
      final py = boid.y.round().clamp(0, playHeight - 1);
      final speed = _length(boid.vx, boid.vy);
      terminal.setCell(
        px,
        py,
        Cell(
          content: _boidGlyph(boid.vx, boid.vy),
          style: styleForSpeed(speed),
        ),
      );
    }

    if (forceEnabled) {
      final markerStyle = repelMode
          ? const UvStyle(
              fg: UvColor.rgb(255, 120, 120),
              bg: UvColor.rgb(8, 12, 24),
              attrs: Attr.bold,
            )
          : const UvStyle(
              fg: UvColor.rgb(255, 216, 120),
              bg: UvColor.rgb(8, 12, 24),
              attrs: Attr.bold,
            );
      final fx = forceX.round().clamp(0, playWidth - 1);
      final fy = forceY.round().clamp(0, playHeight - 1);
      terminal.setCell(
        fx,
        fy,
        Cell(content: repelMode ? 'X' : 'O', style: markerStyle),
      );
    }

    final hudStyle = const UvStyle(
      fg: UvColor.rgb(222, 232, 246),
      bg: UvColor.rgb(18, 24, 36),
    );
    final helpStyle = const UvStyle(
      fg: UvColor.rgb(158, 176, 200),
      bg: UvColor.rgb(18, 24, 36),
    );

    final status =
        'Boids Swarm  n:${boids.length}  sep:${separationWeight.toStringAsFixed(2)}'
        '  ali:${alignmentWeight.toStringAsFixed(2)}  coh:${cohesionWeight.toStringAsFixed(2)}'
        '  force:${forceEnabled ? (repelMode ? "repel" : "attract") : "off"}'
        '  ${paused ? "paused" : "running"}';
    final help =
        'q/esc/ctrl+c quit  p pause  z/x sep  a/s align  c/v cohesion  f force  g invert'
        '  m mouse  i/j/k/l move  +/- boids  r reset';

    if (bounds.height >= 2) {
      terminal.fillArea(
        Cell(content: ' ', style: hudStyle),
        rect(0, bounds.height - 2, bounds.width, 1),
      );
      _writeLine(
        terminal,
        0,
        bounds.height - 2,
        status,
        style: hudStyle,
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

  final clock = Stopwatch()..start();
  var lastTick = clock.elapsed;
  late final Timer ticker;
  ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
    final now = clock.elapsed;
    final dt = ((now - lastTick).inMicroseconds / 1000000.0).clamp(0.001, 0.08);
    lastTick = now;
    if (!paused) {
      stepFlock(dt);
    }
    render();
  });

  void moveForceBy(double dx, double dy) {
    forceX = (forceX + dx).clamp(0.0, math.max(0.0, worldWidth - 1));
    forceY = (forceY + dy).clamp(0.0, math.max(0.0, worldHeight - 1));
  }

  try {
    render();
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        resizeWorld(event.width, event.height);
        hardClear = true;
        render();
        continue;
      }

      if (event is MouseEvent && useMouseForce) {
        forceEnabled = true;
        forceX = event.mouse().x.toDouble().clamp(
          0.0,
          math.max(0.0, worldWidth - 1),
        );
        forceY = event.mouse().y.toDouble().clamp(
          0.0,
          math.max(0.0, worldHeight - 1),
        );
        continue;
      }

      if (event is! KeyEvent) continue;
      if (event.matchString('q', 'esc', 'ctrl+c')) break;

      final keyText = event.key().text;
      if (event.matchString('p', ' ')) {
        paused = !paused;
      } else if (event.matchString('z')) {
        separationWeight = math.max(0.1, separationWeight - 0.08);
      } else if (event.matchString('x')) {
        separationWeight = math.min(3.5, separationWeight + 0.08);
      } else if (event.matchString('a')) {
        alignmentWeight = math.max(0.0, alignmentWeight - 0.06);
      } else if (event.matchString('s')) {
        alignmentWeight = math.min(2.4, alignmentWeight + 0.06);
      } else if (event.matchString('c')) {
        cohesionWeight = math.max(0.0, cohesionWeight - 0.06);
      } else if (event.matchString('v')) {
        cohesionWeight = math.min(2.4, cohesionWeight + 0.06);
      } else if (event.matchString('f')) {
        forceEnabled = !forceEnabled;
      } else if (event.matchString('g')) {
        repelMode = !repelMode;
      } else if (event.matchString('m')) {
        useMouseForce = !useMouseForce;
        if (useMouseForce) {
          terminal.enableMouse();
        } else {
          terminal.disableMouse();
        }
      } else if (event.matchString('i', 'up')) {
        forceEnabled = true;
        moveForceBy(0, -3);
      } else if (event.matchString('k', 'down')) {
        forceEnabled = true;
        moveForceBy(0, 3);
      } else if (event.matchString('j', 'left')) {
        forceEnabled = true;
        moveForceBy(-3, 0);
      } else if (event.matchString('l', 'right')) {
        forceEnabled = true;
        moveForceBy(3, 0);
      } else if (keyText == '+' || keyText == '=') {
        if (boids.length < 220) {
          boids.add(_spawnBoid(rng, worldWidth, worldHeight));
        }
      } else if (keyText == '-') {
        if (boids.length > 5) {
          boids.removeLast();
        }
      } else if (event.matchString('r')) {
        repopulate();
      }

      render();
    }
  } finally {
    ticker.cancel();
    terminal.disableMouse();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
