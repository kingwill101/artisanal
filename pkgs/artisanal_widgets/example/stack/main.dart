// Stack & Overlay Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates Stack, Positioned, Visibility, and Opacity widgets.
//
// Run with: dart run example/stack/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(StackShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class StackShowcase extends w.StatefulWidget {
  StackShowcase({super.key});

  @override
  w.State createState() => _StackShowcaseState();
}

class _StackShowcaseState extends w.State<StackShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _visible = true;
  double _opacity = 1.0;

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
              w.Text('Stack & Overlay Showcase', style: theme.titleLarge),
              w.Text(
                'v: toggle visibility, o: cycle opacity, q: quit',
                style: label,
              ),
              w.Divider(width: 50),

              // -- Stack with Positioned children --
              w.Text(
                'Stack with Positioned overlays',
                style: theme.titleMedium,
              ),
              w.Stack(
                width: 40,
                height: 8,
                children: [
                  // Base layer
                  w.Container(
                    width: 40,
                    height: 8,
                    color: theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text('Base Layer', style: onSurface),
                  ),
                  // Top-right badge
                  w.Positioned(
                    right: 1,
                    top: 0,
                    child: w.Container(
                      color: theme.error,
                      padding: const w.EdgeInsets.symmetric(horizontal: 1),
                      child: w.Text(
                        'Badge',
                        style: Style().foreground(theme.onPrimary),
                      ),
                    ),
                  ),
                  // Bottom-left status
                  w.Positioned(
                    left: 1,
                    bottom: 0,
                    child: w.Text(
                      'Status: OK',
                      style: Style().foreground(theme.success),
                    ),
                  ),
                  // Centered overlay
                  w.Positioned(
                    left: 15,
                    top: 3,
                    child: w.Container(
                      color: theme.primary,
                      padding: const w.EdgeInsets.symmetric(horizontal: 1),
                      child: w.Text('Overlay', style: onPrimary),
                    ),
                  ),
                ],
              ),
              w.Divider(width: 50),

              // -- Visibility toggle --
              w.Text(
                'Visibility (visible: $_visible)',
                style: theme.titleMedium,
              ),
              w.Visibility(
                visible: _visible,
                replacement: w.Text('[ Hidden ]', style: label),
                child: w.Container(
                  width: 30,
                  height: 3,
                  color: theme.primary,
                  alignment: w.Alignment.center,
                  child: w.Text('I am visible!', style: onPrimary),
                ),
              ),
              w.Divider(width: 50),

              // -- Opacity --
              w.Text(
                'Opacity (${_opacity.toStringAsFixed(1)})',
                style: theme.titleMedium,
              ),
              w.Opacity(
                opacity: _opacity,
                child: w.Container(
                  width: 30,
                  height: 3,
                  color: theme.secondary,
                  alignment: w.Alignment.center,
                  child: w.Text(
                    'Fading content',
                    style: Style().foreground(theme.onSecondary),
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
      if (key.char == 'v') {
        setState(() => _visible = !_visible);
      }
      if (key.char == 'o') {
        setState(() {
          _opacity -= 0.2;
          if (_opacity < 0) _opacity = 1.0;
        });
      }
    }
    return null;
  }
}
