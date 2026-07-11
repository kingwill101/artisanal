// Sparkline Enhancements Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates the new SparklineChart features:
// - Color gradient (low → high value coloring)
// - Configurable baseline (values at/below render as empty)
// - Explicit min/max bounds (consistent scaling across charts)
//
// Run with: dart run example/sparkline_enhancements/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' show UvStyle, UvColor;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:artisanal_widgets/charting.dart' as charting;

void main() async {
  final app = WidgetApp(SparklineEnhancementsShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class SparklineEnhancementsShowcase extends w.StatefulWidget {
  SparklineEnhancementsShowcase({super.key});

  @override
  w.State createState() => _SparklineEnhancementsShowcaseState();
}

class _SparklineEnhancementsShowcaseState
    extends w.State<SparklineEnhancementsShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final dim = theme.bodySmall.copy()..foreground(theme.muted);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
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
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text('Sparkline Enhancements', style: theme.titleLarge),
              w.Text('Press q to quit.', style: label),
              w.Divider(),

              // ── Basic Sparkline ──
              w.Text('Basic (single color)', style: theme.titleMedium),
              charting.SparklineChart(
                values: [10, 20, 15, 30, 25, 18, 35, 28, 40, 22, 33, 12, 27],
                height: 1,
                style: UvStyle(fg: UvColor.rgb(80, 200, 120)),
              ),
              w.Divider(),

              // ── Color Gradient ──
              w.Text('Color Gradient (blue → red)', style: theme.titleMedium),
              charting.SparklineChart(
                values: [1, 2, 5, 3, 8, 6, 10, 7, 4, 9, 2, 6],
                height: 1,
                style: UvStyle(fg: UvColor.rgb(200, 200, 200)),
                gradientLow: UvStyle(fg: UvColor.rgb(0, 100, 255)),
                gradientHigh: UvStyle(fg: UvColor.rgb(255, 50, 50)),
              ),
              w.Text('Low values → blue, high values → red', style: dim),
              w.Divider(),

              // ── Gradient Multi-Row ──
              w.Text(
                'Gradient Multi-Row (green → yellow → red)',
                style: theme.titleMedium,
              ),
              charting.SparklineChart(
                values: [5, 15, 10, 25, 20, 35, 30, 40, 28, 33, 18, 38],
                height: 4,
                gradientLow: UvStyle(fg: UvColor.rgb(0, 200, 0)),
                gradientHigh: UvStyle(fg: UvColor.rgb(255, 50, 50)),
                showGrid: true,
                gridStyle: UvStyle(fg: UvColor.rgb(60, 60, 60)),
              ),
              w.Divider(),

              // ── Baseline ──
              w.Text(
                'Baseline = 0 (default: empty below zero)',
                style: theme.titleMedium,
              ),
              charting.SparklineChart(
                values: [-5, -2, 0, 3, 8, 5, 12, 7, 2, -1, 4, 10],
                height: 1,
                style: UvStyle(fg: UvColor.rgb(200, 200, 100)),
                baseline: 0.0,
              ),
              w.Text('Negative and zero values → empty columns', style: dim),
              w.Divider(),

              w.Text('Baseline = 5 (empty below 5)', style: theme.titleMedium),
              charting.SparklineChart(
                values: [1, 3, 5, 7, 9, 6, 8, 10, 4, 2, 7, 11],
                height: 1,
                style: UvStyle(fg: UvColor.rgb(100, 200, 255)),
                baseline: 5.0,
              ),
              w.Text('Values ≤ 5 → empty columns', style: dim),
              w.Divider(),

              // ── Explicit Bounds ──
              w.Text(
                'Explicit Bounds (0–100, same data, different ranges)',
                style: theme.titleMedium,
              ),
              w.Row(
                gap: 1,
                children: [
                  w.Text('Auto:  ', style: label),
                  w.Expanded(
                    child: charting.SparklineChart(
                      values: [25, 50, 75],
                      height: 1,
                      style: UvStyle(fg: UvColor.rgb(200, 200, 200)),
                    ),
                  ),
                ],
              ),
              w.Row(
                gap: 1,
                children: [
                  w.Text('0–100: ', style: label),
                  w.Expanded(
                    child: charting.SparklineChart(
                      values: [25, 50, 75],
                      height: 1,
                      style: UvStyle(fg: UvColor.rgb(200, 200, 200)),
                      minValue: 0.0,
                      maxValue: 100.0,
                    ),
                  ),
                ],
              ),
              w.Row(
                gap: 1,
                children: [
                  w.Text('0–200: ', style: label),
                  w.Expanded(
                    child: charting.SparklineChart(
                      values: [25, 50, 75],
                      height: 1,
                      style: UvStyle(fg: UvColor.rgb(200, 200, 200)),
                      minValue: 0.0,
                      maxValue: 200.0,
                    ),
                  ),
                ],
              ),
              w.Text(
                'Same [25, 50, 75] data — different bar heights',
                style: dim,
              ),
              w.Divider(),

              // ── Combined: Gradient + Baseline + Bounds ──
              w.Text(
                'Combined: Gradient + Baseline + Bounds',
                style: theme.titleMedium,
              ),
              charting.SparklineChart(
                values: [-10, 0, 10, 20, 30, 50, 40, 60, 25, 15, 5, -5],
                height: 5,
                baseline: 0.0,
                minValue: -20.0,
                maxValue: 80.0,
                gradientLow: UvStyle(fg: UvColor.rgb(0, 0, 200)),
                gradientHigh: UvStyle(fg: UvColor.rgb(255, 200, 0)),
                showGrid: true,
                gridStyle: UvStyle(fg: UvColor.rgb(40, 40, 40)),
              ),
              w.Text(
                'Baseline=0, bounds=[-20,80], gradient blue→gold, grid on',
                style: dim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
