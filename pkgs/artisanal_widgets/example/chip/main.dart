// Chip Showcase
//
// Demonstrates Chip with avatar and delete action.
//
// Run with: dart run example/chip/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ChipShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ChipShowcase extends w.StatefulWidget {
  ChipShowcase({super.key});

  @override
  w.State createState() => _ChipShowcaseState();
}

class _ChipShowcaseState extends w.State<ChipShowcase> {
  bool _showArtifactChip = true;
  String _status = 'none';

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
          w.Text('Chip', style: theme.titleLarge),
          w.Text('Click x to delete chip. q to quit.', style: labelStyle),
          w.Divider(width: 48),
          w.Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [
              if (_showArtifactChip)
                w.Chip(
                  label: w.Text('artifact.log'),
                  avatar: w.Text('#'),
                  onDeleted: () {
                    setState(() {
                      _showArtifactChip = false;
                      _status = 'artifact.log deleted';
                    });
                    return null;
                  },
                ),
              w.Chip(
                label: w.Text('stable'),
                avatar: w.Text('*'),
                backgroundColor: theme.surface,
              ),
            ],
          ),
          w.Text('Status: $_status', style: labelStyle),
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
