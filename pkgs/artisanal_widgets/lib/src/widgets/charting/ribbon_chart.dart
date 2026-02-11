part of 'chart_widgets.dart';

/// A stacked area (ribbon) chart widget for visualising multiple data series.
///
/// Each series is rendered as a stacked band within the [width]×[height]
/// area. When [normalizeTotals] is true each column fills 100% of the
/// chart height.
///
/// ```dart
/// RibbonChart(
///   series: [
///     [10, 20, 30, 25],
///     [15, 10, 20, 30],
///   ],
///   width: 60,
///   height: 12,
///   seriesStyles: [
///     UvStyle(fg: UvColor.rgb(80, 180, 255)),
///     UvStyle(fg: UvColor.rgb(255, 120, 80)),
///   ],
/// )
/// ```
class RibbonChart extends LeafRenderObjectWidget {
  /// Creates a [RibbonChart] with the given series data and display options.
  ///
  /// When [width] or [height] is null the chart fills the available
  /// constraint space (responsive mode).
  ///
  /// Set [crosshairX] and [crosshairY] to draw a crosshair overlay at
  /// that position (e.g. from mouse hover).
  RibbonChart({
    required this.series,
    this.width,
    this.height,
    this.seriesStyles,
    this.normalizeTotals = true,
    this.fillChar = '█',
    this.showGrid = false,
    this.gridRows = 3,
    this.gridCols = 0,
    this.gridStyle,
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
    super.key,
  });

  /// The list of data series (each is a list of values).
  final List<List<double>> series;

  /// The chart width in terminal columns, or null to fill available space.
  final int? width;

  /// The chart height in terminal rows, or null to fill available space.
  final int? height;

  /// Per-series styles. If null, default empty styles are used.
  final List<UvStyle>? seriesStyles;

  /// Whether each column is normalised to fill the full height.
  final bool normalizeTotals;

  /// Character used to fill stacked bands.
  final String fillChar;

  /// Whether to draw background grid lines.
  final bool showGrid;

  /// Number of horizontal grid lines.
  final int gridRows;

  /// Number of vertical grid lines.
  final int gridCols;

  /// Style for grid lines.
  final UvStyle? gridStyle;

  /// X coordinate for crosshair overlay, or null to hide.
  final int? crosshairX;

  /// Y coordinate for crosshair overlay, or null to hide.
  final int? crosshairY;

  /// Style for the crosshair lines.
  final UvStyle? crosshairStyle;

  @override
  RenderObject createRenderObject() {
    return _RenderRibbonChart(
      series: series,
      chartWidth: width,
      chartHeight: height,
      seriesStyles: seriesStyles,
      normalizeTotals: normalizeTotals,
      fillChar: fillChar,
      showGrid: showGrid,
      gridRows: gridRows,
      gridCols: gridCols,
      gridStyle: gridStyle ?? const UvStyle(),
      crosshairX: crosshairX,
      crosshairY: crosshairY,
      crosshairStyle: crosshairStyle,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderRibbonChart;
    ro
      ..series = series
      ..chartWidth = width
      ..chartHeight = height
      ..seriesStyles = seriesStyles
      ..normalizeTotals = normalizeTotals
      ..fillChar = fillChar
      ..showGrid = showGrid
      ..gridRows = gridRows
      ..gridCols = gridCols
      ..gridStyle = gridStyle ?? const UvStyle()
      ..crosshairX = crosshairX
      ..crosshairY = crosshairY
      ..crosshairStyle = crosshairStyle;
  }

  @override
  Object view() => _renderRibbonChartString(
    series,
    width ?? 60,
    height ?? 12,
    seriesStyles,
    normalizeTotals,
    fillChar,
    showGrid,
    gridRows,
    gridCols,
    gridStyle ?? const UvStyle(),
  );
}

class _RenderRibbonChart extends RenderBox {
  _RenderRibbonChart({
    required this.series,
    required this.chartWidth,
    required this.chartHeight,
    required this.seriesStyles,
    required this.normalizeTotals,
    required this.fillChar,
    required this.showGrid,
    required this.gridRows,
    required this.gridCols,
    required this.gridStyle,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<List<double>> series;
  int? chartWidth;
  int? chartHeight;
  List<UvStyle>? seriesStyles;
  bool normalizeTotals;
  String fillChar;
  bool showGrid;
  int gridRows;
  int gridCols;
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
      60,
    );
    final h = _resolveAxis(
      chartHeight,
      constraints.hasBoundedHeight,
      constraints.maxHeight,
      12,
    );
    _lastPaint = _renderRibbonChartString(
      series,
      w,
      h,
      seriesStyles,
      normalizeTotals,
      fillChar,
      showGrid,
      gridRows,
      gridCols,
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
        _renderRibbonChartString(
          series,
          chartWidth ?? 60,
          chartHeight ?? 12,
          seriesStyles,
          normalizeTotals,
          fillChar,
          showGrid,
          gridRows,
          gridCols,
          gridStyle,
          crosshairX: crosshairX,
          crosshairY: crosshairY,
          crosshairStyle: crosshairStyle,
        );
  }
}

String _renderRibbonChartString(
  List<List<double>> series,
  int width,
  int height,
  List<UvStyle>? seriesStyles,
  bool normalizeTotals,
  String fillChar,
  bool showGrid,
  int gridRows,
  int gridCols,
  UvStyle gridStyle, {
  int? crosshairX,
  int? crosshairY,
  UvStyle? crosshairStyle,
}) {
  if (width <= 0 || height <= 0) return '';
  final canvas = Canvas(width, height);
  final area = rect(0, 0, width, height);
  drawRibbonChart(
    canvas,
    area,
    series,
    styles: seriesStyles,
    normalizeTotals: normalizeTotals,
    fillChar: fillChar,
    showGrid: showGrid,
    gridRows: gridRows,
    gridCols: gridCols,
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
