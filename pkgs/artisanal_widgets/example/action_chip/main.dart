// ActionChip Showcase
//
// Demonstrates ActionChip interaction callbacks.
//
// Run with: dart run example/action_chip/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ActionChipShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ActionChipShowcase extends w.StatefulWidget {
  ActionChipShowcase({super.key});

  @override
  w.State createState() => _ActionChipShowcaseState();
}

class _ActionChipShowcaseState extends w.State<ActionChipShowcase> {
  int _runCount = 0;
  int _buildCount = 0;
  String _lastAction = 'none';

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
          w.Text('ActionChip', style: theme.titleLarge),
          w.Text('Click chips to run actions. q to quit.', style: labelStyle),
          w.Divider(width: 48),
          w.Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [
              w.ActionChip(
                label: w.Text('Run checks'),
                avatar: w.Text('>'),
                onPressed: () {
                  setState(() {
                    _runCount++;
                    _lastAction = 'checks';
                  });
                  return null;
                },
              ),
              w.ActionChip(
                label: w.Text('Build'),
                avatar: w.Text('#'),
                onPressed: () {
                  setState(() {
                    _buildCount++;
                    _lastAction = 'build';
                  });
                  return null;
                },
              ),
              w.ActionChip(label: w.Text('Disabled'), enabled: false),
            ],
          ),
          w.Text('Checks: $_runCount  Builds: $_buildCount', style: labelStyle),
          w.Text('Last action: $_lastAction', style: labelStyle),
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
