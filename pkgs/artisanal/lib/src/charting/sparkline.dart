/// Sparkline renderer for UV screens.
library;

import 'package:ultraviolet/core.dart';
import 'core.dart';
import 'package:artisanal/style.dart';

/// Block characters for sparkline rendering (9 levels: empty + 8 bars).
const sparkChars = SparkBars.levels;

/// Draws a compact sparkline of [values] into [area] on [screen].
///
/// When [area] has a height of 1, each column uses a single block character
/// from the 8-level set (`▁`–`█`) to indicate the value.
///
/// When [area] has a height greater than 1, the sparkline fills the full
/// vertical extent: full-block (`█`) cells below the value level, and a
/// fractional block character at the top of each column for sub-cell
/// precision.  This gives 8× the vertical resolution of the cell grid.
///
/// [baseline] controls the value below which columns render as empty
/// (default: 0.0).  [minValue] and [maxValue] allow explicit bounds;
/// when null, they are auto-detected from the data.
///
/// [gradientLow] and [gradientHigh] enable per-column color interpolation
/// based on value: low values get [gradientLow], high values get
/// [gradientHigh], with linear interpolation between.
void drawSparkline(
  Screen screen,
  Rectangle area,
  List<double> values, {
  UvStyle style = const UvStyle(),
  bool showGrid = false,
  UvStyle gridStyle = const UvStyle(),
  double baseline = 0.0,
  double? minValue,
  double? maxValue,
  UvStyle? gradientLow,
  UvStyle? gradientHigh,
}) {
  final width = area.width;
  final height = area.height;
  if (width <= 0 || height <= 0) return;

  final samples = sampleSeries(values, width);
  if (samples.isEmpty) return;

  // Resolve bounds.
  var dataMin = minValue ?? samples.reduce((a, b) => a < b ? a : b);
  var dataMax = maxValue ?? samples.reduce((a, b) => a > b ? a : b);
  if (!dataMin.isFinite) dataMin = 0;
  if (!dataMax.isFinite) dataMax = 1;
  if (dataMin >= dataMax) {
    dataMin -= 0.5;
    dataMax += 0.5;
  }
  final range = dataMax - dataMin;

  if (showGrid) {
    drawGrid(
      screen,
      area,
      rows: height > 3 ? (height ~/ 3).clamp(1, 5) : 1,
      cols: 0,
      style: gridStyle,
      hChar: '┄',
      vChar: '┆',
      intersectionChar: '┼',
    );
  }

  final useGradient = gradientLow != null && gradientHigh != null;

  if (height == 1) {
    // Single-row mode: one character per column from the 8-level set.
    final row = area.minY;
    for (var x = 0; x < width; x++) {
      if (samples[x] <= baseline) continue; // at or below baseline → empty
      final normalized = clamp01((samples[x] - dataMin) / range);
      final idx = (normalized * 8).round();
      if (idx <= 0) continue;
      final glyph = sparkChars[idx.clamp(0, 8)];
      var cellStyle = style;
      if (useGradient) {
        cellStyle = _lerpStyle(gradientLow, gradientHigh, normalized);
      }
      putCell(screen, area.minX + x, row, glyph, cellStyle);
    }
    return;
  }

  // Multi-row mode: fill columns from the bottom using full blocks.
  final totalSubCells = height * 8;

  for (var x = 0; x < width; x++) {
    if (samples[x] <= baseline) continue;
    final normalized = clamp01((samples[x] - dataMin) / range);
    final subCellHeight = (normalized * totalSubCells).round().clamp(
      0,
      totalSubCells,
    );
    if (subCellHeight <= 0) continue;

    var cellStyle = style;
    if (useGradient) {
      cellStyle = _lerpStyle(gradientLow, gradientHigh, normalized);
    }

    final fullRows = subCellHeight ~/ 8;
    final remainder = subCellHeight % 8;

    for (var r = 0; r < fullRows; r++) {
      final cellY = area.maxY - 1 - r;
      if (cellY < area.minY) break;
      putSolidChartCell(
        screen,
        area.minX + x,
        cellY,
        cellStyle,
        BlockShades.full,
      );
    }

    if (remainder > 0) {
      final cellY = area.maxY - 1 - fullRows;
      if (cellY >= area.minY) {
        final glyph = sparkChars[remainder];
        putSolidChartCell(screen, area.minX + x, cellY, cellStyle, glyph);
      }
    }
  }
}

/// Linearly interpolate between two [UvStyle]s based on [t] (0.0–1.0).
UvStyle _lerpStyle(UvStyle low, UvStyle high, double t) {
  final fg = _lerpUvColor(low.fg, high.fg, t);
  final bg = _lerpUvColor(low.bg, high.bg, t);
  return UvStyle(fg: fg, bg: bg);
}

UvColor? _lerpUvColor(UvColor? low, UvColor? high, double t) {
  if (low == null || high == null) return t < 0.5 ? low : high;
  if (low is UvRgb && high is UvRgb) {
    final t0 = t.clamp(0.0, 1.0);
    return UvColor.rgb(
      (low.r + (high.r - low.r) * t0).round().clamp(0, 255),
      (low.g + (high.g - low.g) * t0).round().clamp(0, 255),
      (low.b + (high.b - low.b) * t0).round().clamp(0, 255),
    );
  }
  // For non-RGB colors, step at the midpoint.
  return t < 0.5 ? low : high;
}
