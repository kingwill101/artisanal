// AsciiText & AsciiFont Example
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates AsciiText, StyledAsciiText, and the four built-in AsciiFont
// styles. Press 'f' to cycle fonts, 's' to toggle styled mode.
//
// Run with: dart run example/ascii_text/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(AsciiTextDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class AsciiTextDemo extends w.StatefulWidget {
  AsciiTextDemo({super.key});

  @override
  w.State createState() => _AsciiTextDemoState();
}

class _AsciiTextDemoState extends w.State<AsciiTextDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _fontIndex = 0;
  bool _styled = false;

  static final _fonts = [
    (w.AsciiFont.standard, 'Standard (5 lines)'),
    (w.AsciiFont.banner, 'Banner (7 lines)'),
    (w.AsciiFont.block, 'Block (6 lines)'),
    (w.AsciiFont.slim, 'Slim (5 lines)'),
  ];

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'f') {
        setState(() {
          _fontIndex = (_fontIndex + 1) % _fonts.length;
        });
      }
      if (msg.key.char == 's') {
        setState(() => _styled = !_styled);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    final currentFont = _fonts[_fontIndex].$1;
    final fontName = _fonts[_fontIndex].$2;

    final cyanStyle = Style()
      ..foreground(Colors.cyan)
      ..bold(true);

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
              crossAxisAlignment: w.CrossAxisAlignment.start,
              children: [
                w.Text('AsciiText & AsciiFont Demo', style: theme.titleLarge),
                w.Text(
                  'f = cycle font | s = toggle styled | q = quit',
                  style: label,
                ),
                w.Text(
                  'Font: $fontName | Styled: ${_styled ? "ON" : "OFF"}',
                  style: label,
                ),
                w.Divider(width: 70),

                // Main showcase
                if (_styled)
                  w.StyledAsciiText(
                    data: 'HI',
                    font: currentFont,
                    style: cyanStyle,
                  )
                else
                  w.AsciiText(data: 'HI', font: currentFont),
                w.Divider(width: 70),

                // Smaller sample with word
                w.Text('Word rendering:', style: theme.titleMedium),
                if (_styled)
                  w.StyledAsciiText(
                    data: 'OK',
                    font: currentFont,
                    style: Style()..foreground(Colors.green),
                  )
                else
                  w.AsciiText(data: 'OK', font: currentFont),
                w.Divider(width: 70),

                // Numbers sample
                w.Text('Numbers:', style: theme.titleMedium),
                if (_styled)
                  w.StyledAsciiText(
                    data: '42',
                    font: currentFont,
                    style: Style()..foreground(Colors.yellow),
                  )
                else
                  w.AsciiText(data: '42', font: currentFont),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
