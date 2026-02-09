import 'dart:io';
import 'package:artisanal/artisanal.dart' show Console;
import 'package:artisanal/uv.dart';
import 'package:image/image.dart' as img;

// #region compositor_usage
void main() {
  final io = Console(out: (s) => stdout.write(s), err: (s) => stderr.write(s));
  final caps = TerminalCapabilities(
    env: Platform.environment.entries
        .map((e) => '${e.key}=${e.value}')
        .toList(),
  );
  io.write('Detected capabilities (env hints only):\n');
  io.write('  TERM=${Platform.environment['TERM'] ?? ''}\n');
  io.write('  TERM_PROGRAM=${Platform.environment['TERM_PROGRAM'] ?? ''}\n');
  io.write('  LC_TERMINAL=${Platform.environment['LC_TERMINAL'] ?? ''}\n');
  io.write('  kitty=${caps.hasKittyGraphics}\n');
  io.write('  sixel=${caps.hasSixel}\n');
  io.write('  iterm2=${caps.hasITerm2}\n');
  io.write('  keyboard=${caps.hasKeyboardEnhancements}\n');
  io.write('\n');

  // Create a simple gradient image
  final image = img.Image(width: 100, height: 100);
  for (var y = 0; y < 100; y++) {
    for (var x = 0; x < 100; x++) {
      image.setPixelRgba(x, y, x * 2, y * 2, 150, 255);
    }
  }

  final imageDrawable = Terminal.bestImageDrawable(
    image,
    capabilities: caps,
    columns: 20,
    rows: 10,
  );

  // Create layers
  final imageLayer = newLayer(imageDrawable)
    ..setId('image')
    ..setX(5)
    ..setY(2);

  final textLayer =
      newLayer(StyledString('\x1b[1;33mHello from Compositor!\x1b[0m'))
        ..setId('text')
        ..setX(2)
        ..setY(1);

  final compositor = Compositor([imageLayer, textLayer]);

  final bounds = compositor.bounds();
  // Render to a canvas
  final canvas = Canvas(bounds.width, bounds.height);
  canvas.compose(compositor);

  io.write(canvas.render());
  io.write('\nDone.\n');
}

// #endregion
