// ColoredBox Widget Example
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates using ColoredBox to apply background colors to child widgets.
//
// Run with: dart run example/colored_box/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(ColoredBoxExample());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ColoredBoxExample extends w.StatefulWidget {
  ColoredBoxExample({super.key});

  @override
  w.State createState() => _ColoredBoxExampleState();
}

class _ColoredBoxExampleState extends w.State<ColoredBoxExample> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

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
          child: w.Column(
            gap: 1,
            children: [
              w.Text('ColoredBox Widget', style: theme.titleLarge),
              w.Text('q: quit', style: label),
              w.Divider(width: 50),

              // Basic colored boxes
              w.Text('Basic ANSI colors:', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.ColoredBox(color: Colors.blue, child: w.Text(' Blue ')),
                  w.ColoredBox(color: Colors.red, child: w.Text(' Red ')),
                  w.ColoredBox(color: Colors.green, child: w.Text(' Green ')),
                  w.ColoredBox(color: Colors.yellow, child: w.Text(' Yellow ')),
                  w.ColoredBox(color: Colors.cyan, child: w.Text(' Cyan ')),
                ],
              ),

              w.Divider(width: 50),

              // ColoredBox with styled text
              w.Text('With styled text children:', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.ColoredBox(
                    color: Colors.blue,
                    child: w.Text(' Bold ', style: Style().bold()),
                  ),
                  w.ColoredBox(
                    color: Colors.red,
                    child: w.Text(' Italic ', style: Style().italic()),
                  ),
                  w.ColoredBox(
                    color: Colors.green,
                    child: w.Text(' Underline ', style: Style().underline()),
                  ),
                ],
              ),

              w.Divider(width: 50),

              // ColoredBox wrapping complex children
              w.Text('Wrapping a Column:', style: theme.titleMedium),
              w.ColoredBox(
                color: Colors.blue,
                child: w.Column(
                  children: [
                    w.Text(' Line 1: colored background '),
                    w.Text(' Line 2: same background   '),
                    w.Text(' Line 3: still colored     '),
                  ],
                ),
              ),

              w.Divider(width: 50),

              // Empty ColoredBox
              w.Text('Empty (no child):', style: theme.titleMedium),
              w.ColoredBox(color: Colors.yellow),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
