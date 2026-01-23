import 'dart:io';
import 'package:artisanal/uv.dart';
import 'package:artisanal/src/uv/iterm2_drawable.dart' show ITerm2ImageDrawable;
import 'package:artisanal/src/uv/kitty_drawable.dart' show KittyImageDrawable;
import 'package:artisanal/src/uv/sixel_drawable.dart' show SixelImageDrawable;
import 'package:image/image.dart' as img;

void main() async {
  final terminal = Terminal();

  stdout.writeln('Probing terminal capabilities (DA1/DA2/Kitty)...');
  await terminal.start();

  // Wait for async responses to populate capabilities
  await Future.delayed(const Duration(milliseconds: 600));

  final caps = terminal.capabilities;
  stdout.writeln('Capabilities discovered:');
  stdout.writeln('  Kitty Graphics: ${caps.hasKittyGraphics ? "YES" : "NO"}');
  stdout.writeln('  iTerm2 Images:  ${caps.hasITerm2 ? "YES" : "NO"}');
  stdout.writeln('  Sixel Graphics: ${caps.hasSixel ? "YES" : "NO"}');
  stdout.writeln(
    '  Keyboard Ext:   ${caps.hasKeyboardEnhancements ? "YES" : "NO"}',
  );
  stdout.writeln('');

  final image = img.Image(width: 100, height: 50);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final r = (x / image.width * 255).toInt();
      final g = (y / image.height * 255).toInt();
      image.setPixelRgb(x, y, r, g, 150);
    }
  }

  terminal.enterAltScreen();
  terminal.hideCursor();

  void draw() {
    final buf = terminal;
    buf.fill(Cell(content: ' '));

    // Kitty
    _write(terminal, 2, 1, 'Kitty Graphics Protocol');
    if (caps.hasKittyGraphics) {
      KittyImageDrawable(
        image,
        columns: 20,
        rows: 10,
      ).draw(terminal, rect(2, 2, 20, 10));
    } else {
      _write(terminal, 2, 2, '[Not Supported]');
    }

    // iTerm2
    _write(terminal, 25, 1, 'iTerm2 Inline Images');
    if (caps.hasITerm2) {
      ITerm2ImageDrawable(
        image,
        columns: 20,
        rows: 10,
      ).draw(terminal, rect(25, 2, 20, 10));
    } else {
      _write(terminal, 25, 2, '[Not Supported]');
    }

    // Sixel
    _write(terminal, 48, 1, 'Sixel Graphics');
    if (caps.hasSixel) {
      SixelImageDrawable(
        image,
        columns: 20,
        rows: 10,
      ).draw(terminal, rect(48, 2, 20, 10));
    } else {
      _write(terminal, 48, 2, '[Not Supported]');
    }

    _write(terminal, 2, 14, 'Best Fit (Auto-detected):');
    terminal
        .bestImageDrawableForTerminal(image, columns: 20, rows: 10)
        .draw(terminal, rect(2, 15, 20, 10));

    _write(terminal, 2, 27, 'Press any key to exit...');
    terminal.draw();
  }

  draw();

  // Wait for a key
  await for (final event in terminal.events) {
    if (event is KeyPressEvent) break;
  }

  await terminal.stop();
  exit(0);
}

void _write(Screen buf, int x, int y, String text) {
  for (var i = 0; i < text.length; i++) {
    buf.setCell(x + i, y, Cell(content: text[i]));
  }
}
