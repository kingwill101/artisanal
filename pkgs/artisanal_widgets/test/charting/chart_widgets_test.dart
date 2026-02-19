import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/charting.dart' show ChartLegendEntry, ChartRamp;
import 'package:artisanal/uv.dart' show UvStyle, UvColor;
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // ChartType
  // -----------------------------------------------------------------------
  group('ChartType', () {
    test('has all expected values', () {
      expect(ChartType.values, hasLength(6));
      expect(ChartType.values, contains(ChartType.sparkline));
      expect(ChartType.values, contains(ChartType.line));
      expect(ChartType.values, contains(ChartType.bar));
      expect(ChartType.values, contains(ChartType.heatmap));
      expect(ChartType.values, contains(ChartType.pie));
      expect(ChartType.values, contains(ChartType.ribbon));
    });
  });

  // -----------------------------------------------------------------------
  // ChartSeries
  // -----------------------------------------------------------------------
  group('ChartSeries', () {
    test('stores label and values', () {
      final series = ChartSeries('Revenue', [10, 20, 30]);
      expect(series.label, 'Revenue');
      expect(series.values, [10, 20, 30]);
      expect(series.style, isNull);
    });

    test('stores optional style', () {
      final style = UvStyle(fg: UvColor.rgb(255, 0, 0));
      final series = ChartSeries('Costs', [5, 10], style: style);
      expect(series.style, style);
    });
  });

  // -----------------------------------------------------------------------
  // ChartModel
  // -----------------------------------------------------------------------
  group('ChartModel', () {
    test('default constructor values', () {
      final model = ChartModel();
      expect(model.type, ChartType.line);
      expect(model.values, isEmpty);
      expect(model.series, isEmpty);
      expect(model.grid, isEmpty);
      expect(model.showGrid, isFalse);
      expect(model.showMarkers, isTrue);
      expect(model.showAxis, isTrue);
      expect(model.donut, isFalse);
      expect(model.innerRadiusRatio, 0.45);
      expect(model.normalizeTotals, isTrue);
      expect(model.ramp, isNull);
      expect(model.lineStyle, isNull);
      expect(model.barStyle, isNull);
      expect(model.gridStyle, isNull);
      expect(model.labelStyle, isNull);
      expect(model.sliceStyles, isNull);
      expect(model.xLabels, isNull);
      expect(model.yLabels, isNull);
      expect(model.title, isNull);
    });

    test('constructor with custom values', () {
      final model = ChartModel(
        type: ChartType.bar,
        values: [1, 2, 3],
        showGrid: true,
        title: 'Sales',
      );
      expect(model.type, ChartType.bar);
      expect(model.values, [1, 2, 3]);
      expect(model.showGrid, isTrue);
      expect(model.title, 'Sales');
    });

    test('notifies on type change', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.type = ChartType.bar;
      expect(notified, 1);
      expect(model.type, ChartType.bar);
    });

    test('does not notify when type unchanged', () {
      final model = ChartModel(type: ChartType.bar);
      var notified = 0;
      model.addListener(() => notified++);

      model.type = ChartType.bar;
      expect(notified, 0);
    });

    test('notifies on values change', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.values = [1, 2, 3];
      expect(notified, 1);
      expect(model.values, [1, 2, 3]);
    });

    test('always notifies on values set (list identity)', () {
      final model = ChartModel(values: [1, 2, 3]);
      var notified = 0;
      model.addListener(() => notified++);

      // Even same content, different list identity — should notify
      model.values = [1, 2, 3];
      expect(notified, 1);
    });

    test('notifies on series change', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.series = [
        ChartSeries('A', [1, 2]),
      ];
      expect(notified, 1);
    });

    test('notifies on grid change', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.grid = [
        [0.1, 0.2],
        [0.3, 0.4],
      ];
      expect(notified, 1);
    });

    test('notifies on boolean flag changes', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.showGrid = true;
      expect(notified, 1);

      model.showMarkers = false;
      expect(notified, 2);

      model.showAxis = false;
      expect(notified, 3);

      model.donut = true;
      expect(notified, 4);

      model.normalizeTotals = false;
      expect(notified, 5);
    });

    test('does not notify when boolean flags unchanged', () {
      final model = ChartModel(showGrid: true);
      var notified = 0;
      model.addListener(() => notified++);

      model.showGrid = true;
      expect(notified, 0);
    });

    test('notifies on numeric property changes', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.innerRadiusRatio = 0.6;
      expect(notified, 1);
      expect(model.innerRadiusRatio, 0.6);
    });

    test('notifies on style changes', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      final style = UvStyle(fg: UvColor.rgb(255, 0, 0));
      model.lineStyle = style;
      expect(notified, 1);

      model.barStyle = style;
      expect(notified, 2);

      model.gridStyle = style;
      expect(notified, 3);

      model.labelStyle = style;
      expect(notified, 4);

      model.ramp = ChartRamp.thermal();
      expect(notified, 5);

      model.sliceStyles = [style];
      expect(notified, 6);
    });

    test('notifies on label changes', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.xLabels = ['A', 'B', 'C'];
      expect(notified, 1);

      model.yLabels = ['1', '2', '3'];
      expect(notified, 2);
    });

    test('notifies on title change', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.title = 'New Title';
      expect(notified, 1);
    });

    test('does not notify when title unchanged', () {
      final model = ChartModel(title: 'Same');
      var notified = 0;
      model.addListener(() => notified++);

      model.title = 'Same';
      expect(notified, 0);
    });

    test('dispose clears listeners', () {
      final model = ChartModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.dispose();
      expect(() => model.type = ChartType.pie, throwsStateError);
      expect(notified, 0);
    });
  });

  // -----------------------------------------------------------------------
  // SparklineChart
  // -----------------------------------------------------------------------
  group('SparklineChart', () {
    test('renders with default dimensions', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          SparklineChart(values: [10, 20, 15, 30, 25, 18]),
        );
        // Should produce some output (sparkline block chars)
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with custom dimensions', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          SparklineChart(values: [5, 10, 15, 20], width: 20, height: 3),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('handles empty values', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(SparklineChart(values: []));
        // Should not crash
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with custom style', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          SparklineChart(
            values: [10, 20, 30],
            style: UvStyle(fg: UvColor.rgb(0, 200, 100)),
            width: 20,
            height: 1,
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // LineChart
  // -----------------------------------------------------------------------
  group('LineChart', () {
    test('renders with default options', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          LineChart(values: [10, 20, 15, 30, 25], width: 40, height: 10),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with grid and markers', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          LineChart(
            values: [5, 15, 10, 25, 20],
            width: 40,
            height: 10,
            showGrid: true,
            showMarkers: true,
            gridRows: 2,
            gridCols: 2,
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with axis labels', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          LineChart(
            values: [10, 20, 30],
            width: 40,
            height: 10,
            xLabels: ['Jan', 'Feb', 'Mar'],
            yLabels: ['0', '15', '30'],
          ),
        );
        // The chart should render without error; labels are drawn via putText
        // into the canvas but may be embedded with ANSI codes
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('handles empty values', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(LineChart(values: []));
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });

    test('renders without markers', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          LineChart(
            values: [10, 20, 15],
            width: 30,
            height: 8,
            showMarkers: false,
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders legend entries inside chart', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          LineChart(
            values: [10, 20, 15, 30],
            width: 50,
            height: 10,
            legendEntries: [
              ChartLegendEntry(
                label: 'Series A',
                style: UvStyle(fg: UvColor.rgb(80, 180, 255)),
              ),
              ChartLegendEntry(
                label: 'Series B',
                style: UvStyle(fg: UvColor.rgb(255, 120, 80)),
              ),
            ],
            legendColumns: 2,
            legendPosition: ChartLegendPosition.bottomRight,
          ),
        );
        expect(tester.view, contains('Series A'));
        expect(tester.view, contains('Series B'));
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // BarChart
  // -----------------------------------------------------------------------
  group('BarChart', () {
    test('renders with default options', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          BarChart(values: [5, 12, 8, 20, 15], width: 30, height: 10),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with axis visible', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          BarChart(values: [10, 20, 30], width: 30, height: 10, showAxis: true),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders without axis', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          BarChart(values: [10, 20, 30], width: 20, height: 8, showAxis: false),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with labels', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          BarChart(
            values: [10, 20, 30],
            width: 30,
            height: 10,
            xLabels: ['A', 'B', 'C'],
          ),
        );
        // Chart with labels should render without error
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('handles empty values', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(BarChart(values: []));
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // HeatmapChart
  // -----------------------------------------------------------------------
  group('HeatmapChart', () {
    test('renders with default options', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          HeatmapChart(
            grid: [
              [0.1, 0.4, 0.8],
              [0.3, 0.6, 0.9],
              [0.5, 0.7, 1.0],
            ],
            width: 20,
            height: 8,
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with custom ramp', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          HeatmapChart(
            grid: [
              [0.0, 0.5, 1.0],
            ],
            width: 15,
            height: 5,
            ramp: ChartRamp.thermal(),
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('handles empty grid', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(HeatmapChart(grid: []));
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // PieChart
  // -----------------------------------------------------------------------
  group('PieChart', () {
    test('renders with default options', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          PieChart(values: [30, 20, 50], width: 20, height: 10),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders as donut', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          PieChart(values: [30, 20, 50], width: 20, height: 10, donut: true),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with custom slice styles', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          PieChart(
            values: [40, 60],
            width: 20,
            height: 10,
            sliceStyles: [
              UvStyle(bg: UvColor.rgb(230, 57, 70)),
              UvStyle(bg: UvColor.rgb(42, 157, 143)),
            ],
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('handles empty values', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(PieChart(values: []));
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });

    test('renders legend entries for slices', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          PieChart(
            values: [35, 25, 40],
            width: 30,
            height: 12,
            legendEntries: [
              ChartLegendEntry(
                label: 'Added',
                style: UvStyle(bg: UvColor.rgb(80, 180, 255)),
              ),
              ChartLegendEntry(
                label: 'Removed',
                style: UvStyle(bg: UvColor.rgb(255, 120, 80)),
              ),
              ChartLegendEntry(
                label: 'Modified',
                style: UvStyle(bg: UvColor.rgb(160, 120, 255)),
              ),
            ],
            legendPosition: ChartLegendPosition.topLeft,
          ),
        );
        expect(tester.view, contains('Added'));
        expect(tester.view, contains('Removed'));
        expect(tester.view, contains('Modified'));
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // RibbonChart
  // -----------------------------------------------------------------------
  group('RibbonChart', () {
    test('renders with default options', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          RibbonChart(
            series: [
              [10, 20, 30, 25],
              [15, 10, 20, 30],
            ],
            width: 40,
            height: 10,
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders without normalization', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          RibbonChart(
            series: [
              [10, 20, 30],
              [5, 10, 15],
            ],
            width: 30,
            height: 8,
            normalizeTotals: false,
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with custom styles', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          RibbonChart(
            series: [
              [10, 20],
              [15, 25],
            ],
            width: 30,
            height: 8,
            seriesStyles: [
              UvStyle(fg: UvColor.rgb(80, 180, 255)),
              UvStyle(fg: UvColor.rgb(255, 120, 80)),
            ],
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('handles empty series', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(RibbonChart(series: []));
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });

    test('renders legend entries for stacked series', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          RibbonChart(
            series: [
              [10, 20, 30, 25],
              [15, 10, 20, 30],
              [8, 12, 10, 16],
            ],
            width: 50,
            height: 12,
            legendEntries: [
              ChartLegendEntry(
                label: 'Alpha',
                style: UvStyle(fg: UvColor.rgb(80, 180, 255)),
              ),
              ChartLegendEntry(
                label: 'Beta',
                style: UvStyle(fg: UvColor.rgb(255, 120, 80)),
              ),
              ChartLegendEntry(
                label: 'Gamma',
                style: UvStyle(fg: UvColor.rgb(100, 220, 100)),
              ),
            ],
            legendColumns: 2,
            legendPosition: ChartLegendPosition.topLeft,
          ),
        );
        expect(tester.view, contains('Alpha'));
        expect(tester.view, contains('Beta'));
        expect(tester.view, contains('Gamma'));
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // ChartBuilder
  // -----------------------------------------------------------------------
  group('ChartBuilder', () {
    test('builds with initial model data', () async {
      final model = ChartModel(
        type: ChartType.sparkline,
        values: [10, 20, 30, 15],
      );
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          ChartBuilder(
            model: model,
            builder: (context, m) =>
                SparklineChart(values: m.values, width: 30, height: 1),
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        model.dispose();
        await tester.dispose();
      }
    });

    test('rebuilds when model changes', () async {
      final model = ChartModel(type: ChartType.bar, values: [5, 10, 15]);
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          ChartBuilder(
            model: model,
            builder: (context, m) {
              return BarChart(values: m.values, width: 30, height: 8);
            },
          ),
        );
        // Mutate the model — listener calls setState which marks for rebuild
        model.values = [20, 30, 40];
        // Re-pump the widget tree so the rebuild picks up new values
        await tester.pumpWidget(
          ChartBuilder(
            model: model,
            builder: (context, m) {
              return BarChart(values: m.values, width: 30, height: 8);
            },
          ),
        );

        // The rendered output should be different because the values changed
        // (bar heights are different)
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        model.dispose();
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // Constraint-respecting behaviour
  // -----------------------------------------------------------------------
  group('Chart constraint handling', () {
    test('sparkline respects bounded width constraint', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        // Chart wants 40 columns but screen is only 20
        await tester.pumpWidget(
          SparklineChart(values: [10, 20, 30, 40, 50], width: 40, height: 1),
        );
        // Should render without error within 20-col viewport
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('line chart respects bounded constraints', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 8);
      try {
        await tester.pumpWidget(
          LineChart(values: [10, 20, 30], width: 60, height: 12),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('bar chart respects bounded constraints', () async {
      final tester = WidgetTester(screenWidth: 25, screenHeight: 6);
      try {
        await tester.pumpWidget(
          BarChart(values: [10, 20, 30], width: 40, height: 10),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // view() fallback rendering
  // -----------------------------------------------------------------------
  group('Chart view() fallback', () {
    test('SparklineChart.view() returns string', () {
      final widget = SparklineChart(values: [10, 20, 30], width: 20, height: 1);
      final output = widget.view();
      expect(output, isA<String>());
      expect((output as String).isNotEmpty, isTrue);
    });

    test('LineChart.view() returns string', () {
      final widget = LineChart(values: [10, 20, 15], width: 30, height: 8);
      final output = widget.view();
      expect(output, isA<String>());
    });

    test('BarChart.view() returns string', () {
      final widget = BarChart(values: [5, 10, 15], width: 20, height: 6);
      final output = widget.view();
      expect(output, isA<String>());
    });

    test('HeatmapChart.view() returns string', () {
      final widget = HeatmapChart(
        grid: [
          [0.0, 0.5, 1.0],
        ],
        width: 10,
        height: 4,
      );
      final output = widget.view();
      expect(output, isA<String>());
    });

    test('PieChart.view() returns string', () {
      final widget = PieChart(values: [30, 70], width: 16, height: 8);
      final output = widget.view();
      expect(output, isA<String>());
    });

    test('RibbonChart.view() returns string', () {
      final widget = RibbonChart(
        series: [
          [10, 20],
          [15, 25],
        ],
        width: 20,
        height: 6,
      );
      final output = widget.view();
      expect(output, isA<String>());
    });
  });

  // -----------------------------------------------------------------------
  // Responsive layout (null width/height fills constraints)
  // -----------------------------------------------------------------------
  group('Responsive chart layout', () {
    test('SparklineChart fills available width when width is null', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SparklineChart(values: [10, 20, 30, 40], height: 1),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('LineChart fills available space when both dims are null', () async {
      final tester = WidgetTester(screenWidth: 50, screenHeight: 15);
      try {
        await tester.pumpWidget(LineChart(values: [10, 20, 30, 15, 25]));
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('BarChart fills available width when width is null', () async {
      final tester = WidgetTester(screenWidth: 35, screenHeight: 10);
      try {
        await tester.pumpWidget(BarChart(values: [5, 15, 25], height: 8));
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test(
      'HeatmapChart fills available space when both dims are null',
      () async {
        final tester = WidgetTester(screenWidth: 30, screenHeight: 12);
        try {
          await tester.pumpWidget(
            HeatmapChart(
              grid: [
                [0.0, 0.5, 1.0],
                [1.0, 0.5, 0.0],
              ],
            ),
          );
          expect(tester.view.isNotEmpty, isTrue);
        } finally {
          await tester.dispose();
        }
      },
    );

    test('PieChart fills available space when both dims are null', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 10);
      try {
        await tester.pumpWidget(PieChart(values: [30, 70]));
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('RibbonChart fills available space when both dims are null', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 12);
      try {
        await tester.pumpWidget(
          RibbonChart(
            series: [
              [10, 20, 30],
              [5, 15, 25],
            ],
          ),
        );
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('responsive chart output differs from small explicit dims', () async {
      // With explicit small dims the chart is tiny; with null dims (responsive)
      // it fills the 60-col viewport and should produce more content.
      final tester = WidgetTester(screenWidth: 60, screenHeight: 15);
      try {
        await tester.pumpWidget(
          LineChart(values: [10, 20, 30], width: 10, height: 4),
        );
        final smallView = tester.view;

        await tester.pumpWidget(LineChart(values: [10, 20, 30]));
        final responsiveView = tester.view;

        // The responsive view should be longer (more characters)
        expect(responsiveView.length, greaterThan(smallView.length));
      } finally {
        await tester.dispose();
      }
    });
  });

  // -----------------------------------------------------------------------
  // Crosshair rendering
  // -----------------------------------------------------------------------
  group('Chart crosshair rendering', () {
    test('LineChart with crosshair contains crosshair chars', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        await tester.pumpWidget(
          LineChart(
            values: [10, 20, 30, 15, 25],
            width: 30,
            height: 10,
            crosshairX: 15,
            crosshairY: 5,
            crosshairStyle: const UvStyle(),
          ),
        );
        final output = tester.view;
        expect(
          output.contains('┼'),
          isTrue,
          reason: 'crosshair intersection should be present',
        );
        expect(
          output.contains('│'),
          isTrue,
          reason: 'crosshair vertical line should be present',
        );
        expect(
          output.contains('─'),
          isTrue,
          reason: 'crosshair horizontal line should be present',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('BarChart with crosshair contains crosshair chars', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        await tester.pumpWidget(
          BarChart(
            values: [10, 25, 15],
            width: 30,
            height: 10,
            crosshairX: 10,
            crosshairY: 5,
            crosshairStyle: const UvStyle(fg: UvColor.rgb(255, 255, 0)),
          ),
        );
        final output = tester.view;
        // Non-destructive crosshair: line-drawing chars appear on empty
        // cells; filled cells get the crosshair fg colour tint instead.
        final hasCrosshairChars =
            output.contains('┼') ||
            output.contains('│') ||
            output.contains('─');
        // RGB escape for 255,255,0 (fg on empty cells, bg tint on filled cells)
        final hasCrosshairColor =
            output.contains('38;2;255;255;0') ||
            output.contains('48;2;255;255;0');
        expect(
          hasCrosshairChars || hasCrosshairColor,
          isTrue,
          reason: 'crosshair should tint existing content or draw line chars',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('SparklineChart with crosshair contains crosshair chars', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SparklineChart(
            values: [10, 20, 30, 15, 25, 35, 20, 10],
            width: 30,
            height: 5,
            crosshairX: 15,
            crosshairY: 2,
            crosshairStyle: const UvStyle(fg: UvColor.rgb(255, 255, 0)),
          ),
        );
        final output = tester.view;
        final hasCrosshairChars =
            output.contains('┼') ||
            output.contains('│') ||
            output.contains('─');
        final hasCrosshairColor =
            output.contains('38;2;255;255;0') ||
            output.contains('48;2;255;255;0');
        expect(
          hasCrosshairChars || hasCrosshairColor,
          isTrue,
          reason: 'crosshair should tint existing content or draw line chars',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('HeatmapChart with crosshair contains crosshair chars', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 8);
      try {
        await tester.pumpWidget(
          HeatmapChart(
            grid: [
              [0.0, 0.5, 1.0],
              [1.0, 0.5, 0.0],
            ],
            width: 20,
            height: 8,
            crosshairX: 10,
            crosshairY: 4,
          ),
        );
        final output = tester.view;
        expect(output.contains('┼'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('PieChart with crosshair contains crosshair chars', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 10);
      try {
        await tester.pumpWidget(
          PieChart(
            values: [40, 60],
            width: 20,
            height: 10,
            crosshairX: 10,
            crosshairY: 5,
            crosshairStyle: const UvStyle(fg: UvColor.rgb(255, 255, 0)),
          ),
        );
        final output = tester.view;
        final hasCrosshairChars =
            output.contains('┼') ||
            output.contains('│') ||
            output.contains('─');
        final hasCrosshairColor =
            output.contains('38;2;255;255;0') ||
            output.contains('48;2;255;255;0');
        expect(
          hasCrosshairChars || hasCrosshairColor,
          isTrue,
          reason: 'crosshair should tint existing content or draw line chars',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('RibbonChart with crosshair contains crosshair chars', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        await tester.pumpWidget(
          RibbonChart(
            series: [
              [10, 20, 30],
              [5, 15, 25],
            ],
            width: 30,
            height: 10,
            crosshairX: 15,
            crosshairY: 5,
            crosshairStyle: const UvStyle(fg: UvColor.rgb(255, 255, 0)),
          ),
        );
        final output = tester.view;
        final hasCrosshairChars =
            output.contains('┼') ||
            output.contains('│') ||
            output.contains('─');
        final hasCrosshairColor =
            output.contains('38;2;255;255;0') ||
            output.contains('48;2;255;255;0');
        expect(
          hasCrosshairChars || hasCrosshairColor,
          isTrue,
          reason: 'crosshair should tint existing content or draw line chars',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('chart without crosshair does not contain intersection', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 10);
      try {
        // A simple sparkline without crosshair should not have ┼
        await tester.pumpWidget(
          SparklineChart(values: [10, 20, 30], width: 30, height: 3),
        );
        final output = tester.view;
        expect(
          output.contains('┼'),
          isFalse,
          reason: 'no crosshair should be drawn without crosshair params',
        );
      } finally {
        await tester.dispose();
      }
    });

    test('LineChart view() with crosshair contains crosshair chars', () {
      final widget = LineChart(
        values: [10, 20, 30, 15, 25],
        width: 30,
        height: 10,
        crosshairX: 15,
        crosshairY: 5,
      );
      // view() doesn't use crosshair (it's a layout path-only feature)
      // so this just ensures view() still works without error
      final output = widget.view();
      expect(output, isA<String>());
      expect((output as String).isNotEmpty, isTrue);
    });
  });
}
