// Row & Column Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates Row, Column, HBox, VBox with gap, mainAxisAlignment,
// crossAxisAlignment, and mainAxisSize options.
//
// Run with: dart run example/row_column/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(RowColumnShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class RowColumnShowcase extends w.StatefulWidget {
  RowColumnShowcase({super.key});

  @override
  w.State createState() => _RowColumnShowcaseState();
}

class _RowColumnShowcaseState extends w.State<RowColumnShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onPrimary = theme.labelSmall.copy()..foreground(theme.onPrimary);
    final onSecondary = theme.labelSmall.copy()..foreground(theme.onSecondary);

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
              w.Text('Row & Column Showcase', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(width: 60),

              // -- Row with gap --
              w.Text('Row (gap: 2)', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  _box('A', 8, 3, theme.primary, onPrimary),
                  _box('B', 12, 3, theme.secondary, onSecondary),
                  _box('C', 8, 3, theme.primary, onPrimary),
                ],
              ),

              // -- Row with mainAxisAlignment --
              w.Text('Row spaceBetween (width: 50)', style: theme.titleMedium),
              w.Row(
                width: 50,
                mainAxisSize: w.MainAxisSize.max,
                mainAxisAlignment: w.MainAxisAlignment.spaceBetween,
                children: [
                  _box('L', 6, 2, theme.primary, onPrimary),
                  _box('M', 6, 2, theme.secondary, onSecondary),
                  _box('R', 6, 2, theme.primary, onPrimary),
                ],
              ),

              // -- Row with crossAxisAlignment --
              w.Text('Row crossAxis: end', style: theme.titleMedium),
              w.Row(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.end,
                children: [
                  _box('Tall', 6, 4, theme.primary, onPrimary),
                  _box('Med', 6, 2, theme.secondary, onSecondary),
                  _box('Sm', 6, 1, theme.primary, onPrimary),
                ],
              ),
              w.Divider(width: 60),

              // -- Column with gap --
              w.Text('Column (gap: 1)', style: theme.titleMedium),
              w.Column(
                gap: 1,
                children: [
                  _box('Row 1', 20, 1, theme.primary, onPrimary),
                  _box('Row 2', 20, 1, theme.secondary, onSecondary),
                  _box('Row 3', 20, 1, theme.primary, onPrimary),
                ],
              ),
              w.Divider(width: 60),

              // -- HBox and VBox --
              w.Text('HBox (gap: 1, default) & VBox', style: theme.titleMedium),
              w.Row(
                gap: 4,
                children: [
                  w.HBox(
                    children: [
                      w.Text('H1', style: label),
                      w.Text('H2', style: label),
                      w.Text('H3', style: label),
                    ],
                  ),
                  w.VBox(
                    children: [
                      w.Text('V1', style: label),
                      w.Text('V2', style: label),
                      w.Text('V3', style: label),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  w.Widget _box(String text, int w2, int h, Color bg, Style style) {
    return w.Container(
      width: w2,
      height: h,
      color: bg,
      alignment: w.Alignment.center,
      child: w.Text(text, style: style),
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
