// Benchmark: Renderer diff loop
//
// Stresses: _cellEqual, _markStaleCells, PackedCell, styleToSgr, styleDiff,
//           buffer diffing, scroll optimizations, line-level caching.
//
// Phases:
//   1. Full-buffer writes — every cell changes every frame (worst case)
//   2. Incremental updates — small patches per frame (common case)
//   3. Style-heavy updates — many distinct styles per frame
//   4. Scroll / line-shift patterns

import 'dart:math';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  // Use a large-ish buffer — 200x80 = 16 000 cells, realistic for fullscreen
  const width = 200;
  const height = 80;
  const totalCells = width * height;

  final rng = Random(42);
  final sink = Sink();
  final renderer = UvTerminalRenderer(sink);

  var buf = Buffer.create(width, height);
  // Pre-fill with blank cells
  for (var y = 0; y < height; y++) {
    final line = buf.line(y)!;
    for (var x = 0; x < width; x++) {
      line.set(x, Cell.emptyCell());
    }
  }
  renderer.render(buf);

  // Pre-allocate reusable cells
  final cells = List.generate(
    100,
    (_) => Cell(
      content: String.fromCharCode(65 + rng.nextInt(26)),
      style: UvStyle(
        fg: UvColor.rgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256)),
        bg: UvColor.rgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256)),
      ),
    ),
  );

  // ---- Phase 1: Full-buffer random writes ----
  final phase1Start = Stopwatch()..start();
  const phase1Frames = 500;
  for (var f = 0; f < phase1Frames; f++) {
    for (var y = 0; y < height; y++) {
      final line = buf.line(y)!;
      for (var x = 0; x < width; x++) {
        final ci = rng.nextInt(cells.length);
        line.set(x, cells[ci]);
      }
    }
    renderer.render(buf);
  }
  final phase1Elapsed = phase1Start.elapsed;
  final phase1CellsPerSec =
      (phase1Frames * totalCells) / phase1Elapsed.inMicroseconds * 1e6;

  // ---- Phase 2: Incremental patches (10% of cells per frame) ----
  final phase2Start = Stopwatch()..start();
  const phase2Frames = 2000;
  const patchCount = totalCells ~/ 10; // ~10% per frame
  for (var f = 0; f < phase2Frames; f++) {
    for (var i = 0; i < patchCount; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      final ci = rng.nextInt(cells.length);
      buf.setCell(x, y, cells[ci]);
    }
    renderer.render(buf);
  }
  final phase2Elapsed = phase2Start.elapsed;
  final phase2CellsPerSec =
      (phase2Frames * patchCount) / phase2Elapsed.inMicroseconds * 1e6;

  // ---- Phase 3: Style-heavy (many distinct styles, same content) ----
  final phase3Start = Stopwatch()..start();
  const phase3Frames = 500;
  // Generate many unique styles
  final manyStyles = List.generate(
    200,
    (i) => UvStyle(
      fg: UvColor.rgb((i * 17) % 256, (i * 31) % 256, (i * 53) % 256),
      attrs: i % 4 == 0
          ? Attr.bold
          : i % 4 == 1
              ? Attr.italic
              : i % 4 == 2
                  ? Attr.reverse
                  : 0,
    ),
  );
  for (var f = 0; f < phase3Frames; f++) {
    for (var y = 0; y < min(height, 20); y++) {
      final line = buf.line(y)!;
      for (var x = 0; x < width; x++) {
        line.set(
          x,
          Cell(
            content: String.fromCharCode(65 + (f + x + y) % 26),
            style: manyStyles[(f + x + y) % manyStyles.length],
          ),
        );
      }
    }
    renderer.render(buf);
  }
  final phase3Elapsed = phase3Start.elapsed;

  print('=== Renderer Diff Benchmark ===');
  print('Buffer size: ${width}x$height ($totalCells cells)');
  print('');
  print(
    'Phase 1 (full-buffer): '
    '${phase1Frames} frames in ${phase1Elapsed.inMilliseconds}ms — '
    '${_fmt(phase1CellsPerSec)} cells/s',
  );
  print(
    'Phase 2 (patch 10%):   '
    '${phase2Frames} frames in ${phase2Elapsed.inMilliseconds}ms — '
    '${_fmt(phase2CellsPerSec)} cells/s',
  );
  print(
    'Phase 3 (style-heavy): '
    '${phase3Frames} frames in ${phase3Elapsed.inMilliseconds}ms',
  );
  print('');
  print('Total rendered: ${sink.bytesWritten} bytes');
  print(
    'Metrics: ${renderer.metrics.summary()}',
  );
}

String _fmt(double n) {
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}

/// A sink that discards output — avoids I/O overhead in benchmark.
class Sink implements StringSink {
  int bytesWritten = 0;

  @override
  void write(Object? obj) {
    bytesWritten += obj.toString().length;
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    for (final o in objects) {
      write(o);
      write(separator);
    }
  }

  @override
  void writeCharCode(int charCode) {
    bytesWritten++;
  }

  @override
  void writeln([Object? obj = '']) {
    write(obj);
    bytesWritten++; // newline
  }
}
