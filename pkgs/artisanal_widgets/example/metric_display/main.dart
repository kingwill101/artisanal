// MetricDisplay Showcase
//
// Demonstrates MetricDisplay with various metric values, units, trend
// indicators, and dynamic value updates.
//
// Run with: dart run example/metric_display/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(MetricDisplayShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class MetricDisplayShowcase extends w.StatefulWidget {
  MetricDisplayShowcase({super.key});

  @override
  w.State createState() => _MetricDisplayShowcaseState();
}

class _MetricDisplayShowcaseState extends w.State<MetricDisplayShowcase> {
  int _cpuValue = 42;
  int _memValue = 68;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    final cpuTrend = _cpuValue > 50
        ? w.MetricTrend.up
        : (_cpuValue < 30 ? w.MetricTrend.down : w.MetricTrend.flat);

    final memTrend = _memValue > 70
        ? w.MetricTrend.up
        : (_memValue < 40 ? w.MetricTrend.down : w.MetricTrend.flat);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        gap: 1,
        children: [
          w.Text('MetricDisplay Showcase', style: theme.titleLarge),
          w.Text('+/-: adjust CPU  [/]: adjust Memory  q: quit', style: label),
          w.Divider(width: 60),

          // -- Dynamic metrics --
          w.Text('System Metrics (dynamic)', style: theme.titleMedium),
          w.Frame(
            border: Border.rounded,
            borderColor: theme.border,
            padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: w.Column(
              gap: 1,
              children: [
                w.MetricDisplay(
                  label: 'CPU Usage',
                  value: '$_cpuValue',
                  unit: '%',
                  trend: cpuTrend,
                ),
                w.MetricDisplay(
                  label: 'Memory',
                  value: '$_memValue',
                  unit: '%',
                  trend: memTrend,
                ),
              ],
            ),
          ),
          w.Divider(width: 60),

          // -- All trend directions --
          w.Text('Trend Indicators', style: theme.titleMedium),
          w.Column(
            gap: 0,
            children: [
              w.MetricDisplay(
                label: 'Revenue',
                value: '12.4',
                unit: 'k',
                trend: w.MetricTrend.up,
              ),
              w.MetricDisplay(
                label: 'Latency',
                value: '230',
                unit: 'ms',
                trend: w.MetricTrend.down,
              ),
              w.MetricDisplay(
                label: 'Uptime',
                value: '99.9',
                unit: '%',
                trend: w.MetricTrend.flat,
              ),
            ],
          ),
          w.Divider(width: 60),

          // -- Without trends or units --
          w.Text('Minimal Metrics', style: theme.titleMedium),
          w.Column(
            gap: 0,
            children: [
              w.MetricDisplay(label: 'Active Users', value: '1,247'),
              w.MetricDisplay(label: 'Open Issues', value: '38'),
              w.MetricDisplay(label: 'Build Status', value: 'passing'),
            ],
          ),
          w.Divider(width: 60),

          // -- Various units --
          w.Text('Mixed Units', style: theme.titleMedium),
          w.Column(
            gap: 0,
            children: [
              w.MetricDisplay(
                label: 'Disk Free',
                value: '128',
                unit: ' GB',
                trend: w.MetricTrend.down,
              ),
              w.MetricDisplay(
                label: 'Requests/sec',
                value: '4,520',
                unit: ' rps',
                trend: w.MetricTrend.up,
              ),
              w.MetricDisplay(
                label: 'Error Rate',
                value: '0.02',
                unit: '%',
                trend: w.MetricTrend.flat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') return tui.Cmd.quit();
      if (key.char == '+' || key.char == '=') {
        setState(() {
          _cpuValue = (_cpuValue + 5).clamp(0, 100);
        });
      }
      if (key.char == '-') {
        setState(() {
          _cpuValue = (_cpuValue - 5).clamp(0, 100);
        });
      }
      if (key.char == ']') {
        setState(() {
          _memValue = (_memValue + 5).clamp(0, 100);
        });
      }
      if (key.char == '[') {
        setState(() {
          _memValue = (_memValue - 5).clamp(0, 100);
        });
      }
    }
    return null;
  }
}
