import 'package:ultraviolet/ultraviolet.dart';
import 'package:ultraviolet/web.dart' show CanvasTerminalRenderer;
import 'package:web/web.dart' as web;

const _bg = UvRgb(96, 96, 96);
const _fg = UvRgb(238, 238, 238);

void main() {
  final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
  canvas.id = 'gap-probe-canvas';
  web.document.body!.appendChild(canvas);

  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
  final renderer = CanvasTerminalRenderer(ctx, fontSize: 14);
  renderer.measureFont();

  const cols = 20;
  const rows = 8;
  renderer.resize(cols, rows);

  final width = (cols * renderer.cellWidth).ceil();
  final height = (rows * renderer.cellHeight).ceil();
  canvas.width = width;
  canvas.height = height;
  canvas.style.width = '${width}px';
  canvas.style.height = '${height}px';
  renderer.configureViewport(width: width.toDouble(), height: height.toDouble());

  final buffer = Buffer.create(cols, rows, tracksDirty: false);

  _writeLabel(buffer, 0, 'A full styled row');
  _fillStyledText(buffer, 1, '3 PRs 20', styleSpaces: true);

  _writeLabel(buffer, 3, 'B null-bg spaces');
  _fillStyledText(buffer, 4, '3 PRs 20', styleSpaces: false);

  _writeLabel(buffer, 6, 'C manual gap run');
  _fillManualGapRun(buffer, 7);

  renderer.render(buffer);
}

void _writeLabel(Buffer buffer, int y, String text) {
  for (var x = 0; x < text.length && x < buffer.width(); x++) {
    buffer.setCell(x, y, Cell.asciiStyled(text.codeUnitAt(x), style: const UvStyle(fg: _fg)));
  }
}

void _fillStyledText(Buffer buffer, int y, String text, {required bool styleSpaces}) {
  for (var x = 0; x < text.length && x < buffer.width(); x++) {
    final ch = text.codeUnitAt(x);
    final isSpace = ch == 0x20;
    final style = (!isSpace || styleSpaces)
        ? const UvStyle(fg: _fg, bg: _bg)
        : const UvStyle(fg: _fg);
    buffer.setCell(x, y, Cell.asciiStyled(ch, style: style));
  }
}

void _fillManualGapRun(Buffer buffer, int y) {
  const style = UvStyle(fg: _fg, bg: _bg);
  const left = '3';
  const right = '20';
  buffer.setCell(0, y, Cell.asciiStyled(left.codeUnitAt(0), style: style));
  buffer.setCell(1, y, Cell.asciiStyled(0x20, style: const UvStyle()));
  buffer.setCell(2, y, Cell.asciiStyled('P'.codeUnitAt(0), style: style));
  buffer.setCell(3, y, Cell.asciiStyled('R'.codeUnitAt(0), style: style));
  buffer.setCell(4, y, Cell.asciiStyled('s'.codeUnitAt(0), style: style));
  buffer.setCell(5, y, Cell.asciiStyled(0x20, style: const UvStyle()));
  buffer.setCell(6, y, Cell.asciiStyled(0x20, style: const UvStyle()));
  buffer.setCell(7, y, Cell.asciiStyled(right.codeUnitAt(0), style: style));
  buffer.setCell(8, y, Cell.asciiStyled(right.codeUnitAt(1), style: style));
}
