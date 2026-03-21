part of 'chart_widgets.dart';

/// A compact sparkline widget rendered with Unicode block characters.
///
/// Displays a single row of proportional vertical bars representing the
/// data in [values]. The chart occupies the full [width]×[height] area.
///
/// ```dart
/// SparklineChart(
///   values: [10, 20, 15, 30, 25, 18],
///   width: 40,
///   height: 1,
///   style: UvStyle(fg: UvColor.rgb(0, 200, 100)),
/// )
///
/// // With gradient coloring:
/// SparklineChart(
///   values: [1, 5, 3, 8, 2],
///   width: 20,
///   gradientLow: UvStyle(fg: UvColor.rgb(0, 0, 200)),
///   gradientHigh: UvStyle(fg: UvColor.rgb(200, 0, 0)),
/// )
/// ```
class SparklineChart extends LeafRenderObjectWidget {
  /// Creates a [SparklineChart] with the given data and dimensions.
  ///
  /// When [width] or [height] is null the chart fills the available
  /// constraint space (responsive mode).
  ///
  /// Set [crosshairX] and [crosshairY] to draw a crosshair overlay at
  /// that position (e.g. from mouse hover).
  ///
  /// [baseline] controls the value below which columns render as empty
  /// (default: 0.0). [minValue]/[maxValue] allow explicit bounds for
  /// consistent scaling across multiple sparklines.
  ///
  /// [gradientLow] and [gradientHigh] enable per-column color
  /// interpolation based on value.
  SparklineChart({
    required this.values,
    this.width,
    this.height,
    this.style,
    this.showGrid = false,
    this.gridStyle,
    this.legendEntries,
    this.legendColumns = 1,
    this.legendRowGap = 0,
    this.legendPosition = ChartLegendPosition.topRight,
    this.legendPadding = 1,
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
    this.baseline = 0.0,
    this.minValue,
    this.maxValue,
    this.gradientLow,
    this.gradientHigh,
    super.key,
  });

  /// The data values to render.
  final List<double> values;

  /// The chart width in terminal columns, or null to fill available space.
  final int? width;

  /// The chart height in terminal rows, or null to fill available space.
  final int? height;

  /// Style for the sparkline characters.
  final UvStyle? style;

  /// Whether to draw a horizontal baseline.
  final bool showGrid;

  /// Style for the baseline grid.
  final UvStyle? gridStyle;

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

  /// X coordinate for crosshair overlay, or null to hide.
  final int? crosshairX;

  /// Y coordinate for crosshair overlay, or null to hide.
  final int? crosshairY;

  /// Style for the crosshair lines.
  final UvStyle? crosshairStyle;

  /// Values at or below this render as empty columns (default: 0.0).
  final double baseline;

  /// Explicit minimum bound for scaling. Auto-detected when null.
  final double? minValue;

  /// Explicit maximum bound for scaling. Auto-detected when null.
  final double? maxValue;

  /// Low-end style for gradient coloring (paired with [gradientHigh]).
  final UvStyle? gradientLow;

  /// High-end style for gradient coloring (paired with [gradientLow]).
  final UvStyle? gradientHigh;

  @override
  RenderObject createRenderObject() {
    return _RenderSparklineChart(
      values: values,
      chartWidth: width,
      chartHeight: height,
      style: style ?? const UvStyle(),
      showGrid: showGrid,
      gridStyle: gridStyle ?? const UvStyle(),
      legendEntries: legendEntries,
      legendColumns: legendColumns,
      legendRowGap: legendRowGap,
      legendPosition: legendPosition,
      legendPadding: legendPadding,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
      baseline: baseline,
      minValue: minValue,
      maxValue: maxValue,
      gradientLow: gradientLow,
      gradientHigh: gradientHigh,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderSparklineChart;
    ro
      ..values = values
      ..chartWidth = width
      ..chartHeight = height
      ..style = style ?? const UvStyle()
      ..showGrid = showGrid
      ..gridStyle = gridStyle ?? const UvStyle()
      ..legendEntries = legendEntries
      ..legendColumns = legendColumns
      ..legendRowGap = legendRowGap
      ..legendPosition = legendPosition
      ..legendPadding = legendPadding
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle
      ..baseline = baseline
      ..minValue = minValue
      ..maxValue = maxValue
      ..gradientLow = gradientLow
      ..gradientHigh = gradientHigh;
  }

  @override
  Object view() => _renderSparkline(
    values,
    width ?? 40,
    height ?? 1,
    style ?? const UvStyle(),
    showGrid,
    gridStyle ?? const UvStyle(),
    legendEntries,
    legendColumns,
    legendRowGap,
    legendPosition,
    legendPadding,
    baseline: baseline,
    minValue: minValue,
    maxValue: maxValue,
    gradientLow: gradientLow,
    gradientHigh: gradientHigh,
  );
}

class _RenderSparklineChart extends RenderBox {
  _RenderSparklineChart({
    required this.values,
    required this.chartWidth,
    required this.chartHeight,
    required this.style,
    required this.showGrid,
    required this.gridStyle,
    required this.legendEntries,
    required this.legendColumns,
    required this.legendRowGap,
    required this.legendPosition,
    required this.legendPadding,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
    required this.baseline,
    required this.minValue,
    required this.maxValue,
    required this.gradientLow,
    required this.gradientHigh,
  });

  List<double> values;
  int? chartWidth;
  int? chartHeight;
  UvStyle style;
  bool showGrid;
  UvStyle gridStyle;
  List<ChartLegendEntry>? legendEntries;
  int legendColumns;
  int legendRowGap;
  ChartLegendPosition legendPosition;
  int legendPadding;
  int? crosshairX;
  int? crosshairY;
  UvStyle? crosshairStyle;
  double baseline;
  double? minValue;
  double? maxValue;
  UvStyle? gradientLow;
  UvStyle? gradientHigh;
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
      1,
    );
    _lastPaint = _renderSparkline(
      values,
      w,
      h,
      style,
      showGrid,
      gridStyle,
      legendEntries,
      legendColumns,
      legendRowGap,
      legendPosition,
      legendPadding,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
      baseline: baseline,
      minValue: minValue,
      maxValue: maxValue,
      gradientLow: gradientLow,
      gradientHigh: gradientHigh,
    );
    size = constraints.constrain(Size(w.toDouble(), h.toDouble()));
  }

  @override
  String paint() {
    return _lastPaint ??
        _renderSparkline(
          values,
          chartWidth ?? 40,
          chartHeight ?? 1,
          style,
          showGrid,
          gridStyle,
          legendEntries,
          legendColumns,
          legendRowGap,
          legendPosition,
          legendPadding,
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
          baseline: baseline,
          minValue: minValue,
          maxValue: maxValue,
          gradientLow: gradientLow,
          gradientHigh: gradientHigh,
        );
  }
}

String _renderSparkline(
  List<double> values,
  int width,
  int height,
  UvStyle style,
  bool showGrid,
  UvStyle gridStyle,
  List<ChartLegendEntry>? legendEntries,
  int legendColumns,
  int legendRowGap,
  ChartLegendPosition legendPosition,
  int legendPadding, {
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
  double baseline = 0.0,
  double? minValue,
  double? maxValue,
  UvStyle? gradientLow,
  UvStyle? gradientHigh,
}) {
  if (width <= 0 || height <= 0) return '';
  final canvas = Canvas(width, height);
  final area = rect(0, 0, width, height);
  drawSparkline(
    canvas,
    area,
    values,
    style: style,
    showGrid: showGrid,
    gridStyle: gridStyle,
    baseline: baseline,
    minValue: minValue,
    maxValue: maxValue,
    gradientLow: gradientLow,
    gradientHigh: gradientHigh,
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
