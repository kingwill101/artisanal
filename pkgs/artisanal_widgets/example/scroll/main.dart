//
// Run with: dart run example/scroll/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ScrollDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
      useUltravioletRenderer: true,
    ),
  );
}

class ScrollDemo extends w.StatefulWidget {
  ScrollDemo({super.key});

  @override
  w.State createState() => _ScrollDemoState();
}

class _ScrollDemoState extends w.State<ScrollDemo> {
  final w.WidgetScrollController _outerScrollController =
      w.WidgetScrollController();
  final w.WidgetScrollController _controller = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final percent = (_controller.scrollPercent * 100).round();
    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: widget.theme.background,
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
          enableSelection: true,
          child: w.Column(
            gap: 1,
            children: [
              w.Text(
                'Scroll + Viewport + ListView',
                style: widget.theme.titleLarge,
              ),
              w.Text(
                'Use j/k, pgup/pgdn, or mouse wheel',
                style: widget.theme.labelSmall,
              ),
              w.Container(
                width: 36,
                height: 12,
                color: widget.theme.surface,
                child: w.Scrollbar(
                  controller: _controller,
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
                  child: w.ListView.builder(
                    controller: _controller,
                    handleKeys: true,
                    itemCount: 60,
                    itemBuilder: (context, index) {
                      final item = index + 1;
                      return w.ListTile(
                        title: 'Item $item',
                        subtitle: item.isEven ? 'Even row with subtitle' : null,
                        leading: w.Text(item.isEven ? '\u2022' : ' '),
                        trailing: w.Text('#$item'),
                        dense: true,
                      );
                    },
                  ),
                ),
              ),
              w.Text('Scroll: $percent%', style: widget.theme.labelSmall),
              w.Text('Press q to quit', style: widget.theme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key)) {
      if (key.char == 'q') return tui.Cmd.quit();
    }
    return null;
  }
}
