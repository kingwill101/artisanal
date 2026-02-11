part of 'chart_widgets.dart';

/// A 2D heatmap widget that maps grid values to colours via a [ChartRamp].
///
/// Each cell in the [grid] is expected to be in the `[0..1]` range and is
/// rendered as a coloured terminal cell.
///
/// ```dart
/// HeatmapChart(
///   grid: [
///     [0.1, 0.4, 0.8],
///     [0.3, 0.6, 0.9],
///     [0.5, 0.7, 1.0],
///   ],
///   width: 30,
///   height: 10,
///   ramp: ChartRamp.thermal(),
/// )
/// ```
class HeatmapChart extends LeafRenderObjectWidget {
  /// Creates a [HeatmapChart] with the given [grid] data and display options.
  ///
  /// When [width] or [height] is null the chart fills the available
  /// constraint space (responsive mode).
  ///
  /// Set [crosshairX] and [crosshairY] to draw a crosshair overlay at
  /// that position (e.g. from mouse hover).
  HeatmapChart({
    required this.grid,
    this.width,
    this.height,
    this.ramp,
    this.useBackground = true,
    this.glyph = ' ',
    this.showGrid = false,
    this.gridRows = 3,
    this.gridCols = 3,
    this.gridStyle,
    this.xLabels,
    this.yLabels,
    this.labelStyle,
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
    super.key,
  });

  /// The 2D array of values, each in `[0..1]`.
  final List<List<double>> grid;

  /// The chart width in terminal columns, or null to fill available space.
  final int? width;

  /// The chart height in terminal rows, or null to fill available space.
  final int? height;

  /// Colour ramp for value-to-colour mapping.
  ///
  /// Defaults to [ChartRamp.thermal()] if not specified.
  final ChartRamp? ramp;

  /// If true, applies colour as background; otherwise as foreground.
  final bool useBackground;

  /// Character placed in each cell (visible only when [useBackground] is false).
  final String glyph;

  /// Whether to draw a grid overlay.
  final bool showGrid;

  /// Number of horizontal grid lines.
  final int gridRows;

  /// Number of vertical grid lines.
  final int gridCols;

  /// Style for grid overlay lines.
  final UvStyle? gridStyle;

  /// Labels along the bottom (X) axis.
  final List<String>? xLabels;

  /// Labels along the left (Y) axis.
  final List<String>? yLabels;

  /// Style for axis labels.
  final UvStyle? labelStyle;

  /// X coordinate for crosshair overlay, or null to hide.
  final int? crosshairX;

  /// Y coordinate for crosshair overlay, or null to hide.
  final int? crosshairY;

  /// Style for the crosshair lines.
  final UvStyle? crosshairStyle;

  @override
  RenderObject createRenderObject() {
    return _RenderHeatmapChart(
      grid: grid,
      chartWidth: width,
      chartHeight: height,
      ramp: ramp,
      useBackground: useBackground,
      glyph: glyph,
      showGrid: showGrid,
      gridRows: gridRows,
      gridCols: gridCols,
      gridStyle: gridStyle ?? const UvStyle(),
      xLabels: xLabels,
      yLabels: yLabels,
      labelStyle: labelStyle ?? const UvStyle(),
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderHeatmapChart;
    ro
      ..grid = grid
      ..chartWidth = width
      ..chartHeight = height
      ..ramp = ramp
      ..useBackground = useBackground
      ..glyph = glyph
      ..showGrid = showGrid
      ..gridRows = gridRows
      ..gridCols = gridCols
      ..gridStyle = gridStyle ?? const UvStyle()
      ..xLabels = xLabels
      ..yLabels = yLabels
      ..labelStyle = labelStyle ?? const UvStyle()
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle;
  }

  @override
  Object view() => _renderHeatmapChartString(
    grid,
    width ?? 30,
    height ?? 10,
    ramp,
    useBackground,
    glyph,
    showGrid,
    gridRows,
    gridCols,
    gridStyle ?? const UvStyle(),
    xLabels,
    yLabels,
    labelStyle ?? const UvStyle(),
  );
}

class _RenderHeatmapChart extends RenderBox {
  _RenderHeatmapChart({
    required this.grid,
    required this.chartWidth,
    required this.chartHeight,
    required this.ramp,
    required this.useBackground,
    required this.glyph,
    required this.showGrid,
    required this.gridRows,
    required this.gridCols,
    required this.gridStyle,
    required this.xLabels,
    required this.yLabels,
    required this.labelStyle,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<List<double>> grid;
  int? chartWidth;
  int? chartHeight;
  ChartRamp? ramp;
  bool useBackground;
  String glyph;
  bool showGrid;
  int gridRows;
  int gridCols;
  UvStyle gridStyle;
  List<String>? xLabels;
  List<String>? yLabels;
  UvStyle labelStyle;
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
      30,
    );
    final h = _resolveAxis(
      chartHeight,
      constraints.hasBoundedHeight,
      constraints.maxHeight,
      10,
    );
    _lastPaint = _renderHeatmapChartString(
      grid,
      w,
      h,
      ramp,
      useBackground,
      glyph,
      showGrid,
      gridRows,
      gridCols,
      gridStyle,
      xLabels,
      yLabels,
      labelStyle,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
    size = constraints.constrain(Size(w.toDouble(), h.toDouble()));
  }

  @override
  String paint() {
    return _lastPaint ??
        _renderHeatmapChartString(
          grid,
          chartWidth ?? 30,
          chartHeight ?? 10,
          ramp,
          useBackground,
          glyph,
          showGrid,
          gridRows,
          gridCols,
          gridStyle,
          xLabels,
          yLabels,
          labelStyle,
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
        );
  }
}

String _renderHeatmapChartString(
  List<List<double>> grid,
  int width,
  int height,
  ChartRamp? ramp,
  bool useBackground,
  String glyph,
  bool showGrid,
  int gridRows,
  int gridCols,
  UvStyle gridStyle,
  List<String>? xLabels,
  List<String>? yLabels,
  UvStyle labelStyle, {
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
}) {
  if (width <= 0 || height <= 0) return '';
  final canvas = Canvas(width, height);
  final area = rect(0, 0, width, height);
  drawHeatmap(
    canvas,
    area,
    grid,
    ramp: ramp,
    useBackground: useBackground,
    glyph: glyph,
    showGrid: showGrid,
    gridRows: gridRows,
    gridCols: gridCols,
    gridStyle: gridStyle,
    xLabels: xLabels,
    yLabels: yLabels,
    labelStyle: labelStyle,
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
  return canvas.render();
}
