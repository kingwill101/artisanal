/// Chart widgets that wrap the artisanal charting library for use in
/// the widget tree.
///
/// Provides observable [ChartModel] data objects and leaf widgets
/// ([SparklineChart], [LineChart], [BarChart], [HeatmapChart],
/// [PieChart], [RibbonChart]) that paint charts via UV canvas rendering.
///
/// A convenience [ChartBuilder] widget automatically rebuilds when its
/// [ChartModel] notifies listeners.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'dart:math' as math;

import 'package:artisanal/charting.dart'
    show
        ChartPainter,
        ChartLegendEntry,
        ChartRamp,
        drawCrosshair,
        drawLegend,
        drawSparkline,
        drawLineChart,
        drawMultiSeriesLineChart,
        drawHistogram,
        drawGroupedHistogram,
        drawStackedHistogram,
        drawHorizontalGroupedHistogram,
        drawHorizontalStackedHistogram,
        drawHeatmap,
        drawPieChart,
        drawRibbonChart,
        parseSequenceDiagram,
        drawSequenceDiagram,
        layoutSequenceDiagram,
        SequenceDiagram,
        SequenceDiagramTheme;
import 'package:artisanal/uv.dart' show Canvas, Cell, Rectangle, UvStyle, rect;

import '../animation/listenable.dart';
import '../core/framework.dart' show BuildContext, StatefulWidget, State;
import '../core/widget.dart';
import '../rendering/render_object.dart';
import '../layout/geometry.dart' show BoxConstraints, Size;

part 'chart_model.dart';
part 'chart_builder.dart';
part 'custom_chart.dart';
part 'sparkline_chart.dart';
part 'line_chart.dart';
part 'bar_chart.dart';
part 'heatmap_chart.dart';
part 'pie_chart.dart';
part 'ribbon_chart.dart';
part 'sequence_diagram_chart.dart';

/// Resolves a chart dimension (width or height) from an optional explicit
/// value and the incoming layout constraint.
///
/// When [explicit] is non-null the chart caps at that value (or the
/// constraint, whichever is smaller). When null the chart fills the
/// available constraint space, falling back to [fallback] when the
/// constraint is unbounded.
int _resolveAxis(
  int? explicit,
  bool hasBounded,
  double maxConstraint,
  int fallback,
) {
  if (explicit != null) {
    return hasBounded ? math.min(explicit, maxConstraint.toInt()) : explicit;
  }
  return hasBounded ? maxConstraint.toInt() : fallback;
}

/// Placement for chart legends rendered inside chart bounds.
enum ChartLegendPosition { topLeft, topRight, bottomLeft, bottomRight }

void _drawLegendOverlay(
  Canvas canvas,
  Rectangle chartArea,
  List<ChartLegendEntry>? entries, {
  int columns = 1,
  int rowGap = 0,
  ChartLegendPosition position = ChartLegendPosition.topRight,
  int padding = 1,
}) {
  if (entries == null || entries.isEmpty) return;

  final safeColumns = math.max(1, columns);
  final rows = ((entries.length + safeColumns) - 1) ~/ safeColumns;
  final neededHeight = rows + ((rows - 1) * math.max(0, rowGap));
  final maxLabelWidth = entries.fold<int>(
    0,
    (prev, entry) => math.max(prev, entry.label.length + 2),
  );
  final neededWidth = maxLabelWidth * safeColumns;

  // Reserve a framed panel (1-cell border) so legend text remains readable
  // over dense chart content.
  const frameInset = 1;

  final availableWidth = chartArea.width - (padding * 2);
  final availableHeight = chartArea.height - (padding * 2);
  if (availableWidth <= 0 || availableHeight <= 0) return;

  final contentMaxWidth = availableWidth - (frameInset * 2);
  final contentMaxHeight = availableHeight - (frameInset * 2);
  if (contentMaxWidth <= 0 || contentMaxHeight <= 0) return;

  final legendWidth = math.min(neededWidth, contentMaxWidth).toInt();
  final legendHeight = math.min(neededHeight, contentMaxHeight).toInt();
  if (legendWidth <= 0 || legendHeight <= 0) return;

  final panelWidth = legendWidth + (frameInset * 2);
  final panelHeight = legendHeight + (frameInset * 2);

  late int minX;
  late int minY;
  switch (position) {
    case ChartLegendPosition.topLeft:
      minX = chartArea.minX + padding;
      minY = chartArea.minY + padding;
    case ChartLegendPosition.topRight:
      minX = chartArea.maxX - padding - panelWidth;
      minY = chartArea.minY + padding;
    case ChartLegendPosition.bottomLeft:
      minX = chartArea.minX + padding;
      minY = chartArea.maxY - padding - panelHeight;
    case ChartLegendPosition.bottomRight:
      minX = chartArea.maxX - padding - panelWidth;
      minY = chartArea.maxY - padding - panelHeight;
  }

  final panelMaxX = minX + panelWidth;
  final panelMaxY = minY + panelHeight;

  // Clear panel background so chart pixels do not bleed through label text.
  for (var y = minY; y < panelMaxY; y++) {
    for (var x = minX; x < panelMaxX; x++) {
      canvas.setCell(x, y, Cell(content: ' '));
    }
  }

  // Draw frame.
  if (panelWidth >= 2 && panelHeight >= 2) {
    canvas.setCell(minX, minY, Cell(content: '┌'));
    canvas.setCell(panelMaxX - 1, minY, Cell(content: '┐'));
    canvas.setCell(minX, panelMaxY - 1, Cell(content: '└'));
    canvas.setCell(panelMaxX - 1, panelMaxY - 1, Cell(content: '┘'));
    for (var x = minX + 1; x < panelMaxX - 1; x++) {
      canvas.setCell(x, minY, Cell(content: '─'));
      canvas.setCell(x, panelMaxY - 1, Cell(content: '─'));
    }
    for (var y = minY + 1; y < panelMaxY - 1; y++) {
      canvas.setCell(minX, y, Cell(content: '│'));
      canvas.setCell(panelMaxX - 1, y, Cell(content: '│'));
    }
  }

  final legendArea = Rectangle(
    minX: minX + frameInset,
    minY: minY + frameInset,
    maxX: minX + frameInset + legendWidth,
    maxY: minY + frameInset + legendHeight,
  );
  drawLegend(
    canvas,
    legendArea,
    entries,
    columns: safeColumns,
    rowGap: math.max(0, rowGap).toInt(),
  );
}
