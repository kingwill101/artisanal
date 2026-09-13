import 'package:test/test.dart';

import '../tool/memory_soak.dart' as soak;

void main() {
  test('slope excludes teardown, even when teardown is a large drop', () {
    final slope = soak.calculateSoakSlope([
      {'phase': 'warmup', 'liveBytes': 1000000},
      {'phase': 'batch-0', 'liveBytes': 100},
      {'phase': 'batch-1', 'liveBytes': 200},
      {'phase': 'teardown', 'liveBytes': 0},
    ]);

    expect(slope['available'], isTrue);
    expect(slope['liveBytesPerBatch'], 100);
  });

  test('options reject malformed integers and unknown keys', () {
    expect(
      () => soak.SoakOptions.parse(['--iterations=wat']),
      throwsFormatException,
    );
    expect(
      () => soak.SoakOptions.parse(['--iteratons=2']),
      throwsFormatException,
    );
    expect(soak.SoakOptions.parse(['--warmup=0', '--batches=1']).warmup, 0);
  });
}
