import 'dart:async';

import 'package:artisanal/src/terminal/stdin_stream.dart';
import 'package:test/test.dart';

void main() {
  group('SharedInputStream', () {
    test('keeps source subscription until shutdown', () async {
      var sourceListenCount = 0;
      var sourceCancelCount = 0;

      final source = StreamController<List<int>>(
        onListen: () => sourceListenCount++,
        onCancel: () => sourceCancelCount++,
      );
      addTearDown(source.close);

      final shared = SharedInputStream(source.stream);

      final sub = shared.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(sourceListenCount, 1);
      expect(shared.isStarted, isTrue);
      expect(shared.isShutdown, isFalse);

      await sub.cancel();
      await Future<void>.delayed(Duration.zero);
      // Canceling the last listener should NOT cancel the source subscription.
      expect(sourceCancelCount, 0);

      await shared.shutdown();
      expect(shared.isShutdown, isTrue);
      expect(sourceCancelCount, 1);
    });

    test('shutdown closes the broadcast stream and prevents reuse', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final shared = SharedInputStream(source.stream);

      final done = expectLater(shared.stream, emitsDone);
      await shared.shutdown();
      await done;

      expect(() => shared.stream, throwsA(isA<StateError>()));
      await shared.shutdown(); // idempotent
    });
  });
}
