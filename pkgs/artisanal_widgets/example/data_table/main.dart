// DataTable Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates DataTable with all border styles (normal, rounded, heavy,
// dashed, ascii), custom header/cell styling, and dynamic row management.
//
// Run with: dart run example/data_table/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(DataTableShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class DataTableShowcase extends w.StatefulWidget {
  DataTableShowcase({super.key});

  @override
  w.State createState() => _DataTableShowcaseState();
}

class _DataTableShowcaseState extends w.State<DataTableShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _styleIndex = 0;

  static const _styles = [
    w.DataTableBorderStyle.normal,
    w.DataTableBorderStyle.rounded,
    w.DataTableBorderStyle.heavy,
    w.DataTableBorderStyle.dashed,
    w.DataTableBorderStyle.ascii,
  ];

  static const _styleNames = ['normal', 'rounded', 'heavy', 'dashed', 'ascii'];

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            children: [
              w.Text('DataTable Showcase', style: theme.titleLarge),
              w.Text('Tab: cycle border style  q: quit', style: label),
              w.Text(
                'Current style: ${_styleNames[_styleIndex]}',
                style: label,
              ),
              w.Divider(width: 60),

              // -- Basic table --
              w.Text('Basic Table', style: theme.titleMedium),
              w.DataTable(
                columns: ['Name', 'Language', 'Stars'],
                rows: [
                  ['artisanal', 'Dart', '142'],
                  ['ink', 'TypeScript', '26k'],
                  ['bubbletea', 'Go', '28k'],
                  ['ratatui', 'Rust', '11k'],
                ],
                borderStyle: _styles[_styleIndex],
              ),
              w.Divider(width: 60),

              // -- All border styles side by side --
              w.Text('All Border Styles', style: theme.titleMedium),
              for (var i = 0; i < _styles.length; i++) ...[
                w.Text('  ${_styleNames[i]}:', style: label),
                w.DataTable(
                  columns: ['Key', 'Value'],
                  rows: [
                    ['host', 'localhost'],
                    ['port', '8080'],
                  ],
                  borderStyle: _styles[i],
                ),
                if (i < _styles.length - 1) w.Spacer(size: 1),
              ],
              w.Divider(width: 60),

              // -- Wider table with more columns --
              w.Text('Multi-Column Table', style: theme.titleMedium),
              w.DataTable(
                columns: ['PID', 'User', 'CPU%', 'Mem%', 'Command'],
                rows: [
                  ['1234', 'root', '12.3', '4.5', '/usr/bin/dart'],
                  ['5678', 'user', '8.7', '2.1', 'code-server'],
                  ['9012', 'user', '3.2', '1.8', 'bash'],
                  ['3456', 'root', '0.1', '0.3', 'sshd'],
                ],
                borderStyle: _styles[_styleIndex],
              ),
              w.Divider(width: 60),

              // -- Empty table --
              w.Text('Empty Table', style: theme.titleMedium),
              w.DataTable(
                columns: ['No Data', 'Available'],
                rows: [],
                borderStyle: _styles[_styleIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') return tui.Cmd.quit();
      if (key.char == '\t' || key.type == tui.KeyType.tab) {
        setState(() {
          _styleIndex = (_styleIndex + 1) % _styles.length;
        });
      }
    }
    return null;
  }
}
