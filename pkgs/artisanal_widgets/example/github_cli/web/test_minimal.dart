import 'package:web/web.dart' as web;

void main() {
  final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
  canvas.width = 800;
  canvas.height = 600;
  canvas.id = 'test-canvas';
  web.document.body!.appendChild(canvas);
}
