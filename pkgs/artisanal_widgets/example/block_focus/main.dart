// BlockFocus Example
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates blocking keyboard events from reaching child widgets.
// Toggle blocking on/off with 'b' and observe key events being consumed
// or passed through to the inner counter.
//
// Run with: dart run example/block_focus/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(BlockFocusDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class BlockFocusDemo extends w.StatefulWidget {
  BlockFocusDemo({super.key});

  @override
  w.State createState() => _BlockFocusDemoState();
}

class _BlockFocusDemoState extends w.State<BlockFocusDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _blocking = true;
  int _counter = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'b') {
        setState(() => _blocking = !_blocking);
      }
      if (msg.key.char == '+') {
        setState(() => _counter++);
      }
      if (msg.key.char == '-' && _counter > 0) {
        setState(() => _counter--);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = theme.labelSmall.copy()..foreground(theme.onSurface);

    final statusStyle = Style()
      ..foreground(_blocking ? Colors.red : Colors.green)
      ..bold();

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Container(
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
                w.Text('BlockFocus Demo', style: theme.titleLarge),
                w.Text(
                  'b = toggle blocking | +/- = change counter | q = quit',
                  style: label,
                ),
                w.Divider(width: 60),

                w.Text(
                  'Blocking: ${_blocking ? "ON" : "OFF"}',
                  style: statusStyle,
                ),
                w.Divider(width: 60),

                w.Text(
                  'Counter (inside BlockFocus):',
                  style: theme.titleMedium,
                ),
                w.BlockFocus(
                  blocking: _blocking,
                  child: w.Container(
                    width: 30,
                    height: 3,
                    color: theme.surface,
                    alignment: w.Alignment.center,
                    child: w.Text('Count: $_counter', style: onSurface),
                  ),
                ),

                w.Divider(width: 60),
                w.Text(
                  _blocking
                      ? 'Keys +/- are blocked from reaching the counter area.'
                      : 'Keys pass through — press +/- to change the counter.',
                  style: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
