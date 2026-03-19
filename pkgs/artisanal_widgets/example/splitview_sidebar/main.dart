// SplitView & Sidebar Showcase
//
// Demonstrates SplitView (horizontal/vertical with flex ratios),
// Sidebar (left/right side panels with fixed width).
//
// Run with: dart run example/splitview_sidebar/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(SplitViewShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class SplitViewShowcase extends w.StatefulWidget {
  SplitViewShowcase({super.key});

  @override
  w.State createState() => _SplitViewShowcaseState();
}

class _SplitViewShowcaseState extends w.State<SplitViewShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = theme.labelSmall.copy()..foreground(theme.onSurface);

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
            children: [
              w.Text('SplitView & Sidebar Showcase', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(width: 60),

              // -- SplitView: horizontal (default) --
              w.Text('SplitView (horizontal, 1:1)', style: theme.titleMedium),
              w.SplitView(
                gap: 1,
                first: w.Container(
                  height: 4,
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Column(
                    children: [
                      w.Text('Left Pane', style: theme.titleSmall),
                      w.Text('First panel', style: onSurface),
                    ],
                  ),
                ),
                second: w.Container(
                  height: 4,
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Column(
                    children: [
                      w.Text('Right Pane', style: theme.titleSmall),
                      w.Text('Second panel', style: onSurface),
                    ],
                  ),
                ),
              ),
              w.Divider(width: 60),

              // -- SplitView: custom flex ratios --
              w.Text('SplitView (1:2 ratio)', style: theme.titleMedium),
              w.SplitView(
                gap: 1,
                firstFlex: 1,
                secondFlex: 2,
                first: w.Container(
                  height: 3,
                  color: theme.surface,
                  alignment: w.Alignment.center,
                  child: w.Text('Narrow', style: onSurface),
                ),
                second: w.Container(
                  height: 3,
                  color: theme.surface,
                  alignment: w.Alignment.center,
                  child: w.Text('Wide', style: onSurface),
                ),
              ),
              w.Divider(width: 60),

              // -- SplitView: vertical --
              w.Text('SplitView (vertical)', style: theme.titleMedium),
              w.SplitView(
                axis: w.Axis.vertical,
                gap: 1,
                first: w.Container(
                  width: 40,
                  height: 2,
                  color: theme.surface,
                  alignment: w.Alignment.center,
                  child: w.Text('Top', style: onSurface),
                ),
                second: w.Container(
                  width: 40,
                  height: 2,
                  color: theme.surface,
                  alignment: w.Alignment.center,
                  child: w.Text('Bottom', style: onSurface),
                ),
              ),
              w.Divider(width: 60),

              // -- Sidebar: left (default) --
              w.Text('Sidebar (left, width: 16)', style: theme.titleMedium),
              w.Sidebar(
                width: 16,
                gap: 1,
                sidebar: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Column(
                    children: [
                      w.Text('Nav', style: theme.titleSmall),
                      w.Text('Item 1', style: onSurface),
                      w.Text('Item 2', style: onSurface),
                      w.Text('Item 3', style: onSurface),
                    ],
                  ),
                ),
                child: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Column(
                    children: [
                      w.Text('Main Content', style: theme.titleSmall),
                      w.Text('Content area with sidebar.', style: onSurface),
                    ],
                  ),
                ),
              ),
              w.Divider(width: 60),

              // -- Sidebar: right --
              w.Text('Sidebar (right)', style: theme.titleMedium),
              w.Sidebar(
                width: 16,
                side: w.SidebarSide.right,
                sidebar: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Column(
                    children: [
                      w.Text('Props', style: theme.titleSmall),
                      w.Text('Key: val', style: onSurface),
                    ],
                  ),
                ),
                child: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Text('Content on left', style: onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
