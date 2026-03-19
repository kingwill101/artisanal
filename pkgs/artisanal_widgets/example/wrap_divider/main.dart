// Wrap, Divider, Icon & Spacer Showcase
//
// Demonstrates Wrap with spacing/runSpacing, Divider, Icon with
// built-in Icons constants, Spacer, and ShrinkWrap widgets.
//
// Run with: dart run example/wrap_divider/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(WrapDividerShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class WrapDividerShowcase extends w.StatefulWidget {
  WrapDividerShowcase({super.key});

  @override
  w.State createState() => _WrapDividerShowcaseState();
}

class _WrapDividerShowcaseState extends w.State<WrapDividerShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onPrimary = theme.labelSmall.copy()..foreground(theme.onPrimary);

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
              w.Text('Wrap, Divider, Icon & Spacer', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(width: 60),

              // -- Wrap with chips --
              w.Text(
                'Wrap (spacing: 1, runSpacing: 1)',
                style: theme.titleMedium,
              ),
              w.Wrap(
                spacing: 1,
                runSpacing: 1,
                children: [
                  for (final tag in [
                    'Dart',
                    'Flutter',
                    'Terminal',
                    'TUI',
                    'Widgets',
                    'Layout',
                    'Rendering',
                    'Themes',
                    'Scroll',
                    'Focus',
                  ])
                    w.Container(
                      padding: const w.EdgeInsets.symmetric(horizontal: 1),
                      color: theme.surface,
                      child: w.Text(tag, style: label),
                    ),
                ],
              ),
              w.Divider(width: 60),

              // -- Wrap with alignment --
              w.Text('Wrap (alignment: center)', style: theme.titleMedium),
              w.SizedBox(
                width: 40,
                child: w.Wrap(
                  spacing: 1,
                  runSpacing: 1,
                  alignment: w.WrapAlignment.center,
                  children: [
                    _chip('Alpha', theme),
                    _chip('Beta', theme),
                    _chip('Gamma', theme),
                    _chip('Delta', theme),
                    _chip('Epsilon', theme),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- Icons --
              w.Text('Icons', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Icon(w.Icons.star, color: theme.warning),
                  w.Icon(w.Icons.check, color: theme.success),
                  w.Icon(w.Icons.close, color: theme.error),
                  w.Icon(w.Icons.arrowLeft, color: theme.primary),
                  w.Icon(w.Icons.arrowRight, color: theme.primary),
                  w.Icon(w.Icons.arrowUp, color: theme.secondary),
                  w.Icon(w.Icons.arrowDown, color: theme.secondary),
                  w.Icon(w.Icons.add, color: theme.onBackground),
                  w.Icon(w.Icons.remove, color: theme.onBackground),
                ],
              ),
              w.Divider(width: 60),

              // -- Divider styles --
              w.Text('Divider variants', style: theme.titleMedium),
              w.Divider(width: 40),
              w.Divider(width: 40, char: '='),
              w.Divider(
                width: 40,
                char: '-',
                style: Style().foreground(theme.muted),
              ),
              w.Divider(width: 60),

              // -- Spacer --
              w.Text('Spacer (between items)', style: theme.titleMedium),
              w.Row(
                children: [
                  w.Container(
                    width: 8,
                    height: 2,
                    color: theme.primary,
                    alignment: w.Alignment.center,
                    child: w.Text('A', style: onPrimary),
                  ),
                  w.Spacer(size: 5, fill: '.'),
                  w.Container(
                    width: 8,
                    height: 2,
                    color: theme.secondary,
                    alignment: w.Alignment.center,
                    child: w.Text('B', style: onPrimary),
                  ),
                  w.Spacer(size: 5, fill: '.'),
                  w.Container(
                    width: 8,
                    height: 2,
                    color: theme.primary,
                    alignment: w.Alignment.center,
                    child: w.Text('C', style: onPrimary),
                  ),
                ],
              ),

              // -- ShrinkWrap --
              w.Text('ShrinkWrap', style: theme.titleMedium),
              w.ShrinkWrap(
                child: w.Container(
                  color: theme.surface,
                  padding: const w.EdgeInsets.symmetric(horizontal: 2),
                  child: w.Text('Shrink-wrapped content', style: label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  w.Widget _chip(String text, w.Theme theme) {
    return w.Container(
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      color: theme.surface,
      child: w.Text(
        text,
        style: theme.labelSmall.copy()..foreground(theme.onSurface),
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
