// Transform Example
//
// Demonstrates the Transform widget with translate, flipHorizontal,
// and flipVertical operations. Press 'h' to toggle horizontal flip,
// 'v' to toggle vertical flip, arrow keys to translate.
//
// Run with: dart run example/transform/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(TransformDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class TransformDemo extends w.StatefulWidget {
  TransformDemo({super.key});

  @override
  w.State createState() => _TransformDemoState();
}

class _TransformDemoState extends w.State<TransformDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _flipH = false;
  bool _flipV = false;
  int _translateX = 0;
  int _translateY = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'h') {
        setState(() => _flipH = !_flipH);
      }
      if (msg.key.char == 'v') {
        setState(() => _flipV = !_flipV);
      }
      if (msg.key.char == 'r') {
        setState(() {
          _flipH = false;
          _flipV = false;
          _translateX = 0;
          _translateY = 0;
        });
      }
      if (msg.key.type == tui.KeyType.right) {
        setState(() => _translateX = (_translateX + 1).clamp(0, 20));
      }
      if (msg.key.type == tui.KeyType.left) {
        setState(() => _translateX = (_translateX - 1).clamp(0, 20));
      }
      if (msg.key.type == tui.KeyType.down) {
        setState(() => _translateY = (_translateY + 1).clamp(0, 10));
      }
      if (msg.key.type == tui.KeyType.up) {
        setState(() => _translateY = (_translateY - 1).clamp(0, 10));
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = Style()..foreground(theme.onSurface);

    final sampleContent = w.Column(
      children: [
        w.Text('ABC', style: onSurface),
        w.Text('DEF', style: onSurface),
        w.Text('GHI', style: onSurface),
      ],
    );

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
                w.Text('Transform Widget Demo', style: theme.titleLarge),
                w.Text(
                  'h = flip H | v = flip V | arrows = translate | r = reset | q = quit',
                  style: label,
                ),
                w.Text(
                  'FlipH: ${_flipH ? "ON" : "OFF"} | '
                  'FlipV: ${_flipV ? "ON" : "OFF"} | '
                  'Translate: ($_translateX, $_translateY)',
                  style: label,
                ),
                w.Divider(width: 65),

                // Combined transform
                w.Text('Combined Transform:', style: theme.titleMedium),
                w.Container(
                  width: 40,
                  height: 8,
                  decoration: w.BoxDecoration(
                    border: Border.normal,
                    color: theme.surface,
                  ),
                  child: w.Transform(
                    translateX: _translateX,
                    translateY: _translateY,
                    flipH: _flipH,
                    flipV: _flipV,
                    child: sampleContent,
                  ),
                ),
                w.Divider(width: 65),

                // Static examples side by side
                w.Text('Static Examples:', style: theme.titleMedium),
                w.Row(
                  gap: 4,
                  children: [
                    w.Column(
                      children: [
                        w.Text('Original', style: label),
                        w.Container(
                          decoration: w.BoxDecoration(
                            border: Border.normal,
                            color: theme.surface,
                          ),
                          padding: const w.EdgeInsets.all(1),
                          child: w.Column(
                            children: [
                              w.Text('123', style: onSurface),
                              w.Text('456', style: onSurface),
                            ],
                          ),
                        ),
                      ],
                    ),
                    w.Column(
                      children: [
                        w.Text('Flip H', style: label),
                        w.Container(
                          decoration: w.BoxDecoration(
                            border: Border.normal,
                            color: theme.surface,
                          ),
                          padding: const w.EdgeInsets.all(1),
                          child: w.Transform.flipHorizontal(
                            child: w.Column(
                              children: [
                                w.Text('123', style: onSurface),
                                w.Text('456', style: onSurface),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    w.Column(
                      children: [
                        w.Text('Flip V', style: label),
                        w.Container(
                          decoration: w.BoxDecoration(
                            border: Border.normal,
                            color: theme.surface,
                          ),
                          padding: const w.EdgeInsets.all(1),
                          child: w.Transform.flipVertical(
                            child: w.Column(
                              children: [
                                w.Text('123', style: onSurface),
                                w.Text('456', style: onSurface),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    w.Column(
                      children: [
                        w.Text('Translate(3,1)', style: label),
                        w.Container(
                          width: 15,
                          height: 5,
                          decoration: w.BoxDecoration(
                            border: Border.normal,
                            color: theme.surface,
                          ),
                          child: w.Transform.translate(
                            offset: const w.Offset(3, 1),
                            child: w.Text('Hi!', style: onSurface),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
