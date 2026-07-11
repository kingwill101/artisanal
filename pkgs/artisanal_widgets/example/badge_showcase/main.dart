// Badge Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates the Badge widget with per-side padding, width calculation,
// and various color configurations.
//
// Run with: dart run example/badge_showcase/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(BadgeShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class BadgeShowcase extends w.StatefulWidget {
  BadgeShowcase({super.key});

  @override
  w.State createState() => _BadgeShowcaseState();
}

class _BadgeShowcaseState extends w.State<BadgeShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final dim = theme.bodySmall.copy()..foreground(theme.muted);

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
              w.Text('Badge Showcase', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(),

              // ── Color Variants ──
              w.Text('Color Variants', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Badge('OK'),
                  w.Badge('INFO', background: Colors.blue),
                  w.Badge(
                    'WARN',
                    background: Colors.yellow,
                    foreground: Colors.black,
                  ),
                  w.Badge('ERROR', background: Colors.red),
                  w.Badge(
                    'SUCCESS',
                    background: Colors.green,
                    foreground: Colors.black,
                  ),
                  w.Badge(
                    'MUTED',
                    background: Colors.gray,
                    foreground: Colors.white,
                  ),
                ],
              ),
              w.Divider(),

              // ── Default Padding ──
              w.Text(
                'Default Padding (horizontal: 1)',
                style: theme.titleMedium,
              ),
              w.Row(
                gap: 2,
                children: [
                  w.Badge('A'),
                  w.Badge('AB'),
                  w.Badge('ABC'),
                  w.Badge('longer label'),
                ],
              ),
              w.Row(
                gap: 2,
                children: [
                  w.Text('widths: ', style: dim),
                  w.Text('${w.Badge("A").width} ', style: label),
                  w.Text('${w.Badge("AB").width} ', style: label),
                  w.Text('${w.Badge("ABC").width} ', style: label),
                  w.Text('${w.Badge("longer label").width}', style: label),
                ],
              ),
              w.Divider(),

              // ── Per-Side Padding ──
              w.Text('Per-Side Padding', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Badge('TIGHT', paddingLeft: 0, paddingRight: 0),
                  w.Badge('LEFT3', paddingLeft: 3, paddingRight: 1),
                  w.Badge('RIGHT3', paddingLeft: 1, paddingRight: 3),
                  w.Badge('EVEN4', paddingLeft: 4, paddingRight: 4),
                ],
              ),
              w.Row(
                gap: 2,
                children: [
                  w.Text('widths: ', style: dim),
                  w.Text(
                    '${w.Badge("TIGHT", paddingLeft: 0, paddingRight: 0).width} ',
                    style: label,
                  ),
                  w.Text(
                    '${w.Badge("LEFT3", paddingLeft: 3, paddingRight: 1).width} ',
                    style: label,
                  ),
                  w.Text(
                    '${w.Badge("RIGHT3", paddingLeft: 1, paddingRight: 3).width} ',
                    style: label,
                  ),
                  w.Text(
                    '${w.Badge("EVEN4", paddingLeft: 4, paddingRight: 4).width}',
                    style: label,
                  ),
                ],
              ),
              w.Divider(),

              // ── EdgeInsets Padding ──
              w.Text(
                'EdgeInsets Padding (symmetric)',
                style: theme.titleMedium,
              ),
              w.Row(
                gap: 2,
                children: [
                  w.Badge('ZERO', padding: w.EdgeInsets.zero),
                  w.Badge(
                    'H:2',
                    padding: const w.EdgeInsets.symmetric(horizontal: 2),
                  ),
                  w.Badge(
                    'H:4',
                    padding: const w.EdgeInsets.symmetric(horizontal: 4),
                  ),
                ],
              ),
              w.Divider(),

              // ── Empty Label ──
              w.Text('Empty Label', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Badge(''),
                  w.Badge('', background: Colors.red),
                  w.Badge(
                    '',
                    paddingLeft: 3,
                    paddingRight: 3,
                    background: Colors.green,
                  ),
                ],
              ),
              w.Row(
                gap: 2,
                children: [
                  w.Text('widths: ', style: dim),
                  w.Text('${w.Badge("").width} ', style: label),
                  w.Text('${w.Badge("").width} ', style: label),
                  w.Text(
                    '${w.Badge("", paddingLeft: 3, paddingRight: 3).width}',
                    style: label,
                  ),
                ],
              ),
              w.Divider(),

              // ── Inline Usage ──
              w.Text('Inline Usage (in rows)', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.Text('Status:', style: label),
                  w.Badge(
                    'Active',
                    background: Colors.green,
                    foreground: Colors.black,
                  ),
                ],
              ),
              w.Row(
                gap: 1,
                children: [
                  w.Text('Build:', style: label),
                  w.Badge('FAILED', background: Colors.red),
                  w.Text('3 errors', style: dim),
                ],
              ),
              w.Row(
                gap: 1,
                children: [
                  w.Text('Version:', style: label),
                  w.Badge('v2.1.0', background: Colors.blue),
                  w.Badge(
                    'latest',
                    background: Colors.green,
                    foreground: Colors.black,
                  ),
                ],
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
    return null;
  }
}
