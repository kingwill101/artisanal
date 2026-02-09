import 'dart:io';

import 'package:artisanal/uv.dart';

Future<void> main() async {
  const width = 40;
  const height = 10;
  final sink = BufferRenderSink(width: width, height: height);
  final filter = LiquifyFilter(strength: 2.5);

  for (var frame = 0; frame < 40; frame++) {
    final buffer = Buffer.create(width, height);
    _drawBox(buffer, 0, 0, width, height);
    _drawText(buffer, 2, 2, 'LIQUIFY FILTER');
    _drawText(buffer, 2, 4, 'frame ${frame.toString().padLeft(2)}');
    _drawText(buffer, 2, 6, 'observe the warp');

    final filtered = sink.render(buffer, [filter], dt: 1 / 30);

    stdout.write('\x1B[2J\x1B[H');
    stdout.write(filtered.render());
    stdout.write('\n');
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }
}

void _drawText(Buffer buffer, int x, int y, String text) {
  for (var i = 0; i < text.length; i++) {
    _setCell(buffer, x + i, y, text[i]);
  }
}

void _drawBox(Buffer buffer, int x, int y, int width, int height) {
  if (width < 2 || height < 2) return;
  _setCell(buffer, x, y, '+');
  _setCell(buffer, x + width - 1, y, '+');
  _setCell(buffer, x, y + height - 1, '+');
  _setCell(buffer, x + width - 1, y + height - 1, '+');

  for (var i = 1; i < width - 1; i++) {
    _setCell(buffer, x + i, y, '-');
    _setCell(buffer, x + i, y + height - 1, '-');
  }

  for (var j = 1; j < height - 1; j++) {
    _setCell(buffer, x, y + j, '|');
    _setCell(buffer, x + width - 1, y + j, '|');
  }
}

void _setCell(Buffer buffer, int x, int y, String ch) {
  final line = buffer.line(y);
  if (line == null) return;
  line.set(x, Cell(content: ch));
}
