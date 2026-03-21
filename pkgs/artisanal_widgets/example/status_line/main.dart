// Badge & StatusLine Showcase
//
// Demonstrates the Badge widget with per-side padding and width calculation,
// and the StatusLine widget with 3-region layout (left/center/right),
// typed StatusItem variants, spacers, and custom separators.
//
// Run with: dart run example/status_line/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(StatusLineShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class StatusLineShowcase extends w.StatefulWidget {
  StatusLineShowcase({super.key});

  @override
  w.State createState() => _StatusLineShowcaseState();
}

class _StatusLineShowcaseState extends w.State<StatusLineShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _frameIndex = 0;
  int _progress = 0;

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
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text('Badge & StatusLine Showcase', style: theme.titleLarge),
              w.Text(
                'Press q to quit. Watch the spinner and progress animate.',
                style: label,
              ),
              w.Divider(),

              // ── Badge Examples ──
              w.Text('Badge Variants', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Badge('OK'),
                  w.Badge(
                    'WARN',
                    background: Colors.yellow,
                    foreground: Colors.black,
                  ),
                  w.Badge('ERROR', background: Colors.red),
                  w.Badge('INFO', background: Colors.blue),
                  w.Badge(
                    'v2.0',
                    background: Colors.green,
                    foreground: Colors.black,
                  ),
                ],
              ),

              w.Text('Badge with Per-Side Padding', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Badge('Tight', paddingLeft: 0, paddingRight: 0),
                  w.Badge('Left-heavy', paddingLeft: 3, paddingRight: 1),
                  w.Badge('Right-heavy', paddingLeft: 1, paddingRight: 3),
                  w.Badge('Padded', paddingLeft: 2, paddingRight: 2),
                ],
              ),

              w.Text('Badge Width Calculation', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Text('w=${w.Badge("OK").width} ', style: label),
                  w.Text(
                    'w=${w.Badge("AB", paddingLeft: 3).width} ',
                    style: label,
                  ),
                  w.Text(
                    'w=${w.Badge("X", padding: w.EdgeInsets.zero).width}',
                    style: label,
                  ),
                ],
              ),

              w.Divider(),

              // ── StatusLine Examples ──
              w.Text('StatusLine — Editor Mode', style: theme.titleMedium),
              w.StatusLine(
                left: [
                  w.StatusItem.text('[INSERT]'),
                  w.StatusItem.text(' '),
                  w.StatusItem.text('main.dart'),
                ],
                center: [w.StatusItem.text('utf-8 · dart')],
                right: [
                  w.StatusItem.keyHint('^S', 'save'),
                  w.StatusItem.text('Ln 42, Col 10'),
                ],
              ),

              w.Text(
                'StatusLine — With Spinner & Progress',
                style: theme.titleMedium,
              ),
              w.StatusLine(
                left: [
                  w.StatusItem.spinner(_frameIndex),
                  w.StatusItem.text(' Building...'),
                ],
                right: [
                  w.StatusItem.progress(_progress, 100),
                  w.StatusItem.text(' '),
                  w.StatusItem.keyHint('^C', 'cancel'),
                ],
              ),

              w.Text('StatusLine — With Spacer', style: theme.titleMedium),
              w.StatusLine(
                left: [w.StatusItem.text('LEFT')],
                right: [w.StatusItem.text('RIGHT')],
                separator: ' │ ',
              ),

              w.Text(
                'StatusLine — Three Regions with Separator',
                style: theme.titleMedium,
              ),
              w.StatusLine(
                left: [
                  w.StatusItem.text('file_a.dart'),
                  w.StatusItem.text('file_b.dart'),
                ],
                center: [w.StatusItem.text('* modified')],
                right: [
                  w.StatusItem.text('2 files'),
                  w.StatusItem.keyHint('^P', 'files'),
                ],
                separator: ' · ',
              ),

              w.Divider(),

              // ── Bottom Status Bars ──
              w.Text('StatusLine — Bottom Key Hints', style: theme.titleMedium),
              w.StatusLine(
                left: [
                  w.StatusItem.keyHint('esc', 'interrupt'),
                  w.StatusItem.keyHint('ctrl+p', 'commands'),
                ],
                right: [w.StatusItem.keyHint('ctrl+q', 'quit')],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();

    // Animate spinner and progress on tick messages
    if (msg is tui.TickMsg) {
      setState(() {
        _frameIndex = (_frameIndex + 1) % 10;
        _progress = (_progress + 1) % 101;
      });
    }
    return null;
  }

  tui.Cmd? init() =>
      tui.every(const Duration(milliseconds: 120), (t) => tui.TickMsg(t));
}
