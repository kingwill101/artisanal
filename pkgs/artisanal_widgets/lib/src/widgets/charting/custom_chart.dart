part of 'chart_widgets.dart';

/// A generic chart widget backed by a custom [ChartPainter].
///
/// Use this when a chart does not fit one of the built-in primitives but can
/// still render into a UV canvas using cell-based drawing.
class CustomChart extends LeafRenderObjectWidget {
  CustomChart({
    required this.painter,
    this.width,
    this.height,
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

  final ChartPainter painter;
  final int? width;
  final int? height;
  final List<ChartLegendEntry>? legendEntries;
  final int legendColumns;
  final int legendRowGap;
  final ChartLegendPosition legendPosition;
  final int legendPadding;
  final int? crosshairX;
  final int? crosshairY;
  final UvStyle? crosshairStyle;

  @override
  RenderObject createRenderObject() => _RenderCustomChart(
    painter: painter,
    chartWidth: width,
    chartHeight: height,
    legendEntries: legendEntries,
    legendColumns: legendColumns,
    legendRowGap: legendRowGap,
    legendPosition: legendPosition,
    legendPadding: legendPadding,
    crosshairX: crosshairX,
    crosshairY: crosshairY,
    crosshairStyle: crosshairStyle,
  );

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderCustomChart;
    ro
      ..painter = painter
      ..chartWidth = width
      ..chartHeight = height
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
  Object view() => _renderCustomChartString(
    painter,
    width ?? 40,
    height ?? 10,
    legendEntries,
    legendColumns,
    legendRowGap,
    legendPosition,
    legendPadding,
  );
}

class _RenderCustomChart extends RenderBox {
  _RenderCustomChart({
    required this.painter,
    required this.chartWidth,
    required this.chartHeight,
    required this.legendEntries,
    required this.legendColumns,
    required this.legendRowGap,
    required this.legendPosition,
    required this.legendPadding,
    required this.crosshairX,
    required this.crosshairY,
    required this.crosshairStyle,
  });

  ChartPainter painter;
  int? chartWidth;
  int? chartHeight;
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
      40,
    );
    final h = _resolveAxis(
      chartHeight,
      constraints.hasBoundedHeight,
      constraints.maxHeight,
      10,
    );
    _lastPaint = _renderCustomChartString(
      painter,
      w,
      h,
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
  String paint() =>
      _lastPaint ??
      _renderCustomChartString(
        painter,
        chartWidth ?? 40,
        chartHeight ?? 10,
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

String _renderCustomChartString(
  ChartPainter painter,
  int width,
  int height,
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
  painter(canvas, area);
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
