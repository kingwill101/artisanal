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
/// ```
class SparklineChart extends LeafRenderObjectWidget {
  /// Creates a [SparklineChart] with the given data and dimensions.
  ///
  /// When [width] or [height] is null the chart fills the available
  /// constraint space (responsive mode).
  ///
  /// Set [crosshairX] and [crosshairY] to draw a crosshair overlay at
  /// that position (e.g. from mouse hover).
  SparklineChart({
    required this.values,
    this.width,
    this.height,
    this.style,
    this.showGrid = false,
    this.gridStyle,
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
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

  /// X coordinate for crosshair overlay, or null to hide.
  final int? crosshairX;

  /// Y coordinate for crosshair overlay, or null to hide.
  final int? crosshairY;

  /// Style for the crosshair lines.
  final UvStyle? crosshairStyle;

  @override
  RenderObject createRenderObject() {
    return _RenderSparklineChart(
      values: values,
      chartWidth: width,
      chartHeight: height,
      style: style ?? const UvStyle(),
      showGrid: showGrid,
      gridStyle: gridStyle ?? const UvStyle(),
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
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
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle;
  }

  @override
  Object view() => _renderSparkline(
    values,
    width ?? 40,
    height ?? 1,
    style ?? const UvStyle(),
    showGrid,
    gridStyle ?? const UvStyle(),
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
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<double> values;
  int? chartWidth;
  int? chartHeight;
  UvStyle style;
  bool showGrid;
  UvStyle gridStyle;
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
      1,
    );
    _lastPaint = _renderSparkline(
      values,
      w,
      h,
      style,
      showGrid,
      gridStyle,
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
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
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
        );
  }
}

String _renderSparkline(
  List<double> values,
  int width,
  int height,
  UvStyle style,
  bool showGrid,
  UvStyle gridStyle, {
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
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
