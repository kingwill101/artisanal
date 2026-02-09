//
// Run with: dart run example/tui/examples/widgets/scroll/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/widgets.dart' as w;

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
  final w.ViewportController _controller = w.ViewportController();
  late final List<w.Widget> _items = List<w.Widget>.generate(
    60,
    (index) => w.Text('Item ${index + 1}'),
  );

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final percent = (_controller.scrollPercent * 100).round();
    final isDark = w.hasDarkBackground;

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        gap: 1,
        children: [
          w.Text('Scroll + ListView + Scrollbar', style: theme.titleLarge),
          w.Text(
            'Use j/k, pgup/pgdn, mouse wheel, or drag the scrollbar',
            style: theme.labelSmall,
          ),
          w.Container(
            width: 40,
            height: 14,
            color: theme.surface,
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
                start: isDark
                    ? const BasicColor('#2f363d')
                    : const BasicColor('#e3e7eb'),
                end: isDark
                    ? const BasicColor('#1f252a')
                    : const BasicColor('#d3d9e0'),
              ),
              thumbGradient: w.ScrollbarGradient.background(
                start: isDark
                    ? const BasicColor('#3fb2ff')
                    : const BasicColor('#2f7df6'),
                end: isDark
                    ? const BasicColor('#7c5cff')
                    : const BasicColor('#6e55f5'),
              ),
              hoverThumbGradient: w.ScrollbarGradient.background(
                start: isDark
                    ? const BasicColor('#79ddff')
                    : const BasicColor('#4f93ff'),
                end: isDark
                    ? const BasicColor('#b18bff')
                    : const BasicColor('#836bff'),
              ),
              hoverThumbChar: ' ',
              child: w.ListView(
                children: _items,
                handleKeys: false,
                controller: _controller,
              ),
            ),
          ),
          w.Text('Scroll: $percent%', style: theme.labelSmall),
          w.Text('Press q to quit', style: theme.labelSmall),
        ],
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key)) {
      final prev = _controller.model;
      final (next, _) = _controller.update(msg);
      if (!identical(prev, next)) {
        setState(() {});
      }
      if (key.char == 'q') return tui.Cmd.quit();
    }
    return null;
  }
}
