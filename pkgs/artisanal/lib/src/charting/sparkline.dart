/// Sparkline renderer for UV screens.
library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// Block characters for sub-cell vertical resolution (1/8 increments).
///
/// Index 0 is the lowest fraction, index 7 is a full block.
const _sparkChars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

/// Draws a compact sparkline of [values] into [area] on [screen].
///
/// When [area] has a height of 1, each column uses a single block character
/// from the 8-level set (`▁`–`█`) to indicate the value.
///
/// When [area] has a height greater than 1, the sparkline fills the full
/// vertical extent: full-block (`█`) cells below the value level, and a
/// fractional block character at the top of each column for sub-cell
/// precision.  This gives 8× the vertical resolution of the cell grid.
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

  final samples = sampleSeries(values, width);
  if (samples.isEmpty) return;
  final maxValue = samples.reduce((a, b) => a > b ? a : b);

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

  if (height == 1) {
    // Single-row mode: one character per column from the 8-level set.
    // Normalize against 0 (not minValue) so the baseline is zero.
    final row = area.minY;
    for (var x = 0; x < width; x++) {
      final normalized = normalize(samples[x], 0, maxValue);
      final idx = (normalized * (_sparkChars.length - 1)).round();
      if (idx <= 0) continue; // truly zero → no glyph
      final glyph = _sparkChars[idx.clamp(0, _sparkChars.length - 1)];
      putCell(screen, area.minX + x, row, glyph, style);
    }
    return;
  }

  // Multi-row mode: fill columns from the bottom using full blocks, with
  // a fractional block at the top of each column.
  //
  // Total sub-cell height is height * 8 (each cell has 8 block levels).
  // Normalize against 0 (not minValue) so the chart baseline is at zero.
  final totalSubCells = height * 8;

  for (var x = 0; x < width; x++) {
    final normalized = normalize(samples[x], 0, maxValue);
    // How many sub-cell units this value occupies (0..totalSubCells).
    // Zero values produce 0 sub-cells (empty column).
    final subCellHeight = (normalized * totalSubCells).round().clamp(
      0,
      totalSubCells,
    );
    if (subCellHeight <= 0) continue;

    final fullRows = subCellHeight ~/ 8;
    final remainder = subCellHeight % 8;

    // Draw full-block cells from the bottom.
    for (var r = 0; r < fullRows; r++) {
      final cellY = area.maxY - 1 - r;
      if (cellY < area.minY) break;
      putCell(screen, area.minX + x, cellY, '█', style);
    }

    // Draw fractional top cell.
    if (remainder > 0) {
      final cellY = area.maxY - 1 - fullRows;
      if (cellY >= area.minY) {
        final glyph = _sparkChars[remainder - 1];
        putCell(screen, area.minX + x, cellY, glyph, style);
      }
    }
  }
}
