// Error Recovery Example
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates the global error boundary in WidgetApp. Unhandled exceptions
// during update/build no longer crash the TUI. Instead, an error screen is
// shown with a scrollable stack trace, a Copy button, and a Dismiss button
// (or press Escape) to recover the app.
//
// Controls:
//   1 = trigger build-time error
//   2 = trigger update-time error
//   c  = copy last error to clipboard (when error screen is visible)
//   Esc = dismiss error and recover
//   q   = quit
//
// Run with: dart run example/error_recovery/main.dart

import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(ErrorRecoveryDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ErrorRecoveryDemo extends w.StatefulWidget {
  ErrorRecoveryDemo({super.key});

  @override
  w.State<ErrorRecoveryDemo> createState() => _ErrorRecoveryDemoState();
}

class _ErrorRecoveryDemoState extends w.State<ErrorRecoveryDemo> {
  int _selected = 0;
  String _status = 'Press 1 or 2 to trigger an error.';

  static const _items = [
    'Trigger a build-time error',
    'Trigger an update-time error',
  ];

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();

      if (msg.key.type == KeyType.down) {
        setState(() => _selected = (_selected + 1) % _items.length);
        return tui.Cmd.none();
      }
      if (msg.key.type == KeyType.up) {
        setState(
          () => _selected = (_selected - 1 + _items.length) % _items.length,
        );
        return tui.Cmd.none();
      }
      if (msg.key.type == KeyType.enter) {
        _activate();
        return tui.Cmd.none();
      }
    }
    return null;
  }

  void _activate() {
    switch (_selected) {
      case 0:
        setState(() {
          _status = 'About to throw in build()...';
          throw StateError('Deliberate build-time error');
        });
        break;
      case 1:
        setState(() {
          _status = 'About to throw in update()...';
        });
        throw StateError('Deliberate update-time error');
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    final menuItems = <w.Widget>[];
    for (var i = 0; i < _items.length; i++) {
      final prefix = i == _selected ? '> ' : '  ';
      final style = i == _selected
          ? (theme.titleSmall.copy()..foreground(theme.primary))
          : label;
      menuItems.add(w.Text('$prefix${_items[i]}', style: style));
    }

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('Error Recovery Demo', style: theme.titleLarge),
          w.Text(
            'Up/Down = select | Enter = trigger error | q = quit',
            style: label,
          ),
          w.Divider(width: 55),
          ...menuItems,
          w.Divider(width: 55),
          w.Text(_status, style: label),
        ],
      ),
    );
  }
}
