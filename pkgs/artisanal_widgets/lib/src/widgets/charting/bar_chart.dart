part of 'chart_widgets.dart';

/// A vertical bar chart (histogram) widget.
///
/// Each value is rendered as a column whose height is proportional to its
/// magnitude within the [width]×[height] area.
///
/// ```dart
/// BarChart(
///   values: [5, 12, 8, 20, 15],
///   width: 40,
///   height: 10,
///   showAxis: true,
///   barStyle: UvStyle(fg: UvColor.rgb(100, 200, 50)),
/// )
/// ```
class BarChart extends LeafRenderObjectWidget {
  /// Creates a [BarChart] with the given data and display options.
  ///
  /// When [width] or [height] is null the chart fills the available
  /// constraint space (responsive mode).
  ///
  /// Set [crosshairX] and [crosshairY] to draw a crosshair overlay at
  /// that position (e.g. from mouse hover).
  BarChart({
    required this.values,
    this.width,
    this.height,
    this.barStyle,
    this.axisStyle,
    this.gridStyle,
    this.labelStyle,
    this.showAxis = true,
    this.showGrid = false,
    this.gridRows = 3,
    this.gridCols = 0,
    this.xLabels,
    this.yLabels,
    this.legendEntries,
    this.legendColumns = 1,
    this.legendRowGap = 0,
    this.legendPosition = ChartLegendPosition.topRight,
    this.legendPadding = 1,
    this.barChar = '█',
    this.barGap = 1,
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
    super.key,
  });

  /// The data values to render as bars.
  final List<double> values;

  /// The chart width in terminal columns, or null to fill available space.
  final int? width;

  /// The chart height in terminal rows, or null to fill available space.
  final int? height;

  /// Style for the bar fill characters.
  final UvStyle? barStyle;

  /// Style for the bottom axis line.
  final UvStyle? axisStyle;

  /// Style for grid lines.
  final UvStyle? gridStyle;

  /// Style for axis labels.
  final UvStyle? labelStyle;

  /// Whether to draw a horizontal axis at the bottom.
  final bool showAxis;

  /// Whether to draw background grid lines.
  final bool showGrid;

  /// Number of horizontal grid lines.
  final int gridRows;

  /// Number of vertical grid lines.
  final int gridCols;

  /// Labels along the bottom (X) axis.
  final List<String>? xLabels;

  /// Labels along the left (Y) axis.
  final List<String>? yLabels;

  /// Optional legend entries rendered inside chart bounds.
  final List<ChartLegendEntry>? legendEntries;

  /// Number of legend columns.
  final int legendColumns;

  /// Empty rows inserted between legend rows.
  final int legendRowGap;

  /// Legend placement within chart bounds.
  final ChartLegendPosition legendPosition;

  /// Inner padding from chart edges to legend area.
  final int legendPadding;

  /// Character used to fill bar columns.
  final String barChar;

  /// Number of empty columns between adjacent bars.
  final int barGap;

  /// X coordinate for crosshair overlay, or null to hide.
  final int? crosshairX;

  /// Y coordinate for crosshair overlay, or null to hide.
  final int? crosshairY;

  /// Style for the crosshair lines.
  final UvStyle? crosshairStyle;

  @override
  RenderObject createRenderObject() {
    return _RenderBarChart(
      values: values,
      chartWidth: width,
      chartHeight: height,
      barStyle: barStyle ?? const UvStyle(),
      axisStyle: axisStyle ?? const UvStyle(),
      gridStyle: gridStyle ?? const UvStyle(),
      labelStyle: labelStyle ?? const UvStyle(),
      showAxis: showAxis,
      showGrid: showGrid,
      gridRows: gridRows,
      gridCols: gridCols,
      xLabels: xLabels,
      yLabels: yLabels,
      legendEntries: legendEntries,
      legendColumns: legendColumns,
      legendRowGap: legendRowGap,
      legendPosition: legendPosition,
      legendPadding: legendPadding,
      barChar: barChar,
      barGap: barGap,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderBarChart;
    ro
      ..values = values
      ..chartWidth = width
      ..chartHeight = height
      ..barStyle = barStyle ?? const UvStyle()
      ..axisStyle = axisStyle ?? const UvStyle()
      ..gridStyle = gridStyle ?? const UvStyle()
      ..labelStyle = labelStyle ?? const UvStyle()
      ..showAxis = showAxis
      ..showGrid = showGrid
      ..gridRows = gridRows
      ..gridCols = gridCols
      ..xLabels = xLabels
      ..yLabels = yLabels
      ..legendEntries = legendEntries
      ..legendColumns = legendColumns
      ..legendRowGap = legendRowGap
      ..legendPosition = legendPosition
      ..legendPadding = legendPadding
      ..barChar = barChar
      ..barGap = barGap
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle;
  }

  @override
  Object view() => _renderBarChartString(
    values,
    width ?? 40,
    height ?? 10,
    barStyle ?? const UvStyle(),
    axisStyle ?? const UvStyle(),
    gridStyle ?? const UvStyle(),
    labelStyle ?? const UvStyle(),
    showAxis,
    showGrid,
    gridRows,
    gridCols,
    xLabels,
    yLabels,
    legendEntries,
    legendColumns,
    legendRowGap,
    legendPosition,
    legendPadding,
    barChar,
    barGap,
  );
}

class _RenderBarChart extends RenderBox {
  _RenderBarChart({
    required this.values,
    required this.chartWidth,
    required this.chartHeight,
    required this.barStyle,
    required this.axisStyle,
    required this.gridStyle,
    required this.labelStyle,
    required this.showAxis,
    required this.showGrid,
    required this.gridRows,
    required this.gridCols,
    required this.xLabels,
    required this.yLabels,
    required this.legendEntries,
    required this.legendColumns,
    required this.legendRowGap,
    required this.legendPosition,
    required this.legendPadding,
    required this.barChar,
    required this.barGap,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<double> values;
  int? chartWidth;
  int? chartHeight;
  UvStyle barStyle;
  UvStyle axisStyle;
  UvStyle gridStyle;
  UvStyle labelStyle;
  bool showAxis;
  bool showGrid;
  int gridRows;
  int gridCols;
  List<String>? xLabels;
  List<String>? yLabels;
  List<ChartLegendEntry>? legendEntries;
  int legendColumns;
  int legendRowGap;
  ChartLegendPosition legendPosition;
  int legendPadding;
  String barChar;
  int barGap;
  int? crosshairX;
  int? crosshairY;
  UvStyle? crosshairStyle;
  String? _lastPaint;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final w = _resolveAxis(
      chartWidth,
      constraints.hasBoundedWidth,
      constraints.maxWidth,
      40,
    );
    final h = _resolveAxis(
      chartHeight,
      constraints.hasBoundedHeight,
      constraints.maxHeight,
      10,
    );
    _lastPaint = _renderBarChartString(
      values,
      w,
      h,
      barStyle,
      axisStyle,
      gridStyle,
      labelStyle,
      showAxis,
      showGrid,
      gridRows,
      gridCols,
      xLabels,
      yLabels,
      legendEntries,
      legendColumns,
      legendRowGap,
      legendPosition,
      legendPadding,
      barChar,
      barGap,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
    size = constraints.constrain(Size(w.toDouble(), h.toDouble()));
  }

  @override
  String paint() {
    return _lastPaint ??
        _renderBarChartString(
          values,
          chartWidth ?? 40,
          chartHeight ?? 10,
          barStyle,
          axisStyle,
          gridStyle,
          labelStyle,
          showAxis,
          showGrid,
          gridRows,
          gridCols,
          xLabels,
          yLabels,
          legendEntries,
          legendColumns,
          legendRowGap,
          legendPosition,
          legendPadding,
          barChar,
          barGap,
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
        );
  }
}

String _renderBarChartString(
  List<double> values,
  int width,
  int height,
  UvStyle barStyle,
  UvStyle axisStyle,
  UvStyle gridStyle,
  UvStyle labelStyle,
  bool showAxis,
  bool showGrid,
  int gridRows,
  int gridCols,
  List<String>? xLabels,
  List<String>? yLabels,
  List<ChartLegendEntry>? legendEntries,
  int legendColumns,
  int legendRowGap,
  ChartLegendPosition legendPosition,
  int legendPadding,
  String barChar,
  int barGap, {
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
}) {
  if (width <= 0 || height <= 0) return '';
  final canvas = Canvas(width, height);
  final area = rect(0, 0, width, height);
  drawHistogram(
    canvas,
    area,
    values,
    barStyle: barStyle,
    axisStyle: axisStyle,
    gridStyle: gridStyle,
    labelStyle: labelStyle,
    showAxis: showAxis,
    showGrid: showGrid,
    gridRows: gridRows,
    gridCols: gridCols,
    xLabels: xLabels,
    yLabels: yLabels,
    barChar: barChar,
    barGap: barGap,
  );
  if (crosshairX != null && crosshairY != null) {
    drawCrosshair(
      canvas,
      area,
      crosshairX,
      crosshairY,
      style: crosshairStyle ?? const UvStyle(),
    );
  }
  _drawLegendOverlay(
    canvas,
    area,
    legendEntries,
    columns: legendColumns,
    rowGap: legendRowGap,
    position: legendPosition,
    padding: legendPadding,
  );
  return canvas.render();
}
