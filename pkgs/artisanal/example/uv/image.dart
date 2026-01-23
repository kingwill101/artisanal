import 'package:artisanal/uv.dart';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final t = Terminal();
  if (!stdin.hasTerminal) {
    print('Not a TTY');
    return;
  }

  String? imagePath;
  if (args.isNotEmpty) {
    imagePath = args[0];
  } else {
    // Try to find a default image in the workspace.
    final possiblePaths = [
      'example/tui/examples/timer/timer.gif',
      'packages/artisanal/example/tui/examples/timer/timer.gif',
      '../example/tui/examples/timer/timer.gif',
    ];
    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        imagePath = path;
        break;
      }
    }
  }

  if (imagePath == null || !File(imagePath).existsSync()) {
    print('Please provide an image path as an argument.');
    return;
  }

  final bytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image: $imagePath');
    return;
  }

  await t.start();
  t.enterAltScreen();
  t.hideCursor();

  try {
    void render() {
      t.clear();

      final header =
          '''
Image Example
=============
File: ${p.basename(imagePath!)}
Protocol: ${t.capabilities.hasKittyGraphics
              ? 'Kitty'
              : t.capabilities.hasITerm2
              ? 'iTerm2'
              : t.capabilities.hasSixel
              ? 'Sixel'
              : 'Half-block fallback'}

Press 'q' to exit.
''';
      final ss = StyledString(header);
      final headerBounds = ss.bounds();
      ss.draw(
        t,
        Rectangle(
          minX: 0,
          minY: 0,
          maxX: t.bounds().width,
          maxY: headerBounds.height,
        ),
      );

      // Render image below header.
      final imgArea = Rectangle(
        minX: 2,
        minY: headerBounds.height + 1,
        maxX: t.bounds().width - 2,
        maxY: t.bounds().height - 1,
      );

      // #region image_rendering_usage
      if (imgArea.width > 0 && imgArea.height > 0) {
        final drawable = t.bestImageDrawableForTerminal(
          image,
          columns: imgArea.width,
          rows: imgArea.height,
        );
        drawable.draw(t, imgArea);
      }
      // #endregion

      t.draw();
    }

    render();

    await for (final event in t.events) {
      if (event is KeyPressEvent) {
        final key = event.keystroke();
        if (key == 'q' || key == 'esc' || key == 'ctrl+c') {
          break;
        }
      }
      if (event is WindowSizeEvent) {
        render();
      }
      // Re-render if capabilities change (e.g. after query responses).
      if (event is KittyGraphicsEvent ||
          event is PrimaryDeviceAttributesEvent) {
        render();
      }
    }
  } finally {
    t.exitAltScreen();
    t.showCursor();
    await t.stop();
  }
}
