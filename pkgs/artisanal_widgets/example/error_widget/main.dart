// TUIErrorWidget Example
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates the TUIErrorWidget for displaying error messages with
// optional details and icon. Press 'd' to toggle details, 'i' to toggle icon.
//
// Run with: dart run example/error_widget/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(ErrorWidgetDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ErrorWidgetDemo extends w.StatefulWidget {
  ErrorWidgetDemo({super.key});

  @override
  w.State createState() => _ErrorWidgetDemoState();
}

class _ErrorWidgetDemoState extends w.State<ErrorWidgetDemo> {
  bool _showDetails = false;
  bool _showIcon = true;
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'd') {
        setState(() => _showDetails = !_showDetails);
      }
      if (msg.key.char == 'i') {
        setState(() => _showIcon = !_showIcon);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    const stackTrace =
        '#0      main (package:example/main.dart:12:3)\n'
        '#1      _startIsolate.<anonymous closure> (isolate_patch.dart:301)\n'
        '#2      _RawReceivePortImpl._handleMessage (isolate_patch.dart:168)';

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
              crossAxisAlignment: w.CrossAxisAlignment.start,
              children: [
                w.Text('TUIErrorWidget Demo', style: theme.titleLarge),
                w.Text(
                  'd = toggle details | i = toggle icon | q = quit',
                  style: label,
                ),
                w.Text(
                  'Details: ${_showDetails ? "ON" : "OFF"} | '
                  'Icon: ${_showIcon ? "ON" : "OFF"}',
                  style: label,
                ),
                w.Divider(width: 60),

                // Simple error
                w.Text('Simple Error:', style: theme.titleMedium),
                w.TUIErrorWidget(
                  message: 'Connection refused',
                  showIcon: _showIcon,
                ),
                w.Divider(width: 60),

                // Error with details
                w.Text('Error with Details:', style: theme.titleMedium),
                w.TUIErrorWidget(
                  message: 'Widget build failed: NullPointerException',
                  details: _showDetails ? stackTrace : null,
                  showIcon: _showIcon,
                ),
                w.Divider(width: 60),

                // Multiple errors
                w.Text('Multiple Errors:', style: theme.titleMedium),
                w.TUIErrorWidget(
                  message: 'File not found: config.yaml',
                  showIcon: _showIcon,
                ),
                w.TUIErrorWidget(
                  message: 'Permission denied: /etc/shadow',
                  details: _showDetails ? 'errno = EACCES (13)' : null,
                  showIcon: _showIcon,
                ),
                w.TUIErrorWidget(
                  message: 'Network timeout after 30s',
                  showIcon: _showIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
