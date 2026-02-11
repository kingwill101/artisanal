part of 'chart_widgets.dart';

/// A multi-point line chart widget with optional markers, grid, and axis labels.
///
/// Renders data as a connected series of points within the
/// [width]×[height] area.
///
/// ```dart
/// LineChart(
///   values: [10, 20, 15, 30, 25],
///   width: 60,
///   height: 12,
///   showGrid: true,
///   showMarkers: true,
///   lineStyle: UvStyle(fg: UvColor.rgb(80, 180, 255)),
/// )
/// ```
class LineChart extends LeafRenderObjectWidget {
  /// Creates a [LineChart] with the given data and display options.
  ///
  /// When [width] or [height] is null the chart fills the available
  /// constraint space (responsive mode).
  ///
  /// Set [crosshairX] and [crosshairY] to draw a crosshair overlay at
  /// that position (e.g. from mouse hover).
  LineChart({
    required this.values,
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
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
    super.key,
  });

  /// The data values to plot.
  final List<double> values;

  /// The chart width in terminal columns, or null to fill available space.
  final int? width;

  /// The chart height in terminal rows, or null to fill available space.
  final int? height;

  /// Style for the line and marker characters.
  final UvStyle? lineStyle;

  /// Style for grid lines.
  final UvStyle? gridStyle;

  /// Style for axis labels.
  final UvStyle? labelStyle;

  /// Whether to draw background grid lines.
  final bool showGrid;

  /// Number of horizontal grid lines.
  final int gridRows;

  /// Number of vertical grid lines.
  final int gridCols;

  /// Whether to draw markers at each data point.
  final bool showMarkers;

  /// Character used for data point markers.
  final String markerChar;

  /// Character used for interpolated line segments.
  final String lineChar;

  /// Labels along the bottom (X) axis.
  final List<String>? xLabels;

  /// Labels along the left (Y) axis.
  final List<String>? yLabels;

  /// X coordinate for crosshair overlay, or null to hide.
  final int? crosshairX;

  /// Y coordinate for crosshair overlay, or null to hide.
  final int? crosshairY;

  /// Style for the crosshair lines.
  final UvStyle? crosshairStyle;

  @override
  RenderObject createRenderObject() {
    return _RenderLineChart(
      values: values,
      chartWidth: width,
      chartHeight: height,
      lineStyle: lineStyle ?? const UvStyle(),
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
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderLineChart;
    ro
      ..values = values
      ..chartWidth = width
      ..chartHeight = height
      ..lineStyle = lineStyle ?? const UvStyle()
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
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle;
  }

  @override
  Object view() => _renderLineChartString(
    values,
    width ?? 60,
    height ?? 12,
    lineStyle ?? const UvStyle(),
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
  );
}

class _RenderLineChart extends RenderBox {
  _RenderLineChart({
    required this.values,
    required this.chartWidth,
    required this.chartHeight,
    required this.lineStyle,
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
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<double> values;
  int? chartWidth;
  int? chartHeight;
  UvStyle lineStyle;
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
      values,
      w,
      h,
      lineStyle,
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
          values,
          chartWidth ?? 60,
          chartHeight ?? 12,
          lineStyle,
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
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
        );
  }
}

String _renderLineChartString(
  List<double> values,
  int width,
  int height,
  UvStyle lineStyle,
  UvStyle gridStyle,
  UvStyle labelStyle,
  bool showGrid,
  int gridRows,
  int gridCols,
  bool showMarkers,
  String markerChar,
  String lineChar,
  List<String>? xLabels,
  List<String>? yLabels, {
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
}) {
  if (width <= 0 || height <= 0) return '';
  final canvas = Canvas(width, height);
  final area = rect(0, 0, width, height);
  drawLineChart(
    canvas,
    area,
    values,
    lineStyle: lineStyle,
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
