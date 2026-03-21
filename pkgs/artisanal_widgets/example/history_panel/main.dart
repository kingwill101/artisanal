// HistoryPanel Showcase
//
// Demonstrates the HistoryPanel widget with undo/redo stacks,
// compact and full modes, custom icons, marker text, and styling.
//
// Run with: dart run example/history_panel/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(HistoryPanelShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class HistoryPanelShowcase extends w.StatefulWidget {
  HistoryPanelShowcase({super.key});

  @override
  w.State createState() => _HistoryPanelShowcaseState();
}

class _HistoryPanelShowcaseState extends w.State<HistoryPanelShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  final _undoItems = <w.HistoryEntry>[
    const w.HistoryEntry(description: 'Open file main.dart'),
    const w.HistoryEntry(description: 'Insert import statement'),
    const w.HistoryEntry(description: 'Add function parseConfig()'),
    const w.HistoryEntry(description: 'Delete unused variable'),
    const w.HistoryEntry(description: 'Rename handler to processEvent'),
    const w.HistoryEntry(description: 'Move validation to separate method'),
    const w.HistoryEntry(description: 'Add error handling try/catch'),
    const w.HistoryEntry(description: 'Update comment on line 42'),
  ];

  final _redoItems = <w.HistoryEntry>[
    const w.HistoryEntry(
      description: 'Reformat with dart format',
      isRedo: true,
    ),
    const w.HistoryEntry(description: 'Sort imports', isRedo: true),
    const w.HistoryEntry(description: 'Fix trailing comma', isRedo: true),
  ];

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
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: w.hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: w.hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: w.hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text('HistoryPanel Showcase', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(),

              // ── Compact Mode ──
              w.Text(
                'Compact Mode (default, limit=5)',
                style: theme.titleMedium,
              ),
              w.HistoryPanel(
                title: 'Edit History',
                undoItems: _undoItems,
                redoItems: _redoItems,
                mode: w.HistoryPanelMode.compact,
                compactLimit: 5,
              ),
              w.Divider(),

              // ── Full Mode ──
              w.Text('Full Mode (all items visible)', style: theme.titleMedium),
              w.HistoryPanel(
                title: 'Complete History',
                undoItems: _undoItems,
                redoItems: _redoItems,
                mode: w.HistoryPanelMode.full,
              ),
              w.Divider(),

              // ── Custom Icons & Marker ──
              w.Text('Custom Icons & Marker', style: theme.titleMedium),
              w.HistoryPanel(
                title: 'Timeline',
                undoItems: _undoItems.take(4).toList(),
                redoItems: _redoItems.take(2).toList(),
                undoIcon: '← ',
                redoIcon: '→ ',
                markerText: '═══ NOW ═══',
              ),
              w.Divider(),

              // ── Undo Only ──
              w.Text('Undo Only (no redo items)', style: theme.titleMedium),
              w.HistoryPanel(
                title: 'Undo Stack',
                undoItems: _undoItems.take(5).toList(),
              ),
              w.Divider(),

              // ── Redo Only ──
              w.Text('Redo Only (no undo items)', style: theme.titleMedium),
              w.HistoryPanel(title: 'Redo Stack', redoItems: _redoItems),
              w.Divider(),

              // ── Empty ──
              w.Text('Empty Panel', style: theme.titleMedium),
              w.HistoryPanel(title: 'No History Yet'),
              w.Divider(),

              // ── Compact with small limit ──
              w.Text('Compact Limit=2', style: theme.titleMedium),
              w.HistoryPanel(
                title: 'Recent Only',
                undoItems: _undoItems,
                redoItems: _redoItems,
                compactLimit: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
