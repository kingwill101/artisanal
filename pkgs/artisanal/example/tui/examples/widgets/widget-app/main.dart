// WidgetApp Example
import 'package:artisanal/widgets.dart' as w;
import 'package:artisanal/widgets.dart' as tui hide Key, TextSelection;
//
// Run with: dart run example/tui/examples/widgets/widget-app/main.dart

import 'package:artisanal/tui.dart' as tui;

void main() async {
  final app = tui.WidgetApp(CounterApp());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(altScreen: false, mouse: true),
  );
}

class CounterApp extends w.StatefulWidget {
  CounterApp({super.key});

  @override
  w.State createState() => _CounterAppState();
}

class _CounterAppState extends w.State<CounterApp> {
  int count = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: widget.theme.background,
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
