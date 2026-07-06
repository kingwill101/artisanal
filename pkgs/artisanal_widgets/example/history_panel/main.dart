// HistoryPanel Showcase
//
// Demonstrates the HistoryPanel widget with undo/redo stacks,
// compact and full modes, custom icons, marker text, and styling.
//
// Run with: dart run example/history_panel/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';

void main() async {
  final app = WidgetApp(HistoryPanelShowcase());
  await runProgram(
    app,
    options: const ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: MouseMode.allMotion,
    ),
  );
}

class HistoryPanelShowcase extends StatefulWidget {
  HistoryPanelShowcase({super.key});

  @override
  State createState() => _HistoryPanelShowcaseState();
}

class _HistoryPanelShowcaseState extends State<HistoryPanelShowcase> {
  final WidgetScrollController _scrollController = WidgetScrollController();
  final _undoItems = <HistoryEntry>[
    const HistoryEntry(description: 'Open file main.dart'),
    const HistoryEntry(description: 'Insert import statement'),
    const HistoryEntry(description: 'Add function parseConfig()'),
    const HistoryEntry(description: 'Delete unused variable'),
    const HistoryEntry(description: 'Rename handler to processEvent'),
    const HistoryEntry(description: 'Move validation to separate method'),
    const HistoryEntry(description: 'Add error handling try/catch'),
    const HistoryEntry(description: 'Update comment on line 42'),
  ];

  final _redoItems = <HistoryEntry>[
    const HistoryEntry(
      description: 'Reformat with dart format',
      isRedo: true,
    ),
    const HistoryEntry(description: 'Sort imports', isRedo: true),
    const HistoryEntry(description: 'Fix trailing comma', isRedo: true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return Container(
      padding: const EdgeInsets.all(1),
      color: theme.background,
      child: Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: ScrollbarGradient.background(
          start: hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: ScrollbarGradient.background(
          start: hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: ScrollbarGradient.background(
          start: hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: Column(
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('HistoryPanel Showcase', style: theme.titleLarge),
              Text('Press q to quit.', style: label),
              Divider(),

              // ── Compact Mode ──
              Text(
                'Compact Mode (default, limit=5)',
                style: theme.titleMedium,
              ),
              HistoryPanel(
                title: 'Edit History',
                undoItems: _undoItems,
                redoItems: _redoItems,
                mode: HistoryPanelMode.compact,
                compactLimit: 5,
              ),
              Divider(),

              // ── Full Mode ──
              Text('Full Mode (all items visible)', style: theme.titleMedium),
              HistoryPanel(
                title: 'Complete History',
                undoItems: _undoItems,
                redoItems: _redoItems,
                mode: HistoryPanelMode.full,
              ),
              Divider(),

              // ── Custom Icons & Marker ──
              Text('Custom Icons & Marker', style: theme.titleMedium),
              HistoryPanel(
                title: 'Timeline',
                undoItems: _undoItems.take(4).toList(),
                redoItems: _redoItems.take(2).toList(),
                undoIcon: '← ',
                redoIcon: '→ ',
                markerText: '═══ NOW ═══',
              ),
              Divider(),

              // ── Undo Only ──
              Text('Undo Only (no redo items)', style: theme.titleMedium),
              HistoryPanel(
                title: 'Undo Stack',
                undoItems: _undoItems.take(5).toList(),
              ),
              Divider(),

              // ── Redo Only ──
              Text('Redo Only (no undo items)', style: theme.titleMedium),
              HistoryPanel(title: 'Redo Stack', redoItems: _redoItems),
              Divider(),

              // ── Empty ──
              Text('Empty Panel', style: theme.titleMedium),
              HistoryPanel(title: 'No History Yet'),
              Divider(),

              // ── Compact with small limit ──
              Text('Compact Limit=2', style: theme.titleMedium),
              HistoryPanel(
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
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg && msg.key.char == 'q') return Cmd.quit();
    return null;
  }
}
