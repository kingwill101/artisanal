import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_artisanal/src/terminal_painter.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

Future<ui.Color> _paintedPixel({
  required uv.Buffer screen,
  required uv.UvPaintPolicy policy,
  required int width,
  required int height,
  int x = 0,
  int y = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final painter = TerminalPainter(
    screen: screen,
    cellWidth: 10,
    cellHeight: 10,
    fontFamily: 'monospace',
    fontSize: 10,
    defaultFg: const ui.Color(0xff000000),
    defaultBg: const ui.Color(0xff000000),
    cursorColor: const ui.Color(0xff000000),
    paintPolicy: policy,
    customBlockGlyphs: false,
    customBrailleGlyphs: false,
  );
  painter.paint(canvas, ui.Size(width.toDouble(), height.toDouble()));
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = (y * width + x) * 4;
  return ui.Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
}

void main() {
  test('reverse paints the resolved foreground as the background', () async {
    const red = uv.UvRgb(255, 0, 0);
    const blue = uv.UvRgb(0, 0, 255);
    final pixel = await _paintedPixel(
      screen: uv.Buffer.fromCells([
        [
          uv.Cell(
            content: ' ',
            style: uv.UvStyle(fg: red, bg: blue, attrs: uv.Attr.reverse),
          ),
        ],
      ]),
      policy: uv.UvPaintPolicy(),
      width: 10,
      height: 10,
    );

    expect((pixel.r * 255).round(), 255);
    expect((pixel.g * 255).round(), 0);
    expect((pixel.b * 255).round(), 0);
  });

  test('blank cells and remainder use the policy background', () async {
    const background = uv.UvRgb(17, 34, 51);
    final pixel = await _paintedPixel(
      screen: uv.Buffer.fromCells([
        [uv.Cell(content: ' ')],
      ]),
      policy: uv.UvPaintPolicy(background: background),
      width: 20,
      height: 20,
      x: 15,
      y: 15,
    );

    expect((pixel.r * 255).round(), 17);
    expect((pixel.g * 255).round(), 34);
    expect((pixel.b * 255).round(), 51);
  });
}
