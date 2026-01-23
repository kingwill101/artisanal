import 'dart:io';
import 'package:artisanal/src/io/console.dart';
import 'package:artisanal/src/uv/canvas.dart';
import 'package:artisanal/src/uv/kitty_drawable.dart';
import 'package:artisanal/src/uv/layer.dart';
import 'package:artisanal/src/uv/styled_string.dart';
import 'package:image/image.dart' as img;

// #region compositor_usage
void main() {
  final io = Console(out: (s) => stdout.write(s), err: (s) => stderr.write(s));

  // Create a simple gradient image
  final image = img.Image(width: 100, height: 100);
  for (var y = 0; y < 100; y++) {
    for (var x = 0; x < 100; x++) {
      image.setPixelRgba(x, y, x * 2, y * 2, 150, 255);
    }
  }

  // Create layers
  final imageLayer = newLayer(KittyImageDrawable(image, columns: 20, rows: 10))
    ..setId('image')
    ..setX(5)
    ..setY(2);

  final textLayer =
      newLayer(StyledString('\x1b[1;33mHello from Compositor!\x1b[0m'))
        ..setId('text')
        ..setX(2)
        ..setY(1);

  final compositor = Compositor([imageLayer, textLayer]);

  // Render to a canvas
  final canvas = Canvas(40, 15);
  canvas.compose(compositor);

  io.write(canvas.render());
  io.write('\nDone.\n');
}

// #endregion
