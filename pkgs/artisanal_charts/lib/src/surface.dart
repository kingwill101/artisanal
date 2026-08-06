/// Owned canvas surface for create/update chart APIs.
library;

import 'package:ultraviolet/ultraviolet.dart';

import 'frame_buffer.dart';

/// A fixed-size chart canvas that can be painted and rendered to text.
final class ChartSurface {
  ChartSurface({required this.width, required this.height})
    : canvas = Canvas(width, height) {
    frameBuffer = CanvasFrameBuffer(canvas);
  }

  final int width;
  final int height;
  final Canvas canvas;
  late final CanvasFrameBuffer frameBuffer;

  /// Paints via [painter] onto this surface's frame buffer.
  void paint(void Function(ChartFrameBuffer fb) painter) {
    painter(frameBuffer);
  }

  /// Renders the canvas to a multi-line string.
  String render() => canvas.render();

  /// Renders the canvas as individual lines.
  List<String> renderLines() {
    final rendered = render();
    if (rendered.isEmpty) return List<String>.filled(height, '');
    final lines = rendered.split('\n');
    if (lines.length >= height) return lines;
    return [...lines, ...List<String>.filled(height - lines.length, '')];
  }

  /// Clears the backing canvas.
  void clear() => canvas.clear();
}

/// Creates a [ChartSurface] and paints it with [paint].
ChartSurface createChartSurface({
  required int width,
  required int height,
  required void Function(ChartFrameBuffer fb, int width, int height) paint,
}) {
  final surface = ChartSurface(width: width, height: height);
  paint(surface.frameBuffer, width, height);
  return surface;
}

/// Re-paints an existing [surface].
void updateChartSurface(
  ChartSurface surface, {
  required void Function(ChartFrameBuffer fb, int width, int height) paint,
}) {
  surface.clear();
  paint(surface.frameBuffer, surface.width, surface.height);
}
