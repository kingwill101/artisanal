// Benchmark: Event decoder
//
// Stresses: EventDecoder.decode(), consumeEscapeSequence(), _parseCsi(),
//           _parseOsc(), mouse decoding, key decoding, UTF-8 parsing,
//           sublist() allocations, String.fromCharCodes()
//
// Phases:
//   1. ASCII keystrokes (plain text input — most common)
//   2. CSI sequences (cursor keys, function keys)
//   3. Mouse reports (SGR-encoded mouse events)
//   4. OSC sequences (terminal title, clipboard)
//   5. Kitty keyboard protocol (extended CSI)
//   6. Mixed real-world input stream

import 'dart:math';
import 'package:ultraviolet/ultraviolet.dart';

/// Generate N bytes of plain ASCII keystrokes (a-z, space, enter).
List<int> asciiKeystrokes(Random rng, int count) {
  final bytes = <int>[];
  for (var i = 0; i < count; i++) {
    switch (rng.nextInt(5)) {
      case 0:
        bytes.add(0x0A); // enter
      case 1:
        bytes.add(0x20); // space
      default:
        bytes.add(0x61 + rng.nextInt(26)); // a-z
    }
  }
  return bytes;
}

/// Generate N CSI cursor key sequences.
List<int> csiCursorKeys(Random rng, int count) {
  const csi = 0x1B;
  const lb = 0x5B;
  const keys = [0x41, 0x42, 0x43, 0x44]; // Up, Down, Right, Left
  final bytes = <int>[];
  for (var i = 0; i < count; i++) {
    bytes.addAll([csi, lb, keys[rng.nextInt(keys.length)]]);
  }
  return bytes;
}

/// Generate N SGR mouse reports.
List<int> sgrMouseReports(Random rng, int count) {
  const csi = 0x1B;
  const lb = 0x5B;
  const lt = 0x3C; // '<'
  const M = 0x4D; // 'M'
  final bytes = <int>[];
  for (var i = 0; i < count; i++) {
    final cb = rng.nextInt(3); // button 0-2
    final cx = rng.nextInt(200); // column
    final cy = rng.nextInt(80); // row
    // SGR: ESC [ < Cb ; Cx ; Cy M
    final seq = '${String.fromCharCode(csi)}'
        '${String.fromCharCode(lb)}'
        '${String.fromCharCode(lt)}'
        '$cb;${cx + 1};${cy + 1}'
        '${String.fromCharCode(M)}';
    bytes.addAll(seq.codeUnits);
  }
  return bytes;
}

/// Generate N OSC sequences (e.g., set window title).
List<int> oscSequences(Random rng, int count) {
  const osc = 0x1B;
  const rb = 0x5D; // ]
  const bel = 0x07;
  final bytes = <int>[];
  for (var i = 0; i < count; i++) {
    bytes.addAll([osc, rb, 0x30, 0x3B]);
    // 5-char random title
    for (var j = 0; j < 5; j++) {
      bytes.add(0x61 + rng.nextInt(26));
    }
    bytes.add(bel);
  }
  return bytes;
}

/// Generate N Kitty keyboard protocol sequences.
List<int> kittyKeys(Random rng, int count) {
  const csi = 0x1B;
  const lb = 0x5B;
  const tilde = 0x7E;
  final bytes = <int>[];
  for (var i = 0; i < count; i++) {
    final key = 10 + rng.nextInt(20); // f-keys and others
    final modifiers = rng.nextInt(8); // 0-7 (ctrl, alt, shift combos)
    final seq = '${String.fromCharCode(csi)}'
        '${String.fromCharCode(lb)}'
        '$key;${modifiers + 1}'
        '${String.fromCharCode(tilde)}';
    bytes.addAll(seq.codeUnits);
  }
  return bytes;
}

/// Decode all events from [data] using [decoder].
/// Advances through [data] via an index offset to avoid sublist allocations.
int decodeAll(EventDecoder decoder, List<int> data) {
  var count = 0;
  var offset = 0;
  while (offset < data.length) {
    final slice = data.sublist(offset);
    final (n, ev) = decoder.decode(slice, allowIncompleteEsc: true);
    if (n == 0) break;
    offset += n;
    if (ev != null) count++;
  }
  return count;
}

void main() {
  final rng = Random(42);

  // ---- Phase 1: ASCII keystrokes ----
  final asciiData = asciiKeystrokes(rng, 10_000);
  final phase1Start = Stopwatch()..start();
  const phase1Iterations = 20;
  var phase1Count = 0;
  for (var i = 0; i < phase1Iterations; i++) {
    phase1Count += decodeAll(EventDecoder(), asciiData);
  }
  final phase1Elapsed = phase1Start.elapsed;
  final phase1EventsPerSec =
      (phase1Iterations * asciiData.length) /
      phase1Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 2: CSI cursor keys ----
  final csiData = csiCursorKeys(rng, 5_000);
  final phase2Start = Stopwatch()..start();
  const phase2Iterations = 40;
  var phase2Count = 0;
  for (var i = 0; i < phase2Iterations; i++) {
    phase2Count += decodeAll(EventDecoder(), csiData);
  }
  final phase2Elapsed = phase2Start.elapsed;
  final phase2EventsPerSec =
      (phase2Iterations * csiData.length) /
      phase2Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 3: SGR mouse reports ----
  final mouseData = sgrMouseReports(rng, 2_000);
  final phase3Start = Stopwatch()..start();
  const phase3Iterations = 20;
  var phase3Count = 0;
  for (var i = 0; i < phase3Iterations; i++) {
    phase3Count += decodeAll(EventDecoder(), mouseData);
  }
  final phase3Elapsed = phase3Start.elapsed;
  final phase3EventsPerSec =
      (phase3Iterations * mouseData.length) /
      phase3Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 4: OSC sequences ----
  final oscData = oscSequences(rng, 1_000);
  final phase4Start = Stopwatch()..start();
  const phase4Iterations = 10;
  var phase4Count = 0;
  for (var i = 0; i < phase4Iterations; i++) {
    phase4Count += decodeAll(EventDecoder(), oscData);
  }
  final phase4Elapsed = phase4Start.elapsed;
  final phase4EventsPerSec =
      (phase4Iterations * oscData.length) /
      phase4Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 5: Kitty keyboard ----
  final kittyData = kittyKeys(rng, 2_000);
  final phase5Start = Stopwatch()..start();
  const phase5Iterations = 20;
  var phase5Count = 0;
  for (var i = 0; i < phase5Iterations; i++) {
    phase5Count += decodeAll(EventDecoder(), kittyData);
  }
  final phase5Elapsed = phase5Start.elapsed;
  final phase5EventsPerSec =
      (phase5Iterations * kittyData.length) /
      phase5Elapsed.inMicroseconds *
      1e6;

  // ---- Phase 6: Mixed real-world input ----
  final mixedData = <int>[];
  mixedData.addAll(asciiKeystrokes(rng, 2_000));
  mixedData.addAll(csiCursorKeys(rng, 500));
  mixedData.addAll(sgrMouseReports(rng, 200));
  mixedData.addAll(oscSequences(rng, 100));
  mixedData.addAll(kittyKeys(rng, 200));
  mixedData.shuffle(rng);

  final phase6Start = Stopwatch()..start();
  const phase6Iterations = 10;
  var phase6Count = 0;
  for (var i = 0; i < phase6Iterations; i++) {
    phase6Count += decodeAll(EventDecoder(), mixedData);
  }
  final phase6Elapsed = phase6Start.elapsed;

  final totalCheck = phase1Count + phase2Count + phase3Count +
      phase4Count + phase5Count + phase6Count;

  print('=== Event Decoder Benchmark ===');
  print('');
  print(
    'Phase 1 (ASCII keys):     ${_fmt(phase1EventsPerSec)} bytes/s  '
    '(${phase1Count} events)',
  );
  print(
    'Phase 2 (CSI cursor):     ${_fmt(phase2EventsPerSec)} bytes/s  '
    '(${phase2Count} events)',
  );
  print(
    'Phase 3 (SGR mouse):      ${_fmt(phase3EventsPerSec)} bytes/s  '
    '(${phase3Count} events)',
  );
  print(
    'Phase 4 (OSC):            ${_fmt(phase4EventsPerSec)} bytes/s  '
    '(${phase4Count} events)',
  );
  print(
    'Phase 5 (Kitty keyboard): ${_fmt(phase5EventsPerSec)} bytes/s  '
    '(${phase5Count} events)',
  );
  print(
    'Phase 6 (mixed):          '
    '${phase6Iterations * mixedData.length} bytes in '
    '${phase6Elapsed.inMilliseconds}ms  '
    '(${phase6Count} events)',
  );
  print('');
  print('Total check value: $totalCheck');
}

String _fmt(double n) {
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}
