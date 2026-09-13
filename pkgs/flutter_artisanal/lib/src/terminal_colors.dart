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
UvRgb uvFlutterToColor(Color color) => UvRgb(
  _channelByte(color.r),
  _channelByte(color.g),
  _channelByte(color.b),
  a: _channelByte(color.a),
);

int _channelByte(double channel) => (channel * 255).round().clamp(0, 255);
