// Modal & Drawer Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates Modal dialog overlay and Drawer side panel,
// both with dismiss handling and interactive open/close.
//
// Run with: dart run example/modal_drawer/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(ModalDrawerShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ModalDrawerShowcase extends w.StatefulWidget {
  ModalDrawerShowcase({super.key});

  @override
  w.State createState() => _ModalDrawerShowcaseState();
}

class _ModalDrawerShowcaseState extends w.State<ModalDrawerShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _modalOpen = false;
  bool _drawerLeftOpen = false;
  bool _drawerRightOpen = false;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    // Modal dialog content
    final dialog = w.Card(
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        children: [
          w.Text('Confirm Action', style: theme.titleSmall),
          w.Text('Are you sure you want to proceed?', style: theme.bodySmall),
          w.Row(
            gap: 1,
            children: [
              w.Button(
                label: 'Cancel',
                variant: w.ButtonVariant.outline,
                size: w.ButtonSize.small,
                onPressed: () {
                  setState(() => _modalOpen = false);
                  return null;
                },
              ),
              w.Button(
                label: 'Confirm',
                size: w.ButtonSize.small,
                onPressed: () {
                  setState(() => _modalOpen = false);
                  return null;
                },
              ),
            ],
          ),
        ],
      ),
    );

    // Drawer content
    final drawerContent = w.Container(
      color: theme.surface,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        children: [
          w.Text('Navigation', style: theme.titleSmall),
          w.Divider(width: 16),
          w.Text('Dashboard', style: theme.bodySmall),
          w.Text('Settings', style: theme.bodySmall),
          w.Text('Profile', style: theme.bodySmall),
          w.Divider(width: 16),
          w.Button(
            label: 'Close',
            size: w.ButtonSize.small,
            variant: w.ButtonVariant.ghost,
            onPressed: () {
              setState(() {
                _drawerLeftOpen = false;
                _drawerRightOpen = false;
              });
              return null;
            },
          ),
        ],
      ),
    );

    // Main content area wrapped by Modal
    final mainContent = w.Container(
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
            children: [
              w.Text('Modal & Drawer Showcase', style: theme.titleLarge),
              w.Text(
                'm: modal, d: drawer left, r: drawer right, q: quit',
                style: label,
              ),
              w.Divider(width: 55),
              w.Row(
                gap: 1,
                children: [
                  w.Button(
                    label: 'Open Modal',
                    onPressed: () {
                      setState(() => _modalOpen = true);
                      return null;
                    },
                  ),
                  w.Button(
                    label: 'Drawer Left',
                    variant: w.ButtonVariant.secondary,
                    onPressed: () {
                      setState(() => _drawerLeftOpen = true);
                      return null;
                    },
                  ),
                  w.Button(
                    label: 'Drawer Right',
                    variant: w.ButtonVariant.outline,
                    onPressed: () {
                      setState(() => _drawerRightOpen = true);
                      return null;
                    },
                  ),
                ],
              ),
              w.Divider(width: 55),
              w.Text(
                'Modal: ${_modalOpen ? "open" : "closed"} | '
                'Drawer L: ${_drawerLeftOpen ? "open" : "closed"} | '
                'Drawer R: ${_drawerRightOpen ? "open" : "closed"}',
                style: label,
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Modal
    w.Widget result = w.Modal(
      open: _modalOpen,
      dialog: dialog,
      onDismiss: () {
        setState(() => _modalOpen = false);
        return null;
      },
      child: mainContent,
    );

    // Wrap with left Drawer
    result = w.Drawer(
      open: _drawerLeftOpen,
      width: 22,
      side: w.SidebarSide.left,
      drawer: drawerContent,
      onDismiss: () {
        setState(() => _drawerLeftOpen = false);
        return null;
      },
      child: result,
    );

    // Wrap with right Drawer
    result = w.Drawer(
      open: _drawerRightOpen,
      width: 22,
      side: w.SidebarSide.right,
      drawer: drawerContent,
      onDismiss: () {
        setState(() => _drawerRightOpen = false);
        return null;
      },
      child: result,
    );

    return result;
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') return tui.Cmd.quit();
      if (key.char == 'm') setState(() => _modalOpen = !_modalOpen);
      if (key.char == 'd') setState(() => _drawerLeftOpen = !_drawerLeftOpen);
      if (key.char == 'r') setState(() => _drawerRightOpen = !_drawerRightOpen);
    }
    return null;
  }
}
