// ProgressIndicator & SpinnerIndicator Showcase
//
// Demonstrates ProgressIndicator with value, custom chars, labels,
// colors, and SpinnerIndicator with different frame sets.
//
// Run with: dart run example/progress_spinner/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ProgressSpinnerShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ProgressSpinnerShowcase extends w.StatefulWidget {
  ProgressSpinnerShowcase({super.key});

  @override
  w.State createState() => _ProgressSpinnerShowcaseState();
}

class _ProgressSpinnerShowcaseState extends w.State<ProgressSpinnerShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  double _progress = 0.35;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

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
              w.Text('Progress & Spinner Showcase', style: theme.titleLarge),
              w.Text('+/-: change progress, q: quit', style: label),
              w.Divider(width: 50),

              // -- ProgressIndicator: default --
              w.Text('ProgressIndicator (default)', style: theme.titleMedium),
              w.ProgressIndicator(value: _progress),

              // -- With label --
              w.Text('With label', style: theme.titleMedium),
              w.ProgressIndicator(value: _progress, showLabel: true),

              // -- Custom width and chars --
              w.Text('Custom (width: 30, chars)', style: theme.titleMedium),
              w.ProgressIndicator(
                value: _progress,
                width: 30,
                fillChar: '=',
                trackChar: '.',
                showLabel: true,
              ),

              // -- With custom colors --
              w.Text('Custom colors', style: theme.titleMedium),
              w.ProgressIndicator(
                value: _progress,
                color: theme.success,
                trackColor: theme.muted,
                showLabel: true,
              ),

              // -- Different progress values --
              w.Text('Fixed values: 0%, 50%, 100%', style: theme.titleMedium),
              w.ProgressIndicator(value: 0, showLabel: true, width: 30),
              w.ProgressIndicator(value: 0.5, showLabel: true, width: 30),
              w.ProgressIndicator(value: 1.0, showLabel: true, width: 30),
              w.Divider(width: 50),

              // -- SpinnerIndicator --
              w.Text('SpinnerIndicator', style: theme.titleMedium),
              w.Row(
                gap: 3,
                children: [
                  w.Row(
                    gap: 1,
                    children: [
                      w.SpinnerIndicator(
                        key: const w.Key('spinner-default'),
                        color: theme.primary,
                      ),
                      w.Text('Default', style: label),
                    ],
                  ),
                  w.Row(
                    gap: 1,
                    children: [
                      w.SpinnerIndicator(
                        key: const w.Key('spinner-dots'),
                        frames: const [
                          '⠋',
                          '⠙',
                          '⠹',
                          '⠸',
                          '⠼',
                          '⠴',
                          '⠦',
                          '⠧',
                          '⠇',
                          '⠏',
                        ],
                        color: theme.success,
                      ),
                      w.Text('Dots', style: label),
                    ],
                  ),
                  w.Row(
                    gap: 1,
                    children: [
                      w.SpinnerIndicator(
                        key: const w.Key('spinner-blocks'),
                        frames: const ['▖', '▘', '▝', '▗'],
                        color: theme.warning,
                      ),
                      w.Text('Blocks', style: label),
                    ],
                  ),
                ],
              ),
              w.Divider(width: 50),

              w.Text('Progress: ${(_progress * 100).round()}%', style: label),
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
      if (key.char == '+' || key.char == '=') {
        setState(() {
          _progress = (_progress + 0.05).clamp(0.0, 1.0);
        });
      }
      if (key.char == '-') {
        setState(() {
          _progress = (_progress - 0.05).clamp(0.0, 1.0);
        });
      }
    }
    return null;
  }
}
