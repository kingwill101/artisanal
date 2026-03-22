// Command Palette Showcase
//
// Demonstrates the CommandPalette widget with Bayesian scoring, tag
// matching, and incremental filtering. Open with Ctrl+P or 'p'.
//
// The palette uses Bayesian scoring to rank results:
// - "gd" → "Go Dashboard" (word-start match, high score)
// - "sav" → "Save Session", "Save All" (prefix matches)
// - "file" → "Open File", "Save File" (substring + tag matches)
//
// Run with: dart run example/command_palette/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(CommandPaletteShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class CommandPaletteShowcase extends w.StatefulWidget {
  CommandPaletteShowcase({super.key});

  @override
  w.State createState() => _CommandPaletteShowcaseState();
}

class _CommandPaletteShowcaseState extends w.State<CommandPaletteShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _paletteOpen = false;
  String _lastAction = '(none)';

  static const _commands = [
    // Session
    w.CommandPaletteItem(
      label: 'New Session',
      shortcut: 'ctrl+n',
      group: 'Session',
      tags: ['create', 'start', 'begin'],
    ),
    w.CommandPaletteItem(
      label: 'Session List',
      shortcut: 'ctrl+l',
      group: 'Session',
      tags: ['browse', 'history'],
    ),
    w.CommandPaletteItem(
      label: 'Clear Messages',
      group: 'Session',
      tags: ['reset', 'empty', 'wipe'],
    ),
    w.CommandPaletteItem(
      label: 'Exit',
      shortcut: 'ctrl+c',
      group: 'Session',
      tags: ['quit', 'close', 'end'],
    ),
    // View
    w.CommandPaletteItem(
      label: 'Toggle Sidebar',
      shortcut: 'ctrl+b',
      group: 'View',
      tags: ['panel', 'hide', 'show'],
    ),
    w.CommandPaletteItem(
      label: 'Toggle Theme',
      group: 'View',
      tags: ['dark', 'light', 'color', 'appearance'],
    ),
    w.CommandPaletteItem(
      label: 'Zoom In',
      shortcut: 'ctrl++',
      group: 'View',
      tags: ['increase', 'bigger', 'font'],
    ),
    w.CommandPaletteItem(
      label: 'Zoom Out',
      shortcut: 'ctrl+-',
      group: 'View',
      tags: ['decrease', 'smaller', 'font'],
    ),
    // File
    w.CommandPaletteItem(
      label: 'Open File',
      shortcut: 'ctrl+o',
      group: 'File',
      tags: ['load', 'read', 'browse'],
    ),
    w.CommandPaletteItem(
      label: 'Save File',
      shortcut: 'ctrl+s',
      group: 'File',
      tags: ['write', 'persist', 'disk'],
    ),
    w.CommandPaletteItem(
      label: 'Save All',
      shortcut: 'ctrl+shift+s',
      group: 'File',
      tags: ['write', 'persist', 'batch'],
    ),
    w.CommandPaletteItem(
      label: 'Go Dashboard',
      group: 'Navigate',
      tags: ['home', 'overview', 'stats'],
    ),
    w.CommandPaletteItem(
      label: 'Go to Line',
      shortcut: 'ctrl+g',
      group: 'Navigate',
      tags: ['jump', 'goto', 'number'],
    ),
    w.CommandPaletteItem(
      label: 'Git Diff',
      group: 'Git',
      tags: ['version', 'changes', 'vcs'],
    ),
    w.CommandPaletteItem(
      label: 'Git Commit',
      shortcut: 'ctrl+enter',
      group: 'Git',
      tags: ['version', 'save', 'vcs'],
    ),
    w.CommandPaletteItem(
      label: 'Settings',
      shortcut: 'ctrl+,',
      group: 'Preferences',
      tags: ['config', 'options', 'customize'],
    ),
    w.CommandPaletteItem(
      label: 'Keyboard Shortcuts',
      shortcut: 'ctrl+k ctrl+s',
      group: 'Preferences',
      tags: ['keybindings', 'hotkeys', 'keys'],
    ),
  ];

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final dim = theme.bodySmall.copy()..foreground(theme.muted);

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
        child: w.CommandPalette(
          open: _paletteOpen,
          title: 'Commands',
          hint: 'Type to search...',
          width: 70,
          maxHeight: 30,
          items: _commands,
          onDismiss: () {
            setState(() => _paletteOpen = false);
            return null;
          },
          onSelect: (item) {
            setState(() {
              _paletteOpen = false;
              _lastAction = item.label;
            });
            return null;
          },
          child: w.ScrollView(
            controller: _scrollController,
            handleKeys: true,
            child: w.Column(
              gap: 1,
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              children: [
                w.Text('Command Palette Showcase', style: theme.titleLarge),
                w.Text(
                  'Press Ctrl+P or "p" to open. Press q to quit.',
                  style: label,
                ),
                w.Divider(),

                w.Text('Scoring Demo', style: theme.titleMedium),
                w.Text(
                  'The palette ranks results using Bayesian scoring:',
                  style: label,
                ),
                w.Text(
                  '  exact > prefix > word-start > substring > fuzzy',
                  style: dim,
                ),
                w.Text('', style: label),
                w.Text('Try these queries:', style: label),
                w.Text('  "gd"  → Go Dashboard (word-start)', style: dim),
                w.Text('  "sav" → Save File, Save All (prefix)', style: dim),
                w.Text(
                  '  "git" → Git Diff, Git Commit (prefix + tags)',
                  style: dim,
                ),
                w.Text(
                  '  "s"   → Save, Session, Settings (substring)',
                  style: dim,
                ),
                w.Text(
                  '  "f"   → Open File, Save File, Toggle Theme (mixed)',
                  style: dim,
                ),
                w.Divider(),

                w.Text('Tag Matching', style: theme.titleMedium),
                w.Text(
                  'Items have searchable tags that boost scores:',
                  style: label,
                ),
                w.Text(
                  '  "vcs" → Git Diff, Git Commit (tag match)',
                  style: dim,
                ),
                w.Text('  "font" → Zoom In, Zoom Out (tag match)', style: dim),
                w.Divider(),

                w.Text('Status', style: theme.titleMedium),
                w.Row(
                  gap: 2,
                  children: [
                    w.Text('Palette:', style: label),
                    w.Badge(
                      _paletteOpen ? 'OPEN' : 'CLOSED',
                      background: _paletteOpen ? Colors.green : Colors.gray,
                      foreground: _paletteOpen ? Colors.black : Colors.white,
                    ),
                  ],
                ),
                w.Row(
                  gap: 2,
                  children: [
                    w.Text('Last action:', style: label),
                    w.Text(_lastAction, style: dim),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q' && !_paletteOpen) return tui.Cmd.quit();
      if (msg.key.char == 'p' && !_paletteOpen) {
        setState(() => _paletteOpen = true);
        return null;
      }
    }
    return null;
  }
}
