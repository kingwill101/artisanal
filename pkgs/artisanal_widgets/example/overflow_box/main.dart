// OverflowBox & SizedOverflowBox Example
//
// Demonstrates how OverflowBox overrides child constraints and how
// SizedOverflowBox provides a fixed size while allowing children to overflow.
//
// Run with: dart run example/overflow_box/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(OverflowBoxDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class OverflowBoxDemo extends w.StatefulWidget {
  OverflowBoxDemo({super.key});

  @override
  w.State createState() => _OverflowBoxDemoState();
}

class _OverflowBoxDemoState extends w.State<OverflowBoxDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onPrimary = theme.labelSmall.copy()..foreground(theme.onPrimary);
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
            children: [
              w.Text(
                'OverflowBox & SizedOverflowBox Demo',
                style: theme.titleLarge,
              ),
              w.Text('Press q to quit.', style: label),
              w.Divider(width: 60),

              // -- OverflowBox --
              w.Text(
                'OverflowBox (maxWidth: 50 override)',
                style: theme.titleMedium,
              ),
              w.Text(
                'Parent is 30 wide, but child gets maxWidth=50:',
                style: label,
              ),
              w.Container(
                width: 30,
                height: 3,
                color: theme.surface,
                child: w.OverflowBox(
                  maxWidth: 50,
                  child: w.Container(
                    color: theme.primary,
                    alignment: w.Alignment.center,
                    child: w.Text(
                      'I can be up to 50 columns wide!',
                      style: onPrimary,
                    ),
                  ),
                ),
              ),
              w.Divider(width: 60),

              // -- OverflowBox with constrained child --
              w.Text(
                'OverflowBox (minWidth: 20, maxWidth: 20)',
                style: theme.titleMedium,
              ),
              w.Container(
                width: 40,
                height: 3,
                color: theme.surface,
                child: w.OverflowBox(
                  minWidth: 20,
                  maxWidth: 20,
                  child: w.Container(
                    color: theme.primary,
                    alignment: w.Alignment.center,
                    child: w.Text('Fixed 20w', style: onPrimary),
                  ),
                ),
              ),
              w.Divider(width: 60),

              // -- SizedOverflowBox --
              w.Text('SizedOverflowBox (size: 25x3)', style: theme.titleMedium),
              w.Text(
                'The box itself is 25x3, but the child may be larger:',
                style: label,
              ),
              w.Container(
                color: theme.surface,
                child: w.SizedOverflowBox(
                  requestedSize: w.Size(25, 3),
                  child: w.Container(
                    width: 40,
                    height: 2,
                    color: theme.primary,
                    alignment: w.Alignment.centerLeft,
                    padding: const w.EdgeInsets.symmetric(horizontal: 1),
                    child: w.Text(
                      'Child is wider than the SizedOverflowBox',
                      style: onPrimary,
                    ),
                  ),
                ),
              ),
              w.Divider(width: 60),

              // -- Side by side comparison --
              w.Text('Side-by-side Comparison', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Column(
                    children: [
                      w.Text('OverflowBox', style: onSurface),
                      w.Container(
                        width: 20,
                        height: 3,
                        color: theme.surface,
                        child: w.OverflowBox(
                          maxWidth: 30,
                          child: w.Text(
                            'Overrides constraints',
                            style: onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  w.Column(
                    children: [
                      w.Text('SizedOverflowBox', style: onSurface),
                      w.SizedOverflowBox(
                        requestedSize: w.Size(20, 3),
                        child: w.Container(
                          color: theme.surface,
                          child: w.Text(
                            'Passes parent constraints',
                            style: onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
