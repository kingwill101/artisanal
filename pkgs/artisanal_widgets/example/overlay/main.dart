// Overlay Example
//
// Demonstrates the Overlay and OverlayEntry widgets for managing layered
// content. Press 'a' to add an entry, 'r' to remove the last entry,
// 'c' to clear all entries.
//
// Run with: dart run example/overlay/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(OverlayDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class OverlayDemo extends w.StatelessWidget {
  OverlayDemo({super.key});

  @override
  w.Widget build(w.BuildContext context) {
    return w.Overlay(
      initialEntries: [w.OverlayEntry(builder: (_) => _OverlayDemoHost())],
    );
  }
}

class _OverlayDemoHost extends w.StatefulWidget {
  _OverlayDemoHost();

  @override
  w.State createState() => _OverlayDemoHostState();
}

class _OverlayDemoHostState extends w.State<_OverlayDemoHost> {
  int _entryCount = 0;
  final List<_EntryInfo> _entries = [];
  final List<w.OverlayEntry> _overlayEntries = [];
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  static final _colors = [
    (Colors.red, 'Red'),
    (Colors.green, 'Green'),
    (Colors.blue, 'Blue'),
    (Colors.cyan, 'Cyan'),
    (Colors.magenta, 'Magenta'),
    (Colors.yellow, 'Yellow'),
  ];

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'a') {
        final colorIdx = _entryCount % _colors.length;
        final info = _EntryInfo(
          id: _entryCount,
          color: _colors[colorIdx].$1,
          name: _colors[colorIdx].$2,
        );
        final overlayEntry = _buildOverlayEntry(
          info,
          stackIndex: _entries.length,
        );
        setState(() {
          _entries.add(info);
          _overlayEntries.add(overlayEntry);
          _entryCount++;
        });
        w.Overlay.of(context).insert(overlayEntry);
        return tui.Cmd.repaint();
      }
      if (msg.key.char == 'r' && _entries.isNotEmpty) {
        final removedEntry = _overlayEntries.removeLast();
        setState(() => _entries.removeLast());
        removedEntry.remove();
        return tui.Cmd.repaint();
      }
      if (msg.key.char == 'c') {
        final removedEntries = List<w.OverlayEntry>.from(_overlayEntries);
        setState(() {
          _entries.clear();
          _overlayEntries.clear();
        });
        for (final entry in removedEntries) {
          entry.remove();
        }
        return tui.Cmd.repaint();
      }
    }
    return null;
  }

  w.OverlayEntry _buildOverlayEntry(
    _EntryInfo entry, {
    required int stackIndex,
  }) {
    return w.OverlayEntry(
      builder: (ctx) {
        final theme = widget.theme;
        final label = theme.labelSmall.copy()..foreground(theme.onBackground);
        final entryStyle = Style()..foreground(entry.color);
        return w.Positioned(
          top: 8 + (stackIndex * 4),
          right: 3,
          child: w.Container(
            padding: const w.EdgeInsets.all(1),
            decoration: w.BoxDecoration(
              border: Border.normal,
              color: theme.surface,
            ),
            child: w.Column(
              gap: 0,
              crossAxisAlignment: w.CrossAxisAlignment.start,
              children: [
                w.Text('Overlay #${entry.id}', style: entryStyle),
                w.Text(entry.name, style: label),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Container(
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
              crossAxisAlignment: w.CrossAxisAlignment.start,
              children: [
                w.Text('Overlay Widget Demo', style: theme.titleLarge),
                w.Text(
                  'a = add entry | r = remove last | c = clear | q = quit',
                  style: label,
                ),
                w.Text('Active entries: ${_entries.length}', style: label),
                w.Divider(width: 60),
                w.Text('Base Layer', style: theme.titleMedium),
                w.Text(
                  'This is the base layer of the Overlay.\n'
                  'Additional entries stack on top.\n'
                  'New cards appear as floating layers on the right.',
                  style: label,
                ),
                w.Divider(width: 60),
                if (_entries.isEmpty)
                  w.Text(
                    'No overlay entries. Press a to add one.',
                    style: label,
                  )
                else
                  w.Text(
                    'Entries (bottom to top): '
                    '${_entries.map((e) => e.name).join(", ")}',
                    style: label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryInfo {
  _EntryInfo({required this.id, required this.color, required this.name});
  final int id;
  final Color color;
  final String name;
}
