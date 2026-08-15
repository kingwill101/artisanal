/// Terminal chart rendering utilities — colors, axis scales, and Screen-based drawing helpers.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ultraviolet/ultraviolet.dart';



import 'core.dart';
import 'types.dart';

// ─── Color helpers ───────────────────────────────────────────────────────────

/// Parses a hex color (`#RRGGBB` or `RRGGBB`) into a [UvColor].
UvColor parseHexColor(
  String hex, {
  UvColor fallback = const UvColor.rgb(170, 170, 170),
}) {
  if (hex.isEmpty) return fallback;
  var value = hex.toLowerCase().replaceAll('#', '');
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (value.length != 6) return fallback;
  final r = int.tryParse(value.substring(0, 2), radix: 16) ?? 0;
  final g = int.tryParse(value.substring(2, 4), radix: 16) ?? 0;
  final b = int.tryParse(value.substring(4, 6), radix: 16) ?? 0;
  return UvColor.rgb(r, g, b);
}

/// Foreground [UvStyle] for a hex color.
UvStyle fg(String hex) => UvStyle(fg: parseHexColor(hex));

/// Dims a hex color by [factor] (0..1) and returns a foreground style.
UvStyle dimFg(String hex, [double factor = 0.4]) {
  final c = parseHexColor(hex);
  if (c is! UvRgb) return fg(hex);
  return UvStyle(
    fg: UvColor.rgb(
      (c.r * factor).round().clamp(0, 255),
      (c.g * factor).round().clamp(0, 255),
      (c.b * factor).round().clamp(0, 255),
    ),
  );
}

/// Linearly interpolates between two hex colors; returns a foreground style.
UvStyle lerpFg(String a, String b, double t) {
  final ca = parseHexColor(a);
  final cb = parseHexColor(b);
  if (ca is! UvRgb || cb is! UvRgb) return fg(a);
  final tt = t.clamp(0.0, 1.0);
  return UvStyle(
    fg: UvColor.rgb(
      (ca.r + (cb.r - ca.r) * tt).round().clamp(0, 255),
      (ca.g + (cb.g - ca.g) * tt).round().clamp(0, 255),
      (ca.b + (cb.b - ca.b) * tt).round().clamp(0, 255),
    ),
  );
}

/// Merges foreground and background [UvStyle]s into a combined style.
UvStyle mergeStyle(UvStyle fg, UvStyle bg) =>
    UvStyle(fg: fg.fg, bg: bg.bg ?? bg.fg);

// ─── Math helpers ────────────────────────────────────────────────────────────

/// Computes a "nice" axis scale with evenly spaced ticks.
NiceScale computeNiceScale(
  double dataMin,
  double dataMax, [
  int maxTicks = 10,
  int? plotHeight,
]) {
  var min = dataMin;
  var max = dataMax;
  if (min == max) {
    min = min == 0 ? 0 : min - 1;
    max = max == 0 ? 1 : max + 1;
  }
  final range = _niceNum(max - min, false);
  final tickSpacing = _niceNum(range / math.max(1, maxTicks - 1), true);
  final niceMin = (min / tickSpacing).floor() * tickSpacing;
  final niceMax = (max / tickSpacing).ceil() * tickSpacing;

  final ticks = <double>[];
  for (var v = niceMin; v <= niceMax + tickSpacing * 0.5; v += tickSpacing) {
    ticks.add(double.parse(v.toStringAsPrecision(12)));
  }

  int? effectivePlotH;
  int? plotYOffset;
  if (plotHeight != null && plotHeight > 4 && ticks.length > 1) {
    final intervals = ticks.length - 1;
    final availableRows = plotHeight - 1;
    final excess = availableRows % intervals;
    if (excess > 0) {
      effectivePlotH = plotHeight - excess;
      plotYOffset = excess ~/ 2;
    }
  }

  return NiceScale(
    min: niceMin,
    max: niceMax,
    tickSpacing: tickSpacing,
    ticks: ticks,
    effectivePlotH: effectivePlotH,
    plotYOffset: plotYOffset,
  );
}

double _niceNum(double range, bool round) {
  if (range <= 0) return 1;
  final exp = (math.log(range) / math.ln10).floor();
  final frac = range / math.pow(10, exp);
  late double nice;
  if (round) {
    if (frac < 1.5) {
      nice = 1;
    } else if (frac < 3) {
      nice = 2;
    } else if (frac < 7) {
      nice = 5;
    } else {
      nice = 10;
    }
  } else {
    if (frac <= 1) {
      nice = 1;
    } else if (frac <= 2) {
      nice = 2;
    } else if (frac <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
  }
  return nice * math.pow(10, exp).toDouble();
}

/// Result of [computeNiceScale].
final class NiceScale {
  const NiceScale({
    required this.min,
    required this.max,
    required this.tickSpacing,
    required this.ticks,
    this.effectivePlotH,
    this.plotYOffset,
  });

  final double min;
  final double max;
  final double tickSpacing;
  final List<double> ticks;
  final int? effectivePlotH;
  final int? plotYOffset;
}

/// Merges partial margins with [defaultMargins].
ChartMargins resolveMargins(ChartMargins? partial) {
  if (partial == null) return defaultMargins;
  return ChartMargins(
    top: partial.top,
    right: partial.right,
    bottom: partial.bottom,
    left: partial.left,
  );
}

/// Formats a number for axis labels.
String formatNumber(double n) {
  final abs = n.abs();
  if (abs >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
  if (abs >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (abs >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  if (n == n.roundToDouble()) return n.round().toString();
  return n.toStringAsFixed(1);
}

// ─── Screen drawing helpers ──────────────────────────────────────────────────

/// Draws a horizontal line on [screen].
void drawHLine(
  Screen screen,
  Rectangle area,
  int x1,
  int x2,
  int y,
  UvStyle fg,
  UvStyle bg, [
  String char = LineChars.horizontal,
]) {
  final start = math.min(x1, x2);
  final end = math.max(x1, x2);
  final style = mergeStyle(fg, bg);
  for (var x = start; x <= end; x++) {
    putCell(screen, x, y, char, style);
  }
}

/// Draws a vertical line on [screen].
void drawVLine(
  Screen screen,
  Rectangle area,
  int x,
  int y1,
  int y2,
  UvStyle fg,
  UvStyle bg, [
  String char = LineChars.vertical,
]) {
  final start = math.min(y1, y2);
  final end = math.max(y1, y2);
  final style = mergeStyle(fg, bg);
  for (var y = start; y <= end; y++) {
    putCell(screen, x, y, char, style);
  }
}

/// Bresenham line with optional fixed [char] (else directional box-draw glyphs).
void drawLine(
  Screen screen,
  Rectangle area,
  int x0,
  int y0,
  int x1,
  int y1,
  UvStyle fg,
  UvStyle bg, [
  String char = '',
]) {
  final dx = (x1 - x0).abs();
  final dy = (y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx - dy;
  var cx = x0;
  var cy = y0;
  var prevDx = 0;
  var prevDy = 0;
  final style = mergeStyle(fg, bg);

  while (true) {
    var cellChar = char;
    if (cellChar.isEmpty) {
      final e2 = 2 * err;
      final willMoveX = e2 > -dy;
      final willMoveY = e2 < dx;
      if (willMoveX && willMoveY) {
        cellChar = sy < 0 ? '╱' : '╲';
      } else if (willMoveX) {
        cellChar = '─';
      } else if (willMoveY) {
        cellChar = '│';
      } else {
        cellChar = '─';
      }
      if (cx == x1 && cy == y1) {
        if (prevDx != 0 && prevDy != 0) {
          cellChar = prevDy < 0 ? '╱' : '╲';
        } else if (prevDx != 0) {
          cellChar = '─';
        } else if (prevDy != 0) {
          cellChar = '│';
        }
      }
    }

    putCell(screen, cx, cy, cellChar, style);
    if (cx == x1 && cy == y1) break;

    final e2 = 2 * err;
    prevDx = 0;
    prevDy = 0;
    if (e2 > -dy) {
      err -= dy;
      cx += sx;
      prevDx = sx;
    }
    if (e2 < dx) {
      err += dx;
      cy += sy;
      prevDy = sy;
    }
  }
}

/// Draws axes, ticks, grid, and optional X labels on [screen].
void drawAxes(
  Screen screen,
  Rectangle area,
  int plotX,
  int plotY,
  int plotW,
  int plotH,
  NiceScale scale,
  List<String>? labels,
  UvStyle bg,
  UvStyle axisColor,
  AxisOptions? xAxisOpts,
  AxisOptions? yAxisOpts,
  GridOptions? gridOpts,
) {
  final showXAxis = xAxisOpts?.show != false;
  final showYAxis = yAxisOpts?.show != false;
  final showGrid = gridOpts?.show != false;
  final gridColor = gridOpts?.color != null
      ? fg(gridOpts!.color!)
      : dimFg('#FFFFFF', 0.15);
  final gridStyle = gridOpts?.style ?? GridStyle.dotted;
  final gridChar = switch (gridStyle) {
    GridStyle.dotted => LineChars.smallDot,
    GridStyle.dashed || GridStyle.solid => LineChars.horizontal,
  };

  final ePH = scale.effectivePlotH ?? plotH;
  final ePY = plotY + (scale.plotYOffset ?? 0);

  if (showYAxis) {
    drawVLine(screen, area, plotX, plotY, plotY + plotH - 1, axisColor, bg);
  }
  if (showXAxis) {
    drawHLine(
      screen,
      area,
      plotX,
      plotX + plotW - 1,
      plotY + plotH - 1,
      axisColor,
      bg,
    );
  }

  if (showYAxis) {
    for (final tick in scale.ticks) {
      final t = (tick - scale.min) / (scale.max - scale.min);
      final y = (ePY + ePH - 1 - t * (ePH - 1)).round();
      if (y < plotY || y >= plotY + plotH) continue;

      putCell(screen, plotX - 1, y, LineChars.teeLeft, mergeStyle(axisColor, bg));

      final fmt = yAxisOpts?.formatTick != null
          ? yAxisOpts!.formatTick!(tick)
          : formatNumber(tick);
      final labelStr = fmt.length > plotX - 1
          ? fmt.substring(0, plotX - 1)
          : fmt.padLeft(plotX - 1);
      putText(screen, area, 0, y, labelStr, mergeStyle(axisColor, bg));

      if (showGrid && y > plotY && y < plotY + plotH - 1) {
        for (var x = plotX + 1; x < plotX + plotW - 1; x++) {
          if (gridStyle == GridStyle.dotted && x % 2 == 0) continue;
          if (gridStyle == GridStyle.dashed && x % 3 == 2) continue;
          putCell(screen, x, y, gridChar, mergeStyle(gridColor, bg));
        }
      }
    }
  }

  if (showXAxis && labels != null && labels.isNotEmpty) {
    final step = math.max(1, (labels.length / math.max(1, plotW ~/ 6)).ceil());
    for (var i = 0; i < labels.length; i += step) {
      final x = (plotX +
              1 +
              (i / math.max(1, labels.length - 1)) * (plotW - 2))
          .round();
      if (x > plotX && x < plotX + plotW) {
        putCell(screen, x, plotY + plotH - 1, LineChars.teeBottom, mergeStyle(axisColor, bg));
        final label = labels[i].length > 6 ? labels[i].substring(0, 6) : labels[i];
        final lx = math.max(0, x - label.length ~/ 2);
        putText(screen, area, lx, plotY + plotH, label, mergeStyle(axisColor, bg));
      }
    }
  }

  if (showXAxis && showYAxis) {
    putCell(screen, plotX, plotY + plotH - 1, LineChars.cornerBl, mergeStyle(axisColor, bg));
  }
}

/// Draws a horizontal legend row on [screen].
///
/// When [vertical] is true each item is placed on its own row below [y],
/// which suits narrow side columns next to pie/donut charts.
void drawLegend(
  Screen screen,
  Rectangle area,
  List<({String name, String color})> items,
  int x,
  int y,
  int maxWidth,
  UvStyle bg, {
  bool vertical = false,
}) {
  if (vertical) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      putSolidChartCell(screen, x, y + i, fg(item.color), Block.full);
      putText(
        screen,
        area,
        x + 1,
        y + i,
        ' ${item.name}',
        mergeStyle(fg('#AAAAAA'), bg),
      );
    }
    return;
  }
  var cx = x;
  for (final item in items) {
    final entryLen = item.name.length + 3;
    if (cx + entryLen + 2 > x + maxWidth) break;
    putSolidChartCell(screen, cx, y, fg(item.color), Block.full);
    putText(screen, area, cx + 1, y, ' ${item.name}', mergeStyle(fg('#AAAAAA'), bg));
    cx += entryLen;
  }
}

/// Continuous vertical fill under a polyline using shade glyphs.
void fillAreaUnderPolyline(
  Screen screen,
  Rectangle area,
  List<(int, int)> points,
  int baseY,
  int plotX,
  int plotY,
  int plotW,
  int plotH,
  UvStyle fillStyle,
  UvStyle bg, {
  String fillChar = Block.shadeMedium,
  List<int>? baselineYs,
}) {
  if (points.isEmpty) return;

  void column(int px, int top, int bottom) {
    final y0 = math.min(top, bottom);
    final y1 = math.max(top, bottom);
    final style = mergeStyle(fillStyle, bg);
    for (var y = y0; y <= y1; y++) {
      if (y > plotY &&
          y < plotY + plotH - 1 &&
          px > plotX &&
          px < plotX + plotW - 1) {
        putCell(screen, px, y, fillChar, style);
      }
    }
  }

  if (points.length == 1) {
    final (px, py) = points[0];
    final bottom = baselineYs != null && baselineYs.isNotEmpty
        ? baselineYs[0]
        : baseY;
    column(px, py, bottom);
    return;
  }

  for (var i = 0; i < points.length - 1; i++) {
    final (x0, y0) = points[i];
    final (x1, y1) = points[i + 1];
    final b0 = baselineYs != null && i < baselineYs.length
        ? baselineYs[i]
        : baseY;
    final b1 = baselineYs != null && i + 1 < baselineYs.length
        ? baselineYs[i + 1]
        : baseY;
    final minX = math.min(x0, x1);
    final maxX = math.max(x0, x1);
    if (minX == maxX) {
      column(x0, math.min(y0, y1), math.max(b0, b1));
      continue;
    }
    for (var x = minX; x <= maxX; x++) {
      final t = (x - x0) / (x1 - x0);
      final y = (y0 + (y1 - y0) * t).round();
      final b = (b0 + (b1 - b0) * t).round();
      column(x, y, b);
    }
  }
}

// ─── Braille canvas ──────────────────────────────────────────────────────────

/// High-resolution braille canvas (2×4 sub-pixels per terminal cell).
final class BrailleCanvas {
  BrailleCanvas(this.cols, this.rows)
    : w = cols * 2,
      h = rows * 4,
      _grid = Uint8List(cols * rows);

  final int cols;
  final int rows;
  final int w;
  final int h;
  final Uint8List _grid;

  void clear() => _grid.fillRange(0, _grid.length, 0);

  void set(int sx, int sy) {
    if (sx < 0 || sx >= w || sy < 0 || sy >= h) return;
    final cx = sx >> 1;
    final cy = sy ~/ 4;
    final dotCol = sx & 1;
    final dotRow = sy & 3;
    final bit = Braille.dots[dotCol][dotRow];
    _grid[cy * cols + cx] |= bit;
  }

  void fillDot(int sx, int sy, [int radius = 3]) {
    final r2 = radius * radius;
    for (var dy = -radius; dy <= radius; dy++) {
      for (var dx = -radius; dx <= radius; dx++) {
        if (dx * dx + dy * dy <= r2) set(sx + dx, sy + dy);
      }
    }
  }

  void drawLine(int x0, int y0, int x1, int y1) {
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;
    var cx = x0;
    var cy = y0;
    while (true) {
      set(cx, cy);
      if (cx == x1 && cy == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        cx += sx;
      }
      if (e2 < dx) {
        err += dx;
        cy += sy;
      }
    }
  }

  void render(
    Screen screen,
    Rectangle area,
    int offsetX,
    int offsetY,
    UvStyle fg,
    UvStyle bg,
  ) {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final bits = _grid[r * cols + c];
        if (bits == 0) continue;
        putCell(
          screen,
          offsetX + c,
          offsetY + r,
          String.fromCharCode(Braille.base + bits),
          mergeStyle(fg, bg),
        );
      }
    }
  }
}

// ─── Quadrant canvas ─────────────────────────────────────────────────────────

/// 2×2 sub-pixel quadrant-block canvas for smooth solid lines.
final class QuadrantCanvas {
  QuadrantCanvas(this.cols, this.rows)
    : subW = cols * 2,
      subH = rows * 2,
      _pixels = List<String?>.filled(cols * 2 * rows * 2, null);

  final int cols;
  final int rows;
  final int subW;
  final int subH;
  final List<String?> _pixels;

  static const _chars = [
    ' ', '▘', '▝', '▀',
    '▖', '▌', '▞', '▛',
    '▗', '▚', '▐', '▜',
    '▄', '▙', '▟', '█',
  ];

  void clear() {
    for (var i = 0; i < _pixels.length; i++) {
      _pixels[i] = null;
    }
  }

  void set(int sx, int sy, String col) {
    if (sx < 0 || sx >= subW || sy < 0 || sy >= subH) return;
    _pixels[sy * subW + sx] = col;
  }

  /// Bresenham line in sub-pixel space (1-pixel stroke).
  void drawLine(int x0, int y0, int x1, int y1, String col) {
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;
    var cx = x0;
    var cy = y0;
    while (true) {
      set(cx, cy, col);
      if (cx == x1 && cy == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        cx += sx;
      }
      if (e2 < dx) {
        err += dx;
        cy += sy;
      }
    }
  }

  void render(
    Screen screen,
    Rectangle area,
    int offsetX,
    int offsetY,
    UvStyle bgColor,
  ) {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final tlHex = _pixels[(r * 2) * subW + (c * 2)];
        final trHex = _pixels[(r * 2) * subW + (c * 2 + 1)];
        final blHex = _pixels[(r * 2 + 1) * subW + (c * 2)];
        final brHex = _pixels[(r * 2 + 1) * subW + (c * 2 + 1)];

        final set = <String>[];
        if (tlHex != null) set.add(tlHex);
        if (trHex != null) set.add(trHex);
        if (blHex != null) set.add(blHex);
        if (brHex != null) set.add(brHex);
        if (set.isEmpty) continue;

        final unique = set.toSet().toList();
        if (unique.length == 1) {
          final mask = (tlHex != null ? 1 : 0) |
              (trHex != null ? 2 : 0) |
              (blHex != null ? 4 : 0) |
              (brHex != null ? 8 : 0);
          putCell(
            screen,
            offsetX + c,
            offsetY + r,
            _chars[mask],
            mergeStyle(fg(unique[0]), bgColor),
          );
        } else {
          final counts = <String, int>{};
          for (final s in set) {
            counts[s] = (counts[s] ?? 0) + 1;
          }
          final sorted = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final primary = sorted[0].key;
          final secondary = sorted[1].key;
          final mask = (tlHex == primary ? 1 : 0) |
              (trHex == primary ? 2 : 0) |
              (blHex == primary ? 4 : 0) |
              (brHex == primary ? 8 : 0);
          putCell(
            screen,
            offsetX + c,
            offsetY + r,
            _chars[mask],
            mergeStyle(fg(primary), fg(secondary)),
          );
        }
      }
    }
  }
}

// ─── Rendering helpers ───────────────────────────────────────────────────────

/// Fills a rectangular region on [screen] with [style] as the background.
void fillRect(Screen screen, Rectangle area, int x, int y, int w, int h, UvStyle style) {
  final bg = style.bg ?? style.fg;
  if (bg == null) return;
  final fill = UvStyle(fg: bg, bg: bg);
  final startX = math.max(x, area.minX);
  final startY = math.max(y, area.minY);
  final maxX = math.min(x + w, area.maxX);
  final maxY = math.min(y + h, area.maxY);
  for (var py = startY; py < maxY; py++) {
    for (var px = startX; px < maxX; px++) {
      putCell(screen, px, py, ' ', fill);
    }
  }
}

/// Renders a chart using [painter] at the given [width] and [height],
/// returning the result as a single [String] with embedded newlines.
String renderChart(int width, int height, ChartPainter painter) {
  final lines = renderChartLines(width, height, painter);
  return lines.join('\n');
}
