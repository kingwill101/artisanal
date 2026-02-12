// InputChip Showcase
//
// Demonstrates InputChip selection, press, and delete behavior.
//
// Run with: dart run example/input_chip/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(InputChipShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class InputChipShowcase extends w.StatefulWidget {
  InputChipShowcase({super.key});

  @override
  w.State createState() => _InputChipShowcaseState();
}

class _InputChipShowcaseState extends w.State<InputChipShowcase> {
  bool _selected = true;
  bool _showDeletable = true;
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
          w.Text('InputChip', style: theme.titleLarge),
          w.Text(
            'Click chips, press delete/backspace while focused. q to quit.',
            style: labelStyle,
          ),
          w.Divider(width: 62),
          w.Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [
              w.InputChip(
                label: w.Text('stable'),
                avatar: w.Text('S'),
                selected: _selected,
                showCheckmark: true,
                onSelected: (value) {
                  setState(() {
                    _selected = value;
                    _status = 'selected: $value';
                  });
                  return null;
                },
                onPressed: () {
                  setState(() => _status = 'pressed stable');
                  return null;
                },
              ),
              if (_showDeletable)
                w.InputChip(
                  label: w.Text('notes.txt'),
                  avatar: w.Text('#'),
                  onDeleted: () {
                    setState(() {
                      _showDeletable = false;
                      _status = 'deleted notes.txt';
                    });
                    return null;
                  },
                ),
              w.InputChip(label: w.Text('disabled'), enabled: false),
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
