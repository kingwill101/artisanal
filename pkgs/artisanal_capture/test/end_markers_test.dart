import 'dart:math';

import 'package:artisanal_capture/src/cli/end_markers.dart';
import 'package:test/test.dart';

void main() {
  test('matches embedded, overlapping, suffix, and prefix markers', () {
    final matcher = EndMarkerMatcher([
      'END_A',
      'END_AB',
      'END_END_A',
      'END_A_END_A',
      'END_MISSING',
      'END_A',
    ]);
    for (final text in [
      'prefixEND_A_END_Asuffix END_END_AB',
      'xEND_ABextra',
      '',
      'END_MISSING',
    ]) {
      expect(
        matcher.findIn(text),
        matcher.markers.where(text.contains).toSet(),
      );
    }
  });

  test('source duplicates do not consume the distinct-marker budget', () {
    final matcher = EndMarkerMatcher.fromSource(
      List.filled(20000, 'END_A').join('\n'),
    );
    expect(matcher.markers, ['END_A']);
    expect(matcher.findIn('inline END_AB'), {'END_A'});
  });

  test('matches String.contains on deterministic generated inputs', () {
    final random = Random(42);
    for (var run = 0; run < 200; run++) {
      final patterns = [
        for (var i = 0; i < 20; i++)
          'END_${List.generate(1 + random.nextInt(8), (_) => 'ABC_'[random.nextInt(4)]).join()}',
      ];
      final text = List.generate(
        100,
        (_) => random.nextBool()
            ? patterns[random.nextInt(patterns.length)]
            : 'noise',
      ).join();
      expect(
        EndMarkerMatcher(patterns).findIn(text),
        patterns.where(text.contains).toSet(),
      );
    }
  });

  test('repeated suffix matches do not accumulate output work or state', () {
    final patterns = [
      for (var i = 1; i <= 200; i++) 'END_' * (i + 1),
      'END_MISSING',
    ];
    final matcher = EndMarkerMatcher(patterns);
    expect(matcher.findIn('END_' * 100000), patterns.take(200).toSet());
    expect(matcher.findIn('END_MISSING'), {'END_MISSING'});
  });

  test('rejects excessive distinct marker sets', () {
    expect(
      () => EndMarkerMatcher.fromSource(
        List.generate(10001, (i) => 'END_$i').join('\n'),
      ),
      throwsFormatException,
    );
  });

  test('rejects excessive retained pattern text before building the index', () {
    expect(
      () => EndMarkerMatcher([
        'END_${'A' * (EndMarkerMatcher.maxPatternBytes ~/ 2)}',
      ]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('pattern text'),
        ),
      ),
    );
  });

  test('rejects a trie above the node budget', () {
    expect(
      () => EndMarkerMatcher(['END_${'A' * EndMarkerMatcher.maxNodes}']),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('resource limit'),
        ),
      ),
    );
  });
}
