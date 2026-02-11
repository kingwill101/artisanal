// AnimatedTint & FadeTint Example
//
// Demonstrates AnimatedTint (animates between two colors) and FadeTint
// (fades a single color in/out). Press 'a' to restart AnimatedTint,
// 'f' to toggle FadeTint fade direction.
//
// Run with: dart run example/animated_tint/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(AnimatedTintDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class AnimatedTintDemo extends w.StatefulWidget {
  AnimatedTintDemo({super.key});

  @override
  w.State createState() => _AnimatedTintDemoState();
}

class _AnimatedTintDemoState extends w.State<AnimatedTintDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _animColorIndex = 0;
  bool _fadeIn = true;
  int _fadeKey = 0;
  int _animKey = 0;

  static final _colorPairs = [
    (Colors.red, Colors.blue, 'Red -> Blue'),
    (Colors.green, Colors.yellow, 'Green -> Yellow'),
    (Colors.cyan, Colors.magenta, 'Cyan -> Magenta'),
    (Colors.blue, Colors.green, 'Blue -> Green'),
  ];

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'a') {
        setState(() {
          _animColorIndex = (_animColorIndex + 1) % _colorPairs.length;
          _animKey++;
        });
      }
      if (msg.key.char == 'f') {
        setState(() {
          _fadeIn = !_fadeIn;
          _fadeKey++;
        });
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = Style()..foreground(theme.onSurface);

    final pair = _colorPairs[_animColorIndex];

    return w.Container(
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
          child: w.Container(
            padding: const w.EdgeInsets.all(1),
            color: theme.background,
            child: w.Column(
              gap: 1,
              children: [
                w.Text('AnimatedTint & FadeTint Demo', style: theme.titleLarge),
                w.Text(
                  'a = cycle AnimatedTint colors | f = toggle FadeTint | q = quit',
                  style: label,
                ),
                w.Divider(width: 65),

                // AnimatedTint section
                w.Text('AnimatedTint (${pair.$3}):', style: theme.titleMedium),
                w.AnimatedTint(
                  key: w.ValueKey('anim-$_animKey'),
                  begin: pair.$1,
                  end: pair.$2,
                  duration: const Duration(milliseconds: 1500),
                  child: w.Container(
                    width: 50,
                    height: 3,
                    color: theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text(
                      'Animated color transition',
                      style: onSurface,
                    ),
                  ),
                ),
                w.Divider(width: 65),

                // FadeTint section
                w.Text(
                  'FadeTint (${_fadeIn ? "Fade In" : "Fade Out"}):',
                  style: theme.titleMedium,
                ),
                w.FadeTint(
                  key: w.ValueKey('fade-$_fadeKey'),
                  color: Colors.blue,
                  duration: const Duration(milliseconds: 1000),
                  fadeIn: _fadeIn,
                  child: w.Container(
                    width: 50,
                    height: 3,
                    color: theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text('Blue fade tint overlay', style: onSurface),
                  ),
                ),
                w.Divider(width: 65),

                // Info
                w.Text(
                  'AnimatedTint interpolates between two colors over time.\n'
                  'FadeTint fades a single color opacity from 0 to 1 (or reverse).',
                  style: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
