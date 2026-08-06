# artisanal_charts

OpenTUI-style terminal charts for [Artisanal](https://github.com/kingwill101/artisanal) — a Dart port of [opentui-charts](https://github.com/).

Renders **9 chart types** with sub-pixel fidelity (Unicode quadrant blocks & braille), automatic nice-scale axes, legends, and sliding-window time-series buffers for live dashboards.

> This package is **parallel** to the lower-level `package:artisanal` charting painters and `package:artisanal_widgets` chart widgets. Use this when you want the OpenTUI props/create/update API and full chart chrome (title, margins, axes, grid).

## Chart types

| Chart | Factory | Description |
|-------|---------|-------------|
| **Line** | `createLineChart` | Multi-series, quadrant sub-pixel lines, step mode, optional fill |
| **Bar** | `createBarChart` | Vertical/horizontal, single or grouped |
| **Pie** | `createPieChart` | Pie/donut with braille fill and labels |
| **Scatter** | `createScatterChart` | Per-point colors |
| **Area** | `createAreaChart` | Filled area, optional stacking |
| **Stacked Bar** | `createStackedBarChart` | Stacked categories |
| **Heatmap** | `createHeatmapChart` | 2D intensity grid |
| **Gauge** | `createGaugeChart` | Semicircle with thresholds (braille) |
| **Sparkline** | `createSparkline` | Compact line/bar/dot mini-charts |

## Install

In the monorepo workspace:

```yaml
dependencies:
  artisanal_charts:
    path: pkgs/artisanal_charts
```

## Quick start

```dart
import 'package:artisanal_charts/artisanal_charts.dart';

void main() {
  final chart = createLineChart(LineChartProps(
    width: 60,
    height: 20,
    title: 'Revenue',
    series: [
      DataSeries(name: '2025', data: [10, 25, 35, 42, 55, 63], color: '#4FC3F7'),
      DataSeries(name: '2026', data: [15, 30, 40, 50, 60, 75], color: '#81C784'),
    ],
    showDots: true,
    grid: GridOptions(show: true),
  ));

  print(chart.render());
}
```

## API

Every chart type exports three entry points:

| Function | Purpose |
|----------|---------|
| `create*Chart(props)` | Allocates a [ChartSurface] and paints |
| `update*Chart(surface, props)` | Re-paints in place |
| `render*Chart(fb, w, h, props)` | Low-level paint onto any [ChartFrameBuffer] |

### Live updates + time series

```dart
final buf = TimeSeriesBuffer(TimeSeriesBufferOptions(windowMs: 60000, maxPoints: 200));
// push samples...
final surface = createLineChart(LineChartProps(
  width: 60,
  height: 12,
  series: [DataSeries(name: 'CPU', data: buf.getData(), color: '#4FC3F7')],
));

// later:
updateLineChart(surface, LineChartProps(
  width: 60,
  height: 12,
  series: [DataSeries(name: 'CPU', data: buf.getData(), color: '#4FC3F7')],
));
```

### Widget integration

```dart
ChartView(
  width: 60,
  height: 14,
  paintCallback: (fb, w, h) => renderLineChart(fb, w, h, props),
)
```

## Demos

```bash
cd pkgs/artisanal_charts

# Interactive overview (matches opentui-charts `bun run demo:all`):
# 3×3 grid → full-screen pages via ←/→ or SPACE
dart run example/demo_all.dart

dart run example/demo.dart              # static 2×2 dashboard
dart run example/demo_animated.dart     # live-updating frames
dart run example/demos/line.dart        # single chart prints
# ... bar, pie, scatter, area, stacked_bar, heatmap, gauge, sparkline
```

## Rendering notes

- **Line / Area / Sparkline** use a **QuadrantCanvas** (2×2 sub-pixels per cell).
- **Pie / Gauge** use a **BrailleCanvas** (2×4 sub-pixels).
- **Bar / Stacked / Scatter / Heatmap** use direct cell paints.
- All scaled charts use `computeNiceScale()` for even tick spacing.

## License

MIT
