import 'package:web/web.dart' as web;
import 'package:ultraviolet/src/web/canvas_renderer.dart';
import 'package:ultraviolet/src/uv/cell.dart';
import 'package:ultraviolet/src/uv/buffer.dart';

void main() {
  final doc = web.document;
  var canvas = doc.querySelector('canvas') as web.HTMLCanvasElement?;
  if (canvas == null) {
    final c = doc.createElement('canvas') as web.HTMLCanvasElement;
    c.id = 'screen';
    doc.body!.appendChild(c);
    canvas = c;
  }

  final ctx = canvas.getContext('2d');
  if (ctx == null) return;

  const cols = 80;
  const rows = 24;
  final renderer = CanvasTerminalRenderer(ctx as web.CanvasRenderingContext2D,
      fontSize: 16);
  renderer.resize(cols, rows);
  renderer.measureFont();

  canvas.width = (cols * renderer.cellWidth).ceil();
  canvas.height = (rows * renderer.cellHeight).ceil();

  final buf = Buffer.create(cols, rows);

  void write(int x, int y, String text, {UvStyle? style}) {
    for (var i = 0; i < text.length; i++) {
      buf.setCell(x + i, y, Cell(content: text[i], style: style ?? const UvStyle()));
    }
  }

  write(0, 0, '┌────────────────────────────────────────────────────────────────┐',
      style: const UvStyle(fg: UvColor.indexed256(8)));
  write(0, 1, '│                    UV Canvas Renderer Demo                     │',
      style: const UvStyle(fg: UvColor.indexed256(8)));
  write(0, 2, '├────────────────────────────────────────────────────────────────┤',
      style: const UvStyle(fg: UvColor.indexed256(8)));

  write(2, 4, '16-Color Palette:',
      style: const UvStyle(fg: UvColor.basic16(6), attrs: Attr.bold));
  for (var i = 0; i < 8; i++) {
    write(2 + i * 4, 5, '███ ',
        style: UvStyle(bg: UvColor.basic16(i)));
    write(2 + i * 4, 6, '███ ',
        style: UvStyle(bg: UvColor.basic16(i, bright: true)));
  }

  write(2, 8, 'True Color:',
      style: const UvStyle(fg: UvColor.indexed256(6), attrs: Attr.bold));
  for (var i = 0; i < 8; i++) {
    final r = (i * 36) % 256;
    final g = (128 + i * 16) % 256;
    final b = (255 - i * 32) % 256;
    write(2 + i * 5, 9, '  RGB  ',
        style: UvStyle(
          fg: UvColor.rgb(r, g, b),
          bg: UvColor.rgb(255 - r, 255 - g, 255 - b),
        ));
  }

  write(2, 11, 'Text Styles:',
      style: const UvStyle(fg: UvColor.indexed256(6), attrs: Attr.bold));
  write(2, 12, '  Normal text',
      style: const UvStyle(fg: UvColor.rgb(200, 200, 200)));
  write(2, 13, '  Bold text',
      style: const UvStyle(fg: UvColor.rgb(220, 220, 220), attrs: Attr.bold));
  write(2, 14, '  Italic text',
      style: const UvStyle(fg: UvColor.rgb(200, 200, 200), attrs: Attr.italic));
  write(2, 15, '  Underlined text',
      style: const UvStyle(fg: UvColor.rgb(200, 200, 200), underline: UnderlineStyle.single));
  write(2, 16, '  Strikethrough text',
      style: const UvStyle(fg: UvColor.rgb(200, 200, 200), attrs: Attr.strikethrough));

  write(0, 22, '└────────────────────────────────────────────────────────────────┘',
      style: const UvStyle(fg: UvColor.indexed256(8)));
  write(6, 23, 'Canvas renderer · ultraviolet · dart compile wasm',
      style: const UvStyle(fg: UvColor.indexed256(8)));

  renderer.render(buf);
}
