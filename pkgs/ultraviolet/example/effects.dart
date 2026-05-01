import 'dart:io';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

final _effects = <_EffectOption>[
  _EffectOption(
    key: '1',
    label: 'Identity',
    description: 'No transform',
    filter: ColorMatrixFilter.identity(),
  ),
  _EffectOption(
    key: '2',
    label: 'Grayscale',
    description: 'Luminance mix',
    filter: ColorMatrixFilter.grayscale(),
  ),
  _EffectOption(
    key: '3',
    label: 'Invert',
    description: 'Invert RGB',
    filter: ColorMatrixFilter.invert(),
  ),
  _EffectOption(
    key: '4',
    label: 'Tint',
    description: 'Blend toward cyan',
    filter: ColorMatrixFilter.tint(const UvRgb(92, 207, 255), amount: 0.42),
  ),
  _EffectOption(
    key: '5',
    label: 'Multiply',
    description: 'Multiply by amber',
    filter: ColorMatrixFilter.multiply(const UvRgb(255, 196, 96)),
  ),
  _EffectOption(
    key: '6',
    label: 'Gain',
    description: 'Boost saturation',
    filter: ColorMatrixFilter.gain(1.22),
  ),
  _EffectOption(
    key: '7',
    label: 'Attenuate',
    description: 'Dim colors',
    filter: ColorMatrixFilter.attenuation(0.55),
  ),
  _EffectOption(
    key: '8',
    label: 'Vignette',
    description: 'Darken the frame edges',
    filter: VignetteFilter(strength: 0.42, roundness: 1.15),
  ),
  _EffectOption(
    key: '9',
    label: 'Scanline',
    description: 'CRT scanlines with a rolling brightness bar',
    filter: ScanlineFilter(
      lineStrength: 0.12,
      barStrength: 0.1,
      barSpeed: 0.55,
      barHeightFraction: 0.12,
    ),
  ),
  _EffectOption(
    key: '0',
    label: 'Wave Distort',
    description: 'Deterministic sine-wave displacement',
    filter: WaveDistortionFilter(
      xAmplitude: 0.35,
      yAmplitude: 0.08,
      xFrequency: 0.42,
      yFrequency: 0.28,
      speed: 0.35,
    ),
  ),
  _EffectOption(
    key: '-',
    label: 'CRT Preset',
    description: 'Preset stack: distortion, vignette, scanlines',
    filter: CrtFilter(),
  ),
  _EffectOption(
    key: '=',
    label: 'Atmosphere',
    description: 'Gentle shimmer and soft falloff',
    filter: AtmosphereFilter(),
  ),
  _EffectOption(
    key: '[',
    label: 'Amber',
    description: 'Warm monochrome terminal preset',
    filter: AmberTerminalFilter(),
  ),
  _EffectOption(
    key: ']',
    label: 'Phosphor',
    description: 'Green phosphor display preset',
    filter: PhosphorFilter(),
  ),
  _EffectOption(
    key: ';',
    label: 'Ghosting',
    description: 'Temporal glyph afterimage without smearing the background',
    filter: GhostingFilter(persistence: 0.48, currentBoost: 0.04),
  ),
  _EffectOption(
    key: '\'',
    label: 'Phosphor Trail',
    description: 'Green phosphor grading plus a short persistence trail',
    filter: PhosphorTrailFilter(persistence: 0.44),
  ),
  _EffectOption(
    key: '\\',
    label: 'Amber Trail',
    description: 'Warm monochrome grading plus a short persistence trail',
    filter: AmberTrailFilter(persistence: 0.4),
  ),
  _EffectOption(
    key: ',',
    label: 'CRT Trail',
    description: 'CRT structure plus a dimmed temporal persistence trail',
    filter: CrtTrailFilter(persistence: 0.34),
  ),
];

const _appBg = UvRgb(7, 10, 16);
const _panelBg = UvRgb(13, 18, 28);
const _panelBorder = UvRgb(56, 81, 112);
const _panelTitle = UvRgb(201, 219, 244);
const _bodyText = UvRgb(180, 197, 224);
const _mutedText = UvRgb(110, 132, 164);
const _accentText = UvRgb(255, 196, 96);

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('UV post-effects demo');
    stdout.writeln('');
    stdout.writeln('Run: dart run pkgs/ultraviolet/example/effects.dart');
    stdout.writeln('Keys:');
    stdout.writeln('  left/right, up/down, tab, shift+tab: cycle effects');
    stdout.writeln(r"  1-9,0,-,=,[,],;,',\,,: jump to an effect");
    stdout.writeln('  q, esc, ctrl+c: quit');
    return;
  }

  final terminal = Terminal();
  final sink = BufferRenderSink();
  var selected = 3;

  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  void render() {
    final bounds = terminal.bounds();
    terminal.buffer.fill(
      Cell(
        content: ' ',
        style: const UvStyle(bg: _appBg),
      ),
    );

    if (bounds.width < 92 || bounds.height < 28) {
      _drawSmallViewport(terminal, bounds);
      terminal.draw();
      return;
    }

    final effect = _effects[selected];
    final content = rect(2, 1, bounds.width - 4, bounds.height - 2);
    final panelTop = content.minY + 4;
    final panelHeight = math.max(12, content.height - 10);
    final panelGap = 3;
    final leftWidth = (content.width - panelGap) ~/ 2;
    final rightWidth = content.width - panelGap - leftWidth;
    final leftPanel = rect(content.minX, panelTop, leftWidth, panelHeight);
    final rightPanel = rect(
      leftPanel.maxX + panelGap,
      panelTop,
      rightWidth,
      panelHeight,
    );
    final sceneWidth = math.min(leftPanel.width, rightPanel.width) - 2;
    final sceneHeight = math.min(leftPanel.height, rightPanel.height) - 2;
    final source = ScreenBuffer(sceneWidth, sceneHeight);

    _drawSourceScene(source);

    roundedBorder()
        .style(const UvStyle(fg: _panelBorder))
        .draw(terminal, leftPanel);
    roundedBorder()
        .style(const UvStyle(fg: _panelBorder))
        .draw(terminal, rightPanel);

    _writeText(
      terminal,
      content.minX,
      content.minY,
      'UV Post Effects',
      const UvStyle(fg: _panelTitle, attrs: Attr.bold),
    );
    _writeText(
      terminal,
      content.minX,
      content.minY + 1,
      'Compare a live scene with a filtered copy.',
      const UvStyle(fg: _bodyText),
    );

    _drawEffectChips(
      terminal,
      content.minX,
      content.minY + 2,
      content.width,
      selected,
    );

    _writeText(
      terminal,
      leftPanel.minX + 2,
      leftPanel.minY,
      ' Original Scene ',
      const UvStyle(fg: _panelTitle, bg: _panelBg, attrs: Attr.bold),
    );
    _writeText(
      terminal,
      rightPanel.minX + 2,
      rightPanel.minY,
      ' Filtered Output · ${effect.label} ',
      const UvStyle(fg: _panelTitle, bg: _panelBg, attrs: Attr.bold),
    );

    source.buffer.draw(
      terminal,
      rect(leftPanel.minX + 1, leftPanel.minY + 1, sceneWidth, sceneHeight),
    );

    final filtered = sink.render(source.buffer, [effect.filter]);
    filtered.draw(
      terminal,
      rect(rightPanel.minX + 1, rightPanel.minY + 1, sceneWidth, sceneHeight),
    );

    final footerY = panelTop + panelHeight + 1;
    _writeText(
      terminal,
      content.minX,
      footerY,
      'Current effect: ${effect.label}',
      const UvStyle(fg: _accentText, attrs: Attr.bold),
    );
    _writeText(
      terminal,
      content.minX + 18,
      footerY,
      effect.description,
      const UvStyle(fg: _bodyText),
    );
    _writeText(
      terminal,
      content.minX,
      footerY + 2,
      'Keys: arrows/tab cycle · 1-9,0,-,=,[,] jump · q quit',
      const UvStyle(fg: _mutedText),
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
        if (event.matchString('q', 'esc', 'ctrl+c')) {
          break;
        } else if (event.matchString('left', 'up', 'shift+tab')) {
          selected = (selected - 1 + _effects.length) % _effects.length;
        } else if (event.matchString('right', 'down', 'tab', ' ')) {
          selected = (selected + 1) % _effects.length;
        } else {
          for (var i = 0; i < _effects.length; i++) {
            if (event.matchString(_effects[i].key)) {
              selected = i;
              break;
            }
          }
        }
      }

      render();
    }
  } finally {
    await terminal.stop();
  }
}

void _drawSmallViewport(Screen screen, Rectangle bounds) {
  roundedBorder()
      .style(const UvStyle(fg: _panelBorder))
      .draw(screen, rect(1, 1, bounds.width - 2, bounds.height - 2));
  _writeText(
    screen,
    4,
    3,
    'Resize to at least 92x28',
    const UvStyle(fg: _panelTitle, attrs: Attr.bold),
  );
  _writeText(
    screen,
    4,
    5,
    'This example shows original and filtered buffers side by side.',
    const UvStyle(fg: _bodyText),
  );
  _writeText(screen, 4, 7, 'Press q to exit.', const UvStyle(fg: _mutedText));
}

void _drawSourceScene(ScreenBuffer screen) {
  screen.fill(
    Cell(
      content: ' ',
      style: const UvStyle(bg: _panelBg),
    ),
  );

  roundedBorder()
      .style(const UvStyle(fg: _panelBorder))
      .draw(screen, screen.bounds());

  _writeText(
    screen,
    2,
    1,
    'Color playground',
    const UvStyle(fg: _panelTitle, attrs: Attr.bold),
  );
  _writeText(
    screen,
    2,
    3,
    'Foreground, background, and underlines all transform.',
    const UvStyle(fg: _bodyText),
  );

  final swatches = <({String label, UvRgb color})>[
    (label: 'sky', color: const UvRgb(92, 207, 255)),
    (label: 'mint', color: const UvRgb(105, 231, 173)),
    (label: 'amber', color: const UvRgb(255, 196, 96)),
    (label: 'rose', color: const UvRgb(255, 126, 148)),
    (label: 'violet', color: const UvRgb(174, 126, 255)),
    (label: 'slate', color: const UvRgb(110, 132, 164)),
  ];

  var swatchX = 2;
  for (final swatch in swatches) {
    _fillRect(
      screen,
      rect(swatchX, 5, 8, 2),
      Cell(
        content: ' ',
        style: UvStyle(bg: UvRgb(32, 40, 58)),
      ),
    );
    _fillRect(
      screen,
      rect(swatchX + 1, 6, 6, 1),
      Cell(
        content: ' ',
        style: UvStyle(bg: swatch.color),
      ),
    );
    _writeCenteredText(
      screen,
      rect(swatchX, 7, 8, 1),
      swatch.label,
      const UvStyle(fg: _mutedText),
    );
    swatchX += 9;
  }

  final badgeY = 10;
  _drawBadge(
    screen,
    2,
    badgeY,
    'PRIMARY',
    const UvRgb(21, 76, 167),
    const UvRgb(214, 232, 255),
  );
  _drawBadge(
    screen,
    15,
    badgeY,
    'SUCCESS',
    const UvRgb(25, 109, 74),
    const UvRgb(210, 255, 231),
  );
  _drawBadge(
    screen,
    28,
    badgeY,
    'ALERT',
    const UvRgb(155, 69, 18),
    const UvRgb(255, 234, 209),
  );

  _writeText(
    screen,
    2,
    13,
    'Underline color survives too',
    const UvStyle(
      fg: UvRgb(219, 227, 244),
      underline: UnderlineStyle.single,
      underlineColor: UvRgb(255, 126, 148),
    ),
  );

  final bounds = screen.bounds();
  _fillGradient(screen, rect(2, 15, bounds.width - 4, 2));

  _writeText(
    screen,
    2,
    bounds.height - 3,
    'Glyphs and layout stay fixed as colors change.',
    const UvStyle(fg: _mutedText),
  );
}

void _drawEffectChips(Screen screen, int x, int y, int width, int selected) {
  var cursor = x;
  for (var i = 0; i < _effects.length; i++) {
    final effect = _effects[i];
    final active = i == selected;
    final style = active
        ? const UvStyle(
            fg: UvRgb(8, 10, 16),
            bg: UvRgb(255, 196, 96),
            attrs: Attr.bold,
          )
        : const UvStyle(fg: _mutedText, bg: UvRgb(25, 31, 44));
    final label = ' ${effect.key} ${effect.label} ';
    if (cursor + label.length > x + width) break;
    _writeText(screen, cursor, y, label, style);
    cursor += label.length + 1;
  }
}

void _drawBadge(
  ScreenBuffer screen,
  int x,
  int y,
  String text,
  UvRgb bg,
  UvRgb fg,
) {
  final width = text.length + 4;
  _fillRect(
    screen,
    rect(x, y, width, 1),
    Cell(
      content: ' ',
      style: UvStyle(bg: bg),
    ),
  );
  _writeText(screen, x + 2, y, text, UvStyle(fg: fg, bg: bg, attrs: Attr.bold));
}

void _fillGradient(ScreenBuffer screen, Rectangle area) {
  final colors = <UvRgb>[
    const UvRgb(92, 207, 255),
    const UvRgb(105, 231, 173),
    const UvRgb(255, 196, 96),
    const UvRgb(255, 126, 148),
    const UvRgb(174, 126, 255),
  ];

  for (var y = area.minY; y < area.maxY; y++) {
    for (var x = area.minX; x < area.maxX; x++) {
      final t = (x - area.minX) / math.max(1, area.width - 1);
      final leftIndex = math.min(
        colors.length - 1,
        (t * (colors.length - 1)).floor(),
      );
      final rightIndex = math.min(colors.length - 1, leftIndex + 1);
      final localT = (t * (colors.length - 1)) - leftIndex;
      final left = colors[leftIndex];
      final right = colors[rightIndex];
      final color = UvRgb(
        _mix(left.r, right.r, localT),
        _mix(left.g, right.g, localT),
        _mix(left.b, right.b, localT),
      );
      screen.setCell(
        x,
        y,
        Cell(
          content: ' ',
          style: UvStyle(bg: color),
        ),
      );
    }
  }
}

int _mix(int a, int b, double t) => (a + ((b - a) * t)).round();

void _fillRect(ScreenBuffer screen, Rectangle area, Cell cell) {
  screen.fillArea(cell, area);
}

void _writeCenteredText(
  Screen screen,
  Rectangle area,
  String text,
  UvStyle style,
) {
  final x = area.minX + math.max(0, (area.width - text.length) ~/ 2).toInt();
  _writeText(screen, x, area.minY, text, style);
}

void _writeText(Screen screen, int x, int y, String text, UvStyle style) {
  final bounds = screen.bounds();
  if (y < bounds.minY || y >= bounds.maxY) return;
  for (var i = 0; i < text.length; i++) {
    final px = x + i;
    if (px < bounds.minX || px >= bounds.maxX) continue;
    screen.setCell(px, y, Cell(content: text[i], style: style));
  }
}

final class _EffectOption {
  const _EffectOption({
    required this.key,
    required this.label,
    required this.description,
    required this.filter,
  });

  final String key;
  final String label;
  final String description;
  final BufferFilter filter;
}
