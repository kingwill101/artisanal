//
// Run with: dart run example/tui/examples/widgets/focus/main.dart

import 'package:artisanal/terminal.dart' as term;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(FocusDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.cellMotion,
      useUltravioletRenderer: true,
    ),
  );
}

class FocusDemo extends w.StatefulWidget {
  FocusDemo({super.key});

  @override
  w.State createState() => _FocusDemoState();
}

class _FocusDemoState extends w.State<FocusDemo> {
  final w.FocusController _controller = w.FocusController();
  final List<String> _values = <String>['', ''];

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    return w.FocusScope(
      controller: _controller,
      child: w.Container(
        padding: const w.EdgeInsets.all(1),
        color: theme.background,
        child: w.Column(
          gap: 1,
          children: [
            w.Text('Focus Demo', style: theme.titleLarge),
            w.Text(
              'Click a field and type. Press q to quit.',
              style: theme.labelSmall,
            ),
            _field(theme, index: 0, label: 'First name'),
            _field(theme, index: 1, label: 'Last name'),
          ],
        ),
      ),
    );
  }

  w.Widget _field(w.Theme theme, {required int index, required String label}) {
    return w.Focusable(
      controller: _controller,
      focusId: 'field-$index',
      autofocus: index == 0,
      onKey: (msg) => _handleInput(index, msg.key),
      child: w.Container(
        padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        color: _controller.isFocused('field-$index')
            ? theme.surface
            : theme.background,
        child: w.Row(
          gap: 2,
          children: [
            w.Text(label, style: theme.labelMedium),
            w.Text(_renderValue(index), style: theme.bodyMedium),
          ],
        ),
      ),
    );
  }

  String _renderValue(int index) {
    final value = _values[index];
    if (value.isEmpty) return '—';
    return value;
  }

  tui.Cmd? _handleInput(int index, term.Key key) {
    if (key.type == term.KeyType.backspace) {
      setState(() {
        if (_values[index].isNotEmpty) {
          _values[index] = _values[index].substring(
            0,
            _values[index].length - 1,
          );
        }
      });
      return null;
    }
    final ch = key.char;
    if (ch == null || ch.isEmpty) return null;
    if (ch == '\n' || ch == '\r') return null;
    setState(() {
      _values[index] = '${_values[index]}$ch';
    });
    return null;
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key)) {
      if (key.char == 'q') return tui.Cmd.quit();
    }
    return null;
  }
}
