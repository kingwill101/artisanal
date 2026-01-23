import 'dart:io';
import 'package:artisanal/artisanal.dart';
import 'package:image/image.dart' as img;

void main() {
  final io = Console(out: stdout.writeln, err: stderr.writeln);

  io.title('Kitty Image Protocol Demo');

  // Create a simple test image (100x100)
  final image = img.Image(width: 100, height: 100);

  // Fill with a gradient
  for (var y = 0; y < 100; y++) {
    for (var x = 0; x < 100; x++) {
      image.setPixelRgb(x, y, x * 2, y * 2, 128);
    }
  }

  // Draw a circle in the middle
  img.drawCircle(
    image,
    x: 50,
    y: 50,
    radius: 30,
    color: img.ColorRgb8(255, 255, 255),
  );

  io.writeln('Displaying a generated 100x100 gradient image with a circle:');
  io.writeln();

  // Encode and write to stdout
  final kittySequence = KittyImage.encode(image);
  stdout.write(kittySequence);

  io.writeln();
  io.writeln();
  io.info(
    'Note: This requires a terminal that supports the Kitty Graphics Protocol (like Kitty, WezTerm, or Konsole).',
  );
  io.success('Demo complete.');
}
