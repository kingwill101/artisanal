import 'dart:async';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

const _glyphRamp = ' .,:;irsXA253hMHGS#9B&@';

const _hudStyle = UvStyle(
  fg: UvColor.rgb(222, 230, 240),
  bg: UvColor.rgb(18, 24, 32),
);
const _helpStyle = UvStyle(
  fg: UvColor.rgb(150, 168, 186),
  bg: UvColor.rgb(12, 17, 24),
);

void _writeLine(
  Screen screen,
  int x,
  int y,
  String text, {
  required int maxWidth,
  required UvStyle style,
}) {
  final limit = math.min(text.length, math.max(0, maxWidth));
  for (var i = 0; i < limit; i++) {
    screen.setCell(x + i, y, Cell(content: text[i], style: style));
  }
}

UvColor _hsvToRgb(double h, double s, double v) {
  final hh = (h % 1.0 + 1.0) % 1.0;
  final c = v * s;
  final x = c * (1.0 - ((hh * 6.0) % 2.0 - 1.0).abs());
  final m = v - c;

  double rPrime;
  double gPrime;
  double bPrime;

  if (hh < 1.0 / 6.0) {
    rPrime = c;
    gPrime = x;
    bPrime = 0;
  } else if (hh < 2.0 / 6.0) {
    rPrime = x;
    gPrime = c;
    bPrime = 0;
  } else if (hh < 3.0 / 6.0) {
    rPrime = 0;
    gPrime = c;
    bPrime = x;
  } else if (hh < 4.0 / 6.0) {
    rPrime = 0;
    gPrime = x;
    bPrime = c;
  } else if (hh < 5.0 / 6.0) {
    rPrime = x;
    gPrime = 0;
    bPrime = c;
  } else {
    rPrime = c;
    gPrime = 0;
    bPrime = x;
  }

  final r = ((rPrime + m) * 255).round().clamp(0, 255);
  final g = ((gPrime + m) * 255).round().clamp(0, 255);
  final b = ((bPrime + m) * 255).round().clamp(0, 255);
  return UvColor.rgb(r, g, b);
}

double _fieldValue(int mode, double nx, double ny, double t) {
  final dist = math.sqrt(nx * nx + ny * ny);
  switch (mode) {
    case 0:
      return (math.sin(nx * 4.0 + t * 0.9) +
              math.sin((nx + ny) * 3.3 - t * 1.4) +
              math.cos(dist * 11.0 - t * 1.1)) /
          3.0;
    case 1:
      final angle = math.atan2(ny, nx);
      return (math.sin(14.0 * angle + t * 1.6) + math.cos(7.0 / (dist + 0.2))) *
          0.5;
    case 2:
      final warpX = nx + math.sin(ny * 4.0 + t * 0.8) * 0.28;
      final warpY = ny + math.cos(nx * 5.0 - t * 1.2) * 0.22;
      final d = math.sqrt(warpX * warpX + warpY * warpY);
      return math.sin((warpX * warpY) * 9.0 + t * 1.5) * 0.6 +
          math.cos(d * 14.0 - t * 1.1) * 0.4;
    default:
      return math.sin(nx * 12.0 + t * 1.2) * math.cos(ny * 10.0 - t * 1.3);
  }
}

double _modeHue(int mode) {
  switch (mode) {
    case 0:
      return 0.58;
    case 1:
      return 0.02;
    case 2:
      return 0.34;
    default:
      return 0.76;
  }
}

void main() async {
  final terminal = Terminal();
  Timer? ticker;

  var started = false;
  var inAltScreen = false;
  var cursorHidden = false;

  try {
    await terminal.start();
    started = true;
    terminal.enterAltScreen();
    inAltScreen = true;
    terminal.hideCursor();
    cursorHidden = true;
    terminal.setScrollOptim(false);
    terminal.setSynchronizedOutput(true);

    var mode = 0;
    var paused = false;
    var showHelp = true;
    var colorCycle = true;
    var hardClear = true;
    var timeScale = 1.0;
    var smoothedFps = 0.0;
    var frame = 0;

    final clock = Stopwatch()..start();
    var lastElapsed = clock.elapsed;
    var visualTime = 0.0;

    void renderFrame() {
      final bounds = terminal.bounds();
      final width = bounds.width;
      final height = bounds.height;

      if (hardClear) {
        terminal.clear();
        terminal.clearScreen();
        hardClear = false;
      } else {
        terminal.clear();
      }

      if (width <= 0 || height <= 0) {
        terminal.draw();
        return;
      }

      final fieldHeight = math.max(1, height - 2);
      final aspect = width / math.max(1, fieldHeight);
      final baseHue = _modeHue(mode);
      final paletteShift = colorCycle ? visualTime * 0.06 : 0.0;

      for (var y = 0; y < fieldHeight; y++) {
        final ny = ((y / math.max(1, fieldHeight - 1)) * 2.0 - 1.0);
        for (var x = 0; x < width; x++) {
          final nx = (((x / math.max(1, width - 1)) * 2.0 - 1.0) * aspect);
          final value = _fieldValue(mode, nx, ny, visualTime);
          final brightness = ((value + 1.0) * 0.5).clamp(0.0, 1.0);
          final rampIndex = (brightness * (_glyphRamp.length - 1))
              .round()
              .clamp(0, _glyphRamp.length - 1);
          final glyph = _glyphRamp[rampIndex];
          final fg = _hsvToRgb(
            baseHue + paletteShift + brightness * 0.18,
            0.76,
            0.24 + brightness * 0.76,
          );
          final bg = _hsvToRgb(baseHue + 0.52, 0.34, 0.05 + brightness * 0.12);

          terminal.setCell(
            x,
            y,
            Cell(
              content: glyph,
              style: UvStyle(fg: fg, bg: bg),
            ),
          );
        }
      }

      final modeName = switch (mode) {
        0 => 'plasma',
        1 => 'tunnel',
        2 => 'warp',
        _ => 'interference',
      };
      final hud =
          'shader-toy  mode:${mode + 1}($modeName)  scale:${timeScale.toStringAsFixed(2)}x  fps:${smoothedFps.toStringAsFixed(1)}';
      final help = showHelp
          ? '1-4 mode  j/k speed  p pause  c color-cycle  h help  q esc ctrl+c quit'
          : 'h help';

      if (height >= 2) {
        terminal.fillArea(
          Cell(content: ' ', style: _hudStyle),
          rect(0, height - 2, width, 1),
        );
        _writeLine(
          terminal,
          0,
          height - 2,
          hud,
          maxWidth: width,
          style: _hudStyle,
        );
      }
      if (height >= 1) {
        terminal.fillArea(
          Cell(content: ' ', style: _helpStyle),
          rect(0, height - 1, width, 1),
        );
        _writeLine(
          terminal,
          0,
          height - 1,
          help,
          maxWidth: width,
          style: _helpStyle,
        );
      }

      terminal.draw();
    }

    ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final now = clock.elapsed;
      final dt = (now - lastElapsed).inMicroseconds / 1000000.0;
      lastElapsed = now;

      if (dt > 0) {
        final fps = 1.0 / dt;
        smoothedFps = smoothedFps == 0 ? fps : smoothedFps * 0.88 + fps * 0.12;
      }
      if (!paused) {
        visualTime += dt * timeScale;
      }
      frame++;
      if (!paused && frame % 180 == 0) {
        visualTime += 0.001;
      }
      renderFrame();
    });

    renderFrame();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        hardClear = true;
        renderFrame();
        continue;
      }
      if (event is! KeyEvent) continue;

      if (event.matchString('q', 'esc', 'ctrl+c')) {
        break;
      } else if (event.matchString('1')) {
        mode = 0;
      } else if (event.matchString('2')) {
        mode = 1;
      } else if (event.matchString('3')) {
        mode = 2;
      } else if (event.matchString('4')) {
        mode = 3;
      } else if (event.matchString('j')) {
        timeScale = (timeScale * 0.85).clamp(0.08, 6.0);
      } else if (event.matchString('k')) {
        timeScale = (timeScale * 1.2).clamp(0.08, 6.0);
      } else if (event.matchString('p', ' ')) {
        paused = !paused;
      } else if (event.matchString('c')) {
        colorCycle = !colorCycle;
      } else if (event.matchString('h')) {
        showHelp = !showHelp;
      } else if (event.matchString('r')) {
        visualTime = 0.0;
        hardClear = true;
      }
      renderFrame();
    }
  } finally {
    ticker?.cancel();
    if (cursorHidden) {
      terminal.showCursor();
    }
    if (inAltScreen) {
      terminal.exitAltScreen();
    }
    if (started) {
      await terminal.stop();
    }
  }
}
