// Container & Alignment Showcase
//
// Demonstrates Container, Align, Center, Padding, SizedBox,
// ConstrainedBox, and ShrinkWrap widgets.
//
// Run with: dart run example/container_align/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ContainerAlignShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ContainerAlignShowcase extends w.StatefulWidget {
  ContainerAlignShowcase({super.key});

  @override
  w.State createState() => _ContainerAlignShowcaseState();
}

class _ContainerAlignShowcaseState extends w.State<ContainerAlignShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onPrimary = theme.labelSmall.copy()..foreground(theme.onPrimary);
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
              w.Text('Container & Alignment Showcase', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(width: 60),

              // -- Container with color, padding, alignment --
              w.Text(
                'Container: color, padding, alignment',
                style: theme.titleMedium,
              ),
              w.Row(
                gap: 2,
                children: [
                  w.Container(
                    width: 16,
                    height: 5,
                    color: theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text('Centered', style: onSurface),
                  ),
                  w.Container(
                    width: 16,
                    height: 5,
                    color: theme.surface,
                    alignment: w.Alignment.bottomRight,
                    child: w.Text('BR', style: onSurface),
                  ),
                  w.Container(
                    width: 16,
                    height: 5,
                    color: theme.surface,
                    alignment: w.Alignment.topLeft,
                    child: w.Text('TL', style: onSurface),
                  ),
                ],
              ),
              w.Divider(width: 60),

              // -- Container with padding and margin --
              w.Text('Container: padding + margin', style: theme.titleMedium),
              w.Container(
                color: theme.surface,
                child: w.Container(
                  margin: const w.EdgeInsets.all(1),
                  padding: const w.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  color: theme.primary,
                  child: w.Text('Padded + Margin', style: onPrimary),
                ),
              ),
              w.Divider(width: 60),

              // -- Align widget --
              w.Text('Align inside Container', style: theme.titleMedium),
              w.Container(
                width: 30,
                height: 5,
                color: theme.surface,
                child: w.Align(
                  alignment: w.Alignment.centerRight,
                  child: w.Text('Right', style: onSurface),
                ),
              ),
              w.Divider(width: 60),

              // -- Center widget --
              w.Text('Center widget', style: theme.titleMedium),
              w.Container(
                width: 30,
                height: 3,
                color: theme.surface,
                child: w.Center(child: w.Text('Centered!', style: onSurface)),
              ),
              w.Divider(width: 60),

              // -- Padding widget --
              w.Text('Padding widget', style: theme.titleMedium),
              w.Container(
                color: theme.surface,
                child: w.Padding(
                  padding: const w.EdgeInsets.all(2),
                  child: w.Text('2-cell padding all around', style: onSurface),
                ),
              ),
              w.Divider(width: 60),

              // -- SizedBox --
              w.Text('SizedBox variants', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.SizedBox(
                    width: 12,
                    height: 3,
                    child: w.Container(
                      color: theme.primary,
                      alignment: w.Alignment.center,
                      child: w.Text('12x3', style: onPrimary),
                    ),
                  ),
                  w.SizedBox.square(
                    dimension: 4,
                    child: w.Container(
                      color: theme.secondary,
                      alignment: w.Alignment.center,
                      child: w.Text('4x4', style: onPrimary),
                    ),
                  ),
                  w.SizedBox.shrink(child: w.Text('Shrink', style: label)),
                ],
              ),
              w.Divider(width: 60),

              // -- ConstrainedBox --
              w.Text('ConstrainedBox (min 24x3)', style: theme.titleMedium),
              w.ConstrainedBox(
                constraints: w.BoxConstraints(minWidth: 24, minHeight: 3),
                child: w.Container(
                  color: theme.surface,
                  alignment: w.Alignment.centerLeft,
                  padding: const w.EdgeInsets.symmetric(horizontal: 1),
                  child: w.Text('Min size enforced', style: onSurface),
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
