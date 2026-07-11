//
import 'package:artisanal_widgets/artisanal_widgets.dart';
// Run with: dart run example/layout/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(LayoutShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class LayoutShowcase extends w.StatefulWidget {
  LayoutShowcase({super.key});

  @override
  w.State createState() => _LayoutShowcaseState();
}

class _LayoutShowcaseState extends w.State<LayoutShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final label = widget.theme.labelSmall.copy()
      ..foreground(widget.theme.onBackground);
    final onSurface = widget.theme.labelSmall.copy()
      ..foreground(widget.theme.onSurface);
    final onPrimary = widget.theme.labelSmall.copy()
      ..foreground(widget.theme.onPrimary);
    final onSecondary = widget.theme.labelSmall.copy()
      ..foreground(widget.theme.onSecondary);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: widget.theme.background,
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
                w.Text('Layout Primitives', style: widget.theme.titleLarge),
                w.Text('Padding', style: label),
                w.Container(
                  width: 26,
                  height: 5,
                  color: widget.theme.surface,
                  child: w.Padding(
                    padding: const w.EdgeInsets.all(1),
                    child: w.Container(
                      color: widget.theme.primary,
                      alignment: w.Alignment.center,
                      child: w.Text('Inner', style: onPrimary),
                    ),
                  ),
                ),
                w.Text('Align / Center', style: label),
                w.Container(
                  width: 26,
                  height: 5,
                  color: widget.theme.surface,
                  child: w.Align(
                    alignment: w.Alignment.bottomRight,
                    child: w.Container(
                      width: 4,
                      height: 1,
                      color: widget.theme.secondary,
                      alignment: w.Alignment.center,
                      child: w.Text('BR', style: onSecondary),
                    ),
                  ),
                ),
                w.Container(
                  width: 26,
                  height: 5,
                  color: widget.theme.surface,
                  child: w.Center(
                    child: w.Container(
                      width: 8,
                      height: 1,
                      color: widget.theme.warning,
                      alignment: w.Alignment.center,
                      child: w.Text('Center', style: onSurface),
                    ),
                  ),
                ),
                w.Text('SizedBox', style: label),
                w.Row(
                  gap: 2,
                  children: [
                    w.SizedBox(
                      width: 8,
                      height: 3,
                      child: w.Container(
                        color: widget.theme.primary,
                        alignment: w.Alignment.center,
                        child: w.Text('8x3', style: onPrimary),
                      ),
                    ),
                    w.SizedBox.square(
                      dimension: 4,
                      child: w.Container(
                        color: widget.theme.secondary,
                        alignment: w.Alignment.center,
                        child: w.Text('4', style: onSecondary),
                      ),
                    ),
                    w.SizedBox.shrink(child: w.Text('Shrink', style: label)),
                  ],
                ),
                w.Text('ConstrainedBox', style: label),
                w.ConstrainedBox(
                  constraints: w.BoxConstraints(minWidth: 20, minHeight: 3),
                  child: w.Container(
                    color: widget.theme.surface,
                    alignment: w.Alignment.centerLeft,
                    padding: const w.EdgeInsets.symmetric(horizontal: 1),
                    child: w.Text('Min 20x3', style: onSurface),
                  ),
                ),
                w.Text('Press q to quit', style: label),
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
