// LayoutBuilder Widget Example
//
// Demonstrates using LayoutBuilder to build responsive layouts
// based on available constraints from MediaQuery.
//
// Run with: dart run example/layout_builder/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(LayoutBuilderExample());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class LayoutBuilderExample extends w.StatefulWidget {
  LayoutBuilderExample({super.key});

  @override
  w.State createState() => _LayoutBuilderExampleState();
}

class _LayoutBuilderExampleState extends w.State<LayoutBuilderExample> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

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
              children: [
                w.Text('LayoutBuilder Widget', style: theme.titleLarge),
                w.Text(
                  'Resize terminal to see constraints change. q: quit',
                  style: label,
                ),
                w.Divider(width: 50),

                // Show current constraints
                w.Text('Current constraints:', style: theme.titleMedium),
                w.LayoutBuilder(
                  builder: (ctx, constraints) {
                    return w.Container(
                      padding: const w.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      decoration: w.BoxDecoration(border: Border.rounded),
                      child: w.Column(
                        children: [
                          w.Text(
                            'maxWidth:  ${constraints.maxWidth.toInt()}',
                            style: Style().foreground(theme.success),
                          ),
                          w.Text(
                            'maxHeight: ${constraints.maxHeight.toInt()}',
                            style: Style().foreground(theme.success),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                w.Divider(width: 50),

                // Responsive layout — switches between wide and narrow
                w.Text(
                  'Responsive layout (wide >60, narrow <=60):',
                  style: theme.titleMedium,
                ),
                w.LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth > 60;
                    if (isWide) {
                      return w.Row(
                        gap: 2,
                        children: [
                          w.Container(
                            padding: const w.EdgeInsets.all(1),
                            decoration: w.BoxDecoration(border: Border.rounded),
                            child: w.Text(
                              'Panel A',
                              style: Style().foreground(theme.primary),
                            ),
                          ),
                          w.Container(
                            padding: const w.EdgeInsets.all(1),
                            decoration: w.BoxDecoration(border: Border.rounded),
                            child: w.Text(
                              'Panel B',
                              style: Style().foreground(theme.warning),
                            ),
                          ),
                          w.Container(
                            padding: const w.EdgeInsets.all(1),
                            decoration: w.BoxDecoration(border: Border.rounded),
                            child: w.Text(
                              'Panel C',
                              style: Style().foreground(theme.success),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return w.Column(
                        gap: 1,
                        children: [
                          w.Text(
                            'Panel A',
                            style: Style().foreground(theme.primary),
                          ),
                          w.Text(
                            'Panel B',
                            style: Style().foreground(theme.warning),
                          ),
                          w.Text(
                            'Panel C',
                            style: Style().foreground(theme.success),
                          ),
                        ],
                      );
                    }
                  },
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
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
