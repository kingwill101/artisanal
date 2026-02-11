// RichText & TextSpan Example
//
// Demonstrates nested styled text spans, text alignment (left/center/right),
// and overflow modes (clip/ellipsis).
//
// Run with: dart run example/rich_text/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(RichTextDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class RichTextDemo extends w.StatefulWidget {
  RichTextDemo({super.key});

  @override
  w.State createState() => _RichTextDemoState();
}

class _RichTextDemoState extends w.State<RichTextDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _alignIndex = 0;
  static const _alignments = [
    w.TextAlign.left,
    w.TextAlign.center,
    w.TextAlign.right,
  ];
  static const _alignNames = ['Left', 'Center', 'Right'];

  int _overflowIndex = 0;
  static const _overflows = [w.TextOverflow.clip, w.TextOverflow.ellipsis];
  static const _overflowNames = ['Clip', 'Ellipsis'];

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'a') {
        setState(() {
          _alignIndex = (_alignIndex + 1) % _alignments.length;
        });
      }
      if (msg.key.char == 'o') {
        setState(() {
          _overflowIndex = (_overflowIndex + 1) % _overflows.length;
        });
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

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
                w.Text('RichText & TextSpan Demo', style: theme.titleLarge),
                w.Text(
                  'a = cycle alignment | o = cycle overflow | q = quit',
                  style: label,
                ),
                w.Divider(width: 60),

                // -- Nested styled spans --
                w.Text('Nested Styled Spans:', style: theme.titleMedium),
                w.RichText(
                  text: w.TextSpan(
                    text: 'Hello ',
                    style: Style()..foreground(theme.onBackground),
                    children: [
                      w.TextSpan(text: 'bold ', style: Style()..bold()),
                      w.TextSpan(
                        text: 'and ',
                        style: Style()..foreground(theme.onBackground),
                      ),
                      w.TextSpan(
                        text: 'colored',
                        style: Style()
                          ..foreground(Colors.cyan)
                          ..underline(),
                      ),
                      w.TextSpan(
                        text: ' world!',
                        style: Style()
                          ..foreground(Colors.green)
                          ..bold(),
                      ),
                    ],
                  ),
                ),
                w.Divider(width: 60),

                // -- Text alignment --
                w.Text(
                  'Alignment: ${_alignNames[_alignIndex]}',
                  style: theme.titleMedium,
                ),
                w.Container(
                  width: 40,
                  height: 3,
                  color: theme.surface,
                  child: w.RichText(
                    textAlign: _alignments[_alignIndex],
                    text: w.TextSpan(
                      text: 'Aligned text',
                      style: Style()..foreground(theme.onSurface),
                    ),
                  ),
                ),
                w.Divider(width: 60),

                // -- Overflow modes --
                w.Text(
                  'Overflow: ${_overflowNames[_overflowIndex]} (maxWidth: 30)',
                  style: theme.titleMedium,
                ),
                w.Container(
                  width: 32,
                  color: theme.surface,
                  child: w.RichText(
                    overflow: _overflows[_overflowIndex],
                    maxWidth: 30,
                    text: w.TextSpan(
                      text:
                          'This is a very long line of text that should overflow',
                      style: Style()..foreground(theme.onSurface),
                    ),
                  ),
                ),
                w.Divider(width: 60),

                // -- Deeply nested spans --
                w.Text('Deeply Nested Spans:', style: theme.titleMedium),
                w.RichText(
                  text: w.TextSpan(
                    text: 'Root ',
                    style: Style()..foreground(Colors.white),
                    children: [
                      w.TextSpan(
                        text: '> Level 1 ',
                        style: Style()..foreground(Colors.yellow),
                        children: [
                          w.TextSpan(
                            text: '> Level 2 ',
                            style: Style()
                              ..foreground(Colors.magenta)
                              ..italic(),
                          ),
                        ],
                      ),
                      w.TextSpan(
                        text: '> Back to 1',
                        style: Style()
                          ..foreground(Colors.cyan)
                          ..dim(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
