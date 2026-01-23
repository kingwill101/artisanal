library;

import 'profile.dart';

class Rgb {
  const Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}

const _cubeLevels = <int>[0, 95, 135, 175, 215, 255];

// XTerm 16-color palette (approximate).
const _ansi16Palette = <Rgb>[
  Rgb(0, 0, 0), // 0 black
  Rgb(205, 0, 0), // 1 red
  Rgb(0, 205, 0), // 2 green
  Rgb(205, 205, 0), // 3 yellow
  Rgb(0, 0, 238), // 4 blue
  Rgb(205, 0, 205), // 5 magenta
  Rgb(0, 205, 205), // 6 cyan
  Rgb(229, 229, 229), // 7 white
  Rgb(127, 127, 127), // 8 bright black (gray)
  Rgb(255, 0, 0), // 9 bright red
  Rgb(0, 255, 0), // 10 bright green
  Rgb(255, 255, 0), // 11 bright yellow
  Rgb(92, 92, 255), // 12 bright blue
  Rgb(255, 0, 255), // 13 bright magenta
  Rgb(0, 255, 255), // 14 bright cyan
  Rgb(255, 255, 255), // 15 bright white
];

final _rgbToAnsi256Cache = <int, int>{};
final _rgbToAnsi16Cache = <int, int>{};
final _ansi256ToAnsi16Cache = List<int?>.filled(256, null);

int rgbToAnsi256(int r, int g, int b) {
  r = r.clamp(0, 255);
  g = g.clamp(0, 255);
  b = b.clamp(0, 255);

  final key = (r << 16) | (g << 8) | b;
  final cached = _rgbToAnsi256Cache[key];
  if (cached != null) return cached;

  final cube = _rgbToCubeIndex(r, g, b);
  final cubeRgb = ansi256ToRgb(cube);
  final cubeDist = _dist2(r, g, b, cubeRgb.r, cubeRgb.g, cubeRgb.b);

  final gray = _rgbToGrayIndex(r, g, b);
  final grayRgb = ansi256ToRgb(gray);
  final grayDist = _dist2(r, g, b, grayRgb.r, grayRgb.g, grayRgb.b);

  final result = grayDist < cubeDist ? gray : cube;
  _rgbToAnsi256Cache[key] = result;
  return result;
}

int rgbToAnsi16(int r, int g, int b) {
  r = r.clamp(0, 255);
  g = g.clamp(0, 255);
  b = b.clamp(0, 255);

  final key = (r << 16) | (g << 8) | b;
  final cached = _rgbToAnsi16Cache[key];
  if (cached != null) return cached;

  final idx = rgbToAnsi256(r, g, b);
  final result = ansi256ToAnsi16(idx);
  _rgbToAnsi16Cache[key] = result;
  return result;
}

Rgb ansi256ToRgb(int index) {
  if (index < 0) index = 0;
  if (index > 255) index = 255;

  if (index < 16) {
    return _ansi16Palette[index];
  }

  if (index >= 232) {
    final level = 8 + (index - 232) * 10;
    return Rgb(level, level, level);
  }

  final idx = index - 16;
  final r = idx ~/ 36;
  final g = (idx % 36) ~/ 6;
  final b = idx % 6;
  return Rgb(_cubeLevels[r], _cubeLevels[g], _cubeLevels[b]);
}

int ansi256ToAnsi16(int index) {
  if (index < 0) index = 0;
  if (index > 255) index = 255;

  if (index < 16) return index;
  final cached = _ansi256ToAnsi16Cache[index];
  if (cached != null) return cached;

  int result;
  if (index >= 232) {
    final level = 8 + (index - 232) * 10;
    if (level < 64) {
      result = 0; // black
    } else if (level < 128) {
      result = 8; // bright black
    } else if (level < 192) {
      result = 7; // white
    } else {
      result = 15; // bright white
    }
  } else {
    final idx = index - 16;
    final r = idx ~/ 36;
    final g = (idx % 36) ~/ 6;
    final b = idx % 6;

    var basic = 0;
    if (r >= 3) basic |= 1;
    if (g >= 3) basic |= 2;
    if (b >= 3) basic |= 4;

    final bright = r >= 4 || g >= 4 || b >= 4;
    result = basic + (bright ? 8 : 0);
  }

  _ansi256ToAnsi16Cache[index] = result;
  return result;
}

String sgrColor({
  required Profile profile,
  bool background = false,
  bool underline = false,
  int? ansi16,
  int? ansi256,
  Rgb? rgb,
}) {
  if (profile <= Profile.noTty) return '';

  if (profile == Profile.ascii) {
    return '';
  }

  if (profile == Profile.trueColor) {
    if (rgb == null) {
      if (ansi256 != null) rgb = ansi256ToRgb(ansi256);
      if (ansi16 != null) rgb = _ansi16Palette[ansi16.clamp(0, 15)];
    }
    if (rgb == null) return '';
    if (underline) {
      // SGR 58 uses xterm-style colon parameters for underline color.
      // Example: ESC[58:2::R:G:Bm
      return '\x1B[58:2::${rgb.r}:${rgb.g}:${rgb.b}m';
    }
    final p = background ? 48 : 38;
    return '\x1B[$p;2;${rgb.r};${rgb.g};${rgb.b}m';
  }

  if (profile == Profile.ansi256) {
    final idx =
        ansi256 ??
        (rgb != null
            ? rgbToAnsi256(rgb.r, rgb.g, rgb.b)
            : (ansi16 != null ? _ansi16ToAnsi256(ansi16) : 0));
    if (underline) {
      // SGR 58 uses colon parameters for underline color.
      return '\x1B[58:5:${idx}m';
    }
    final p = background ? 48 : 38;
    return '\x1B[$p;5;${idx}m';
  }

  // Profile.ansi
  if (underline) {
    // Underline color doesn't have 16-color SGR codes, use 256-color fallback
    final idx =
        ansi256 ??
        (rgb != null
            ? rgbToAnsi256(rgb.r, rgb.g, rgb.b)
            : (ansi16 != null ? _ansi16ToAnsi256(ansi16) : 0));
    // SGR 58 uses colon parameters for underline color.
    return '\x1B[58:5:${idx}m';
  }

  final idx16 =
      ansi16 ??
      (ansi256 != null
          ? ansi256ToAnsi16(ansi256)
          : (rgb != null ? rgbToAnsi16(rgb.r, rgb.g, rgb.b) : 0));
  return _sgrAnsi16(idx16, background: background);
}

String _sgrAnsi16(int idx16, {required bool background}) {
  final i = idx16.clamp(0, 15);
  if (i < 8) {
    return '\x1B[${(background ? 40 : 30) + i}m';
  }
  return '\x1B[${(background ? 100 : 90) + (i - 8)}m';
}

int _ansi16ToAnsi256(int idx16) {
  final rgb = _ansi16Palette[idx16.clamp(0, 15)];
  return rgbToAnsi256(rgb.r, rgb.g, rgb.b);
}

int _rgbToCubeIndex(int r, int g, int b) {
  final ri = _nearestCubeLevelIndex(r);
  final gi = _nearestCubeLevelIndex(g);
  final bi = _nearestCubeLevelIndex(b);
  return 16 + 36 * ri + 6 * gi + bi;
}

int _rgbToGrayIndex(int r, int g, int b) {
  final avg = ((r + g + b) / 3).round();
  final gray = ((avg - 8) / 10).round().clamp(0, 23);
  return 232 + gray;
}

int _nearestCubeLevelIndex(int c) {
  var bestIdx = 0;
  var bestDist = 1 << 62;
  for (var i = 0; i < _cubeLevels.length; i++) {
    final d = (c - _cubeLevels[i]).abs();
    if (d < bestDist) {
      bestDist = d;
      bestIdx = i;
    }
  }
  return bestIdx;
}

int _dist2(int r1, int g1, int b1, int r2, int g2, int b2) {
  final dr = r1 - r2;
  final dg = g1 - g2;
  final db = b1 - b2;
  return dr * dr + dg * dg + db * db;
}
