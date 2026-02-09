/// Core charting primitives for rendering charts into UV canvases.
library;

import 'dart:math' as math;

import '../uv/canvas.dart';
import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';

/// Signature for chart painters.
typedef ChartPainter = void Function(Screen screen, Rectangle area);

/// A convenience canvas for rendering charts into UV buffers.
final class ChartCanvas {
  /// Creates a [ChartCanvas] of the given [width] and [height].
  ChartCanvas(int width, int height) : _canvas = Canvas(width, height);

  final Canvas _canvas;

  /// The underlying UV [Canvas].
  Canvas get canvas => _canvas;

  /// The bounding [Rectangle] of this canvas.
  Rectangle get bounds => _canvas.bounds();

  /// Renders the canvas contents to a single string.
  String render() => _canvas.render();

  /// Renders the canvas contents as a list of lines.
  List<String> renderLines() {
    final rendered = render();
    if (rendered.isEmpty) return const <String>[];
    return rendered.split('\n');
  }
}

/// Renders a chart into a list of lines.
List<String> renderChartLines(int width, int height, ChartPainter painter) {
  final canvas = ChartCanvas(width, height);
  painter(canvas.canvas, canvas.bounds);
  final lines = canvas.renderLines();
  if (lines.length >= height) return lines;
  return [...lines, ...List<String>.filled(height - lines.length, '')];
}

/// Places a single [glyph] cell at ([x], [y]) on the [screen].
void putCell(Screen screen, int x, int y, String glyph, UvStyle style) {
  screen.setCell(x, y, Cell(content: glyph, style: style));
}

void putText(
  Screen screen,
  Rectangle area,
  int x,
  int y,
  String text,
  UvStyle style,
) {
  if (y < area.minY || y >= area.maxY) return;
  var cursor = x;
  for (final rune in text.runes) {
    if (cursor >= area.maxX) break;
    if (cursor >= area.minX) {
      putCell(screen, cursor, y, String.fromCharCode(rune), style);
    }
    cursor++;
  }
}

/// Draws a grid of horizontal and vertical guide lines within [area].
void drawGrid(
  Screen screen,
  Rectangle area, {
  int rows = 3,
  int cols = 3,
  UvStyle style = const UvStyle(),
  String hChar = '┄',
  String vChar = '┆',
  String intersectionChar = '┼',
  bool preserveBackground = false,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 2 || height <= 2) return;

  final rowStep = height / (rows + 1);
  final colStep = width / (cols + 1);

  final rowPositions = List<int>.generate(
    rows,
    (i) => area.minY + ((i + 1) * rowStep).round(),
    growable: false,
  );
  final colPositions = List<int>.generate(
    cols,
    (i) => area.minX + ((i + 1) * colStep).round(),
    growable: false,
  );

  for (final y in rowPositions) {
    if (y <= area.minY || y >= area.maxY) continue;
    for (var x = area.minX; x < area.maxX; x++) {
      putCell(
        screen,
        x,
        y,
        hChar,
        _mergeGridStyle(screen, x, y, style, preserveBackground),
      );
    }
  }

  for (final x in colPositions) {
    if (x <= area.minX || x >= area.maxX) continue;
    for (var y = area.minY; y < area.maxY; y++) {
      putCell(
        screen,
        x,
        y,
        vChar,
        _mergeGridStyle(screen, x, y, style, preserveBackground),
      );
    }
  }

  for (final y in rowPositions) {
    for (final x in colPositions) {
      if (x <= area.minX || x >= area.maxX) continue;
      if (y <= area.minY || y >= area.maxY) continue;
      putCell(
        screen,
        x,
        y,
        intersectionChar,
        _mergeGridStyle(screen, x, y, style, preserveBackground),
      );
    }
  }
}

UvStyle _mergeGridStyle(
  Screen screen,
  int x,
  int y,
  UvStyle style,
  bool preserveBackground,
) {
  if (!preserveBackground || style.bg != null) return style;
  final cell = screen.cellAt(x, y);
  final bg = cell?.style.bg;
  if (bg == null) return style;
  return style.copyWith(bg: bg);
}

/// Draws axis labels along the X and/or Y edges of [area].
void drawAxisLabels(
  Screen screen,
  Rectangle area, {
  List<String>? xLabels,
  List<String>? yLabels,
  UvStyle style = const UvStyle(),
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0) return;

  if (xLabels != null && xLabels.isNotEmpty) {
    final step = xLabels.length <= 1 ? 0 : width / (xLabels.length - 1);
    for (var i = 0; i < xLabels.length; i++) {
      final label = xLabels[i];
      var x = area.minX + (i * step).round();
      x -= (label.length / 2).floor();
      x = math.max(area.minX, math.min(x, area.maxX - 1));
      putText(screen, area, x, area.maxY - 1, label, style);
    }
  }

  if (yLabels != null && yLabels.isNotEmpty) {
    final step = yLabels.length <= 1 ? 0 : height / (yLabels.length - 1);
    for (var i = 0; i < yLabels.length; i++) {
      final label = yLabels[i];
      var y = area.maxY - 1 - (i * step).round();
      y = math.max(area.minY, math.min(y, area.maxY - 1));
      putText(screen, area, area.minX, y, label, style);
    }
  }
}

/// A single entry in a chart legend.
final class ChartLegendEntry {
  /// Creates a [ChartLegendEntry] with the given [label] and [style].
  const ChartLegendEntry({
    required this.label,
    required this.style,
    this.glyph = '■',
    this.labelStyle = const UvStyle(),
  });

  /// The text label for this legend entry.
  final String label;

  /// The style applied to the [glyph].
  final UvStyle style;

  /// The character used as the legend marker.
  final String glyph;

  /// The style applied to the [label] text.
  final UvStyle labelStyle;
}

/// Draws a legend for the given [entries] within [area].
void drawLegend(
  Screen screen,
  Rectangle area,
  List<ChartLegendEntry> entries, {
  int columns = 1,
  int rowGap = 0,
}) {
  if (entries.isEmpty) return;
  final safeColumns = math.max(1, columns);
  final colWidth = (area.width / safeColumns).floor();
  if (colWidth <= 0) return;

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final col = i % safeColumns;
    final row = i ~/ safeColumns;
    final y = area.minY + row * (1 + rowGap);
    final x = area.minX + col * colWidth;
    if (y >= area.maxY) break;
    putCell(screen, x, y, entry.glyph, entry.style);
    putText(screen, area, x + 2, y, entry.label, entry.labelStyle);
  }
}

/// Down-samples or up-samples [values] to fit the given [width].
List<double> sampleSeries(List<double> values, int width) {
  if (width <= 0) return const <double>[];
  if (values.isEmpty) return List<double>.filled(width, 0);

  final step = values.length / width;
  if (step <= 1) {
    return List<double>.generate(
      width,
      (i) => values[(i * step).floor().clamp(0, values.length - 1)],
      growable: false,
    );
  }

  return List<double>.generate(width, (i) {
    final start = (i * step).floor();
    final end = ((i + 1) * step).floor().clamp(start + 1, values.length);
    var total = 0.0;
    for (var j = start; j < end; j++) {
      total += values[j];
    }
    return total / (end - start);
  }, growable: false);
}

/// Clamps [value] to the range 0..1, treating NaN as 0.
double clamp01(double value) {
  if (value.isNaN) return 0;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

/// Normalizes [value] into the 0..1 range between [min] and [max].
double normalize(double value, double min, double max) {
  if (max <= min) return 0;
  return clamp01((value - min) / (max - min));
}
