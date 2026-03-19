// Tint Example
//
// Demonstrates the Tint widget with different colors and opacity levels.
// Cycle through colors with 'c' and adjust opacity with +/-.
//
// Run with: dart run example/tint/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(TintDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class TintDemo extends w.StatefulWidget {
  TintDemo({super.key});

  @override
  w.State createState() => _TintDemoState();
}

class _TintDemoState extends w.State<TintDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _colorIndex = 0;
  double _opacity = 1.0;

  static final _colors = [
    (Colors.red, 'Red'),
    (Colors.green, 'Green'),
    (Colors.blue, 'Blue'),
    (Colors.cyan, 'Cyan'),
    (Colors.magenta, 'Magenta'),
    (Colors.yellow, 'Yellow'),
  ];

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'c') {
        setState(() {
          _colorIndex = (_colorIndex + 1) % _colors.length;
        });
      }
      if (msg.key.char == '+' && _opacity < 1.0) {
        setState(() {
          _opacity = (_opacity + 0.25).clamp(0.0, 1.0);
        });
      }
      if (msg.key.char == '-' && _opacity > 0.0) {
        setState(() {
          _opacity = (_opacity - 0.25).clamp(0.0, 1.0);
        });
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = Style()..foreground(theme.onSurface);

    final currentColor = _colors[_colorIndex].$1;
    final currentName = _colors[_colorIndex].$2;

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
                w.Text('Tint Widget Demo', style: theme.titleLarge),
                w.Text(
                  'c = cycle color | +/- = adjust opacity | q = quit',
                  style: label,
                ),
                w.Divider(width: 60),

                w.Text(
                  'Color: $currentName | Opacity: ${_opacity.toStringAsFixed(2)}',
                  style: theme.titleMedium,
                ),
                w.Divider(width: 60),

                // -- Tint applied to text --
                w.Text('Tinted Text:', style: theme.titleMedium),
                w.Tint(
                  color: currentColor,
                  opacity: _opacity,
                  child: w.Text(
                    'This text has a $currentName tint applied',
                    style: onSurface,
                  ),
                ),
                w.Divider(width: 60),

                // -- Tint applied to a container --
                w.Text('Tinted Container:', style: theme.titleMedium),
                w.Tint(
                  color: currentColor,
                  opacity: _opacity,
                  child: w.Container(
                    width: 40,
                    height: 3,
                    color: theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text('Container content', style: onSurface),
                  ),
                ),
                w.Divider(width: 60),

                // -- Side-by-side opacity comparison --
                w.Text('Opacity Comparison:', style: theme.titleMedium),
                w.Row(
                  gap: 2,
                  children: [
                    w.Column(
                      children: [
                        w.Text('0.0', style: label),
                        w.Tint(
                          color: currentColor,
                          opacity: 0.0,
                          child: w.Text('Sample', style: onSurface),
                        ),
                      ],
                    ),
                    w.Column(
                      children: [
                        w.Text('0.5', style: label),
                        w.Tint(
                          color: currentColor,
                          opacity: 0.5,
                          child: w.Text('Sample', style: onSurface),
                        ),
                      ],
                    ),
                    w.Column(
                      children: [
                        w.Text('1.0', style: label),
                        w.Tint(
                          color: currentColor,
                          opacity: 1.0,
                          child: w.Text('Sample', style: onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
