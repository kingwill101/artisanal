// All chart types demo — layout parity with opentui-charts `bun run demo:all`.
//
// Overview: 3×3 grid of all charts.
// Navigate: ←/→ or SPACE/Enter cycle overview → full-screen charts → overview.
// Exit: Ctrl+C / q
//
// Run: dart run example/charting/demo_all.dart
import 'dart:math' as math;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';

void main() async {
  await tui.runProgram(
    WidgetApp(_DemoAllApp()),
    options: const tui.ProgramOptions(altScreen: true),
  );
}

// ─── Navigation ──────────────────────────────────────────────────────────────

/// `-1` = overview grid, `0..8` = full-screen chart index.
const _overview = -1;
const _total = 9;

// ─── Shared sample data (matches demo-all.ts) ────────────────────────────────

const _lineSeries = [
  DataSeries(
    name: 'Revenue',
    data: [12, 28, 35, 47, 42, 55, 63, 58, 71, 80],
    color: '#4FC3F7',
  ),
  DataSeries(
    name: 'Costs',
    data: [8, 15, 22, 30, 35, 32, 40, 45, 50, 48],
    color: '#E57373',
  ),
];

const _barSeries = [
  DataSeries(
    name: 'Sales',
    data: [90, 120, 75, 140, 110, 95, 130],
    color: '#81C784',
  ),
];

const _barLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _pieSlices = [
  PieSlice(label: 'TypeScript', value: 45, color: '#3178C6'),
  PieSlice(label: 'Zig', value: 30, color: '#F7A41D'),
  PieSlice(label: 'MDX', value: 10, color: '#FCB32C'),
  PieSlice(label: 'Other', value: 15, color: '#888888'),
];

const _pieSlicesShort = [
  PieSlice(label: 'TS', value: 45, color: '#3178C6'),
  PieSlice(label: 'Zig', value: 30, color: '#F7A41D'),
  PieSlice(label: 'MDX', value: 10, color: '#FCB32C'),
  PieSlice(label: 'Other', value: 15, color: '#888888'),
];

const _areaSeries = [
  DataSeries(
    name: 'Frontend',
    data: [20, 35, 30, 45, 50, 55, 60],
    color: '#4FC3F7',
  ),
  DataSeries(
    name: 'Backend',
    data: [15, 20, 25, 30, 35, 30, 40],
    color: '#81C784',
  ),
  DataSeries(
    name: 'DevOps',
    data: [5, 10, 15, 12, 18, 22, 20],
    color: '#FFB74D',
  ),
];

const _stackedSeries = [
  DataSeries(name: 'Bugs', data: [15, 22, 18, 10, 8], color: '#E57373'),
  DataSeries(name: 'Features', data: [30, 25, 35, 40, 45], color: '#81C784'),
  DataSeries(name: 'Chores', data: [10, 8, 12, 15, 10], color: '#FFB74D'),
];

const _heatmapData = <List<double>>[
  [2, 5, 8, 3, 1, 9, 7],
  [6, 1, 4, 8, 5, 2, 3],
  [9, 7, 2, 5, 8, 4, 6],
  [3, 8, 6, 1, 4, 7, 9],
  [1, 4, 9, 7, 2, 5, 8],
];

const _sparkData = <double>[
  3, 7, 2, 9, 5, 8, 1, 6, 4, 10, 3, 7, 5, 8, 2, 9, 6, 4, 7, 3, 8, 5, 10, 2, 6,
];

const _bg = '#0D1117';
const _palette = ['#4FC3F7', '#81C784', '#FFB74D', '#E57373'];

List<ScatterPoint> _scatterPoints(math.Random rng, {int count = 40}) {
  return [
    for (var i = 0; i < count; i++)
      ScatterPoint(
        x: rng.nextDouble() * 100,
        y: rng.nextDouble() * 100,
        color: _palette[rng.nextInt(_palette.length)],
      ),
  ];
}

// ─── Chart factories ─────────────────────────────────────────────────────────

ChartPainter _fullChart(int index, math.Random rng) {
  return (screen, area) {
    switch (index) {
      case 0:
        renderLineChart(
          screen,
          area,
          LineChartProps(
            width: area.width,
            height: area.height,
            title: '1/9 — Line Chart',
            series: _lineSeries,
            showDots: true,
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 1:
        renderBarChart(
          screen,
          area,
          BarChartProps(
            width: area.width,
            height: area.height,
            title: '2/9 — Bar Chart',
            series: _barSeries,
            labels: _barLabels,
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 2:
        renderPieChart(
          screen,
          area,
          PieChartProps(
            width: area.width,
            height: area.height,
            title: '3/9 — Pie Chart',
            slices: _pieSlices,
            showPercentages: true,
            backgroundColor: _bg,
          ),
        );
      case 3:
        renderScatterChart(
          screen,
          area,
          ScatterChartProps(
            width: area.width,
            height: area.height,
            title: '4/9 — Scatter Chart',
            points: _scatterPoints(rng),
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 4:
        renderAreaChart(
          screen,
          area,
          AreaChartProps(
            width: area.width,
            height: area.height,
            title: '5/9 — Area Chart (Stacked)',
            series: _areaSeries,
            stacked: true,
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 5:
        renderStackedBarChart(
          screen,
          area,
          StackedBarChartProps(
            width: area.width,
            height: area.height,
            title: '6/9 — Stacked Bar Chart',
            series: _stackedSeries,
            labels: const [
              'Sprint 1',
              'Sprint 2',
              'Sprint 3',
              'Sprint 4',
              'Sprint 5',
            ],
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 6:
        renderHeatmapChart(
          screen,
          area,
          HeatmapChartProps(
            width: area.width,
            height: area.height,
            title: '7/9 — Heatmap',
            data: _heatmapData,
            xLabels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            yLabels: const ['Week1', 'Week2', 'Week3', 'Week4', 'Week5'],
            showValues: true,
            backgroundColor: _bg,
            margins: const ChartMargins(left: 8, right: 2, top: 2, bottom: 3),
          ),
        );
      case 7:
        renderGaugeChart(
          screen,
          area,
          GaugeChartProps(
            width: area.width,
            height: area.height,
            title: '8/9 — Gauge Chart',
            value: 72,
            min: 0,
            max: 100,
            label: 'Performance Score',
            showValue: true,
            thresholds: const [
              GaugeThreshold(value: 0.4, color: '#F44336'),
              GaugeThreshold(value: 0.7, color: '#FFC107'),
              GaugeThreshold(value: 1.0, color: '#4CAF50'),
            ],
            backgroundColor: _bg,
          ),
        );
      case 8:
        renderSparklineChart(
          screen,
          area,
          SparklineProps(
            width: area.width,
            height: area.height,
            data: _sparkData,
            color: '#4FC3F7',
            style: SparklineStyle.line,
            showMinMax: true,
            title: '9/9 — Sparkline',
            backgroundColor: _bg,
          ),
        );
      default:
        break;
    }
  };
}

ChartPainter _gridChart(int index, math.Random rng) {
  return (screen, area) {
    switch (index) {
      case 0:
        renderLineChart(
          screen,
          area,
          LineChartProps(
            width: area.width,
            height: area.height,
            title: '1 — Line',
            series: _lineSeries,
            showDots: true,
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 1:
        renderBarChart(
          screen,
          area,
          BarChartProps(
            width: area.width,
            height: area.height,
            title: '2 — Bar',
            series: _barSeries,
            labels: _barLabels,
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 2:
        renderPieChart(
          screen,
          area,
          PieChartProps(
            width: area.width,
            height: area.height,
            title: '3 — Pie',
            slices: _pieSlicesShort,
            showPercentages: true,
            backgroundColor: _bg,
          ),
        );
      case 3:
        renderScatterChart(
          screen,
          area,
          ScatterChartProps(
            width: area.width,
            height: area.height,
            title: '4 — Scatter',
            points: _scatterPoints(rng),
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 4:
        renderAreaChart(
          screen,
          area,
          AreaChartProps(
            width: area.width,
            height: area.height,
            title: '5 — Area',
            series: _areaSeries,
            stacked: true,
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 5:
        renderStackedBarChart(
          screen,
          area,
          StackedBarChartProps(
            width: area.width,
            height: area.height,
            title: '6 — Stacked',
            series: _stackedSeries,
            labels: const ['S1', 'S2', 'S3', 'S4', 'S5'],
            grid: const GridOptions(show: true),
            backgroundColor: _bg,
          ),
        );
      case 6:
        renderHeatmapChart(
          screen,
          area,
          HeatmapChartProps(
            width: area.width,
            height: area.height,
            title: '7 — Heatmap',
            data: _heatmapData,
            xLabels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            yLabels: const ['W1', 'W2', 'W3', 'W4', 'W5'],
            showValues: false,
            backgroundColor: _bg,
          ),
        );
      case 7:
        renderGaugeChart(
          screen,
          area,
          GaugeChartProps(
            width: area.width,
            height: area.height,
            title: '8 — Gauge',
            value: 72,
            min: 0,
            max: 100,
            label: 'Score',
            showValue: true,
            thresholds: const [
              GaugeThreshold(value: 0.4, color: '#F44336'),
              GaugeThreshold(value: 0.7, color: '#FFC107'),
              GaugeThreshold(value: 1.0, color: '#4CAF50'),
            ],
            backgroundColor: _bg,
          ),
        );
      case 8:
        renderSparklineChart(
          screen,
          area,
          SparklineProps(
            width: area.width,
            height: area.height,
            data: _sparkData,
            color: '#4FC3F7',
            style: SparklineStyle.line,
            showMinMax: true,
            title: '9 — Sparkline',
            backgroundColor: _bg,
          ),
        );
      default:
        break;
    }
  };
}

// ─── App ─────────────────────────────────────────────────────────────────────

class _DemoAllApp extends StatefulWidget {
  _DemoAllApp();

  @override
  State createState() => _DemoAllAppState();
}

class _DemoAllAppState extends State<_DemoAllApp> {
  /// `-1` overview, `0..8` full-screen chart.
  int _currentIdx = _overview;
  final _rng = math.Random(42);

  void _next() {
    setState(() {
      _currentIdx = _currentIdx == _total - 1 ? _overview : _currentIdx + 1;
    });
  }

  void _prev() {
    setState(() {
      _currentIdx = _currentIdx == _overview ? _total - 1 : _currentIdx - 1;
    });
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.InterruptMsg) return tui.Cmd.quit();
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.ctrl && key.isChar('c')) return tui.Cmd.quit();
      if (key.isChar('q') || key.isChar('Q')) return tui.Cmd.quit();
      if (key.type == tui.KeyType.right ||
          key.isSpaceLike ||
          key.isEnterLike) {
        _next();
        return null;
      }
      if (key.type == tui.KeyType.left) {
        _prev();
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final termW = math.max(40, media?.size.width.round() ?? 80);
    final termH = math.max(16, media?.size.height.round() ?? 24);

    // Match bun demo-all.ts sizing.
    const gridCols = 3;
    const gridRows = 3;
    const gridPad = 1;
    final gridCellW =
        (termW - gridPad * (gridCols + 1)) ~/ gridCols;
    final gridCellH =
        (termH - gridPad * (gridRows + 1) - 1) ~/ gridRows;

    final fullW = math.min(termW - 4, 80);
    final fullH = math.min(termH - 4, 24);

    final hintStyle = Style()..foreground(Colors.gray);
    final bg = Color.basic('#0D1117');

    final footer = Text(
      '←/→ or SPACE to navigate  |  q / Ctrl+C to exit',
      style: hintStyle,
    );

    if (_currentIdx == _overview) {
      // 3×3 overview grid — same layout math as demo-all.ts.
      final cells = <Widget>[];
      for (var row = 0; row < gridRows; row++) {
        final rowChildren = <Widget>[];
        for (var col = 0; col < gridCols; col++) {
          final i = row * gridCols + col;
          rowChildren.add(
            SizedBox(
              width: gridCellW.toDouble(),
              height: gridCellH.toDouble(),
              child: CustomChart(
                width: gridCellW,
                height: gridCellH,
                painter: _gridChart(i, _rng),
              ),
            ),
          );
          if (col < gridCols - 1) {
            rowChildren.add(SizedBox(width: gridPad.toDouble()));
          }
        }
        cells.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        );
        if (row < gridRows - 1) {
          cells.add(SizedBox(height: gridPad.toDouble()));
        }
      }

      return Container(
        color: bg,
        padding: const EdgeInsets.all(gridPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cells,
              ),
            ),
            footer,
          ],
        ),
      );
    }

    // Full-screen individual chart (offset like left:2 top:2).
    return Container(
      color: bg,
      padding: const EdgeInsets.only(left: 2, top: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomChart(
              width: fullW,
              height: fullH,
              painter: _fullChart(_currentIdx, _rng),
            ),
          ),
          footer,
        ],
      ),
    );
  }
}
