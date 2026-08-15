/// Core type definitions and drawing constants for OpenTUI-style charts.
library;

// ─── Data types ──────────────────────────────────────────────────────────────

/// A labeled numeric data point.
final class DataPoint {
  const DataPoint({required this.value, this.label});

  final double value;
  final String? label;
}

/// A named series of Y values for multi-series charts.
final class DataSeries {
  const DataSeries({required this.name, required this.data, this.color});

  final String name;
  final List<double> data;
  final String? color;
}

/// A labeled slice for pie charts.
final class PieSlice {
  const PieSlice({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final String? color;
}

/// An (x, y) point for scatter charts.
final class ScatterPoint {
  const ScatterPoint({
    required this.x,
    required this.y,
    this.label,
    this.color,
  });

  final double x;
  final double y;
  final String? label;
  final String? color;
}

/// A heatmap cell coordinate (optional convenience type).
final class HeatmapCell {
  const HeatmapCell({required this.x, required this.y, required this.value});

  final int x;
  final int y;
  final double value;
}

// ─── Chart options ───────────────────────────────────────────────────────────

/// Chart content margins in terminal cells.
final class ChartMargins {
  const ChartMargins({
    this.top = 2,
    this.right = 2,
    this.bottom = 2,
    this.left = 8,
  });

  final int top;
  final int right;
  final int bottom;
  final int left;

  ChartMargins copyWith({int? top, int? right, int? bottom, int? left}) {
    return ChartMargins(
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
    );
  }
}

/// Grid line stroke style.
enum GridStyle {
  solid,
  dotted,
  dashed,
}

/// Legend placement relative to the plot.
enum LegendPosition {
  top,
  bottom,
  right,
}

/// Line interpolation style for line charts.
enum LineStyle {
  straight,
  step,
}

/// Bar / stacked-bar orientation.
enum ChartOrientation {
  vertical,
  horizontal,
}

/// Compact sparkline rendering style.
enum SparklineStyle {
  line,
  bar,
  dot,
}

/// Optional border style for chart containers (UI chrome).
enum ChartBorderStyle {
  single,
  double,
  rounded,
  heavy,
}

/// Axis display options.
final class AxisOptions {
  const AxisOptions({
    this.show,
    this.label,
    this.color,
    this.tickCount,
    this.min,
    this.max,
    this.formatTick,
  });

  final bool? show;
  final String? label;
  final String? color;
  final int? tickCount;
  final double? min;
  final double? max;
  final String Function(double value)? formatTick;
}

/// Grid line options.
final class GridOptions {
  const GridOptions({this.show, this.color, this.style});

  final bool? show;
  final String? color;
  final GridStyle? style;
}

/// Legend options.
final class LegendOptions {
  const LegendOptions({this.show, this.position});

  final bool? show;
  final LegendPosition? position;
}

/// Shared props for full-frame charts.
final class BaseChartProps {
  const BaseChartProps({
    this.id,
    required this.width,
    required this.height,
    this.title,
    this.titleColor,
    this.backgroundColor,
    this.borderStyle,
    this.borderColor,
    this.margins,
    this.xAxis,
    this.yAxis,
    this.grid,
    this.legend,
    this.colors,
  });

  final String? id;
  final int width;
  final int height;
  final String? title;
  final String? titleColor;
  final String? backgroundColor;
  final ChartBorderStyle? borderStyle;
  final String? borderColor;
  final ChartMargins? margins;
  final AxisOptions? xAxis;
  final AxisOptions? yAxis;
  final GridOptions? grid;
  final LegendOptions? legend;
  final List<String>? colors;
}

/// Props for multi-series line charts.
final class LineChartProps extends BaseChartProps {
  const LineChartProps({
    super.id,
    required super.width,
    required super.height,
    super.title,
    super.titleColor,
    super.backgroundColor,
    super.borderStyle,
    super.borderColor,
    super.margins,
    super.xAxis,
    super.yAxis,
    super.grid,
    super.legend,
    super.colors,
    required this.series,
    this.showDots,
    this.dotChar,
    this.lineStyle,
    this.fillArea,
    this.maxPoints,
  });

  final List<DataSeries> series;
  final bool? showDots;
  final String? dotChar;
  final LineStyle? lineStyle;
  final bool? fillArea;
  final int? maxPoints;
}

/// Props for bar charts.
final class BarChartProps extends BaseChartProps {
  const BarChartProps({
    super.id,
    required super.width,
    required super.height,
    super.title,
    super.titleColor,
    super.backgroundColor,
    super.borderStyle,
    super.borderColor,
    super.margins,
    super.xAxis,
    super.yAxis,
    super.grid,
    super.legend,
    super.colors,
    required this.series,
    this.labels,
    this.barChar,
    this.orientation,
    this.grouped,
    this.barWidth,
    this.gap,
  });

  final List<DataSeries> series;
  final List<String>? labels;
  final String? barChar;
  final ChartOrientation? orientation;
  final bool? grouped;
  final int? barWidth;
  final int? gap;
}

/// Props for pie / donut charts.
final class PieChartProps {
  const PieChartProps({
    this.id,
    required this.width,
    required this.height,
    this.title,
    this.titleColor,
    this.backgroundColor,
    this.margins,
    this.legend,
    this.colors,
    required this.slices,
    this.radius,
    this.showPercentages,
    this.showLabels,
    this.donut,
    this.donutInnerRadius,
  });

  final String? id;
  final int width;
  final int height;
  final String? title;
  final String? titleColor;
  final String? backgroundColor;
  final ChartMargins? margins;
  final LegendOptions? legend;
  final List<String>? colors;
  final List<PieSlice> slices;
  final int? radius;
  final bool? showPercentages;
  final bool? showLabels;
  final bool? donut;
  final int? donutInnerRadius;
}

/// Props for scatter charts.
final class ScatterChartProps extends BaseChartProps {
  const ScatterChartProps({
    super.id,
    required super.width,
    required super.height,
    super.title,
    super.titleColor,
    super.backgroundColor,
    super.borderStyle,
    super.borderColor,
    super.margins,
    super.xAxis,
    super.yAxis,
    super.grid,
    super.legend,
    super.colors,
    required this.points,
    this.dotChar,
    this.defaultColor,
  });

  final List<ScatterPoint> points;
  final String? dotChar;
  final String? defaultColor;
}

/// Props for compact sparklines.
final class SparklineProps {
  const SparklineProps({
    this.id,
    required this.data,
    required this.width,
    this.height,
    this.color,
    this.showMinMax,
    this.style,
    this.title,
    this.titleColor,
    this.backgroundColor,
  });

  final String? id;
  final List<double> data;
  final int width;
  final int? height;
  final String? color;
  final bool? showMinMax;
  final SparklineStyle? style;
  final String? title;
  final String? titleColor;
  final String? backgroundColor;
}

/// A gauge threshold stop.
final class GaugeThreshold {
  const GaugeThreshold({required this.value, required this.color});

  /// Normalized 0..1 threshold upper bound.
  final double value;
  final String color;
}

/// Props for semicircular gauges.
final class GaugeChartProps {
  const GaugeChartProps({
    this.id,
    required this.width,
    required this.height,
    this.title,
    this.titleColor,
    this.backgroundColor,
    this.margins,
    this.colors,
    required this.value,
    this.min,
    this.max,
    this.label,
    this.thresholds,
    this.showValue,
    this.arcChar,
  });

  final String? id;
  final int width;
  final int height;
  final String? title;
  final String? titleColor;
  final String? backgroundColor;
  final ChartMargins? margins;
  final List<String>? colors;
  final double value;
  final double? min;
  final double? max;
  final String? label;
  final List<GaugeThreshold>? thresholds;
  final bool? showValue;
  final String? arcChar;
}

/// Props for heatmaps.
final class HeatmapChartProps extends BaseChartProps {
  const HeatmapChartProps({
    super.id,
    required super.width,
    required super.height,
    super.title,
    super.titleColor,
    super.backgroundColor,
    super.borderStyle,
    super.borderColor,
    super.margins,
    super.xAxis,
    super.yAxis,
    super.grid,
    super.legend,
    super.colors,
    required this.data,
    this.xLabels,
    this.yLabels,
    this.colorScale,
    this.showValues,
  });

  final List<List<double>> data;
  final List<String>? xLabels;
  final List<String>? yLabels;
  final List<String>? colorScale;
  final bool? showValues;
}

/// Props for filled area charts.
final class AreaChartProps extends BaseChartProps {
  const AreaChartProps({
    super.id,
    required super.width,
    required super.height,
    super.title,
    super.titleColor,
    super.backgroundColor,
    super.borderStyle,
    super.borderColor,
    super.margins,
    super.xAxis,
    super.yAxis,
    super.grid,
    super.legend,
    super.colors,
    required this.series,
    this.stacked,
    this.fillChar,
    this.showDots,
  });

  final List<DataSeries> series;
  final bool? stacked;
  final String? fillChar;
  final bool? showDots;
}

/// Props for stacked bar charts.
final class StackedBarChartProps extends BaseChartProps {
  const StackedBarChartProps({
    super.id,
    required super.width,
    required super.height,
    super.title,
    super.titleColor,
    super.backgroundColor,
    super.borderStyle,
    super.borderColor,
    super.margins,
    super.xAxis,
    super.yAxis,
    super.grid,
    super.legend,
    super.colors,
    required this.series,
    this.labels,
    this.barChar,
    this.orientation,
  });

  final List<DataSeries> series;
  final List<String>? labels;
  final String? barChar;
  final ChartOrientation? orientation;
}

// ─── Defaults ────────────────────────────────────────────────────────────────

/// Default multi-series color palette (hex).
const List<String> defaultColors = [
  '#4FC3F7',
  '#81C784',
  '#FFB74D',
  '#E57373',
  '#BA68C8',
  '#4DD0E1',
  '#FFD54F',
  '#F06292',
  '#AED581',
  '#90A4AE',
];

/// Default chart margins.
const ChartMargins defaultMargins = ChartMargins();

/// Block-drawing characters.
abstract final class Block {
  static const full = '█';
  static const sevenEighths = '▉';
  static const threeQuarters = '▊';
  static const fiveEighths = '▋';
  static const half = '▌';
  static const threeEighths = '▍';
  static const quarter = '▎';
  static const eighth = '▏';
  static const upperHalf = '▀';
  static const lowerHalf = '▄';
  static const shadeLight = '░';
  static const shadeMedium = '▒';
  static const shadeDark = '▓';
}

/// Braille base and bit layout.
abstract final class Braille {
  static const base = 0x2800;

  /// Dot bit masks: [col][row].
  static const dots = [
    [0x01, 0x02, 0x04, 0x40],
    [0x08, 0x10, 0x20, 0x80],
  ];
}

/// Box-drawing and marker characters.
abstract final class LineChars {
  static const horizontal = '─';
  static const vertical = '│';
  static const cornerTl = '┌';
  static const cornerTr = '┐';
  static const cornerBl = '└';
  static const cornerBr = '┘';
  static const teeLeft = '├';
  static const teeRight = '┤';
  static const teeTop = '┬';
  static const teeBottom = '┴';
  static const cross = '┼';
  static const dot = '●';
  static const smallDot = '·';
  static const diamond = '◆';
  static const triangleUp = '▲';
  static const triangleDown = '▼';
  static const arrowRight = '→';
  static const arrowUp = '↑';
}

/// Alternate pie fill characters.
const List<String> pieChars = [
  '█',
  '▓',
  '▒',
  '░',
  '▚',
  '▞',
  '◆',
  '●',
  '○',
  '◇',
];
