// ScrollArea & ScrollView Showcase
//
// Demonstrates ScrollArea (simple scrollable container with optional
// scrollbar), ScrollView, and SingleChildScrollView widgets.
//
// Run with: dart run example/scroll_area/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ScrollAreaShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ScrollAreaShowcase extends w.StatefulWidget {
  ScrollAreaShowcase({super.key});

  @override
  w.State createState() => _ScrollAreaShowcaseState();
}

class _ScrollAreaShowcaseState extends w.State<ScrollAreaShowcase> {
  final w.WidgetScrollController _outerScrollController =
      w.WidgetScrollController();
  final w.WidgetScrollController _scrollCtrl = w.WidgetScrollController();
  final w.WidgetScrollController _singleCtrl = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _outerScrollController,
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
          controller: _outerScrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            children: [
              w.Text(
                'ScrollArea & ScrollView Showcase',
                style: theme.titleLarge,
              ),
              w.Text(
                'Scroll with mouse wheel or j/k. q to quit.',
                style: label,
              ),
              w.Divider(width: 60),

              // -- ScrollArea --
              w.Text(
                'ScrollArea (height: 6, showScrollbar)',
                style: theme.titleMedium,
              ),
              w.ScrollArea(
                height: 6,
                width: 40,
                showScrollbar: true,
                child: w.Column(
                  gap: 0,
                  children: [
                    for (var i = 1; i <= 20; i++)
                      w.Text('ScrollArea item $i', style: theme.bodySmall),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- ScrollView with controller --
              w.Text('ScrollView (with controller)', style: theme.titleMedium),
              w.Container(
                width: 40,
                height: 6,
                color: theme.surface,
                child: w.Scrollbar(
                  controller: _scrollCtrl,
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
                    controller: _scrollCtrl,
                    handleKeys: true,
                    child: w.Column(
                      gap: 0,
                      children: [
                        for (var i = 1; i <= 30; i++)
                          w.Text(
                            'ScrollView line $i — some content here',
                            style: theme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              w.Text(
                'Scroll: ${(_scrollCtrl.scrollPercent * 100).round()}%',
                style: label,
              ),
              w.Divider(width: 60),

              // -- SingleChildScrollView --
              w.Text('SingleChildScrollView', style: theme.titleMedium),
              w.Container(
                width: 40,
                height: 5,
                child: w.Scrollbar(
                  controller: _singleCtrl,
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
                  child: w.SingleChildScrollView(
                    controller: _singleCtrl,
                    padding: const w.EdgeInsets.symmetric(horizontal: 1),
                    child: w.Column(
                      gap: 0,
                      children: [
                        for (var i = 1; i <= 15; i++)
                          w.Text(
                            'Single scroll item $i',
                            style: theme.bodySmall,
                          ),
                      ],
                    ),
                  ),
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
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') return tui.Cmd.quit();
    }
    return null;
  }
}
