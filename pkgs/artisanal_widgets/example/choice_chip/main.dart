// ChoiceChip Showcase
//
// Demonstrates single-selection behavior with ChoiceChip.
//
// Run with: dart run example/choice_chip/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ChoiceChipShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ChoiceChipShowcase extends w.StatefulWidget {
  ChoiceChipShowcase({super.key});

  @override
  w.State createState() => _ChoiceChipShowcaseState();
}

class _ChoiceChipShowcaseState extends w.State<ChoiceChipShowcase> {
  String _selected = 'Stable';

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
          w.Text('ChoiceChip', style: theme.titleLarge),
          w.Text('Pick one release channel. q to quit.', style: labelStyle),
          w.Divider(width: 48),
          w.Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [
              _choiceChip('Stable', 'S'),
              _choiceChip('Beta', 'B'),
              _choiceChip('Nightly', 'N'),
            ],
          ),
          w.Text('Selected: $_selected', style: labelStyle),
        ],
      ),
    );
  }

  w.Widget _choiceChip(String label, String avatar) {
    return w.ChoiceChip(
      label: w.Text(label),
      avatar: w.Text(avatar),
      selected: _selected == label,
      onSelected: (selected) {
        if (!selected) return null;
        setState(() => _selected = label);
        return null;
      },
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
