// LinearProgressIndicator Showcase
//
// Demonstrates determinate and indeterminate LinearProgressIndicator.
//
// Run with: dart run example/linear_progress_indicator/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(LinearProgressIndicatorShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class LinearProgressIndicatorShowcase extends w.StatefulWidget {
  LinearProgressIndicatorShowcase({super.key});

  @override
  w.State createState() => _LinearProgressIndicatorShowcaseState();
}

class _LinearProgressIndicatorShowcaseState
    extends w.State<LinearProgressIndicatorShowcase> {
  double _progress = 0.4;

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
          w.Text('LinearProgressIndicator', style: theme.titleLarge),
          w.Text('+/- to adjust value, q to quit.', style: labelStyle),
          w.Divider(width: 56),
          w.Text('Determinate', style: theme.titleMedium),
          w.LinearProgressIndicator(value: _progress, width: 36),
          w.Text('Value: ${(_progress * 100).round()}%', style: labelStyle),
          w.Divider(width: 56),
          w.Text('Indeterminate', style: theme.titleMedium),
          w.LinearProgressIndicator(value: null, width: 36),
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
