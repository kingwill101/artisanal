// RangeSlider Showcase
//
// Demonstrates RangeSlider mouse and keyboard interactions.
//
// Run with: dart run example/range_slider/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(RangeSliderShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class RangeSliderShowcase extends w.StatefulWidget {
  RangeSliderShowcase({super.key});

  @override
  w.State createState() => _RangeSliderShowcaseState();
}

class _RangeSliderShowcaseState extends w.State<RangeSliderShowcase> {
  w.RangeValues _window = const w.RangeValues(0.2, 0.75);

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
          w.Text('RangeSlider', style: theme.titleLarge),
          w.Text(
            'Click/drag thumbs. Use s/e to pick start/end thumb; arrows move it. q to quit.',
            style: labelStyle,
          ),
          w.Divider(width: 74),
          w.RangeSlider(
            values: _window,
            width: 40,
            divisions: 20,
            label: 'Release Window',
            onChanged: (values) {
              setState(() => _window = values);
              return null;
            },
          ),
          w.Text(
            'Start: ${(_window.start * 100).round()}%  End: ${(_window.end * 100).round()}%',
            style: labelStyle,
          ),
          w.RangeSlider(
            values: const w.RangeValues(0.3, 0.6),
            width: 24,
            enabled: false,
          ),
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
