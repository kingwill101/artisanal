// VerticalDivider Widget Example
//
// Demonstrates using VerticalDivider to separate content horizontally
// with various characters, heights, and styles.
//
// Run with: dart run example/vertical_divider/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(VerticalDividerExample());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class VerticalDividerExample extends w.StatefulWidget {
  VerticalDividerExample({super.key});

  @override
  w.State createState() => _VerticalDividerExampleState();
}

class _VerticalDividerExampleState extends w.State<VerticalDividerExample> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
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
              w.Text('VerticalDivider Widget', style: theme.titleLarge),
              w.Text('q: quit', style: label),
              w.Divider(width: 50),

              // Default VerticalDivider
              w.Text('Default (height: 3, char: │):', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.Text('Left', style: Style().foreground(theme.primary)),
                  w.VerticalDivider(),
                  w.Text('Right', style: Style().foreground(theme.success)),
                ],
              ),

              w.Divider(width: 50),

              // Multiple dividers with custom chars
              w.Text('Custom characters:', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.Text('A', style: Style().foreground(theme.primary)),
                  w.VerticalDivider(height: 3, char: '┃'),
                  w.Text('B', style: Style().foreground(theme.warning)),
                  w.VerticalDivider(height: 3, char: '║'),
                  w.Text('C', style: Style().foreground(theme.success)),
                  w.VerticalDivider(height: 3, char: ':'),
                  w.Text('D', style: Style().foreground(theme.error)),
                ],
              ),

              w.Divider(width: 50),

              // Custom styles
              w.Text('Custom styles and heights:', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Text('Short', style: label),
                  w.VerticalDivider(
                    height: 1,
                    style: Style().foreground(theme.error),
                  ),
                  w.Text('Medium', style: label),
                  w.VerticalDivider(
                    height: 3,
                    style: Style().foreground(theme.warning),
                  ),
                  w.Text('Tall', style: label),
                  w.VerticalDivider(
                    height: 5,
                    style: Style().foreground(theme.success),
                  ),
                ],
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
