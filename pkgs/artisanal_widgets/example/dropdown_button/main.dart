// DropdownButton Showcase
//
// Demonstrates DropdownButton and DropdownMenuItem selection behavior.
//
// Run with: dart run example/dropdown_button/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(DropdownButtonShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class DropdownButtonShowcase extends w.StatefulWidget {
  DropdownButtonShowcase({super.key});

  @override
  w.State createState() => _DropdownButtonShowcaseState();
}

class _DropdownButtonShowcaseState extends w.State<DropdownButtonShowcase> {
  String? _selected = 'main';

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
          w.Text('DropdownButton', style: theme.titleLarge),
          w.Text('Click to cycle enabled items. q to quit.', style: labelStyle),
          w.Divider(width: 52),
          w.DropdownButton<String>(
            value: _selected,
            hint: w.Text('Select branch'),
            items: [
              w.DropdownMenuItem(value: 'main', child: w.Text('main')),
              w.DropdownMenuItem(value: 'develop', child: w.Text('develop')),
              w.DropdownMenuItem(value: 'release', child: w.Text('release')),
              w.DropdownMenuItem(
                value: 'archived',
                child: w.Text('archived'),
                enabled: false,
              ),
            ],
            onChanged: (value) {
              setState(() => _selected = value);
              return null;
            },
          ),
          w.DropdownButton<String>(
            enabled: false,
            hint: w.Text('Hint'),
            disabledHint: w.Text('Dropdown disabled'),
            items: [w.DropdownMenuItem(value: 'x', child: w.Text('x'))],
          ),
          w.Text('Selected: ${_selected ?? 'none'}', style: labelStyle),
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
