part of 'charting.dart';

/// Bar chart direction.
enum BarChartDirection {
  /// Bars grow upward from the bottom.
  vertical,

  /// Bars grow rightward from the left.
  horizontal,
}

/// Bar chart mode for multi-series data.
enum BarChartMode {
  /// Bars are placed side-by-side within each group.
  grouped,

  /// Bars are stacked on top of each other.
  stacked,
}

/// A bar chart widget supporting single or multi-series data.
///
/// Supports vertical/horizontal direction, grouped/stacked modes,
/// per-series styling, and group labels.
///
/// ```dart
/// // Single-series (backward-compatible)
/// BarChart(values: [5, 12, 8, 20], xLabels: ['A', 'B', 'C', 'D'])
///
/// // Multi-series grouped
/// BarChart(
///   series: [[42, 58, 35], [38, 45, 52], [55, 62, 48]],
///   barStyles: [style1, style2, style3],
///   xLabels: ['Q1', 'Q2', 'Q3'],
///   mode: BarChartMode.grouped,
/// )
///
/// // Horizontal stacked
/// BarChart(
///   series: [[10, 20], [15, 25]],
///   direction: BarChartDirection.horizontal,
///   mode: BarChartMode.stacked,
/// )
/// ```
class BarChart extends LeafRenderObjectWidget {
  BarChart({
    this.values,
    this.series,
    this.barStyles,
    this.direction = BarChartDirection.vertical,
    this.mode = BarChartMode.grouped,
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
    this.barWidth,
    this.barGap = 1,
    this.groupGap = 1,
    this.drawAxisLine = true,
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
    super.key,
  }) : assert(
         values != null || series != null,
         'Either values or series must be provided',
       );

  /// Single-series data values (backward-compatible).
  final List<double>? values;

  /// Multi-series data: list of value lists (one per series).
  final List<List<double>>? series;

  /// Per-series bar styles (cycled if shorter than series count).
  final List<UvStyle>? barStyles;

  /// Bar direction (vertical or horizontal).
  final BarChartDirection direction;

  /// Bar mode for multi-series data (grouped or stacked).
  final BarChartMode mode;

  final int? width;
  final int? height;
  final UvStyle? barStyle;
  final UvStyle? axisStyle;
  final UvStyle? gridStyle;
  final UvStyle? labelStyle;
  final bool showAxis;
  final bool showGrid;
  final int gridRows;
  final int gridCols;
  final List<String>? xLabels;
  final List<String>? yLabels;
  final List<ChartLegendEntry>? legendEntries;
  final int legendColumns;
  final int legendRowGap;
  final ChartLegendPosition legendPosition;
  final int legendPadding;
  final String barChar;
  final int? barWidth;
  final int barGap;
  final int groupGap;
  final bool drawAxisLine;
  final int? crosshairX;
  final int? crosshairY;
  final UvStyle? crosshairStyle;

  List<List<double>> get _effectiveSeries {
    if (series != null) return series!;
    if (values != null) return [values!];
    return [[]];
  }

  List<UvStyle> get _effectiveStyles {
    if (barStyles != null) return barStyles!;
    return [barStyle ?? const UvStyle()];
  }

  @override
  RenderObject createRenderObject() {
    return _RenderBarChart(
      series: _effectiveSeries,
      styles: _effectiveStyles,
      direction: direction,
      mode: mode,
      chartWidth: width,
      chartHeight: height,
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
      barWidth: barWidth,
      barGap: barGap,
      groupGap: groupGap,
      drawAxisLine: drawAxisLine,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderBarChart;
    ro
      ..series = _effectiveSeries
      ..styles = _effectiveStyles
      ..direction = direction
      ..mode = mode
      ..chartWidth = width
      ..chartHeight = height
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
      ..barWidth = barWidth
      ..barGap = barGap
      ..groupGap = groupGap
      ..drawAxisLine = drawAxisLine
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle;
  }

  @override
  Object view() => _renderBarChartString(
    _effectiveSeries,
    _effectiveStyles,
    direction,
    mode,
    width ?? 40,
    height ?? 10,
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
    barWidth,
    barGap,
    groupGap,
    drawAxisLine: drawAxisLine,
  );
}

class _RenderBarChart extends RenderBox {
  _RenderBarChart({
    required this.series,
    required this.styles,
    required this.direction,
    required this.mode,
    required this.chartWidth,
    required this.chartHeight,
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
    required this.barWidth,
    required this.barGap,
    required this.groupGap,
    required this.drawAxisLine,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<List<double>> series;
  List<UvStyle> styles;
  BarChartDirection direction;
  BarChartMode mode;
  int? chartWidth;
  int? chartHeight;
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
  int? barWidth;
  int barGap;
  int groupGap;
  bool drawAxisLine;
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
      series,
      styles,
      direction,
      mode,
      w,
      h,
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
      barWidth,
      barGap,
      groupGap,
      drawAxisLine: drawAxisLine,
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
          series,
          styles,
          direction,
          mode,
          chartWidth ?? 40,
          chartHeight ?? 10,
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
          barWidth,
          barGap,
          groupGap,
          drawAxisLine: drawAxisLine,
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
        );
  }
}

String _renderBarChartString(
  List<List<double>> series,
  List<UvStyle> styles,
  BarChartDirection direction,
  BarChartMode mode,
  int width,
  int height,
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
  int? barWidth,
  int barGap,
  int groupGap, {
  bool drawAxisLine = true,
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
}) {
  if (width <= 0 || height <= 0) return '';
  final canvas = Canvas(width, height);
  final area = rect(0, 0, width, height);

  if (series.length <= 1 && direction == BarChartDirection.vertical) {
    // Single-series vertical — use original drawHistogram for backward compat.
    drawHistogram(
      canvas,
      area,
      series.isNotEmpty ? series[0] : [],
      barStyle: styles.isNotEmpty ? styles[0] : const UvStyle(),
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
      barWidth: barWidth,
      barGap: barGap,
      drawAxisLine: drawAxisLine,
    );
  } else if (direction == BarChartDirection.vertical) {
    if (mode == BarChartMode.stacked) {
      drawStackedHistogram(
        canvas,
        area,
        series,
        styles: styles,
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
        barWidth: barWidth,
        barGap: barGap,
        groupGap: groupGap,
        drawAxisLine: drawAxisLine,
      );
    } else {
      drawGroupedHistogram(
        canvas,
        area,
        series,
        styles: styles,
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
        barWidth: barWidth,
        barGap: barGap,
        groupGap: groupGap,
        drawAxisLine: drawAxisLine,
      );
    }
  } else {
    // Horizontal
    if (mode == BarChartMode.stacked) {
      drawHorizontalStackedHistogram(
        canvas,
        area,
        series,
        styles: styles,
        axisStyle: axisStyle,
        gridStyle: gridStyle,
        labelStyle: labelStyle,
        showAxis: showAxis,
        showGrid: showGrid,
        gridRows: gridRows,
        gridCols: gridCols,
        yLabels: yLabels,
        barChar: barChar,
        barWidth: barWidth,
        barGap: barGap,
        groupGap: groupGap,
        drawAxisLine: drawAxisLine,
      );
    } else {
      drawHorizontalGroupedHistogram(
        canvas,
        area,
        series,
        styles: styles,
        axisStyle: axisStyle,
        gridStyle: gridStyle,
        labelStyle: labelStyle,
        showAxis: showAxis,
        showGrid: showGrid,
        gridRows: gridRows,
        gridCols: gridCols,
        yLabels: yLabels,
        barChar: barChar,
        barWidth: barWidth,
        barGap: barGap,
        groupGap: groupGap,
        drawAxisLine: drawAxisLine,
      );
    }
  }

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
