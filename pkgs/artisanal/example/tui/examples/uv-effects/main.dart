/// UV effects with Artisanal's low-level terminal API.
///
/// Run from `pkgs/artisanal`:
///   dart run example/tui/examples/uv-effects/main.dart
library;

import 'dart:math' as math;

import 'package:artisanal/uv.dart';

final _effects = <_EffectPreset>[
  _EffectPreset('Grayscale', ColorMatrixFilter.grayscale()),
  _EffectPreset('Invert', ColorMatrixFilter.invert()),
  _EffectPreset(
    'Cyan tint',
    ColorMatrixFilter.tint(const UvRgb(72, 205, 255), amount: 0.45),
  ),
  _EffectPreset('Vignette', VignetteFilter(strength: 0.55)),
  _EffectPreset(
    'Scanlines',
    ScanlineFilter(lineStrength: 0.2, barStrength: 0.12),
  ),
  _EffectPreset('CRT', CrtFilter()),
  _EffectPreset('Amber', AmberTerminalFilter()),
  _EffectPreset('Phosphor', PhosphorFilter()),
];

const _background = UvRgb(7, 10, 17);
const _surface = UvRgb(17, 24, 38);
const _border = UvRgb(72, 98, 132);
const _text = UvRgb(219, 229, 245);
const _muted = UvRgb(128, 149, 180);
const _cyan = UvRgb(62, 207, 255);
const _amber = UvRgb(255, 190, 82);
const _pink = UvRgb(255, 101, 167);

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    print('UV effects example');
    print('left/right or 1-8: select effect; q: quit');
    return;
  }

  final terminal = Terminal();
  final sink = BufferRenderSink();
  var selected = 0;

  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  void render() {
    final bounds = terminal.bounds();
    terminal.buffer.fill(
      Cell(
        content: ' ',
        style: const UvStyle(bg: _background),
      ),
    );

    if (bounds.width < 32 || bounds.height < 12) {
      _writeText(
        terminal,
        1,
        1,
        'Resize to at least 32x12',
        const UvStyle(fg: _text),
      );
      terminal.draw();
      return;
    }

    final wide = bounds.width >= 76;
    final gap = wide ? 3 : 0;
    final sceneWidth = wide
        ? (bounds.width - gap - 4) ~/ 2
        : math.min(54, bounds.width - 4);
    final sceneHeight = math.min(14, bounds.height - 7);
    final source = Canvas(sceneWidth, sceneHeight);
    _drawSourceScene(source);

    // This is the complete low-level effects pipeline: render through one or
    // more BufferFilters, then draw the returned buffer like any other UV
    // buffer. BufferRenderSink owns and reuses the intermediate buffers.
    final filtered = sink.render(source.buffer, [
      _effects[selected].filter,
    ], dt: 1 / 30);

    final startX = wide ? 2 : (bounds.width - sceneWidth) ~/ 2;
    const startY = 3;
    _writeText(
      terminal,
      2,
      0,
      'Artisanal UV Effects',
      const UvStyle(fg: _text, attrs: Attr.bold),
    );
    _writeText(
      terminal,
      2,
      1,
      'left/right or 1-8 select · q quits',
      const UvStyle(fg: _muted),
    );

    if (wide) {
      _writeText(
        terminal,
        startX,
        startY - 1,
        'Original',
        const UvStyle(fg: _muted),
      );
      source.buffer.draw(
        terminal,
        rect(startX, startY, sceneWidth, sceneHeight),
      );
    }

    final filteredX = wide ? startX + sceneWidth + gap : startX;
    _writeText(
      terminal,
      filteredX,
      startY - 1,
      'Filtered · ${_effects[selected].label}',
      const UvStyle(fg: _amber, attrs: Attr.bold),
    );
    filtered.draw(terminal, rect(filteredX, startY, sceneWidth, sceneHeight));

    final footerY = startY + sceneHeight + 1;
    _writeText(
      terminal,
      2,
      footerY,
      _effectLegend(0, 4),
      const UvStyle(fg: _muted),
    );
    _writeText(
      terminal,
      2,
      footerY + 1,
      _effectLegend(4, _effects.length),
      const UvStyle(fg: _muted),
    );
    terminal.draw();
  }

  try {
    render();
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        terminal.clearScreen();
      } else if (event is KeyEvent) {
        if (event.matchString('q', 'esc', 'ctrl+c')) break;
        if (event.matchString('left', 'up')) {
          selected = (selected - 1 + _effects.length) % _effects.length;
        } else if (event.matchString('right', 'down', 'tab', ' ')) {
          selected = (selected + 1) % _effects.length;
        } else {
          for (var i = 0; i < _effects.length; i++) {
            if (event.matchString('${i + 1}')) selected = i;
          }
        }
      }
      render();
    }
  } finally {
    await terminal.stop();
  }
}

void _drawSourceScene(Canvas canvas) {
  canvas.fill(
    Cell(
      content: ' ',
      style: const UvStyle(bg: _surface),
    ),
  );
  final width = canvas.width();
  final height = canvas.height();

  for (var x = 0; x < width; x++) {
    canvas.setCell(
      x,
      0,
      Cell(
        content: '─',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    );
    canvas.setCell(
      x,
      height - 1,
      Cell(
        content: '─',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    );
  }
  for (var y = 0; y < height; y++) {
    canvas.setCell(
      0,
      y,
      Cell(
        content: '│',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    );
    canvas.setCell(
      width - 1,
      y,
      Cell(
        content: '│',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    );
  }
  canvas
    ..setCell(
      0,
      0,
      Cell(
        content: '╭',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    )
    ..setCell(
      width - 1,
      0,
      Cell(
        content: '╮',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    )
    ..setCell(
      0,
      height - 1,
      Cell(
        content: '╰',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    )
    ..setCell(
      width - 1,
      height - 1,
      Cell(
        content: '╯',
        style: const UvStyle(fg: _border, bg: _surface),
      ),
    );

  _writeText(
    canvas,
    3,
    2,
    'BUILD PIPELINE',
    const UvStyle(fg: _cyan, bg: _surface, attrs: Attr.bold),
  );
  _writeText(
    canvas,
    3,
    4,
    'compile   ████████████  100%',
    const UvStyle(fg: _text, bg: _surface),
  );
  _writeText(
    canvas,
    3,
    6,
    'tests     █████████░░░   76%',
    const UvStyle(fg: _amber, bg: _surface),
  );
  _writeText(
    canvas,
    3,
    8,
    'deploy    █████░░░░░░░   42%',
    const UvStyle(fg: _pink, bg: _surface),
  );
  if (height > 11) {
    _writeText(
      canvas,
      3,
      10,
      'Glyphs and styles stay intact.',
      const UvStyle(fg: _muted, bg: _surface),
    );
  }
}

void _writeText(Screen screen, int x, int y, String value, UvStyle style) {
  final bounds = screen.bounds();
  for (final rune in value.runes) {
    if (x >= bounds.maxX || y >= bounds.maxY) return;
    if (x >= 0 && y >= 0) {
      screen.setCell(
        x,
        y,
        Cell(content: String.fromCharCode(rune), style: style),
      );
    }
    x++;
  }
}

String _effectLegend(int start, int end) => _effects.indexed
    .skip(start)
    .take(end - start)
    .map((entry) => '${entry.$1 + 1}:${entry.$2.label}')
    .join('  ');

final class _EffectPreset {
  const _EffectPreset(this.label, this.filter);

  final String label;
  final BufferFilter filter;
}
