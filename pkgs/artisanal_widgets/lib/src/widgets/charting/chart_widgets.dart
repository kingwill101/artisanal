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
        ChartRamp,
        drawCrosshair,
        drawSparkline,
        drawLineChart,
        drawHistogram,
        drawHeatmap,
        drawPieChart,
        drawRibbonChart;
import 'package:artisanal/uv.dart' show Canvas, UvStyle, rect;

import '../animation/listenable.dart';
import '../core/framework.dart' show BuildContext, StatefulWidget, State;
import '../core/widget.dart';
import '../rendering/render_object.dart';
import '../layout/geometry.dart' show BoxConstraints, Size;

part 'chart_model.dart';
part 'chart_builder.dart';
part 'sparkline_chart.dart';
part 'line_chart.dart';
part 'bar_chart.dart';
part 'heatmap_chart.dart';
part 'pie_chart.dart';
part 'ribbon_chart.dart';

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
