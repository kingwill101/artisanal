// Gesture & Mouse Showcase
//
// Demonstrates GestureDetector (tap, drag, wheel), MouseRegion
// (hover enter/exit), and Zone widgets with interactive feedback.
//
// Run with: dart run example/gesture/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(GestureShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class GestureShowcase extends w.StatefulWidget {
  GestureShowcase({super.key});

  @override
  w.State createState() => _GestureShowcaseState();
}

class _GestureShowcaseState extends w.State<GestureShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _tapCount = 0;
  String _lastEvent = 'None';
  bool _hovered = false;
  int _wheelDelta = 0;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onPrimary = theme.labelSmall.copy()..foreground(theme.onPrimary);

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
                w.Text('Gesture & Mouse Showcase', style: theme.titleLarge),
                w.Text(
                  'Click, hover, and scroll on the boxes. q to quit.',
                  style: label,
                ),
                w.Divider(width: 60),

                // -- GestureDetector: tap --
                w.Text('GestureDetector: onTap', style: theme.titleMedium),
                w.GestureDetector(
                  onTap: () {
                    setState(() {
                      _tapCount++;
                      _lastEvent = 'tap';
                    });
                    return null;
                  },
                  onTapDown: (_) {
                    setState(() => _lastEvent = 'tapDown');
                    return null;
                  },
                  onTapUp: (_) {
                    setState(() => _lastEvent = 'tapUp');
                    return null;
                  },
                  child: w.Container(
                    width: 30,
                    height: 3,
                    color: theme.primary,
                    alignment: w.Alignment.center,
                    child: w.Text(
                      'Click me! (${_tapCount}x)',
                      style: onPrimary,
                    ),
                  ),
                ),
                w.Text('Last event: $_lastEvent', style: label),
                w.Divider(width: 60),

                // -- GestureDetector: drag --
                w.Text(
                  'GestureDetector: drag events',
                  style: theme.titleMedium,
                ),
                w.GestureDetector(
                  onDragStart: (d) {
                    setState(() => _lastEvent = 'dragStart');
                    return null;
                  },
                  onDragUpdate: (d) {
                    setState(() => _lastEvent = 'dragUpdate');
                    return null;
                  },
                  onDragEnd: (d) {
                    setState(() => _lastEvent = 'dragEnd');
                    return null;
                  },
                  child: w.Container(
                    width: 30,
                    height: 3,
                    color: theme.secondary,
                    alignment: w.Alignment.center,
                    child: w.Text(
                      'Drag me!',
                      style: Style().foreground(theme.onSecondary),
                    ),
                  ),
                ),
                w.Divider(width: 60),

                // -- GestureDetector: wheel --
                w.Text('GestureDetector: onWheel', style: theme.titleMedium),
                w.GestureDetector(
                  onWheel: (_) {
                    setState(() {
                      _wheelDelta++;
                      _lastEvent = 'wheel';
                    });
                    return null;
                  },
                  child: w.Container(
                    width: 30,
                    height: 3,
                    color: theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text(
                      'Scroll here! (${_wheelDelta}x)',
                      style: Style().foreground(theme.onSurface),
                    ),
                  ),
                ),
                w.Divider(width: 60),

                // -- MouseRegion: hover --
                w.Text(
                  'MouseRegion: hover enter/exit',
                  style: theme.titleMedium,
                ),
                w.MouseRegion(
                  onEnter: (_) {
                    setState(() => _hovered = true);
                    return null;
                  },
                  onExit: (_) {
                    setState(() => _hovered = false);
                    return null;
                  },
                  child: w.Container(
                    width: 30,
                    height: 3,
                    color: _hovered ? theme.primary : theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text(
                      _hovered ? 'Hovered!' : 'Hover me',
                      style: _hovered
                          ? onPrimary
                          : (Style()..foreground(theme.onSurface)),
                    ),
                  ),
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
