library;

import 'dart:ui' show Color;

import 'package:artisanal/uv.dart';

Color uvColorToFlutter(UvColor? color, Color defaultColor) {
  final fallback = uvFlutterToColor(defaultColor);
  final resolved = UvPaintPolicy(
    foreground: fallback,
    background: fallback,
  ).resolveColor(color, fallback);
  return Color.fromARGB(resolved.a, resolved.r, resolved.g, resolved.b);
}

/// Converts a Flutter color to the UV color used by the shared paint policy.
UvRgb uvFlutterToColor(Color color) =>
    UvRgb(color.red, color.green, color.blue, a: color.alpha);
