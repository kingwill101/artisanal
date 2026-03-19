// CircularProgressIndicator Showcase
//
// Demonstrates determinate and indeterminate CircularProgressIndicator.
//
// Run with: dart run example/circular_progress_indicator/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(CircularProgressIndicatorShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class CircularProgressIndicatorShowcase extends w.StatefulWidget {
  CircularProgressIndicatorShowcase({super.key});

  @override
  w.State createState() => _CircularProgressIndicatorShowcaseState();
}

class _CircularProgressIndicatorShowcaseState
    extends w.State<CircularProgressIndicatorShowcase> {
  double _progress = 0.35;

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
          w.Text('CircularProgressIndicator', style: theme.titleLarge),
          w.Text('+/- to adjust value, q to quit.', style: labelStyle),
          w.Divider(width: 58),
          w.Row(
            gap: 2,
            children: [
              w.Text('Determinate:'),
              w.CircularProgressIndicator(value: _progress),
              w.Text('Value: ${(_progress * 100).round()}%', style: labelStyle),
            ],
          ),
          w.Row(
            gap: 2,
            children: [
              w.Text('Indeterminate:'),
              w.CircularProgressIndicator(
                key: const w.Key('circular-indeterminate'),
                value: null,
                interval: const Duration(milliseconds: 120),
              ),
            ],
          ),
          w.Text('0%..100% maps to ○ ◔ ◑ ◕ ●', style: labelStyle),
        ],
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    if (msg.key.char == 'q') return tui.Cmd.quit();
    if (msg.key.char == '+' || msg.key.char == '=') {
      setState(() => _progress = (_progress + 0.05).clamp(0.0, 1.0));
    }
    if (msg.key.char == '-') {
      setState(() => _progress = (_progress - 0.05).clamp(0.0, 1.0));
    }
    return null;
  }
}
