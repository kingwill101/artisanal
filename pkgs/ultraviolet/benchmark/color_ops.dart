// Benchmark: Color operations
//
// Stresses: sourceOver(), rgbToHsl(), rgbToAnsi256(), rgbToAnsi16(),
//           ansi256ToAnsi16(), colorToHex(), clampRgbChannel,
//           UvColor.rgb() construction, UvStyle construction with colors,
//           color profile conversion
//
// Phases:
//   1. Alpha compositing (sourceOver) — many pixel pairs
//   2. RGB↔HSL conversion
//   3. Color space conversion (rgbToAnsi256, rgbToAnsi16, ansi256ToAnsi16)
//   4. Color formatting (colorToHex, SGR construction)
//   5. UvColor construction + comparison
//   6. Color matrix application (effects/filters)

import 'dart:math';
import 'package:ultraviolet/ultraviolet.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

void main() {
  final rng = Random(42);

  // ---- Phase 1: Alpha compositing (sourceOver) ----
  // Generate many RGBA pairs
  final srcColors = List.generate(
    10_000,
    (_) => UvColor.rgb(
      rng.nextInt(256),
      rng.nextInt(256),
      rng.nextInt(256),
      a: rng.nextInt(256),
    ) as UvRgb,
  );
  final dstColors = List.generate(
    10_000,
    (_) => UvColor.rgb(
      rng.nextInt(256),
      rng.nextInt(256),
      rng.nextInt(256),
      a: rng.nextInt(256),
    ) as UvRgb,
  );
  final phase1Start = Stopwatch()..start();
  const phase1Iterations = 2000;
  var phase1Result = 0;
  for (var i = 0; i < phase1Iterations; i++) {
    for (var j = 0; j < srcColors.length; j++) {
      final result = uv.sourceOver(srcColors[j], dstColors[j]);
      if (result is UvRgb) {
        phase1Result += result.r + result.g + result.b;
      }
    }
  }
  final phase1Elapsed = phase1Start.elapsed;
  final phase1OpsPerSec =
      (phase1Iterations * srcColors.length) /
      phase1Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 2: RGB↔HSL ----
  final phase2Start = Stopwatch()..start();
  const phase2Iterations = 50_000;
  var phase2Result = 0.0;
  for (var i = 0; i < phase2Iterations; i++) {
    final r = rng.nextInt(256);
    final g = rng.nextInt(256);
    final b = rng.nextInt(256);
    final (h, s, l) = uv.rgbToHsl(r, g, b);
    phase2Result += h + s + l;
  }
  final phase2Elapsed = phase2Start.elapsed;
  final phase2OpsPerSec = phase2Iterations / phase2Elapsed.inMicroseconds * 1e6;

  // ---- Phase 3: Color space conversion ----
  final phase3Start = Stopwatch()..start();
  const phase3Iterations = 50_000;
  var phase3Result = 0;
  for (var i = 0; i < phase3Iterations; i++) {
    final r = rng.nextInt(256);
    final g = rng.nextInt(256);
    final b = rng.nextInt(256);
    phase3Result += uv.rgbToAnsi256(r, g, b);
    phase3Result += uv.rgbToAnsi16(r, g, b);
  }
  // Also test ansi256ToAnsi16
  for (var i = 0; i < phase3Iterations; i++) {
    final idx = rng.nextInt(256);
    phase3Result += uv.ansi256ToAnsi16(idx);
  }
  final phase3Elapsed = phase3Start.elapsed;
  final phase3OpsPerSec =
      (phase3Iterations * 3) / phase3Elapsed.inMicroseconds * 1e6;

  // ---- Phase 4: Color formatting (colorToHex) ----
  final phase4colors = List.generate(
    5000,
    (_) => UvRgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256)),
  );
  final phase4Start = Stopwatch()..start();
  const phase4Iterations = 10_000;
  var phase4Result = 0;
  for (var i = 0; i < phase4Iterations; i++) {
    for (final c in phase4colors) {
      final hex = uv.colorToHex(c);
      phase4Result += hex.length;
    }
  }
  final phase4Elapsed = phase4Start.elapsed;
  final phase4OpsPerSec =
      (phase4Iterations * phase4colors.length) /
      phase4Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 5: UvColor construction + comparison ----
  final phase5Start = Stopwatch()..start();
  const phase5Iterations = 100_000;
  var phase5Result = 0;
  for (var i = 0; i < phase5Iterations; i++) {
    final a = UvColor.rgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256));
    final b = UvColor.rgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256));
    const styleA = UvStyle();
    const styleB = UvStyle();
    if (a == b) phase5Result++;
    if (styleA == styleB) phase5Result++;
  }
  final phase5Elapsed = phase5Start.elapsed;
  final phase5OpsPerSec =
      phase5Iterations / phase5Elapsed.inMicroseconds * 1e6;

  // ---- Phase 6: Color matrix application ----
  final grayMatrix = ColorMatrix([
    0.33, 0.59, 0.11, 0, 0, //
    0.33, 0.59, 0.11, 0, 0, //
    0.33, 0.59, 0.11, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
  final phase6Colors = List.generate(
    10_000,
    (_) => UvRgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256)),
  );
  final phase6Start = Stopwatch()..start();
  const phase6Iterations = 1000;
  var phase6Result = 0.0;
  for (var i = 0; i < phase6Iterations; i++) {
    for (final c in phase6Colors) {
      final r = c.r * grayMatrix.values[0] +
          c.g * grayMatrix.values[1] +
          c.b * grayMatrix.values[2] +
          grayMatrix.values[4];
      final g = c.r * grayMatrix.values[5] +
          c.g * grayMatrix.values[6] +
          c.b * grayMatrix.values[7] +
          grayMatrix.values[9];
      final b = c.r * grayMatrix.values[10] +
          c.g * grayMatrix.values[11] +
          c.b * grayMatrix.values[12] +
          grayMatrix.values[14];
      phase6Result += r + g + b;
    }
  }
  final phase6Elapsed = phase6Start.elapsed;

  final totalCheck = phase1Result + phase2Result.round() + phase3Result +
      phase4Result + phase5Result + phase6Result.round();

  print('=== Color Operations Benchmark ===');
  print('');
  print(
    'Phase 1 (sourceOver):          ${_fmt(phase1OpsPerSec)} ops/s  '
    '(check: $phase1Result)',
  );
  print(
    'Phase 2 (rgbToHsl):            ${_fmt(phase2OpsPerSec)} ops/s  '
    '(check: ${phase2Result.toStringAsFixed(1)})',
  );
  print(
    'Phase 3 (conv ansi256/16):     ${_fmt(phase3OpsPerSec)} ops/s  '
    '(check: $phase3Result)',
  );
  print(
    'Phase 4 (colorToHex):          ${_fmt(phase4OpsPerSec)} ops/s  '
    '(check: $phase4Result)',
  );
  print(
    'Phase 5 (construct + compare): ${_fmt(phase5OpsPerSec)} ops/s  '
    '(check: $phase5Result)',
  );
  print(
    'Phase 6 (color matrix):        '
    '${phase6Iterations * phase6Colors.length} ops in '
    '${phase6Elapsed.inMilliseconds}ms  '
    '(check: ${phase6Result.toStringAsFixed(0)})',
  );
  print('');
  print('Total check value: $totalCheck');
}

String _fmt(double n) {
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}
