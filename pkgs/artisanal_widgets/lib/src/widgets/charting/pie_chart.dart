part of 'chart_widgets.dart';

/// A pie or donut chart widget.
///
/// Renders [values] as proportional angular slices within a circular area
/// of [width]×[height] cells. Terminal cell aspect ratio is compensated by
/// [cellAspect].
///
/// ```dart
/// PieChart(
///   values: [30, 20, 50],
///   width: 20,
///   height: 10,
///   donut: true,
///   sliceStyles: [
///     UvStyle(bg: UvColor.rgb(230, 57, 70)),
///     UvStyle(bg: UvColor.rgb(42, 157, 143)),
///     UvStyle(bg: UvColor.rgb(233, 196, 106)),
///   ],
/// )
/// ```
class PieChart extends LeafRenderObjectWidget {
  /// Creates a [PieChart] with the given data and display options.
  ///
  /// When [width] or [height] is null the chart fills the available
  /// constraint space (responsive mode).
  ///
  /// Set [crosshairX] and [crosshairY] to draw a crosshair overlay at
  /// that position (e.g. from mouse hover).
  PieChart({
    required this.values,
    this.width,
    this.height,
    this.sliceStyles,
    this.useBackground = true,
    this.donut = false,
    this.innerRadiusRatio = 0.45,
    this.cellAspect = 2.0,
    this.glyph = ' ',
    this.legendEntries,
    this.legendColumns = 1,
    this.legendRowGap = 0,
    this.legendPosition = ChartLegendPosition.topRight,
    this.legendPadding = 1,
    this.crosshairX,
    this.crosshairY,
    this.crosshairStyle,
    super.key,
  });

  /// The slice sizes (proportional, not normalised).
  final List<double> values;

  /// The chart width in terminal columns, or null to fill available space.
  final int? width;

  /// The chart height in terminal rows, or null to fill available space.
  final int? height;

  /// Per-slice styles. If null, default empty styles are used.
  final List<UvStyle>? sliceStyles;

  /// If true, slices are rendered as coloured backgrounds.
  final bool useBackground;

  /// Whether to cut out an inner circle (donut mode).
  final bool donut;

  /// Inner radius as a fraction of outer radius in donut mode.
  final double innerRadiusRatio;

  /// Width-to-height ratio of terminal cells for circle compensation.
  final double cellAspect;

  /// Character rendered in background mode.
  final String glyph;

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

  @override
  RenderObject createRenderObject() {
    return _RenderPieChart(
      values: values,
      chartWidth: width,
      chartHeight: height,
      sliceStyles: sliceStyles,
      useBackground: useBackground,
      donut: donut,
      innerRadiusRatio: innerRadiusRatio,
      cellAspect: cellAspect,
      glyph: glyph,
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
    final ro = renderObject as _RenderPieChart;
    ro
      ..values = values
      ..chartWidth = width
      ..chartHeight = height
      ..sliceStyles = sliceStyles
      ..useBackground = useBackground
      ..donut = donut
      ..innerRadiusRatio = innerRadiusRatio
      ..cellAspect = cellAspect
      ..glyph = glyph
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
  Object view() => _renderPieChartString(
    values,
    width ?? 20,
    height ?? 10,
    sliceStyles,
    useBackground,
    donut,
    innerRadiusRatio,
    cellAspect,
    glyph,
    legendEntries,
    legendColumns,
    legendRowGap,
    legendPosition,
    legendPadding,
  );
}

class _RenderPieChart extends RenderBox {
  _RenderPieChart({
    required this.values,
    required this.chartWidth,
    required this.chartHeight,
    required this.sliceStyles,
    required this.useBackground,
    required this.donut,
    required this.innerRadiusRatio,
    required this.cellAspect,
    required this.glyph,
    required this.legendEntries,
    required this.legendColumns,
    required this.legendRowGap,
    required this.legendPosition,
    required this.legendPadding,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  List<double> values;
  int? chartWidth;
  int? chartHeight;
  List<UvStyle>? sliceStyles;
  bool useBackground;
  bool donut;
  double innerRadiusRatio;
  double cellAspect;
  String glyph;
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
      20,
    );
    final h = _resolveAxis(
      chartHeight,
      constraints.hasBoundedHeight,
      constraints.maxHeight,
      10,
    );
    _lastPaint = _renderPieChartString(
      values,
      w,
      h,
      sliceStyles,
      useBackground,
      donut,
      innerRadiusRatio,
      cellAspect,
      glyph,
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
        _renderPieChartString(
          values,
          chartWidth ?? 20,
          chartHeight ?? 10,
          sliceStyles,
          useBackground,
          donut,
          innerRadiusRatio,
          cellAspect,
          glyph,
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

String _renderPieChartString(
  List<double> values,
  int width,
  int height,
  List<UvStyle>? sliceStyles,
  bool useBackground,
  bool donut,
  double innerRadiusRatio,
  double cellAspect,
  String glyph,
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
  drawPieChart(
    canvas,
    area,
    values,
    styles: sliceStyles,
    useBackground: useBackground,
    donut: donut,
    innerRadiusRatio: innerRadiusRatio,
    cellAspect: cellAspect,
    glyph: glyph,
  );
  if (crosshairX != null && crosshairY != null) {
    drawCrosshair(
      canvas,
      area,
      crosshairX,
      crosshairY,
      style: crosshairStyle ?? const UvStyle(),
      drawOnEmpty: false,
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
