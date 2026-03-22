import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

final class Metaball {
  Metaball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });

  double x;
  double y;
  double vx;
  double vy;
  double radius;

  bool step(double dt, double worldWidth, double worldHeight) {
    x += vx * dt;
    y += vy * dt;

    final minX = 0.0;
    final minY = 0.0;
    final maxX = math.max(0.0, worldWidth - 1);
    final maxY = math.max(0.0, worldHeight - 1);

    var hitLeftWall = false;

    if (x < minX) {
      x = minX;
      vx = vx.abs();
      hitLeftWall = true;
    } else if (x > maxX) {
      x = maxX;
      vx = -vx.abs();
    }

    if (y < minY) {
      y = minY;
      vy = vy.abs();
    } else if (y > maxY) {
      y = maxY;
      vy = -vy.abs();
    }

    return hitLeftWall;
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

double _fieldAt(double x, double y, List<Metaball> metaballs) {
  var sum = 0.0;
  for (final ball in metaballs) {
    final dx = x - ball.x;
    final dy = y - ball.y;
    // Keeps field finite and smooth very near a metaball center.
    final d2 = dx * dx + dy * dy + 0.25;
    sum += (ball.radius * ball.radius) / d2;
  }
  return sum;
}

String _densityGlyph(double ratio) {
  const ramp = ' .:-=+*#%@';
  final clamped = ratio.clamp(0.0, 2.2);
  final index = ((clamped / 2.2) * (ramp.length - 1)).floor();
  return ramp[index];
}

const _marchingGlyph = <String>[
  ' ',
  ',',
  '.',
  '_',
  '.',
  '|',
  '/',
  '|',
  '\'',
  '\\',
  '-',
  '-',
  '\\',
  '|',
  '-',
  '#',
];

Metaball _spawnMetaball(math.Random rng, double width, double height) {
  final safeW = math.max(1.0, width);
  final safeH = math.max(1.0, height);
  return Metaball(
    x: rng.nextDouble() * safeW,
    y: rng.nextDouble() * safeH,
    vx: rng.nextDouble() * 20 - 10,
    vy: rng.nextDouble() * 20 - 10,
    radius: 2.2 + rng.nextDouble() * 4.2,
  );
}

String _sanitizeTimestamp(DateTime timestamp) =>
    timestamp.toIso8601String().replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '-');

String _visualizeBuffer(Buffer buffer) {
  final rows = <String>[];
  for (var y = 0; y < buffer.height(); y++) {
    final line = buffer.line(y);
    if (line == null) {
      rows.add('');
      continue;
    }
    final row = StringBuffer();
    for (var x = 0; x < line.length; x++) {
      final cell = line.at(x);
      if (cell == null || cell.width == 0) continue;
      final glyph = cell.content.isEmpty ? ' ' : cell.content;
      row.write(glyph == ' ' ? '_' : glyph);
    }
    rows.add(row.toString());
  }
  return rows.join('\n');
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
  var threshold = 2.8;
  var paused = false;
  var contourMode = true;
  var hardClear = true;
  var frameNumber = 0;
  var dumpOnNextLeftWall = false;
  String? lastDumpPath;

  final metaballs = <Metaball>[
    for (var i = 0; i < 6; i++) _spawnMetaball(rng, worldWidth, worldHeight),
  ];

  void resizeWorld(int width, int height) {
    worldWidth = math.max(1, width).toDouble();
    worldHeight = math.max(1, height - 2).toDouble();
    final maxX = worldWidth - 1;
    final maxY = worldHeight - 1;
    for (final ball in metaballs) {
      ball.x = ball.x.clamp(0.0, maxX);
      ball.y = ball.y.clamp(0.0, maxY);
    }
  }

  UvStyle styleForRatio(double ratio) {
    if (ratio < 0.75) {
      return const UvStyle(
        fg: UvColor.rgb(100, 133, 186),
        bg: UvColor.rgb(8, 14, 24),
      );
    }
    if (ratio < 1.1) {
      return const UvStyle(
        fg: UvColor.rgb(132, 187, 255),
        bg: UvColor.rgb(8, 14, 24),
      );
    }
    if (ratio < 1.5) {
      return const UvStyle(
        fg: UvColor.rgb(166, 231, 255),
        bg: UvColor.rgb(8, 14, 24),
        attrs: Attr.bold,
      );
    }
    return const UvStyle(
      fg: UvColor.rgb(255, 252, 210),
      bg: UvColor.rgb(8, 14, 24),
      attrs: Attr.bold,
    );
  }

  String writeAsciiDump(String reason) {
    final snapshot = terminal.clone();
    final emitted = terminal.lastDrawOutput;
    final stamp = _sanitizeTimestamp(DateTime.now());
    final file = File('metaballs_ascii_dump_$stamp.txt');
    final payload = StringBuffer()
      ..writeln('reason: $reason')
      ..writeln('frame: $frameNumber')
      ..writeln('mode: ${contourMode ? "contour" : "density"}')
      ..writeln('threshold: ${threshold.toStringAsFixed(2)}')
      ..writeln('size: ${snapshot.width()}x${snapshot.height()}')
      ..writeln('balls: ${metaballs.length}')
      ..writeln('')
      ..writeln('metaballs:')
      ..writeln(
        [
          for (var i = 0; i < metaballs.length; i++)
            '  [$i] x=${metaballs[i].x.toStringAsFixed(2)} '
                'y=${metaballs[i].y.toStringAsFixed(2)} '
                'vx=${metaballs[i].vx.toStringAsFixed(2)} '
                'vy=${metaballs[i].vy.toStringAsFixed(2)} '
                'r=${metaballs[i].radius.toStringAsFixed(2)}',
        ].join('\n'),
      )
      ..writeln('')
      ..writeln('ascii (spaces shown as _):')
      ..writeln(_visualizeBuffer(snapshot))
      ..writeln('')
      ..writeln('ansi render:')
      ..write(snapshot.render())
      ..writeln('')
      ..writeln('')
      ..writeln('last draw output escaped:')
      ..write(emitted.replaceAll('\x1b', '<ESC>'))
      ..writeln('')
      ..writeln('')
      ..writeln('last draw output raw:')
      ..write(emitted);
    file.writeAsStringSync(payload.toString());
    return file.absolute.path;
  }

  void render({String? dumpReason}) {
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

    for (var y = 0; y < playHeight; y++) {
      final y1 = math.min(playHeight - 1, y + 1);
      for (var x = 0; x < playWidth; x++) {
        final x1 = math.min(playWidth - 1, x + 1);

        final f00 = _fieldAt(x.toDouble(), y.toDouble(), metaballs);
        final f10 = _fieldAt(x1.toDouble(), y.toDouble(), metaballs);
        final f11 = _fieldAt(x1.toDouble(), y1.toDouble(), metaballs);
        final f01 = _fieldAt(x.toDouble(), y1.toDouble(), metaballs);
        final avg = (f00 + f10 + f11 + f01) / 4;
        final ratio = avg / threshold;

        if (!contourMode) {
          terminal.setCell(
            x,
            y,
            Cell(content: _densityGlyph(ratio), style: styleForRatio(ratio)),
          );
          continue;
        }

        var mask = 0;
        if (f00 >= threshold) mask |= 1;
        if (f10 >= threshold) mask |= 2;
        if (f11 >= threshold) mask |= 4;
        if (f01 >= threshold) mask |= 8;

        final glyph = _marchingGlyph[mask];
        terminal.setCell(
          x,
          y,
          Cell(content: glyph, style: styleForRatio(ratio)),
        );
      }
    }

    final hudStyle = const UvStyle(
      fg: UvColor.rgb(220, 230, 242),
      bg: UvColor.rgb(18, 24, 36),
    );
    final helpStyle = const UvStyle(
      fg: UvColor.rgb(160, 174, 196),
      bg: UvColor.rgb(18, 24, 36),
    );
    final status =
        'Metaballs Marching Squares  balls:${metaballs.length}  threshold:${threshold.toStringAsFixed(2)}'
        '  mode:${contourMode ? "contour" : "density"}  ${paused ? "paused" : "running"}'
        '  dump:${dumpOnNextLeftWall ? "armed" : (lastDumpPath == null ? "off" : "ready")}';
    const help =
        'q/esc/ctrl+c quit  [ ] threshold  b add  n remove  m mode  p pause  d arm-left-dump  D dump-now';

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
    frameNumber++;

    if (dumpReason != null) {
      lastDumpPath = writeAsciiDump(dumpReason);
    }
  }

  final clock = Stopwatch()..start();
  var lastTick = clock.elapsed;
  late final Timer ticker;
  ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
    final now = clock.elapsed;
    final dt = ((now - lastTick).inMicroseconds / 1000000.0).clamp(0.001, 0.08);
    lastTick = now;

    if (!paused) {
      var hitLeftWall = false;
      for (final ball in metaballs) {
        hitLeftWall = ball.step(dt, worldWidth, worldHeight) || hitLeftWall;
      }
      if (dumpOnNextLeftWall && hitLeftWall) {
        dumpOnNextLeftWall = false;
        render(dumpReason: 'left-wall-hit');
        return;
      }
    }
    render();
  });

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

      if (event is! KeyEvent) continue;
      if (event.matchString('q', 'esc', 'ctrl+c')) break;

      if (event.matchString('[')) {
        threshold = math.max(0.45, threshold - 0.12);
      } else if (event.matchString(']')) {
        threshold = math.min(7.0, threshold + 0.12);
      } else if (event.matchString('b')) {
        if (metaballs.length < 22) {
          metaballs.add(_spawnMetaball(rng, worldWidth, worldHeight));
        }
      } else if (event.matchString('n')) {
        if (metaballs.length > 1) {
          metaballs.removeLast();
        }
      } else if (event.matchString('m')) {
        contourMode = !contourMode;
      } else if (event.matchString('p', ' ')) {
        paused = !paused;
      } else if (event.matchString('d')) {
        dumpOnNextLeftWall = true;
      } else if (event.matchString('D')) {
        render(dumpReason: 'manual-dump');
        continue;
      }

      render();
    }
  } finally {
    ticker.cancel();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
    if (lastDumpPath != null) {
      stdout.writeln('Metaballs ASCII dump written to $lastDumpPath');
    }
  }
}
