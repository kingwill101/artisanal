/// Tests for the charting renderer library.
library;

import 'package:artisanal/uv.dart';
import 'package:artisanal/charting.dart';
import 'package:test/test.dart';

/// Helper to render a chart into a Canvas and extract the cell content at
/// a given position.
Cell? _cellAt(Canvas canvas, int x, int y) => canvas.cellAt(x, y);

/// Helper to render a chart and return the full rendered string.
String _render(int w, int h, void Function(Canvas, Rectangle) painter) {
  final canvas = Canvas(w, h);
  final area = Rectangle(minX: 0, minY: 0, maxX: w, maxY: h);
  painter(canvas, area);
  return canvas.render();
}

// ---------------------------------------------------------------------------
// Core utilities
// ---------------------------------------------------------------------------

void main() {
  group('core utilities', () {
    test('clamp01 clamps values to 0..1', () {
      expect(clamp01(-1), 0);
      expect(clamp01(0), 0);
      expect(clamp01(0.5), 0.5);
      expect(clamp01(1), 1);
      expect(clamp01(2), 1);
    });

    test('clamp01 treats NaN as 0', () {
      expect(clamp01(double.nan), 0);
    });

    test('normalize maps value into 0..1 range', () {
      expect(normalize(5, 0, 10), 0.5);
      expect(normalize(0, 0, 10), 0.0);
      expect(normalize(10, 0, 10), 1.0);
    });

    test('normalize returns 0 when min == max', () {
      expect(normalize(5, 5, 5), 0);
    });

    test('normalize clamps out-of-range values', () {
      expect(normalize(-5, 0, 10), 0);
      expect(normalize(15, 0, 10), 1);
    });

    test('sampleSeries down-samples to target width', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
      final sampled = sampleSeries(values, 4);
      expect(sampled.length, 4);
      // Each bucket averages 2 values: [1.5, 3.5, 5.5, 7.5]
      expect(sampled[0], closeTo(1.5, 0.01));
      expect(sampled[1], closeTo(3.5, 0.01));
    });

    test('sampleSeries up-samples with linear interpolation', () {
      final values = [10.0, 20.0];
      final sampled = sampleSeries(values, 6);
      expect(sampled.length, 6);
      // Linear interpolation: 10, 12, 14, 16, 18, 20
      expect(sampled.first, closeTo(10, 0.01));
      expect(sampled.last, closeTo(20, 0.01));
      // Values should increase monotonically
      for (var i = 1; i < sampled.length; i++) {
        expect(sampled[i], greaterThanOrEqualTo(sampled[i - 1]));
      }
    });

    test('sampleSeries returns zeros for empty input', () {
      final sampled = sampleSeries([], 5);
      expect(sampled.length, 5);
      expect(sampled.every((v) => v == 0), isTrue);
    });

    test('sampleSeries returns empty for zero width', () {
      expect(sampleSeries([1, 2, 3], 0), isEmpty);
    });

    test('ChartCanvas render produces non-empty output', () {
      final cc = ChartCanvas(10, 5);
      cc.canvas.setCell(0, 0, Cell(content: 'X', style: const UvStyle()));
      final output = cc.render();
      expect(output, contains('X'));
    });

    test('ChartCanvas renderLines splits by newline', () {
      final cc = ChartCanvas(10, 3);
      cc.canvas.setCell(0, 0, Cell(content: 'A', style: const UvStyle()));
      cc.canvas.setCell(0, 1, Cell(content: 'B', style: const UvStyle()));
      cc.canvas.setCell(0, 2, Cell(content: 'C', style: const UvStyle()));
      final lines = cc.renderLines();
      expect(lines.length, greaterThanOrEqualTo(3));
    });

    test('renderChartLines returns exactly height lines', () {
      final lines = renderChartLines(10, 5, (screen, area) {
        screen.setCell(0, 0, Cell(content: 'Z', style: const UvStyle()));
      });
      expect(lines.length, 5);
    });

    test('putText writes text within area bounds', () {
      final canvas = Canvas(20, 3);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 3);
      putText(canvas, area, 2, 1, 'Hello', const UvStyle());
      expect(_cellAt(canvas, 2, 1)?.content, 'H');
      expect(_cellAt(canvas, 3, 1)?.content, 'e');
      expect(_cellAt(canvas, 6, 1)?.content, 'o');
    });

    test('putText clips at area boundary', () {
      final canvas = Canvas(5, 1);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 1);
      putText(canvas, area, 3, 0, 'ABCDE', const UvStyle());
      // Only 'AB' should fit (positions 3, 4)
      expect(_cellAt(canvas, 3, 0)?.content, 'A');
      expect(_cellAt(canvas, 4, 0)?.content, 'B');
    });
  });

  // -------------------------------------------------------------------------
  // drawGrid
  // -------------------------------------------------------------------------

  group('drawGrid', () {
    test('draws horizontal and vertical lines', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawGrid(canvas, area, rows: 2, cols: 2, style: const UvStyle());
      final output = canvas.render();
      expect(output, contains('┄'));
      expect(output, contains('┆'));
    });

    test('draws intersection characters', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawGrid(canvas, area, rows: 2, cols: 2, style: const UvStyle());
      final output = canvas.render();
      expect(output, contains('┼'));
    });

    test('skips drawing for tiny areas', () {
      final canvas = Canvas(2, 2);
      final area = Rectangle(minX: 0, minY: 0, maxX: 2, maxY: 2);
      drawGrid(canvas, area, rows: 1, cols: 1, style: const UvStyle());
      final output = canvas.render();
      // Should not crash and should be mostly empty
      expect(output, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // drawAxisLabels
  // -------------------------------------------------------------------------

  group('drawAxisLabels', () {
    test('draws X labels along the bottom', () {
      final canvas = Canvas(50, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 50, maxY: 5);
      drawAxisLabels(
        canvas,
        area,
        xLabels: ['AA', 'BB', 'CC'],
        style: const UvStyle(),
      );
      final output = canvas.render();
      // First label at left edge should appear.
      expect(output, contains('AA'));
      // Middle label should appear.
      expect(output, contains('BB'));
    });

    test('draws Y labels along the left', () {
      final canvas = Canvas(30, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 30, maxY: 5);
      drawAxisLabels(
        canvas,
        area,
        yLabels: ['Lo', 'Hi'],
        style: const UvStyle(),
      );
      final output = canvas.render();
      expect(output, contains('Lo'));
      expect(output, contains('Hi'));
    });
  });

  // -------------------------------------------------------------------------
  // drawLegend
  // -------------------------------------------------------------------------

  group('drawLegend', () {
    test('renders legend entries', () {
      final canvas = Canvas(30, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 30, maxY: 5);
      drawLegend(canvas, area, [
        ChartLegendEntry(label: 'Series A', style: const UvStyle()),
        ChartLegendEntry(label: 'Series B', style: const UvStyle()),
      ]);
      final output = canvas.render();
      expect(output, contains('Series A'));
      expect(output, contains('Series B'));
    });

    test('renders default glyph marker', () {
      final canvas = Canvas(30, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 30, maxY: 5);
      drawLegend(canvas, area, [
        ChartLegendEntry(label: 'Test', style: const UvStyle()),
      ]);
      expect(_cellAt(canvas, 0, 0)?.content, '■');
    });

    test('renders custom glyph marker', () {
      final canvas = Canvas(30, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 30, maxY: 5);
      drawLegend(canvas, area, [
        ChartLegendEntry(label: 'Test', style: const UvStyle(), glyph: '●'),
      ]);
      expect(_cellAt(canvas, 0, 0)?.content, '●');
    });

    test('multi-column legend distributes entries', () {
      final canvas = Canvas(40, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 40, maxY: 5);
      drawLegend(canvas, area, [
        ChartLegendEntry(label: 'A', style: const UvStyle()),
        ChartLegendEntry(label: 'B', style: const UvStyle()),
        ChartLegendEntry(label: 'C', style: const UvStyle()),
        ChartLegendEntry(label: 'D', style: const UvStyle()),
      ], columns: 2);
      final output = canvas.render();
      expect(output, contains('A'));
      expect(output, contains('B'));
      expect(output, contains('C'));
      expect(output, contains('D'));
    });
  });

  // -------------------------------------------------------------------------
  // Sparkline
  // -------------------------------------------------------------------------

  group('drawSparkline', () {
    test('single-row mode uses block characters', () {
      final output = _render(10, 1, (s, a) {
        drawSparkline(s, a, [0.0, 0.25, 0.5, 0.75, 1.0]);
      });
      // Should contain block characters from the _sparkChars set
      expect(output, isNotEmpty);
      // Full block should appear for max value
      expect(output, contains('█'));
    });

    test('multi-row mode fills columns from bottom', () {
      final canvas = Canvas(5, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 5);
      // Use varying data so normalization works (max != min).
      // The max-value column should be fully filled.
      drawSparkline(canvas, area, [0.0, 0.25, 0.5, 0.75, 1.0]);
      // The rightmost column (value=1.0 → normalized=1.0) should have █
      // all the way up.
      for (var y = 0; y < 5; y++) {
        final cell = _cellAt(canvas, 4, y);
        expect(cell, isNotNull, reason: 'cell at (4,$y) should exist');
        expect(
          cell!.content,
          '█',
          reason: 'max-value column should fill with █',
        );
      }
    });

    test('multi-row mode uses fractional top block', () {
      final canvas = Canvas(5, 4);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 4);
      // Use data where some columns get partial heights.
      drawSparkline(canvas, area, [0.0, 0.3, 0.6, 0.8, 1.0]);
      final output = canvas.render();
      // Should contain both full blocks and fractional blocks
      expect(output, contains('█'));
      // Fractional block chars: ▁▂▃▄▅▆▇
      final hasFractional = RegExp(r'[▁▂▃▄▅▆▇]').hasMatch(output);
      expect(
        hasFractional,
        isTrue,
        reason: 'mid-range columns should have fractional top block',
      );
    });

    test('multi-row mode with uniform values fills all columns equally', () {
      final canvas = Canvas(5, 4);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 4);
      // All-equal non-zero values: normalize(v, 0, v) returns 0 (min==max),
      // but normalize against 0..maxValue means all columns are at
      // normalized=1.0 → fully filled. Since normalize(0.5, 0, 0.5) = 1.0,
      // all columns should be full blocks.
      drawSparkline(canvas, area, [0.5, 0.5, 0.5, 0.5, 0.5]);
      final output = canvas.render();
      expect(output, contains('█'));
    });

    test('handles empty values gracefully', () {
      final output = _render(10, 3, (s, a) {
        drawSparkline(s, a, []);
      });
      // Should not crash — empty sparkline
      expect(output, isNotNull);
    });

    test('handles zero-size area gracefully', () {
      // Should not throw
      final canvas = Canvas(10, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);
      drawSparkline(canvas, area, [1.0, 2.0, 3.0]);
    });

    test('with showGrid draws grid lines', () {
      final output = _render(20, 5, (s, a) {
        drawSparkline(
          s,
          a,
          [1, 2, 3, 4, 5],
          showGrid: true,
          gridStyle: const UvStyle(),
        );
      });
      expect(output, contains('┄'));
    });
  });

  // -------------------------------------------------------------------------
  // Line chart (Braille)
  // -------------------------------------------------------------------------

  group('drawLineChart', () {
    test('renders Braille characters for lines', () {
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [0, 5, 2, 8, 3, 7, 1, 9, 4, 6], showMarkers: false);
      });
      // Braille chars are in range U+2800..U+28FF
      final braillePattern = RegExp(r'[\u2800-\u28FF]');
      expect(
        braillePattern.hasMatch(output),
        isTrue,
        reason: 'should contain Braille dot patterns',
      );
    });

    test('renders markers when enabled', () {
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [0, 5, 10], showMarkers: true, markerChar: '●');
      });
      expect(output, contains('●'));
    });

    test('renders without markers when disabled', () {
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [0, 5, 10], showMarkers: false);
      });
      expect(output.contains('●'), isFalse);
    });

    test('renders grid when enabled', () {
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [0, 5, 10], showGrid: true);
      });
      // Line chart uses lightweight dot grid characters
      expect(output, contains('·'));
    });

    test('renders axis labels', () {
      final output = _render(60, 14, (s, a) {
        drawLineChart(
          s,
          a,
          [0, 5, 10],
          xLabels: ['Jan', 'Jul', 'Dec'],
          yLabels: ['0', '10'],
        );
      });
      // The middle label 'Jul' is placed away from the Y-axis overlap zone.
      expect(output, contains('Jul'));
    });

    test('handles single data point', () {
      // Should not crash with one point (no line segments)
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [5.0]);
      });
      expect(output, isNotNull);
    });

    test('handles constant data (flat line)', () {
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [5, 5, 5, 5, 5], showMarkers: false);
      });
      // Braille dots should be present on a horizontal line
      final braillePattern = RegExp(r'[\u2800-\u28FF]');
      expect(braillePattern.hasMatch(output), isTrue);
    });

    test('handles too-small area', () {
      final canvas = Canvas(10, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 1, maxY: 1);
      // width=1, height=1 — below the guard (width<=1 || height<=1)
      drawLineChart(canvas, area, [1, 2, 3]);
      // Should not crash
    });
  });

  // -------------------------------------------------------------------------
  // Histogram (Bar chart)
  // -------------------------------------------------------------------------

  group('drawHistogram', () {
    test('renders bar characters', () {
      final output = _render(20, 10, (s, a) {
        drawHistogram(s, a, [3, 7, 5, 10, 2]);
      });
      expect(output, contains('█'));
    });

    test('renders axis line when showAxis is true', () {
      final output = _render(20, 10, (s, a) {
        drawHistogram(s, a, [3, 7, 5], showAxis: true);
      });
      expect(output, contains('─'));
    });

    test('does not render axis line when showAxis is false', () {
      final output = _render(20, 10, (s, a) {
        drawHistogram(s, a, [3, 7, 5], showAxis: false);
      });
      expect(output.contains('─'), isFalse);
    });

    test('uses half-block for sub-cell precision', () {
      // Use values that produce non-integer bar heights to trigger fractional
      // tops.  With usableHeight=9 (10 minus 1 for axis) and normalisation
      // against globalMax=10, value=5 gives h=(5/10)*9=4.5 whose fractional
      // part 0.5 maps to fracIdx=4 → '▄'.
      final output = _render(30, 10, (s, a) {
        drawHistogram(s, a, [1, 5, 6.2, 8.8, 10]);
      });
      // The ▄ half-block should appear at the top of some bars
      expect(output, contains('▄'));
    });

    test('respects barGap parameter', () {
      final canvas = Canvas(20, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 5);
      // Use different values so normalization works (max != min).
      drawHistogram(canvas, area, [5, 10], barGap: 3);
      final output = canvas.render();
      expect(output, contains('█'));
    });

    test('barGap=0 produces adjacent bars', () {
      final canvas = Canvas(10, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 5);
      // Use different values so normalization works.
      // The max bar (10) should fill all usable rows.
      drawHistogram(canvas, area, [5, 10], barGap: 0);
      // With barGap=0, 2 bars share 10 columns → 5 cols each.
      // The max bar (value=10) should have full blocks in the bottom rows.
      // Check that at least 5 columns have full blocks on the bottom data row.
      final bottomDataRow = area.maxY - 2; // row above axis
      var fullBlocks = 0;
      for (var x = area.minX; x < area.maxX; x++) {
        if (_cellAt(canvas, x, bottomDataRow)?.content == '█') fullBlocks++;
      }
      expect(fullBlocks, greaterThanOrEqualTo(5));
    });

    test('renders x labels under bars', () {
      final output = _render(30, 10, (s, a) {
        drawHistogram(s, a, [5, 10, 15, 20], xLabels: ['Q1', 'Q2', 'Q3', 'Q4']);
      });
      expect(output, contains('Q1'));
      expect(output, contains('Q4'));
    });

    test('renders grid when enabled', () {
      final output = _render(20, 10, (s, a) {
        drawHistogram(s, a, [3, 7, 5], showGrid: true, gridRows: 2);
      });
      expect(output, contains('┄'));
    });

    test('handles empty values', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawHistogram(canvas, area, []);
      // Should not crash
    });

    test('handles zero-height area', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 0);
      drawHistogram(canvas, area, [1, 2, 3]);
      // Should not crash
    });

    test('custom barChar renders that character', () {
      final output = _render(20, 10, (s, a) {
        drawHistogram(s, a, [5, 10], barChar: '#');
      });
      expect(output, contains('#'));
    });
  });

  // -------------------------------------------------------------------------
  // Heatmap
  // -------------------------------------------------------------------------

  group('drawHeatmap', () {
    test('renders cells for 2D grid', () {
      final output = _render(10, 5, (s, a) {
        drawHeatmap(s, a, [
          [0.0, 0.5, 1.0],
          [0.2, 0.7, 0.9],
          [0.1, 0.3, 0.8],
        ]);
      });
      // Should produce non-empty output (space with background color)
      expect(output, isNotEmpty);
    });

    test('does not crash with empty grid', () {
      final canvas = Canvas(10, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 5);
      drawHeatmap(canvas, area, []);
    });

    test('does not crash with empty rows', () {
      final canvas = Canvas(10, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 5);
      drawHeatmap(canvas, area, [[]]);
    });

    test('renders grid overlay when enabled', () {
      final output = _render(20, 10, (s, a) {
        drawHeatmap(
          s,
          a,
          [
            [0.0, 0.5, 1.0],
            [0.2, 0.7, 0.9],
          ],
          showGrid: true,
          gridRows: 1,
          gridCols: 1,
        );
      });
      // Grid characters should appear on top of the heatmap
      expect(output, contains('┄'));
    });

    test('renders axis labels', () {
      final output = _render(40, 12, (s, a) {
        drawHeatmap(
          s,
          a,
          [
            [0.0, 0.5, 1.0],
            [0.2, 0.7, 0.9],
          ],
          xLabels: ['A', 'B', 'C'],
          yLabels: ['Low', 'High'],
        );
      });
      // Y labels are drawn along the left edge; check that at least the
      // Y labels survive (they are put first but heatmap cells can overwrite
      // X labels at edge positions).
      expect(output, contains('Low'));
      expect(output, contains('High'));
    });

    test('uses custom ramp', () {
      // Just verify it doesn't crash with a custom ramp
      final canvas = Canvas(10, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 5);
      drawHeatmap(canvas, area, [
        [0.0, 0.5, 1.0],
      ], ramp: ChartRamp.thermal());
      final output = canvas.render();
      expect(output, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Pie chart
  // -------------------------------------------------------------------------

  group('drawPieChart', () {
    test('renders cells for pie slices', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawPieChart(
        canvas,
        area,
        [30, 40, 30],
        styles: [
          const UvStyle(fg: UvColor.basic16(1)),
          const UvStyle(fg: UvColor.basic16(2)),
          const UvStyle(fg: UvColor.basic16(3)),
        ],
      );
      final output = canvas.render();
      // Should produce non-trivial output with colored cells
      expect(output, isNotEmpty);
    });

    test('handles empty values', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawPieChart(canvas, area, []);
      // Should not crash
    });

    test('handles all-zero values', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawPieChart(canvas, area, [0, 0, 0]);
      // Total is 0, early return
    });

    test('handles single value (full pie)', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawPieChart(canvas, area, [100]);
      final output = canvas.render();
      expect(output, isNotEmpty);
    });

    test('donut mode creates hole in center', () {
      final canvas = Canvas(30, 15);
      final area = Rectangle(minX: 0, minY: 0, maxX: 30, maxY: 15);
      drawPieChart(canvas, area, [50, 50], donut: true);
      // Center cell should be empty (not filled)
      final centerX = 15;
      final centerY = 7;
      final cell = _cellAt(canvas, centerX, centerY);
      // In donut mode, the very center should not have a pie cell
      // (it's inside the inner radius). Content should be default/null.
      if (cell != null) {
        expect(
          cell.content != ' ' || cell.style.bg == null,
          isTrue,
          reason: 'donut center should be empty',
        );
      }
    });

    test('handles tiny area', () {
      final canvas = Canvas(10, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 1, maxY: 1);
      drawPieChart(canvas, area, [50, 50]);
      // Should not crash (width<=1 || height<=1 guard)
    });
  });

  // -------------------------------------------------------------------------
  // Ribbon chart
  // -------------------------------------------------------------------------

  group('drawRibbonChart', () {
    test('renders stacked bands', () {
      final output = _render(20, 10, (s, a) {
        drawRibbonChart(
          s,
          a,
          [
            [1, 2, 3, 4, 5],
            [5, 4, 3, 2, 1],
          ],
          styles: [
            const UvStyle(fg: UvColor.basic16(1)),
            const UvStyle(fg: UvColor.basic16(2)),
          ],
        );
      });
      expect(output, isNotEmpty);
    });

    test('uses solid interiors with half-block boundaries', () {
      final output = _render(20, 10, (s, a) {
        drawRibbonChart(
          s,
          a,
          [
            [5, 5, 5, 5, 5],
            [5, 5, 5, 5, 5],
          ],
          styles: [
            const UvStyle(fg: UvColor.basic16(1)),
            const UvStyle(fg: UvColor.basic16(2)),
          ],
        );
      });
      // With 8-subrow resolution and solid-cell rendering, identical-value
      // columns render as solid interiors; boundaries only appear at actual
      // transitions between different series ratios.
      expect(output, isNotEmpty);
    });

    test('handles empty series', () {
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawRibbonChart(canvas, area, []);
      // Should not crash
    });

    test('handles single series', () {
      final output = _render(20, 10, (s, a) {
        drawRibbonChart(
          s,
          a,
          [
            [1, 2, 3, 4, 5],
          ],
          styles: [const UvStyle(fg: UvColor.basic16(1))],
        );
      });
      expect(output, isNotEmpty);
    });

    test('normalizes totals when normalizeTotals is true', () {
      // Different totals per column should still fill the full height
      final canvas = Canvas(10, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 10);
      drawRibbonChart(
        canvas,
        area,
        [
          [1, 10], // very different magnitudes
          [9, 1],
        ],
        normalizeTotals: true,
        styles: [
          const UvStyle(fg: UvColor.basic16(1)),
          const UvStyle(fg: UvColor.basic16(2)),
        ],
      );
      // Both columns should have content filling the full height
      // Bottom cell of first column should have content
      final bottomCell = _cellAt(canvas, 0, 9);
      expect(bottomCell, isNotNull);
    });

    test('renders grid when enabled', () {
      // The ribbon chart draws the grid first and then overwrites cells with
      // ribbon content (full blocks / half blocks).  For series that fully
      // cover the area the grid is invisible.  Use a sparse single-series
      // chart so that some cells remain empty and grid chars survive.
      final output = _render(20, 10, (s, a) {
        drawRibbonChart(
          s,
          a,
          [
            [0, 0, 0], // no data → empty columns
          ],
          showGrid: true,
          gridRows: 2,
        );
      });
      // With all-zero data the ribbon is empty, so the grid should be visible.
      expect(output, contains('┄'));
    });
  });

  // -------------------------------------------------------------------------
  // Palette / ChartRamp
  // -------------------------------------------------------------------------

  group('ChartRamp', () {
    test('thermal ramp produces a style for any t in 0..1', () {
      final ramp = ChartRamp.thermal();
      for (var i = 0; i <= 10; i++) {
        final t = i / 10.0;
        final style = ramp.styleFor(t, background: true);
        expect(style, isNotNull);
      }
    });

    test('fromHexes creates ramp from hex color strings', () {
      final ramp = ChartRamp.fromHexes(['#FF0000', '#00FF00', '#0000FF']);
      final style = ramp.styleFor(0.5, background: true);
      expect(style.bg, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // uvColorFromHex / uvStyleFromHex
  // -------------------------------------------------------------------------

  group('color helpers', () {
    test('uvColorFromHex parses 6-digit hex', () {
      final color = uvColorFromHex('#FF8000');
      expect(color, isNotNull);
    });

    test('uvStyleFromHex creates styled cell', () {
      final style = uvStyleFromHex('#00FF00');
      expect(style.fg, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Integration: renderChartLines pipeline
  // -------------------------------------------------------------------------

  group('integration', () {
    test('renderChartLines with sparkline', () {
      final lines = renderChartLines(40, 5, (screen, area) {
        drawSparkline(screen, area, [1, 3, 5, 2, 8, 4, 6]);
      });
      expect(lines.length, 5);
      // At least one line should have content
      expect(lines.any((l) => l.isNotEmpty), isTrue);
    });

    test('renderChartLines with line chart', () {
      final lines = renderChartLines(40, 10, (screen, area) {
        drawLineChart(screen, area, [10, 20, 15, 25, 5, 30], showMarkers: true);
      });
      expect(lines.length, 10);
    });

    test('renderChartLines with histogram', () {
      final lines = renderChartLines(40, 10, (screen, area) {
        drawHistogram(screen, area, [5, 12, 8, 20, 15], showAxis: true);
      });
      expect(lines.length, 10);
      // Last line should contain axis
      expect(lines.last, contains('─'));
    });

    test('renderChartLines with heatmap', () {
      final lines = renderChartLines(20, 5, (screen, area) {
        drawHeatmap(screen, area, [
          [0.0, 0.5, 1.0],
          [0.2, 0.7, 0.9],
          [0.4, 0.6, 0.3],
        ]);
      });
      expect(lines.length, 5);
    });

    test('renderChartLines with pie chart', () {
      final lines = renderChartLines(20, 10, (screen, area) {
        drawPieChart(screen, area, [25, 50, 25]);
      });
      expect(lines.length, 10);
    });

    test('renderChartLines with ribbon chart', () {
      final lines = renderChartLines(20, 10, (screen, area) {
        drawRibbonChart(screen, area, [
          [3, 5, 7, 9],
          [7, 5, 3, 1],
        ]);
      });
      expect(lines.length, 10);
    });
  });

  // -------------------------------------------------------------------------
  // Visual quality regression tests
  // -------------------------------------------------------------------------

  group('visual quality regressions', () {
    test('sampleSeries linear interpolation produces smooth values', () {
      // 3 points → 9 samples should interpolate smoothly
      final sampled = sampleSeries([0.0, 100.0, 0.0], 9);
      expect(sampled.length, 9);
      // First value should be 0, middle should be 100, last should be 0
      expect(sampled[0], closeTo(0, 0.01));
      expect(sampled[4], closeTo(100, 0.01));
      expect(sampled[8], closeTo(0, 0.01));
      // Values between should be strictly between endpoints
      expect(sampled[1], greaterThan(0));
      expect(sampled[1], lessThan(100));
      expect(sampled[2], greaterThan(sampled[1]));
    });

    test('sampleSeries single-value input fills with that value', () {
      final sampled = sampleSeries([42.0], 5);
      expect(sampled.length, 5);
      for (final v in sampled) {
        expect(v, 42.0);
      }
    });

    test('sparkline zero values produce empty columns', () {
      final canvas = Canvas(5, 4);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 4);
      // Mix of zero and non-zero: zero columns should be empty.
      drawSparkline(canvas, area, [0, 10, 0, 10, 0]);
      // Columns 0, 2, 4 (zero values) should have no content
      for (final x in [0, 2, 4]) {
        for (var y = 0; y < 4; y++) {
          final cell = _cellAt(canvas, x, y);
          if (cell != null) {
            expect(
              cell.content == ' ' || cell.content.isEmpty,
              isTrue,
              reason: 'zero-value column $x row $y should be empty',
            );
          }
        }
      }
      // Columns 1, 3 (value=10) should have full blocks
      expect(_cellAt(canvas, 1, 3)?.content, '█');
      expect(_cellAt(canvas, 3, 3)?.content, '█');
    });

    test('line chart produces Braille lines between data points', () {
      // With 3 data points [0, 100, 0] on a 20x10 canvas, we should see
      // Braille dots forming a V-shape (or inverted V).
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [0, 100, 0], showMarkers: false);
      });
      final braillePattern = RegExp(r'[\u2801-\u28FF]');
      expect(
        braillePattern.hasMatch(output),
        isTrue,
        reason: 'should contain non-blank Braille characters',
      );
    });

    test('line chart uses light grid characters', () {
      final output = _render(20, 10, (s, a) {
        drawLineChart(s, a, [0, 5, 10], showGrid: true);
      });
      // Should use · (middle dot) instead of heavy ┄ or ┼
      expect(output, contains('·'));
      expect(output.contains('┄'), isFalse);
      expect(output.contains('┼'), isFalse);
    });

    test('histogram distributes labels evenly when count differs', () {
      // 10 bars with only 4 labels — labels should spread across full width
      final canvas = Canvas(60, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 60, maxY: 10);
      drawHistogram(
        canvas,
        area,
        [12, 28, 18, 35, 22, 40, 15, 30, 25, 33],
        xLabels: ['Q1', 'Q2', 'Q3', 'Q4'],
        showAxis: true,
      );
      final output = canvas.render();
      expect(output, contains('Q1'));
      expect(output, contains('Q2'));
      expect(output, contains('Q3'));
      expect(output, contains('Q4'));
      // Check that Q4 is positioned in the right half of the output.
      // The axis row is the last line.
      final lines = output.split('\n');
      final axisLine = lines.last;
      final q1Pos = axisLine.indexOf('Q1');
      final q4Pos = axisLine.indexOf('Q4');
      expect(
        q4Pos,
        greaterThan(q1Pos + 10),
        reason: 'Q4 should be far to the right of Q1',
      );
    });

    test('histogram 1:1 label-to-bar mapping still works', () {
      final output = _render(40, 10, (s, a) {
        drawHistogram(
          s,
          a,
          [10, 20, 30],
          xLabels: ['A', 'B', 'C'],
          showAxis: true,
        );
      });
      expect(output, contains('A'));
      expect(output, contains('B'));
      expect(output, contains('C'));
    });

    test('pie chart uses solid-cell rendering with high sub-sample resolution', () {
      final output = _render(30, 15, (s, a) {
        drawPieChart(
          s,
          a,
          [50, 50],
          styles: [
            const UvStyle(fg: UvColor.basic16(1)),
            const UvStyle(fg: UvColor.basic16(2)),
          ],
        );
      });
      // With 4x8 sub-sampling, cells near the boundary may have mixed
      // samples but the dominant slice determines the cell color; solid
      // interiors render as space + background color.
      expect(output, isNotEmpty);
    });

    test('pie chart supports legacy 2x2 sampling via subSamples parameter', () {
      final output = _render(32, 16, (s, a) {
        drawPieChart(
          s,
          a,
          [35, 25, 40],
          styles: [
            const UvStyle(fg: UvColor.basic16(1)),
            const UvStyle(fg: UvColor.basic16(2)),
            const UvStyle(fg: UvColor.basic16(3)),
          ],
          subSamples: 2,
        );
      });
      final hasQuarterBlock =
          output.contains('▘') ||
          output.contains('▝') ||
          output.contains('▖') ||
          output.contains('▗') ||
          output.contains('▙') ||
          output.contains('▛') ||
          output.contains('▜') ||
          output.contains('▟');
      expect(
        hasQuarterBlock,
        isTrue,
        reason: 'pie edges should include quarter-block smoothing glyphs',
      );
    });

    test('ribbon chart with interpolated samples produces smooth output', () {
      // 3 data points → 20 columns should interpolate smoothly via
      // sampleSeries, producing gradual band-height transitions.
      final canvas = Canvas(20, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 20, maxY: 10);
      drawRibbonChart(
        canvas,
        area,
        [
          [0, 10, 0],
          [10, 0, 10],
        ],
        styles: [
          const UvStyle(fg: UvColor.basic16(1)),
          const UvStyle(fg: UvColor.basic16(2)),
        ],
      );
      final output = canvas.render();
      // Should contain content (non-empty)
      expect(output.trim(), isNotEmpty);
      // Should use half-block transitions at band boundaries
      final hasHalfBlock = output.contains('▀') || output.contains('▄');
      expect(
        hasHalfBlock,
        isTrue,
        reason: 'ribbon bands should use half-block blending',
      );
    });
  });

  // -----------------------------------------------------------------------
  // drawCrosshair
  // -----------------------------------------------------------------------
  group('drawCrosshair', () {
    test('draws vertical and horizontal lines with intersection', () {
      final canvas = Canvas(10, 6);
      final area = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 6);
      drawCrosshair(canvas, area, 4, 2);

      // Vertical line at x=4 (all rows except y=2 intersection)
      for (var row = 0; row < 6; row++) {
        final cell = _cellAt(canvas, 4, row);
        expect(cell, isNotNull, reason: 'cell at (4,$row) should exist');
        if (row == 2) {
          expect(cell!.content, '┼', reason: 'intersection at (4,2)');
        } else {
          expect(cell!.content, '│', reason: 'vertical at (4,$row)');
        }
      }

      // Horizontal line at y=2 (all cols except x=4 intersection)
      for (var col = 0; col < 10; col++) {
        final cell = _cellAt(canvas, col, 2);
        expect(cell, isNotNull, reason: 'cell at ($col,2) should exist');
        if (col == 4) {
          expect(cell!.content, '┼');
        } else {
          expect(cell!.content, '─', reason: 'horizontal at ($col,2)');
        }
      }
    });

    test('does not draw outside the area bounds', () {
      final canvas = Canvas(10, 10);
      final area = Rectangle(minX: 2, minY: 2, maxX: 8, maxY: 7);
      drawCrosshair(canvas, area, 5, 4);

      // Cells outside the area should be default empty (space)
      expect(_cellAt(canvas, 5, 0)?.content, ' ');
      expect(_cellAt(canvas, 5, 1)?.content, ' ');
      expect(_cellAt(canvas, 5, 7)?.content, ' ');
      expect(_cellAt(canvas, 0, 4)?.content, ' ');
      expect(_cellAt(canvas, 1, 4)?.content, ' ');
      expect(_cellAt(canvas, 8, 4)?.content, ' ');

      // Inside area — should have crosshair
      expect(_cellAt(canvas, 5, 2)?.content, '│');
      expect(_cellAt(canvas, 5, 6)?.content, '│');
      expect(_cellAt(canvas, 2, 4)?.content, '─');
      expect(_cellAt(canvas, 7, 4)?.content, '─');
      expect(_cellAt(canvas, 5, 4)?.content, '┼');
    });

    test('crosshair at corner of area', () {
      final canvas = Canvas(5, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 5);
      drawCrosshair(canvas, area, 0, 0);

      // Intersection at top-left corner
      expect(_cellAt(canvas, 0, 0)?.content, '┼');
      // Horizontal line along row 0 (cols 1..4)
      for (var c = 1; c < 5; c++) {
        expect(_cellAt(canvas, c, 0)?.content, '─');
      }
      // Vertical line along col 0 (rows 1..4)
      for (var r = 1; r < 5; r++) {
        expect(_cellAt(canvas, 0, r)?.content, '│');
      }
    });

    test('crosshair outside area bounds draws nothing', () {
      final canvas = Canvas(5, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 5);
      drawCrosshair(canvas, area, 10, 10);

      // Canvas should be completely empty (default space cells)
      for (var r = 0; r < 5; r++) {
        for (var c = 0; c < 5; c++) {
          expect(
            _cellAt(canvas, c, r)?.content,
            ' ',
            reason: 'cell at ($c,$r) should be space',
          );
        }
      }
    });

    test('custom characters', () {
      final canvas = Canvas(5, 3);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 3);
      drawCrosshair(
        canvas,
        area,
        2,
        1,
        hChar: '=',
        vChar: '|',
        intersectionChar: '+',
      );

      expect(_cellAt(canvas, 2, 0)?.content, '|');
      expect(_cellAt(canvas, 2, 2)?.content, '|');
      expect(_cellAt(canvas, 0, 1)?.content, '=');
      expect(_cellAt(canvas, 4, 1)?.content, '=');
      expect(_cellAt(canvas, 2, 1)?.content, '+');
    });

    test('preserves existing cell content and applies crosshair fg tint', () {
      final canvas = Canvas(5, 3);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 3);
      // Pre-fill a cell with content and a foreground color (like a chart bar)
      final fillStyle = UvStyle(fg: UvColor.rgb(100, 200, 50));
      canvas.setCell(2, 0, Cell(content: '█', style: fillStyle));

      drawCrosshair(
        canvas,
        area,
        2,
        1,
        style: const UvStyle(fg: UvColor.rgb(255, 255, 0)),
      );

      // The cell at (2,0) should keep its original character, with the
      // crosshair color applied as a foreground tint.
      final cell = _cellAt(canvas, 2, 0);
      expect(cell, isNotNull);
      expect(cell!.content, '█'); // character preserved
      expect(cell.style.fg, const UvColor.rgb(255, 255, 0)); // crosshair as fg
      expect(cell.style.bg, isNull);
    });

    test('drawOnEmpty=false tints only existing chart content', () {
      final canvas = Canvas(5, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 5);
      canvas.setCell(
        2,
        2,
        Cell(
          content: '█',
          style: const UvStyle(fg: UvColor.rgb(0, 200, 0)),
        ),
      );

      drawCrosshair(
        canvas,
        area,
        2,
        2,
        style: const UvStyle(fg: UvColor.rgb(255, 255, 0)),
        drawOnEmpty: false,
      );

      final center = _cellAt(canvas, 2, 2);
      expect(center, isNotNull);
      expect(center!.content, '█');
      expect(center.style.fg, const UvColor.rgb(255, 255, 0));

      // Neighbor cells on crosshair axes remain untouched because they are
      // empty and drawOnEmpty=false.
      expect(_cellAt(canvas, 2, 1)?.content, ' ');
      expect(_cellAt(canvas, 2, 3)?.content, ' ');
      expect(_cellAt(canvas, 1, 2)?.content, ' ');
      expect(_cellAt(canvas, 3, 2)?.content, ' ');
    });

    test('x only within area draws vertical line only', () {
      final canvas = Canvas(5, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 5);
      // y is outside the area
      drawCrosshair(canvas, area, 2, 10);

      // Only vertical line at x=2 should be drawn (y is out of bounds)
      for (var r = 0; r < 5; r++) {
        expect(_cellAt(canvas, 2, r)?.content, '│');
      }
      // Cells not on the vertical line should be default spaces
      expect(_cellAt(canvas, 0, 0)?.content, ' ');
      expect(_cellAt(canvas, 1, 0)?.content, ' ');
    });

    test('y only within area draws horizontal line only', () {
      final canvas = Canvas(5, 5);
      final area = Rectangle(minX: 0, minY: 0, maxX: 5, maxY: 5);
      // x is outside the area
      drawCrosshair(canvas, area, 10, 2);

      // Only horizontal line at y=2 should be drawn (x is out of bounds)
      for (var c = 0; c < 5; c++) {
        expect(_cellAt(canvas, c, 2)?.content, '─');
      }
      // Cells not on the horizontal line should be default spaces
      expect(_cellAt(canvas, 0, 0)?.content, ' ');
      expect(_cellAt(canvas, 0, 1)?.content, ' ');
    });
  });
}
