import 'dart:async';

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

/// Test message for command results.
class TestMsg extends Msg {
  const TestMsg(this.value);
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TestMsg && value == other.value);

  @override
  int get hashCode => value.hashCode;
}

/// Test message for errors.
class ErrorMsg extends Msg {
  const ErrorMsg(this.error);
  final String error;
}

void main() {
  group('Cmd', () {
    test('executes and returns message', () async {
      final cmd = Cmd(() async => const TestMsg('result'));
      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
      expect((msg as TestMsg).value, 'result');
    });

    test('can return null', () async {
      final cmd = Cmd(() async => null);
      final msg = await cmd.execute();
      expect(msg, isNull);
    });
  });

  group('Cmd.none', () {
    test('returns null', () async {
      final cmd = Cmd.none();
      final msg = await cmd.execute();
      expect(msg, isNull);
    });
  });

  group('Cmd.quit', () {
    test('returns QuitMsg', () async {
      final cmd = Cmd.quit();
      final msg = await cmd.execute();
      expect(msg, isA<QuitMsg>());
    });
  });

  group('Cmd.tick', () {
    test('waits for duration then calls callback', () async {
      final stopwatch = Stopwatch()..start();

      final cmd = Cmd.tick(
        const Duration(milliseconds: 50),
        (time) => TestMsg('tick at ${time.millisecond}'),
      );

      final msg = await cmd.execute();
      stopwatch.stop();

      expect(msg, isA<TestMsg>());
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });

    test('callback receives DateTime', () async {
      DateTime? receivedTime;

      final cmd = Cmd.tick(const Duration(milliseconds: 1), (time) {
        receivedTime = time;
        return const TestMsg('done');
      });

      await cmd.execute();

      expect(receivedTime, isNotNull);
      expect(
        receivedTime!.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 1)),
      );
    });

    test('callback can return null', () async {
      final cmd = Cmd.tick(const Duration(milliseconds: 1), (_) => null);
      final msg = await cmd.execute();
      expect(msg, isNull);
    });
  });

  group('Cmd.message', () {
    test('returns message immediately', () async {
      final cmd = Cmd.message(const TestMsg('immediate'));
      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
      expect((msg as TestMsg).value, 'immediate');
    });
  });

  group('Cmd.batch', () {
    test('empty batch returns none', () async {
      final cmd = Cmd.batch([]);
      final msg = await cmd.execute();
      expect(msg, isNull);
    });

    test('single command batch returns that command result', () async {
      final cmd = Cmd.batch([Cmd.message(const TestMsg('single'))]);
      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
      expect((msg as TestMsg).value, 'single');
    });

    test('multiple commands return BatchMsg', () async {
      final cmd = Cmd.batch([
        Cmd.message(const TestMsg('first')),
        Cmd.message(const TestMsg('second')),
      ]);

      final msg = await cmd.execute();
      expect(msg, isA<BatchMsg>());
      final batch = msg as BatchMsg;
      expect(batch.messages, hasLength(2));
      expect((batch.messages[0] as TestMsg).value, 'first');
      expect((batch.messages[1] as TestMsg).value, 'second');
    });

    test('runs commands concurrently', () async {
      final order = <int>[];

      final cmd = Cmd.batch([
        Cmd(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          order.add(1);
          return const TestMsg('slow');
        }),
        Cmd(() async {
          order.add(2);
          return const TestMsg('fast');
        }),
      ]);

      await cmd.execute();

      // Fast command should complete first
      expect(order, [2, 1]);
    });

    test('filters out null results', () async {
      final cmd = Cmd.batch([
        Cmd.message(const TestMsg('only')),
        Cmd.none(),
        Cmd(() async => null),
      ]);

      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
      expect((msg as TestMsg).value, 'only');
    });

    test('returns null if all commands return null', () async {
      final cmd = Cmd.batch([Cmd.none(), Cmd.none()]);
      final msg = await cmd.execute();
      expect(msg, isNull);
    });
  });

  group('Cmd.sequence', () {
    test('empty sequence returns none', () async {
      final cmd = Cmd.sequence([]);
      final msg = await cmd.execute();
      expect(msg, isNull);
    });

    test('single command sequence returns that command result', () async {
      final cmd = Cmd.sequence([Cmd.message(const TestMsg('single'))]);
      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
      expect((msg as TestMsg).value, 'single');
    });

    test('multiple commands return BatchMsg', () async {
      final cmd = Cmd.sequence([
        Cmd.message(const TestMsg('first')),
        Cmd.message(const TestMsg('second')),
      ]);

      final msg = await cmd.execute();
      expect(msg, isA<BatchMsg>());
      final batch = msg as BatchMsg;
      expect(batch.messages, hasLength(2));
    });

    test('runs commands in order', () async {
      final order = <int>[];

      final cmd = Cmd.sequence([
        Cmd(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          order.add(1);
          return const TestMsg('first');
        }),
        Cmd(() async {
          order.add(2);
          return const TestMsg('second');
        }),
      ]);

      await cmd.execute();

      // Commands should run in order despite timing
      expect(order, [1, 2]);
    });

    test('filters out null results', () async {
      final cmd = Cmd.sequence([
        Cmd.none(),
        Cmd.message(const TestMsg('only')),
        Cmd(() async => null),
      ]);

      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
      expect((msg as TestMsg).value, 'only');
    });
  });

  group('Cmd.perform', () {
    test('maps success result to message', () async {
      final cmd = Cmd.perform(
        () async => 'hello',
        onSuccess: (result) => TestMsg(result),
      );

      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
      expect((msg as TestMsg).value, 'hello');
    });

    test('maps error to message when onError provided', () async {
      final cmd = Cmd.perform<String>(
        () async => throw Exception('failed'),
        onSuccess: (result) => TestMsg(result),
        onError: (error, _) => ErrorMsg(error.toString()),
      );

      final msg = await cmd.execute();
      expect(msg, isA<ErrorMsg>());
      expect((msg as ErrorMsg).error, contains('failed'));
    });

    test('rethrows error when onError not provided', () async {
      final cmd = Cmd.perform<String>(
        () async => throw Exception('failed'),
        onSuccess: (result) => TestMsg(result),
      );

      expect(() => cmd.execute(), throwsException);
    });
  });

  group('StreamCmd', () {
    test('sends messages for stream data', () async {
      final controller = StreamController<String>();
      final received = <Msg>[];

      final cmd = Cmd.listen<String>(
        controller.stream,
        onData: (data) => TestMsg(data),
      );

      cmd.start((msg) => received.add(msg));

      controller.add('first');
      controller.add('second');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, hasLength(2));
      expect((received[0] as TestMsg).value, 'first');
      expect((received[1] as TestMsg).value, 'second');

      await cmd.cancel();
      await controller.close();
    });

    test('sends message for stream errors', () async {
      final controller = StreamController<String>();
      final received = <Msg>[];

      final cmd = Cmd.listen<String>(
        controller.stream,
        onData: (data) => TestMsg(data),
        onError: (error, _) => ErrorMsg(error.toString()),
      );

      cmd.start((msg) => received.add(msg));

      controller.addError(Exception('oops'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, hasLength(1));
      expect(received[0], isA<ErrorMsg>());
      expect((received[0] as ErrorMsg).error, contains('oops'));

      await cmd.cancel();
      await controller.close();
    });

    test('sends message on stream done', () async {
      final controller = StreamController<String>();
      final received = <Msg>[];

      final cmd = Cmd.listen<String>(
        controller.stream,
        onData: (data) => TestMsg(data),
        onDone: () => const TestMsg('done'),
      );

      cmd.start((msg) => received.add(msg));

      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, hasLength(1));
      expect((received[0] as TestMsg).value, 'done');

      await cmd.cancel();
    });

    test('isActive tracks subscription state', () async {
      final controller = StreamController<String>();

      final cmd = Cmd.listen<String>(
        controller.stream,
        onData: (data) => TestMsg(data),
      );

      expect(cmd.isActive, isFalse);

      cmd.start((_) {});
      expect(cmd.isActive, isTrue);

      await cmd.cancel();
      expect(cmd.isActive, isFalse);

      await controller.close();
    });

    test('can filter messages by returning null', () async {
      final controller = StreamController<String>();
      final received = <Msg>[];

      final cmd = Cmd.listen<String>(
        controller.stream,
        onData: (data) => data.startsWith('keep') ? TestMsg(data) : null,
      );

      cmd.start((msg) => received.add(msg));

      controller.add('ignore');
      controller.add('keep this');
      controller.add('also ignore');
      controller.add('keep that');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, hasLength(2));
      expect((received[0] as TestMsg).value, 'keep this');
      expect((received[1] as TestMsg).value, 'keep that');

      await cmd.cancel();
      await controller.close();
    });
  });

  group('EveryCmd', () {
    test('fires at interval', () async {
      final received = <Msg>[];

      final cmd = EveryCmd(
        interval: const Duration(milliseconds: 50),
        callback: (time) => TestMsg('tick'),
      );

      cmd.start((msg) => received.add(msg));

      // Wait for a few ticks
      await Future<void>.delayed(const Duration(milliseconds: 175));

      cmd.stop();

      // Should have received 2-3 ticks
      expect(received.length, greaterThanOrEqualTo(2));
      expect(received.length, lessThanOrEqualTo(4));
    });

    test('isActive tracks timer state', () {
      final cmd = EveryCmd(
        interval: const Duration(milliseconds: 100),
        callback: (time) => const TestMsg('tick'),
      );

      expect(cmd.isActive, isFalse);

      cmd.start((_) {});
      // Note: Due to initial delay, might not be active immediately
      cmd.stop();
      expect(cmd.isActive, isFalse);
    });

    test('stop cancels timer', () async {
      final received = <Msg>[];

      final cmd = EveryCmd(
        interval: const Duration(milliseconds: 30),
        callback: (time) => TestMsg('tick'),
      );

      cmd.start((msg) => received.add(msg));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final countBeforeStop = received.length;
      cmd.stop();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // No new messages after stop
      expect(received.length, countBeforeStop);
    });

    test('stop before first tick prevents any ticks', () async {
      final received = <Msg>[];

      final cmd = EveryCmd(
        interval: const Duration(milliseconds: 200),
        callback: (time) => const TestMsg('tick'),
      );

      cmd.start((msg) => received.add(msg));
      cmd.stop();

      // Wait longer than the interval boundary.
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(received, isEmpty);
    });
  });

  group('CmdExtension', () {
    test('orNone returns Cmd.none for null', () async {
      const Cmd? nullCmd = null;
      final cmd = nullCmd.orNone();
      final msg = await cmd.execute();
      expect(msg, isNull);
    });

    test('orNone returns original command if not null', () async {
      final Cmd someCmd = Cmd.message(const TestMsg('value'));
      final cmd = someCmd.orNone();
      final msg = await cmd.execute();
      expect(msg, isA<TestMsg>());
    });

    test('isActive is false for null', () {
      const Cmd? nullCmd = null;
      expect(nullCmd.isActive, isFalse);
    });

    test('isActive is true for non-null', () {
      final Cmd someCmd = Cmd.none();
      expect(someCmd.isActive, isTrue);
    });
  });

  group('every helper function', () {
    test('creates EveryCmd', () {
      final cmd = every(
        const Duration(milliseconds: 100),
        (time) => const TestMsg('tick'),
      );
      expect(cmd, isA<EveryCmd>());
    });

    test('accepts optional id', () {
      final cmd = every(
        const Duration(milliseconds: 100),
        (time) => const TestMsg('tick'),
        id: 'my-timer',
      );
      expect((cmd as EveryCmd).id, 'my-timer');
    });
  });
}
