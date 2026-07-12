// Benchmark: Full-stack end-to-end terminal simulation
//
// Simulates a realistic terminal application: rendering frames with
// varying content (text, animations, styled output), decoding input events,
// and handling resize/redraw cycles.
//
// This stresses everything together: the renderer, style ops, string width,
// event decoder, buffer operations, and color ops.

import 'dart:math';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  final rng = Random(42);
  final sink = Sink();
  final renderer = UvTerminalRenderer(sink);

  const width = 200;
  const height = 80;

  // ---- Phase 1: Text-heavy rendering with scrolling ----
  var buf = Buffer.create(width, height);
  renderer.render(buf);

  // Fill with text lines and scroll
  final phase1Start = Stopwatch()..start();
  const phase1Frames = 200;

  for (var f = 0; f < phase1Frames; f++) {
    // Scroll everything up by 1 line
    for (var y = 0; y < height - 1; y++) {
      final src = buf.line(y + 1);
      final dst = buf.line(y);
      if (src != null && dst != null) {
        for (var x = 0; x < width; x++) {
          dst.set(x, src.at(x));
        }
      }
    }
    // Write a new last line with styled content
    final lastLine = buf.line(height - 1)!;
    for (var x = 0; x < width; x++) {
      final charCode = 32 + (f + x) % 95;
      lastLine.set(
        x,
        Cell(
          content: String.fromCharCode(charCode),
          style: UvStyle(
            fg: UvColor.rgb(
              (f * 17 + x * 3) % 256,
              (f * 31 + x * 7) % 256,
              (f * 53 + x * 11) % 256,
            ),
          ),
        ),
      );
    }
    renderer.render(buf);
  }
  final phase1Elapsed = phase1Start.elapsed;
  final phase1Fps = phase1Frames / phase1Elapsed.inMilliseconds * 1000;

  // ---- Phase 2: Animated graphics with drawables ----
  // Simulate drawing graphics patterns by setting many cells per frame
  buf = Buffer.create(width, height);
  renderer.render(buf);

  final phase2Start = Stopwatch()..start();
  const phase2Frames = 100;

  for (var f = 0; f < phase2Frames; f++) {
    // Draw concentric-style pattern using styled cells
    for (var y = 0; y < height; y += 2) {
      final line = buf.line(y)!;
      for (var x = 0; x < width; x += 2) {
        final dx = x - width ~/ 2;
        final dy = y - height ~/ 2;
        final dist = (dx * dx + dy * dy).toDouble();
        final hue = (dist * 0.001 + f * 0.05) % 1.0;
        final phase = hue * 6.28;
        final r = ((sin(phase) * 0.5 + 0.5) * 255).round().clamp(0, 255);
        final g = ((sin(phase + 2.09) * 0.5 + 0.5) * 255).round().clamp(0, 255);
        final b = ((sin(phase + 4.19) * 0.5 + 0.5) * 255).round().clamp(0, 255);

        line.set(
          x,
          Cell(
            content: '█',
            style: UvStyle(fg: UvColor.rgb(r, g, b)),
          ),
        );
        line.set(
          x + 1,
          x + 1 < width
              ? Cell(
                  content: ' ',
                  style: UvStyle(bg: UvColor.rgb(r, g, b)),
                )
              : Cell.emptyCell(),
        );
      }
    }
    renderer.render(buf);
  }
  final phase2Elapsed = phase2Start.elapsed;
  final phase2Fps = phase2Frames / phase2Elapsed.inMilliseconds * 1000;

  // ---- Phase 3: Input event decoding with mixed workloads ----
  final decoder = EventDecoder();
  final phase3Start = Stopwatch()..start();
  var phase3Events = 0;

  // Generate a realistic mixed input stream
  for (var f = 0; f < 100; f++) {
    final input = <int>[];
    // Some ASCII text
    for (var i = 0; i < 50; i++) {
      input.add(0x61 + rng.nextInt(26)); // a-z
    }
    // Some cursor keys
    for (var i = 0; i < 10; i++) {
      input.addAll([0x1B, 0x5B, [0x41, 0x42, 0x43, 0x44][rng.nextInt(4)]]);
    }
    // Some mouse events
    for (var i = 0; i < 5; i++) {
      final cb = 32 + rng.nextInt(3);
      final cx = 32 + rng.nextInt(width);
      final cy = 32 + rng.nextInt(height);
      input.addAll([
        0x1B, 0x5B, 0x4D, //
        cb, //
        cx < 256 ? cx : cx - 256, //
        cy < 256 ? cy : cy - 256, //
      ]);
    }
    // Decode all events from input buffer
    var buf = input;
    while (buf.isNotEmpty) {
      final (n, ev) = decoder.decode(buf, allowIncompleteEsc: true);
      if (n == 0) break;
      buf = buf.sublist(n);
      if (ev != null) phase3Events++;
    }
  }
  final phase3Elapsed = phase3Start.elapsed;

  // ---- Phase 4: Simultaneous string width + layout ----
  final phase4Start = Stopwatch()..start();
  var phase4Width = 0;
  const phase4Iterations = 1000;

  for (var i = 0; i < phase4Iterations; i++) {
    // Generate a paragraph of mixed text
    final words = <String>[];
    for (var j = 0; j < 20; j++) {
      final wordLen = 2 + rng.nextInt(8);
      final word = String.fromCharCodes(
        List.generate(wordLen, (_) => 0x61 + rng.nextInt(26)),
      );
      words.add(word);
    }
    final line = words.join(' ');

    // Measure display width (stresses stringWidth)
    final w = stringWidth(line);
    phase4Width += w;

    // Simulate text wrapping (stresses layout)
    if (w > 80) {
      // Long lines trigger the grapheme-fallback path
      final longLine = line +
          ' \u{4E00}' * 5 +
          ' \u{1F600}' * 3;
      phase4Width += stringWidth(longLine);
    }
  }
  final phase4Elapsed = phase4Start.elapsed;

  // ---- Combined results ----
  final totalCheck = phase1Frames + phase2Frames + phase3Events + phase4Width;

  print('=== Full Stack Benchmark ===');
  print('');
  print(
    'Phase 1 (text scroll):    ${phase1Frames} frames in '
    '${phase1Elapsed.inMilliseconds}ms — '
    '${phase1Fps.toStringAsFixed(1)} FPS',
  );
  print(
    'Phase 2 (animated gfx):   ${phase2Frames} frames in '
    '${phase2Elapsed.inMilliseconds}ms — '
    '${phase2Fps.toStringAsFixed(1)} FPS',
  );
  print(
    'Phase 3 (event decode):   ${phase3Events} events in '
    '${phase3Elapsed.inMilliseconds}ms',
  );
  print(
    'Phase 4 (string + layout): ${phase4Width} total width in '
    '${phase4Elapsed.inMilliseconds}ms',
  );
  print('');
  print('Total output: ${sink.bytesWritten} bytes');
  print('Metrics: ${renderer.metrics.summary()}');
  print('Total check value: $totalCheck');
}

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
    bytesWritten++;
  }
}
