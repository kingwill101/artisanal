// Test: Use WidgetApp as model but bypass its element tree by overriding view
import 'package:artisanal/tui.dart' show Model, Cmd, View, runProgram, Msg;
import 'package:artisanal/web.dart'
    show WebTerminalBackend, WebUltravioletRenderer;
import 'package:artisanal/terminal.dart' show BackendTerminal;
import 'package:ultraviolet/web.dart' show CanvasTerminalRenderer;
import 'package:web/web.dart' as web;

class SimpleModel implements Model {
  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  Object view() => View(content: 'Hello!');
}

void main() async {
  final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
  web.document.body!.appendChild(canvas);
  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

  final cr = CanvasTerminalRenderer(ctx, fontSize: 14);
  cr.measureFont();
  cr.resize(80, 24);
  canvas.width = (80 * cr.cellWidth).ceil();
  canvas.height = (24 * cr.cellHeight).ceil();

  final backend = WebTerminalBackend(initialSize: (width: 80, height: 24));
  final terminal = BackendTerminal(backend);
  final renderer = WebUltravioletRenderer(
    terminal: terminal,
    canvasRenderer: cr,
  );

  await runProgram(SimpleModel(), terminal: terminal, renderer: renderer);
}
