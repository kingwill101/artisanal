//
// Run with: dart run example/scrollbar/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ScrollbarDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
      useUltravioletRenderer: true,
    ),
  );
}

class ScrollbarDemo extends w.StatefulWidget {
  ScrollbarDemo({super.key});

  @override
  w.State createState() => _ScrollbarDemoState();
}

class _ScrollbarDemoState extends w.State<ScrollbarDemo> {
  final w.WidgetScrollController _controller = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final palette = _scrollbarPalette(w.hasDarkBackground);
    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        gap: 1,
        children: [
          w.Text('Standalone Scrollbar', style: theme.titleLarge),
          w.Text(
            'Wheel, drag thumb, or use pgup/pgdn. Hover to glow. Press q to quit.',
            style: theme.labelSmall,
          ),
          w.Container(
            color: theme.surface,
            child: w.Scrollbar(
              controller: _controller,
              thickness: 1,
              gutterWidth: 2,
              overlay: false,
              gap: 1,
              roundedCaps: false,
              enableHover: true,
              trackChar: ' ',
              thumbChar: ' ',
              trackUsesBackground: true,
              thumbUsesBackground: true,
              trackGradient: w.ScrollbarGradient.background(
                start: palette.trackStart,
                end: palette.trackEnd,
              ),
              thumbGradient: w.ScrollbarGradient.background(
                start: palette.thumbStart,
                end: palette.thumbEnd,
              ),
              hoverTrackGradient: w.ScrollbarGradient.background(
                start: palette.hoverTrackStart,
                end: palette.hoverTrackEnd,
              ),
              hoverThumbGradient: w.ScrollbarGradient.background(
                start: palette.hoverThumbStart,
                end: palette.hoverThumbEnd,
              ),
              hoverThumbChar: ' ',
              child: w.ScrollView(
                controller: _controller,
                handleKeys: true,
                child: w.Column(gap: 1, children: _buildItems(theme)),
              ),
            ),
          ),
          w.Text('Drag the bar for fast scroll.', style: theme.labelSmall),
        ],
      ),
    );
  }

  List<w.Widget> _buildItems(w.Theme theme) {
    return List<w.Widget>.generate(80, (index) {
      final label = 'Signal ${index + 1}'.padRight(12);
      final status = _statusFor(index, theme);
      return w.Row(
        gap: 2,
        children: [
          w.Text('${index + 1}'.padLeft(3, '0'), style: theme.labelSmall),
          w.Text(label, style: theme.bodyMedium),
          w.Text(status.label, style: status.style),
        ],
      );
    });
  }

  _Status _statusFor(int index, w.Theme theme) {
    if (index % 5 == 0) {
      return _Status('WARN', Style().foreground(theme.warning).bold());
    }
    if (index % 7 == 0) {
      return _Status('ERR', Style().foreground(theme.error).bold());
    }
    if (index % 3 == 0) {
      return _Status('OK', Style().foreground(theme.success));
    }
    return _Status('IDLE', Style().foreground(theme.muted));
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key)) {
      if (key.char == 'q') return tui.Cmd.quit();
    }
    return null;
  }
}

_ScrollbarPalette _scrollbarPalette(bool isDark) {
  if (isDark) {
    return const _ScrollbarPalette(
      trackStart: BasicColor('#2f363d'),
      trackEnd: BasicColor('#1f252a'),
      thumbStart: BasicColor('#3fb2ff'),
      thumbEnd: BasicColor('#7c5cff'),
      hoverTrackStart: BasicColor('#3f4850'),
      hoverTrackEnd: BasicColor('#273038'),
      hoverThumbStart: BasicColor('#79ddff'),
      hoverThumbEnd: BasicColor('#b18bff'),
    );
  }
  return const _ScrollbarPalette(
    trackStart: BasicColor('#e3e7eb'),
    trackEnd: BasicColor('#d3d9e0'),
    thumbStart: BasicColor('#2f7df6'),
    thumbEnd: BasicColor('#6e55f5'),
    hoverTrackStart: BasicColor('#d8dee5'),
    hoverTrackEnd: BasicColor('#c7cfd7'),
    hoverThumbStart: BasicColor('#4f93ff'),
    hoverThumbEnd: BasicColor('#836bff'),
  );
}

class _ScrollbarPalette {
  const _ScrollbarPalette({
    required this.trackStart,
    required this.trackEnd,
    required this.thumbStart,
    required this.thumbEnd,
    required this.hoverTrackStart,
    required this.hoverTrackEnd,
    required this.hoverThumbStart,
    required this.hoverThumbEnd,
  });

  final BasicColor trackStart;
  final BasicColor trackEnd;
  final BasicColor thumbStart;
  final BasicColor thumbEnd;
  final BasicColor hoverTrackStart;
  final BasicColor hoverTrackEnd;
  final BasicColor hoverThumbStart;
  final BasicColor hoverThumbEnd;
}

class _Status {
  _Status(this.label, this.style);

  final String label;
  final Style style;
}
