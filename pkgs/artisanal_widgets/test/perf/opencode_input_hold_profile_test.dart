import 'dart:math' as math;

import 'package:artisanal/tui.dart' show PasteMsg;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/main.dart' as opencode;

void main() {
  test(
    'OpenCode held-key profile detects pause growth',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        await tester.pumpWidget(opencode.OpenCodeApp());

        const repeats = 1400;
        final durationsUs = <int>[];
        for (var i = 0; i < repeats; i++) {
          durationsUs.add(_timeUs(() => tester.sendKey('k')));
        }

        final chunk = 100;
        final chunkAveragesMs = <double>[];
        for (var start = 0; start < durationsUs.length; start += chunk) {
          final end = math.min(durationsUs.length, start + chunk);
          final slice = durationsUs.sublist(start, end);
          final avgUs = slice.fold<int>(0, (s, v) => s + v) / slice.length;
          chunkAveragesMs.add(avgUs / 1000.0);
        }

        final firstThird = durationsUs.sublist(0, repeats ~/ 3);
        final lastThird = durationsUs.sublist(repeats - repeats ~/ 3);
        final firstAvgMs =
            firstThird.fold<int>(0, (s, v) => s + v) /
            firstThird.length /
            1000.0;
        final lastAvgMs =
            lastThird.fold<int>(0, (s, v) => s + v) / lastThird.length / 1000.0;
        final growthRatio = firstAvgMs <= 0 ? 0 : (lastAvgMs / firstAvgMs);

        print('Held-key repeats: $repeats');
        print('Held-key avg first-third: ${firstAvgMs.toStringAsFixed(2)}ms');
        print('Held-key avg last-third : ${lastAvgMs.toStringAsFixed(2)}ms');
        print('Held-key growth ratio   : ${growthRatio.toStringAsFixed(2)}x');
        print(
          'Held-key chunk avgs (ms): ${chunkAveragesMs.map((v) => v.toStringAsFixed(2)).join(', ')}',
        );

        // Keep permissive for now: this is primarily a detector/profiler.
        // We'll tighten once we stabilize the input path.
        expect(growthRatio, lessThan(8.0));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  test(
    'OpenCode held-key cadence profile detects burst spikes',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        await tester.pumpWidget(opencode.OpenCodeApp());

        const repeats = 420;
        const cadenceMs = 16;
        final durationsUs = <int>[];
        for (var i = 0; i < repeats; i++) {
          durationsUs.add(_timeUs(() => tester.sendKey('k')));
          await Future<void>.delayed(const Duration(milliseconds: cadenceMs));
        }

        final sorted = List<int>.of(durationsUs)..sort();
        final medianUs = sorted[sorted.length ~/ 2];
        final spikeThresholdUs = medianUs * 3;
        final spikes = durationsUs.where((v) => v >= spikeThresholdUs).length;
        final p95Us =
            sorted[(sorted.length * 0.95).floor().clamp(0, sorted.length - 1)];

        print('Held-key cadence repeats: $repeats @ ${cadenceMs}ms');
        print(
          'Held-key cadence median : ${(medianUs / 1000).toStringAsFixed(2)}ms',
        );
        print(
          'Held-key cadence p95    : ${(p95Us / 1000).toStringAsFixed(2)}ms',
        );
        print(
          'Held-key cadence spikes : $spikes (>= ${(spikeThresholdUs / 1000).toStringAsFixed(2)}ms)',
        );

        // Detector budget: keep spikes bounded.
        expect(spikes, lessThan(80));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );

  test(
    'OpenCode paste profile measures large paste latency',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        await tester.pumpWidget(opencode.OpenCodeApp());

        final payload = List<String>.filled(50000, 'k').join();
        final durUs = _timeUs(() => tester.sendMsg(PasteMsg(payload)));

        print('Paste chars: ${payload.length}');
        print('Paste latency: ${(durUs / 1000).toStringAsFixed(2)}ms');

        expect(tester.find.text('kkkkkkkkkkkkkkkkkkkk'), isFalse);
        expect(durUs / 1000, lessThan(500));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

int _timeUs(void Function() fn) {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  return sw.elapsedMicroseconds;
}
