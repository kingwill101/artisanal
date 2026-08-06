/// Widget that paints an OpenTUI-style chart into the artisanal widget tree.
library;

import 'dart:math' as math;

import 'package:artisanal_widgets/widgets.dart';

import '../frame_buffer.dart';
import '../surface.dart';

/// Signature for painting a chart into a [ChartFrameBuffer].
typedef ChartPaintCallback =
    void Function(ChartFrameBuffer fb, int width, int height);

/// A leaf widget that renders a chart via [paintCallback] into a UV canvas.
///
/// When [width] / [height] are omitted, the chart fills the layout constraints
/// (with sensible fallbacks when unbounded).
class ChartView extends LeafRenderObjectWidget {
  ChartView({
    required this.paintCallback,
    this.width,
    this.height,
    super.key,
  });

  final ChartPaintCallback paintCallback;
  final int? width;
  final int? height;

  @override
  RenderObject createRenderObject() => _RenderChartView(
        paint: paintCallback,
        chartWidth: width,
        chartHeight: height,
      );

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderChartView;
    ro
      ..paintCallback = paintCallback
      ..chartWidth = width
      ..chartHeight = height;
  }

  @override
  Object view() {
    final w = width ?? 40;
    final h = height ?? 12;
    final surface = ChartSurface(width: w, height: h);
    paintCallback(surface.frameBuffer, w, h);
    return surface.render();
  }
}

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

class _RenderChartView extends RenderBox {
  _RenderChartView({
    required ChartPaintCallback paint,
    required this.chartWidth,
    required this.chartHeight,
  }) : paintCallback = paint;

  ChartPaintCallback paintCallback;
  int? chartWidth;
  int? chartHeight;
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
      12,
    );
    final surface = ChartSurface(width: w, height: h);
    paintCallback(surface.frameBuffer, w, h);
    _lastPaint = surface.render();
    size = constraints.constrain(Size(w.toDouble(), h.toDouble()));
  }

  @override
  String paint() {
    if (_lastPaint != null) return _lastPaint!;
    final w = chartWidth ?? 40;
    final h = chartHeight ?? 12;
    final surface = ChartSurface(width: w, height: h);
    paintCallback(surface.frameBuffer, w, h);
    return surface.render();
  }
}
