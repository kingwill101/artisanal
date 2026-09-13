import 'dart:ui';

import 'package:artisanal/uv.dart';
import 'package:flutter_artisanal/src/terminal_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves byte channels and alpha when converting both directions', () {
    const source = Color(0x80123456);
    final converted = uvFlutterToColor(source);
    expect(converted, const UvRgb(0x12, 0x34, 0x56, a: 0x80));
    expect(uvColorToFlutter(converted, const Color(0xff000000)), source);
  });

  test('rounds normalized Flutter color channels to terminal bytes', () {
    const source = Color.from(alpha: 0.5, red: 0.1, green: 0.2, blue: 0.3);
    expect(uvFlutterToColor(source), const UvRgb(26, 51, 77, a: 128));
  });
}
