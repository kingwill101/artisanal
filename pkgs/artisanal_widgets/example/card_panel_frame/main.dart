// Card, PanelBox, Frame, AlertBox & Toast Showcase
//
// Demonstrates container-style component widgets: Card, PanelBox
// (with title and actions), Frame, AlertBox (info/success/warning/error),
// and Toast.
//
// Run with: dart run example/card_panel_frame/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(CardPanelShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class CardPanelShowcase extends w.StatefulWidget {
  CardPanelShowcase({super.key});

  @override
  w.State createState() => _CardPanelShowcaseState();
}

class _CardPanelShowcaseState extends w.State<CardPanelShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

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
              w.Text(
                'Card, Panel, Frame, Alert & Toast',
                style: theme.titleLarge,
              ),
              w.Text('Press q to quit.', style: label),
              w.Divider(width: 60),

              // -- Card --
              w.Text('Card', style: theme.titleMedium),
              w.Card(
                padding: const w.EdgeInsets.all(1),
                child: w.Column(
                  gap: 1,
                  children: [
                    w.Text('Card Title', style: theme.titleSmall),
                    w.Text(
                      'Cards provide a bordered container for grouping content.',
                      style: theme.bodySmall,
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- PanelBox --
              w.Text('PanelBox (with title)', style: theme.titleMedium),
              w.PanelBox(
                title: 'System Status',
                child: w.Column(
                  gap: 0,
                  children: [
                    w.Text('CPU: 42%', style: theme.bodySmall),
                    w.Text('Memory: 67%', style: theme.bodySmall),
                    w.Text('Disk: 23%', style: theme.bodySmall),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- Frame --
              w.Text('Frame', style: theme.titleMedium),
              w.Frame(
                padding: const w.EdgeInsets.all(1),
                background: theme.surface,
                child: w.Text('Frame with background', style: theme.bodyMedium),
              ),
              w.Divider(width: 60),

              // -- AlertBox variants --
              w.Text('AlertBox Variants', style: theme.titleMedium),
              w.Column(
                gap: 1,
                children: [
                  w.AlertBox(
                    title: 'Info',
                    message: 'This is an informational alert.',
                    variant: w.AlertVariant.info,
                  ),
                  w.AlertBox(
                    title: 'Success',
                    message: 'Operation completed successfully.',
                    variant: w.AlertVariant.success,
                  ),
                  w.AlertBox(
                    title: 'Warning',
                    message: 'Disk space is running low.',
                    variant: w.AlertVariant.warning,
                  ),
                  w.AlertBox(
                    title: 'Error',
                    message: 'Connection failed. Retrying...',
                    variant: w.AlertVariant.error,
                  ),
                ],
              ),
              w.Divider(width: 60),

              // -- Toast --
              w.Text('Toast', style: theme.titleMedium),
              w.Toast(
                title: 'Saved',
                message: 'Your changes have been saved.',
                variant: w.AlertVariant.success,
              ),
            ],
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
