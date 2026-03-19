// Slider Showcase
//
// Demonstrates Slider with keyboard and mouse interactions.
//
// Run with: dart run example/slider/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(SliderShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class SliderShowcase extends w.StatefulWidget {
  SliderShowcase({super.key});

  @override
  w.State createState() => _SliderShowcaseState();
}

class _SliderShowcaseState extends w.State<SliderShowcase> {
  double _volume = 0.35;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final labelStyle = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('Slider', style: theme.titleLarge),
          w.Text(
            'Click or drag the track. Arrow keys when focused. q to quit.',
            style: labelStyle,
          ),
          w.Divider(width: 64),
          w.Slider(
            value: _volume,
            width: 36,
            divisions: 20,
            label: 'Volume',
            onChanged: (value) {
              setState(() => _volume = value);
              return null;
            },
          ),
          w.Text('Volume: ${(_volume * 100).round()}%', style: labelStyle),
          w.Slider(value: 0.7, width: 20, enabled: false),
        ],
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
