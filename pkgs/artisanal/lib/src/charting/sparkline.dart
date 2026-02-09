/// Sparkline renderer for UV screens.
library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

const _sparkChars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

/// Draws a compact sparkline of [values] into [area] on [screen].
void drawSparkline(
  Screen screen,
  Rectangle area,
  List<double> values, {
  UvStyle style = const UvStyle(),
  bool showGrid = false,
  UvStyle gridStyle = const UvStyle(),
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0) return;

  final row = area.minY + (height ~/ 2);
  final samples = sampleSeries(values, width);
  if (samples.isEmpty) return;
  final maxValue = samples.reduce((a, b) => a > b ? a : b);
  final minValue = samples.reduce((a, b) => a < b ? a : b);

  if (showGrid) {
    for (var x = 0; x < width; x++) {
      putCell(screen, area.minX + x, row, '─', gridStyle);
    }
  }

  for (var x = 0; x < width; x++) {
    final value = samples[x];
    final normalized = normalize(value, minValue, maxValue);
    final idx = (normalized * (_sparkChars.length - 1)).round();
    final glyph = _sparkChars[idx.clamp(0, _sparkChars.length - 1)];
    putCell(screen, area.minX + x, row, glyph, style);
  }
}
