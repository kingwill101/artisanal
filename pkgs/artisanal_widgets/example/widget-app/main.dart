// WidgetApp Example
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Run with: dart run example/widget-app/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(CounterApp());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class CounterApp extends w.StatefulWidget {
  CounterApp({super.key});

  @override
  w.State createState() => _CounterAppState();
}

class _CounterAppState extends w.State<CounterApp> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int count = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: widget.theme.background,
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
                w.Text('WidgetApp Counter', style: widget.theme.titleLarge),
                w.Text('Count: $count', style: widget.theme.titleMedium),
                w.Text(
                  'Press + / - to change, q to quit',
                  style: widget.theme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') {
        return tui.Cmd.quit();
      }
      if (key.char == '+' || key.char == '=') {
        setState(() => count++);
      }
      if (key.char == '-') {
        setState(() => count--);
      }
    }
    return null;
  }
}
