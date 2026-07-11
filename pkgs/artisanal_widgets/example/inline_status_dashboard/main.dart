// Inline widget dashboard.
//
// Runs a widget-based dashboard in the primary screen's bottom rows while
// streaming log lines above it through Cmd.println.
//
// Run with:
//   dart run pkgs/artisanal_widgets/example/inline_status_dashboard/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = InlineWidgetDashboardApp();
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      screenMode: tui.ScreenMode.inline,
      inlineHeight: 8,
      uiAnchor: tui.UiAnchor.bottom,
      mouseMode: tui.MouseMode.none,
      fps: 30,
      startupProbes: false,
    ),
  );
}

class InlineWidgetDashboardApp extends w.WidgetApp {
  InlineWidgetDashboardApp()
    : super(
        _DashboardView(tick: 0, progress: 0, running: true),
        handleFrameTick: false,
      );

  int _tick = 0;
  int _progress = 0;
  bool _running = true;

  @override
  tui.Cmd? init() {
    final base = super.init();
    final ticker = tui.every(
      const Duration(milliseconds: 500),
      (_) => const _DashboardTick(),
    );
    return base == null ? ticker : tui.ParallelCmd([base, ticker]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg &&
        msg.key.type == tui.KeyType.runes &&
        msg.key.runes.isNotEmpty) {
      final ch = String.fromCharCode(msg.key.runes.first);
      if (ch == 'q') return (this, tui.Cmd.quit());
      if (ch == ' ') {
        _running = !_running;
        _refreshRoot();
        return (
          this,
          tui.Cmd.println(_running ? '[widgets] resumed' : '[widgets] paused'),
        );
      }
    }

    if (msg is _DashboardTick) {
      if (!_running) return (this, null);
      _tick++;
      _progress = (_progress + 7) % 101;
      _refreshRoot();
      return (this, tui.Cmd.println(_logLine()));
    }

    final result = super.update(msg);
    return (this, result.$2);
  }

  void _refreshRoot() {
    root = _DashboardView(tick: _tick, progress: _progress, running: _running);
    reassemble();
  }

  String _logLine() {
    final phase = _DashboardView.phaseFor(_tick);
    final ms = 14 + (_tick * 11) % 83;
    final fps = 59 + (_tick * 9) % 61;
    return '[widgets ${_tick.toString().padLeft(3, '0')}] '
        '$phase completed in ${ms}ms; terminal frame ${fps}fps';
  }
}

class _DashboardTick extends tui.Msg {
  const _DashboardTick();
}

class _DashboardView extends w.StatelessWidget {
  _DashboardView({
    required this.tick,
    required this.progress,
    required this.running,
  });

  final int tick;
  final int progress;
  final bool running;

  static String phaseFor(int tick) {
    const phases = ['layout', 'diff', 'paint', 'flush', 'input', 'metrics'];
    return phases[tick % phases.length];
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = context.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final phase = phaseFor(tick);
    final status = running ? 'RUNNING' : 'PAUSED';
    final fps = 59 + (tick * 9) % 61;
    final memory = 96 + (tick * 5) % 48;

    return w.Container(
      padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      color: theme.background,
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.StatusLine(
            left: [
              w.StatusItem.text('artisanal widgets'),
              w.StatusItem.text(' '),
              w.StatusItem.text(status),
            ],
            center: [w.StatusItem.text('inline dashboard')],
            right: [
              w.StatusItem.keyHint('space', 'pause'),
              w.StatusItem.text(' '),
              w.StatusItem.keyHint('q', 'quit'),
            ],
          ),
          w.Row(
            gap: 2,
            children: [
              w.Badge(phase.toUpperCase(), background: theme.primary),
              w.Text('tick ${tick.toString().padLeft(3, '0')}', style: label),
              w.Text('${fps}fps', style: label),
              w.Text('${memory}MB', style: label),
            ],
          ),
          w.ProgressIndicator(
            value: progress / 100,
            showLabel: true,
            width: 42,
            color: running ? theme.success : Colors.yellow,
            trackColor: theme.muted,
          ),
          w.Divider(),
          w.Text(
            'Logs above this panel are emitted via Cmd.println; native scrollback stays available.',
            style: label,
          ),
        ],
      ),
    );
  }
}
