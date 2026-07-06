// Flex Layout Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates Flexible, Expanded, Flex, and Spacer widgets.
// Shows how flex distribution works in Row and Column.
//
// Run with: dart run example/flex_layout/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(FlexShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class FlexShowcase extends w.StatefulWidget {
  FlexShowcase({super.key});

  @override
  w.State createState() => _FlexShowcaseState();
}

class _FlexShowcaseState extends w.State<FlexShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onPrimary = theme.labelSmall.copy()..foreground(theme.onPrimary);
    final onSecondary = theme.labelSmall.copy()..foreground(theme.onSecondary);

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
              w.Text('Flex Layout Showcase', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(width: 60),

              // -- Expanded in a Row --
              w.Text(
                'Expanded: fills remaining space',
                style: theme.titleMedium,
              ),
              w.SizedBox(
                width: 50,
                child: w.Row(
                  children: [
                    w.Container(
                      width: 10,
                      height: 3,
                      color: theme.primary,
                      alignment: w.Alignment.center,
                      child: w.Text('Fixed', style: onPrimary),
                    ),
                    w.Expanded(
                      child: w.Container(
                        height: 3,
                        color: theme.secondary,
                        alignment: w.Alignment.center,
                        child: w.Text('Expanded', style: onSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- Multiple Expanded with flex ratios --
              w.Text('Expanded flex ratios (1:2:1)', style: theme.titleMedium),
              w.SizedBox(
                width: 50,
                child: w.Row(
                  children: [
                    w.Expanded(
                      flex: 1,
                      child: w.Container(
                        height: 3,
                        color: theme.primary,
                        alignment: w.Alignment.center,
                        child: w.Text('1x', style: onPrimary),
                      ),
                    ),
                    w.Expanded(
                      flex: 2,
                      child: w.Container(
                        height: 3,
                        color: theme.secondary,
                        alignment: w.Alignment.center,
                        child: w.Text('2x', style: onSecondary),
                      ),
                    ),
                    w.Expanded(
                      flex: 1,
                      child: w.Container(
                        height: 3,
                        color: theme.primary,
                        alignment: w.Alignment.center,
                        child: w.Text('1x', style: onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- Flexible (loose fit) vs Expanded (tight fit) --
              w.Text(
                'Flexible (loose) vs Expanded (tight)',
                style: theme.titleMedium,
              ),
              w.Text(
                'Flexible wraps content; Expanded fills space',
                style: label,
              ),
              w.SizedBox(
                width: 50,
                child: w.Row(
                  children: [
                    w.Flexible(
                      child: w.Container(
                        height: 2,
                        color: theme.primary,
                        child: w.Text(' Flex ', style: onPrimary),
                      ),
                    ),
                    w.Expanded(
                      child: w.Container(
                        height: 2,
                        color: theme.secondary,
                        alignment: w.Alignment.center,
                        child: w.Text('Expanded', style: onSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- Spacer --
              w.Text('Spacer: pushes items apart', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.Text('Left', style: label),
                  w.Spacer(size: 10),
                  w.Text('Center', style: label),
                  w.Spacer(size: 10),
                  w.Text('Right', style: label),
                ],
              ),
              w.Divider(width: 60),

              // -- Flex with explicit direction --
              w.Text('Flex(direction: vertical)', style: theme.titleMedium),
              w.Flex(
                direction: w.Axis.vertical,
                gap: 1,
                children: [
                  w.Container(
                    width: 20,
                    height: 1,
                    color: theme.primary,
                    alignment: w.Alignment.center,
                    child: w.Text('Top', style: onPrimary),
                  ),
                  w.Container(
                    width: 20,
                    height: 1,
                    color: theme.secondary,
                    alignment: w.Alignment.center,
                    child: w.Text('Bottom', style: onSecondary),
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
