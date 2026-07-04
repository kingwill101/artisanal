library;

import 'dart:ui' show Color;

import 'package:artisanal/uv.dart';

const List<Color> _basic16Palette = [
  Color(0xFF000000),
  Color(0xFFCD0000),
  Color(0xFF00CD00),
  Color(0xFFCDCD00),
  Color(0xFF0000EE),
  Color(0xFFCD00CD),
  Color(0xFF00CDCD),
  Color(0xFFE5E5E5),
  Color(0xFF7F7F7F),
  Color(0xFFFF0000),
  Color(0xFF00FF00),
  Color(0xFFFFFF00),
  Color(0xFF5C5CFF),
  Color(0xFFFF00FF),
  Color(0xFF00FFFF),
  Color(0xFFFFFFFF),
];

const List<int> _cubeSteps = [0, 95, 135, 175, 215, 255];

Color _indexed256ToColor(int index) {
  if (index < 16) return _basic16Palette[index];
  if (index < 232) {
    final i = index - 16;
    final r = _cubeSteps[i ~/ 36];
    final g = _cubeSteps[(i % 36) ~/ 6];
    final b = _cubeSteps[i % 6];
    return Color.fromARGB(255, r, g, b);
  }
  final v = 8 + (index - 232) * 10;
  return Color.fromARGB(255, v, v, v);
}

Color uvColorToFlutter(UvColor? color, Color defaultColor) {
  if (color == null) return defaultColor;
  return switch (color) {
    UvRgb c => Color.fromARGB(c.a, c.r, c.g, c.b),
    UvBasic16 c => _basic16Palette[c.index + (c.bright ? 8 : 0)],
    UvIndexed256 c => _indexed256ToColor(c.index),
  };
}
