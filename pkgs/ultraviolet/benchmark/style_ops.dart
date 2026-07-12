// Benchmark: Style operations
//
// Stresses: styleToSgr(), styleDiff(), convertStyle(), UvStyle.copyWith(),
//           packedKey hashing, style equality
//
// Phases:
//   1. styleToSgr() — single-style to ANSI
//   2. styleDiff() — pairwise diff between consecutive styles
//   3. convertStyle() — style down-conversion across color profiles
//   4. copyWith() — style mutation
//   5. Style equality + hashing

import 'dart:math';
import 'package:ultraviolet/ultraviolet.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

void main() {
  final rng = Random(42);

  const attrValues = [
    Attr.bold,
    Attr.italic,
    Attr.faint,
    Attr.reverse,
    Attr.blink,
    Attr.strikethrough,
  ];

  const underlineValues = [
    UnderlineStyle.none,
    UnderlineStyle.single,
    UnderlineStyle.double,
    UnderlineStyle.curly,
    UnderlineStyle.dotted,
    UnderlineStyle.dashed,
  ];

  // Generate a diverse pool of styles
  final stylePool = List.generate(500, (i) {
    return UvStyle(
      fg: i % 3 == 0
          ? UvColor.basic16(rng.nextInt(8), bright: rng.nextBool())
          : i % 3 == 1
          ? UvColor.indexed256(rng.nextInt(256))
          : UvColor.rgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256)),
      bg: rng.nextBool()
          ? UvColor.rgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256))
          : null,
      attrs: attrValues[rng.nextInt(attrValues.length)],
      underline: underlineValues[rng.nextInt(underlineValues.length)],
    );
  });

  // ---- Phase 1: styleToSgr() ----
  final phase1Start = Stopwatch()..start();
  const phase1Iterations = 5_000;
  var phase1Length = 0;
  for (var i = 0; i < phase1Iterations; i++) {
    for (final style in stylePool) {
      phase1Length += uv.styleToSgr(style).length;
    }
  }
  final phase1Elapsed = phase1Start.elapsed;
  final phase1OpsPerSec =
      (phase1Iterations * stylePool.length) /
      phase1Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 2: styleDiff() ----
  final phase2Start = Stopwatch()..start();
  const phase2Iterations = 5_000;
  var phase2Length = 0;
  for (var i = 0; i < phase2Iterations; i++) {
    for (var j = 1; j < stylePool.length; j++) {
      phase2Length += uv.styleDiff(stylePool[j - 1], stylePool[j]).length;
    }
  }
  final phase2Elapsed = phase2Start.elapsed;
  final phase2OpsPerSec =
      (phase2Iterations * (stylePool.length - 1)) /
      phase2Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 3: convertStyle() ----
  const profiles = [
    uv.Profile.trueColor,
    uv.Profile.ansi,
    uv.Profile.ansi256,
    uv.Profile.noTty,
  ];
  final phase3Start = Stopwatch()..start();
  const phase3Iterations = 1_000;
  var phase3Result = 0;
  for (var i = 0; i < phase3Iterations; i++) {
    for (final style in stylePool) {
      for (final profile in profiles) {
        final converted = uv.convertStyle(style, profile);
        phase3Result += (converted.fg?.hashCode ?? 0);
      }
    }
  }
  final phase3Elapsed = phase3Start.elapsed;
  final phase3OpsPerSec =
      (phase3Iterations * stylePool.length * profiles.length) /
      phase3Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 4: copyWith() ----
  final phase4Start = Stopwatch()..start();
  const phase4Iterations = 5_000;
  var phase4Result = 0;
  for (var i = 0; i < phase4Iterations; i++) {
    for (final style in stylePool) {
      final copy = style.copyWith(
        fg: UvColor.rgb(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256)),
        underline: UnderlineStyle.double,
      );
      phase4Result += copy.packedKey;
    }
  }
  final phase4Elapsed = phase4Start.elapsed;
  final phase4OpsPerSec =
      (phase4Iterations * stylePool.length) /
      phase4Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 5: Style equality + hashing ----
  // Create many identical/similar style pairs for comparison
  final eqPairs = List.generate(5000, (_) {
    final fg = UvColor.rgb(
      rng.nextInt(256),
      rng.nextInt(256),
      rng.nextInt(256),
    );
    final bg = UvColor.rgb(
      rng.nextInt(256),
      rng.nextInt(256),
      rng.nextInt(256),
    );
    return (
      UvStyle(fg: fg, bg: bg, attrs: Attr.bold),
      UvStyle(fg: fg, bg: bg, attrs: Attr.bold),
    );
  });
  final phase5Start = Stopwatch()..start();
  const phase5Iterations = 2_000;
  var phase5Result = 0;
  for (var i = 0; i < phase5Iterations; i++) {
    for (final (a, b) in eqPairs) {
      if (a == b) phase5Result += a.hashCode;
    }
  }
  final phase5Elapsed = phase5Start.elapsed;
  final phase5OpsPerSec =
      (phase5Iterations * eqPairs.length) / phase5Elapsed.inMicroseconds * 1e6;

  final totalCheck =
      phase1Length + phase2Length + phase3Result + phase4Result + phase5Result;

  print('=== Style Operations Benchmark ===');
  print('');
  print(
    'Phase 1 (styleToSgr):      ${_fmt(phase1OpsPerSec)} ops/s  '
    '(total len: $phase1Length)',
  );
  print(
    'Phase 2 (styleDiff):       ${_fmt(phase2OpsPerSec)} ops/s  '
    '(total len: $phase2Length)',
  );
  print(
    'Phase 3 (convertStyle):    ${_fmt(phase3OpsPerSec)} ops/s  '
    '(check: $phase3Result)',
  );
  print(
    'Phase 4 (copyWith):        ${_fmt(phase4OpsPerSec)} ops/s  '
    '(check: $phase4Result)',
  );
  print(
    'Phase 5 (eq + hash):       ${_fmt(phase5OpsPerSec)} ops/s  '
    '(check: $phase5Result)',
  );
  print('');
  print('Total check value: $totalCheck');
}

String _fmt(double n) {
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}
