part of 'charting.dart';

/// A line chart widget supporting single or multi-series data.
///
/// Renders data as connected points using Braille sub-cell resolution.
/// Supports optional markers, grid, axis labels, and per-series styling.
///
/// ```dart
/// // Single-series (backward-compatible)
/// LineChart(values: [10, 20, 15, 30, 25], width: 60, height: 12)
///
/// // Multi-series with per-line colors
/// LineChart(
///   series: [sineValues, cosineValues, noiseValues],
///   lineStyles: [style1, style2, style3],
///   legendEntries: [
///     ChartLegendEntry('sin(t)', style1),
///     ChartLegendEntry('cos(t)', style2),
///     ChartLegendEntry('noise', style3),
///   ],
/// )
/// ```
class LineChart extends LeafRenderObjectWidget {
  LineChart({
    this.values,
    this.series,
    this.lineStyles,
    this.width,
    this.height,
    this.lineStyle,
    this.gridStyle,
    this.labelStyle,
    this.showGrid = false,
    this.gridRows = 3,
    this.gridCols = 3,
    this.showMarkers = true,
    this.markerChar = '●',
    this.lineChar = '•',
    this.xLabels,
    this.yLabels,
    this.minValue,
    this.maxValue,
    this.legendEntries,
    this.legendColumns = 1,
    this.legendRowGap = 0,
    this.legendPosition = ChartLegendPosition.topRight,
    this.legendPadding = 1,
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

  /// Per-series line styles (cycled if shorter than series count).
  final List<UvStyle>? lineStyles;

  final int? width;
  final int? height;
  final UvStyle? lineStyle;
  final UvStyle? gridStyle;
  final UvStyle? labelStyle;
  final bool showGrid;
  final int gridRows;
  final int gridCols;
  final bool showMarkers;
  final String markerChar;
  final String lineChar;
  final List<String>? xLabels;
  final List<String>? yLabels;
  final double? minValue;
  final double? maxValue;
  final List<ChartLegendEntry>? legendEntries;
  final int legendColumns;
  final int legendRowGap;
  final ChartLegendPosition legendPosition;
  final int legendPadding;
  final int? crosshairX;
  final int? crosshairY;
  final UvStyle? crosshairStyle;

  List<List<double>> get _effectiveSeries {
    if (series != null) return series!;
    if (values != null) return [values!];
    return [[]];
  }

  List<UvStyle> get _effectiveStyles {
    if (lineStyles != null) return lineStyles!;
    return [lineStyle ?? const UvStyle()];
  }

  @override
  RenderObject createRenderObject() {
    return _RenderLineChart(
      series: _effectiveSeries,
      styles: _effectiveStyles,
      chartWidth: width,
      chartHeight: height,
      gridStyle: gridStyle ?? const UvStyle(),
      labelStyle: labelStyle ?? const UvStyle(),
      showGrid: showGrid,
      gridRows: gridRows,
      gridCols: gridCols,
      showMarkers: showMarkers,
      markerChar: markerChar,
      lineChar: lineChar,
      xLabels: xLabels,
      yLabels: yLabels,
      minValue: minValue,
      maxValue: maxValue,
      legendEntries: legendEntries,
      legendColumns: legendColumns,
      legendRowGap: legendRowGap,
      legendPosition: legendPosition,
      legendPadding: legendPadding,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderLineChart;
    ro
      ..series = _effectiveSeries
      ..styles = _effectiveStyles
      ..chartWidth = width
      ..chartHeight = height
      ..gridStyle = gridStyle ?? const UvStyle()
      ..labelStyle = labelStyle ?? const UvStyle()
      ..showGrid = showGrid
      ..gridRows = gridRows
      ..gridCols = gridCols
      ..showMarkers = showMarkers
      ..markerChar = markerChar
      ..lineChar = lineChar
      ..xLabels = xLabels
      ..yLabels = yLabels
      ..minValue = minValue
      ..maxValue = maxValue
      ..legendEntries = legendEntries
      ..legendColumns = legendColumns
      ..legendRowGap = legendRowGap
      ..legendPosition = legendPosition
      ..legendPadding = legendPadding
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle;
  }

  @override
  Object view() => _renderLineChartString(
    _effectiveSeries,
    _effectiveStyles,
    width ?? 60,
    height ?? 12,
    gridStyle ?? const UvStyle(),
    labelStyle ?? const UvStyle(),
    showGrid,
    gridRows,
    gridCols,
    showMarkers,
    markerChar,
    lineChar,
    xLabels,
    yLabels,
    minValue,
    maxValue,
    legendEntries,
    legendColumns,
    legendRowGap,
    legendPosition,
    legendPadding,
  );
}

class _RenderLineChart extends RenderBox {
  _RenderLineChart({
    required this.series,
    required this.styles,
    required this.chartWidth,
    required this.chartHeight,
    required this.gridStyle,
    required this.labelStyle,
    required this.showGrid,
    required this.gridRows,
    required this.gridCols,
    required this.showMarkers,
    required this.markerChar,
    required this.lineChar,
    required this.xLabels,
    required this.yLabels,
    required this.minValue,
    required this.maxValue,
    required this.legendEntries,
    required this.legendColumns,
    required this.legendRowGap,
    required this.legendPosition,
    required this.legendPadding,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<List<double>> series;
  List<UvStyle> styles;
  int? chartWidth;
  int? chartHeight;
  UvStyle gridStyle;
  UvStyle labelStyle;
  bool showGrid;
  int gridRows;
  int gridCols;
  bool showMarkers;
  String markerChar;
  String lineChar;
  List<String>? xLabels;
  List<String>? yLabels;
  double? minValue;
  double? maxValue;
  List<ChartLegendEntry>? legendEntries;
  int legendColumns;
  int legendRowGap;
  ChartLegendPosition legendPosition;
  int legendPadding;
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
      60,
    );
    final h = _resolveAxis(
      chartHeight,
      constraints.hasBoundedHeight,
      constraints.maxHeight,
      12,
    );
    _lastPaint = _renderLineChartString(
      series,
      styles,
      w,
      h,
      gridStyle,
      labelStyle,
      showGrid,
      gridRows,
      gridCols,
      showMarkers,
      markerChar,
      lineChar,
      xLabels,
      yLabels,
      minValue,
      maxValue,
      legendEntries,
      legendColumns,
      legendRowGap,
      legendPosition,
      legendPadding,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
    size = constraints.constrain(Size(w.toDouble(), h.toDouble()));
  }

  @override
  String paint() {
    return _lastPaint ??
        _renderLineChartString(
          series,
          styles,
          chartWidth ?? 60,
          chartHeight ?? 12,
          gridStyle,
          labelStyle,
          showGrid,
          gridRows,
          gridCols,
          showMarkers,
          markerChar,
          lineChar,
          xLabels,
          yLabels,
          minValue,
          maxValue,
          legendEntries,
          legendColumns,
          legendRowGap,
          legendPosition,
          legendPadding,
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
        );
  }
}

String _renderLineChartString(
  List<List<double>> series,
  List<UvStyle> styles,
  int width,
  int height,
  UvStyle gridStyle,
  UvStyle labelStyle,
  bool showGrid,
  int gridRows,
  int gridCols,
  bool showMarkers,
  String markerChar,
  String lineChar,
  List<String>? xLabels,
  List<String>? yLabels,
  double? minValue,
  double? maxValue,
  List<ChartLegendEntry>? legendEntries,
  int legendColumns,
  int legendRowGap,
  ChartLegendPosition legendPosition,
  int legendPadding, {
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
}) {
  if (width <= 0 || height <= 0) return '';
  final canvas = Canvas(width, height);
  final area = rect(0, 0, width, height);

  if (series.length <= 1) {
    // Single-series backward-compatible path
    drawLineChart(
      canvas,
      area,
      series.isNotEmpty ? series[0] : [],
      lineStyle: styles.isNotEmpty ? styles[0] : const UvStyle(),
      gridStyle: gridStyle,
      labelStyle: labelStyle,
      showGrid: showGrid,
      gridRows: gridRows,
      gridCols: gridCols,
      showMarkers: showMarkers,
      markerChar: markerChar,
      lineChar: lineChar,
      xLabels: xLabels,
      yLabels: yLabels,
      minValue: minValue,
      maxValue: maxValue,
    );
  } else {
    drawMultiSeriesLineChart(
      canvas,
      area,
      series,
      styles: styles,
      gridStyle: gridStyle,
      labelStyle: labelStyle,
      showGrid: showGrid,
      gridRows: gridRows,
      gridCols: gridCols,
      showMarkers: showMarkers,
      markerChar: markerChar,
      xLabels: xLabels,
      yLabels: yLabels,
      minValue: minValue,
      maxValue: maxValue,
    );
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
