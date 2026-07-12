// Benchmark: String width calculation
//
// Stresses: runeWidth(), stringWidth(), _asciiStringWidth(),
//           _simpleUnicodeStringWidth(), _unicodeStringWidthCache,
//           _isEmojiPresentation(), grapheme clustering
//
// Phases:
//   1. Short ASCII strings (fast path via _asciiStringWidth)
//   2. Mixed ASCII + Unicode (via _simpleUnicodeStringWidth)
//   3. CJK characters (wide path via runeWidth range checks)
//   4. Emoji sequences (grapheme clustering path)
//   5. Long strings (> 4096 chars, uncached)
//   6. Cache thrash — many unique strings

import 'dart:math';
import 'package:ultraviolet/ultraviolet.dart';

/// Generate a random ASCII string of given length.
String randomAscii(Random rng, int length) {
  final units = List.generate(
    length,
    (_) => 32 + rng.nextInt(95), // 0x20..0x7E
  );
  return String.fromCharCodes(units);
}

/// Generate a string with some CJK characters mixed in.
String mixedString(Random rng, int length, {double cjkRatio = 0.2}) {
  final units = <int>[];
  for (var i = 0; i < length; i++) {
    if (rng.nextDouble() < cjkRatio) {
      // CJK Unified Ideograph in range U+4E00..U+9FFF
      units.add(0x4E00 + rng.nextInt(0x5200));
    } else {
      units.add(32 + rng.nextInt(95));
    }
  }
  return String.fromCharCodes(units);
}

/// Generate an emoji-heavy string.
String emojiString(Random rng, int count) {
  // Common emoji code points
  const emojis = <int>[
    0x1F600, // 😀 grinning
    0x1F308, // 🌈 rainbow
    0x1F389, // 🎉 party popper
    0x1F44D, // 👍 thumbs up
    0x1F499, // 💙 blue heart
    0x1F4A1, // 💡 light bulb
    0x1F4BB, // 💻 laptop
    0x1F60E, // 😎 smiling with sunglasses
    0x1F634, // 😴 sleeping
    0x1F680, // 🚀 rocket
    0x1F914, // 🤔 thinking
    0x1F929, // 🤩 star-struck
    0x1F970, // 🥰 smiling with hearts
    0x1F3C0, // 🏀 basketball
    0x1F3AE, // 🎮 video game
    0x1F4F1, // 📱 mobile phone
    0x1F4F8, // 📸 camera
    0x1F525, // 🔥 fire
    0x1F602, // 😂 tears of joy
    0x1F92A, // 🤪 zany face
  ];
  final units = <int>[];
  for (var i = 0; i < count; i++) {
    units.add(emojis[rng.nextInt(emojis.length)]);
  }
  return String.fromCharCodes(units);
}

void main() {
  final rng = Random(42);

  // ---- Phase 1: Short ASCII strings ----
  final asciiStrings = List.generate(5000, (_) => randomAscii(rng, 10));
  final phase1Start = Stopwatch()..start();
  const phase1Iterations = 10_000;
  var phase1Result = 0;
  for (var i = 0; i < phase1Iterations; i++) {
    for (final s in asciiStrings) {
      phase1Result += stringWidth(s);
    }
  }
  final phase1Elapsed = phase1Start.elapsed;
  final phase1OpsPerSec =
      (phase1Iterations * asciiStrings.length) /
      phase1Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 2: Mixed ASCII + Unicode ----
  final mixedStrings = List.generate(2000, (_) => mixedString(rng, 20));
  final phase2Start = Stopwatch()..start();
  const phase2Iterations = 5000;
  var phase2Result = 0;
  for (var i = 0; i < phase2Iterations; i++) {
    for (final s in mixedStrings) {
      phase2Result += stringWidth(s);
    }
  }
  final phase2Elapsed = phase2Start.elapsed;
  final phase2OpsPerSec =
      (phase2Iterations * mixedStrings.length) /
      phase2Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 3: CJK strings ----
  final cjkStrings = List.generate(
    2000,
    (_) => mixedString(rng, 20, cjkRatio: 1.0),
  );
  final phase3Start = Stopwatch()..start();
  const phase3Iterations = 5000;
  var phase3Result = 0;
  for (var i = 0; i < phase3Iterations; i++) {
    for (final s in cjkStrings) {
      phase3Result += stringWidth(s);
    }
  }
  final phase3Elapsed = phase3Start.elapsed;
  final phase3OpsPerSec =
      (phase3Iterations * cjkStrings.length) /
      phase3Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 4: Emoji strings ----
  final emojiStrings = List.generate(1000, (_) => emojiString(rng, 5));
  final phase4Start = Stopwatch()..start();
  const phase4Iterations = 10_000;
  var phase4Result = 0;
  for (var i = 0; i < phase4Iterations; i++) {
    for (final s in emojiStrings) {
      phase4Result += stringWidth(s);
    }
  }
  final phase4Elapsed = phase4Start.elapsed;
  final phase4OpsPerSec =
      (phase4Iterations * emojiStrings.length) /
      phase4Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 5: Long strings (uncached, > 4096 chars) ----
  final longStrings = List.generate(
    200,
    (_) => randomAscii(rng, 5000),
  );
  final phase5Start = Stopwatch()..start();
  const phase5Iterations = 1000;
  var phase5Result = 0;
  for (var i = 0; i < phase5Iterations; i++) {
    for (final s in longStrings) {
      phase5Result += stringWidth(s);
    }
  }
  final phase5Elapsed = phase5Start.elapsed;
  final phase5OpsPerSec =
      (phase5Iterations * longStrings.length) /
      phase5Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 6: Cache thrash — many unique strings ----
  final uniqueStrings = List.generate(
    10_000,
    (i) => randomAscii(rng, 20) + String.fromCharCode(0x4E00 + i % 0x1000), // make unique
  );
  final phase6Start = Stopwatch()..start();
  const phase6Iterations = 100;
  var phase6Result = 0;
  for (var i = 0; i < phase6Iterations; i++) {
    for (final s in uniqueStrings) {
      phase6Result += stringWidth(s);
    }
  }
  final phase6Elapsed = phase6Start.elapsed;

  // Drain results to prevent DCE
  final totalCheck =
      phase1Result + phase2Result + phase3Result +
      phase4Result + phase5Result + phase6Result;

  print('=== String Width Benchmark ===');
  print('');
  print(
    'Phase 1 (short ASCII):      '
    '${_fmt(phase1OpsPerSec)} ops/s  (check: $phase1Result)',
  );
  print(
    'Phase 2 (mixed Unicode):    '
    '${_fmt(phase2OpsPerSec)} ops/s  (check: $phase2Result)',
  );
  print(
    'Phase 3 (CJK):              '
    '${_fmt(phase3OpsPerSec)} ops/s  (check: $phase3Result)',
  );
  print(
    'Phase 4 (emoji):            '
    '${_fmt(phase4OpsPerSec)} ops/s  (check: $phase4Result)',
  );
  print(
    'Phase 5 (long ASCII):       '
    '${_fmt(phase5OpsPerSec)} ops/s  (check: $phase5Result)',
  );
  print(
    'Phase 6 (cache thrash):     '
    '${phase6Iterations * uniqueStrings.length} calls in '
    '${phase6Elapsed.inMilliseconds}ms  (check: $phase6Result)',
  );
  print('');
  print('Total check value: $totalCheck'); // prevent DCE
}

String _fmt(double n) {
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}
