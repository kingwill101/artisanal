// LimitedBox Example
//
// Demonstrates the LimitedBox widget which limits its child's size only
// when the parent provides no constraints. Shows different maxWidth and
// maxHeight configurations.
//
// Run with: dart run example/limited_box/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(LimitedBoxDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class LimitedBoxDemo extends w.StatefulWidget {
  LimitedBoxDemo({super.key});

  @override
  w.State createState() => _LimitedBoxDemoState();
}

class _LimitedBoxDemoState extends w.State<LimitedBoxDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = Style()..foreground(theme.onSurface);

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
            crossAxisAlignment: w.CrossAxisAlignment.start,
            children: [
              w.Text('LimitedBox Widget Demo', style: theme.titleLarge),
              w.Text('q = quit', style: label),
              w.Divider(width: 60),

              // Example 1: maxWidth = 30
              w.Text('LimitedBox(maxWidth: 30):', style: theme.titleMedium),
              w.LimitedBox(
                maxWidth: 30,
                child: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Text(
                    'This text is inside a LimitedBox with maxWidth: 30.',
                    style: onSurface,
                  ),
                ),
              ),
              w.Divider(width: 60),

              // Example 2: maxWidth = 50
              w.Text('LimitedBox(maxWidth: 50):', style: theme.titleMedium),
              w.LimitedBox(
                maxWidth: 50,
                child: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.all(1),
                  child: w.Text(
                    'This text is inside a LimitedBox with maxWidth: 50. '
                    'It has more room to spread out horizontally.',
                    style: onSurface,
                  ),
                ),
              ),
              w.Divider(width: 60),

              // Example 3: maxHeight = 3
              w.Text(
                'LimitedBox(maxWidth: 40, maxHeight: 3):',
                style: theme.titleMedium,
              ),
              w.LimitedBox(
                maxWidth: 40,
                maxHeight: 3,
                child: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.symmetric(horizontal: 1),
                  child: w.Text(
                    'Constrained to 3 rows max height and 40 cols max width.',
                    style: onSurface,
                  ),
                ),
              ),
              w.Divider(width: 60),

              // Explanation
              w.Text('How LimitedBox works:', style: theme.titleMedium),
              w.Text(
                'LimitedBox only applies its limits when the parent gives\n'
                'unbounded (infinite) constraints. If the parent already\n'
                'constrains the child, LimitedBox passes through unchanged.',
                style: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
