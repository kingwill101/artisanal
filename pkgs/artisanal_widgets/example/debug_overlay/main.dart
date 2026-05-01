// DebugOverlay Example
//
// Demonstrates the built-in debug overlay via WidgetApp's debugOverlay
// parameter and the F12 toggle.  Also shows manual PerformanceOverlay
// usage for the simpler frame-timing display.
//
// Press F12 to toggle the built-in debug overlay.
// Press 'p' to toggle the manual PerformanceOverlay.
// Press +/- to bump a counter (triggers re-renders).
// Press 'q' to quit.
//
// Run with: dart run example/debug_overlay/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final monitor = w.RenderMetricsProgramMonitor(prefix: 'Monitor');
  // The simplest way: set debugOverlay: true.
  // Press F12 at runtime to toggle it on/off.
  final app = tui.WidgetApp(
    DebugOverlayDemo(),
    debugOverlay: true,
    debugOverlayPosition: w.DebugOverlayPosition.topRight,
  );
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ).withInterceptor(monitor),
  );
}

class DebugOverlayDemo extends w.StatefulWidget {
  DebugOverlayDemo({super.key});

  @override
  w.State createState() => _DebugOverlayDemoState();
}

class _DebugOverlayDemoState extends w.State<DebugOverlayDemo> {
  bool _perfEnabled = false;
  int _counter = 0;
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'p') {
        setState(() => _perfEnabled = !_perfEnabled);
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

    final content = w.Container(
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
                w.Text('Debug Overlay Demo', style: theme.titleLarge),
                w.Text(
                  'F12 = toggle debug overlay | p = toggle perf | +/- = counter | q = quit',
                  style: label,
                ),
                w.Text('Perf: ${_perfEnabled ? "ON" : "OFF"}', style: label),
                w.Divider(width: 65),
                w.Text('Counter: $_counter', style: theme.titleMedium),
                w.Text(
                  'Press +/- to change the counter and trigger re-renders.\n'
                  'Watch the overlay metrics update in response.',
                  style: label,
                ),
                w.Divider(width: 65),
                w.Text(
                  'The built-in debug overlay (F12) shows FPS, frame count,\n'
                  'and average frame/render time. It uses real renderer metrics\n'
                  'and shows 0.0 FPS when idle.\n\n'
                  'PerformanceOverlay (p) shows a simpler frame counter\n'
                  'and last frame time at the bottom-right.',
                  style: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Optionally wrap with PerformanceOverlay (manual toggle via 'p')
    if (_perfEnabled) {
      return w.PerformanceOverlay(enabled: true, child: content);
    }

    return content;
  }
}
