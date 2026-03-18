// Image Example
//
// Demonstrates the Image widget with MemoryImage, UV-backed auto protocol
// selection, and various BoxFit modes.
// Uses package:image to generate a synthetic gradient image in memory.
//
// Run with: dart run example/image/main.dart

import 'dart:typed_data';

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:image/image.dart' as img;

void main() async {
  final app = tui.WidgetApp(ImageDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

/// Generates a simple gradient PNG in memory.
Uint8List _generateGradientImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final r = (x * 255 ~/ width);
      final g = (y * 255 ~/ height);
      const b = 128;
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

class ImageDemo extends w.StatefulWidget {
  ImageDemo({super.key});

  @override
  w.State createState() => _ImageDemoState();
}

class _ImageDemoState extends w.State<ImageDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _fitIndex = 0;
  late final Uint8List _imageBytes;

  static const _fits = [
    (w.BoxFit.contain, 'contain'),
    (w.BoxFit.fill, 'fill'),
    (w.BoxFit.cover, 'cover'),
    (w.BoxFit.fitWidth, 'fitWidth'),
    (w.BoxFit.fitHeight, 'fitHeight'),
    (w.BoxFit.none, 'none'),
  ];

  @override
  void initState() {
    super.initState();
    _imageBytes = _generateGradientImage(80, 40);
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'f') {
        setState(() {
          _fitIndex = (_fitIndex + 1) % _fits.length;
        });
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    final currentFit = _fits[_fitIndex].$1;
    final currentName = _fits[_fitIndex].$2;

    return w.Container(
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: w.hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: w.hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: w.hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Container(
            padding: const w.EdgeInsets.all(1),
            color: theme.background,
            child: w.Column(
              gap: 1,
              children: [
                w.Text('Image Widget Demo', style: theme.titleLarge),
                w.Text('f = cycle BoxFit | q = quit', style: label),
                w.Divider(width: 60),

                w.Text('BoxFit: $currentName', style: theme.titleMedium),
                w.Text(
                  'Gradient image (80x40 pixels) in 40x10 terminal area:',
                  style: label,
                ),
                w.Text(
                  'Render mode: auto (Kitty / iTerm2 / Sixel / half-block fallback)',
                  style: label,
                ),
                w.Container(
                  decoration: w.BoxDecoration(
                    border: Border.normal,
                    color: theme.surface,
                  ),
                  child: w.Image(
                    image: w.MemoryImage(_imageBytes),
                    width: 40,
                    height: 10,
                    fit: currentFit,
                    renderMode: w.ImageRenderMode.auto,
                    placeholder: w.Text('Loading gradient...', style: label),
                    errorWidget: w.Text(
                      'Failed to load image',
                      style: Style()..foreground(Colors.red),
                    ),
                  ),
                ),
                w.Divider(width: 60),

                w.Text('All BoxFit modes:', style: theme.titleMedium),
                w.Text(
                  'contain | fill | cover | fitWidth | fitHeight | none',
                  style: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
