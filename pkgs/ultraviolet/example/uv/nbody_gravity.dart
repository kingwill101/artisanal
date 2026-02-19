import 'dart:async';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

final class _Body {
  _Body({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.mass,
  });

  double x;
  double y;
  double vx;
  double vy;
  double mass;
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

int _indexOfPeak(double value) {
  if (value < 0.03) return 0;
  if (value < 0.08) return 1;
  if (value < 0.16) return 2;
  if (value < 0.28) return 3;
  if (value < 0.46) return 4;
  if (value < 0.72) return 5;
  if (value < 1.05) return 6;
  return 7;
}

void main() async {
  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();
  terminal.setScrollOptim(false);
  terminal.setSynchronizedOutput(true);

  final random = math.Random();

  var hardClear = true;
  var running = true;
  var trailsEnabled = true;

  var bodyCount = 140;
  var timeStep = 0.006;
  var timeScale = 1.0;

  const gravConst = 0.55;
  const softening = 0.006;
  const velocityDamping = 0.9994;

  var simWidth = math.max(1, terminal.bounds().width);
  var simHeight = math.max(1, terminal.bounds().height - 2);
  var trailField = List<double>.filled(simWidth * simHeight, 0.0);

  final bodies = <_Body>[];

  final ramp = [' ', '.', ':', '-', '=', '+', '*', '@'];
  final rampStyles = <UvStyle>[
    const UvStyle(bg: UvColor.rgb(4, 7, 14)),
    const UvStyle(fg: UvColor.rgb(66, 91, 136), bg: UvColor.rgb(4, 7, 14)),
    const UvStyle(fg: UvColor.rgb(84, 120, 180), bg: UvColor.rgb(4, 7, 14)),
    const UvStyle(fg: UvColor.rgb(108, 151, 210), bg: UvColor.rgb(4, 7, 14)),
    const UvStyle(fg: UvColor.rgb(132, 182, 236), bg: UvColor.rgb(4, 7, 14)),
    const UvStyle(fg: UvColor.rgb(164, 215, 247), bg: UvColor.rgb(4, 7, 14)),
    const UvStyle(fg: UvColor.rgb(210, 235, 255), bg: UvColor.rgb(4, 7, 14)),
    const UvStyle(
      fg: UvColor.rgb(255, 244, 186),
      bg: UvColor.rgb(4, 7, 14),
      attrs: Attr.bold,
    ),
  ];

  final hudStyle = const UvStyle(
    fg: UvColor.rgb(216, 225, 236),
    bg: UvColor.rgb(18, 24, 34),
  );
  final helpStyle = const UvStyle(
    fg: UvColor.rgb(146, 165, 190),
    bg: UvColor.rgb(18, 24, 34),
  );
  final bodyStyle = const UvStyle(
    fg: UvColor.rgb(255, 240, 180),
    bg: UvColor.rgb(4, 7, 14),
    attrs: Attr.bold,
  );

  void resetBodies() {
    bodies
      ..clear()
      ..addAll(
        List<_Body>.generate(bodyCount, (index) {
          final angle = random.nextDouble() * math.pi * 2;
          final radius = math.sqrt(random.nextDouble()) * 0.43;
          final cx = 0.5 + math.cos(angle) * radius;
          final cy = 0.5 + math.sin(angle) * radius;
          final tangent = angle + math.pi / 2;
          final orbital =
              (0.28 - radius * 0.25) * (0.8 + random.nextDouble() * 0.5);
          return _Body(
            x: cx,
            y: cy,
            vx: math.cos(tangent) * orbital,
            vy: math.sin(tangent) * orbital,
            mass: 0.6 + random.nextDouble() * 1.8,
          );
        }),
      );

    for (var i = 0; i < trailField.length; i++) {
      trailField[i] = 0.0;
    }
    hardClear = true;
  }

  void resizeSimulation(int width, int height) {
    simWidth = math.max(1, width);
    simHeight = math.max(1, height - 2);
    trailField = List<double>.filled(simWidth * simHeight, 0.0);
    hardClear = true;
  }

  void integrate(double dt) {
    if (bodies.isEmpty) return;

    final ax = List<double>.filled(bodies.length, 0.0);
    final ay = List<double>.filled(bodies.length, 0.0);

    for (var i = 0; i < bodies.length; i++) {
      final bi = bodies[i];
      for (var j = i + 1; j < bodies.length; j++) {
        final bj = bodies[j];

        var dx = bj.x - bi.x;
        var dy = bj.y - bi.y;

        if (dx > 0.5) dx -= 1.0;
        if (dx < -0.5) dx += 1.0;
        if (dy > 0.5) dy -= 1.0;
        if (dy < -0.5) dy += 1.0;

        final dist2 = dx * dx + dy * dy + softening * softening;
        final invDist = 1.0 / math.sqrt(dist2);
        final invDist3 = invDist * invDist * invDist;
        final factor = gravConst * invDist3;

        ax[i] += dx * factor * bj.mass;
        ay[i] += dy * factor * bj.mass;
        ax[j] -= dx * factor * bi.mass;
        ay[j] -= dy * factor * bi.mass;
      }
    }

    for (var i = 0; i < bodies.length; i++) {
      final body = bodies[i];
      body.vx = (body.vx + ax[i] * dt) * velocityDamping;
      body.vy = (body.vy + ay[i] * dt) * velocityDamping;
      body.x += body.vx * dt;
      body.y += body.vy * dt;

      if (body.x < 0) {
        body.x += 1.0;
      } else if (body.x >= 1.0) {
        body.x -= 1.0;
      }
      if (body.y < 0) {
        body.y += 1.0;
      } else if (body.y >= 1.0) {
        body.y -= 1.0;
      }
    }
  }

  void stampBodiesToField() {
    final decay = trailsEnabled ? 0.918 : 0.0;
    for (var i = 0; i < trailField.length; i++) {
      trailField[i] *= decay;
    }

    for (final body in bodies) {
      final px = (body.x * (simWidth - 1)).round().clamp(0, simWidth - 1);
      final py = (body.y * (simHeight - 1)).round().clamp(0, simHeight - 1);

      final center = py * simWidth + px;
      trailField[center] += 0.54 * body.mass;

      for (var oy = -1; oy <= 1; oy++) {
        final y = py + oy;
        if (y < 0 || y >= simHeight) continue;
        for (var ox = -1; ox <= 1; ox++) {
          if (ox == 0 && oy == 0) continue;
          final x = px + ox;
          if (x < 0 || x >= simWidth) continue;
          final d = math.sqrt((ox * ox + oy * oy).toDouble());
          final idx = y * simWidth + x;
          trailField[idx] += (0.14 / (1.0 + d)) * body.mass;
        }
      }
    }
  }

  void render() {
    final bounds = terminal.bounds();
    final nextW = math.max(1, bounds.width);
    final nextH = math.max(1, bounds.height - 2);
    if (nextW != simWidth || nextH != simHeight) {
      resizeSimulation(bounds.width, bounds.height);
    }

    terminal.clear();
    if (hardClear) {
      terminal.clearScreen();
      hardClear = false;
    }

    for (var y = 0; y < simHeight; y++) {
      final rowStart = y * simWidth;
      for (var x = 0; x < simWidth; x++) {
        final density = trailField[rowStart + x];
        final peak = _indexOfPeak(density);
        terminal.setCell(
          x,
          y,
          Cell(content: ramp[peak], style: rampStyles[peak]),
        );
      }
    }

    for (final body in bodies) {
      final x = (body.x * (simWidth - 1)).round().clamp(0, simWidth - 1);
      final y = (body.y * (simHeight - 1)).round().clamp(0, simHeight - 1);
      terminal.setCell(x, y, Cell(content: '●', style: bodyStyle));
    }

    final status =
        'N-body gravity  bodies:${bodies.length}  ${running ? "running" : "paused"}  dt:${(timeStep * 1000).toStringAsFixed(1)}ms  speed:${timeScale.toStringAsFixed(2)}x  trails:${trailsEnabled ? "on" : "off"}';
    final help =
        'space pause/resume  +/- dt  [/] speed  t trails  r reset  b/B bodies +/-20  q/esc/ctrl+c quit';

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

  resetBodies();

  final clock = Stopwatch()..start();
  var lastElapsed = clock.elapsed;
  var accumulator = 0.0;

  final ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
    final now = clock.elapsed;
    var frameDt = (now - lastElapsed).inMicroseconds / 1000000.0;
    lastElapsed = now;

    frameDt = frameDt.clamp(0.0, 0.08);

    if (running) {
      accumulator += frameDt * timeScale;
      var subSteps = 0;
      while (accumulator >= timeStep && subSteps < 22) {
        integrate(timeStep);
        accumulator -= timeStep;
        subSteps++;
      }
      stampBodiesToField();
    } else if (!trailsEnabled) {
      stampBodiesToField();
    }

    render();
  });

  try {
    render();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        resizeSimulation(event.width, event.height);
        render();
        continue;
      }

      if (event is! KeyEvent) continue;
      if (event.matchString('q', 'esc', 'ctrl+c')) break;

      final key = event.key().text;
      if (event.matchString(' ')) {
        running = !running;
      } else if (key == '+' || key == '=') {
        timeStep = math.max(0.0015, timeStep * 0.85);
      } else if (key == '-') {
        timeStep = math.min(0.030, timeStep * 1.15);
      } else if (event.matchString(']')) {
        timeScale = math.min(8.0, timeScale * 1.2);
      } else if (event.matchString('[')) {
        timeScale = math.max(0.1, timeScale / 1.2);
      } else if (event.matchString('t')) {
        trailsEnabled = !trailsEnabled;
        if (!trailsEnabled) {
          for (var i = 0; i < trailField.length; i++) {
            trailField[i] = 0.0;
          }
        }
      } else if (event.matchString('r')) {
        resetBodies();
      } else if (event.matchString('b')) {
        bodyCount = math.min(560, bodyCount + 20);
        resetBodies();
      } else if (event.matchString('B')) {
        bodyCount = math.max(20, bodyCount - 20);
        resetBodies();
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
