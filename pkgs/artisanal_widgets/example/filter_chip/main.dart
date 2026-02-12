// FilterChip Showcase
//
// Demonstrates multi-selection behavior with FilterChip.
//
// Run with: dart run example/filter_chip/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(FilterChipShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class FilterChipShowcase extends w.StatefulWidget {
  FilterChipShowcase({super.key});

  @override
  w.State createState() => _FilterChipShowcaseState();
}

class _FilterChipShowcaseState extends w.State<FilterChipShowcase> {
  bool _open = true;
  bool _merged = false;
  bool _assigned = true;

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
          w.Text('FilterChip', style: theme.titleLarge),
          w.Text('Toggle filters. q to quit.', style: labelStyle),
          w.Divider(width: 48),
          w.Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [
              w.FilterChip(
                label: w.Text('Open'),
                selected: _open,
                onSelected: (selected) {
                  setState(() => _open = selected);
                  return null;
                },
              ),
              w.FilterChip(
                label: w.Text('Merged'),
                selected: _merged,
                onSelected: (selected) {
                  setState(() => _merged = selected);
                  return null;
                },
              ),
              w.FilterChip(
                label: w.Text('Assigned to me'),
                selected: _assigned,
                onSelected: (selected) {
                  setState(() => _assigned = selected);
                  return null;
                },
              ),
            ],
          ),
          w.Text('Active filters: ${_activeFilters()}', style: labelStyle),
        ],
      ),
    );
  }

  String _activeFilters() {
    final filters = <String>[];
    if (_open) filters.add('Open');
    if (_merged) filters.add('Merged');
    if (_assigned) filters.add('Assigned');
    if (filters.isEmpty) return 'none';
    return filters.join(', ');
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
