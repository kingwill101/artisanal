// FadeModalBarrier Example
//
// Demonstrates the FadeModalBarrier widget that overlays a semi-transparent
// barrier over content. Press 'm' to toggle visibility, 'd' to toggle
// dismissible mode.
//
// Run with: dart run example/fade_modal_barrier/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(FadeModalBarrierDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class FadeModalBarrierDemo extends w.StatefulWidget {
  FadeModalBarrierDemo({super.key});

  @override
  w.State createState() => _FadeModalBarrierDemoState();
}

class _FadeModalBarrierDemoState extends w.State<FadeModalBarrierDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _visible = false;
  bool _dismissible = true;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'm') {
        setState(() => _visible = !_visible);
      }
      if (msg.key.char == 'd') {
        setState(() => _dismissible = !_dismissible);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = Style()..foreground(theme.onSurface);

    final content = w.Container(
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
            crossAxisAlignment: w.CrossAxisAlignment.start,
            children: [
              w.Text('FadeModalBarrier Demo', style: theme.titleLarge),
              w.Text(
                'm = toggle barrier | d = toggle dismissible | q = quit',
                style: label,
              ),
              w.Text(
                'Visible: ${_visible ? "ON" : "OFF"} | '
                'Dismissible: ${_dismissible ? "ON" : "OFF"}',
                style: label,
              ),
              w.Divider(width: 60),
              w.Text('Background Content:', style: theme.titleMedium),
              w.Container(
                width: 50,
                height: 5,
                color: theme.surface,
                padding: const w.EdgeInsets.all(1),
                child: w.Column(
                  children: [
                    w.Text(
                      'This content sits behind the barrier.',
                      style: onSurface,
                    ),
                    w.Text(
                      'Press m to show/hide the barrier.',
                      style: onSurface,
                    ),
                    w.Text(
                      'When visible, the barrier covers this.',
                      style: onSurface,
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),
              w.Text(
                'The FadeModalBarrier animates its opacity\n'
                'when toggled. It can optionally be dismissed\n'
                'by tapping (when dismissible is enabled).',
                style: label,
              ),
            ],
          ),
        ),
      ),
    );

    return w.FadeModalBarrier(
      visible: _visible,
      color: Colors.black,
      opacity: 0.6,
      duration: const Duration(milliseconds: 300),
      dismissible: _dismissible,
      onDismiss: () {
        setState(() => _visible = false);
        return null;
      },
      child: content,
    );
  }
}
